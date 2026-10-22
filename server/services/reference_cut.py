"""참조 번들 한 번 조립 → 다섯 가지로 자르기 (2026-10-22, /compare · /find 경량화).

`build_reference_bundle` 결과를 검증된 덤프 하나로 만든 뒤 ① `/reference/all` 바이트(예전과 바이트 동일)
② `/reference/index` 가벼운 목록 ③ `/reference/companies/{id}` 회사별 상세 ④ `/reference/find` 복지검색 가벼운 묶음
⑤ `/reference/notes/{code}` 코드별 설명을 함께 만든다. 다섯이 같은 조립에서 나오므로 승인 반영(`cache.clear()`) 한 번이
다 비우고, 묶음과 설명이 서로 다른 시점의 값이 되지 않는다.

눈금 통계의 정의는 `generator/corpus.py::build` 와 같다(분모 = 전체 회사 수 · rmax 최소 1 · 표시 행 제외).
"""
from __future__ import annotations

import json
from dataclasses import dataclass, field

from server.models.reference import ReferenceBundle, ReferenceFind, ReferenceIndex, ReferenceNotes

from generator import marks
from generator.pages.company import CATEGORY_ORDER


@dataclass(frozen=True)
class ReferenceCut:
    all_body: bytes
    index_body: bytes
    company_bodies: dict[int, bytes] = field(default_factory=dict)
    find_body: bytes = b""
    note_bodies: dict[str, bytes] = field(default_factory=dict)  # 복지 코드 → 그 코드의 모든 회사 행 설명


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


# ── /find ────────────────────────────────────────────────────────────────────

TOP_N = 3  # 조건 없음 화면이 회사마다 보여주는 금액 큰 항목 수(find.js::renderRow 의 slice(0, 3))


def amount_of(b: dict) -> float:
    """복지 한 건의 연 환산 금액(만원) — `find.js::amountOf` 와 같은 규칙. 정성이면 0 · 수가 아니거나 ≤0 이면 0.

    공용 픽스처(find_lazy_cases.json)가 두 쪽을 같은 입력으로 대조한다."""
    if not b or b.get("qual_yn"):
        return 0
    try:
        n = float(b.get("benefit_amt"))
    except (TypeError, ValueError):
        return 0
    return n if n == n and n not in (float("inf"), float("-inf")) and n > 0 else 0


def top_benefits(company: dict) -> list[dict]:
    """조건 없음 화면의 그 회사 행 3개 — `renderRow` 의 `countable(c).filter(금액>0).sort(금액 내림차순).slice(0,3)`.

    정렬은 안정이라(파이썬 sorted · JS Array.sort 둘 다) 금액 동률은 번들 순서가 이긴다."""
    rows = [b for b in marks.countable(company) if amount_of(b) > 0]
    return sorted(rows, key=lambda b: -amount_of(b))[:TOP_N]


def build_find(dump: dict) -> dict:
    """검증된 번들 덤프 → 복지검색 가벼운 묶음(검증 전 dict). 회사 · 행 순서는 번들과 같다."""
    keep = ("comp_id", "comp_eng_nm", "comp_nm", "comp_tp_cd", "industry_nm", "logo_nm", "aliases")
    row_keep = ("benefit_cd", "benefit_nm", "benefit_ctgr_cd", "qual_yn", "benefit_amt", "amt_source", "badge_src_cd")
    companies = [{**{k: c[k] for k in keep}, "benefits": [{k: b[k] for k in row_keep} for b in c["benefits"]]}
                 for c in dump["companies"]]
    top_notes = [
        {"comp_id": c["comp_id"], "benefit_cd": b["benefit_cd"],
         "qual_desc_ctnt": b["qual_desc_ctnt"], "note_ctnt": b["note_ctnt"]}
        for c in dump["companies"] for b in top_benefits(c)
    ]
    return {"company_types": dump["company_types"], "companies": companies, "top_notes": top_notes}


def build_notes(dump: dict) -> dict[str, dict]:
    """검증된 번들 덤프 → {코드: {benefit_cd, notes[]}} — 그 코드를 가진 모든 회사 행(번들 회사 순서)."""
    out: dict[str, dict] = {}
    for c in dump["companies"]:
        for b in c["benefits"]:
            entry = out.setdefault(b["benefit_cd"], {"benefit_cd": b["benefit_cd"], "notes": []})
            entry["notes"].append({"comp_id": c["comp_id"], "qual_desc_ctnt": b["qual_desc_ctnt"], "note_ctnt": b["note_ctnt"]})
    return out


def cut_bundle(bundle: dict) -> ReferenceCut:
    """조립 결과 dict → 다섯 가지 응답 바이트.

    H-1(라우터 주석 참고): 원시 dict 가 아니라 **검증된 모델의 덤프**를 직렬화한다 — 계약 밖 필드가 새지 않는다.
    계약 위반은 `model_validate` 가 예외로 전파한다(전역 핸들러 500)."""
    dump = ReferenceBundle.model_validate(bundle).model_dump()
    index = ReferenceIndex.model_validate(build_index(dump)).model_dump()
    find = ReferenceFind.model_validate(build_find(dump)).model_dump()
    return ReferenceCut(
        all_body=_dumps(dump),
        index_body=_dumps(index),
        company_bodies={c["comp_id"]: _dumps(c) for c in dump["companies"]},
        find_body=_dumps(find),
        note_bodies={cd: _dumps(ReferenceNotes.model_validate(n).model_dump()) for cd, n in build_notes(dump).items()},
    )
