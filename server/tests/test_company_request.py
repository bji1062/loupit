"""회사 등록 요청 — 검색에 없는 회사의 유일한 출구 (SP-AUTH-17, 2026-07-29 신설).

**왜 필요한가(사용자 지적)**: 재직 인증 화면에서 회사를 검색했을 때 결과가 0건이면 **화면이
아무 반응도 하지 않았다**(`verify.js` 가 목록을 숨기기만 했다). 게다가 막다른 길이었다 —
수동 승인 요청조차 `comp_id` 가 필수라, DB 에 없는 회사는 폴백 경로에 **진입조차 못 했다**.
등록 회사는 95개뿐이고 한국 취업자 대부분은 그 밖에 있으므로, 이건 소수 예외가 아니다.

**설계 결정(사용자)**: 등록 여부는 **무조건 운영자 판단**이다. 요청이 자동으로 회사를 만들지
않는다 — 복지 데이터가 0인 빈 회사가 비교 서비스에 쌓이면 데이터 품질이 무너진다.

무 DB — `database` 를 monkeypatch 해 SQL·파라미터·분기만 본다(test_auth_code 규약).
"""
from __future__ import annotations

import pytest

from server.services import company_request


class _Spy(list):
    """호출 기록(list) + 스텁 상태(state)를 함께 들고 다니는 컨테이너.

    `list` 는 속성 대입을 받지 않아 초판이 `calls.state = …` 로 터졌다 — 서브클래스로 연다."""

    state: dict


@pytest.fixture
def spy(monkeypatch):
    """`database.execute`/`fetch_one` 가로채기 — (sql, params) 수집 + 조회 결과 주입."""
    calls = _Spy()
    calls.state = {"existing": None, "pending_count": 0}

    async def _exec(sql, params=()):
        calls.append((sql, params))
        return 1

    async def _fetch_one(sql, params=()):
        calls.append((sql, params))
        if "COUNT(*)" in sql:
            return {"n": calls.state["pending_count"]}
        return calls.state["existing"]

    monkeypatch.setattr("server.database.execute", _exec)
    monkeypatch.setattr("server.database.fetch_one", _fetch_one)
    return calls


# ── URL 검증: 사용자 입력이 그대로 저장·표시된다 ────────────────────────────────
def test_CR1_accepts_http_and_https_only():
    """`http`/`https` 만 통과. 나머지 스킴은 **거부**한다.

    이 값은 저장됐다가 운영자에게 보여지고, 나중에 운영 화면이 생기면 링크가 될 수 있다.
    `javascript:`·`data:` 를 통과시키면 그 순간 저장형 XSS 벡터가 된다 — 지금 화면이 없다고
    미루면, 화면을 만드는 사람이 이 값을 안전하다고 오해한다."""
    assert company_request.normalize_url("https://example.com/careers") == "https://example.com/careers"
    assert company_request.normalize_url("http://example.com") == "http://example.com"
    for bad in (
        "javascript:alert(1)",
        "JavaScript:alert(1)",
        "  javascript:alert(1)  ",
        "data:text/html,<script>alert(1)</script>",
        "vbscript:msgbox(1)",
        "file:///etc/passwd",
        "//example.com/protocol-relative",
        "example.com",           # 스킴 없음
        "ftp://example.com",
    ):
        with pytest.raises(ValueError):
            company_request.normalize_url(bad)


def test_CR2_url_is_optional():
    """URL 은 **선택**이다 — 없다고 요청을 막지 않는다(사용자 결정)."""
    assert company_request.normalize_url(None) is None
    assert company_request.normalize_url("") is None
    assert company_request.normalize_url("   ") is None


def test_CR3_company_name_normalized_and_bounded():
    """회사명은 공백 정리 + 길이 상한. 제어문자는 제거한다(로그·터미널 오염 방지)."""
    assert company_request.normalize_name("  삼성  전자 ") == "삼성 전자"
    assert company_request.normalize_name("카카오\t\n뱅크") == "카카오 뱅크"
    with pytest.raises(ValueError):
        company_request.normalize_name("")
    with pytest.raises(ValueError):
        company_request.normalize_name("   ")
    with pytest.raises(ValueError):
        company_request.normalize_name("가" * 101)


# ── 저장 ─────────────────────────────────────────────────────────────────────
@pytest.mark.asyncio
async def test_CR4_submit_stores_name_and_url(spy):
    r = await company_request.submit(7, "테스트회사", "https://example.com/careers")
    assert r == "ok"
    ins = [(s, p) for s, p in spy if "INSERT" in s.upper() and "TCOMPANY_REQUEST" in s]
    assert ins, "요청이 저장되지 않았다"
    params = ins[0][1]
    assert 7 in params and "테스트회사" in params
    assert "https://example.com/careers" in params


@pytest.mark.asyncio
async def test_CR5_duplicate_pending_is_rejected(spy):
    """같은 회원이 같은 회사를 pending 으로 또 넣지 못한다 — 큐가 중복으로 부풀지 않게."""
    spy.state["existing"] = {"COMP_REQUEST_ID": 1}
    assert await company_request.submit(7, "테스트회사", None) == "dup"
    assert not [s for s, _ in spy if "INSERT" in s.upper()], "중복인데 INSERT 했다"


@pytest.mark.asyncio
async def test_CR5b_duplicate_check_is_case_and_space_insensitive(spy):
    """'테스트 회사' 와 '테스트회사' 를 다른 요청으로 취급하면 중복 방지가 무력해진다."""
    await company_request.submit(7, "  테스트  회사 ", None)
    sel = [p for s, p in spy if "SELECT" in s.upper() and "TCOMPANY_REQUEST" in s]
    assert sel and "테스트 회사" in sel[0], f"정규화된 이름으로 조회하지 않는다: {sel}"


@pytest.mark.asyncio
async def test_CR6_pending_cap_blocks_spam(spy):
    """한 회원의 pending 요청 수에 상한이 있다.

    로그인만 하면 누구나 요청할 수 있으므로, 상한이 없으면 한 계정이 큐를 무한정 채워
    운영자 검토를 마비시킬 수 있다(요청은 사람이 읽어야 하는 항목이라 특히 취약하다)."""
    spy.state["pending_count"] = company_request.MAX_PENDING_PER_MEMBER
    assert await company_request.submit(7, "또다른회사", None) == "too_many"
    assert not [s for s, _ in spy if "INSERT" in s.upper()]


@pytest.mark.asyncio
async def test_CR7_never_creates_a_company(spy):
    """**요청은 회사를 만들지 않는다**(사용자 결정: 승인은 무조건 운영자 판단).

    자동 생성하면 복지 0건짜리 빈 회사가 비교 서비스에 쌓인다."""
    await company_request.submit(7, "테스트회사", None)
    assert not [s for s, _ in spy if "TCOMPANY" in s and "TCOMPANY_REQUEST" not in s], (
        "요청 처리가 TCOMPANY 를 건드렸다 — 자동 등록 금지"
    )


# ── 라우터 계약 ───────────────────────────────────────────────────────────────
@pytest.mark.asyncio
async def test_CR8_router_maps_outcomes(monkeypatch):
    """202 pending / 409 중복 / 429 상한 — 사용자가 무엇을 해야 하는지 갈리는 값들이다."""
    from fastapi import HTTPException

    from server.routers import employment as router_mod

    body = type("B", (), {"comp_nm": "테스트회사", "ref_url": None})()

    async def _mk(outcome):
        async def _submit(mbr_id, name, url):
            return outcome
        monkeypatch.setattr(router_mod.company_request, "submit", _submit)

    await _mk("ok")
    resp = await router_mod.submit_company_request(body, type("R", (), {"headers": {}})(), None, {"MBR_ID": 7})
    assert resp["status"] == "pending"

    for outcome, code in (("dup", 409), ("too_many", 429)):
        await _mk(outcome)
        with pytest.raises(HTTPException) as exc:
            await router_mod.submit_company_request(body, type("R", (), {"headers": {}})(), None, {"MBR_ID": 7})
        assert exc.value.status_code == code
