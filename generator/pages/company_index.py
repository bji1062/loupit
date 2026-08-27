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
from generator.finance import index_row

# 섹션 순서·라벨(SP-FIN-5). 금융은 지표 세트가 달라(매출·영업이익 계정 부재) 표를 가른다.
_SECTIONS = (("general", "일반"), ("financial", "금융"))


def _finance_sections(items: list[dict], ctx) -> list[dict]:
    """재무가 실린 빌드에서만 — 회사를 `acct_set` 으로 일반/금융에 나눠 최신연도 수치를 붙인다.
    매핑이 없는 회사(CJ올리브영)는 일반 섹션에 '—' 로. 빈 섹션은 내지 않는다(금융 0곳이면 생략)."""
    if not ctx.finance_loaded:
        return []
    groups: dict[str, list[dict]] = {key: [] for key, _ in _SECTIONS}
    for it in items:  # items 는 이미 가나다순 — 섹션 안 순서가 그대로 GC-27 이다
        fin = ctx.finance.get(it["comp_id"])
        key = fin["acct_set"] if fin and fin.get("acct_set") in groups else "general"
        groups[key].append({**it, **index_row(fin)})
    return [
        {"key": key, "label": label, "financial": key == "financial", "rows": groups[key]}
        for key, label in _SECTIONS
        if groups[key]
    ]


def render(env, ctx, cfg=CFG) -> Page:
    """등록 회사 전량을 가나다순으로 링크하는 단일 인덱스 페이지."""
    companies = sorted(ctx.companies, key=lambda c: (c["comp_nm"], c["comp_eng_nm"]))
    items = [
        {
            "comp_id": c["comp_id"],
            "comp_nm": c["comp_nm"],
            "industry_nm": c.get("industry_nm"),
            "href": f"/company/{ctx.slugs[c['comp_eng_nm']]}",
        }
        for c in companies
    ]
    url = f"{cfg.site_origin}/companies"
    title = f"회사정보 — 등록 회사 {len(items)}곳 복지·연봉·근무조건 | {cfg.site_name}"
    desc = (
        f"jobcho.wiki에 등록된 회사 {len(items)}곳의 복지·연봉·근무조건 페이지 목록입니다. "
        f"회사를 골라 복지 항목을 확인하고 다른 회사와 비교해 보세요."
    )
    html = env.get_template("companies.html").render(
        items=items,
        total=len(items),
        finance_sections=_finance_sections(items, ctx),
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
        nav_active="/companies",  # 회사정보 탭의 착지 페이지
    )
    return Page(path="companies.html", url=url, html=html, title=title, description=desc)
