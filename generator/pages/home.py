"""generator/pages/home.py — 대문 `/` (SCR-01·SCR-10). 대문 재설계 2단계(2026-09-13).

1단계(2026-09-12, PR #43)는 대문을 「고밀도 정적 허브」로 바꾸되 HTML 을 **손으로** 썼다. 숫자와 회사
목록이 전부 고정값이라 회사 확장 웨이브가 공개되는 순간 거짓이 된다(「2026-09-12 기준」이 임시 방어선이었다).
이 모듈은 같은 대문을 **빌드마다 데이터에서** 만든다. 규칙은 1단계 산출 스크립트를 그대로 옮겼고, 거기서
사람이 판단하던 자리는 아래 상수·함수로 적었다(정본 설계 = 대문 재설계 아티팩트, handoff 2026-09-12·09-13).

원칙
  · **같은 로더·같은 표기** — 회사 페이지·히트맵·복지검색과 같은 함수로 세고 적는다(`derive_codes`·
    `sector_of`·`corpus.build`·`employ._to_manwon/_to_year`·`format.krw_manwon`). 대문과 상세가 다른
    숫자를 말하면 둘 다 못 믿는다.
  · **결정적** — 빌드 시각을 HTML 에 넣지 않는다. sitemap lastmod 는 내용 지문으로 정해지므로
    (`release.lastmod_index`) 시각이 들어가면 매 빌드가 「바뀐 페이지」가 된다. 기준일은 데이터에서 나온
    날짜(복지 최근 확인일)다.
  · **없는 데이터는 블록째 뺀다** — 직원 현황이 안 실린 빌드에 빈 순위표를 남기지 않는다(함정 (57)).
"""
from __future__ import annotations

import json
from collections import Counter
from pathlib import Path

from generator import corpus as corpus_mod
from generator.config import CFG
from generator.content.policy import POLICY_FOOTER_LINKS
from generator.context import Page
from generator.employ import _to_manwon, _to_year
from generator.format import iso_date, krw_manwon
from generator.pages import combo as combo_mod
from generator.pages.company import CATEGORY_LABEL, CATEGORY_ORDER
from generator.pages.find import derive_codes
from generator.sector import load_sectors, sector_of
from generator.slug import combo_slug

REGISTRATIONS_PATH = Path(__file__).resolve().parents[1] / "data" / "company_registrations.json"

# 네이버 서치어드바이저 소유확인(2026-07-21). 소유확인은 등록 URL(`/`) **하나만** 본다 — 지우면 소유권을 잃는다.
NAVER_SITE_VERIFICATION = "db7956bfac6b387b3c03f707dd526a763d420a7d"

# 브랜드가 첫 어절이어야 한다 — 구글 사이트 이름 신호는 홈 한 장의 h1·title·JSON-LD 에서만 읽힌다.
TITLE = "잡초위키 — 회사 복지·연봉·재무를 로그인 없이 열람·비교"
SITE_DESCRIPTION = "로그인 없이 열람하는 한국 상장사 복지·연봉·재무 위키"

SECTOR_TOP = 5            # 업종 묶음마다 싣는 회사 수(복지 항목 수 상위)
OTHER_SECTOR = "그 밖"     # 회사 1곳짜리 묶음만 여기로 합친다 — 나머지는 KRX 분류(히트맵과 같은 체계) 그대로
RANK_TOP = 5              # 「숫자로 보는 회사」 축마다 순위 수
SALARY_MIN_HEAD = 1000    # 평균연봉 순위 문턱 — 소인원 지주사가 상단을 독식한다
TOP_CODES = 12            # 복지 조건 칩(항목) 수
RECENT_WAVES = 2          # 「새로 등록된 회사」에 싣는 최근 웨이브 수


def _benefits(c: dict) -> list:
    return c.get("benefits") or []


def _link(c: dict, ctx) -> dict:
    return {"name": c["comp_nm"], "href": f"/company/{ctx.slugs[c['comp_eng_nm']]}"}


def _korean_date(iso: str | None) -> str:
    if not iso:
        return ""
    y, m, d = iso.split("-")
    return f"{int(y)}년 {int(m)}월 {int(d)}일"


def load_registrations(path=None) -> list[dict]:
    """등록 이력(`generator/data/company_registrations.json`) → 웨이브 목록, **최신 날짜가 먼저**.

    번들에 등록일 필드가 없고 `TCOMPANY.INS_DTM` 은 `load.py --fresh` 한 번에 전부 그날로 초기화된다 —
    그래서 커밋되는 파일이 정본이다. 회사 등록 PR 이 여기를 빠뜨리면 test_home_page.py 가 붉어진다.
    """
    p = Path(path) if path else REGISTRATIONS_PATH
    raw = json.loads(p.read_text(encoding="utf-8"))
    return sorted(raw.get("waves") or [], key=lambda w: w["date"], reverse=True)


def _recent_waves(ctx) -> list[dict]:
    """최근 웨이브 `RECENT_WAVES` 개 — 이번 빌드에 실제로 있는 회사만(없는 회사는 링크가 404 다)."""
    out = []
    for wave in load_registrations():
        present = [ctx.by_eng[e] for e in wave.get("companies") or [] if e in ctx.by_eng]
        if not present:
            continue
        out.append({
            "date": wave["date"],
            "companies": [_link(c, ctx) for c in sorted(present, key=lambda c: c["comp_nm"])],
        })
        if len(out) == RECENT_WAVES:
            break
    return out


def _sector_groups(ctx) -> list[dict]:
    """업종 묶음(KRX, 히트맵과 같은 `sector_of`) — 회사 수 내림차순 · 묶음당 복지 항목 수 상위 `SECTOR_TOP`.

    회사 1곳짜리 묶음만 「그 밖」으로 합친다. 임의로 더 합치면 히트맵과 다른 업종 체계가 둘이 되고,
    둘 중 어느 쪽이 맞는지 아무도 모르게 된다(1단계 검증 결정).
    """
    sectors = load_sectors()
    by_sector: dict[str, list] = {}
    for c in ctx.companies:
        by_sector.setdefault(sector_of(ctx.finance.get(c["comp_id"]), sectors), []).append(c)
    groups, misc = [], []
    for name, members in by_sector.items():
        if len(members) < 2:
            misc.extend(members)
        else:
            groups.append((name, members))
    if misc:
        groups.append((OTHER_SECTOR, misc))
    groups.sort(key=lambda g: (-len(g[1]), g[0]))
    return [{
        "name": name,
        "total": len(members),
        "top": [dict(_link(c, ctx), n=len(_benefits(c)))
                for c in sorted(members, key=lambda c: (-len(_benefits(c)), c["comp_nm"]))[:SECTOR_TOP]],
    } for name, members in groups]


def _category_chips(ctx) -> list[dict]:
    out = []
    for key in CATEGORY_ORDER:
        n = len({c["comp_id"] for c in ctx.companies for b in _benefits(c) if b.get("benefit_ctgr_cd") == key})
        if n:
            out.append({"key": key, "label": CATEGORY_LABEL[key], "n": n})
    return out


def _code_chips(codes: dict) -> list[dict]:
    ranked = sorted(codes.values(), key=lambda i: (-i["count"], i["label"]))[:TOP_CODES]
    return [{"code": i["code"], "label": i["label"], "n": i["count"]} for i in ranked]


def _combos(ctx, pairs) -> list[dict]:
    """조합 링크 — 이름 순서는 **생성 페이지 h1 과 같은 규칙**(slug 가 앞선 쪽이 먼저, `combo.render_all`).

    `combinations.json` 의 a/b 순서를 그대로 쓰면 `/vs/kakao-naver` 의 h1「카카오 vs NAVER」와 링크 글자가
    어긋난다(1단계 검증 LOW ⑨ 실측).
    """
    notes: dict[frozenset, str] = {}
    try:
        raw = json.loads(combo_mod.COMBINATIONS_PATH.read_text(encoding="utf-8"))
        for item in raw.get("combinations", []):
            notes[frozenset((item["a"], item["b"]))] = item.get("note") or ""
    except (OSError, ValueError):
        notes = {}
    out = []
    for a, b in pairs:
        path, first, _second = combo_slug(a, b, ctx.slugs)
        eng_first = a if ctx.slugs[a] == first else b
        eng_second = b if eng_first == a else a
        out.append({
            "label": f"{ctx.by_eng[eng_first]['comp_nm']} vs {ctx.by_eng[eng_second]['comp_nm']}",
            "href": f"/vs/{path}",
            "note": notes.get(frozenset((a, b)), ""),
        })
    return out


def _numbers(ctx) -> dict:
    """「숫자로 보는 회사」 — 직원 3축(최신 사업연도 **한 해**) + 복지 항목 수 순위.

    ⓘ 연도: 전 회사 직원 데이터의 최신 연도 **하나**만 쓴다. 회사마다 자기 최신 연도를 쓰면 「2025 사업연도
      기준」이라 적어 놓고 2024 값이 섞인다(1단계 스크립트는 회사별 최신 연도를 썼다 — 여기서 바로잡는다).
    ⓘ 「공동」은 **정수 항목 수 전용**이다(1단계 handoff 결정 6). 근속·연봉은 소수·원 단위 원값으로 순서를
      정하고 표시만 반올림한다 — 17.42 와 17.35 가 둘 다 17.4년으로 보여도 동률이 아니다.
    """
    axes = []
    year = None
    if ctx.employ_loaded:
        year = max((y for e in ctx.employ.values() for y in e), default=None)
    if year is not None:
        rows = [(c, (ctx.employ.get(c["comp_id"]) or {}).get(year)) for c in ctx.companies]
        rows = [(c, v) for c, v in rows if v]

        def top(field, fmt, min_head=None):
            picked = [(c, v) for c, v in rows
                      if v.get(field) is not None and (min_head is None or (v.get("head") or 0) >= min_head)]
            picked.sort(key=lambda cv: (-cv[1][field], cv[0]["comp_nm"]))
            return [dict(_link(c, ctx), text=fmt(v[field])) for c, v in picked[:RANK_TOP]]

        axes += [
            {"title": "직원 수", "rows": top("head", lambda h: f"{int(h):,}명")},
            {"title": "평균 근속", "rows": top("tenure", lambda t: f"{_to_year(t):.1f}년")},
            {"title": f"평균연봉 ({SALARY_MIN_HEAD:,}명 이상)",
             "rows": top("salary", lambda s: krw_manwon(_to_manwon(s)), SALARY_MIN_HEAD)},
        ]
    corp = corpus_mod.build(ctx.companies, CATEGORY_ORDER)
    items = []
    for c in sorted(ctx.companies, key=lambda c: (-len(_benefits(c)), c["comp_nm"])):
        r = corp.rank_of(c["comp_id"])
        if r["items_rank"] > RANK_TOP:
            break
        text = f"공동 {r['item_count']}항목" if r["items_tied"] else f"{r['item_count']}항목"
        items.append(dict(_link(c, ctx), text=text))
    axes.append({"title": "복지 항목 수", "rows": items})
    return {"year": year, "salary_min_head": f"{SALARY_MIN_HEAD:,}", "axes": [a for a in axes if a["rows"]]}


def _trust(ctx) -> dict:
    """「읽기 전에 알아 둘 것」의 수 — 세 갈래(공식·추정·정성)와 금액 빈 행이 **전체 행 수로 닫힌다**.

    확인일 기준점은 가장 많은 행이 확인된 날(최빈값, 동률이면 늦은 날)이다 — 1단계는 2026-04-15 를
    손으로 적었다. 기준점을 데이터가 정해야 웨이브가 들어와도 문장이 참으로 남는다.
    """
    stated = estimated = qual = no_amount = 0
    dates: Counter = Counter()
    for c in ctx.companies:
        for b in _benefits(c):
            if b.get("qual_yn"):
                qual += 1
            elif b.get("benefit_amt") is None:
                no_amount += 1
            elif b.get("amt_source") == "stated":
                stated += 1
            else:
                estimated += 1
            dates[iso_date(b.get("verified_dtm"))] += 1
    total = stated + estimated + qual + no_amount
    dated = {d: n for d, n in dates.items() if d}
    pivot = max(dated.items(), key=lambda kv: (kv[1], kv[0]))[0] if dated else None
    return {
        "total": f"{total:,}",
        "stated": f"{stated:,}",
        "stated_pct": f"{(stated / total * 100) if total else 0:.1f}",
        "estimated": f"{estimated:,}",
        "qual": f"{qual:,}",
        "no_amount": f"{no_amount:,}" if no_amount else "",
        "pivot": _korean_date(pivot),
        "on_pivot": f"{dated.get(pivot, 0):,}",
        "after": f"{sum(n for d, n in dated.items() if pivot and d > pivot):,}",
        "before": f"{sum(n for d, n in dated.items() if pivot and d < pivot):,}",
        "undated": f"{dates.get('', 0):,}" if dates.get("", 0) else "",
        "latest": max(dated) if dated else "",
    }


def _year_range(ctx) -> str:
    years = set()
    for f in ctx.finance.values():
        for y in (f or {}).get("years") or []:
            if y.get("year") is not None:
                years.add(int(y["year"]))
    for e in ctx.employ.values():
        years.update(int(y) for y in e)
    return f"{min(years)}–{max(years)}" if years else ""


def build_view(ctx, pairs=None) -> dict:
    """뷰모델(순수 — 테스트가 직접 검사). 템플릿은 여기서 만든 **문자열을 그대로** 싣는다."""
    if pairs is None:
        pairs = combo_mod.load_pairs(ctx)
    codes = derive_codes(ctx.companies)
    type_counts = Counter(c.get("comp_tp_cd") for c in ctx.companies)
    types_text = ", ".join(
        f"{t['comp_tp_nm']} {type_counts[t['comp_tp_cd']]}"
        for t in ctx.types_by_cd.values() if type_counts.get(t["comp_tp_cd"])
    )
    recent = _recent_waves(ctx)
    rows = sum(len(_benefits(c)) for c in ctx.companies)
    return {
        "total_companies": len(ctx.companies),
        "total_rows": f"{rows:,}",
        "total_codes": len(codes),
        "types_text": types_text,
        "year_range": _year_range(ctx),
        "latest_registration": recent[0]["date"] if recent else "",
        "combos": _combos(ctx, pairs),
        "sectors": _sector_groups(ctx),
        "sector_top": SECTOR_TOP,
        "categories": _category_chips(ctx),
        "codes": _code_chips(codes),
        "numbers": _numbers(ctx),
        "recent": recent,
        "trust": _trust(ctx),
    }


def render(env, ctx, cfg=CFG, pairs=None) -> Page:
    view = build_view(ctx, pairs=pairs)
    url = f"{cfg.site_origin}/"
    n, rows, codes = view["total_companies"], view["total_rows"], view["total_codes"]
    desc = (f"잡초위키는 {n}곳 회사의 복지 {rows}건·연봉·재무를 로그인 없이 열람하고 두 회사를 비교합니다. "
            f"복지는 회사 공식 페이지에서 수집해 표준 항목 {codes}종으로 분류합니다.")
    og_desc = f"회사 {n}곳의 복지 {rows}건·연봉·재무를 로그인 없이 열람하고 두 회사를 비교합니다."
    jsonld = {
        "@context": "https://schema.org", "@type": "WebSite", "name": "잡초위키",
        "alternateName": [cfg.site_name, "잡초"], "url": url, "inLanguage": "ko",
        "description": SITE_DESCRIPTION,
    }
    html = env.get_template("home.html").render(
        view=view, meta_title=TITLE, meta_desc=desc, canonical=url,
        og={"title": TITLE, "description": og_desc, "type": "website", "url": url,
            "image": cfg.site_origin + cfg.default_og_image},
        jsonld=jsonld, naver_site_verification=NAVER_SITE_VERIFICATION, font_preload=False,
        cfg=cfg, footer_links=POLICY_FOOTER_LINKS, nav_active="/",
    )
    return Page(path="index.html", url=url, html=html, title=TITLE, description=desc)
