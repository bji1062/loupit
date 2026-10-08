"""generator/pages/about_data.py — 데이터 안내 `/about/data` (가이드 D편, SP-GUIDE, 2026-10-06).

애드센스 2차 거절(스팸 정책 3유형 — 빈약한 제휴 · 스크랩 · 도어웨이, 도어웨이 유력) 대응으로 쓰는 **고유 글** 한 편이다. 사이트가 데이터를 어디서
가져오고 · 어떻게 나누고 · 금액을 어떻게 표시하고 · 언제 다시 확인하는지를 **그때그때의 실제 숫자**로 적는다.
문장은 `generator/content/about_data.py`(사람이 쓴 정본) · 숫자는 이 모듈이 빌드 데이터에서 센다.

원칙
  · **같은 집계 · 같은 라벨** — 전체 · 공식 수치 · 추정 · 금액 미등록은 대문과 같은 `trust.welfare_totals`,
    카테고리 라벨은 `company.CATEGORY_*`, 표시 라벨은 `marks`, 배지 라벨은 `format.badge_state`,
    재무 · 직원 회사 수는 회사 페이지가 카드를 그리는 규칙(`employ.company_metrics`)에서 읽는다.
    두 곳이 같은 사실을 말하는데 따로 세면 둘 다 못 믿게 된다(배지 함정, 2026-07-31).
  · **결정적** — 빌드 날짜를 HTML 에 넣지 않는다. 기준일은 복지 확인일의 **최댓값**이다. 빌드 날짜를 찍으면 릴리스마다
    본문이 바뀌어 sitemap lastmod · IndexNow 가 거짓으로 갱신된다(`release.lastmod_index` 는 내용 지문으로 정한다).
  · **없는 것은 문장째 뺀다** — 검색 요약 회사가 0이면 그 문장이 없다. 「0곳」을 적지 않는다.
  · **거짓이 될 문장은 빌드를 멈춘다** — 「이 항목들에는 금액을 넣지 않습니다」는 검색 요약 행이 전부 금액 없음일 때만
    참이다. 아니면 `BuildError`(조용히 틀린 말을 싣지 않는다).
"""
from __future__ import annotations

from collections import Counter
from datetime import datetime

from generator import benefit_rules, marks
from generator.config import CFG
from generator.content import about_data as T
from generator.content.policy import POLICY_FOOTER_LINKS
from generator.context import Page
from generator.employ import company_metrics
from generator.finance import _josa
from generator.format import badge_state, iso_date
from generator.pages.company import CATEGORY_LABEL, CATEGORY_ORDER, LENS_BUCKETS, _truncate
from generator.pages.home import _korean_date
from generator.slug import BuildError
from generator.trust import welfare_totals

ROUTE = "/about/data"
GUIDE_LIST_ROUTE = "/guide"  # 가이드 탭 · 목록 (content/guides.py::LIST_ROUTE 와 같다 — 테스트가 대조)
PATH = "about/data.html"

# ── 코드 정본과 맞물리는 상수 — 테스트가 원본과 대조한다(`test_about_data.py`) ────────────────────
# 이직 계산기 밴드(`web/assets/js/calc.js` 의 BAND_BASE.stated · BAND_BASE.estimated · BAND_EXPIRE) — 비율(0.05)이 아니라 %.
BAND_STATED_PCT = 5
BAND_ESTIMATED_PCT = 20
BAND_EXPIRE_PP = 15
# 만료 규칙 — 확인일 + 18개월(`server/services/benefit_edit.py` 의 `INTERVAL 18 MONTH`, 시드도 같다).
EXPIRE_MONTHS = 18

RESORT_CD = "resort"
RESORT_CHIPS = 10  # 이름 칩 수(빈도순 상위)

_NATIVE_COUNT = {1: "한", 2: "두", 3: "세", 4: "네", 5: "다섯", 6: "여섯", 7: "일곱", 8: "여덟", 9: "아홉", 10: "열"}


def native_count(n: int) -> str:
    """개수 앞에 붙는 고유어 수사(「아홉」 개). 열 개를 넘으면 숫자를 그대로 쓴다."""
    return _NATIVE_COUNT.get(n, str(n))


def _fold(name: str) -> str:
    """이름 묶음 키 — 대소문자만 다른 이름(`PC-OFF` · `PC-off`)은 같은 이름이다(DB 의 DISTINCT 와 같은 판정)."""
    return (name or "").strip().casefold()


def _probe(kind: str) -> dict:
    """배지 라벨을 `format.badge_state` 에서 얻기 위한 최소 행 — 라벨을 이 모듈에 다시 적지 않는다."""
    return {
        "stale": {"expires_dtm": "1999-01-01"},
        "official": {"badge_cd": "official"},
        "edited": {"edit_origin": "edited"},
        "member": {"edit_origin": "member"},
    }[kind]


def _badge_view(kind: str) -> dict:
    s = badge_state(_probe(kind), datetime(2000, 1, 1))
    return {"code": s["code"], "label": s["label"]}


def counts(ctx) -> dict:
    """페이지의 모든 숫자 — 순수 함수(테스트가 합성 ctx 로 정의 하나하나를 검사한다). 값은 정수 · 문자열 날짜.

    정의는 SPEC 21 §숫자 표와 같다. 0 처리(문장 생략)는 `build_view` 가 한다.
    """
    rows = [(c, b) for c in ctx.companies for b in (c.get("benefits") or [])]
    t = welfare_totals(ctx)

    dated = sorted(d for d in t["dates"] if d)  # 확인일 범위 — 검색 요약 행(요약 기준일)은 뺀다

    fin_comps = emp_comps = 0
    years: set[int] = set()
    if ctx.finance_loaded or ctx.employ_loaded:
        for c in ctx.companies:
            fin = ctx.finance.get(c["comp_id"])
            emp = ctx.employ.get(c["comp_id"])
            # 회사 페이지가 카드를 그리는 규칙 그대로 — 한쪽만 넣고 돌려 그쪽 카드가 서는지로 센다.
            if company_metrics(fin, None) is not None:
                fin_comps += 1
            if company_metrics(None, emp) is not None:
                emp_comps += 1
            for y in (fin or {}).get("years") or []:
                if y.get("year") is not None and any(
                        y.get(k) is not None for k in ("revenue", "op_income", "net_income")):
                    years.add(int(y["year"]))

    resort_rows = [(c["comp_id"], b.get("benefit_nm") or "") for c, b in rows if b.get("benefit_cd") == RESORT_CD]
    resort_freq: Counter = Counter(_fold(n) for _, n in resort_rows)
    shown: dict[str, str] = {}
    for _, n in resort_rows:
        shown.setdefault(_fold(n), n.strip())
    chips = [shown[k] for k, _ in sorted(resort_freq.items(), key=lambda kv: (-kv[1], shown[kv[0]]))[:RESORT_CHIPS]]

    summary_rows = [b for _, b in rows if marks.is_summary(b)]
    return {
        "asof": dated[-1] if dated else "",  # 확인일 범위(vmin~vmax)와 같은 집합 — 검색 요약 행의 요약 기준일은 뺀다
        "N": len(ctx.companies),
        "url_comp": sum(1 for c in ctx.companies if c.get("careers_benefit_url")),
        "summary_comp": len(t["summary_comps"]),
        "summary_rows": t["summary"],
        "summary_all_no_amount": all(b.get("qual_yn") or b.get("benefit_amt") is None for b in summary_rows),
        "fin": fin_comps,
        "emp": emp_comps,
        "fy_min": min(years) if years else None,
        "fy_max": max(years) if years else None,
        "names": len({_fold(b.get("benefit_nm")) for _, b in rows if _fold(b.get("benefit_nm"))}),
        "codes": len({b.get("benefit_cd") for _, b in rows if b.get("benefit_cd")}),
        "resort_comp": len({cid for cid, _ in resort_rows}),
        "resort_names": len(resort_freq),
        "resort_chips": chips,
        "cats": len(CATEGORY_ORDER),
        "rows": t["total"],
        "st": t["stated"],
        "es": t["estimated"],
        "no": t["none"],
        "qual": t["qual"],  # 「금액 미등록」 안의 두 갈래 — 정성(환산 불가) · 금액 미기재(환산 가능, 값 모름)
        "blank": t["no_amount"],
        "legal": t["marked"]["legal"],
        "work_edu": t["marked"]["work_edu"],
        "vmin": dated[0] if dated else "",
        "vmax": dated[-1] if dated else "",
    }


def _sentence(template: str, **kw) -> str:
    return template.format(**kw)


def _para(*sentences) -> list:
    """문장 목록 → 문단 조각 목록. 조각은 문자열이거나 배지(dict) — 템플릿이 배지만 매크로로 그린다."""
    out: list = []
    for s in sentences:
        if not s:
            continue
        parts = s if isinstance(s, list) else [s]
        if out and isinstance(out[-1], str) and isinstance(parts[0], str):
            out[-1] += " " + parts[0]
            out.extend(parts[1:])
        else:
            if out:
                out.append(" ")
            out.extend(parts)
    return out


def _with_badge(template: str, badge: dict, **kw) -> list:
    """`{badge}` 자리에서 문장을 쪼개 [앞, 배지, 뒤] 로 — 배지는 문자열이 아니라 그려야 하는 요소다."""
    before, _, after = template.partition("{badge}")
    return [before.format(**kw), badge, after.format(**kw)]


def _gwa(label: str) -> str:
    return _josa(label, "과", "와")


def _eul(label: str) -> str:
    return _josa(label, "을", "를")


def _ro(label: str) -> str:
    """로/으로 — 받침이 없거나 ㄹ 받침이면 「로」."""
    if label and 0xAC00 <= ord(label[-1]) <= 0xD7A3:
        jong = (ord(label[-1]) - 0xAC00) % 28
        return "로" if jong in (0, 8) else "으로"
    return "로"


def _crumb() -> dict:
    """빵부스러기 「가이드 › 데이터 안내」 — 「가이드」는 `/guide` 목록 링크다(2026-10-08, A편 목록이 생겼다). 글자는 T.CRUMB 그대로."""
    root, _, tail = T.CRUMB.partition(" › ")
    return {"href": GUIDE_LIST_ROUTE, "root": root, "tail": tail}


def build_view(ctx, benefit_links: dict | None = None) -> dict:
    """뷰모델(순수). 문장은 content 모듈 · 숫자는 `counts` · 라벨은 각 정본에서 — 0이면 그 문장은 통째로 뺀다.

    `benefit_links` = `benefit.links(...)` 의 `{code: "/benefit/{slug}"}`. 휴양시설 항목 페이지가 실제로 생성됐을 때만 링크를 건다.
    """
    n = counts(ctx)
    if n["N"] and not n["url_comp"]:
        # 실데이터에서 근거 주소 0곳은 있을 수 없다 — 번들에서 필드가 조용히 떨어진 것이다(Pydantic 화이트리스트 함정).
        raise BuildError("about/data: 근거 주소가 있는 회사가 0곳 — 번들 필드 누락 의심(careers_benefit_url)")
    f = lambda v: f"{v:,}"  # noqa: E731 — 천 단위 쉼표(페이지 안의 모든 수가 같은 표기)

    # ── 어디서 가져오나 ──
    welfare = [_para(T.SRC_WELFARE_ORIGIN)]
    rest = []
    if n["url_comp"]:
        rest.append(_sentence(T.SRC_WELFARE_URL, url_comp=f(n["url_comp"])))
    rest.append(T.SRC_WELFARE_NOT)
    if n["summary_comp"]:
        summary_badge = {"code": "summary", "label": marks.SUMMARY["label"]}
        rest.append(_with_badge(T.SRC_SUMMARY, summary_badge, summary_comp=f(n["summary_comp"])))
        if not n["summary_all_no_amount"]:
            # 「금액을 넣지 않습니다」가 거짓이 되는 순간이다 — 문장을 슬쩍 빼지 말고 사람이 문안을 다시 정하게 멈춘다.
            raise BuildError("about/data: 검색 요약 행에 금액이 있다 — SRC_SUMMARY_NO_AMOUNT 문장이 거짓이 된다(리드 판정 필요)")
        rest.append(T.SRC_SUMMARY_NO_AMOUNT)
    welfare.append(_para(*rest))
    sources = [{"h": T.SRC_WELFARE_H, "paras": welfare}]

    if n["fin"] or n["emp"]:
        fin_parts = ([_sentence(T.SRC_FIN_COUNT_FIN, fin=f(n["fin"]))] if n["fin"] else []) + \
                    ([_sentence(T.SRC_FIN_COUNT_EMP, emp=f(n["emp"]))] if n["emp"] else [])
        fin_counts = "(" + " · ".join(fin_parts) + ")"  # 0인 절은 뺀다 — 둘 다 0이면 이 블록 자체가 없다
        metrics = (_sentence(T.SRC_FIN_METRICS, fy_min=n["fy_min"], fy_max=n["fy_max"])
                   if n["fy_min"] is not None else T.SRC_FIN_METRICS_NO_YEARS)
        sources.append({"h": T.SRC_FIN_H, "paras": [
            _para(T.SRC_FIN_ORIGIN, metrics),
            _para(_sentence(T.SRC_FIN_AS_IS, counts=fin_counts)),
        ]})
    sources.append({"h": T.SRC_MEMBER_H, "paras": [_para(T.SRC_MEMBER_EDIT), _para(T.SRC_MEMBER_MARK)]})

    # ── 같은 제도는 같은 이름으로 ──
    group_a: list = [_sentence(T.GROUP_NAMES, names=f(n["names"]))]
    resort_title = (benefit_rules.load_pages().get(RESORT_CD) or {}).get("title") or ""
    resort_href = (benefit_links or {}).get(RESORT_CD)
    chips_label = ""
    if n["resort_comp"] and resort_title:
        before, _, after = T.GROUP_RESORT.partition("{resort_title}")
        rest_txt = after.format(resort_comp=f(n["resort_comp"]), resort_names=f(n["resort_names"]))
        # 제목은 항목 페이지 설정이 정본이다 — 페이지가 있으면 거기로 링크, 없으면 글자만.
        group_a.append(" ")
        group_a.append({"href": resort_href, "text": resort_title} if resort_href else resort_title)
        group_a.append(rest_txt)
        chips_label = _sentence(T.GROUP_CHIPS_LABEL, resort_title=resort_title, eul=_eul(resort_title))
    group_b = [_sentence(T.GROUP_CODES, codes=f(n["codes"]), cats_ko=native_count(n["cats"]))]
    clauses = [T.GROUP_MARK_CLAUSE.format(phrase=marks.KINDS[k]["phrase"], label=marks.KINDS[k]["label"])
               for k in ("legal", "work_edu") if n[k]]
    if clauses:
        group_b.append(", ".join(clauses) + T.GROUP_MARK_TAIL)
    # 문장 사이 공백 하나 — 마지막 문장의 꼬리(` 표시를 달고…`)는 앞 공백을 이미 갖고 있어 따로 잇는다.
    group_b_text = group_b[0] + (" " + group_b[1] if len(group_b) > 1 else "")

    # ── 금액 세 가지 ──
    lens = {k: label for k, label, _ in LENS_BUCKETS}
    # 금액 갈래는 회사 페이지 금액 렌즈(`.sc-lens-chip`)와 같은 모양이다 — 출처 배지(`badge-*`)를 금액에 쓰지 않는다.
    qual_l, blank_l = lens["qual"], lens["blank"]
    kinds = [
        {"label": lens["stated"], "text": _sentence(T.KIND_STATED, K_st=BAND_STATED_PCT)},
        {"label": lens["est"], "text": _sentence(T.KIND_ESTIMATED, K_es=BAND_ESTIMATED_PCT)},
        {"label": T.KIND_NONE_LABEL, "text": T.KIND_NONE + " " + _sentence(
            T.KIND_NONE_SPLIT, qual=qual_l, qual_gwa=_gwa(qual_l), blank=blank_l, blank_ro=_ro(blank_l))},
    ]
    detail_parts = [_sentence(T.AMOUNT_DETAIL_PART, label=lab, n=f(v))
                    for lab, v in ((qual_l, n["qual"]), (blank_l, n["blank"])) if v]
    detail = "(" + " · ".join(detail_parts) + ")" if detail_parts else ""
    totals = (_sentence(T.AMOUNT_TOTALS, rows=f(n["rows"]), st=f(n["st"]), es=f(n["es"]), no=f(n["no"]), detail=detail)
              if n["rows"] else "")

    # ── 다시 확인 ──
    stale = _badge_view("stale")
    reverify = [_sentence(T.REVERIFY_RULE, exp_months=EXPIRE_MONTHS, stale=stale["label"], K_exp=BAND_EXPIRE_PP)]
    if n["vmin"]:
        reverify.append(_sentence(T.REVERIFY_RANGE, vmin=_korean_date(n["vmin"]), vmax=_korean_date(n["vmax"])))

    # ── 누가 고칠 수 있나 ──
    who = [
        {"badge": _badge_view("official"), "text": T.WHO_OFFICIAL},
        {"badge": _badge_view("edited"), "text": T.WHO_EDITED},
        {"badge": _badge_view("member"), "text": T.WHO_MEMBER},
    ]

    return {
        "crumb": _crumb(),
        "h1": T.H1,
        "meta": _sentence(T.META, asof=_korean_date(n["asof"]), N=f(n["N"])) if n["asof"] else
                _sentence(T.META_NO_ASOF, N=f(n["N"])),
        "lead": T.LEAD,
        "sources": sources,
        "group_a": group_a,
        "resort_chips": n["resort_chips"] if (n["resort_comp"] and resort_title) else [],
        "resort_chips_label": chips_label,
        "group_b": group_b_text,
        "cats": [CATEGORY_LABEL[k] for k in CATEGORY_ORDER],
        "find_link": T.GROUP_FIND_LINK,
        "kinds": kinds,
        "totals": totals,
        "reverify": " ".join(reverify),
        "weekly": T.REVERIFY_WEEKLY if n["url_comp"] else "",
        "timeline": {"from": T.TIMELINE_FROM, "span": _sentence(T.TIMELINE_SPAN, exp_months=EXPIRE_MONTHS), "stale": stale},
        "who": who,
        "who_note": T.WHO_NOTE,
        "nots": list(T.NOT_LIST),
        "h": {"sources": T.H_SOURCES, "group": T.H_GROUP, "amount": T.H_AMOUNT, "reverify": T.H_REVERIFY,
              "who": T.H_WHO, "nots": T.H_NOT},
    }


def render(env, ctx, cfg=CFG, benefit_links: dict | None = None) -> Page:
    view = build_view(ctx, benefit_links)
    url = f"{cfg.site_origin}{ROUTE}"
    title = f"{T.TITLE} | {cfg.site_name}"
    desc = _truncate(T.LEAD.split(". ")[0] + ". " + T.DESCRIPTION_TAIL, cfg.desc_max)
    html = env.get_template("about_data.html").render(
        view=view, meta_title=title, meta_desc=desc, canonical=url,
        og={"title": title, "description": desc, "type": "website", "url": url,
            "image": cfg.site_origin + cfg.default_og_image},
        cfg=cfg, footer_links=POLICY_FOOTER_LINKS, nav_active=GUIDE_LIST_ROUTE,  # 탭 「가이드」 = /guide 목록(2026-10-08)

    )
    return Page(path=PATH, url=url, html=html, title=title, description=desc)
