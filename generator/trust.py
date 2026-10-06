"""generator/trust.py — 복지 행 집계(근거 · 금액 세 갈래 · 확인일)의 유일한 자리 (SP-GUIDE-2, 2026-10-06).

대문 「읽기 전에 알아 둘 것」(`pages/home.py::_trust`)과 데이터 안내 `/about/data`(`pages/about_data.py`)가
**같은 함수**로 센다. 두 페이지가 같은 사실(전체 · 공식 수치 · 추정 · 금액 미등록 · 확인일)을 말하는데
집계가 둘이면 언젠가 숫자가 갈라지고, 둘 다 못 믿게 된다.

이 모듈은 **정수만** 돌려준다. 천 단위 쉼표 · 한국어 날짜 같은 표기는 소비처의 몫이다.
"""
from __future__ import annotations

from collections import Counter

from generator import marks
from generator.format import iso_date


def welfare_totals(ctx) -> dict:
    """전체 복지 행을 한 번 훑어 세 갈래 금액 · 근거 · 표시 · 확인일을 센다.

    금액 세 갈래(`stated` · `estimated` · `qual`/`no_amount`)는 **전체 행 수로 닫힌다**(total = 넷의 합).
    `none` = 정성(`qual`) + 금액 빈 행(`no_amount`) — 화면의 「금액 미등록」이다.
    확인일(`dates`)은 **검색 요약 행을 뺀** 행으로 센다 — 요약 행의 날짜는 확인일이 아니라 요약 기준일이다.
    """
    stated = estimated = qual = no_amount = 0
    summary = member = 0
    summary_comps: set = set()
    marked: Counter = Counter()
    dates: Counter = Counter()
    for c in ctx.companies:
        eng = c.get("comp_eng_nm") or ""
        for b in c.get("benefits") or []:
            kind = marks.row_mark(eng, b.get("benefit_cd"), b.get("benefit_nm") or "")
            if kind:
                marked[kind] += 1
            src = b.get("badge_src_cd")
            if b.get("qual_yn"):
                qual += 1
            elif b.get("benefit_amt") is None:
                no_amount += 1
            elif b.get("amt_source") == "stated":
                stated += 1
            else:
                estimated += 1
            if marks.is_summary(b):
                summary += 1
                summary_comps.add(c["comp_id"])
                continue  # 요약 기준일은 확인일 집계에 넣지 않는다
            if src == "user_report":
                member += 1
            dates[iso_date(b.get("verified_dtm"))] += 1
    return {
        "total": stated + estimated + qual + no_amount,
        "stated": stated, "estimated": estimated, "qual": qual, "no_amount": no_amount,
        "none": qual + no_amount,
        "summary": summary, "summary_comps": summary_comps, "member": member,
        "marked": marked, "dates": dates,
    }
