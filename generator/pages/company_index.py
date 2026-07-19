"""generator/pages/company_index.py — 회사 인덱스 `/companies` (SP-GEN-5.3).

2026-07-19 신설. 회사 상세·조합 페이지는 서로 관련 링크로 이어져 있었으나
랜딩·비교툴에서 그 덩어리로 **들어가는** 정적 링크가 0건이라 진입문이
sitemap.xml 뿐이었다(검수 반증). 이 페이지가 등록 회사 전량을 한 곳에서
링크해 크롤러 진입점이자 사용자 탐색 경로가 된다.

page_type을 선언하지 않는다 = 광고 없음(ads.js 'default'). 목록 페이지에
광고를 얹지 않는 편이 심사·가독 양쪽에 낫다.
"""
from __future__ import annotations

from generator.config import CFG
from generator.content.policy import POLICY_FOOTER_LINKS
from generator.context import Page


def render(env, ctx, cfg=CFG) -> Page:
    """등록 회사 전량을 가나다순으로 링크하는 단일 인덱스 페이지."""
    companies = sorted(ctx.companies, key=lambda c: (c["comp_nm"], c["comp_eng_nm"]))
    items = [
        {
            "comp_nm": c["comp_nm"],
            "industry_nm": c.get("industry_nm"),
            "href": f"/company/{ctx.slugs[c['comp_eng_nm']]}",
        }
        for c in companies
    ]
    url = f"{cfg.site_origin}/companies"
    title = f"등록 회사 {len(items)}곳 복지·연봉 목록 | {cfg.site_name}"
    desc = (
        f"jobcho.wiki에 등록된 회사 {len(items)}곳의 복지·연봉·근무조건 페이지 목록입니다. "
        f"회사를 골라 복지 항목을 확인하고 다른 회사와 비교해 보세요."
    )
    html = env.get_template("companies.html").render(
        items=items,
        total=len(items),
        meta_title=title,
        meta_desc=desc,
        canonical=url,
        og={
            "title": title,
            "description": desc,
            "type": "website",
            "url": url,
            "image": cfg.site_origin + cfg.default_og_image,
        },
        cfg=cfg,
        footer_links=POLICY_FOOTER_LINKS,
    )
    return Page(path="companies.html", url=url, html=html, title=title, description=desc)
