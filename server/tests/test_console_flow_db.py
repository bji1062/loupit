"""SP-AUTH-19 운영 콘솔 — **실 DB** 승인 흐름과 감사 주입 (CF-1~CF-7).

`test_console_gate.py` 는 관문과 표면을 순수 함수로 잰다. 여기서 재는 것은 그 뒤 —
**권한이 통과했을 때 실제로 무엇이 DB 에 남는가**다. 그리고 그게 이 기능의 존재 이유다.

> 지금 `DECIDED_BY_ID` 는 CLI 가 `--by N` 으로 사람이 손으로 넣는 값이고 FK 도 검증도 없다.
> **현재 감사 기록은 자율신고다.** 세션에서 자동 주입돼야 비로소 감사가 성립한다.

CF-4 가 그 축을 직접 잰다: 결정 후 `DECIDED_BY_ID` 가 **운영자 세션의 MBR_ID 와 같은가**.

⚠ 이 파일은 `DB_NAME` 이 가리키는 DB 에 실제로 쓴다(conftest 가드가 `loupit_test` 로 제한).
"""

from __future__ import annotations

import pytest
import pytest_asyncio
from fastapi import HTTPException

from server import database, deps
from server.services import operator

OP_EMAIL = "console-operator@example.com"
OTHER_EMAIL = "console-outsider@example.com"


@pytest_asyncio.fixture
async def flow(schema_db, monkeypatch):
    """운영자 1명 · 비운영자 1명 · 회사 1개 · 대기 요청 3종을 심는다.

    `schema_db` 가 db/schema.sql 을 적용한 뒤 실제 aiomysql 풀을 연다(SR-* 와 같은 방식).
    """
    from server.config import get_settings

    await database.init_pool()
    monkeypatch.setattr(get_settings(), "operator_emails", OP_EMAIL)

    async def _clean():
        for t in ("TEMPLOY_VERIFICATION", "TEMPLOY_VRF_REQUEST", "TCOMPANY_REQUEST",
                  "TMAIL_SUPPRESSION", "TMEMBER", "TCOMPANY", "TCOMPANY_TYPE"):
            await database.execute(f"DELETE FROM {t}")

    await _clean()
    await database.execute(
        "INSERT INTO TMEMBER (LOGIN_EMAIL_NM, NICKNAME_NM) VALUES (%s, 'op'), (%s, 'outsider')",
        (OP_EMAIL, OTHER_EMAIL),
    )
    ids = {r["LOGIN_EMAIL_NM"]: r["MBR_ID"] for r in
           await database.fetch_all("SELECT MBR_ID, LOGIN_EMAIL_NM FROM TMEMBER")}
    await database.execute(
        "INSERT INTO TCOMPANY_TYPE (COMP_TP_CD, COMP_TP_NM) VALUES ('testtype', '테스트유형')"
    )
    tp = (await database.fetch_one("SELECT COMP_TP_ID FROM TCOMPANY_TYPE LIMIT 1"))["COMP_TP_ID"]
    await database.execute(
        "INSERT INTO TCOMPANY (COMP_NM, COMP_ENG_NM, COMP_TP_ID) VALUES ('테스트사','testco',%s)", (tp,)
    )
    comp = (await database.fetch_one("SELECT COMP_ID FROM TCOMPANY LIMIT 1"))["COMP_ID"]
    await database.execute(
        "INSERT INTO TEMPLOY_VRF_REQUEST (MBR_ID, COMP_ID, EVIDENCE_CTNT) VALUES (%s, %s, %s)",
        (ids[OTHER_EMAIL], comp, "<img src=x onerror=alert(1)> 사원증 사진"),
    )
    await database.execute(
        "INSERT INTO TCOMPANY_REQUEST (MBR_ID, REQ_COMP_NM, REF_URL_CTNT) VALUES (%s, %s, %s)",
        (ids[OTHER_EMAIL], "없는회사", "https://example.com/careers"),
    )
    await database.execute(
        "INSERT INTO TMAIL_SUPPRESSION (TARGET_HASH_VAL, REASON_CD) VALUES (%s, 'hard_bounce')",
        ("c" * 64,),
    )
    vrf = (await database.fetch_one("SELECT VRF_REQUEST_ID FROM TEMPLOY_VRF_REQUEST LIMIT 1"))
    creq = (await database.fetch_one("SELECT COMP_REQUEST_ID FROM TCOMPANY_REQUEST LIMIT 1"))
    try:
        yield {"op": ids[OP_EMAIL], "outsider": ids[OTHER_EMAIL], "comp": comp,
               "vrf_req": vrf["VRF_REQUEST_ID"], "comp_req": creq["COMP_REQUEST_ID"]}
    finally:
        await _clean()
        await database.close_pool()


# ── CF-1~3: 관문이 실제 세션·회원 상태를 본다 ─────────────────────────────────

@pytest.mark.asyncio
async def test_CF1_운영자_세션은_통과하고_이메일을_함께_돌려준다(flow):
    """반환에 `LOGIN_EMAIL_NM` 이 있어야 콘솔이 '누구로 로그인했는지'를 보여줄 수 있다."""
    row = await deps.require_operator({"MBR_ID": flow["op"]})
    assert row["MBR_ID"] == flow["op"]
    assert row["LOGIN_EMAIL_NM"] == OP_EMAIL


@pytest.mark.asyncio
async def test_CF2_비운영자_세션은_404다(flow):
    """403 이 아니다 — 로그인은 됐지만 운영자가 아닌 사람에게도 존재를 알리지 않는다."""
    with pytest.raises(HTTPException) as exc:
        await deps.require_operator({"MBR_ID": flow["outsider"]})
    assert exc.value.status_code == 404


@pytest.mark.asyncio
async def test_CF3_탈퇴하면_운영자_권한도_함께_사라진다(flow):
    """화이트리스트에 남아 있어도 계정이 죽으면 권한이 없다.

    `.env` 를 고치는 것을 잊어도 계정 상태가 먼저 막는다 — 두 축이 **AND** 로 걸린다."""
    await database.execute(
        "UPDATE TMEMBER SET STATUS_CD='withdrawn' WHERE MBR_ID=%s", (flow["op"],))
    assert operator.is_operator(OP_EMAIL) is True  # 화이트리스트에는 여전히 있다
    with pytest.raises(HTTPException) as exc:
        await deps.require_operator({"MBR_ID": flow["op"]})
    assert exc.value.status_code == 404


# ── CF-4: **이 기능의 존재 이유** — 감사가 자율신고를 벗어났는가 ────────────────

@pytest.mark.asyncio
async def test_CF4_승인은_결정자를_세션에서_기록한다(flow):
    """`DECIDED_BY_ID` == 운영자 세션의 `MBR_ID`.

    CLI 는 이 값을 `--by N` 으로 사람이 넣고 FK 도 검증도 없다 — 아무 숫자나 들어간다.
    콘솔이 주는 이득은 처리 편의가 아니라 **이 한 줄이 진짜가 되는 것**이다."""
    op = await deps.require_operator({"MBR_ID": flow["op"]})
    assert await operator.approve_verification(flow["vrf_req"], op["MBR_ID"], "확인함") == "approved"

    req = await database.fetch_one(
        "SELECT STATUS_CD, DECIDED_BY_ID, DECIDED_DTM, DECIDE_NOTE_CTNT "
        "FROM TEMPLOY_VRF_REQUEST WHERE VRF_REQUEST_ID=%s", (flow["vrf_req"],))
    assert req["STATUS_CD"] == "approved"
    assert req["DECIDED_BY_ID"] == flow["op"], "결정자가 세션에서 오지 않았다 — 감사가 여전히 자율신고다"
    assert req["DECIDED_DTM"] is not None
    assert req["DECIDE_NOTE_CTNT"] == "확인함"

    # 인증이 실제로 생겼는가 — 상태만 바뀌고 인증이 없으면 사용자는 승인 통보를 받고도 못 쓴다.
    vrf = await database.fetch_one(
        "SELECT VRF_METHOD_CD, INS_ID FROM TEMPLOY_VERIFICATION WHERE MBR_ID=%s AND COMP_ID=%s",
        (flow["outsider"], flow["comp"]))
    assert vrf["VRF_METHOD_CD"] == "manual"
    assert vrf["INS_ID"] == flow["op"], "인증 행의 입력자도 운영자여야 추적이 이어진다"


@pytest.mark.asyncio
async def test_CF5_두_번_결정할_수_없다(flow):
    """`AND STATUS_CD='pending'` 가드 — 이게 빠지면 `DECIDED_DTM` 이 마지막 것만 남아
    "누가 언제 처음 결정했는가"를 잃는다. CLI 와 **같은 SQL** 을 쓰므로 양쪽이 함께 지켜진다."""
    op = await deps.require_operator({"MBR_ID": flow["op"]})
    assert await operator.approve_verification(flow["vrf_req"], op["MBR_ID"], None) == "approved"
    assert await operator.approve_verification(flow["vrf_req"], op["MBR_ID"], None) == "not_pending"
    assert await operator.reject_verification(flow["vrf_req"], op["MBR_ID"], None) is False


@pytest.mark.asyncio
async def test_CF6_회사_등록_요청_승인은_회사를_만들지_않는다(flow):
    """🚨 상태만 바뀐다. 실제 등록은 db/seed 작업 + 정적 사이트 재생성이다(SP-AUTH-17).

    여기서 회사가 생기면 사용자 입력 문자열이 그대로 서비스 데이터가 된다 — 그 순간
    "회사 등록은 운영자 판단"이라는 설계가 무너진다."""
    op = await deps.require_operator({"MBR_ID": flow["op"]})
    before = (await database.fetch_one("SELECT COUNT(*) c FROM TCOMPANY"))["c"]
    assert await operator.decide_company_request(flow["comp_req"], True, op["MBR_ID"], "등록 예정") is True
    after = (await database.fetch_one("SELECT COUNT(*) c FROM TCOMPANY"))["c"]
    assert after == before, "회사가 생겼다 — 사용자 입력이 서비스 데이터가 됐다"

    row = await database.fetch_one(
        "SELECT STATUS_CD, DECIDED_BY_ID, MOD_ID FROM TCOMPANY_REQUEST WHERE COMP_REQUEST_ID=%s",
        (flow["comp_req"],))
    assert row["STATUS_CD"] == "approved"
    assert row["DECIDED_BY_ID"] == flow["op"] and row["MOD_ID"] == flow["op"]
    assert await operator.decide_company_request(flow["comp_req"], False, op["MBR_ID"], None) is False


@pytest.mark.asyncio
async def test_CF7_억제_해제는_행을_지우지_않고_흔적을_남긴다(flow):
    """반복 오탐을 추적하려면 **누가 언제 풀었는지**가 남아야 한다(SP-AUTH-16 과 같은 규약)."""
    op = await deps.require_operator({"MBR_ID": flow["op"]})
    assert await operator.release_suppression("c" * 64, op["MBR_ID"]) is True
    row = await database.fetch_one(
        "SELECT RELEASED_DTM, MOD_ID FROM TMAIL_SUPPRESSION WHERE TARGET_HASH_VAL=%s", ("c" * 64,))
    assert row is not None, "행을 지웠다 — 해제 이력이 사라진다"
    assert row["RELEASED_DTM"] is not None and row["MOD_ID"] == flow["op"]
    # 두 번 풀 수는 없다(`AND RELEASED_DTM IS NULL`).
    assert await operator.release_suppression("c" * 64, op["MBR_ID"]) is False


@pytest.mark.asyncio
async def test_CF8_큐_응답은_사용자_입력을_가공하지_않고_그대로_싣는다(flow):
    """서버가 HTML 을 만들면 그 순간 XSS 경로가 생긴다 — **값은 그대로, 표시는 노드 조립**이다.

    증빙에 `<img src=x onerror=...>` 를 심어 두고, 서버가 이스케이프하거나 잘라내지 **않는지**
    확인한다. 이스케이프를 서버에서 하면 CLI 출력·API 소비자마다 규칙이 갈리고, 결국
    "어디선가는 안 했다"가 된다. 방어는 렌더링 한 곳에 모은다."""
    from server.routers.console import queues

    op = await deps.require_operator({"MBR_ID": flow["op"]})
    data = await queues(op)
    ev = data["verifications"][0]["evidence"]
    assert ev == "<img src=x onerror=alert(1)> 사원증 사진", "서버가 값을 가공했다"
    assert data["operator"] == OP_EMAIL
    assert data["suppressed"][0]["target_hash"] == "c" * 64
    # 억제 항목에 원문 주소가 실릴 자리가 없다(애초에 저장되지 않는다, T9).
    assert "email" not in data["suppressed"][0]
