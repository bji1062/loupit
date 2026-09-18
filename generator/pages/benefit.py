"""generator/pages/benefit.py — 복지 항목 페이지 `/benefit/{slug}` (SP-BEN, 2026-09-18).

표준 복지 항목(코드) 하나에 한 쪽. 회사 페이지가 「이 회사에 무엇이 있나」라면 여기는 「이 복지를
가진 회사들이 **원문에 무엇을 적었나**」다. 설정은 `generator/data/benefit_pages/{code}.json`
(설정 1개 = 페이지 1개), 원문을 세는 규칙은 `generator/benefit_rules.py` 가 적용한다.

🚨 **템플릿이 고정으로 내보내는 글은 제목·라벨·수치 표기뿐이다.** 완결문장(「…다.」「…요.」)은
   설정 JSON 의 사람 글(intro·notes·questions)과 회사 원문에서만 나온다. 애드센스 거절 사유가
   「가치가 별로 없는 콘텐츠」(공식 정의 = 필러)였고, 여러 페이지에 똑같이 반복되는 완결문장이 곧
   필러다 — 회사 페이지에서 A안(2026-09-16)으로 걷어 낸 것을 여기서 다시 만들지 않는다.
   `test_benefit_pages.py` 가 렌더 결과로 고정한다.

🚨 **법정 행(SP-LEGAL-5)은 표에는 남고 집계에서는 빠진다.** 「이 회사가 육아휴직을 준다」는 사실은
   정보지만 복지가 아니다. 보유 회사 수·방식·원문 항목·질문·금액 출처 **전부**가 법정 행을 뺀
   분모로 센다 — 한 곳이라도 섞으면 같은 페이지의 두 숫자가 다른 분모를 쓴다. 설정의 `exclude` 예외
   (이 코드로 잘못 분류된 행)도 같은 길로 빠지되, 이쪽은 표에도 남지 않는다(이 복지가 아니므로).

⚠ **보유 회사가 `MIN_COMPANIES` 미만이면 페이지를 만들지 않는다.** 표 몇 줄과 사람 글 두 문단만
   남는 쪽은 그 자체로 얇은 페이지다. 조용히 빼지 않고 빌드 로그에 남긴다(회사가 늘면 저절로 생긴다).
"""
from __future__ import annotations

import re
import sys
from collections import Counter

from generator import benefit_rules, legal
from generator.config import CFG
from generator.content.policy import POLICY_FOOTER_LINKS
from generator.context import Page
from generator.format import benefit_desc
from generator.pages.company import CATEGORY_LABEL, LENS_BUCKETS, amount_view, benefit_anchor, lens_keys
from generator.pages.find import _prefer_name, derive_codes
from generator.slug import BuildError

# 페이지를 만드는 보유 회사 수 하한(법정 행 제외). 2026-09-18 실측: 87종 중 36종이 넘는다.
MIN_COMPANIES = 20
# 회사 표 첫 화면 행 수 — 나머지는 `<details>` 안. 방식이 있으면 방식마다 고르게 뽑는다.
FIRST_ROWS = 12
# 「회사들이 부르는 이름」 칩 개수 — 나머지는 「외 N가지」.
NAME_CHIPS = 8
# 금액 표를 낼 최소 행 수 — 두 줄짜리 표는 표가 아니라 예시다.
MONEY_MIN_ROWS = 3

# 법정 기준선 표의 `paid` 코드 → 칸 라벨. 표에 `paid_note` 가 있으면 그쪽이 이긴다(표의 말이 정본).
PAID_LABEL = {"employer": "사업주 유급", "insurance": "고용보험", "unpaid": "무급", "mixed": "일부 유급"}

_FIRST_SENTENCE = re.compile(r"^(.+?[다요]\.)(?:\s|$)")


def collect_rows(ctx, code: str) -> list[dict]:
    """이 코드를 가진 회사 행 전부(회사당 1행) — 법정 행도 포함하고 `legal` 로 표시한다.

    `desc`·`note` 는 `benefit_rules.classify` 가 매칭·해시에 쓰는 원문 두 칸이다(해시 = 예외의 열쇠라
    이 두 칸의 뜻이 바뀌면 예외 전부가 `stale` 로 꺼진다).
    """
    rows = []
    for c in ctx.companies:
        hits = [b for b in (c.get("benefits") or []) if b.get("benefit_cd") == code]
        if len(hits) > 1:
            # `uq_comp_benefit` 가 막는 상태다. 조용히 첫 행만 쓰면 집계가 틀린 채 초록이 된다.
            raise BuildError(f"SP-BEN: {c['comp_eng_nm']} 에 {code} 행이 {len(hits)}개")
        for b in hits:
            rows.append({
                "comp": c["comp_eng_nm"],
                "comp_nm": c["comp_nm"],
                "slug": ctx.slugs[c["comp_eng_nm"]],
                "desc": b.get("qual_desc_ctnt"),
                "note": b.get("note_ctnt"),
                "benefit": b,
                "legal": legal.is_legal_row(c["comp_eng_nm"], code, b["benefit_nm"]),
            })
    return rows


def _mode_defs(modes_cfg: dict | None) -> list[dict]:
    """방식 정의 — **표시 순서대로** `{key, label, cls}`. 방식이 없으면 빈 목록.

    색 클래스는 **표시 순서**로 붙는다(화면의 첫째 방식 `--brand`, 둘째 `--slot-b` …, `extra` = 두 색
    줄무늬, fallback = 회색). 규칙 순서로 붙이면 안 된다 — 규칙 순서는 매칭 우선순위라(「대출이자」가
    「대출」에도 걸려 이자 지원을 먼저 본다) 화면 순서와 다르고, 그러면 막대 맨 앞 칸이 둘째 색이 된다.
    `display` 가 빠뜨린 키는 끝에 붙인다 — 막대에서 조용히 사라지면 방식 합이 보유 회사 수와 달라진다.
    """
    if not modes_cfg:
        return []
    rules, extra, fb = modes_cfg["rules"], modes_cfg.get("extra", []), modes_cfg["fallback"]
    labels = {x["key"]: x["label"] for x in (*rules, *extra, fb)}
    order = list(modes_cfg.get("display") or labels)
    order += [k for k in labels if k not in order]
    rule_keys = [k for k in order if k in {r["key"] for r in rules}]
    cls = {k: f"bn-m{i + 1}" for i, k in enumerate(rule_keys)}
    cls.update({x["key"]: "bn-mx" for x in extra})
    cls[fb["key"]] = "bn-m0"
    return [{"key": k, "label": labels[k], "cls": cls[k]} for k in order]


def _pct(n: int, total: int) -> str:
    """막대 폭(%) — 인라인 `style` 에 들어가므로 숫자만 돌려준다."""
    return f"{n / total * 100:.1f}" if total else "0"


def _name_chips(rows: list[dict]) -> dict:
    """회사들이 이 제도를 부르는 이름 — 빈도순(동률은 짧은 것 → 코드포인트, `find._prefer_name`)."""
    cnt = Counter(r["benefit"]["benefit_nm"] for r in rows)
    names = [nm for nm, _ in sorted(cnt.items(), key=_prefer_name)]
    return {"total": len(names), "shown": names[:NAME_CHIPS], "more": max(0, len(names) - NAME_CHIPS)}


def _amount_sources(rows: list[dict]) -> list[dict]:
    """금액 출처 칸 — 회사 카드 「항목 구성」과 **같은 통**(`company.lens_keys` 의 금액 축)을 센다.

    계보 축(재직자·만료)은 넘기지 않는다(`badge_code=""`) — 이 칸은 금액의 성격만 말한다.
    """
    per = Counter()
    for r in rows:
        m = amount_view(r["benefit"])
        per.update(lens_keys(m["amt_kind"], bool(m["qual"]), ""))
    return [{"key": k, "label": lb, "count": per[k]}
            for k, lb, _ in LENS_BUCKETS if k in ("stated", "est", "qual", "blank") and (per[k] or k != "blank")]


def _baseline_text(bl: dict) -> str:
    """법정 기준선 표의 `baseline` → 칸 하나. 표의 값을 옮길 뿐 문장을 짓지 않는다."""
    unit = bl.get("unit", "")
    kind = bl.get("type")
    if kind == "fixed":
        text = f"{bl['value']}{unit}"
        if bl.get("multiple_birth"):
            text += f" (다태아 {bl['multiple_birth']}{unit})"
        return text
    if kind == "tenure_table":
        vals = [row["value"] for row in bl.get("table", [])] + [row["cap"] for row in bl.get("table", []) if row.get("cap")]
        return f"{min(vals)}~{max(vals)}{unit} (근속별)" if vals else "—"
    if kind in ("set", "formula"):
        return str(bl.get("value", "—"))
    if kind == "rate":
        return f"{bl['value']}{unit}"
    return "—"


def _legal_view(code: str) -> dict:
    """「법으로 정해진 것」 칸 — 법정 기준선 표(`legal_baseline.json`)에서 **가져오기만** 한다.

    표의 `note` 는 싣지 않는다 — 수집 메모(「우리 데이터의 …은 재수집 대상」)가 섞인 **내부 칸**이다.
    새 법 문장도 만들지 않는다: 법이 바뀌면 표 하나를 고치면 되고, 페이지마다 문장이 있으면
    그 문장들이 표와 갈라진다.
    """
    items = [
        {
            "name": it["name"],
            "law": it["law"],
            "article": it["article"],
            "baseline": _baseline_text(it.get("baseline") or {}),
            "paid": it.get("paid_note") or PAID_LABEL.get(it.get("paid"), ""),
            "effective_from": it.get("effective_from", ""),
            "confidence": it.get("confidence", ""),
        }
        for it in legal.items() if code in (it.get("benefit_cds") or [])
    ]
    return {"entries": items, "reviewed": legal.raw().get("reviewed", "")}


def _row_view(r: dict, code: str, mode_by_key: dict) -> dict:
    """회사 표 한 줄. 원문은 회사 페이지 원장과 **같은 표시**(`format.benefit_desc`)다."""
    b = r["benefit"]
    desc = benefit_desc(b.get("qual_desc_ctnt"), b.get("amt_source"))
    note = benefit_desc(b.get("note_ctnt"), b.get("amt_source"))
    # 회사 페이지는 9카테고리 밖 행을 원장에 그리지 않는다(`_group_benefits`) — 그 행에 앵커를 걸면
    # 에러 없이 페이지 맨 위로 떨어지는 링크가 된다.
    anchor = f"#{benefit_anchor(code)}" if b.get("benefit_ctgr_cd") in CATEGORY_LABEL else ""
    return {
        "comp_nm": r["comp_nm"],
        "href": f"/company/{r['slug']}{anchor}",
        "name": b["benefit_nm"],
        "desc": desc,
        # 정성 설명과 비고는 다른 칸이다 — 회사 페이지 원장과 같이 둘 다 싣고, 같으면 한 번만.
        "note": note if note != desc else "",
        "mode": mode_by_key.get(r.get("mode")),
        "legal": r["legal"],
        **amount_view(b),
    }


def _split_first(rows: list[dict], order: list) -> tuple[list[dict], list[dict]]:
    """첫 화면 행 — 방식마다 **고르게** 한 줄씩 돌아가며 `FIRST_ROWS` 까지. 나머지는 접는다.

    방식 순으로 앞에서 자르면 첫 화면이 전부 첫째 방식이 되어 「회사마다 다르다」는 이 페이지의
    요지가 첫 화면에서 안 보인다.
    """
    if len(rows) <= FIRST_ROWS:
        return rows, []
    groups = {k: [r for r in rows if r["mode_key"] == k] for k in order}
    picked: set[int] = set()
    depth = 0
    while len(picked) < FIRST_ROWS and any(depth < len(g) for g in groups.values()):
        for k in order:
            if len(picked) < FIRST_ROWS and depth < len(groups[k]):
                picked.add(id(groups[k][depth]))
        depth += 1
    return [r for r in rows if id(r) in picked], [r for r in rows if id(r) not in picked]


def build_view(ctx, cfg: dict, codes: dict | None = None) -> dict:
    """뷰모델(순수 — 테스트가 직접 검사). 보유 회사 수 판정은 호출자(`render_all`)가 한다.

    `codes` 는 `find.derive_codes` 결과다(빵부스러기 카테고리가 /find 표의 카테고리와 **같은 집계**
    에서 나와야 두 화면이 다른 칸을 가리키지 않는다). 없으면 여기서 만든다.
    """
    code = cfg["code"]
    codes = codes if codes is not None else derive_codes(ctx.companies)
    all_rows = collect_rows(ctx, code)
    legal_rows = [r for r in all_rows if r["legal"]]
    # 세는 행 = 법정 행과 `exclude` 예외를 **둘 다** 뺀 나머지다. 아래의 N·방식·원문·질문·금액 출처·
    # 부르는 이름·표가 전부 이 목록 하나에서 나온다 — 분모가 둘이면 같은 페이지의 숫자가 서로 어긋난다.
    result = benefit_rules.classify(cfg, [r for r in all_rows if not r["legal"]])
    classified = result["rows"]
    n = len(classified)

    modes_cfg = cfg.get("modes")
    mode_defs = _mode_defs(modes_cfg)
    mode_by_key = {m["key"]: m for m in mode_defs}
    fallback = modes_cfg["fallback"]["key"] if modes_cfg else None
    modes = [{**m, "count": result["modes"].get(m["key"], 0),
              "pct": _pct(result["modes"].get(m["key"], 0), n)} for m in mode_defs]

    facets = [{"key": f["key"], "label": f["label"], "count": result["facets"][f["key"]],
               "pct": _pct(result["facets"][f["key"]], n)} for f in cfg["facets"]]

    questions = []
    for q in cfg["questions"]:
        k = sum(1 for r in classified if benefit_rules.answered(q, r, fallback))
        questions.append({"text": q["text"], "count": k, "pct": _pct(k, n)})

    order_idx = {m["key"]: i for i, m in enumerate(mode_defs)}

    def _sorted(rows):
        return sorted(rows, key=lambda r: (order_idx.get(r.get("mode"), 0), r["comp_nm"]))

    money = None
    mf = cfg.get("money_facet")
    if mf:
        hits = [r for r in classified if mf in r["facets"]]
        if len(hits) >= MONEY_MIN_ROWS:
            money = {"rows": [_row_view(r, code, mode_by_key) for r in _sorted(hits)]}

    table = []
    for r in _sorted(classified):
        row = _row_view(r, code, mode_by_key)
        row["mode_key"] = r.get("mode")
        table.append(row)
    first, rest = _split_first(table, [m["key"] for m in mode_defs] or [None])
    # 법정 행은 **맨 끝**에 배지를 달고 남긴다 — 세지 않은 행이 센 행 사이에 끼면 표의 머리 숫자와
    # 눈으로 센 줄 수가 어긋나 보인다.
    legal_view = [dict(_row_view(r, code, mode_by_key), mode_key=None) for r in sorted(legal_rows, key=lambda r: r["comp_nm"])]
    if rest:
        rest += legal_view
    else:
        first += legal_view

    ctgr = (codes.get(code) or {}).get("ctgr", "")
    total = len(ctx.companies)
    return {
        "code": code,
        "slug": cfg["slug"],
        "title": cfg["title"],
        "category": {"key": ctgr, "label": CATEGORY_LABEL.get(ctgr, "")},
        "names": _name_chips(classified),
        "count": n,
        "total": total,
        "share": round(n / total * 100) if total else 0,
        "amount_sources": _amount_sources(classified),
        "intro": list(cfg["intro"]),
        "modes": modes if modes_cfg else [],
        "mode_label": modes_cfg.get("label", "방식") if modes_cfg else "",
        "facets": facets,
        "money": money,
        "questions": questions,
        # 자리마다 빈 문자열을 깔아 둔다 — StrictUndefined 라 없는 키를 템플릿이 읽으면 렌더가 죽는다.
        "notes": {k: (cfg.get("notes") or {}).get(k, "") for k in benefit_rules.NOTE_SLOTS},
        "legal": _legal_view(code),
        "legal_rows": len(legal_rows),
        "rows_first": first,
        "rows_rest": rest,
        "stale": result["stale"],
        # 예외로 뺀 행(`exclude`) — 화면 어디에도 없다. 빌드 로그에만 남긴다(데이터 재코딩 대상 목록).
        "excluded": [{"comp": r["comp"], "why": r["why"]} for r in result["excluded"]],
    }


def _seo(view: dict, cfg=CFG) -> dict:
    """title·description — 항목마다 고유하다(제목 + 해설 첫 문장, GC-7)."""
    url = f"{cfg.site_origin}/benefit/{view['slug']}"
    title = f"{view['title']} — 회사 {view['count']}곳의 복지 원문 비교 | {cfg.site_name}"
    lead = view["intro"][0] if view["intro"] else ""
    m = _FIRST_SENTENCE.match(lead)
    first = m.group(1) if m else lead
    desc = f"{view['title']} — 등록 회사 {view['total']}곳 중 {view['count']}곳 · {first}"
    if len(desc) > cfg.desc_max:
        desc = desc[: cfg.desc_max - 1].rstrip() + "…"
    return {
        "meta_title": title,
        "meta_desc": desc,
        "canonical": url,
        "og": {"title": title, "description": desc, "type": "website", "url": url,
               "image": cfg.site_origin + cfg.default_og_image},
    }


def load_configs() -> dict[str, dict]:
    """설정 전부 + 구조 검사. 오류가 하나라도 있으면 빌드를 멈춘다(`benefit_rules.validate` 주석)."""
    cfgs = benefit_rules.load_pages()
    errs = benefit_rules.validate_all(cfgs)
    if errs:
        raise BuildError("SP-BEN 설정 오류: " + " / ".join(errs))
    return cfgs


def render_all(env, ctx, cfg=CFG, *, configs: dict[str, dict] | None = None,
               min_companies: int = MIN_COMPANIES, log=sys.stderr) -> list[Page]:
    """설정마다 한 쪽. 보유 회사가 `min_companies` 미만인 항목은 건너뛰고 로그에 남긴다.

    `min_companies` 는 테스트 주입점이다(가짜 번들은 회사 3곳이라 실제 문턱으로는 한 쪽도 안 나온다).
    문턱은 법정 행과 `exclude` 예외를 **뺀 뒤**의 개수로 판정한다(`build_view` 의 N 과 같은 수).
    `stale` 예외 경고도 여기서 찍는다 — 실패가 아니라 **사람이 다시 볼 행**이다(원문이 바뀌었다).
    `exclude` 로 뺀 행도 한 줄 남긴다 — 화면에서는 사라졌지만 데이터는 아직 틀려 있다(재코딩 목록).
    """
    configs = configs if configs is not None else load_configs()
    codes = derive_codes(ctx.companies)
    tpl = env.get_template("benefit.html")
    pages: list[Page] = []
    for code in sorted(configs):
        view = build_view(ctx, configs[code], codes)
        for msg in view["stale"]:
            print(f"generator build: 복지 항목 예외 경고 — {msg}", file=log)
        if view["excluded"]:
            print(f"generator build: 복지 항목 {code} — 예외로 뺀 행 {len(view['excluded'])}곳"
                  f"({', '.join(x['comp'] for x in view['excluded'])})", file=log)
        if view["count"] < min_companies:
            print(f"generator build: 복지 항목 페이지 {code} 건너뜀 — 보유 회사 {view['count']}곳"
                  f"(법정 행·예외 제외) < {min_companies}", file=log)
            continue
        seo = _seo(view, cfg)
        html = tpl.render(view=view, **seo, cfg=cfg, footer_links=POLICY_FOOTER_LINKS, nav_active="/find")
        pages.append(Page(path=f"benefit/{view['slug']}.html", url=seo["canonical"], html=html,
                          title=seo["meta_title"], description=seo["meta_desc"]))
    return pages


def links(pages: list[Page], configs: dict[str, dict] | None = None) -> dict[str, str]:
    """생성된 항목 페이지 → `{code: "/benefit/{slug}"}`. `/find` 표가 이 사전으로 링크를 건다.

    **렌더된 페이지에서** 만든다(설정 목록이 아니라). 문턱에 걸려 안 만들어진 항목에 링크를 걸면
    죽은 링크다 — GC-20 이 잡지만, 애초에 만들지 않는 편이 낫다.
    """
    configs = configs if configs is not None else benefit_rules.load_pages()
    by_slug = {c["slug"]: code for code, c in configs.items()}
    out = {}
    for p in pages:
        if p.path.startswith("benefit/") and p.path.endswith(".html"):
            slug = p.path[len("benefit/"):-len(".html")]
            if slug in by_slug:
                out[by_slug[slug]] = f"/benefit/{slug}"
    return out
