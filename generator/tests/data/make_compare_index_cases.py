#!/usr/bin/env python3
"""비교 화면 「가벼운 목록 + 회사별 상세 = 번들」 대조 픽스처(`compare_index_cases.json`)를 만든다.

왜: /compare 는 부팅 때 번들 전체 대신 `/reference/index`(복지 행 없는 목록 · 복지 수 · 눈금 통계의 합)를 받고,
회사 상세는 `/reference/companies/{id}` 로 필요할 때 받는다. 화면 · 계산 결과는 예전(번들 전체)과 **글자까지 같아야** 한다.
이 픽스처는 작은 가짜 번들 한 벌과, 그것을 서버 함수(`server/services/reference_cut.py`)로 자른 결과(index · 회사별 상세)를
함께 담아 두 쪽이 같은 기대값을 재게 한다 — 파이썬(`server/tests/test_reference_cut.py`: 픽스처가 지금 서버 함수 출력과
같은가 · 눈금 합이 `corpus.build` 와 같은가)과 JS(`web/assets/js/compare-index.test.js`: 번들로 센 값 == index 로 만든 값)가
함께 읽는다. 서버 함수나 JS 셈을 바꾸면 이 스크립트로 다시 뽑는다 — 손으로 고치지 마라.

사용:
    python3 generator/tests/data/make_compare_index_cases.py
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT))

from server.models.reference import ReferenceBundle  # noqa: E402
from server.services.reference_cut import build_index  # noqa: E402

OUT = Path(__file__).resolve().parent / "compare_index_cases.json"
NOTE = (
    "서버 자르기(reference_cut)와 JS 셈(categoryStats · countable · rowMeta)이 같은 결과를 내는지 재는 픽스처. "
    "`bundle`(가짜 번들) · `index`(서버가 만든 가벼운 목록) · `details`(회사별 상세). server/tests/test_reference_cut.py 와 "
    "web/assets/js/compare-index.test.js 가 함께 읽는다. 서버 함수나 JS 셈을 바꾸면 "
    "generator/tests/data/make_compare_index_cases.py 로 다시 뽑아라 — 손으로 고치지 마라."
)


def _b(cd: str, nm: str, ctgr: str, *, amt=None, qual=True, src="scrape_official", url="https://x.example/c", origin="seed", sort=1) -> dict:
    return {
        "benefit_cd": cd, "benefit_nm": nm, "benefit_amt": amt, "benefit_ctgr_cd": ctgr, "badge_cd": "official",
        "amt_source": "stated" if amt is not None else "none", "qual_yn": qual if amt is None else False,
        "qual_desc_ctnt": None, "note_ctnt": None, "verified_dtm": "2026-10-01T00:00:00", "expires_dtm": None,
        "badge_src_cd": src, "badge_src_url_ctnt": url, "sort_order_no": sort, "edit_origin": origin,
    }


def _co(comp_id: int, eng: str, nm: str, benefits: list[dict], *, industry="IT", tp="large", aliases=None, ws=None) -> dict:
    return {
        "comp_id": comp_id, "comp_eng_nm": eng, "comp_nm": nm, "comp_tp_cd": tp, "industry_nm": industry,
        "logo_nm": nm[:1], "work_style_val": ws, "careers_benefit_url": f"https://{eng}.example/careers",
        "aliases": aliases or [nm], "benefits": benefits,
    }


def fake_bundle() -> dict:
    """8곳 — 평균이 .125 · .375 에 떨어진다(round2 의 짝수 반올림 지점). 표시 행 · 검색 요약 행 · 빈 업종 · 별칭 여럿."""
    return {
        "company_types": [
            {"comp_tp_id": 1, "comp_tp_cd": "large", "comp_tp_nm": "대기업"},
            {"comp_tp_id": 2, "comp_tp_cd": "startup", "comp_tp_nm": "스타트업"},
        ],
        "benefit_presets": {
            "large": [{"benefit_cd": "meal", "benefit_nm": "식대", "benefit_amt": 200, "benefit_ctgr_cd": "compensation",
                       "badge_cd": "est", "default_checked_yn": True, "sort_order_no": 1}],
            "startup": [],
        },
        "companies": [
            # 법정 표시 행(kt · parenting · 출산/육아 지원)이 한 줄 — 복지 수 · 통계에서 빠진다
            _co(1, "kt", "KT", [_b("parenting", "출산/육아 지원", "family"), _b("meal", "식대", "compensation", amt=240, qual=False, sort=2),
                                _b("gym", "사내 체육관", "health", sort=3)],
                aliases=["KT", "케이티", "한국통신"], ws={"remote": True, "flex": False}),
            # 업무 교육 표시 행(alteogen · edu_support · 신입사원 교육) + 검색 요약 행(ai_parse) — 요약은 센다
            _co(2, "alteogen", "알테오젠", [_b("edu_support", "신입사원 교육", "growth"), _b("snack", "간식", "perks", sort=2, src="ai_parse", url=None),
                                          _b("edu_lang", "어학 강좌", "growth", sort=3)], industry="바이오", aliases=["알테오젠"]),
            _co(3, "naver", "네이버", [_b("remote", "원격근무", "flexibility", origin="edited"), _b("meal", "식대", "compensation", amt=300, qual=False, sort=2),
                                    _b("health_chk", "건강검진", "health", sort=3), _b("lounge", "휴게실", "work_env", sort=4)], aliases=["NAVER", "네이버"]),
            # 업종이 비었다(None) · 한 카테고리에 몰렸다 → rmax
            _co(4, "cluster_co", "몰빵상사", [_b(f"p{i}", f"복리 {i}", "perks", sort=i) for i in range(1, 8)], industry=None, tp="startup"),
            _co(5, "tiny_co", "작은회사", [_b("meal", "식대", "compensation", amt=100, qual=False)], industry="IT", tp="startup", aliases=["작은회사", "tiny"]),
            _co(6, "sk_x", "SK엑스", [_b("leave", "리프레시 휴가", "time_off"), _b("family_day", "가족 사랑의 날", "family", sort=2, origin="member")], industry="통신"),
            _co(7, "dash_co", "대시-컴퍼니", [_b("meal", "식대", "compensation", amt=250, qual=False)], industry="IT"),
            _co(8, "last_co", "마지막상사", [_b("meal", "식대", "compensation", amt=210, qual=False), _b("gym", "사내 체육관", "health", sort=2)], industry="바이오"),
        ],
    }


def build_cases() -> dict:
    bundle = ReferenceBundle.model_validate(fake_bundle()).model_dump()
    return {
        "_note": NOTE,
        "bundle": bundle,
        "index": build_index(bundle),
        "details": {str(c["comp_id"]): c for c in bundle["companies"]},
    }


if __name__ == "__main__":
    OUT.write_text(json.dumps(build_cases(), ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print("wrote", OUT)
