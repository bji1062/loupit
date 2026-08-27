"""generator/pages/heatmap.py — `/heatmap` 복지·실적 히트맵 (SP-HEAT-4, 2026-08-27).

prober.kr 주식 히트맵의 문법(업종 그룹 → 칸 크기 → 색 7단계)을 우리 데이터에 옮긴다:

| 모드 | 크기 | 색(7단계) | 대상 |
|---|---|---|---|
| 복지 | 복지 항목 수 | 금액 합계 7분위(연두→진녹, 정성 복지는 크기에만) | 등록 회사 전부 |
| 실적 | 최신 사업연도 매출 | 영업이익 전년 대비(±3·±10·±30%, 빨강/회색/초록) | 재무·증감률이 있는 회사 |

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
from generator.format import krw_eok
from generator.sector import UNLISTED, load_sectors, sector_of
from generator.treemap import nested_layout

# 배치 캔버스(단위 = %). 가로 16:10 · 세로 3:4 — 템플릿의 aspect-ratio 와 짝(둘 다 폭 100).
ORIENTATIONS = {"landscape": (100.0, 62.5), "portrait": (100.0, 133.333)}
YOY_CUTS = (-30.0, -10.0, -3.0, 3.0, 10.0, 30.0)  # 7단계 경계(%). 회색 = ±3% 이내
SEQ_STEPS = 7


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


def _size_class(area: float) -> str:
    return "xs" if area < 9 else "sm" if area < 20 else "md" if area < 45 else "lg"


def _layout(items, ctx, orientation):
    """뷰모델: 그룹 헤더 + 타일(% 좌표). 세로 배치는 y 를 캔버스 높이 대비 % 로 정규화한다."""
    w, h = ORIENTATIONS[orientation]
    groups: dict[str, list] = {}
    for it in items:
        groups.setdefault(it["sector"], []).append((it["weight"], it))
    heads, tiles = nested_layout(groups, w, h)
    sy = 100.0 / h  # y·height 를 캔버스 높이 100% 기준으로
    return {
        "groups": [{"name": g.name, "count": g.count, "unlisted": g.name == UNLISTED,
                    "x": round(g.x, 3), "y": round(g.y * sy, 3), "w": round(g.w, 3), "h": round(g.h * sy, 3),
                    "narrow": g.w < 7 or g.h < 6} for g in heads],
        "tiles": [{"nm": t.obj["c"]["comp_nm"], "href": f"/company/{ctx.slugs[t.obj['c']['comp_eng_nm']]}",
                   "industry": t.obj["c"].get("industry_nm") or "", "sector": t.obj["sector"],
                   "cls": t.obj["cls"], "size": _size_class(t.w * t.h), "sub": t.obj["sub"], "tip": t.obj["tip"],
                   "x": round(t.x, 3), "y": round(t.y * sy, 3), "w": round(t.w, 3), "h": round(t.h * sy, 3)}
                  for t in tiles],
    }


def build_view(ctx, sectors: dict[str, str] | None = None) -> dict:
    """페이지 뷰모델(순수 — 테스트가 직접 검사). `modes` 는 실적 미적재면 복지 하나뿐."""
    sectors = load_sectors() if sectors is None else sectors
    modes = [{"key": "w", "label": "복지", "hint": "크기 항목 수 · 색 금액 합계",
              "legend": "금액 합계(만원, 7분위)", "lo": "적음", "hi": "많음",
              "note": "정성 복지(금액 없음)는 크기에만 반영", "steps": [f"c{i}" for i in range(7)],
              "layouts": {o: _layout(_welfare_items(ctx, sectors), ctx, o) for o in ORIENTATIONS},
              "count": len(ctx.companies)}]
    if ctx.finance_loaded:
        fi = _finance_items(ctx, sectors)
        if fi:
            year = max(i["year"] for i in fi)
            modes.append({"key": "f", "label": "실적", "hint": "크기 매출 · 색 영업이익 전년 대비",
                          "legend": f"{year} 영업이익 전년 대비", "lo": "−30%↓", "hi": "+30%↑",
                          "note": f"회색 = ±3% 이내 · 금융업·공시 없는 {len(ctx.companies) - len(fi)}곳 제외",
                          "steps": [f"d{i}" for i in range(7)],
                          "layouts": {o: _layout(fi, ctx, o) for o in ORIENTATIONS}, "count": len(fi)})
    sector_count = len({m for mode in modes for m in (g["name"] for g in mode["layouts"]["landscape"]["groups"])})
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
