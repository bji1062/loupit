"""행 표시 장치(SP-MARK, 2026-10) — 등록표 · 판정 · 집계 제외 · 검색 요약 가드.

범위 표시(법정 · 업무 교육)는 `generator/data/row_marks.json` 3튜플로 판정하고 집계에서 뺀다.
검색 요약은 `BADGE_SRC_CD='ai_parse'` 로 판정하고 집계에는 든다(2a).
"""
import json
import re
from datetime import datetime
from pathlib import Path

from generator import marks
from generator.format import badge_state

ROOT = Path(__file__).resolve().parents[2]
SEED_DIR = ROOT / "db" / "seed" / "benefit" / "sql"


def test_registry_structure():
    rows = marks.rows()
    assert len(rows) == 6
    keys = [(r["comp_eng_nm"], r["benefit_cd"], r["benefit_nm"]) for r in rows]
    assert len(keys) == len(set(keys)), "3튜플이 겹친다"
    for r in rows:
        assert r["kind"] in marks.KINDS, r
        assert r["desc_at_review"] and r["why"], f"{r['comp_eng_nm']} 판정 근거가 비었다"
    assert sorted(r["kind"] for r in rows) == ["legal"] * 3 + ["work_edu"] * 3


def _seed_by_slug() -> dict[str, str]:
    by_slug = {}
    for path in SEED_DIR.glob("*.sql"):
        src = path.read_text(encoding="utf-8")
        m = re.search(r"COMP_ENG_NM\s*=\s*'([A-Za-z0-9_]+)'", src)
        if m:
            by_slug[m.group(1)] = src
    return by_slug


def test_registry_rows_all_exist_in_seed_sql():
    """시드에서 행이 사라지거나 항목명이 바뀌면 판정이 조용히 None 이 되어 표시 행이 다시 복지로 세어진다."""
    by_slug = _seed_by_slug()
    missing = [f"{r['comp_eng_nm']}/{r['benefit_nm']}" for r in marks.rows()
               if f"'{r['benefit_nm']}'" not in by_slug.get(r["comp_eng_nm"], "")]
    assert not missing, f"시드에서 사라진 표시 행: {missing}"


def test_row_mark_is_by_company_code_and_name():
    assert marks.row_mark("kt", "parenting", "출산/육아 지원") == "legal"
    assert marks.row_mark("alteogen", "edu_support", "신입사원 교육") == "work_edu"
    assert marks.row_mark("isens", "edu_support", "교육 프로그램") == "work_edu"
    assert marks.row_mark("samsung_card", "edu_support", "Job master 양성과정") == "work_edu"
    # 같은 코드 다른 이름 · 같은 이름 다른 코드 · 다른 회사 = 복지
    assert marks.row_mark("alteogen", "edu_support", "다른 이름") is None
    assert marks.row_mark("alteogen", "parenting", "신입사원 교육") is None
    assert marks.row_mark("yuhan", "edu_support", "신입사원 교육") is None
    assert marks.row_mark(None, "edu_support", "신입사원 교육") is None


def test_mark_view_and_kinds_labels():
    assert marks.mark_view(None) is None
    v = marks.mark_view("work_edu")
    assert v["label"] == "업무 교육" and "제외" in v["title"]
    assert marks.mark_view("legal")["label"] == "법정"
    assert list(marks.KINDS) == ["legal", "work_edu"], "순서 = 표 끝에 붙는 순서"


def _co(eng, rows):
    return {"comp_id": 1, "comp_eng_nm": eng, "benefits": rows}


def _row(cd, nm, src="scrape_official"):
    return {"benefit_cd": cd, "benefit_nm": nm, "badge_src_cd": src}


def test_countable_drops_marked_rows_but_keeps_summary_rows():
    c = _co("alteogen", [_row("edu_support", "신입사원 교육"), _row("edu_support", "다른 교육"),
                         _row("health", "건강검진", src="ai_parse")])
    kept = [b["benefit_nm"] for b in marks.countable(c)]
    assert kept == ["다른 교육", "건강검진"], "검색 요약 행은 집계에 남는다(2a)"
    assert marks.is_summary(c["benefits"][2]) and not marks.is_summary(c["benefits"][0])


def test_countable_tolerates_missing_benefits_and_name():
    assert marks.countable({"comp_eng_nm": "kt"}) == []
    assert marks.countable({"benefits": [_row("x", "y")]}) == [_row("x", "y")]


def test_badge_state_summary_priority():
    now = datetime(2026, 10, 4)
    base = {"badge_cd": "official", "badge_src_cd": "ai_parse", "expires_dtm": "2099-01-01"}
    assert badge_state(base, now) == {"code": "summary", "label": "검색 요약"}
    # 만료 > 검색 요약 · 재직자 > 검색 요약
    assert badge_state({**base, "expires_dtm": "2020-01-01"}, now)["code"] == "stale"
    assert badge_state({**base, "edit_origin": "member"}, now)["code"] == "member"
    assert badge_state({**base, "edit_origin": "edited"}, now)["code"] == "edited"
    assert badge_state({**base, "badge_src_cd": "scrape_official"}, now)["code"] == "official"


def test_SM_G1_ai_parse_companies_are_exactly_url_less_search_summary_seeds():
    """근거 URL 없는 새 회사가 조용히 「검색 요약」이 되는 것을 막는다.

    `-- URL: 없음` 머리말(= 백필이 `ai_parse` 를 찍는 회사)은 반드시 머리말 「출처 상세」에 「검색 AI 요약」이
    있어야 하고, 거꾸로 「검색 AI 요약」 출처 상세는 URL 없음이어야 한다.
    """
    url_less, summary_detail = set(), set()
    for path in SEED_DIR.glob("*.sql"):
        head = "\n".join(path.read_text(encoding="utf-8").splitlines()[:40])
        if re.search(r"^-- URL:\s*없음", head, re.M):
            url_less.add(path.name)
        if re.search(r"^--\s+출처 상세:.*검색 AI 요약", head, re.M):
            summary_detail.add(path.name)
    assert url_less, "머리말 규약이 바뀌었나 — URL 없음 회사가 0"
    assert url_less == summary_detail, (url_less ^ summary_detail)
