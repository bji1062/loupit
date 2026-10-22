"""테스트 보조 — 재직자 편집 행을 **운영과 같은 경로**(요청 → 운영자 승인)로 만든다 (2026-10-21).

회원의 등록·수정은 바로 반영되지 않고 확인 요청이 된다(`services/benefit_edit.py`). 시드 보존(SP-SEED-12)·복구
마이그레이션 같은 테스트는 「재직자가 만든 행 + 편집 이력」이 필요할 뿐이라, 요청을 만든 뒤 곧바로 승인해 같은
결과(본체 + 이력 + verified 배지)를 얻는다. 결정자 ID 에는 FK 가 없다 — 운영자 자리에는 임의 정수를 쓴다.
"""
from __future__ import annotations

from server.services import benefit_edit as svc

OPERATOR_ID = 9_999_001  # DECIDED_BY_ID 는 FK 가 없다(콘솔이 세션 MBR_ID 를 넣는다)


async def approved_update(comp_id: int, benefit_id: int, mbr_id: int, payload) -> dict:
    """수정 요청 → 승인. 요청 단계 실패(conflict 등)는 그 결과를 그대로, 승인되면 `{result: ok, benefit: {benefit_id}}`."""
    r = await svc.update_request(comp_id, benefit_id, mbr_id, payload)
    if r["result"] != "ok":
        return r
    out = await svc.approve_request(r["request"]["request_id"], OPERATOR_ID, None, None, {})
    if out["result"] != "approved":
        return out
    return {"result": "ok", "benefit": {"benefit_id": out["benefit_id"]}}


async def approved_create(comp_id: int, mbr_id: int, payload, ctgr: str | None = None) -> dict:
    """등록 요청 → 승인. 카테고리는 코드에서 정해지므로 `ctgr`(없으면 payload.benefit_ctgr_cd)를 코드 목록으로 넘긴다."""
    codes = {payload.benefit_cd: {"code": payload.benefit_cd, "ctgr": ctgr or payload.benefit_ctgr_cd}}
    r = await svc.create_request(comp_id, mbr_id, payload, codes)
    if r["result"] != "ok":
        return r
    out = await svc.approve_request(r["request"]["request_id"], OPERATOR_ID, payload.benefit_cd, None, codes)
    if out["result"] != "approved":
        return out
    return {"result": "ok", "benefit": {"benefit_id": out["benefit_id"]}}
