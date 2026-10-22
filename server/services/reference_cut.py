"""참조 번들 한 번 조립 → 세 가지로 자르기 (2026-10-22, /compare 경량화).

`build_reference_bundle` 결과를 검증된 덤프 하나로 만든 뒤 ① `/reference/all` 바이트(예전과 바이트 동일)
② `/reference/index` 가벼운 목록 ③ `/reference/companies/{id}` 회사별 상세를 함께 만든다. 셋이 같은 조립에서
나오므로 승인 반영(`cache.clear()`) 한 번이 셋을 다 비우고, 목록과 상세가 서로 다른 시점의 값이 되지 않는다.

눈금 통계의 정의는 `generator/corpus.py::build` 와 같다(분모 = 전체 회사 수 · rmax 최소 1 · 표시 행 제외).
"""
from __future__ import annotations

import json
from dataclasses import dataclass, field

from server.models.reference import ReferenceBundle, ReferenceIndex

from generator import marks
from generator.pages.company import CATEGORY_ORDER


@dataclass(frozen=True)
class ReferenceCut:
    all_body: bytes
    index_body: bytes
    company_bodies: dict[int, bytes] = field(default_factory=dict)


def _dumps(obj) -> bytes:
    return json.dumps(obj, ensure_ascii=False).encode("utf-8")


def category_stats(companies: list[dict]) -> dict:
    """{total, sums, rmax} — `corpus.build` 와 같은 정의, 평균 대신 합."""
    sums = {k: 0 for k in CATEGORY_ORDER}
    rmax = 0
    for c in companies:
        per = {k: 0 for k in CATEGORY_ORDER}
        for b in marks.countable(c):
            cat = b["benefit_ctgr_cd"]
            if cat in per:
                per[cat] += 1
        for k, v in per.items():
            sums[k] += v
            rmax = max(rmax, v)
    return {"total": len(companies), "sums": sums, "rmax": max(rmax, 1)}


def build_index(dump: dict) -> dict:
    """검증된 번들 덤프 → 가벼운 목록(검증 전 dict). 회사 순서는 번들과 같다."""
    keep = ("comp_id", "comp_eng_nm", "comp_nm", "comp_tp_cd", "industry_nm", "logo_nm", "aliases")
    companies = [{**{k: c[k] for k in keep}, "benefit_n": len(marks.countable(c))} for c in dump["companies"]]
    return {
        "company_types": dump["company_types"],
        "benefit_presets": dump["benefit_presets"],
        "companies": companies,
        "category_stats": category_stats(dump["companies"]),
    }


def cut_bundle(bundle: dict) -> ReferenceCut:
    """조립 결과 dict → 세 가지 응답 바이트.

    H-1(라우터 주석 참고): 원시 dict 가 아니라 **검증된 모델의 덤프**를 직렬화한다 — 계약 밖 필드가 새지 않는다.
    계약 위반은 `model_validate` 가 예외로 전파한다(전역 핸들러 500)."""
    dump = ReferenceBundle.model_validate(bundle).model_dump()
    index = ReferenceIndex.model_validate(build_index(dump)).model_dump()
    return ReferenceCut(
        all_body=_dumps(dump),
        index_body=_dumps(index),
        company_bodies={c["comp_id"]: _dumps(c) for c in dump["companies"]},
    )
