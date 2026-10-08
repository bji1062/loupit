"""generator/pages/guide_report.py — 가이드 A편 「복지 공개 현황」 `/guide/report-<판>` (SP-GUIDE-7, 2026-10-08, 리드 판정 (86)).

**날짜 고정판**이다. 숫자는 전부 `generator/data/guide/report-<판>.json`(스냅숏)에서만 읽는다 — 빌드 ctx 의 숫자는 이 페이지에 들어오지 않는다
(`render` 가 ctx 를 받는 것은 다른 생성 페이지와 호출 모양을 맞추기 위해서일 뿐이고, 쓰지 않는다. 테스트가 ctx 를 바꿔도 HTML 이 같음을 지킨다).
문장은 `generator/content/guide_report.py`(사람이 쓴 정본) · 그림 셋은 HTML/CSS 만(JS 없음)이고 각 그림은 같은 숫자를 글자로 함께 싣는다.

원칙
  · **링크는 실제로 생성된 항목 페이지에만** 건다 — `benefit_links`(`benefit.links(...)`)에 있는 코드만. 스냅숏의 slug 는 기록일 뿐 링크 근거가 아니다
    (문턱에 걸려 안 만들어진 항목에 링크 = 죽은 링크, GC-20).
  · 라벨은 스냅숏(항목 페이지 제목 → 복지검색 표시명)에서 읽고, 금액 갈래 라벨은 D편과 같은 정본(`company.LENS_BUCKETS` · `about_data.KIND_NONE_LABEL`)이다.
  · 결정적 — 빌드 날짜를 HTML 에 넣지 않는다.
"""
from __future__ import annotations

from generator import guide_report as snap_mod
from generator.config import CFG
from generator.content import about_data as D
from generator.content import guide_report as T
from generator.content import guide_report_editions as E
from generator.content import guides as G
from generator.content.policy import POLICY_FOOTER_LINKS
from generator.context import Page
from generator.finance import _josa
from generator.pages.company import LENS_BUCKETS, _truncate
from generator.slug import BuildError
from generator.pages.home import _korean_date


def _n(v) -> str:
    return f"{v:,}"  # 천 단위 쉼표(페이지 안의 모든 수가 같은 표기)


def _p(v) -> str:
    return f"{v:.1f}"  # 비율 소수 1자리


def _m(v) -> str:
    return f"{v:g}"  # 중앙값 — 정수면 24, 반이면 24.5


def facts_for(edition: str) -> dict:
    return snap_mod.load_snapshot(edition)


def values(s: dict) -> dict:
    """스냅숏 → 문장 자리표시 값. 문장에 들어가는 모든 수가 여기서 나온다."""
    top, a, g, mk = s["top"], s["amount"], s["gap"], s["marks"]
    t1, t2, t3 = top[0], top[1], top[2]
    lens = {k: label for k, label, _ in LENS_BUCKETS}
    return {
        "stated_label": lens["stated"], "est_label": lens["est"],  # 「회사 공식 수치」 「추정치」 — 사이트 정본 라벨
        "N": _n(s["N"]), "large": _n(s["large"]), "mid": _n(s["mid"]),
        "edition_ko": s["edition_ko"], "asof_ko": _korean_date(s["asof"]),
        "rows": _n(s["rows"]), "counted": _n(s["counted"]), "codes": _n(s["codes"]), "names": _n(s["names"]),
        "legal_rows": _n(mk["legal"]["rows"]), "legal_comps": _n(mk["legal"]["comps"]),
        "work_edu_rows": _n(mk["work_edu"]["rows"]), "work_edu_comps": _n(mk["work_edu"]["comps"]),
        "summary_rows": _n(mk["summary"]["rows"]), "summary_comps": _n(mk["summary"]["comps"]),
        "vmin_ko": _korean_date(s["vmin"]), "vmax_ko": _korean_date(s["vmax"]),
        "half": _n(len(s["half"])),
        "top1_label": t1["label"], "top1_n": _n(t1["comps"]), "top1_pct": _p(t1["pct"]),
        "top1_eun": _josa(t1["label"], "은", "는"),
        "top2_label": t2["label"], "top2_n": _n(t2["comps"]),
        "top3_label": t3["label"], "top3_n": _n(t3["comps"]),
        "gwa": "과",  # 바로 앞 낱말이 「곳」이다(받침 있음) — 「…(130곳)과」. 라벨이 아니라 숫자 꼬리에 붙는 조사다
        "st_n": _n(a["stated"]["n"]), "st_pct": _p(a["stated"]["pct"]),
        "es_n": _n(a["estimated"]["n"]), "es_pct": _p(a["estimated"]["pct"]),
        "no_n": _n(a["none"]["n"]), "no_pct": _p(a["none"]["pct"]),
        "zero_amt": _n(a["zero_comps"]), "st_comp": _n(a["stated_comps"]),
        "st_top_label": a["stated_top"]["label"], "st_top_n": _n(a["stated_top"]["n"]),
        "min_comps": _n(g["min_comps"]),
        "mid_labels": T.LABEL_JOIN.join(e["label"] for e in g["mid_more"]),
        "large_labels": T.LABEL_JOIN.join(e["label"] for e in g["large_more"]),
        "med_large": _m(g["median_large"]), "med_mid": _m(g["median_mid"]),
        "meal_large_pct": _p(s["meal_large_pct"]),
    }


def build_view(s: dict, benefit_links: dict | None = None) -> dict:
    """뷰모델(순수) — 스냅숏 dict 만 읽는다."""
    links = benefit_links or {}
    ed = E.for_edition(s["edition"])
    for side in ("mid_more", "large_more"):  # 이 판의 묘사가 본 항목과 스냅숏이 같아야 한다 — 다르면 문안 판정 필요
        got = tuple(e["code"] for e in s["gap"][side])
        if got != tuple(ed["gap_codes"][side]):
            raise BuildError(f"guide_report {s['edition']}: gap {side} 항목 {got} 이 판별 문안이 본 {ed['gap_codes'][side]} 와 다르다(리드 판정 필요)")
    v = values(s)
    f = lambda tpl: tpl.format(**v)  # noqa: E731

    def bar_item(e: dict) -> dict:
        return {"label": e["label"], "href": links.get(e["code"]), "val": T.BAR_VAL.format(pct=_p(e["pct"]), comps=_n(e["comps"])), "w": e["pct"]}

    def dumbbell_item(e: dict) -> dict:
        lo, hi = sorted((e["large_pct"], e["mid_pct"]))
        return {"label": e["label"], "href": links.get(e["code"]), "val": T.DUMB_VAL.format(large=_p(e["large_pct"]), mid=_p(e["mid_pct"])),
                "large_w": e["large_pct"], "mid_w": e["mid_pct"], "lo": lo, "span": round(hi - lo, 1)}

    lens = {k: label for k, label, _ in LENS_BUCKETS}
    a = s["amount"]
    seg = [
        {"cls": "stated", "label": lens["stated"], "val": T.SEG_VAL.format(n=_n(a["stated"]["n"]), pct=_p(a["stated"]["pct"])), "w": a["stated"]["pct"]},
        {"cls": "est", "label": lens["est"], "val": T.SEG_VAL.format(n=_n(a["estimated"]["n"]), pct=_p(a["estimated"]["pct"])), "w": a["estimated"]["pct"]},
        {"cls": "none", "label": D.KIND_NONE_LABEL, "val": T.SEG_VAL.format(n=_n(a["none"]["n"]), pct=_p(a["none"]["pct"])), "w": a["none"]["pct"]},
    ]

    read = []
    for i, tpl in enumerate(T.READ_ITEMS):
        item = {"text": f(tpl), "link": None}
        if i == T.READ_ITEM_NAMES_LINK:
            item["link"] = {"href": G.DATA_ROUTE, "text": T.READ_DATA_LINK}
        read.append(item)

    edu_href = links.get(snap_mod.CHILD_EDU_CD)
    return {
        "crumb": {"href": G.LIST_ROUTE, "root": T.CRUMB_ROOT, "tail": T.CRUMB_TAIL},
        "h1": f(T.H1),
        "meta": f(T.META),
        "lead": f(T.LEAD),
        "before": {"h": T.BEFORE_H, "text": T.BEFORE},
        "cards": [{"k": f(k), "v": f(val), "s": f(sub)} for k, val, sub in ed["cards"]],
        "half": {
            "h": f(T.H_HALF), "cap": f(T.FIG1_CAP), "bars": [bar_item(e) for e in s["half"]],
            "top": f(T.HALF_TOP), "edu": ed["half_edu"],
            "edu_link": {"href": edu_href, "text": T.HALF_EDU_LINK} if edu_href else None,
        },
        "amount": {
            "h": f(T.H_AMOUNT), "segs": seg, "counts": f(T.AMOUNT_COUNTS), "companies": f(T.AMOUNT_COMPANIES),
            "calc": T.AMOUNT_CALC, "link": {"href": G.DATA_ROUTE, "text": T.AMOUNT_LINK},
        },
        "gap": {
            "h": T.H_GAP, "rule": f(T.GAP_RULE), "read": f(ed["gap_read"]),
            "legend_large": f(T.FIG3_LEGEND_LARGE), "legend_mid": f(T.FIG3_LEGEND_MID), "mid_cap": T.FIG3_MID_CAP, "large_cap": T.FIG3_LARGE_CAP,
            "mid_rows": [dumbbell_item(e) for e in s["gap"]["mid_more"]],
            "large_rows": [dumbbell_item(e) for e in s["gap"]["large_more"]],
            "box": {"h": T.GAP_BOX_H, "text": f(ed["gap_box"])},
        },
        "read": {"h": T.H_READ, "list": read},
    }


def render(env, ctx=None, cfg=CFG, benefit_links: dict | None = None, edition: str | None = None) -> Page:
    """`ctx` 는 쓰지 않는다(위 머리말) — 호출 모양만 다른 생성 페이지와 같다."""
    edition = edition or G.REPORT_EDITIONS[0]
    s = facts_for(edition)
    view = build_view(s, benefit_links)
    v = values(s)
    route, path = G.report_route(edition), G.report_path(edition)
    url = f"{cfg.site_origin}{route}"
    title = f"{T.TITLE.format(**v)} | {cfg.site_name}"
    desc = _truncate(T.LEAD.split(". ")[0].format(**v) + ". " + T.DESCRIPTION_TAIL.format(**v), cfg.desc_max)
    html = env.get_template("guide_report.html").render(
        view=view, meta_title=title, meta_desc=desc, canonical=url,
        og={"title": title, "description": desc, "type": "website", "url": url,
            "image": cfg.site_origin + cfg.default_og_image},
        cfg=cfg, footer_links=POLICY_FOOTER_LINKS, nav_active=G.LIST_ROUTE,
    )
    return Page(path=path, url=url, html=html, title=title, description=desc)


def render_all(env, ctx=None, cfg=CFG, benefit_links: dict | None = None) -> list[Page]:
    return [render(env, ctx, cfg, benefit_links, ed) for ed in G.REPORT_EDITIONS]
