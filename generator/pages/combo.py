"""generator/pages/combo.py — 인기 조합 선정·조합 페이지 렌더 (SP-GEN-7).

FR-60(선정·URL·생성)·FR-61(사전 요약)·FR-62(양사 프리필 CTA)·FR-63(내부 링크)·
FR-64(SEO). 목록 외 임의 조합은 생성하지 않는다(FR-60 R1, 목록 외 경로=404).
"""
from __future__ import annotations

import json
import logging
from pathlib import Path

from generator.content.policy import POLICY_FOOTER_LINKS
from generator.context import Page
from generator.pages.company import CATEGORY_LABEL, CATEGORY_ORDER, _group_benefits, _truncate
from generator.slug import combo_slug, validate_combo_paths

log = logging.getLogger(__name__)

# 인기 조합 큐레이션 목록 경로(SP-GEN-7.1). 테스트는 이 모듈 속성을
# monkeypatch해 소형 fake 목록으로 교체한다(conftest.py `fake_combinations_path`).
COMBINATIONS_PATH = Path(__file__).resolve().parents[1] / "data" / "combinations.json"

_WS_KEYS = ("remote", "flex", "unlimitedPTO", "refreshLeave", "overtime")
_WS_LABEL_MAP = {
    "remote": "재택근무",
    "flex": "유연근무",
    "unlimitedPTO": "무제한 휴가",
    "refreshLeave": "리프레시 휴가",
    "overtime": "야근 있음(고지)",
}


def _company_summary(c: dict, t: dict) -> dict:
    """조합 페이지 M1 기업정보 뷰(양사 공통 파생)."""
    return {
        "comp_nm": c["comp_nm"],
        "comp_eng_nm": c["comp_eng_nm"],
        "comp_tp_nm": t.get("comp_tp_nm"),
        "industry_nm": c.get("industry_nm"),
        "logo_nm": c.get("logo_nm"),
    }


def _work_style_compare(ws_a: dict, ws_b: dict) -> list[tuple[str, str, bool, bool]]:
    """M2 근무형태 5축 나란히 대조 — true만 "제공"(허위 표기 금지)."""
    return [
        (k, _WS_LABEL_MAP[k], bool(ws_a.get(k)), bool(ws_b.get(k))) for k in _WS_KEYS
    ]


def _category_summary(a_benefits: list[dict], b_benefits: list[dict], now) -> list[dict]:
    """M3 9카테고리별 항목수·대표복지·정량금액+배지 대조."""
    groups_a = {k: (label, items) for k, label, items in _group_benefits(a_benefits, now)}
    groups_b = {k: (label, items) for k, label, items in _group_benefits(b_benefits, now)}
    rows = []
    for k in CATEGORY_ORDER:
        la = groups_a.get(k)
        lb = groups_b.get(k)
        if not la and not lb:
            continue
        items_a = la[1] if la else []
        items_b = lb[1] if lb else []
        rows.append(
            {
                "key": k,
                "label": CATEGORY_LABEL[k],
                "count_a": len(items_a),
                "count_b": len(items_b),
                "top_a": items_a[0] if items_a else None,
                "top_b": items_b[0] if items_b else None,
            }
        )
    return rows


def _combo_view(a: dict, b: dict, ctx, pairs) -> dict:
    """사전 계산 비교 요약 (FR-61). 개인화(vdCard)·실효연봉·시간가치는 미렌더(R1)."""
    now = ctx.build_now
    ta = ctx.types_by_cd.get(a["comp_tp_cd"], {})
    tb = ctx.types_by_cd.get(b["comp_tp_cd"], {})
    return {
        "title_h1": f"{a['comp_nm']} vs {b['comp_nm']}",
        "a": _company_summary(a, ta),
        "b": _company_summary(b, tb),
        "work_style_compare": _work_style_compare(
            a.get("work_style_val") or {}, b.get("work_style_val") or {}
        ),
        "category_summary": _category_summary(a["benefits"], b["benefits"], now),
        "compare_href": f"/compare?a={a['comp_eng_nm']}&b={b['comp_eng_nm']}",
    }


def _related(eng_first: str, eng_second: str, ctx, all_pairs):
    """L1 회사 상세(항상 2개) + L2 관련 조합(생성된 것만, FR-63 R1)."""
    a_first, a_second = ctx.by_eng[eng_first], ctx.by_eng[eng_second]
    company_links = [
        (a_first["comp_nm"], f"/company/{ctx.slugs[eng_first]}"),
        (a_second["comp_nm"], f"/company/{ctx.slugs[eng_second]}"),
    ]
    related = []
    for x, y in all_pairs:
        if {x, y} == {eng_first, eng_second}:
            continue
        share = {x, y} & {eng_first, eng_second}
        same_ind = bool(
            ctx.by_eng[x].get("industry_nm")
            and ctx.by_eng[x]["industry_nm"] == ctx.by_eng[eng_first]["industry_nm"]
        )
        if share or same_ind:
            p, _, _ = combo_slug(x, y, ctx.slugs)
            related.append((f"{ctx.by_eng[x]['comp_nm']} vs {ctx.by_eng[y]['comp_nm']}", f"/vs/{p}"))
    return company_links, related[:6]


def _combo_seo(a: dict, b: dict, url: str, cfg) -> dict:
    """조합 SEO head·canonical 정규화 (FR-64)."""
    title = f"{a['comp_nm']} vs {b['comp_nm']} 복지·연봉 비교 | jobcho.wiki"
    desc = (
        f"{a['comp_nm']}과 {b['comp_nm']}의 복지·연봉·근무형태를 한눈에 비교합니다. "
        f"기업정보·근무형태·복지 카테고리별 항목을 대조하고, 비교 툴에서 직접 입력해 확인해 보세요."
    )
    desc = _truncate(desc, cfg.desc_max)
    return {
        "meta_title": title,
        "meta_desc": desc,
        "canonical": url,
        "og": {
            "title": title,
            "description": desc,
            "type": "website",
            "url": url,
            "image": cfg.site_origin + cfg.default_og_image,
        },
    }


def load_pairs(ctx) -> list[tuple[str, str]]:
    """큐레이션 목록 → 유효 조합 쌍(미등록·자기쌍 스킵, FR-60 R1).

    company.py가 회사 페이지의 조합 링크를 그리려면 같은 목록이 필요해
    build.py가 이 함수로 한 번 로드해 양쪽에 전달한다(생성되지 않는 /vs/
    경로를 링크하지 않기 위한 단일 진실).
    """
    raw = json.loads(COMBINATIONS_PATH.read_text(encoding="utf-8"))
    pairs: list[tuple[str, str]] = []
    for item in raw.get("combinations", []):
        a, b = item["a"], item["b"]
        if a not in ctx.by_eng or b not in ctx.by_eng or a == b:
            log.warning("combo skip: invalid/absent %s,%s", a, b)
            continue
        pairs.append((a, b))
    return pairs


def render_all(env, ctx, cfg, pairs=None) -> list[Page]:
    """인기 조합 로드·무효 스킵·경로 검증·렌더 (SP-GEN-7.2)."""
    if pairs is None:
        pairs = load_pairs(ctx)

    validate_combo_paths(pairs, ctx.slugs)  # 경로 충돌 → BuildError(SP-GEN-3)

    tpl = env.get_template("combo.html")
    pages: list[Page] = []
    for a, b in pairs:
        path, first, second = combo_slug(a, b, ctx.slugs)
        eng_first = a if ctx.slugs[a] == first else b
        eng_second = b if eng_first == a else a
        url = f"{cfg.site_origin}/vs/{path}"
        vm = _combo_view(ctx.by_eng[eng_first], ctx.by_eng[eng_second], ctx, pairs)
        company_links, related = _related(eng_first, eng_second, ctx, pairs)
        vm["company_links"] = company_links
        vm["related"] = related
        seo = _combo_seo(ctx.by_eng[eng_first], ctx.by_eng[eng_second], url, cfg)
        html = tpl.render(**vm, **seo, cfg=cfg, footer_links=POLICY_FOOTER_LINKS)
        pages.append(
            Page(
                path=f"vs/{path}.html",
                url=url,
                html=html,
                title=seo["meta_title"],
                description=seo["meta_desc"],
            )
        )
    return pages
