#!/usr/bin/env python3
"""복지검색 「가벼운 묶음 + 코드별 설명 = 번들」 대조 픽스처(`find_lazy_cases.json`)를 만든다.

왜: /find 는 부팅 때 번들 전체 대신 `/reference/find`(설명 없는 복지 행 + 회사마다 금액 큰 3개 행의 설명 `top_notes`)를 받고,
고른 코드의 설명은 `/reference/notes/{code}` 로 받는다. 화면은 설명이 도착한 뒤 예전(번들 전체)과 **글자까지 같아야** 한다.
서버가 고른 「금액 큰 3개」는 클라이언트 `renderRow` 의 조건 없음 3개와 **같은 행**이어야 하는데, 금액 판정 · 안정 정렬 ·
countable 이 양쪽 구현이라 어긋나기 쉽다. 이 픽스처는 작은 가짜 번들 한 벌과, 그것을 서버 함수(`server/services/reference_cut.py`)로 자른
결과(find 묶음 · 코드별 설명) · 금액 판정 대조표(`amount_cases`)를 함께 담아 두 쪽이 같은 기대값을 재게 한다 — 파이썬
(`server/tests/test_reference_cut.py`)과 JS(`web/assets/js/find-lazy.test.js`)가 함께 읽는다. 서버 함수나 JS 셈을 바꾸면
이 스크립트로 다시 뽑는다 — 손으로 고치지 마라.

사용:
    python3 generator/tests/data/make_find_lazy_cases.py
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT))

from server.models.reference import ReferenceBundle, ReferenceFind  # noqa: E402
from server.services.reference_cut import amount_of, build_find, build_notes  # noqa: E402

OUT = Path(__file__).resolve().parent / "find_lazy_cases.json"
NOTE = (
    "서버 자르기(reference_cut.build_find · build_notes · amount_of)와 JS(find.js · find-notes.js)가 같은 결과를 내는지 재는 픽스처. "
    "`bundle`(가짜 번들) · `find`(서버가 만든 가벼운 묶음) · `notes`(코드별 설명 응답) · `amount_cases`(금액 판정 대조표). "
    "server/tests/test_reference_cut.py 와 web/assets/js/find-lazy.test.js 가 함께 읽는다. 서버 함수나 JS 셈을 바꾸면 "
    "generator/tests/data/make_find_lazy_cases.py 로 다시 뽑아라 — 손으로 고치지 마라."
)


def _b(cd: str, nm: str, ctgr: str, *, amt=None, desc=None, note=None, src="scrape_official", qual=None, stated=True) -> dict:
    qual_yn = (amt is None) if qual is None else qual
    return {
        "benefit_cd": cd, "benefit_nm": nm, "benefit_amt": amt, "benefit_ctgr_cd": ctgr, "badge_cd": "official",
        "amt_source": ("stated" if stated else "estimated") if amt is not None else "none", "qual_yn": qual_yn,
        "qual_desc_ctnt": desc, "note_ctnt": note, "verified_dtm": "2026-10-01T00:00:00", "expires_dtm": None,
        "badge_src_cd": src, "badge_src_url_ctnt": "https://x.example/c" if src != "ai_parse" else None,
        "sort_order_no": 1, "edit_origin": "seed",
    }


def _co(comp_id: int, eng: str, nm: str, benefits: list[dict], *, industry="IT", tp="large", aliases=None) -> dict:
    return {
        "comp_id": comp_id, "comp_eng_nm": eng, "comp_nm": nm, "comp_tp_cd": tp, "industry_nm": industry,
        "logo_nm": nm[:1], "work_style_val": None, "careers_benefit_url": f"https://{eng}.example/careers",
        "aliases": aliases or [nm], "benefits": benefits,
    }


def fake_bundle() -> dict:
    """회사 40곳 — 앞 9곳은 손으로 짠 모서리 사례, 나머지는 「더 보기」(30개씩)용 채움."""
    cos = [
        # 금액 동률(meal = welfare = 240) · 법정 표시 행에 금액(parenting 900 — 센 쪽에서 빠져야 한다) · 4번째 금액 항목은 잘린다
        _co(1, "kt", "KT", [
            _b("parenting", "출산/육아 지원", "family", amt=900, qual=False, desc="법정 휴직"),
            _b("meal", "식대", "compensation", amt=240, desc="월 20만원"),
            _b("welfare_point", "복지포인트", "perks", amt=240, desc="연 240만원 포인트"),
            _b("gym", "사내 체육관", "health", amt=100, note="평일 이용"),
            _b("snack", "간식", "perks", amt=60, desc="탕비실"),
            _b("remote", "원격근무", "flexibility", desc="주 2회"),
        ], aliases=["KT", "케이티"]),
        # 금액 3개 미만 · 설명이 비고뿐인 행 · 둘 다 없는 행 · 설명이 빈 문자열이고 비고가 있는 행
        _co(2, "naver", "네이버", [
            _b("meal", "식사 제공", "compensation", amt=300, desc="", note="구내식당"),
            _b("remote", "주 4.5일제", "flexibility", note="전사 시행"),
            _b("welfare_point", "복지포인트", "perks", amt=150, stated=False),
        ], industry="포털"),
        # 금액 있는 항목이 하나도 없다 → 「금액 적힌 항목 없음」 줄
        _co(3, "quiet_co", "조용한상사", [
            _b("remote", "재택근무", "flexibility", desc="주 1회"),
            _b("lounge", "휴게실", "work_env"),
            _b("library", "도서관", "growth", desc="사내 도서"),
            _b("edu_lang", "어학 강좌", "growth"),
            _b("nap", "수면실", "work_env"),
        ], industry="포털", tp="mid"),
        # 정성(qual_yn)인데 금액이 있다 → 금액 0 취급 · 업무 교육 표시 행(알테오젠 edu_support)은 센 쪽에서 빠진다
        _co(4, "alteogen", "알테오젠", [
            _b("edu_support", "신입사원 교육", "growth", amt=500, qual=False, desc="입문 교육"),
            _b("snack", "간식", "perks", amt=400, qual=True, desc="정성인데 금액이 적힌 행"),
            _b("meal", "식대", "compensation", amt=120, desc="점심 제공", src="ai_parse"),
        ], industry="바이오"),
        # 한 회사에만 있는 코드 · 같은 이름 금액 3개 정확히
        _co(5, "solo_co", "솔로컴퍼니", [
            _b("solo_code", "유일한 복지", "perks", amt=30, desc="이 회사에만"),
            _b("meal", "식대", "compensation", amt=30, desc="동률 시작"),
            _b("welfare_point", "복지포인트", "perks", amt=30, desc="동률 둘째"),
        ], industry="바이오", tp="startup"),
        # 업종이 비었다
        _co(6, "noind_co", "업종없음", [_b("meal", "식대", "compensation", amt=200, desc="점심")], industry=None, tp="startup"),
        # 특수문자 이름 · 설명에 <, &
        _co(7, "samsung_ena", "삼성E&A", [
            _b("meal", "식대", "compensation", amt=250, desc="<b>굵게</b> & 그대로"),
            _b("gym", "사내 체육관", "health"),
        ], industry="건설"),
        _co(8, "tiny_co", "작은회사", [_b("leave", "리프레시 휴가", "time_off", desc="연 5일")], industry="IT", tp="mid"),
        _co(9, "dash_co", "대시-컴퍼니", [
            _b("meal", "식대", "compensation", amt=100, desc="a"), _b("gym", "사내 체육관", "health", amt=100, desc="b"),
            _b("snack", "간식", "perks", amt=100, desc="c"), _b("welfare_point", "복지포인트", "perks", amt=100, desc="d"),
        ], industry="IT"),
    ]
    for i in range(10, 41):  # 채움 — 금액 · 코드를 번갈아 가며 「더 보기」 두 쪽을 만든다
        cos.append(_co(i, f"fill_{i}", f"채움상사{i:02d}", [
            _b("meal", "식대", "compensation", amt=100 + (i % 7) * 10, desc=f"식대 설명 {i}"),
            _b("gym", "사내 체육관", "health", desc=f"체육관 {i}") if i % 2 else _b("snack", "간식", "perks", amt=20 + i, desc=f"간식 {i}"),
            _b("remote", "원격근무", "flexibility", note=f"비고 {i}"),
        ], industry=["IT", "포털", "바이오", "건설"][i % 4], tp="mid" if i % 3 == 0 else "large"))
    return {
        "company_types": [
            {"comp_tp_id": 1, "comp_tp_cd": "large", "comp_tp_nm": "대기업"},
            {"comp_tp_id": 2, "comp_tp_cd": "mid", "comp_tp_nm": "중견기업"},
            {"comp_tp_id": 3, "comp_tp_cd": "startup", "comp_tp_nm": "스타트업"},
        ],
        "benefit_presets": {"large": [], "mid": [], "startup": []},
        "companies": cos,
    }


#: 금액 판정 대조표 입력 — 번들은 pydantic 을 거쳐 문자열 금액이 정수로 바뀌므로, 판정 함수만은 날 입력으로 따로 잰다.
AMOUNT_INPUTS = [
    {"qual_yn": False, "benefit_amt": 240},
    {"qual_yn": False, "benefit_amt": "300"},
    {"qual_yn": False, "benefit_amt": " 12.5 "},
    {"qual_yn": False, "benefit_amt": "abc"},
    {"qual_yn": False, "benefit_amt": ""},
    {"qual_yn": False, "benefit_amt": None},
    {"qual_yn": False, "benefit_amt": 0},
    {"qual_yn": False, "benefit_amt": -5},
    {"qual_yn": False, "benefit_amt": "-5"},
    {"qual_yn": True, "benefit_amt": 500},
    {"qual_yn": True, "benefit_amt": None},
    {"benefit_amt": 70},
    {"qual_yn": 0, "benefit_amt": 15},
]


def build_cases() -> dict:
    bundle = ReferenceBundle.model_validate(fake_bundle()).model_dump()
    return {
        "_note": NOTE,
        "bundle": bundle,
        "find": ReferenceFind.model_validate(build_find(bundle)).model_dump(),
        "notes": build_notes(bundle),
        "amount_cases": [{"b": b, "amount": amount_of(b)} for b in AMOUNT_INPUTS],
    }


def dump(cases: dict) -> str:
    """키마다 한 줄 — 너무 길지 않게."""
    body = ",\n".join(f"{json.dumps(k, ensure_ascii=False)}: {json.dumps(v, ensure_ascii=False)}" for k, v in cases.items())
    return "{\n" + body + "\n}\n"


if __name__ == "__main__":
    OUT.write_text(dump(build_cases()), encoding="utf-8")
    print("wrote", OUT)
