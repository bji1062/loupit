"""generator/guide_report.py — 가이드 A편 「복지 공개 현황」 고정판 스냅숏 (SP-GUIDE-7, 2026-10-08, 리드 판정 (86)).

A편은 **날짜 고정판**이다. 판마다 이 모듈이 빌드 ctx 에서 숫자를 한 번 계산해 `generator/data/guide/report-<판>.json` 으로
떨어뜨리고, 페이지(`pages/guide_report.py`)는 그 JSON 만 읽는다. 빌드 ctx 의 숫자는 페이지에 들어가지 않는다 —
회사가 늘어도 이 판의 숫자는 바뀌지 않고, 바뀌었으면 새 판 = 새 파일 = 새 주소다(테스트가 파일 sha256 을 고정한다).

원칙
  · **사이트 정본 함수를 쓴다.** 셈 대상 = `marks.countable`(법정 · 업무 교육 표시 행을 뺀 행), 금액 갈래 = `format.amount_kind`,
    라벨 = 항목 페이지 제목 → 없으면 복지검색 표시명(`find.derive_codes`), 이름 묶음 키 = D편 `about_data._fold`,
    회사 유형 = 번들의 `comp_tp_cd`(`large` · `mid`).
  · **결정적이다.** 생성 시각이 없다 — 같은 입력이면 파일이 바이트 동일하다.
  · `report_facts` 는 순수 함수다(합성 ctx 로 정의 하나하나를 테스트한다).

CLI:
  python3 -m generator.guide_report --edition 2026-10 --asof 2026-10-08 --out generator/data/guide/report-2026-10.json
  (운영 번들로 ctx 를 만든다 — `build.py` 의 DB 경로와 같다. DB 는 SELECT 만 한다.)
"""
from __future__ import annotations

import argparse
import json
import statistics
import sys
from collections import Counter, defaultdict
from pathlib import Path

from generator import benefit_rules, marks
from generator.format import amount_kind, iso_date
from generator.pages.about_data import _fold
from generator.pages.find import derive_codes

DATA_DIR = Path(__file__).resolve().parent / "data" / "guide"

LARGE_CD = "large"
MID_CD = "mid"
GAP_MIN_COMPANIES = 15  # 대기업↔중견 차이를 비교할 항목의 공개 회사 하한(선정 규칙)
GAP_SIDE = 5            # 한쪽에서 고르는 항목 수
HALF_CD_MEAL = "meal"   # 해설 상자가 예로 드는 항목(식대) — 비율을 스냅숏에 박아 둔다
CHILD_EDU_CD = "child_edu"


def snapshot_path(edition: str) -> Path:
    return DATA_DIR / f"report-{edition}.json"


def _pct(n: int, d: int) -> float:
    return round(n / d * 100, 1) if d else 0.0


def _num(x: float):
    """중앙값 — 정수면 int 로(JSON · 화면에서 `24.0` 이 되지 않게)."""
    return int(x) if float(x).is_integer() else x


def edition_ko(edition: str) -> str:
    y, m = edition.split("-")
    return f"{int(y)}년 {int(m)}월"


def report_facts(ctx, *, edition: str, asof: str) -> dict:
    """빌드 ctx → 고정판 숫자(순수). 정의는 SPEC 21 SP-GUIDE-7 과 같다."""
    comps = list(ctx.companies)
    N = len(comps)
    large_ids = {c["comp_id"] for c in comps if c.get("comp_tp_cd") == LARGE_CD}
    mid_ids = {c["comp_id"] for c in comps if c.get("comp_tp_cd") == MID_CD}

    all_rows = [(c, b) for c in comps for b in (c.get("benefits") or [])]
    counted = [(c, b) for c in comps for b in marks.countable(c)]

    # 라벨 · slug — 항목 페이지가 있으면 그 제목 · slug, 없으면 복지검색 표시명
    pages = benefit_rules.load_pages()
    find_codes = derive_codes(comps)

    def label(cd: str) -> str:
        return (pages.get(cd) or {}).get("title") or (find_codes.get(cd) or {}).get("label") or cd

    def slug(cd: str):
        return (pages.get(cd) or {}).get("slug")

    has: dict[str, set] = defaultdict(set)
    for c, b in counted:
        if b.get("benefit_cd"):
            has[b["benefit_cd"]].add(c["comp_id"])

    def entry(cd: str) -> dict:
        s = has[cd]
        return {"code": cd, "label": label(cd), "slug": slug(cd), "comps": len(s), "pct": _pct(len(s), N),
                "large_pct": _pct(len(s & large_ids), len(large_ids)), "mid_pct": _pct(len(s & mid_ids), len(mid_ids))}

    top = sorted((entry(cd) for cd in has), key=lambda e: (-e["comps"], e["label"], e["code"]))
    half = [e for e in top if e["comps"] * 2 > N]  # 「절반 넘는」 = 회사 수×2 > N (정확히 절반은 넘지 않는다)

    # 금액 세 갈래 — 셈 대상 기준
    kinds = Counter(amount_kind(b) for _, b in counted)
    total = len(counted)
    stated_comps = {c["comp_id"] for c, b in counted if amount_kind(b) == "stated"}
    amt_comps = {c["comp_id"] for c, b in counted if amount_kind(b) in ("stated", "estimated")}
    stated_by_code = Counter(b["benefit_cd"] for _, b in counted if amount_kind(b) == "stated")
    st_top = sorted(stated_by_code.items(), key=lambda kv: (-kv[1], label(kv[0]), kv[0]))
    amount = {
        "stated": {"n": kinds["stated"], "pct": _pct(kinds["stated"], total)},
        "estimated": {"n": kinds["estimated"], "pct": _pct(kinds["estimated"], total)},
        "none": {"n": kinds["none"], "pct": _pct(kinds["none"], total)},
        "zero_comps": N - len(amt_comps),
        "stated_comps": len(stated_comps),
        "stated_top": ({"code": st_top[0][0], "label": label(st_top[0][0]), "n": st_top[0][1]} if st_top else None),
    }

    # 대기업↔중견 — 공개 회사 GAP_MIN_COMPANIES 곳 이상 항목만
    cand = [entry(cd) for cd in has if len(has[cd]) >= GAP_MIN_COMPANIES]
    for e in cand:
        e["diff"] = round(len(has[e["code"]] & large_ids) / len(large_ids) * 100 - len(has[e["code"]] & mid_ids) / len(mid_ids) * 100, 4) \
            if large_ids and mid_ids else 0.0
    large_more = sorted(cand, key=lambda e: (-e["diff"], e["code"]))[:GAP_SIDE]
    mid_more = sorted(cand, key=lambda e: (e["diff"], e["code"]))[:GAP_SIDE]

    def pick(e):
        return {k: e[k] for k in ("code", "label", "slug", "large_pct", "mid_pct", "comps")}

    per_codes = {c["comp_id"]: len({b["benefit_cd"] for b in marks.countable(c) if b.get("benefit_cd")}) for c in comps}

    def median_of(ids):
        return _num(statistics.median(per_codes[i] for i in ids)) if ids else 0

    gap = {"min_comps": GAP_MIN_COMPANIES, "mid_more": [pick(e) for e in mid_more],
           "large_more": [pick(e) for e in large_more],
           "median_large": median_of(large_ids), "median_mid": median_of(mid_ids)}

    # 표시 행
    def mark_stat(pred):
        rows = [(c, b) for c, b in all_rows if pred(c, b)]
        return {"rows": len(rows), "comps": len({c["comp_id"] for c, _ in rows})}

    kinds_mark = {k: mark_stat(lambda c, b, k=k: marks.row_mark(c.get("comp_eng_nm") or "", b.get("benefit_cd"), b.get("benefit_nm") or "") == k)
                  for k in marks.KINDS}
    summary_rows = [(c, b) for c, b in counted if marks.is_summary(b)]
    if any(amount_kind(b) != "none" for _, b in summary_rows):
        # 페이지의 「이 항목들에는 금액이 없습니다」가 거짓이 되는 순간이다 — 스냅숏을 뜨지 않고 멈춘다(리드 판정 필요).
        raise ValueError("guide_report: 검색 요약 행에 금액이 있다 — 문안 판정 필요")
    dated = sorted(iso_date(b.get("verified_dtm")) for c, b in counted if not marks.is_summary(b) and b.get("verified_dtm"))

    meal = entry(HALF_CD_MEAL) if HALF_CD_MEAL in has else None
    return {
        "edition": edition, "edition_ko": edition_ko(edition), "asof": asof,
        "N": N, "large": len(large_ids), "mid": len(mid_ids),
        "rows": len(all_rows), "counted": total, "codes": len(has),
        "names": len({_fold(b.get("benefit_nm")) for _, b in all_rows if _fold(b.get("benefit_nm"))}),
        "url_comps": sum(1 for c in comps if c.get("careers_benefit_url")),
        "marks": {**kinds_mark, "summary": {"rows": len(summary_rows), "comps": len({c["comp_id"] for c, _ in summary_rows})}},
        "vmin": dated[0] if dated else "", "vmax": dated[-1] if dated else "",
        "top": top, "half": half,
        "amount": amount, "gap": gap,
        "meal_large_pct": meal["large_pct"] if meal else None,
        "child_edu_slug": slug(CHILD_EDU_CD),
    }


def dumps(facts: dict) -> str:
    """결정적 직렬화 — 키 순서는 삽입 순서 · 끝 줄바꿈 하나."""
    return json.dumps(facts, ensure_ascii=False, indent=1) + "\n"


def load_snapshot(edition: str) -> dict:
    return json.loads(snapshot_path(edition).read_text(encoding="utf-8"))


def main(argv=None) -> int:
    ap = argparse.ArgumentParser("가이드 A편 고정판 스냅숏")
    ap.add_argument("--edition", required=True, help="판 — 예: 2026-10")
    ap.add_argument("--asof", required=True, help="데이터 기준일 — 예: 2026-10-08")
    ap.add_argument("--out", required=True)
    a = ap.parse_args(argv)
    from generator.bundle import load_bundle_with_metrics
    from generator.context import build_context
    bundle, finance, employ = load_bundle_with_metrics()
    ctx = build_context(bundle, finance=finance, employ=employ)
    Path(a.out).write_text(dumps(report_facts(ctx, edition=a.edition, asof=a.asof)), encoding="utf-8")
    print(f"guide_report: {a.out}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
