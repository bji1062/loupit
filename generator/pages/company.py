"""generator/pages/company.py — 회사 상세 페이지 본문·SEO 렌더 (SP-GEN-5·6).

FR-52(기업정보·근무형태)·FR-53(복지표)·FR-54(배지·출처·만료·면책)·FR-57(CTA)·
FR-55(SEO head·JSON-LD). 등록 회사는 실복지 ≥1(INV-6) — 프리셋 폴백 없음.
"""
from __future__ import annotations

import re

from generator.config import CFG
from generator.content.policy import POLICY_FOOTER_LINKS
from generator.context import Page
from generator.format import badge_state, iso_date, krw_manwon
from generator.slug import combo_slug

# 관련 회사 링크 개수 상한 (FR-63 확장, 2026-07-19 고아 페이지 해소).
RELATED_COMPANY_MAX = 6

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


def _industry_tokens(industry_nm) -> set[str]:
    """업종 문자열 → 토큰 집합(casefold 정규화). `INDUSTRY_NM`이 자유 텍스트라
    완전일치만으로는 '전자/반도체'와 '반도체', 'IT/포털'과 'it/플랫폼'이 서로
    남남이 된다. 구분자로 쪼개고 대소문자를 접어 비교한다.
    실데이터 구분자는 '/' 뿐이며 나머지는 예방적 수용이다.
    """
    return {
        t.strip().casefold()
        for t in re.split(r"[/·,&]", industry_nm or "")
        if t.strip()
    }


def _industry_related(tokens: set[str], other: set[str]) -> bool:
    """업종군 일치 판정 — 토큰 완전일치 또는 한쪽이 다른 쪽의 접두.

    접두까지 보는 이유: '반도체장비'(6개사)·'반도체소재'(2)가 '반도체'(3)와
    완전일치로는 영영 안 붙어 업종 이웃 0인 회사가 22개 남았다.
    """
    if tokens & other:
        return True
    return any(a.startswith(b) or b.startswith(a) for a in tokens for b in other)


def _related_companies(c: dict, ctx) -> list[tuple[str, str]]:
    """관련 회사 내부 링크 [(회사명, 라우트)] — 고아 페이지 해소(2026-07-19).

    선정 순서: (1) 업종 토큰이 겹치는 회사, (2) 부족분은 **가나다순 인접**(자기
    위치 앞뒤로 번갈아). 폴백이 필수인 이유: 업종이 단독인 회사가 남아 있어
    업종 매칭만으로는 일부가 링크 0건으로 남는다. 가나다순 인접은 전 회사를
    하나의 링크 체인으로 이어 크롤러가 어디서 시작하든 전량 도달하게 한다.
    정렬·순회가 결정적이라 같은 번들이면 빌드마다 동일 결과다.
    """
    eng = c["comp_eng_nm"]
    ordered = sorted(ctx.companies, key=lambda x: (x["comp_nm"], x["comp_eng_nm"]))
    idx = next(i for i, x in enumerate(ordered) if x["comp_eng_nm"] == eng)
    n = len(ordered)

    # (1) 체인 슬롯 선예약 — 가나다순 앞·뒤 이웃을 **항상** 방출한다(링 구조).
    # 예약이 필수인 이유: 업종 매칭만으로 상한을 채우면 폴백이 실행되지 않아
    # 큰 업종군(게임 8사 등)이 폐쇄 싱크가 되고, 그 안으로 들어온 크롤러가
    # 나머지 전부를 못 본다. 양쪽 이웃을 고정하면 전 회사가 하나의 양방향 링으로
    # 이어져 도달성이 데이터가 아니라 구조로 보장된다(GC-26 회귀 검증).
    chain = []
    for j in ((idx + 1) % n, (idx - 1) % n):
        x = ordered[j]
        if x["comp_eng_nm"] != eng and x not in chain:
            chain.append(x)

    # (2) 남는 슬롯을 업종군으로 채운다(표시 순서는 업종 먼저 — 관련성 우선).
    chain_engs = {x["comp_eng_nm"] for x in chain}
    seen = {eng} | chain_engs
    industry: list[dict] = []
    tokens = _industry_tokens(c.get("industry_nm"))
    if tokens:
        for x in ordered:
            if len(industry) >= RELATED_COMPANY_MAX - len(chain):
                break
            if x["comp_eng_nm"] not in seen and _industry_related(
                tokens, _industry_tokens(x.get("industry_nm"))
            ):
                industry.append(x)
                seen.add(x["comp_eng_nm"])

    picked = industry + chain
    return [(_related_label(x, picked), f"/company/{ctx.slugs[x['comp_eng_nm']]}") for x in picked]


def _related_label(x: dict, picked: list[dict]) -> str:
    """앵커 텍스트 — 동명이사가 함께 뽑히면 업종을 덧붙여 구분한다(현 시드엔 없음)."""
    if sum(1 for y in picked if y["comp_nm"] == x["comp_nm"]) > 1 and x.get("industry_nm"):
        return f"{x['comp_nm']}({x['industry_nm']})"
    return x["comp_nm"]


def _related_combos(eng: str, ctx, combo_pairs) -> list[tuple[str, str]]:
    """이 회사가 등장하는 조합 페이지 링크 [(라벨, 라우트)].

    `combo_pairs`는 build.py가 검증한 유효 쌍만 넘긴다(미등록·자기쌍 제외) —
    존재하지 않는 /vs/ 경로를 링크하지 않기 위한 계약(GC-20 정합).
    """
    links: list[tuple[str, str]] = []
    rev = {ctx.slugs[e]: e for e in (ctx.by_eng or {})}
    for a, b in combo_pairs or ():
        if eng not in (a, b):
            continue
        path, first, second = combo_slug(a, b, ctx.slugs)
        # 앵커 텍스트를 조합 페이지의 h1·title과 같은 순서(slug 사전식)로 맞춘다 —
        # 역순 라벨은 클릭 후 제목이 뒤바뀐 것처럼 보인다(2026-07-19 검수).
        label = f"{ctx.by_eng[rev[first]]['comp_nm']} vs {ctx.by_eng[rev[second]]['comp_nm']}"
        links.append((label, f"/vs/{path}"))
    return links


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


def render_all(env, ctx, combo_pairs=None) -> list[Page]:
    """회사 ~95 전량 렌더 (SP-GEN-5.1). 회사당 정확히 1 페이지, 폴백 없음.

    `combo_pairs`: build.py가 검증한 유효 조합 쌍(선택). 주입 시 각 회사 페이지가
    자신이 등장하는 /vs/ 조합 페이지로 링크한다(고아 해소, FR-63 확장).
    """
    now = ctx.build_now
    tpl = env.get_template("company.html")
    pages: list[Page] = []
    for c in ctx.companies:
        eng = c["comp_eng_nm"]
        slug = ctx.slugs[eng]
        url = f"{CFG.site_origin}/company/{slug}"
        vm = _company_view(c, ctx, now)
        seo = _company_seo(c, ctx, url)
        html = tpl.render(
            **vm,
            **seo,
            related_companies=_related_companies(c, ctx),
            related_combos=_related_combos(eng, ctx, combo_pairs),
            cfg=CFG,
            footer_links=POLICY_FOOTER_LINKS,
        )
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
