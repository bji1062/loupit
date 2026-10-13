"""generator/pages/guide_total_comp.py — 가이드 B편 「복지를 연봉에 더해 보는 법」 `/guide/total-compensation` (SP-GUIDE-10, 2026-10-13, 리드 판정 (90)(91)).

**고정판이 아니라 계산기를 따라가는 글**이다. 예시 숫자는 전부 `generator/data/guide/total-compensation.json` 에서만 읽는다
(`input` = 예시 입력 정본, `output` · `K` = 이직 계산기 `calc.js` 가 낸 값 · 상수 — `node infra/tools/guide_total_comp.mjs` 가 만든다).
빌드(파이썬)에 node 를 들이지 않는다. 계산기 계산이 바뀌면 프런트 테스트(`web/test/guide-total-comp.test.js`)가 실패해 JSON 을 다시 만들게 한다.
문장은 `generator/content/guide_total_comp.py`(사람이 쓴 정본) · 그림(표 · 막대)은 HTML/CSS 만(JS 없음)이고 같은 숫자를 글자로 함께 싣는다.

원칙
  · **결정적** — 빌드 날짜를 HTML 에 넣지 않는다. 빌드 ctx 의 숫자도 이 페이지에 들어오지 않는다(`render` 가 ctx 를 받는 것은 호출 모양을 맞추기 위해서일 뿐이다).
  · **라벨은 사이트 정본에서** — 금액 종류 = `company.LENS_BUCKETS`(「회사 공식 수치」 · 「추정치」), 「금액 미등록」 = `about_data.KIND_NONE_LABEL`.
    상수 자리표시: 만료 개월 = `about_data.EXPIRE_MONTHS`, 익명 비교 기록 보관 일수 = `policy._RETENTION['compare_days']`, 나머지는 JSON 의 `K`.
  · **조용히 틀린 글 금지** — 아래 문장은 예시의 결론 방향(연봉은 오르고 총보상은 줄고, 야근수당 방식 하나로 뒤집힘)에 기댄다. 방향이 어긋나면 `BuildError`(문안 판정 필요).
"""
from __future__ import annotations

import json
import math
from pathlib import Path

from generator.config import CFG
from generator.content import about_data as D
from generator.content import guide_total_comp as T
from generator.content import guides as G
from generator.content.policy import _RETENTION, POLICY_FOOTER_LINKS
from generator.context import Page
from generator.finance import _josa
from generator.pages import about_data as AD
from generator.pages.company import LENS_BUCKETS, _truncate
from generator.slug import BuildError

MINUS = "−"  # 음수 글자 — 계산기 화면(`report-calc.js`)이 쓰는 U+2212(−)와 같다
DATA_PATH = Path(__file__).resolve().parent.parent / "data" / "guide" / "total-compensation.json"  # 예시 정본(`infra/tools/guide_total_comp.mjs` 가 output · K 를 쓴다)


def load_example() -> dict:
    return json.loads(DATA_PATH.read_text(encoding="utf-8"))


def _n(v) -> str:
    return f"{v:,}"  # 천 단위 쉼표


def _p(v: float) -> str:
    return f"{v:.1f}"  # 비율 소수 1자리


def _g(v) -> str:
    return f"{v:g}"  # 1.5 · 4.33 · 209 처럼 군더더기 없이


def _pct(v: float) -> str:
    return _g(round(v * 100, 4))  # 0.05 → 5, 0.03 → 3


def _sign(v: int) -> str:
    """부호 붙인 정수(계산기 화면 관례 — 음수 U+2212, 양수 +, 0 은 부호 없음)."""
    return (f"+{_n(v)}" if v > 0 else f"{MINUS}{_n(-v)}" if v < 0 else "0")


def _check_direction(o: dict) -> None:
    """문안이 기대는 예시의 결론 방향 — 어긋나면 글이 거짓이 된다(조용히 틀린 글 금지)."""
    d, rng, be, nb = o["deltas"], o["range"], o["breakeven"]["full"], o["breakeven"]["noBenefit"]
    ok = (
        d["salMid"] > 0 and d["totalDiff"] < 0 and rng[0] < 0 and rng[1] < 0 and o["tier"] == "a"
        and d["benDiff"] < 0 and d["otDiff"] < 0  # 「복지와 야근수당 차이로 … 줄어듭니다」
        and not nb["bound"] and nb["sal"] > o["a"]["sal"]  # 「복지를 아예 빼고 계산하면 …만원(…% 인상)」
        and o["flip"] and o["flip"]["key"] == "b_wage_flip" and o["flip"]["result"] == "flip" and o["flip"]["totalDiff"] > 0
        and not be["bound"] and o["b"]["sal"] < be["sal"]
    )
    if not ok:
        raise BuildError("guide_total_comp: 예시 결론이 바뀌었다 — 문안 판정 필요(리드). 계산기 계산이 바뀌었는지 확인하고 글 문장을 다시 본다")


def _check_identities(doc: dict) -> None:
    """예시 숫자끼리의 항등식 — 하나라도 어긋나면 JSON 이 손상됐거나 계산기 정의가 바뀐 것이다."""
    i, o = doc["input"], doc["output"]
    a, b, d = o["a"], o["b"], o["deltas"]
    if d["salMid"] + d["benDiff"] + d["otDiff"] != d["totalDiff"] or b["total"] - a["total"] != d["totalDiff"]:
        raise BuildError("guide_total_comp: 막대 합이 총보상 차이와 다르다 — 문안 판정 필요")
    for s, side in (("a", a), ("b", b)):
        if side["sal"] + side["net"] + side["ot"] != side["total"]:
            raise BuildError(f"guide_total_comp: {s} 쪽 연봉 + 복지 + 야근수당 ≠ 총보상")
        if sum(x["amount"] or 0 for x in i["benefits"][s]) != side["net"]:
            raise BuildError(f"guide_total_comp: {s} 쪽 표의 복지 금액 합 ≠ 계산기 복지 합")
    if i["work"]["b"].get("wage") != "inclusive" or b["ot"] != 0 or i["work"]["a"].get("wage") != "separate":
        raise BuildError("guide_total_comp: 표의 야근수당 칸(따로 받음 · 포괄) 문장이 입력과 어긋난다 — 문안 판정 필요")


def values(doc: dict) -> dict:
    """JSON → 문장 자리표시 값. 문장에 들어가는 모든 수가 여기서 나온다."""
    i, o, k = doc["input"], doc["output"], doc["K"]
    a, b, d = o["a"], o["b"], o["deltas"]
    be, nb = o["breakeven"]["full"], o["breakeven"]["noBenefit"]
    lens = {key: label for key, label, _ in LENS_BUCKETS}
    v = {f"lbl_{key}": text for key, text in T.SCREEN_LABELS.items()}
    v.update({
        "stated_label": lens["stated"], "est_label": lens["est"], "none_label": D.KIND_NONE_LABEL,
        "stated_eun": _josa(lens["stated"], "은", "는"), "est_eun": _josa(lens["est"], "은", "는"),  # A편과 같은 조사 함수
        "benefit_value_eun": _josa(T.SCREEN_LABELS["benefit_value"], "은", "는"),
        "hourly_eun": _josa(T.SCREEN_LABELS["hourly"], "은", "는"), "hourly_eul": _josa(T.SCREEN_LABELS["hourly"], "을", "를"),
        "nameA": T.COL_A, "nameB": T.COL_B,
        "salA": _n(a["sal"]), "salB": _n(b["sal"]), "raise": _g(i["raise_pct"]),
        "salMid": _n(d["salMid"]), "diffAbs": _n(abs(d["totalDiff"])),
        "rangeLo": _sign(o["range"][0]), "rangeHi": _sign(o["range"][1]), "monthly": _sign(o["monthly"]),
        "hourPct": (MINUS if o["hourlyPct"] < 0 else "+") + str(math.floor(abs(o["hourlyPct"]) * 100 + 0.5)),  # 화면 `Math.round` 처럼 0.5 는 올림(파이썬 round 는 짝수 쪽이라 다르다)
        "be": _n(be["sal"]), "beRate": _p(be["rate"] * 100), "beNoBen": _n(nb["sal"]), "beNoBenRate": _p(nb["rate"] * 100),
        "flip": _n(o["flip"]["totalDiff"]),
        "K_40": _g(k["LEGAL_WEEK_HRS"]), "K_ot": _g(k["OT_MULT"]), "K_wpm": _g(k["WEEKS_PER_MONTH"]), "K_209": _g(k["MONTHLY_STD_HRS"]),
        "K_52": _g(k["WEEKS_PER_YEAR"]), "K_240": _g(k["COMMUTE_WORKDAYS"]),
        "K_st": _pct(k["BAND_BASE"]["stated"]), "K_es": _pct(k["BAND_BASE"]["estimated"]), "K_exp": _pct(k["BAND_EXPIRE"]),
        "near_pct": _pct(k["AXIS_THRESHOLDS"]["nearTotalPct"]), "near_mult": _g(k["AXIS_THRESHOLDS"]["nearBandMult"]),
        "exp_months": AD.EXPIRE_MONTHS, "compare_days": _RETENTION["compare_days"],
        "step_benefit": 1 + [h for h, _ in T.STEPS].index("복지 금액"),
    })
    return v


def build_view(doc: dict) -> dict:
    """뷰모델(순수) — JSON dict 만 읽는다."""
    _check_direction(doc["output"])
    _check_identities(doc)
    i, o = doc["input"], doc["output"]
    a, b, d = o["a"], o["b"], o["deltas"]
    v = values(doc)
    f = lambda tpl: tpl.format(**v)  # noqa: E731
    kind_label = {"stated": v["stated_label"], "estimated": v["est_label"]}
    for s in ("a", "b"):
        for x in i["benefits"][s]:
            if x["amount"] is not None and x["source"] not in kind_label:
                raise BuildError(f"guide_total_comp: 금액 있는 복지 「{x['name']}」의 source {x['source']!r} 는 stated · estimated 가 아니다 — 문안 판정 필요")

    def stated_cell(s: str) -> list[str]:
        return [T.CELL_BENEFIT.format(nm=x["name"], amt=_n(x["amount"]), kind=kind_label[x["source"]])
                for x in i["benefits"][s] if x["amount"] is not None]

    def none_cell(s: str) -> str:
        names = [x["name"] for x in i["benefits"][s] if x["amount"] is None]
        return T.CELL_NAMES_JOIN.join(names) if names else T.CELL_NONE_EMPTY

    def ot_cell(s: str) -> str:
        wage = i["work"][s]["wage"]
        return T.CELL_OT_SEPARATE.format(ot=_n(o[s]["ot"])) if wage == "separate" else T.CELL_OT_INCLUSIVE

    table = {
        "cap": f(T.TABLE_CAP), "cols": (T.COL_A, T.COL_B),
        "rows": [
            {"k": T.ROW_SALARY, "cells": [[T.CELL_SALARY.format(v=_n(a["sal"]))], [T.CELL_SALARY.format(v=_n(b["sal"]))]]},
            {"k": T.ROW_STATED, "cells": [stated_cell("a"), stated_cell("b")]},
            {"k": f(T.ROW_NONE), "cells": [[none_cell("a")], [none_cell("b")]]},
            {"k": T.ROW_HOURS, "cells": [[T.CELL_HOURS.format(h=i["work"]["a"]["hours"])], [T.CELL_HOURS.format(h=i["work"]["b"]["hours"])]]},
            {"k": T.ROW_OT, "cells": [[ot_cell("a")], [ot_cell("b")]]},
            {"k": f(T.ROW_TOTAL), "cells": [[T.CELL_TOTAL.format(v=_n(a["total"]))], [T.CELL_TOTAL.format(v=_n(b["total"]))]],
             "sub": [T.CELL_BAND.format(band=_n(a["band"])), T.CELL_BAND.format(band=_n(b["band"]))]},
            {"k": f(T.ROW_HOURLY), "cells": [[T.CELL_HOURLY.format(v=_n(a["hourly"]))], [T.CELL_HOURLY.format(v=_n(b["hourly"]))]]},
        ],
    }

    parts = [(T.BAR_SAL, d["salMid"]), (T.BAR_BEN, d["benDiff"]), (T.BAR_OT, d["otDiff"]), (T.BAR_TOTAL, d["totalDiff"])]
    scale = max(abs(x) for _, x in parts)
    bars = [{"label": label, "val": _sign(x), "dir": "up" if x > 0 else "down",
             "left": round(50 - abs(x) / scale * 50, 1) if x < 0 else 50.0, "w": round(abs(x) / scale * 50, 1), "total": label == T.BAR_TOTAL}
            for label, x in parts]

    steps = [{"head": f(h), "text": f(t)} for h, t in T.STEPS]
    nots = [{"text": f(t), "link": {"href": "/privacy", "text": T.NOT_PRIVACY_LINK} if n == T.NOT_PRIVACY_INDEX else None}
            for n, t in enumerate(T.NOT_LIST)]
    return {
        "crumb": {"href": G.LIST_ROUTE, "root": T.CRUMB_ROOT, "tail": T.CRUMB_TAIL},
        "h1": T.H1, "meta": T.META, "lead": T.LEAD,
        "example": {"h": T.H_EXAMPLE, "intro": f(T.EXAMPLE_INTRO), "table": table},
        "verdict": {"main": f(T.VERDICT), "sub": f(T.VERDICT_SUB)},
        "bars": {"cap": T.BARS_CAP, "rows": bars},
        "breakeven": f(T.BREAKEVEN), "flip": f(T.FLIP),
        "steps": {"h": T.H_STEPS, "list": steps},
        "nots": {"h": T.H_NOT, "list": nots},
        "cta": {"href": G.COMPARE_ROUTE, "text": T.CTA_LINK},
        "data_link": {"href": G.DATA_ROUTE, "text": T.DATA_LINK},
    }


def render(env, ctx=None, cfg=CFG) -> Page:
    """`ctx` 는 쓰지 않는다(위 머리말) — 호출 모양만 다른 생성 페이지와 같다."""
    doc = load_example()
    view = build_view(doc)
    url = f"{cfg.site_origin}{G.TOTAL_ROUTE}"
    title = f"{T.TITLE} | {cfg.site_name}"
    desc = _truncate(T.LEAD.split(". ")[0] + ". " + T.DESCRIPTION_TAIL, cfg.desc_max)
    html = env.get_template("guide_total_comp.html").render(
        view=view, meta_title=title, meta_desc=desc, canonical=url,
        og={"title": title, "description": desc, "type": "website", "url": url,
            "image": cfg.site_origin + cfg.default_og_image},
        cfg=cfg, footer_links=POLICY_FOOTER_LINKS, nav_active=G.LIST_ROUTE,
    )
    return Page(path=G.TOTAL_PATH, url=url, html=html, title=title, description=desc)
