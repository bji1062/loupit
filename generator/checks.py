"""generator/checks.py — 생성물 검증 게이트 (SP-GEN-12, Tier-0 GC-2·GC-10).

`run_generated_checks(out_dir, pages)`는 pytest(RED→GREEN 테스트)와 릴리스
게이트(SP-GEN-11 `stage_and_swap` 4단계)가 **동일 호출**한다(검증 로직
이원화 금지, 단일 소스). 실패 시 `BuildError`로 표면화 — 원자적 스왑
중단(SP-ARCH-9). GC-21(XSS 이스케이프)은 `make_env` autoescape 설정으로
구조적으로 보장되며 `generator/tests/test_escape.py`가 직접 회귀 검증한다
(본 함수의 데이터 의존 검사 대상이 아님).
"""
from __future__ import annotations

import re

from generator.context import Page
from generator.slug import BuildError

_SCRIPT_RE = re.compile(r"<script\b[^>]*>.*?</script>", re.IGNORECASE | re.DOTALL)


def _strip_scripts(html: str) -> str:
    """`<script>…</script>` 제거(속성 포함, 대소문자 무시) — 비-JS 본문 검증용."""
    return _SCRIPT_RE.sub("", html)


def _check_company_count(pages: list[Page]) -> None:
    """GC-2(Tier-0, INV-6) — 회사 페이지 개수 ≥1, 200 아님."""
    company_pages = [p for p in pages if p.path.startswith("company/")]
    if len(company_pages) == 0:
        raise BuildError("GC-2: 회사 페이지 0개(등록 회사 없음)")
    if len(company_pages) == 200:
        raise BuildError(
            "GC-2: 회사 페이지 200개(KOSPI/KOSDAQ 200 목록 오적용 의심, INV-6 위반)"
        )


def _check_non_js_body(pages: list[Page]) -> None:
    """GC-10(Tier-0, INV-3) — script 제거 후에도 회사명·복지 항목명이 남아
    본문이 색인·가독 가능해야 한다."""
    for p in pages:
        if not (p.path.startswith("company/") or p.path.startswith("vs/")):
            continue
        stripped = _strip_scripts(p.html)
        if "<h1>" not in stripped or "복지" not in stripped:
            raise BuildError(f"GC-10: 비-JS 본문 가독 실패 — {p.path}")


def run_generated_checks(out_dir: str, pages: list[Page]) -> None:
    """생성물 검증 게이트 — 실패 시 `BuildError`. `stage_and_swap` 4단계 소비."""
    _check_company_count(pages)
    _check_non_js_body(pages)
