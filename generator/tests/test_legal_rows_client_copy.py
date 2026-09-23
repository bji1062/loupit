"""법정 행 클라이언트 사본(`web/assets/js/legal.js`)이 정본(`generator/data/legal_rows.json`)과 같은가.

참조 번들(/api/v1/reference/all)에는 법정 표식이 없다. 이직 계산기(2026-09-23 개편)는 법정 행을 목록에
남기되 비교·집계에서 빼야 해서, 3튜플 목록을 JS 모듈로 옮겨 실었다. 사본은 갈리는 날이 오므로 여기서
전수 대조한다 — 정본을 고치고 사본을 잊으면 이 테스트가 릴리스를 막는다(SP-LEGAL-5).
"""
import json
import re
from pathlib import Path

from generator import legal

ROOT = Path(__file__).resolve().parents[2]


def _client_rows() -> set[tuple[str, str, str]]:
    src = (ROOT / "web" / "assets" / "js" / "legal.js").read_text(encoding="utf-8")
    body = src[src.index("LEGAL_ROWS"):src.index("]);")]
    return {(a, b, c) for a, b, c in re.findall(r"\['([^']*)',\s*'([^']*)',\s*'([^']*)'\]", body)}


def test_client_copy_matches_canonical_rows():
    canonical = {(r["comp_eng_nm"], r["benefit_cd"], r["benefit_nm"]) for r in legal.legal_rows()}
    assert canonical, "정본이 비었다 — 경로가 바뀌었는지 확인하라"
    assert _client_rows() == canonical


def test_client_copy_has_no_duplicates():
    src = (ROOT / "web" / "assets" / "js" / "legal.js").read_text(encoding="utf-8")
    rows = re.findall(r"\['([^']*)',\s*'([^']*)',\s*'([^']*)'\]", src)
    assert len(rows) == len(set(rows)) == len(json.loads((ROOT / "generator" / "data" / "legal_rows.json").read_text(encoding="utf-8"))["rows"])
