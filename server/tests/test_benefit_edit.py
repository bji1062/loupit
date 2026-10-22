"""SP-AUTH-9·10 복지 편집 — 순수 단위(모델·토큰·스냅샷) (AB-*, T-13.10·T-13.11).

2026-10-21 회원의 등록·수정이 운영자 확인 큐로 바뀌면서(바로 반영 → 202 요청), 예전에 인메모리 스텁으로 재던
라우트 계약(등록 201 · 수정 200 · 이력 조회)은 **실 DB** 로 옮겼다 — `test_benefit_edit_request.py`(BR-*).
요청 → 승인에서 배지 강제 · 금액출처 분기 · 낙관적 동시성 · 본체+이력 원자성 · 공개 이력(AH)을 같은 의미로 다시 잰다.
여기 남은 것은 DB 가 필요 없는 순수 함수와 입력 모델이다.
"""
from __future__ import annotations

from datetime import datetime

import pytest

from server.models.benefit_edit import BenefitCreateIn, BenefitUpdateIn
from server.services import benefit_edit as svc

# ── 순수 유닛 (모델·헬퍼) ─────────────────────────────────────────────────────
def test_version_token_prefers_mod_over_ins():
    ins = datetime(2026, 1, 1, 0, 0, 0)
    mod = datetime(2026, 2, 2, 3, 4, 5)
    base = {"benefit_nm": "a", "benefit_amt": 1}
    assert svc._version_token({**base, "INS_DTM": ins, "MOD_DTM": None}).startswith(ins.isoformat())
    assert svc._version_token({**base, "INS_DTM": ins, "MOD_DTM": mod}).startswith(mod.isoformat())


def test_version_token_changes_when_content_changes_same_dtm():
    """같은 초(같은 dtm)라도 내용이 바뀌면 토큰이 달라진다(초해상도 CAS 보강, lost-update 차단)."""
    ins = datetime(2026, 1, 1, 0, 0, 0)
    t_a = svc._version_token({"INS_DTM": ins, "MOD_DTM": None, "benefit_nm": "a", "benefit_amt": 1})
    t_b = svc._version_token({"INS_DTM": ins, "MOD_DTM": None, "benefit_nm": "a", "benefit_amt": 2})
    assert t_a != t_b


def test_snapshot_has_core_benefit_fields():
    snap = svc._snapshot(
        {"benefit_cd": "meal", "benefit_nm": "식대", "benefit_ctgr_cd": "compensation",
         "benefit_amt": 220, "qual_yn": 0, "note_ctnt": None, "badge_cd": "verified", "amt_source": "estimated"}
    )
    assert snap["benefit_cd"] == "meal" and snap["benefit_nm"] == "식대"
    assert snap["benefit_amt"] == 220 and snap["badge_cd"] == "verified"


def test_create_model_qual_with_amount_rejected():
    with pytest.raises(ValueError):
        BenefitCreateIn(benefit_cd="gym", benefit_nm="헬스장", benefit_ctgr_cd="health",
                        benefit_amt=100, qual_yn=True)


def test_create_model_category_is_ignored_not_rejected():
    """카테고리는 승인 때 코드에서 정해진다 — 캐시에 남은 옛 edit.js 가 보내도 422 가 되면 안 된다(2026-10-21)."""
    m = BenefitCreateIn(benefit_cd="meal", benefit_nm="식대", benefit_ctgr_cd="not_a_category", benefit_amt=1)
    assert m.benefit_cd == "meal"


def test_create_model_bad_benefit_cd_rejected():
    with pytest.raises(ValueError):
        BenefitCreateIn(benefit_cd="Meal Card!", benefit_nm="식대", benefit_ctgr_cd="compensation", benefit_amt=1)


def test_create_model_blank_name_rejected():
    """공백-only 이름은 Field(min_length=1)를 통과하나 strip 후 빈 문자열이라 거부(#5)."""
    with pytest.raises(ValueError):
        BenefitCreateIn(benefit_cd="meal", benefit_nm="   ", benefit_ctgr_cd="compensation", benefit_amt=1)


def test_update_model_requires_base_dtm():
    with pytest.raises(ValueError):
        BenefitUpdateIn(benefit_nm="식대", benefit_amt=1)  # base_dtm 누락 → 검증 실패
