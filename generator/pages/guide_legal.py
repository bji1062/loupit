"""generator/pages/guide_legal.py — 가이드 C편 「복지처럼 보이지만 법으로 정해진 제도」 `/guide/legal-baseline` (SP-GUIDE-11, 2026-10-14, 리드 판정 (94)).

**데이터를 따라가는 글**이다. 문장은 `generator/content/guide_legal.py`(사람이 쓴 정본)이고 숫자는 세 곳에서만 온다.
  · 법 숫자 · 제도 이름 · 표 칸 글자 = `generator/data/legal_baseline.json`(`legal.raw()` 하나 — 이 파일에 법 값을 다시 적지 않는다)
  · 인용 예 = `generator/data/guide/legal-examples.json`(숫자가 든 데이터 — 빌드가 지금 데이터와 대조한다)
  · 데이터 숫자(법정 표시 행 수 · 회사 수 · 직원 수 최솟값) = 빌드 ctx

원칙
  · **결정적** — 빌드 날짜를 HTML 에 넣지 않는다. 같은 데이터면 같은 HTML(날짜 장치는 테스트 쪽 — `next_change.from` 이 지났는지).
  · **조용히 틀린 글 금지** — 문장이 기대는 사실(누가 돈을 내는가 · 인용 예 · 옛 법 일수 · 직원 수 기준)이 어긋나면 `BuildError`(문안 판정 필요).
  · `STRICT_DATA` 가 꺼지면(테스트 conftest 의 fake 번들 — 실제 회사가 없다) ctx 대조와 인용 예를 건너뛴다. 운영 빌드는 항상 켜져 있다.
"""
from __future__ import annotations

import json
import re
from pathlib import Path

from generator import legal, marks
from generator.config import CFG
from generator.content import guide_legal as T
from generator.content import guides as G
from generator.content.policy import POLICY_FOOTER_LINKS
from generator.context import Page
from generator.finance import _josa
from generator.format import benefit_desc
from generator.pages.company import _truncate, benefit_anchor
from generator.pages.home import _korean_date
from generator.slug import BuildError
from generator.trust import welfare_totals

EXAMPLES_PATH = Path(__file__).resolve().parent.parent / "data" / "guide" / "legal-examples.json"
STRICT_DATA = True  # 테스트 conftest 만 끈다(fake 번들에는 실제 회사 · 직원 수가 없다)
INSURED_KEYS = ("maternity_leave", "spouse_birth_leave", "spouse_miscarriage_leave", "infertility_leave")  # 고용보험 급여가 대신 나오는 제도(우선지원 대상기업)
EXAMPLE_ERR = "가이드 C편 인용이 지금 데이터와 다르다 — 문안 판정 필요(리드)"


def load_examples() -> dict:
    return json.loads(EXAMPLES_PATH.read_text(encoding="utf-8"))


def _item(key: str) -> dict:
    it = legal.by_key(key)
    if it is None:
        raise BuildError(f"guide_legal: 법정 기준선 표에 {key!r} 가 없다 — 문안 판정 필요")
    return it


# 인용 예 checks 의 `what` 사전 — 모르는 what 이면 BuildError
def _cap(it: dict) -> int:
    caps = [r["cap"] for r in it["baseline"].get("table", []) if r.get("cap")]
    if not caps:
        raise BuildError(f"guide_legal: {it['key']} 에 cap 이 없다")
    return max(caps)


_WHAT = {
    "value": lambda it: it["baseline"]["value"],
    "cap": _cap,
    "value_minus_employer_paid": lambda it: it["baseline"]["value"] - it["employer_paid_days"],
    "paid": lambda it: it["paid"],
    "prev_value": lambda it: it["prev"]["value"],
}


def _check(checks: list[dict]) -> None:
    for c in checks:
        fn = _WHAT.get(c["what"])
        if fn is None:
            raise BuildError(f"guide_legal: 모르는 인용 검사 {c['what']!r} — 문안 판정 필요(리드)")
        try:
            got = fn(_item(c["key"]))
        except (KeyError, TypeError) as e:
            raise BuildError(f"{EXAMPLE_ERR} ({c['key']}.{c['what']}: {e})") from e
        if got != c["equals"]:
            raise BuildError(f"{EXAMPLE_ERR} ({c['key']}.{c['what']} = {got!r}, 인용은 {c['equals']!r})")


def _law_cell(it: dict) -> str:
    parts = it["law"].split(T.LAW_JOIN)
    if len(parts) > 1:
        return T.LAW_SHORT.format(first=parts[0], n=len(parts))
    return it["law"] if it["article"] in T.LAW_ARTICLE_OMIT else f"{it['law']} {it['article']}"


def _row_in(ctx, eng: str, cd: str, nm: str):
    c = ctx.by_eng.get(eng)
    if c is None:
        return None, None
    for b in c.get("benefits") or []:
        if b.get("benefit_cd") == cd and (b.get("benefit_nm") or "") == nm:
            return c, b
    return c, None


def _screen_text(b: dict) -> str:
    return benefit_desc(b.get("qual_desc_ctnt"), b.get("amt_source"))  # 회사 페이지가 쓰는 같은 함수


def _head_min(ctx) -> int:
    """회사별 최근 연도 직원 수(공시 있는 회사만)의 최솟값. 공시 회사가 하나도 없으면 번들 누락이다."""
    heads = []
    for c in ctx.companies:
        years = ctx.employ.get(c["comp_id"]) or {}
        vals = [(y, v["head"]) for y, v in years.items() if v.get("head") is not None]
        if vals:
            heads.append(max(vals)[1])
    if not heads:
        raise BuildError("guide_legal: 직원 수 공시 회사가 하나도 없다 — 번들 누락 의심(직원 현황이 안 실렸다)")
    return min(heads)


def values(ctx, strict: bool) -> dict:
    """문장 자리표시 값. 문장에 들어가는 모든 수가 여기서 나온다."""
    raw = legal.raw()
    small_cut = raw["small_workplace"]["cut"]
    mat, spouse, infert = _item("maternity_leave"), _item("spouse_birth_leave"), _item("infertility_leave")
    if not (mat["paid"] == "mixed" and _item("parental_leave")["paid"] == "insurance"
            and _item("menstrual_leave")["paid"] == "unpaid" and _item("family_care_leave")["paid"] == "unpaid"):
        raise BuildError("guide_legal: 「돈은 누가 내나」 문장이 기대는 사실(출산전후휴가 mixed · 육아휴직 insurance · 생리휴가 · 가족돌봄휴가 unpaid)이 법정 기준선 표와 다르다 — 문안 판정 필요")
    v = {
        "lb_reviewed": _korean_date(raw["reviewed"]),
        "small_cut": small_cut,
        "mat_paid": mat["employer_paid_days"],
        "spouse_days": spouse["baseline"]["value"], "spouse_prev": spouse["prev"]["value"],
        "infert_days": infert["baseline"]["value"], "infert_paid": infert["employer_paid_days"],
        "lbl_legal": marks.KINDS["legal"]["label"],
    }
    nc = infert.get("next_change")
    v["infert_next"] = bool(nc)
    if nc:
        v["infert_paid_next"], v["infert_next_from"] = nc["employer_paid_days"], _korean_date(nc["from"])
    t = welfare_totals(ctx)
    v["legal_rows"] = t["marked"]["legal"]
    v["legal_comps"] = len({c["comp_id"] for c in ctx.companies for b in (c.get("benefits") or [])
                            if marks.row_mark(c.get("comp_eng_nm") or "", b.get("benefit_cd"), b.get("benefit_nm") or "") == "legal"})
    if strict:
        low = _head_min(ctx)
        if low < small_cut:
            raise BuildError(f"guide_legal: 직원 수 공시가 기준({small_cut}명) 미만인 회사가 생겼다({low}명) — 문안 판정 필요")
    return v


def _validate_examples(ctx, ex: dict) -> None:
    """인용 예를 지금 데이터와 대조한다(어긋나면 BuildError)."""
    for r in ex["legal_rows"]:
        c, b = _row_in(ctx, r["comp_eng_nm"], r["benefit_cd"], r["benefit_nm"])
        if b is None or marks.row_mark(r["comp_eng_nm"], r["benefit_cd"], r["benefit_nm"]) != "legal" or _screen_text(b) != r["quote"]:
            raise BuildError(f"{EXAMPLE_ERR} (법정 행 {r['comp_eng_nm']}/{r['benefit_nm']})")
    for g in ex["good"]:
        c, b = _row_in(ctx, g["comp_eng_nm"], g["benefit_cd"], g["benefit_nm"])
        if b is None or g["quote"] not in _screen_text(b) or marks.row_mark(g["comp_eng_nm"], g["benefit_cd"], g["benefit_nm"]) is not None:
            raise BuildError(f"{EXAMPLE_ERR} (좋은 예 {g['comp_eng_nm']}/{g['benefit_nm']})")
        _check(g["checks"])
    _validate_old_law(ex["old_law"])


def _validate_old_law(o: dict) -> None:
    _check(o["checks"])
    m = re.search(r"(\d+)일에 추가로 (\d+)일", o["quote"])
    if not m:
        raise BuildError(f"{EXAMPLE_ERR} (옛 법 인용에서 「N일에 추가로 N일」을 못 찾았다)")
    if int(m.group(1)) + int(m.group(2)) > _item("spouse_birth_leave")["baseline"]["value"]:
        raise BuildError(f"{EXAMPLE_ERR} (옛 법 인용의 합이 지금 법정 일수보다 크다 — 더 주는 날이 생겼다)")


def build_view(ctx, examples: dict | None = None, strict: bool | None = None) -> dict:
    """뷰모델(순수에 가깝다 — JSON 두 개와 ctx 만 읽는다)."""
    strict = STRICT_DATA if strict is None else strict
    ex = examples if examples is not None else load_examples()
    v = values(ctx, strict)
    items = legal.items()
    by_key = {it["key"]: it for it in items}
    keys_grouped = [k for _, ks in T.GROUPS for k in ks]
    if sorted(keys_grouped) != sorted(by_key):
        raise BuildError("guide_legal: 표 묶음의 key 가 법정 기준선 표의 항목과 다르다(빠짐 또는 남음) — 문안 판정 필요")
    if strict:
        _validate_examples(ctx, ex)
    else:
        ex = dict(ex, legal_rows=[], good=[])
        _validate_old_law(ex["old_law"])
    f = lambda tpl, **kw: tpl.format(**{**v, **kw})  # noqa: E731

    groups = [{"name": name, "rows": [
        {"name": by_key[k]["name"], "basis": by_key[k]["guide"]["basis"], "law": _law_cell(by_key[k]), "pay": by_key[k]["guide"]["pay"],
         "small": T.SMALL_YES if by_key[k]["small_ok"] else T.SMALL_NO}
        for k in ks]} for name, ks in T.GROUPS]

    small_names = [it["name"] for it in items if not it["small_ok"]]
    insured_names = [by_key[k]["name"] for k in INSURED_KEYS]
    smalls = [f(T.SMALL_NOTE_ONE, names=T.NAME_JOIN.join(small_names), eun=_josa(small_names[-1], "은", "는"))]
    if by_key["labor_day"].get("small_note"):
        smalls.append(f(T.SMALL_NOTE_LABOR))
    smalls.append(f(T.INSURED_NOTE, names=T.NAME_JOIN.join(insured_names), eun=_josa(insured_names[-1], "은", "는")))
    smalls.append(T.ABBR_NOTE)
    for it in sorted((i for i in items if i.get("next_change")), key=lambda i: i["next_change"]["from"]):
        nc = it["next_change"]
        smalls.append(T.NEXT_CHANGE.format(date=_korean_date(nc["from"]), name=it["name"], text=nc["text"], law_no=nc["law_no"]))
    smalls.append(T.NOT_IN_TABLE)

    old_quote = ex["old_law"]["quote"]
    change_small = [f(T.CHANGE_INFERTILITY)] if v["infert_next"] else []
    change_small.append(T.CHANGE_P3)
    ask_tail = f(T.INFERT_Q_NEXT) if v["infert_next"] else ""
    ask = [{"q": q, "a": f(a, infert_q_next=ask_tail)} for q, a in T.ASK]

    good = [{"company": ctx.by_eng[g["comp_eng_nm"]]["comp_nm"],
             "href": f"/company/{ctx.slugs[g['comp_eng_nm']]}#{benefit_anchor(g['benefit_cd'], g['benefit_nm'])}",
             "tail": T.GOOD_ITEM_TAIL.format(label=g["label"], quote=g["quote"])} for g in ex["good"]]
    return {
        "crumb": {"href": G.LIST_ROUTE, "root": T.CRUMB_ROOT, "tail": T.CRUMB_TAIL},
        "h1": T.H1, "meta": f(T.META), "lead": T.LEAD,
        "line": {"h": T.H_LINE, "intro": T.LINE_INTRO, "cap": f(T.TABLE_CAP),
                 "cols": [T.COL_NAME, T.COL_BASIS, T.COL_LAW, T.COL_PAY, f(T.COL_SMALL)], "groups": groups, "smalls": smalls},
        "who": {"h": T.H_WHO, "paras": [f(T.WHO_P1), T.WHO_P2]},
        "how": {"h": T.H_HOW, "paras": [T.HOW_P1] + ([f(T.HOW_P2)] if v["legal_rows"] else []) + [T.HOW_P3]},
        "bad": {"h": T.H_BAD, "intro": T.BAD_INTRO, "quotes": [r["quote"] for r in ex["legal_rows"]], "after": T.BAD_AFTER,
                "mixed_intro": T.MIXED_INTRO, "mixed_quote": ex["mixed_list"]["quote"], "mixed_after": T.MIXED_AFTER},
        "good": {"h": T.H_GOOD, "intro": T.GOOD_INTRO, "list": good, "after": T.GOOD_AFTER},
        "change": {"h": T.H_CHANGE, "p1": T.CHANGE_P1, "p2": f(T.CHANGE_P2, old_law_quote=old_quote), "smalls": change_small},
        "ask": {"h": T.H_ASK, "list": ask},
        "end": f(T.END_LINE),
        "data_link": {"href": G.DATA_ROUTE, "text": T.DATA_LINK},
    }


def render(env, ctx, cfg=CFG) -> Page:
    view = build_view(ctx)
    url = f"{cfg.site_origin}{G.LEGAL_ROUTE}"
    title = f"{T.TITLE} | {cfg.site_name}"
    desc = _truncate(T.LEAD.split(". ")[0] + ". " + T.DESCRIPTION_TAIL, cfg.desc_max)
    html = env.get_template("guide_legal.html").render(
        view=view, meta_title=title, meta_desc=desc, canonical=url,
        og={"title": title, "description": desc, "type": "website", "url": url,
            "image": cfg.site_origin + cfg.default_og_image},
        cfg=cfg, footer_links=POLICY_FOOTER_LINKS, nav_active=G.LIST_ROUTE,
    )
    return Page(path=G.LEGAL_PATH, url=url, html=html, title=title, description=desc)
