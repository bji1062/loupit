"""generator/pages/find.py — `/find` 「복지로 찾기」 (SP-FIND, 2026-09-06).

회사 이름이 아니라 **복지 항목**으로 회사를 거르는 탭이다. 고르는 도구 자체는 클라이언트가
그린다(`web/assets/js/find.js` + 부팅 번들 `reference/all` — 새 API·새 컬럼 0). 이 파일이 만드는
것은 그 도구가 앉을 **정적 셸**과, JS 없이도 읽히는 본문이다.

비-JS 본문을 「안내 문구」로 때우지 않는 이유(GC-10 정신 + 콘텐츠 두께):
  · 크롤러가 보는 것이 이 페이지의 전부다. 도구는 JS 라 색인되지 않는다.
  · 카테고리 9개 × 코드 86종의 **보유 회사 수 표**는 그 자체로 사실이고, 표의 각 줄이
    `/find?b=<code>` 로 도구에 들어가는 입구가 된다(정적 → 도구 연결).
  · 그래서 표는 도구가 켜져도 **숨기지 않는다**. 숨기면 색인 가치가 사라지고, 남겨 두면
    "이 사이트가 무엇을 알고 있는지"의 목록이 된다.

코드 사전(대표 이름·별칭·최빈 카테고리·보유 회사 수)은 DB 컬럼이 아니라 **집계**다. 같은 규칙이
JS 쪽(`find.js::deriveCodes`)에도 있고, 둘이 갈라지면 표와 칩이 다른 이름을 부른다 —
`generator/tests/test_find_page.py` 가 표시명 override 다섯을 문자열로 맞춰 잡는다.
"""
from __future__ import annotations

from collections import Counter

from generator.config import CFG
from generator.content.policy import POLICY_FOOTER_LINKS
from generator.context import Page
from generator.pages.company import CATEGORY_LABEL, CATEGORY_ORDER

# 같은 대표 이름을 쓰는 코드를 갈라 주는 표시명. **`web/assets/js/find.js::LABEL_OVERRIDE` 와 같은
# 다섯 줄이어야 한다**(표는 여기서, 칩은 거기서 이름을 얻는다). test_find_page.py 가 강제한다.
LABEL_OVERRIDE = {
    "transport": "교통비·유류비 지원",
    "commute_subsidy": "통근버스·출퇴근 지원",
    "long_service_leave": "장기근속 휴가",
    "long_service_bonus": "장기근속 포상금",
    "long_service": "장기근속 포상 (구 코드)",
}


def _most_common(counter: Counter):
    """최빈값 — 동률은 이름순으로 갈라 빌드가 결정적이 되게 한다(JS 쪽과 같은 규칙)."""
    if not counter:
        return None
    return sorted(counter.items(), key=lambda kv: (-kv[1], str(kv[0])))[0][0]


def derive_codes(companies: list[dict]) -> dict[str, dict]:
    """복지 행 전부 → 코드 사전 `{code: {label, base_label, aliases, ctgr, count, amt_count}}`.

    `count` 는 행이 아니라 **회사 수**다(회사 안에서 코드는 UNIQUE 라 같지만, 뜻이 다르다).
    """
    names: dict[str, Counter] = {}
    ctgrs: dict[str, Counter] = {}
    comps: dict[str, set] = {}
    amts: dict[str, int] = {}
    for c in companies:
        for b in c.get("benefits") or []:
            code = b.get("benefit_cd")
            if not code:
                continue  # BENEFIT_CD 는 NOT NULL — 없는 행은 검색의 축이 없어 건너뛴다
            names.setdefault(code, Counter())[b.get("benefit_nm")] += 1
            ctgrs.setdefault(code, Counter())[b.get("benefit_ctgr_cd")] += 1
            comps.setdefault(code, set()).add(c["comp_id"])
            amts.setdefault(code, 0)
            if not b.get("qual_yn") and b.get("benefit_amt"):
                amts[code] += 1

    out: dict[str, dict] = {}
    for code, cnt in names.items():
        base = _most_common(cnt) or code
        out[code] = {
            "code": code,
            "base_label": base,
            "label": base,
            "aliases": [nm for nm, _ in sorted(cnt.items(), key=lambda kv: (-kv[1], str(kv[0])))],
            "ctgr": _most_common(ctgrs[code]) or "",
            "count": len(comps[code]),
            "amt_count": amts[code],
        }
    return _disambiguate(out)


def _disambiguate(codes: dict[str, dict]) -> dict[str, dict]:
    """같은 대표 이름을 쓰는 코드의 표시명을 갈라 준다 — override 우선, 없으면 별칭 병기."""
    groups: dict[str, list] = {}
    for info in codes.values():
        groups.setdefault(info["base_label"], []).append(info)
    for group in groups.values():
        if len(group) < 2:
            continue
        for info in group:
            if info["code"] in LABEL_OVERRIDE:
                continue
            alias = next((a for a in info["aliases"] if a != info["base_label"]), None)
            info["label"] = f"{info['base_label']} · {alias or info['code']}"
    for code, label in LABEL_OVERRIDE.items():
        if code in codes:
            codes[code]["label"] = label
    return codes


def build_view(ctx) -> dict:
    """뷰모델(순수 — 테스트가 직접 검사). 카테고리 9개 × 코드 표 + 요약 수치."""
    codes = derive_codes(ctx.companies)
    by_cat: dict[str, list] = {k: [] for k in CATEGORY_ORDER}
    for info in codes.values():
        by_cat.setdefault(info["ctgr"], []).append(info)
    categories = []
    for key in CATEGORY_ORDER:
        rows = sorted(by_cat.get(key, []), key=lambda i: (-i["count"], i["label"]))
        if not rows:
            continue
        categories.append({
            "key": key,
            "label": CATEGORY_LABEL[key],
            "codes": len(rows),
            # 「이 카테고리 항목을 하나라도 가진 회사」 — 표 머리에 놓는 사실
            "companies": len({
                c["comp_id"] for c in ctx.companies
                for b in (c.get("benefits") or []) if b.get("benefit_ctgr_cd") == key
            }),
            "rows": [{
                "code": i["code"],
                "label": i["label"],
                # 대표 이름 말고 실제로 쓰인 다른 이름 3개까지 — 검색어가 무엇인지 사람이 보게 한다
                "aliases": [a for a in i["aliases"] if a != i["base_label"]][:3],
                "count": i["count"],
                "amt_count": i["amt_count"],
            } for i in rows],
        })
    rows_total = sum(len(c.get("benefits") or []) for c in ctx.companies)
    amt_total = sum(
        1 for c in ctx.companies for b in (c.get("benefits") or [])
        if not b.get("qual_yn") and b.get("benefit_amt")
    )
    return {
        "categories": categories,
        "total_companies": len(ctx.companies),
        "total_codes": len(codes),
        "total_rows": rows_total,
        "amount_rows": amt_total,
        "types": [
            {"cd": t["comp_tp_cd"], "nm": t["comp_tp_nm"],
             "n": sum(1 for c in ctx.companies if c.get("comp_tp_cd") == t["comp_tp_cd"])}
            for t in ctx.types_by_cd.values()
        ],
    }


def render(env, ctx, cfg=CFG) -> Page:
    view = build_view(ctx)
    url = f"{cfg.site_origin}/find"
    total = view["total_companies"]
    title = f"복지로 찾기 — 복지 항목으로 상장사 {total}곳 거르기 | {cfg.site_name}"
    desc = (
        f"사택·학자금·복지포인트처럼 원하는 복지 항목을 골라 그 복지가 있는 회사를 찾습니다. "
        f"등록 회사 {total}곳 · 복지 항목 {view['total_rows']:,}건 · 표준 코드 {view['total_codes']}종을 "
        f"카테고리 9개로 나눠 보유 회사 수와 함께 보여줍니다."
    )
    html = env.get_template("find.html").render(
        view=view, total=total, meta_title=title, meta_desc=desc, canonical=url,
        og={"title": title, "description": desc, "type": "website", "url": url,
            "image": cfg.site_origin + cfg.default_og_image},
        cfg=cfg, footer_links=POLICY_FOOTER_LINKS, nav_active="/find",
    )
    return Page(path="find.html", url=url, html=html, title=title, description=desc)
