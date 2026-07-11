"""T-07.10 릴리스 플로우 테스트 (GC-24·25) — 해시·gzip·매니페스트·원자적 스왑."""
from __future__ import annotations

import gzip
import hashlib
import json

import pytest

from generator.context import Page
from generator.release import stage_and_swap, write_manifest
from generator.slug import BuildError

# gzip이 실제로 원본보다 작아지도록 반복 텍스트로 충분한 길이를 확보한다
# (아주 짧은 문자열은 gzip 헤더 오버헤드 때문에 항상 원본보다 커진다).
_GOOD_HTML = "<html><body><h1>회사</h1>" + ("복지 항목 설명 텍스트 반복. " * 40) + "</body></html>"


def _valid_page(path="company/x.html", html=_GOOD_HTML):
    return Page(
        path=path,
        url=f"https://loupit.co/{path[:-5]}",
        html=html,
        title="t",
        description="d",
    )


# ── GC-24: gzip 사전압축·해시 매니페스트 ────────────────────────────────


def test_gc24_html_gz_exists_and_decompresses_to_original(tmp_path):
    out_dir = str(tmp_path / "dist")
    pages = [_valid_page()]
    stage_and_swap(out_dir, pages, incremental=False, gzip=True)

    gz_path = tmp_path / "dist" / "company" / "x.html.gz"
    assert gz_path.exists()
    with gzip.open(gz_path, "rb") as f:
        assert f.read().decode("utf-8") == _GOOD_HTML


def test_gc24_manifest_sha256_matches_written_file(tmp_path):
    out_dir = str(tmp_path / "dist")
    pages = [_valid_page()]
    manifest = stage_and_swap(out_dir, pages, incremental=False, gzip=True)
    write_manifest(out_dir, manifest)

    written = (tmp_path / "dist" / "company" / "x.html").read_bytes()
    expected_sha = hashlib.sha256(written).hexdigest()
    assert manifest["company/x.html"]["sha256"] == expected_sha
    assert manifest["company/x.html"]["bytes"] == len(written)

    manifest_file = json.loads((tmp_path / "dist" / ".manifest.json").read_text(encoding="utf-8"))
    assert manifest_file["files"]["company/x.html"]["sha256"] == expected_sha
    assert "generated_at" in manifest_file


def test_gc24_gzip_omitted_when_larger_than_original(tmp_path):
    """매우 짧은 콘텐츠는 gzip 헤더 오버헤드로 원본보다 커져 `.gz` 생략.

    GC-2 게이트(회사 페이지 ≥1)를 만족시키기 위해 정상 회사 페이지 1개를
    함께 전달한다(run_generated_checks는 전 페이지 목록 기준으로 검증).
    """
    out_dir = str(tmp_path / "dist")
    pages = [_valid_page(), _valid_page(path="robots.txt", html="a")]
    manifest = stage_and_swap(out_dir, pages, incremental=False, gzip=True)
    assert manifest["robots.txt"]["gz"] is None
    assert not (tmp_path / "dist" / "robots.txt.gz").exists()


def test_gc24_incremental_reuses_unchanged_file_and_recomputes_sitemap_always(tmp_path):
    out_dir = str(tmp_path / "dist")
    p1 = _valid_page()
    stage_and_swap(out_dir, [p1], incremental=False, gzip=True)

    # 동일 콘텐츠로 증분 재빌드 — 변경 없음 → 이전본 복사, sha 동일
    manifest2 = stage_and_swap(out_dir, [p1], incremental=True, gzip=True)
    assert manifest2["company/x.html"]["sha256"] == hashlib.sha256(_GOOD_HTML.encode()).hexdigest()

    # 변경분 재빌드
    p1_changed = _valid_page(html=_GOOD_HTML + "<p>추가</p>")
    manifest3 = stage_and_swap(out_dir, [p1_changed], incremental=True, gzip=True)
    assert manifest3["company/x.html"]["sha256"] != manifest2["company/x.html"]["sha256"]


# ── GC-25: 원자적 스왑 실패 시 산출물 유지 ───────────────────────────────


def test_gc25_validation_failure_aborts_swap_and_keeps_previous_dist(tmp_path):
    out_dir = str(tmp_path / "dist")
    good_page = _valid_page()
    stage_and_swap(out_dir, [good_page], incremental=False, gzip=True)
    before = (tmp_path / "dist" / "company" / "x.html").read_bytes()

    # GC-2 검증 강제 실패 주입: 회사 페이지 0개(전량 제거)
    with pytest.raises(BuildError):
        stage_and_swap(out_dir, [], incremental=False, gzip=True)

    after = (tmp_path / "dist" / "company" / "x.html").read_bytes()
    assert before == after  # {out} 불변


def test_gc25_non_js_body_check_failure_also_aborts_swap(tmp_path):
    out_dir = str(tmp_path / "dist")
    good_page = _valid_page()
    stage_and_swap(out_dir, [good_page], incremental=False, gzip=True)
    before_files = sorted((tmp_path / "dist").rglob("*"))

    broken_page = _valid_page(path="company/y.html", html="<html><body>no h1 no keyword</body></html>")
    with pytest.raises(BuildError):
        stage_and_swap(out_dir, [broken_page, good_page], incremental=False, gzip=True)

    after_files = sorted((tmp_path / "dist").rglob("*"))
    assert before_files == after_files  # {out} 불변 — 스테이징(.next)은 다음 빌드가 _reset_dir로 정리
