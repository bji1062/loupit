"""P1-3 배달주소 백오프 — **실 DB** 계약 (SR-1~SR-6, SP-AUTH-18).

**왜 대역 테스트로 부족한가.** `test_mail_bomb_cooldown.py` 의 인메모리 대역은 시간이 흐르지
않고 SQL 을 해석하지도 않는다. 그래서 이 기능의 핵심 세 가지를 원리적으로 검증할 수 없다.

1. **원자성** — 동시 요청 둘이 같은 누적을 읽어도 발송은 한 번만 나가는가. 직렬화기는
   Python 이 아니라 마지막 UPDATE 의 `LAST_SENT_DTM` 조건이다.
2. **rowcount 의 의미** — MySQL 은 matched 가 아니라 **changed** 를 돌려준다는 전제 위에
   "0행 = 백오프 중" 판정이 서 있다. `CLIENT_FOUND_ROWS` 가 켜지면 이 판정이 통째로 뒤집힌다
   (함정 ㊵: 모드에 따라 뜻이 달라지는 값). SR-2 가 그 전제를 직접 못박는다.
3. **시간** — 창 되감기와 퍼지는 실제 DATETIME 비교로만 확인된다.

⚠ 이 파일은 `DB_NAME` 이 가리키는 DB 에 실제로 쓴다. conftest 의 서빙 스키마 가드가
   맨 pytest 직접 실행을 `loupit_test` 로 제한한다.
"""

from __future__ import annotations

import asyncio

import pytest
import pytest_asyncio

from server import database
from server.services import auth_code

TARGET_A = "a" * 64
TARGET_B = "b" * 64


@pytest_asyncio.fixture
async def real_db(schema_db):
    """실제 aiomysql 풀 — `schema_db` 가 db/schema.sql 을 적용한 뒤에만 연다.

    이 리포에서 비동기 실 DB 를 쓰는 첫 픽스처다. 다른 테스트들은 풀을 no-op 으로 막고
    `database.execute` 를 monkeypatch 하는데, 그 방식으로는 SQL 자체를 검증할 수 없다."""
    await database.init_pool()
    await database.execute("DELETE FROM TMAIL_SEND_RATE")
    try:
        yield
    finally:
        await database.execute("DELETE FROM TMAIL_SEND_RATE")
        await database.close_pool()


async def _state(target: str) -> dict | None:
    return await database.fetch_one(
        "SELECT SENT_CNT, WINDOW_START_DTM, LAST_SENT_DTM "
        "FROM TMAIL_SEND_RATE WHERE TARGET_HASH_VAL=%s",
        (target,),
    )


@pytest.mark.asyncio
async def test_SR1_버스트_구간은_연속_통과하며_카운터만_오른다(real_db):
    """대기 0 구간에서는 조건이 항상 참이라 그대로 통과한다 — 기존 동작 불변의 실증."""
    s = auth_code.get_settings()
    for i in range(s.mail_burst_free_sends):
        assert await auth_code.try_consume_send_slot(TARGET_A) is True, f"{i}번째가 막혔다"
    row = await _state(TARGET_A)
    assert row["SENT_CNT"] == s.mail_burst_free_sends
    assert row["LAST_SENT_DTM"] is not None


@pytest.mark.asyncio
async def test_SR2_버스트를_넘기면_즉시_재요청이_막힌다(real_db):
    """백오프 발동 — 그리고 **막혔을 때 카운터가 오르지 않는다**.

    보내지 않은 요청이 카운터를 태우면, 두들길수록 대기가 늘어 사실상 영구 차단이 된다.
    `SENT_CNT` 는 '발송한 횟수'여야지 '요청받은 횟수'가 아니다.
    """
    s = auth_code.get_settings()
    for _ in range(s.mail_burst_free_sends):
        assert await auth_code.try_consume_send_slot(TARGET_A) is True

    assert await auth_code.try_consume_send_slot(TARGET_A) is False, "백오프가 발동하지 않았다"
    막힌뒤 = await _state(TARGET_A)
    assert 막힌뒤["SENT_CNT"] == s.mail_burst_free_sends, "막힌 요청이 카운터를 태웠다"

    # 한 번 더 두들겨도 여전히 그대로 — 반복 요청이 대기를 스스로 늘리지 않는다.
    assert await auth_code.try_consume_send_slot(TARGET_A) is False
    assert (await _state(TARGET_A))["SENT_CNT"] == s.mail_burst_free_sends


@pytest.mark.asyncio
async def test_SR3_동시_요청이어도_한_번만_통과한다(real_db, monkeypatch):
    """원자성 — 직렬화기는 Python 이 아니라 UPDATE 의 WHERE 조건이다.

    버스트를 0 으로 낮춰 첫 요청부터 대기가 걸리게 한 뒤 동시에 두들긴다. 대역 테스트로는
    잡을 수 없는 축이다(동시성이 없으므로).
    """
    s = auth_code.get_settings()
    monkeypatch.setattr(s, "mail_burst_free_sends", 0)

    결과 = await asyncio.gather(*(auth_code.try_consume_send_slot(TARGET_B) for _ in range(8)))
    assert sum(결과) == 1, f"동시 8건 중 {sum(결과)}건이 통과했다 — 원자성이 깨졌다"
    assert (await _state(TARGET_B))["SENT_CNT"] == 1


@pytest.mark.asyncio
async def test_SR4_창이_지나면_카운터가_되감긴다(real_db, monkeypatch):
    """롤링 창 — 창 시작을 과거로 밀어 두면 다음 호출이 SENT_CNT 를 0으로 되감아야 한다."""
    s = auth_code.get_settings()
    for _ in range(s.mail_burst_free_sends):
        await auth_code.try_consume_send_slot(TARGET_A)
    assert await auth_code.try_consume_send_slot(TARGET_A) is False  # 백오프 중

    # 창 시작과 마지막 발송을 창 길이보다 더 과거로 — "시간이 흘렀다"를 DB 시각으로 재현한다.
    await database.execute(
        "UPDATE TMAIL_SEND_RATE SET WINDOW_START_DTM = UTC_TIMESTAMP() - INTERVAL %s HOUR, "
        "LAST_SENT_DTM = UTC_TIMESTAMP() - INTERVAL %s HOUR WHERE TARGET_HASH_VAL=%s",
        (s.mail_rate_window_hours + 1, s.mail_rate_window_hours + 1, TARGET_A),
    )
    assert await auth_code.try_consume_send_slot(TARGET_A) is True, "창이 지났는데 여전히 막혔다"
    assert (await _state(TARGET_A))["SENT_CNT"] == 1, "되감기 후 카운터가 1부터 시작하지 않았다"


@pytest.mark.asyncio
async def test_SR5_퍼지는_보존기간_밖만_지운다(real_db):
    """퍼지가 백오프 **중인** 주소를 지우면 퍼지 자체가 우회 수단이 된다.

    보존(7일)이 창(24시간)보다 길다는 설정 불변식이 실제로 그 결과를 내는지 확인한다.
    """
    s = auth_code.get_settings()
    assert s.mail_rate_retention_days * 24 > s.mail_rate_window_hours, (
        "보존이 창보다 짧다 — 퍼지가 백오프를 되감아 우회 수단이 된다"
    )
    await auth_code.try_consume_send_slot(TARGET_A)  # 방금 보낸 주소
    await auth_code.try_consume_send_slot(TARGET_B)
    await database.execute(  # B 만 보존기간 밖으로 밀어 둔다
        "UPDATE TMAIL_SEND_RATE SET WINDOW_START_DTM = UTC_TIMESTAMP() - INTERVAL %s DAY, "
        "LAST_SENT_DTM = UTC_TIMESTAMP() - INTERVAL %s DAY WHERE TARGET_HASH_VAL=%s",
        (s.mail_rate_retention_days + 1, s.mail_rate_retention_days + 1, TARGET_B),
    )

    지운수 = await auth_code.purge_send_rate(s.mail_rate_retention_days)
    assert 지운수 == 1, f"{지운수}행 삭제 — 기대 1행(오래된 B 만)"
    assert await _state(TARGET_A) is not None, "방금 쓴 주소를 지웠다 — 백오프가 사라진다"
    assert await _state(TARGET_B) is None


@pytest.mark.asyncio
async def test_SR6_주소마다_독립이다(real_db, monkeypatch):
    """접기가 과하면 무관한 사용자를 막는다(반대 방향 사고). 다른 수신함은 영향 없어야 한다."""
    s = auth_code.get_settings()
    monkeypatch.setattr(s, "mail_burst_free_sends", 0)
    assert await auth_code.try_consume_send_slot(TARGET_A) is True
    assert await auth_code.try_consume_send_slot(TARGET_A) is False  # A 는 백오프
    assert await auth_code.try_consume_send_slot(TARGET_B) is True, "무관한 주소가 함께 막혔다"
