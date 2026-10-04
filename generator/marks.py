"""행 표시(SP-MARK, 2026-10) — 화면에 남기되 무엇인지 밝히는 표시의 유일한 판정 자리.

범위 표시(집계 제외): legal 「법정」 · work_edu 「업무 교육」 — 정본 data/row_marks.json, (회사 eng, 코드, 항목명) 3튜플.
계보 표시(집계 포함): summary 「검색 요약」 — BADGE_SRC_CD = 'ai_parse'(근거 URL 없는 회사 = R-3 기준 39). 판정은
format.badge_state 가 이 상수를 읽어 한다(계보 정본은 그쪽 하나).

클라이언트 사본: web/assets/js/marks.js — generator/tests/test_row_marks_client_copy.py 가 대조한다.
"""
from __future__ import annotations

import json
import os
from functools import lru_cache

_PATH = os.path.join(os.path.dirname(__file__), "data", "row_marks.json")

KINDS = {  # 순서 = 화면 순서(표 끝에 붙는 순서)
    "legal": {"label": "법정",
              "title": "근로기준법 등이 모든 회사에 강제하는 제도입니다. 복지 항목 수에서 제외됩니다.",
              "phrase": "법으로 모든 회사에 정해진 제도만 적힌 항목",
              "sub": "법정 제도만 적은 회사"},
    "work_edu": {"label": "업무 교육",
                 "title": "회사가 업무를 맡기려고 여는 교육(신입 입문·직무 필수·승진자 리더십)만 적힌 항목입니다. 복지 항목 수에서 제외됩니다.",
                 "phrase": "회사가 업무를 맡기려고 여는 교육만 적힌 항목",
                 "sub": "업무 교육만 적은 회사"},
}
SUMMARY_SRC_CD = "ai_parse"
SUMMARY = {"label": "검색 요약",
           "title": "회사 공식 원문을 찾지 못해 검색 AI 요약을 근거로 한 항목입니다. 복지 항목 수에는 셉니다."}


@lru_cache(maxsize=1)
def _raw() -> dict:
    with open(_PATH, encoding="utf-8") as f:
        return json.load(f)


@lru_cache(maxsize=1)
def _index() -> dict:
    return {(r["comp_eng_nm"], r["benefit_cd"], r["benefit_nm"]): r["kind"] for r in _raw()["rows"]}


def rows() -> list[dict]:
    """등록표 전부."""
    return _raw()["rows"]


def row_mark(comp_eng_nm, benefit_cd, benefit_nm) -> str | None:
    """'legal' | 'work_edu' | None. 판정은 (회사, 항목코드, 항목명) 3튜플 — 같은 코드의 다른 이름은 복지다."""
    return _index().get((comp_eng_nm or "", benefit_cd, benefit_nm or ""))


def mark_view(kind) -> dict | None:
    """템플릿용 {kind, label, title}. kind 가 없으면 None."""
    if not kind:
        return None
    k = KINDS[kind]
    return {"kind": kind, "label": k["label"], "title": k["title"]}


def countable(company: dict) -> list[dict]:
    """company["benefits"] 에서 표시 행(법정 · 업무 교육)을 뺀 것. 검색 요약 행은 남는다(2a)."""
    eng = company.get("comp_eng_nm") or ""
    return [b for b in (company.get("benefits") or [])
            if row_mark(eng, b.get("benefit_cd"), b.get("benefit_nm") or "") is None]


def is_summary(b: dict) -> bool:
    return b.get("badge_src_cd") == SUMMARY_SRC_CD
