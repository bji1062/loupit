"""generator/pages/company.py — 회사 상세 페이지 본문·SEO 렌더 (SP-GEN-5·6).

FR-52(기업정보·근무형태)·FR-53(복지표)·FR-54(배지·출처·만료·면책)·FR-57(CTA)·
FR-55(SEO head·JSON-LD). 등록 회사는 실복지 ≥1(INV-6) — 프리셋 폴백 없음.
"""
from __future__ import annotations

from generator.config import CFG
from generator.content.policy import POLICY_FOOTER_LINKS
from generator.context import Page
from generator.format import badge_state, iso_date, krw_manwon

# 9카테고리 정본 순서·라벨 (D1.7). 복지표·조합 대조가 공통 소비한다.
CATEGORY_ORDER = [
    "compensation",
    "flexibility",
    "work_env",
    "time_off",
    "health",
    "family",
    "growth",
    "leisure",
    "perks",
]
CATEGORY_LABEL = {
    "compensation": "보상",
    "flexibility": "유연성",
    "work_env": "근무환경",
    "time_off": "휴가",
    "health": "건강",
    "family": "가족",
    "growth": "성장",
    "leisure": "여가",
    "perks": "복리후생",
}

_ALLOWED_URL_SCHEMES = ("http://", "https://")


def _safe_http(url):
    """출처 URL 스킴 제한 (FR-54 R3, NFR21) — http/https만 링크 허용."""
    if not url:
        return None
    return url if url.startswith(_ALLOWED_URL_SCHEMES) else None


def _truncate(text: str, max_len: int) -> str:
    """meta description 절단 — 상한 초과 시 자연스러운 말줄임(회사명은 앞부분 보존)."""
    if len(text) <= max_len:
        return text
    return text[: max_len - 1].rstrip() + "…"


def _group_benefits(benefits: list[dict], now) -> list[tuple[str, str, list[dict]]]:
    """9카테고리 그룹·정렬·정성/금액·출처 스킴 (FR-53·54).

    비지 않은 카테고리만 `(key, label, items)`로 반환한다. 알 수 없는
    카테고리 코드도 방어적으로 수용(버킷 없으면 무시하지 않고 별도 보관은
    하지 않는다 — 9종 정본 외 카테고리는 CATEGORY_ORDER에 없으므로 UI에
    노출되지 않는다. 데이터 정합은 SP-SEED 소유).
    """
    buckets: dict[str, list[dict]] = {k: [] for k in CATEGORY_ORDER}
    for b in benefits:
        item = {
            "name": b["benefit_nm"],
            "amount": krw_manwon(b["benefit_amt"]) if not b["qual_yn"] else "",
            "qual": b["qual_yn"],
            "qual_desc": b.get("qual_desc_ctnt"),
            "note": b.get("note_ctnt"),
            "badge": badge_state(b, now),
            "src_cd": b.get("badge_src_cd"),
            "src_url": _safe_http(b.get("badge_src_url_ctnt")),
            "verified": iso_date(b.get("verified_dtm")),
            "expires": iso_date(b.get("expires_dtm")),
            "sort": b.get("sort_order_no") or 0,
        }
        cat = b["benefit_ctgr_cd"]
        if cat in buckets:
            buckets[cat].append(item)
    for k in buckets:
        buckets[k].sort(key=lambda x: x["sort"])
    return [(k, CATEGORY_LABEL[k], buckets[k]) for k in CATEGORY_ORDER if buckets[k]]


def _company_view(c: dict, ctx, now) -> dict:
    """뷰모델 파생 — 기업정보·유형지표·근무형태·복지·CTA (SP-GEN-5.2)."""
    t = ctx.types_by_cd.get(c["comp_tp_cd"], {})
    groups = _group_benefits(c["benefits"], now)
    ws = c.get("work_style_val") or {}
    return {
        "comp_nm": c["comp_nm"],
        "industry_nm": c.get("industry_nm"),
        "comp_tp_nm": t.get("comp_tp_nm"),
        "logo_nm": c.get("logo_nm"),
        "growth_label": t.get("growth_label_nm"),
        "stability": t.get("stability_score_no"),
        "work_style": [
            (k, ws[k])
            for k in ("remote", "flex", "unlimitedPTO", "refreshLeave", "overtime")
            if ws.get(k)
        ],
        "benefit_groups": groups,
        "compare_href": f"{CFG.compare_path}?a={c['comp_eng_nm']}",
    }


def _company_seo(c: dict, ctx, url: str) -> dict:
    """title·description·OG·canonical·JSON-LD 뷰모델 (SP-GEN-6.1)."""
    t = ctx.types_by_cd.get(c["comp_tp_cd"], {})
    title = f"{c['comp_nm']} 복지·연봉·근무조건 | jobcho.wiki"
    parts = [p for p in (t.get("comp_tp_nm"), c.get("industry_nm")) if p]
    top = ", ".join(b["benefit_nm"] for b in c["benefits"][:3])
    desc = (
        f"{c['comp_nm']}({' · '.join(parts)})의 복지·연봉·근무조건 정보. "
        f"{top} 등 복지 {len(c['benefits'])}개 항목을 확인하고 다른 회사와 비교해 보세요."
    )
    desc = _truncate(desc, CFG.desc_max)
    jsonld = {
        "@context": "https://schema.org",
        "@type": "Organization",
        "name": c["comp_nm"],
        "url": url,
        "alternateName": [c["comp_eng_nm"], *c.get("aliases", [])],
        "industry": c.get("industry_nm"),
    }
    jsonld = {k: v for k, v in jsonld.items() if v}
    return {
        "meta_title": title,
        "meta_desc": desc,
        "canonical": url,
        "og": {
            "title": title,
            "description": desc,
            "type": "website",
            "url": url,
            "image": CFG.site_origin + CFG.default_og_image,
        },
        "jsonld": jsonld,
    }


def render_all(env, ctx) -> list[Page]:
    """회사 ~95 전량 렌더 (SP-GEN-5.1). 회사당 정확히 1 페이지, 폴백 없음."""
    now = ctx.build_now
    tpl = env.get_template("company.html")
    pages: list[Page] = []
    for c in ctx.companies:
        slug = ctx.slugs[c["comp_eng_nm"]]
        url = f"{CFG.site_origin}/company/{slug}"
        vm = _company_view(c, ctx, now)
        seo = _company_seo(c, ctx, url)
        html = tpl.render(**vm, **seo, cfg=CFG, footer_links=POLICY_FOOTER_LINKS)
        pages.append(
            Page(
                path=f"company/{slug}.html",
                url=url,
                html=html,
                title=seo["meta_title"],
                description=seo["meta_desc"],
            )
        )
    return pages
