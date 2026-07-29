"""발송 억제 적용 — 반송된 주소로는 다시 보내지 않고 **사용자에게 알린다**(SP-AUTH-16 · P1-4).

**균일 204 계약과의 관계(핵심 판단)**: 로그인 코드 발송은 계정 유무를 숨기려고 항상 204 다
(AL-1, 계정 열거 차단). 억제는 그 계약을 깨지 않는다 — **억제는 계정의 속성이 아니라 주소의
배달 가능성**이기 때문이다. "이 주소는 메일이 반송된다"는 사실은 공격자가 스스로 메일을 보내
확인할 수 있는 정보라 우리가 새로 흘리는 것이 없다. 반대로 이것을 숨기면, 반송 주소를 가진
사용자는 **영영 로그인하지 못하면서 이유도 모른다** — P1-4 가 지목한 바로 그 공백이다.

무 DB — `database`·`mail_events` 를 monkeypatch 해 분기와 파라미터만 본다.
"""
from __future__ import annotations

import pytest

from server.services import auth_code, employment, mail_events


@pytest.fixture
def no_db(monkeypatch):
    """DB 접근을 전부 가로챈다 — 호출된 SQL 목록을 돌려준다."""
    calls: list[tuple[str, tuple]] = []

    async def _exec(sql, params=()):
        calls.append((sql, params))
        return 1

    async def _fetch_one(sql, params=()):
        calls.append((sql, params))
        return None

    monkeypatch.setattr("server.database.execute", _exec)
    monkeypatch.setattr("server.database.fetch_one", _fetch_one)
    return calls


@pytest.fixture
def sent(monkeypatch):
    """메일러를 가로채 실제 발송 여부를 관측한다."""
    box: list[tuple[str, str]] = []

    class _M:
        async def send_login_code(self, email, code):
            box.append((email, code))

        async def send_employ_code(self, email, code):
            box.append((email, code))

    monkeypatch.setattr("server.mailer.get_mailer", lambda: _M())
    return box


def _suppress(monkeypatch, value: bool):
    async def _is(email):
        return value

    monkeypatch.setattr(mail_events, "is_suppressed", _is)


# ── 로그인 경로 ───────────────────────────────────────────────────────────────
@pytest.mark.asyncio
async def test_MS1_suppressed_address_blocks_send_and_signals(monkeypatch, no_db, sent):
    """억제된 주소: 메일 0통 + 코드 행도 만들지 않고 호출측에 알린다.

    코드를 만들지 않는 것이 중요하다 — 배달되지 않을 코드를 발급하면 재전송 쿨다운만 잡아먹어
    사용자가 다른 주소로 바꿔도 60초를 기다리게 된다."""
    _suppress(monkeypatch, True)
    result = await auth_code.issue_login_code("bounced@example.com")

    assert result == auth_code.SUPPRESSED
    assert not sent, "억제된 주소로 메일이 나갔다"
    assert not any("TAUTH_CODE" in sql and "INSERT" in sql.upper() for sql, _ in no_db), (
        "배달 불가 주소에 코드 행을 만들었다(쿨다운만 소모)"
    )


@pytest.mark.asyncio
async def test_MS2_normal_address_unchanged(monkeypatch, no_db, sent):
    """억제되지 않은 주소는 기존 경로 그대로 — 회귀 가드."""
    _suppress(monkeypatch, False)
    result = await auth_code.issue_login_code("ok@example.com")

    assert result is None
    assert len(sent) == 1, "정상 주소인데 발송되지 않았다"
    assert any("TAUTH_CODE" in sql for sql, _ in no_db)


@pytest.mark.asyncio
async def test_MS3_suppression_lookup_failure_does_not_block_login(monkeypatch, no_db, sent):
    """**억제 조회 장애가 곧 전면 로그인 장애가 되면 안 된다.**

    억제는 도메인 평판 보호 장치지 인증 경로의 필수 의존이 아니다. 조회가 죽으면 보수적으로
    '억제 아님'으로 보고 발송을 계속한다(fail-open). 반대로 fail-close 하면, 테이블 부재·DB
    순단 한 번에 아무도 로그인하지 못한다.

    ⚠ **억제 조회만** 죽인다(SQL 텍스트로 식별). DB 전체를 죽이면 쿨다운 조회도 함께 터져서
    "억제 조회 실패가 발송을 막지 않는다"가 아니라 "DB 가 죽으면 로그인이 안 된다"를 확인하게
    된다 — 초판이 그 실수를 했다."""
    async def _fetch_one(sql, params=()):
        if "TMAIL_SUPPRESSION" in sql:
            raise RuntimeError("suppression lookup down")
        return None  # 쿨다운 조회 등 나머지는 정상

    monkeypatch.setattr("server.database.fetch_one", _fetch_one)
    assert await mail_events.is_suppressed("x@example.com") is False
    assert await auth_code.issue_login_code("x@example.com") is None
    assert len(sent) == 1, "억제 조회 장애가 로그인 메일 발송을 막았다"


@pytest.mark.asyncio
async def test_MS4_suppression_is_keyed_by_delivery_address(monkeypatch):
    """`+태그`·구글 도트 변형으로 억제를 우회할 수 없다 — 조회키가 배달주소 해시다."""
    seen = []

    async def _fetch_one(sql, params=()):
        seen.append(params)
        return None

    monkeypatch.setattr("server.database.fetch_one", _fetch_one)
    await mail_events.is_suppressed("ab+promo@gmail.com")  # +태그 → 'ab'
    await mail_events.is_suppressed("a.b@gmail.com")       # 구글 도트 → 'ab'
    await mail_events.is_suppressed("AB@gmail.com")        # 대문자 → 'ab'
    assert seen[0] == seen[2], "+태그가 접히지 않아 억제를 우회할 수 있다"
    assert seen[1] == seen[2], "구글 도트가 접히지 않아 억제를 우회할 수 있다"

    # 대조군: 다른 수신함은 달라야 한다(전부 같은 값이면 위 어서션이 무의미해진다).
    await mail_events.is_suppressed("other@gmail.com")
    assert seen[3] != seen[2], "서로 다른 주소가 같은 키로 접혔다 — 조회키가 망가졌다"


# ── 재직 인증 경로 ────────────────────────────────────────────────────────────
@pytest.mark.asyncio
async def test_MS5_employ_code_suppressed(monkeypatch, no_db, sent):
    """회사 이메일도 같은 규칙 — 반송되는 회사 주소로 코드를 계속 쏘지 않는다."""
    _suppress(monkeypatch, True)
    result = await employment.issue_employ_code(1, 2, "bounced@corp.example.com")

    assert result == auth_code.SUPPRESSED
    assert not sent


# ── 라우터 계약 ───────────────────────────────────────────────────────────────
@pytest.mark.asyncio
async def test_MS6_login_code_returns_409_mail_suppressed(monkeypatch):
    """라우터는 409 + `detail="mail_suppressed"` 로 알린다.

    사람이 읽는 문구가 아니라 **기계 토큰**인 이유: 프론트가 문구를 소유한다(`manual_required`
    선례와 동일). 서버 문구를 그대로 노출하면 두 곳에서 문안이 갈라진다."""
    from fastapi import HTTPException

    from server.routers import member

    async def _issue(email):
        return auth_code.SUPPRESSED

    monkeypatch.setattr(member.auth_code, "issue_login_code", _issue)
    body = type("B", (), {"email": "b@example.com"})()
    with pytest.raises(HTTPException) as exc:
        await member.request_login_code(body, None)
    assert exc.value.status_code == 409
    assert exc.value.detail == "mail_suppressed"


@pytest.mark.asyncio
async def test_MS7_employ_code_409_distinguishable_from_manual_required(monkeypatch):
    """재직 경로의 409 는 이미 `manual_required`(도메인 미등록)에 쓰인다 — **detail 로 구분**한다.

    구분하지 않으면 프론트가 반송을 '수동 승인 대기' 흐름으로 오독해, 사용자는 오지 않을
    승인을 기다리게 된다(verify.js `sendOutcome` 이 409 를 manual 로 단정하고 있었다)."""
    from fastapi import HTTPException

    from server.routers import employment as employment_router

    async def _status(comp_id, email):
        return employment.DomainStatus.OK

    async def _issue(comp_id, mbr_id, email):
        return auth_code.SUPPRESSED

    monkeypatch.setattr(employment_router.employment, "domain_status", _status)
    monkeypatch.setattr(employment_router.employment, "issue_employ_code", _issue)

    body = type("B", (), {"comp_id": 1, "company_email": "b@corp.example.com"})()
    with pytest.raises(HTTPException) as exc:
        await employment_router.request_employ_code(body, None, {"MBR_ID": 2})
    assert exc.value.status_code == 409
    assert exc.value.detail == "mail_suppressed" != "manual_required"
