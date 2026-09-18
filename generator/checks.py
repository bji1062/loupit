"""generator/checks.py — 생성물 검증 게이트 (SP-GEN-12, Tier-0 GC-2·GC-10·GC-28 · SP-BEN GC-29·GC-30).

`run_generated_checks(out_dir, pages)`는 pytest(RED→GREEN 테스트)와 릴리스
게이트(SP-GEN-11 `stage_and_swap` 4단계)가 **동일 호출**한다(검증 로직
이원화 금지, 단일 소스). 실패 시 `BuildError`로 표면화 — 원자적 스왑
중단(SP-ARCH-9). GC-21(XSS 이스케이프)은 `make_env` autoescape 설정으로
구조적으로 보장되며 `generator/tests/test_escape.py`가 직접 회귀 검증한다
(본 함수의 데이터 의존 검사 대상이 아님).
"""
from __future__ import annotations

import re

from generator import benefit_rules
from generator.context import Page
from generator.slug import BuildError

_SCRIPT_RE = re.compile(r"<script\b[^>]*>.*?</script>", re.IGNORECASE | re.DOTALL)
_H1_RE = re.compile(r"<h1[\s>]", re.IGNORECASE)  # 속성 있는 `<h1 id=…>` 도 잡는다(대문이 그렇다)


def _strip_scripts(html: str) -> str:
    """`<script>…</script>` 제거(속성 포함, 대소문자 무시) — 비-JS 본문 검증용."""
    return _SCRIPT_RE.sub("", html)


def _check_company_count(pages: list[Page]) -> None:
    """GC-2(Tier-0, INV-6) — 회사 페이지 개수 ≥1.

    구판의 `== 200 이면 BuildError`(200-seed 프리셋 일괄 등록 사고 방지)는 2026-09-01
    회사 확장 개정으로 은퇴했다 — 정상 확장이 200 을 지나는 순간 오폭한다. 그 가드가
    지키던 실질(복지 없는 회사 페이지 금지)은 DB 층 SD-5(회사별 복지 ≥1)와 페이지 층
    GC-10(script 제거 후 복지 본문 존재)이 이미 이중으로 강제한다(INV-6 개정판)."""
    company_pages = [p for p in pages if p.path.startswith("company/")]
    if len(company_pages) == 0:
        raise BuildError("GC-2: 회사 페이지 0개(등록 회사 없음)")


def _check_non_js_body(pages: list[Page]) -> None:
    """GC-10(Tier-0, INV-3) — script 제거 후에도 회사명·복지 항목명이 남아
    본문이 색인·가독 가능해야 한다."""
    for p in pages:
        if not p.path.startswith(("company/", "vs/", "benefit/")):  # 복지 항목 페이지(SP-BEN) 포함
            continue
        stripped = _strip_scripts(p.html)
        if "<h1>" not in stripped or "복지" not in stripped:
            raise BuildError(f"GC-10: 비-JS 본문 가독 실패 — {p.path}")


def _check_home_present(pages: list[Page]) -> None:
    """GC-28(Tier-0) — 생성 대문 `index.html` 정확히 1개 + 비-JS 표식.

    2026-09-15 후속 정리(PR #55)로 수기 셸 `web/index.html` 과 nginx 폴백
    (`try_files /dist/index.html /index.html`)을 걷었다. 그 전까지는 대문 생성이
    빠져도 수기 셸이 `/` 를 받아 줬지만, 이제 `/` 를 떠받치는 건 생성 대문 **하나**뿐이라
    대문이 빠진 산출물을 스왑하는 순간 대문이 404 가 된다. 스모크 SM-1b 는 **스왑이 끝난 뒤**
    보므로 그때는 이미 라이브가 죽어 있다 — 스왑 전 게이트(SP-ARCH-9, 실패 시 이전 산출물 유지)에서 세운다.

    표식은 `<script>` 제거 후에 찾는다(INV-3) — JS 로만 심긴 표식은 크롤러에게 없는 것과 같다.
    표식만으로는 "템플릿이 렌더됐다"까지만 증명된다(표식이 최외곽 래퍼에 달려 있다) — `home.py` 는
    없는 데이터를 블록째 빼므로 껍데기 대문도 표식은 낸다. 그래서 본문 h1 도 함께 본다.
    ⚠ h1 은 리터럴 `"<h1>"` 로 찾으면 안 된다 — 대문은 `<h1 id="home-title">` 이라 상시 오탐이다
    (GC-10 의 회사·조합 페이지는 속성 없는 `<h1>` 이라 그쪽 리터럴 검사는 유효하다).
    """
    homes = [p for p in pages if p.path == "index.html"]
    if len(homes) != 1:
        raise BuildError(f"GC-28: 대문 index.html {len(homes)}개(정확히 1개여야 한다)")
    stripped = _strip_scripts(homes[0].html)
    if "data-home-generated" not in stripped:
        raise BuildError("GC-28: 대문에 생성 표식 data-home-generated 없음(비-JS 본문 기준)")
    if not _H1_RE.search(stripped):
        raise BuildError("GC-28: 대문 본문 없음 — 비-JS 본문에 <h1> 부재(껍데기 대문)")


def _check_benefit_human_text(cfgs: dict | None = None) -> None:
    """GC-29(SP-BEN) — 복지 항목 설정의 사람 글(intro·questions·notes)에 숫자 0.

    개수는 빌드가 원문에서 센다. 사람 글에 숫자가 들어가면 회사가 늘거나 원문이 바뀌는 날 그 문장만
    **에러 없이** 거짓이 된다(`benefit_rules` 머리말). 페이지가 만들어졌는지와 상관없이 설정 **전부**를
    본다 — 문턱(20곳)에 걸려 오늘 안 나온 항목도 회사가 늘면 그대로 나간다.
    """
    cfgs = cfgs if cfgs is not None else benefit_rules.load_pages()
    bad = [e for cfg in cfgs.values() for e in benefit_rules.check_no_digits(cfg)]
    if bad:
        raise BuildError("GC-29: 복지 항목 사람 글에 숫자 — " + " / ".join(bad))


def _check_benefit_reachable(pages: list[Page]) -> None:
    """GC-30(SP-BEN) — 복지 항목 페이지 전부가 sitemap 에 있고 `/find` 에서 링크된다.

    항목 페이지로 들어오는 정적 길은 `/find` 표 하나뿐이다(회사 페이지는 아직 역링크가 없다). 그 링크가
    빠지면 페이지는 sitemap 으로만 발견되는 고아가 되고, 이 사이트의 병목은 크롤 예산이다(실측: 진짜
    Googlebot 15일 18건). 항목 페이지가 하나도 없으면 검사할 것이 없다.
    ⚠ `--only benefit` 부분 빌드는 여기서 멈춘다 — `--only benefit find` 로 함께 그려야 한다.
    """
    items = [p for p in pages if p.path.startswith("benefit/")]
    if not items:
        return
    by_path = {p.path: p for p in pages}
    sitemap, find = by_path.get("sitemap.xml"), by_path.get("find.html")
    if sitemap is None or find is None:
        raise BuildError(f"GC-30: 복지 항목 페이지 {len(items)}개인데 sitemap.xml·find.html 이 함께 없다")
    for p in items:
        route = "/" + p.path[: -len(".html")]
        if f"<loc>{p.url}</loc>" not in sitemap.html:
            raise BuildError(f"GC-30: {route} 가 sitemap 에 없다")
        if f'href="{route}"' not in find.html:
            raise BuildError(f"GC-30: {route} 로 가는 링크가 /find 에 없다(고아 페이지)")


def run_generated_checks(out_dir: str, pages: list[Page]) -> None:
    """생성물 검증 게이트 — 실패 시 `BuildError`. `stage_and_swap` 4단계 소비."""
    _check_company_count(pages)
    _check_non_js_body(pages)
    _check_home_present(pages)
    _check_benefit_human_text()
    _check_benefit_reachable(pages)
