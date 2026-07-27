"""메일 폭탄 쿨다운 — `+태그`·도트 변형 우회 차단 (적대검토 2026-07-27 확증 결함).

**막는 것**: `victim@gmail.com` / `victim+1@gmail.com` / `v.i.ctim@gmail.com` /
`VICTIM+9@Gmail.com` 은 전부 **같은 물리 수신함**에 배달되는데, 쿨다운 조회키
(`TAUTH_CODE.TARGET_HASH_VAL`)가 `strip().lower()` 만 거친 값의 해시라 다섯 변형의 해시가
전부 달랐다 → `recent_unconsumed_exists` 가 매번 미스 → 매번 INSERT + 실발송. 균일 204 계약
때문에 표적이 가입자일 필요도 없어, 단일 IP 로 특정 수신함에 폭탄을 넣을 수 있었다.

**계정 식별키와 분리**: 이 파일은 배달 주소 접기가 **계정 동일성**(`_normalize_email` →
`TMEMBER.LOGIN_EMAIL_NM`·`_hash_code` 스코프)까지 오염시키지 않는다는 것도 함께 못박는다 —
`+태그`를 별개 계정으로 쓰는 사용자는 계속 별개 계정이어야 한다.

무 DB — `database.execute`/`fetch_one` 을 TAUTH_CODE 인메모리 대역으로 monkeypatch 한다.
"""
from __future__ import annotations

import pytest

from server.services import auth_code, employment


class _FakeAuthCodeTable:
    """TAUTH_CODE 인메모리 대역 — 발급 경로(쿨다운 조회 + INSERT)만 처리한다."""

    def __init__(self) -> None:
        self.rows: list[dict] = []

    async def fetch_one(self, sql: str, params: tuple = ()):
        # 발급 경로에서 오는 조회는 쿨다운 검사뿐(INS_DTM 창 조건)
        assert "FROM TAUTH_CODE" in sql and "INS_DTM" in sql, f"예상 밖 조회: {sql!r}"
        target, purpose = params[0], params[1]
        comp = params[2] if len(params) == 4 else None  # 로그인=(target,purpose,cooldown)
        hit = any(
            r["TARGET_HASH_VAL"] == target and r["PURPOSE_CD"] == purpose and r["COMP_ID"] == comp
            for r in self.rows
        )
        return {"x": 1} if hit else None

    async def execute(self, sql: str, params: tuple = ()):
        assert "INSERT INTO TAUTH_CODE" in sql, f"예상 밖 실행: {sql!r}"
        if "'login'" in sql:  # (code_hash, target_hash, ttl)
            self.rows.append({"PURPOSE_CD": "login", "CODE_HASH_VAL": params[0],
                              "TARGET_HASH_VAL": params[1], "COMP_ID": None})
        else:  # 재직: (purpose, code_hash, target_hash, comp, mbr, ttl)
            self.rows.append({"PURPOSE_CD": params[0], "CODE_HASH_VAL": params[1],
                              "TARGET_HASH_VAL": params[2], "COMP_ID": params[3]})
        return 1


@pytest.fixture
def code_table(monkeypatch):
    """TAUTH_CODE 대역 + 발송 캡처 메일러. 반환=(테이블, 발송목록)."""
    from server import mailer

    table = _FakeAuthCodeTable()
    sent: list[tuple[str, str]] = []

    class _CaptureMailer:
        async def send_login_code(self, email, code):
            sent.append((email, code))

        async def send_employ_code(self, email, code):
            sent.append((email, code))

    monkeypatch.setattr(auth_code.database, "fetch_one", table.fetch_one)
    monkeypatch.setattr(auth_code.database, "execute", table.execute)
    monkeypatch.setattr(mailer, "get_mailer", lambda: _CaptureMailer())
    return table, sent


# 같은 수신함에 배달되는 다섯 변형(적대검토가 실측한 그 목록)
_같은_수신함_변형 = [
    "victim@gmail.com",
    "victim+1@gmail.com",
    "victim+2@gmail.com",
    "v.i.ctim@gmail.com",
    "VICTIM+9@Gmail.com",
]


# ── MB-1~3: 배달 주소 정규화 자체 ────────────────────────────────────────────────

def test_MB1_같은_수신함_변형은_모두_같은_조회키로_접힌다():
    """`+태그`·도트·대소문자 변형은 배달 주소가 같으므로 TARGET_HASH_VAL 도 같아야 한다."""
    해시들 = {auth_code._hash_target(e) for e in _같은_수신함_변형}
    assert len(해시들) == 1, f"같은 수신함인데 조회키가 갈렸다: {해시들}"
    # googlemail.com 은 gmail.com 의 도메인 별칭 — 같은 수신함이다.
    assert auth_code._hash_target("victim@googlemail.com") == 해시들.pop()


def test_MB2_지메일_외_도메인은_도트를_보존한다():
    """도트가 유의미한 제공자가 있다 — 도트 제거는 구글 계열로만 한정한다.

    전 도메인에 도트를 지우면 `v.ictim@naver.com` 과 `victim@naver.com`(서로 다른 사람)이
    한 쿨다운 통에 묶여, 무관한 제3자의 코드 발송이 막히는 반대 방향 사고가 된다."""
    assert auth_code._hash_target("v.ictim@naver.com") != auth_code._hash_target("victim@naver.com")
    # 반면 `+태그` 서브어드레싱(RFC 5233)은 제공자 공통이라 도메인 무관하게 접는다.
    assert auth_code._hash_target("victim+x@naver.com") == auth_code._hash_target("victim@naver.com")


def test_MB3_계정_식별키는_배달주소_접기에_오염되지_않는다():
    """계정 동일성은 현행 `strip().lower()` 유지 — `+태그` 별개 계정 사용자를 깨뜨리지 않는다."""
    assert auth_code._normalize_email(" Victim+1@Gmail.com ") == "victim+1@gmail.com"
    assert auth_code._normalize_email("v.i.ctim@gmail.com") == "v.i.ctim@gmail.com"
    # 코드 해시는 계정 식별키로 스코프되므로, 같은 수신함이라도 계정이 다르면 코드가 호환되지 않는다.
    assert auth_code._hash_code("123456", "victim@gmail.com") != auth_code._hash_code("123456", "victim+1@gmail.com")


# ── MB-4~5: 발급 경로 쿨다운(확증 결함 재현) ──────────────────────────────────────

@pytest.mark.asyncio
async def test_MB4_로그인코드_쿨다운이_플러스태그_도트_변형_폭탄을_막는다(code_table):
    """다섯 변형을 연속 요청해도 실제 발송·저장은 **1건**이어야 한다(쿨다운 창 안)."""
    table, sent = code_table
    for 변형 in _같은_수신함_변형:
        await auth_code.issue_login_code(변형)
    assert len(table.rows) == 1, f"쿨다운 우회 — 코드 {len(table.rows)}건 발급됨"
    assert len(sent) == 1, f"쿨다운 우회 — 메일 {len(sent)}통 발송됨"


@pytest.mark.asyncio
async def test_MB4_다른_수신함은_쿨다운에_걸리지_않는다(code_table):
    """접기가 과하면 무관한 사용자를 막는다 — 다른 수신함은 정상 발급되어야 한다."""
    table, sent = code_table
    await auth_code.issue_login_code("victim@gmail.com")
    await auth_code.issue_login_code("other@gmail.com")
    await auth_code.issue_login_code("victim@naver.com")
    assert len(table.rows) == 3 and len(sent) == 3


@pytest.mark.asyncio
async def test_MB5_재직인증코드_쿨다운도_같은_변형_폭탄을_막는다(code_table):
    """재직 인증 발급도 동일 조회키 구조 — 회사 이메일 폭탄에 같은 우회가 있었다."""
    table, sent = code_table
    for 변형 in ["worker@gmail.com", "worker+1@gmail.com", "w.o.rker@gmail.com", "WORKER+9@Gmail.com"]:
        await employment.issue_employ_code(10, 1, 변형)
    assert len(table.rows) == 1, f"쿨다운 우회 — 재직 코드 {len(table.rows)}건 발급됨"
    assert len(sent) == 1, f"쿨다운 우회 — 재직 메일 {len(sent)}통 발송됨"


@pytest.mark.asyncio
async def test_MB5_재직_쿨다운은_회사별_스코프를_유지한다(code_table):
    """회사 스코프는 그대로 — 다른 회사 인증까지 막으면 정상 흐름이 깨진다."""
    table, sent = code_table
    await employment.issue_employ_code(10, 1, "worker@corp.com")
    await employment.issue_employ_code(20, 1, "worker@corp.com")
    assert len(table.rows) == 2 and len(sent) == 2


# ── MB-6: 접기 실패 안전판 ───────────────────────────────────────────────────────

def test_MB6_로컬파트가_비는_변형은_도메인_전체로_접히지_않는다():
    """`+tag@x.com` 처럼 접은 결과가 빈 로컬파트가 되면 원본 로컬파트를 유지한다.

    그러지 않으면 `+a@x.com`·`+b@x.com` 이 모두 `@x.com` 한 통으로 묶여, 한 명이
    그 도메인 전체의 코드 발송을 쿨다운으로 잠그는 반대 방향 사고가 난다."""
    assert auth_code._hash_target("+a@gmail.com") != auth_code._hash_target("+b@gmail.com")
    assert auth_code._hash_target("...@gmail.com") != auth_code._hash_target("+a@gmail.com")
