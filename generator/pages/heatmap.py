"""generator/pages/heatmap.py — `/heatmap` 복지·실적 히트맵 (SP-HEAT-4, 2026-08-27).

prober.kr 주식 히트맵의 문법(업종 그룹 → 칸 크기 → 색 7단계)을 우리 데이터에 옮긴다:

| 모드 | 크기 | 색(7단계) | 대상 |
|---|---|---|---|
| 복지 | 복지 항목 수 | 금액 합계 7분위(연두→진녹, 정성 복지는 크기에만) | 등록 회사 전부 |
| 실적 | 최신 사업연도 매출 | 영업이익 전년 대비(±3·±10·±30%, 빨강/회색/초록) | 재무·증감률이 있는 회사 |
| 카테고리 | 복지 금액(정성은 최소 칸) | **출처** — 회사 공식 / 추정 / 정성 | 9 카테고리 × 안의 **항목** 묶음 × 회사 |

카테고리 모드(2026-08-27 후반, 사용자 결정)는 그룹이 업종이 아니라 **항목**이다 — "같은 식대인데 더 주는 곳"은
식대 묶음 안에서 봐야 한다. 색을 금액이 아니라 **출처**로 두는 이유: 정량 복지 645건 중 회사 공식 수치는
73건(11%)뿐이라 금액 색은 추정 상수를 줄 세우는 그림이 된다. 출처 색은 "무엇을 알고 무엇을 모르는지"를
그대로 보여주고, 추정·정성 칸은 재직자 편집(SC14)의 유입구가 된다.

그룹은 **KRX 업종 분류**(`generator/sector.py`). 배치는 빌드 시점 squarify(`generator/treemap.py`)라
페이지는 JS 없이 완성된다 — JS(`heatmap.js`)는 두 모드를 탭으로 오가는 enhancement 뿐이다.
가로(16:10)·세로(3:4) 두 배치를 모두 렌더하고 CSS 미디어쿼리가 하나만 보인다(모바일에서
칸이 납작해지는 것을 막는다).

표현은 **사실만**(DEC-B·SP-FIN): 색은 수치 구간이고 등급·전망 어휘를 쓰지 않는다. 재무가 안 실린
빌드(수집 전)는 실적 모드를 아예 내지 않는다(102곳 전부 "없음"이 되는 거짓 방지, SP-FIN-5 규칙).
"""
from __future__ import annotations

from generator.config import CFG
from generator.content.policy import POLICY_FOOTER_LINKS
from generator.context import Page
from collections import Counter

from generator.format import krw_eok
from generator.pages.company import CATEGORY_LABEL, CATEGORY_ORDER
from generator.sector import UNLISTED, load_sectors, sector_of
from generator.treemap import nested_layout

# 배치 캔버스(단위 = %). 가로 16:10 · 세로 3:4 — 템플릿의 aspect-ratio 와 짝(둘 다 폭 100).
ORIENTATIONS = {"landscape": (100.0, 62.5), "portrait": (100.0, 133.333)}
YOY_CUTS = (-30.0, -10.0, -3.0, 3.0, 10.0, 30.0)  # 7단계 경계(%). 회색 = ±3% 이내
SEQ_STEPS = 7

# 항목 코드 → 짧은 묶음 이름. 없는 코드는 그 코드의 가장 흔한 `benefit_nm` 으로(빌드 시 집계).
ITEM_LABEL = {
    "meal": "식대·식사", "welfare_point": "복지포인트", "snack_bar": "간식", "commute_subsidy": "통근",
    "transport": "교통비", "telecom": "통신비", "housing_loan": "주택자금", "discount": "임직원 할인",
    "pension_support": "연금 지원", "health_check": "건강검진", "medical": "의료비", "insurance": "단체보험",
    "event": "경조사", "child_edu": "자녀 학자금", "parenting": "육아", "resort": "휴양시설", "club": "동호회",
    "books": "도서", "self_development": "자기계발", "incentive": "인센티브", "holiday_gift": "명절 선물",
    "excellence_award": "포상",
}
SOURCE_LABEL = {"stated": "회사 공식 수치", "est": "추정치", "qual": "정성(금액 없음)"}
EDIT_HINT = "실제 금액을 아시나요? 재직 인증 후 회사 페이지에서 수정할 수 있어요"


def _quantile_cuts(values: list[int], n: int = SEQ_STEPS) -> list[int]:
    """7분위 경계 6개(오름차순). 값이 적어도 죽지 않는다."""
    vs = sorted(values)
    if not vs:
        return [0] * (n - 1)
    return [vs[min(len(vs) - 1, int(len(vs) * k / n))] for k in range(1, n)]


def seq_step(value: int, cuts: list[int]) -> int:
    for i, c in enumerate(cuts):
        if value <= c:
            return i
    return SEQ_STEPS - 1


def yoy_step(pct: float) -> int:
    for i, c in enumerate(YOY_CUTS):
        if pct <= c:
            return i
    return 6


def _latest_with_yoy(fin: dict | None):
    """최신 연도와 직전 연도 영업이익으로 증감률(%). 분모는 |전년|(적자 기준에서도 부호가 방향)."""
    if not fin or not fin.get("years"):
        return None
    ys = sorted(fin["years"], key=lambda y: y["year"])
    latest, prev = ys[-1], (ys[-2] if len(ys) > 1 else None)
    rev, op = latest.get("revenue"), latest.get("op_income")
    if not rev or rev <= 0 or op is None or not prev or not prev.get("op_income"):
        return None
    return {"year": latest["year"], "revenue": rev, "op_income": op, "yoy": (op - prev["op_income"]) / abs(prev["op_income"]) * 100}


def _welfare_items(ctx, sectors):
    items = []
    for c in ctx.companies:
        n = len(c["benefits"])
        amt = sum(int(b["benefit_amt"] or 0) for b in c["benefits"] if not b.get("qual_yn"))
        cats = len({b["benefit_ctgr_cd"] for b in c["benefits"]})
        items.append({"c": c, "sector": sector_of(ctx.finance.get(c["comp_id"]), sectors), "weight": n,
                      "n": n, "amt": amt, "cats": cats})
    cuts = _quantile_cuts([i["amt"] for i in items])
    for i in items:
        i["step"] = seq_step(i["amt"], cuts)
        i["cls"] = f"c{i['step']}"
        i["sub"] = f"{i['n']}항목 · {i['amt']:,}만원"
        i["tip"] = f"복지 {i['n']}항목 · 금액 합계 {i['amt']:,}만원 · 카테고리 {i['cats']}/9"
    return items


def _finance_items(ctx, sectors):
    items = []
    for c in ctx.companies:
        fin = ctx.finance.get(c["comp_id"])
        if not fin or fin.get("acct_set") == "financial":
            continue  # 금융업은 매출·영업이익 계정이 없다(SP-FIN) — 같은 색 규칙을 적용할 수 없다
        lt = _latest_with_yoy(fin)
        if not lt:
            continue
        step = yoy_step(lt["yoy"])
        items.append({"c": c, "sector": sector_of(fin, sectors), "weight": lt["revenue"] / 1e8,
                      "year": lt["year"], "yoy": lt["yoy"], "step": step, "cls": f"d{step}",
                      "sub": f"{krw_eok(lt['revenue'])} · {lt['yoy']:+.1f}%",
                      "tip": f"{lt['year']} 매출 {krw_eok(lt['revenue'])}억 · 영업이익 {krw_eok(lt['op_income'])}억 (전년 대비 {lt['yoy']:+.1f}%)"})
    return items


def _source_of(b: dict) -> str:
    if b.get("qual_yn"):
        return "qual"
    return "stated" if b.get("amt_source") == "stated" else "est"


def _item_labels(ctx) -> dict[str, str]:
    """코드별 묶음 이름 — ITEM_LABEL 우선, 없으면 그 코드의 최빈 benefit_nm(짧게)."""
    names: dict[str, Counter] = {}
    for c in ctx.companies:
        for b in c["benefits"]:
            code = b.get("benefit_cd") or b["benefit_nm"]
            names.setdefault(code, Counter())[b["benefit_nm"]] += 1
    out = {}
    for code, cnt in names.items():
        nm = ITEM_LABEL.get(code) or cnt.most_common(1)[0][0]
        out[code] = nm if len(nm) <= 12 else nm[:11] + "…"
    return out


def _category_items(ctx, ctgr: str, labels: dict[str, str]) -> list[dict]:
    """한 카테고리의 복지 행 전부 → 타일 아이템. 정성(금액 없음)은 최소 칸(그 카테고리 최소 금액의 60%)."""
    rows = [(c, b) for c in ctx.companies for b in c["benefits"] if b["benefit_ctgr_cd"] == ctgr]
    amts = [int(b["benefit_amt"]) for _, b in rows if not b.get("qual_yn") and b.get("benefit_amt")]
    floor = max(1.0, (min(amts) if amts else 10) * 0.6)
    items = []
    for c, b in rows:
        src = _source_of(b)
        has_amt = not b.get("qual_yn") and b.get("benefit_amt")
        amt_text = f"{int(b['benefit_amt']):,}만원" if has_amt else "금액 없음"
        note = (b.get("note_ctnt") or "").replace("(추정)", "").strip()
        tip = f"{b['benefit_nm']} · {amt_text} · {SOURCE_LABEL[src]}"
        if note:
            tip += f" · {note}"
        if src != "stated":
            tip += f" · {EDIT_HINT}"
        items.append({"c": c, "sector": labels.get(b.get("benefit_cd") or b["benefit_nm"], b["benefit_nm"]),
                      "weight": int(b["benefit_amt"]) if has_amt else floor, "src": src, "cls": f"s-{src}",
                      "sub": amt_text, "tip": tip})
    return items


def _category_panels(ctx) -> list[dict]:
    labels = _item_labels(ctx)
    panels = []
    for ctgr in CATEGORY_ORDER:
        items = _category_items(ctx, ctgr, labels)
        if not items:
            continue
        counts = Counter(i["src"] for i in items)
        panels.append({"key": ctgr, "label": CATEGORY_LABEL[ctgr], "count": len({i["c"]["comp_id"] for i in items}),
                       "groups": len({i["sector"] for i in items}), "stated": counts["stated"], "est": counts["est"],
                       "qual": counts["qual"], "layouts": _panel_layouts(items, ctx)})
    return panels


def _size_class(area: float) -> str:
    return "xs" if area < 9 else "sm" if area < 20 else "md" if area < 45 else "lg"


def _group_keys(items) -> dict[str, str]:
    """그룹 이름 → 안정 키(`g0`, `g1`…). 이름을 그대로 속성에 쓰지 않는 이유는 한글·중점(·)·
    공백이 섞여 있어서다. **패널마다 한 번 만들어 가로·세로 배치가 같은 키를 쓰게 한다** —
    squarify 는 배치마다 그룹 순서가 달라지므로 배치 안에서 번호를 매기면 두 배치의 키가 어긋난다."""
    return {name: f"g{i}" for i, name in enumerate(sorted({it["sector"] for it in items}))}


def _layout(items, ctx, orientation, gkeys=None):
    """뷰모델: 그룹 헤더 + 타일(% 좌표). 세로 배치는 y 를 캔버스 높이 대비 % 로 정규화한다.

    타일에 `gkey`(소속 그룹)·`ckey`(회사)를 심어 둔다 — 마우스를 올렸을 때 그 그룹과 같은 회사의
    다른 칸을 함께 강조하기 위해서다(SP-HEAT-7). 강조는 JS enhancement 지만 **연결 정보는 정적
    HTML 에 있다** — 그래야 JS 없이도 문서가 완결이고, 스크립트는 class 만 토글하면 된다.
    """
    w, h = ORIENTATIONS[orientation]
    gkeys = _group_keys(items) if gkeys is None else gkeys
    groups: dict[str, list] = {}
    for it in items:
        groups.setdefault(it["sector"], []).append((it["weight"], it))
    heads, tiles = nested_layout(groups, w, h)
    sy = 100.0 / h  # y·height 를 캔버스 높이 100% 기준으로
    return {
        "groups": [{"name": g.name, "gkey": gkeys[g.name], "count": g.count, "unlisted": g.name == UNLISTED,
                    "x": round(g.x, 3), "y": round(g.y * sy, 3), "w": round(g.w, 3), "h": round(g.h * sy, 3),
                    "narrow": g.w < 7 or g.h < 6} for g in heads],
        "tiles": [{"nm": t.obj["c"]["comp_nm"], "href": f"/company/{ctx.slugs[t.obj['c']['comp_eng_nm']]}",
                   "industry": t.obj["c"].get("industry_nm") or "", "sector": t.obj["sector"],
                   "gkey": gkeys[t.obj["sector"]], "ckey": ctx.slugs[t.obj["c"]["comp_eng_nm"]],
                   "cls": t.obj["cls"], "size": _size_class(t.w * t.h), "sub": t.obj["sub"], "tip": t.obj["tip"],
                   "x": round(t.x, 3), "y": round(t.y * sy, 3), "w": round(t.w, 3), "h": round(t.h * sy, 3)}
                  for t in tiles],
    }


def _panel_layouts(items, ctx) -> dict:
    """한 패널의 두 배치 — 그룹 키를 공유한다(위 `_group_keys` 주석)."""
    gkeys = _group_keys(items)
    return {o: _layout(items, ctx, o, gkeys) for o in ORIENTATIONS}


def build_view(ctx, sectors: dict[str, str] | None = None) -> dict:
    """페이지 뷰모델(순수 — 테스트가 직접 검사). 모드마다 `panels`(복지·실적은 1개, 카테고리는 9개).
    실적은 미적재면 빠진다."""
    sectors = load_sectors() if sectors is None else sectors
    wi = _welfare_items(ctx, sectors)
    modes = [{"key": "w", "label": "복지", "hint": "크기=항목 수, 색=금액 합계", "legend_kind": "steps",
              "legend": "금액 합계(만원, 7분위)", "lo": "적음", "hi": "많음",
              "note": "정성 복지(금액 없음)는 크기에만 반영", "steps": [f"c{i}" for i in range(7)],
              "panels": [{"key": "all", "label": "복지", "count": len(wi),
                          "layouts": _panel_layouts(wi, ctx)}],
              "count": len(ctx.companies)}]
    if ctx.finance_loaded:
        fi = _finance_items(ctx, sectors)
        if fi:
            year = max(i["year"] for i in fi)
            modes.append({"key": "f", "label": "실적", "hint": "크기=매출, 색=영업이익 증감", "legend_kind": "steps",
                          "legend": f"{year} 영업이익 전년 대비", "lo": "−30%↓", "hi": "+30%↑",
                          "note": f"회색 = ±3% 이내 · 금융업·공시 없는 {len(ctx.companies) - len(fi)}곳 제외",
                          "steps": [f"d{i}" for i in range(7)],
                          "panels": [{"key": "all", "label": "실적", "count": len(fi),
                                      "layouts": _panel_layouts(fi, ctx)}],
                          "count": len(fi)})
    cp = _category_panels(ctx)
    if cp:
        modes.append({"key": "c", "label": "카테고리", "hint": "항목 하나씩 회사 비교", "legend_kind": "source",
                      "legend": "칸 크기 = 금액 · 색 = 출처", "lo": "", "hi": "",
                      "note": "추정·정성 칸은 재직 인증 후 회사 페이지에서 수정할 수 있어요",
                      "steps": ["s-stated", "s-est", "s-qual"], "panels": cp,
                      "count": sum(p["count"] for p in cp)})
    sector_count = len({g["name"] for g in modes[0]["panels"][0]["layouts"]["landscape"]["groups"]})
    return {"modes": modes, "sector_count": sector_count}


def render(env, ctx, cfg=CFG) -> Page:
    view = build_view(ctx)
    url = f"{cfg.site_origin}/heatmap"
    total = len(ctx.companies)
    title = f"복지 히트맵 — 등록 회사 {total}곳을 업종별로 한눈에 | {cfg.site_name}"
    desc = (f"KRX 업종별로 묶은 회사 {total}곳의 복지 히트맵. 칸의 크기는 복지 항목 수, 색은 금액 합계. "
            f"실적 모드는 매출 크기와 영업이익 전년 대비를 보여줍니다.")
    html = env.get_template("heatmap.html").render(
        view=view, total=total, meta_title=title, meta_desc=desc, canonical=url,
        og={"title": title, "description": desc, "type": "website", "url": url,
            "image": cfg.site_origin + cfg.default_og_image},
        cfg=cfg, footer_links=POLICY_FOOTER_LINKS, nav_active="/heatmap",
    )
    return Page(path="heatmap.html", url=url, html=html, title=title, description=desc)
