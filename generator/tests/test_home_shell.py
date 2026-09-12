"""대문 수기 셸 계약 — 링크 드리프트 게이트 + 정적 허브 불변식 (2026-09-12, 1단계).

`web/index.html` 은 생성기를 거치지 않는 **수기 HTML** 이다. 그래서 회사가 rename 되거나
웨이브가 새 회사를 들여도 대문은 **아무 신호 없이** 옛 경로를 가리킨 채 남는다 — 생성 페이지는
GC-20(`test_links.py`)이 지키지만 대문은 그 그물 밖에 있었다. 이 파일이 그 구멍을 메운다.

**왜 `web/dist` 를 보지 않는가.** `web/dist` 는 커밋되지 않고(.gitignore `/web/dist`) CI 러너에는
아예 없다. 대신 회사 경로의 정본을 **커밋된 시드 SQL**(`db/seed/benefit/sql/*.sql`)에서 뽑는다:
회사 페이지 slug 는 `slug_of(COMP_ENG_NM)` 이고 그 `COMP_ENG_NM` 은 시드가 정한다. 따라서
시드에서 회사가 사라지거나 eng 이름이 바뀌면 여기서 즉시 붉어진다(웨이브 3 대비).

**중복 구현 금지.** 허용 라우트·href 정규식·루트 실파일·전 페이지 렌더 배선은 `test_links.py`
것을 그대로 import 한다. 두 벌이 되면 한쪽만 고쳐지고, 그 순간 이 게이트는 통과하는데 실제로는
죽은 링크가 나가는 상태가 된다.
"""
from __future__ import annotations

import json
import pathlib
import re

from generator.slug import combo_slug, slug_of
from generator.tests.test_links import (
    _ALLOWED_STATIC_ROUTES,
    _INTERNAL_HREF_RE,
    _ROOT_FILES,
    _WEB_ROOT,
    _build_all_pages,
    _in_hidden_authnav_slot,
)

REPO_ROOT = pathlib.Path(__file__).resolve().parents[2]
HOME = _WEB_ROOT / "index.html"
SEED_SQL = REPO_ROOT / "db" / "seed" / "benefit" / "sql"
COMBINATIONS = REPO_ROOT / "generator" / "data" / "combinations.json"

# 시드 SQL 의 회사 자기등록 문장에서 `COMP_ENG_NM` 을 꺼낸다. 파일당 정확히 하나다
# (복지 SQL 이 회사를 먼저 INSERT IGNORE 한 뒤 @comp_id 를 잡는 규약 — db/seed/load.py).
_SEED_ENG_RE = re.compile(
    r"INSERT\s+IGNORE\s+INTO\s+TCOMPANY\s*\([^)]*COMP_ENG_NM[^)]*\)\s*VALUES\s*\(\s*'([^']+)'",
    re.I | re.S,
)

# 노출된 M9 링크 — `test_authnav.py::test_no_visible_login_link_in_static_html` 과 **같은 정규식**.
# 그 테스트는 생성 페이지를 돌지만 수기 셸은 돌지 않는다. 원칙은 하나이므로 여기서 셸에 건다.
_M9_HREF_RE = re.compile(r'href="(/login|/mypage|/verify|/edit|/edits)(?:[/?#][^"]*)?"')

# 쿼리·해시를 붙여 도구로 들어가는 입구. 경로는 `/find` 하나이고 생성 페이지가 실재한다.
_QUERY_ROUTES = {"/find"}


def _variants(path: str) -> set[str]:
    """끝 슬래시 한 겹은 같은 곳이다 — nginx 가 `/compare` → `/compare/` 로 301 한다.

    허용 목록이 `/compare`(슬래시 없음)와 `/community/`(슬래시 있음)를 **둘 다** 담고 있어
    한쪽 표기만 맞춰 보면 실재하는 라우트를 죽은 링크로 오판한다. 대문은 리다이렉트 한 홉을
    아끼려고 슬래시 붙은 쪽을 쓴다(크롤 예산이 이 사이트의 병목이다).
    """
    bare = path.rstrip("/") or "/"
    return {path, bare, bare + "/"}


def _home_html() -> str:
    return HOME.read_text(encoding="utf-8")


def _seed_slugs() -> dict[str, str]:
    """`{comp_eng_nm: slug}` — 커밋된 시드가 정본. DB·web/dist 무경유(CI 에서도 돈다)."""
    files = sorted(SEED_SQL.glob("*.sql"))
    assert files, f"시드 SQL 이 없다: {SEED_SQL}"
    out: dict[str, str] = {}
    for f in files:
        m = _SEED_ENG_RE.search(f.read_text(encoding="utf-8"))
        assert m, f"{f.name}: TCOMPANY 자기등록 문장을 찾지 못했다 — 시드 규약이 바뀌었다면 이 게이트도 고쳐라"
        out[m.group(1)] = slug_of(m.group(1))
    return out


def _visible_text(html: str) -> str:
    """무JS 로 읽히는 본문 — 주석·script·style 을 걷어내고 태그를 지운 나머지."""
    body = html[html.index("<main>"):html.index("</main>")]
    body = re.sub(r"<!--.*?-->", " ", body, flags=re.S)
    body = re.sub(r"<(script|style)\b.*?</\1>", " ", body, flags=re.S | re.I)
    return re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", body)).strip()


# ── 1. 링크 드리프트 게이트 ──────────────────────────────────────────────────


def test_home_internal_links_all_resolve(fake_bundle, fake_now, fake_combinations_path):
    """대문의 내부 href 전부가 실재하는 목적지를 가리킨다.

    목적지 집합 = 생성 페이지 경로(`/companies`·`/heatmap`·`/find`·정책) ∪ 허용 정적 라우트
    ∪ 루트 실파일 ∪ 시드에서 나온 `/company/<slug>` ∪ 큐레이션 조합의 `/vs/<path>`.
    """
    pages = _build_all_pages(fake_bundle, fake_now)
    generated = {
        "/" + p.path[: -len(".html")] for p in pages if p.path.endswith(".html")
    }
    # fake 번들의 회사 3곳이 만든 경로는 대문 검증에 쓰지 않는다 — 대문은 **실제** 회사를 가리킨다.
    generated = {r for r in generated if not r.startswith(("/company/", "/vs/"))}

    slugs = _seed_slugs()
    company_routes = {f"/company/{s}" for s in slugs.values()}
    pairs = [
        (c["a"], c["b"])
        for c in json.loads(COMBINATIONS.read_text(encoding="utf-8"))["combinations"]
        if c["a"] in slugs and c["b"] in slugs
    ]
    combo_routes = {f"/vs/{combo_slug(a, b, slugs)[0]}" for a, b in pairs}

    html = _home_html()
    missing = []
    for m in _INTERNAL_HREF_RE.finditer(html):
        href = m.group(1)
        path = href.split("?", 1)[0].split("#", 1)[0]
        known = _ALLOWED_STATIC_ROUTES | generated | _QUERY_ROUTES | company_routes | combo_routes
        if _variants(path) & known:
            continue
        if _in_hidden_authnav_slot(html, m.start()):
            continue  # 숨겨진 M9 슬롯 — 대상 유효성이 환경 의존이다(test_links.py 머리말)
        if path in _ROOT_FILES:
            assert (_WEB_ROOT / path.lstrip("/")).is_file(), f"{path} 선언, 실파일 없음"
            continue
        if path.startswith("/assets/"):
            continue
        missing.append(href)
    assert not missing, f"대문이 실재하지 않는 곳을 가리킨다(404 위험): {missing}"


def test_home_does_not_point_to_404_page():
    for href in _INTERNAL_HREF_RE.findall(_home_html()):
        assert "/404" not in href


# ── 2. 정적 허브 계약 — 도구 셸의 잔해가 남으면 안 된다 ──────────────────────


def test_home_is_a_static_hub_not_a_tool_shell():
    """`app.js` 를 **로드하지 않고** 도구 셸 요소도 없다.

    🚨 요소만 빼고 스크립트를 남기면 매 방문 `reference/all` 1MB 를 그대로 받는다 — 번들 소비처가
    전부 null-safe 라 콘솔에 아무것도 남기지 않고 조용히 죽는다(가장 알아채기 어려운 형태).
    ⓘ 문자열이 아니라 **script 태그의 src** 를 본다: 왜 싣지 않는지 설명하는 주석이 파일에 있고,
      그 주석을 지우게 만드는 테스트는 계약이 아니라 함정이다.
    """
    html = _home_html()
    srcs = re.findall(r'<script[^>]*\bsrc="([^"]+)"', html)
    assert not any(s.endswith("/app.js") for s in srcs), f"대문이 app.js 를 싣고 있다: {srcs}"
    for dead in ('id="app"', 'id="trending"', 'id="boot-error"'):
        assert dead not in html, f"도구 셸 잔해가 남았다: {dead}"


def test_home_keeps_authnav_script():
    """로그인 슬롯을 채우는 스크립트는 남는다(슬롯만 있고 스크립트가 없으면 영원히 숨겨진다)."""
    assert "js/authnav.js" in _home_html()


# ── 3. 머리·몸통 불변식 ──────────────────────────────────────────────────────


def test_home_keeps_naver_site_verification():
    """네이버 서치어드바이저 소유확인은 등록 URL(`/`) **하나만** 본다 — 지우면 소유권을 잃는다."""
    assert re.search(r'<meta\s+name="naver-site-verification"\s+content="\w+"', _home_html())


def test_home_keeps_landing_ad_wiring():
    """`data-page-type="landing"` 을 빼면 `ads.js` 기본값이 무광고가 된다. 슬롯은 정확히 1개."""
    html = _home_html()
    assert 'data-page-type="landing"' in html
    assert html.count('data-ad-position="content_bottom"') == 1
    assert 'data-ad-position="report_bottom"' not in html, "리포트 슬롯은 /compare/ 의 것이다"


def test_home_has_exactly_one_h1_and_it_is_the_skip_link_target():
    html = _home_html()
    h1s = re.findall(r"<h1\b[^>]*>(.*?)</h1>", html, flags=re.S)
    assert len(h1s) == 1, f"h1 {len(h1s)}개"
    assert 'id="main-heading"' in re.search(r"<h1\b[^>]*>", html).group(0)
    assert h1s[0].strip().startswith("잡초위키"), f"브랜드가 첫 어절이 아니다: {h1s[0][:40]}"


# ── 4. 고밀도 — 이 페이지의 존재 이유 ────────────────────────────────────────


def test_home_body_is_readable_without_js():
    """크롤러가 보는 것이 이 페이지의 전부다. 애드센스 거절 사유(콘텐츠 부족)의 1차 방어선."""
    chars = len(_visible_text(_home_html()))
    assert chars >= 1500, f"무JS 가시 본문 {chars}자 — 1,500자 미만"


def test_home_carries_company_direct_links():
    """회사 상세로 가는 **1홉** 경로. 이전에는 0개였고 크롤러 진입로가 sitemap 뿐이었다."""
    n = len(re.findall(r'href="/company/', _home_html()))
    assert n >= 60, f"/company/ 직링크 {n}개 — 60개 미만"


# ── 5. 노출된 M9 링크 0 ──────────────────────────────────────────────────────


def test_home_has_no_visible_m9_link():
    """`/login`·`/mypage`·`/verify`·`/edit`·`/edits` 로 가는 `<a>` 는 **hidden authnav 슬롯 하나뿐**.

    prod 는 그 경로를 nginx 가 404 로 막고 정책 문안이 「로그인 없음」을 선언 중이다 —
    「재직자가 직접 고칩니다」 블록에 링크를 거는 순간 눌리는 죽은 진입점이 공개된다.
    """
    html = _home_html()
    for m in _M9_HREF_RE.finditer(html):
        start = html.rfind("<a", 0, m.start())
        tag = html[start: html.find(">", m.start()) + 1]
        assert "data-authnav" in tag and "hidden" in tag, (
            f"대문이 노출된 M9 링크를 갖고 있다 → {tag[:120]}"
        )


# ── 6. 도구 이사와 짝이 맞는가 ───────────────────────────────────────────────


def test_find_compare_prefill_points_at_compare_route():
    """복지검색의 「A vs B 비교하기」가 `/compare/` 로 간다.

    이 한 줄을 두고 오면 프리필이 **도구가 없는 대문**으로 떨어진다. 구현과 그 테스트를 함께 본다
    — 둘 중 하나만 옮기면 초록인 채로 깨진 상태가 되기 때문이다.
    """
    for rel in ("web/assets/js/find.js", "web/assets/js/find.test.js"):
        # 테스트 쪽은 정규식 리터럴이라 구분자가 이스케이프돼 있다(`\/compare\/\?a=`).
        # 역슬래시를 걷어내고 같은 한 문장으로 본다 — 표기 차이로 계약을 둘로 만들지 않는다.
        src = (REPO_ROOT / rel).read_text(encoding="utf-8").replace("\\", "")
        assert "/compare/?a=" in src, f"{rel}: 비교 프리필이 아직 대문을 가리킨다"
