"""메일 폭탄 쿨다운 — `+태그`·도트 변형 우회 차단 (적대검토 2026-07-27 확증 결함).

**막는 것**: `victim@gmail.com` / `victim+1@gmail.com` / `v.i.ctim@gmail.com` /
`VICTIM+9@Gmail.com` 은 전부 **같은 물리 수신함**에 배달되는데, 쿨다운 조회키
(`TAUTH_CODE.TARGET_HASH_VAL`)가 `strip().lower()` 만 거친 값의 해시라 다섯 변형의 해시가
전부 달랐다 → `recent_unconsumed_exists` 가 매번 미스 → 매번 INSERT + 실발송. 균일 204 계약
때문에 표적이 가입자일 필요도 없어, 단일 IP 로 특정 수신함에 폭탄을 넣을 수 있었다.

**계정 식별키와 분리**: 이 파일은 배달 주소 접기가 **계정 동일성**(`_normalize_email` →
`TMEMBER.LOGIN_EMAIL_NM`·`_hash_code` 스코프)까지 오염시키지 않는다는 것도 함께 못박는다 —
`+태그`를 별개 계정으로 쓰는 사용자는 계속 별개 계정이어야 한다.

무 DB — `database.execute`/`fetch_one` 을 인메모리 대역으로 monkeypatch 한다.

⚠ **대역이 모르는 SQL 을 만나면 통과시키지 말고 터뜨려야 한다.** 2026-07-30 에 배달주소 백오프
(P1-3)를 넣자 이 파일이 8/8 초록인 채로 **새 경로를 한 줄도 실행하지 않았다** — 백오프의
fail-open 이 대역의 `AssertionError` 를 삼켜 "상태 조회 실패 → 통과"로 처리했기 때문이다.
그래서 대역이 TMAIL_SEND_RATE 도 함께 모형화하고, 각 테스트가 **대역이 실제로 호출됐는지**
(`rate.calls`)를 함께 확인한다. 통과만 보는 어서션은 통과하는 이유를 구분하지 못한다(함정 ㉔).
"""
from __future__ import annotations

import pytest

from server.services import auth_code, employment


class _FakeSendRateTable:
    """TMAIL_SEND_RATE 인메모리 대역 — 주소당 (누적, 마지막발송, 창시작).

    시간은 흐르지 않는다(단조 카운터만 모형화). 그래서 "대기 시간이 지나면 다시 열린다"는
    검증은 여기서 못 하고, 순수 함수 `effective_cooldown_sec` 쪽에서 따로 한다.
    """

    def __init__(self) -> None:
        self.rows: dict[str, dict] = {}
        self.calls = 0  # 대역이 실제로 쓰였는가(거짓 초록 감지용)

    def sent(self, target: str) -> int:
        return self.rows.get(target, {}).get("SENT_CNT", 0)

    async def fetch_one(self, sql: str, params: tuple = ()):
        self.calls += 1
        target = params[0]
        return {"SENT_CNT": self.sent(target)}

    async def execute(self, sql: str, params: tuple = ()):
        self.calls += 1
        target = params[0]
        if sql.startswith("INSERT INTO TMAIL_SEND_RATE"):
            self.rows.setdefault(target, {"SENT_CNT": 0, "blocked": False})
            return 1
        if "SET SENT_CNT = 0" in sql:  # 창 되감기 — 시간이 안 흐르므로 no-op
            return 0
        # 소비: 대기(wait)가 0 이면 언제나 통과, 0 보다 크면 "직전에 보냈다"는 뜻이라 차단.
        # 시간이 흐르지 않는 대역에서 `LAST_SENT_DTM <= now - wait` 는 wait>0 이면 항상 거짓이다.
        wait = params[1]
        row = self.rows.setdefault(target, {"SENT_CNT": 0})
        if wait > 0 and row["SENT_CNT"] > 0:
            return 0
        row["SENT_CNT"] += 1
        return 1


class _FakeAuthCodeTable:
    """TAUTH_CODE 인메모리 대역 — 발급 경로(쿨다운 조회 + INSERT)만 처리한다.

    TMAIL_SEND_RATE 로 가는 문장은 `rate` 대역에 넘긴다. **모르는 SQL 은 assert 로 터진다** —
    조용히 통과시키면 새 쿼리가 생겨도 아무도 모른다."""

    def __init__(self, rate: _FakeSendRateTable) -> None:
        self.rows: list[dict] = []
        self.rate = rate

    async def fetch_one(self, sql: str, params: tuple = ()):
        if "TMAIL_SEND_RATE" in sql:
            return await self.rate.fetch_one(sql, params)
        if "TMAIL_SUPPRESSION" in sql:
            return None  # 억제된 주소 없음. 여기서 안 받으면 is_suppressed 가 예외를 삼켜
            #              "억제 조회 실패"로 흘러가고, 그 경로가 테스트에서 상시 발동한다.
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
        if "TMAIL_SEND_RATE" in sql:
            return await self.rate.execute(sql, params)
        assert "INSERT INTO TAUTH_CODE" in sql, f"예상 밖 실행: {sql!r}"
        if "'login'" in sql:  # (code_hash, target_hash, ttl)
            self.rows.append({"PURPOSE_CD": "login", "CODE_HASH_VAL": params[0],
                              "TARGET_HASH_VAL": params[1], "COMP_ID": None})
        else:  # 재직: (purpose, code_hash, target_hash, comp, mbr, ttl)
            self.rows.append({"PURPOSE_CD": params[0], "CODE_HASH_VAL": params[1],
                              "TARGET_HASH_VAL": params[2], "COMP_ID": params[3]})
        return 1


@pytest.fixture
def rate_table():
    """TMAIL_SEND_RATE 대역 — `code_table` 이 물고 들어가며, 테스트가 직접 들여다볼 수도 있다."""
    return _FakeSendRateTable()


@pytest.fixture
def code_table(monkeypatch, rate_table):
    """TAUTH_CODE + TMAIL_SEND_RATE 대역 + 발송 캡처 메일러. 반환=(테이블, 발송목록)."""
    from server import mailer

    table = _FakeAuthCodeTable(rate_table)
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
async def test_MB4_로그인코드_쿨다운이_플러스태그_도트_변형_폭탄을_막는다(code_table, rate_table):
    """다섯 변형을 연속 요청해도 실제 발송·저장은 **1건**이어야 한다(쿨다운 창 안)."""
    table, sent = code_table
    for 변형 in _같은_수신함_변형:
        await auth_code.issue_login_code(변형)
    assert len(table.rows) == 1, f"쿨다운 우회 — 코드 {len(table.rows)}건 발급됨"
    assert len(sent) == 1, f"쿨다운 우회 — 메일 {len(sent)}통 발송됨"
    # 대역이 실제로 쓰였는가 — 이 줄이 없으면 백오프가 fail-open 으로 조용히 통과해도
    # 위 두 어서션은 그대로 초록이다(2026-07-30 실발현).
    assert rate_table.calls > 0, "TMAIL_SEND_RATE 대역이 한 번도 호출되지 않았다 — fail-open 의심"


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


# ── MB-7~11: 배달주소 기준 발송 백오프 (P1-3, SP-AUTH-18 — 2026-07-30) ──────────────
#
# 쿨다운은 "창당 1통"만 보장하므로 60초 창에서 1,440통/일이 지나갔다. 여기서 재는 것은
# 그 하루치 총량이 실제로 눌리는가, 그리고 **누르다가 완전히 잠가 버리지는 않는가**다.


def test_MB7_버스트_구간에서는_주소_단위_제약이_없다():
    """허용 버스트 안에서는 대기 0 — 현행 동작을 한 글자도 바꾸지 않는다는 계약.

    새 방어를 넣을 때 가장 흔한 사고가 "정상 사용자까지 같이 느려지는 것"이다.
    버스트 구간이 0 이어야 기존 MB-4·MB-5 의 의미도 그대로 유지된다."""
    s = auth_code.get_settings()
    for n in range(s.mail_burst_free_sends):
        assert auth_code.effective_cooldown_sec(n) == 0, f"{n}번째에서 이미 대기가 생겼다"


def test_MB8_버스트_이후_대기가_2배씩_늘고_상한에서_멈춘다():
    """지수 백오프의 두 성질 — 실제로 늘어나는가, 그리고 무한히 늘지는 않는가."""
    s = auth_code.get_settings()
    free, base, cap = s.mail_burst_free_sends, s.mail_resend_cooldown_sec, s.mail_cooldown_max_sec
    assert auth_code.effective_cooldown_sec(free) == base
    assert auth_code.effective_cooldown_sec(free + 1) == base * 2
    assert auth_code.effective_cooldown_sec(free + 2) == base * 4
    # 상한: 아무리 두들겨도 이 값을 넘지 않는다. 공격자에게 물리는 벌이자
    # **정당한 사용자가 겪을 최대 대기**이기도 하다.
    assert auth_code.effective_cooldown_sec(free + 100) == cap
    assert auth_code.effective_cooldown_sec(10**9) == cap  # 지수 폭주 없음


def test_MB9_하루_총량이_실제로_눌린다():
    """이 방어가 **무엇을 얼마나** 줄이는지 수치로 못박는다.

    "위반이 없다"만 재는 테스트는 방어가 통째로 빠져도 초록이다(함정 ㉙). 그래서 백오프를
    실제로 적분해 하루에 몇 통이 가능한지 세고, 그 수가 무방비(1,440통)보다 **한 자릿수 이상**
    작은지 본다. 상수를 바꾸면 이 테스트가 그 대가를 즉시 보여 준다."""
    s = auth_code.get_settings()
    무방비 = 86400 // s.mail_resend_cooldown_sec  # 쿨다운만 있을 때: 1,440통/일

    남은초, 보낸통수 = 86400, 0
    while True:
        대기 = auth_code.effective_cooldown_sec(보낸통수)
        # 버스트 구간(대기 0)도 용도별 쿨다운 60초는 그대로 걸린다 — 그게 현실의 하한이다.
        대기 = max(대기, s.mail_resend_cooldown_sec)
        if 대기 > 남은초:
            break
        남은초 -= 대기
        보낸통수 += 1

    assert 보낸통수 < 무방비 / 10, f"하루 {보낸통수}통 — 무방비({무방비})의 1/10 밑으로 못 눌렀다"
    assert 보낸통수 > 0, "한 통도 못 보낸다 — 이건 방어가 아니라 서비스 중단이다"


def test_MB10_아무리_두들겨도_영구_차단은_되지_않는다():
    """**반대 방향 사고 금지.** 제3자가 예산을 태워도 피해자는 언젠가 반드시 코드를 받는다.

    하드 상한이었다면 이 성질이 깨진다 — 그래서 하드 상한을 쓰지 않았다. 이 테스트가 그
    설계 결정의 감시자다. 누군가 나중에 `effective_cooldown_sec` 를 "N 이상이면 무한대"로
    바꾸면 여기서 걸린다."""
    s = auth_code.get_settings()
    최대대기 = max(auth_code.effective_cooldown_sec(n) for n in (0, 1, 5, 50, 5000, 10**9))
    assert 최대대기 == s.mail_cooldown_max_sec
    assert 최대대기 < 86400, "하루를 넘는 대기는 사실상 그날의 잠금이다"


@pytest.mark.asyncio
async def test_MB11_회사를_바꿔도_같은_수신함이면_백오프가_따라온다(code_table, rate_table, monkeypatch):
    """재직 쿨다운은 **회사별 스코프**라 회사를 갈아타면 N배로 우회됐다.

    배달주소 백오프는 회사와 무관하게 수신함 하나를 기준으로 세므로 그 곱셈을 닫는다.
    여기서는 버스트를 0 으로 낮춰 첫 발송부터 백오프가 걸리게 만든다(대역엔 시간이 흐르지
    않으므로 "대기 중"만 재현된다)."""
    table, sent = code_table
    s = auth_code.get_settings()
    monkeypatch.setattr(s, "mail_burst_free_sends", 0)

    for comp_id in (10, 20, 30, 40):
        await employment.issue_employ_code(comp_id, 1, "worker@corp.com")

    assert len(sent) == 1, f"회사를 갈아타 백오프를 우회했다 — {len(sent)}통 발송됨"
    assert len(table.rows) == 1, "발송하지 않았는데 코드 행이 생겼다(쿨다운을 이중으로 잡아먹는다)"


@pytest.mark.asyncio
async def test_MB12_상태_조회가_실패하면_발송을_막지_않는다(monkeypatch, caplog):
    """fail-open 계약 — 그리고 **조용히 열리지는 않는다**.

    백오프는 보안 경계가 아니라 남용 완화다. 상태 조회 장애가 곧 전면 로그인 장애가 되면
    그게 더 큰 사고다. 다만 조용히 열리면 보호가 사라진 줄도 모르므로 경고를 남긴다.
    (결함을 심어 그 경로가 실제로 도는지 확인한다 — 함정 ㉔·SED-6.)"""
    async def 터지는_execute(sql, params=()):
        raise RuntimeError("DB 장애 모의")

    monkeypatch.setattr(auth_code.database, "execute", 터지는_execute)
    with caplog.at_level("ERROR"):
        허용 = await auth_code.try_consume_send_slot("f" * 64)
    assert 허용 is True, "상태 조회 실패가 발송을 막았다 — 조회 장애가 로그인 장애가 된다"
    assert any("fail-open" in r.message for r in caplog.records), "열어 주면서 흔적을 안 남겼다"
