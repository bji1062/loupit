"""generator/pages/sitemap.py — sitemap.xml·robots.txt (사이트 전역, SP-GEN-9)."""
from __future__ import annotations

from generator.config import CFG
from generator.context import Page


def render_sitemap(env, urls: list[str], lastmod, cfg=CFG) -> Page:
    """전 URL(회사+조합+정책+랜딩) → sitemap.xml (NFR9). 중복 URL 0.

    `lastmod` 는 **URL 별 dict**(`release.lastmod_index` 결과)이거나, 하위 호환으로 문자열 하나다
    (문자열이면 전 URL 에 같은 날짜 — 테스트·수동 빌드용). 빌드 경로는 항상 dict 를 넘긴다:
    전 URL 에 오늘을 찍는 사이트맵은 구글이 날짜를 무시하게 만든다(`lastmod_index` 주석).
    dict 에 없는 URL 은 그리지 않고 **즉시 실패**한다 — 날짜 없는 URL 을 조용히 빼면 사이트맵에서
    페이지가 사라지고, 아무도 모른다.
    """
    seen = sorted(set(urls))
    if isinstance(lastmod, str):
        dates = {u: lastmod for u in seen}
    else:
        missing = [u for u in seen if u not in lastmod or not lastmod[u].get("lastmod")]
        if missing:
            raise ValueError(f"sitemap: lastmod 가 없는 URL {len(missing)}개 — {missing[:3]}")
        dates = {u: lastmod[u]["lastmod"] for u in seen}
    xml = env.get_template("sitemap.xml").render(urls=seen, lastmods=dates)
    return Page(
        path="sitemap.xml",
        url=f"{cfg.site_origin}/sitemap.xml",
        html=xml,
        title="",
        description="",
        in_sitemap=False,
        content_type="application/xml; charset=utf-8",
    )


# IndexNow 키 파일 경로. 키 자체는 env(`INDEXNOW_KEY`)에서 오고 **공개값**이다 — 이 파일을
# 검색엔진이 직접 읽어 "이 호스트의 주인이 보낸 통보"임을 확인한다. 경로를 고정하는 이유:
# nginx 가 `location = /indexnow-key.txt` 로 dist 에서 서빙해야 하는데, 키를 파일명에 넣으면
# 키를 바꿀 때마다 nginx 설정도 바뀌어야 한다. IndexNow 는 `keyLocation` 으로 아무 경로나 허용한다.
INDEXNOW_KEY_PATH = "indexnow-key.txt"


def render_indexnow_key(cfg=CFG) -> Page | None:
    """`/indexnow-key.txt` — 키가 설정돼 있을 때만 만든다(없으면 None = 페이지 없음, 통보도 없음)."""
    key = (cfg.indexnow_key or "").strip()
    if not key:
        return None
    return Page(
        path=INDEXNOW_KEY_PATH,
        url=f"{cfg.site_origin}/{INDEXNOW_KEY_PATH}",
        html=key + "\n",
        title="",
        description="",
        in_sitemap=False,
        content_type="text/plain; charset=utf-8",
    )


def render_ads_txt(cfg=CFG) -> Page:
    """/ads.txt — AdSense 광고 판매 권한 인증(수익 보호) + 소유권 확인 겸용(2026-07-21).
    형식: `google.com, pub-XXXXXXXXXXXXXXXX, DIRECT, f08c47fec0942fa0`
      · pub-id는 client id(`ca-pub-…`)에서 `ca-` 접두 제거.
      · f08c47fec0942fa0 = Google AdSense 인증기관 고정 ID(전 게시자 공통).
    robots/sitemap과 동일하게 web/dist에 산출되고 nginx `location = /ads.txt`가 서빙한다.
    """
    pub = cfg.adsense_client_id.replace("ca-", "", 1)  # ca-pub-… → pub-…
    body = f"google.com, {pub}, DIRECT, f08c47fec0942fa0\n"
    return Page(
        path="ads.txt",
        url=f"{cfg.site_origin}/ads.txt",
        html=body,
        title="",
        description="",
        in_sitemap=False,
        content_type="text/plain; charset=utf-8",
    )


def render_robots(cfg=CFG) -> Page:
    """`Sitemap:` 라인 필수(NFR10). 읽기전용 API는 색인 대상 아님.

    스크래핑 방어 Layer D(2026-07-21): honor-system이라 정직한 봇만 따르지만 공짜·무해다.
    공격적 SEO 스크래퍼(Ahrefs/Semrush/MJ12 등)에 전면 Disallow를 명시하고, 기본 봇에는
    Crawl-delay로 대량 크롤을 완화한다. 검색·AdSense 크롤러는 규칙 미적용(자기 규칙 우선)이라
    무영향 — 실제 차단은 nginx Layer B(UA)가 담당하고 robots는 선언적 보조다.
    """
    aggressive = [
        "AhrefsBot", "SemrushBot", "MJ12bot", "DotBot", "BLEXBot",
        "DataForSeoBot", "PetalBot", "SerpstatBot", "MegaIndex",
    ]
    blocks = [
        "# 공격적 SEO·데이터 스크래퍼 — 전면 차단(nginx Layer B가 실제 강제)",
        *[f"User-agent: {b}\nDisallow: /" for b in aggressive],
        "",
        "# 그 외 전체 — API만 제외, 대량 크롤 완화",
        "User-agent: *",
        "Allow: /",
        "Disallow: /api/",
        "Crawl-delay: 2",
        "",
        f"Sitemap: {cfg.site_origin}/sitemap.xml",
        "",
    ]
    body = "\n".join(blocks)
    return Page(
        path="robots.txt",
        url=f"{cfg.site_origin}/robots.txt",
        html=body,
        title="",
        description="",
        in_sitemap=False,
        content_type="text/plain; charset=utf-8",
    )
