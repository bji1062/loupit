"""행 표시 클라이언트 사본(`web/assets/js/marks.js`)이 정본(`generator/data/row_marks.json` · `generator/marks.py`)과 같은가.

참조 번들(/api/v1/reference/all)에는 표시 표식이 없다. 이직 계산기 · 모드 A · /find 는 표시 행을 목록에 남기되 비교 ·
집계에서 빼야 해서, 4튜플 목록을 JS 모듈로 옮겨 실었다. 사본은 갈리는 날이 오므로 여기서 전수 대조한다 — 정본을
고치고 사본을 잊으면 이 테스트가 릴리스를 막는다(SP-LEGAL-5 · SP-MARK).
"""
import re
from pathlib import Path

from generator import marks

ROOT = Path(__file__).resolve().parents[2]
SRC = (ROOT / "web" / "assets" / "js" / "marks.js").read_text(encoding="utf-8")
_TUPLE = r"\['([^']*)',\s*'([^']*)',\s*'([^']*)',\s*'([^']*)'\]"


def _client_rows() -> list[tuple[str, str, str, str]]:
    body = SRC[SRC.index("ROW_MARKS"):SRC.index("]);")]
    return re.findall(_TUPLE, body)


def test_client_copy_matches_canonical_rows():
    canonical = {(r["comp_eng_nm"], r["benefit_cd"], r["benefit_nm"], r["kind"]) for r in marks.rows()}
    assert canonical, "정본이 비었다 — 경로가 바뀌었는지 확인하라"
    assert set(_client_rows()) == canonical


def test_client_copy_has_no_duplicates():
    rows = _client_rows()
    assert len(rows) == len(set(rows)) == len(marks.rows())


def test_client_labels_titles_and_phrases_equal_kinds():
    """라벨 · 문구는 두 언어가 같은 글자여야 한다(한쪽만 고치면 화면마다 다른 말을 한다)."""
    for kind, spec in marks.KINDS.items():
        m = re.search(kind + r": Object\.freeze\(\{\s*label: '([^']*)',\s*title: '([^']*)',\s*phrase: '([^']*)',\s*note: '([^']*)',", SRC)
        assert m, f"marks.js MARK.{kind} 를 못 찾았다"
        assert m.groups() == (spec["label"], spec["title"], spec["phrase"], spec["note"])
    s = re.search(r"SUMMARY = Object\.freeze\(\{\s*label: '([^']*)',\s*title: '([^']*)',", SRC)
    assert s and s.groups() == (marks.SUMMARY["label"], marks.SUMMARY["title"])
    assert f"SUMMARY_SRC_CD = '{marks.SUMMARY_SRC_CD}'" in SRC


def test_benefit_page_template_summary_title_equals_registry():
    """benefit.html 의 「검색 요약」 배지 title 은 템플릿 리터럴이라 셋째 사본이다 — 등록표(marks.SUMMARY)와 같은 글자여야 한다."""
    tpl = (ROOT / "generator" / "templates" / "benefit.html").read_text(encoding="utf-8")
    assert f'title="{marks.SUMMARY["title"]}">{marks.SUMMARY["label"]}</span>' in tpl
