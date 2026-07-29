"""generator/stats.py — 번들 집계 통계 (SP-GEN-14).

**왜 있는가**: 2026-07-21 AdSense 반려("가치 없는 콘텐츠") 대응으로 신설하는
`/guide` 편집 콘텐츠 중 A군 6편이 "우리 데이터가 실제로 무엇을 말하는가"를 다룬다.
그 글의 값어치는 다른 사이트가 쓸 수 없는 집계라는 데서 나오므로, 집계는 정확해야
하고 무엇보다 **글과 데이터가 갈라지면 안 된다**.

**왜 하드코딩이 아닌가**: 본문에 "1,317건"을 박아 두면 데이터가 늘어난 다음 날부터
그 문장은 거짓이다. 여기서 계산한 값을 산문 자리표시자에 주입하면 글이 데이터를
따라간다. `content/policy.py` 가 `_RETENTION` 을 테스트로 서버 설정에 묶어 둔 것과
같은 원리 — 조용히 거짓이 되는 경로를 구조로 차단한다.

**경계**: 이 모듈은 세기만 한다. 해석·맥락·판단은 `content/guides.py` 의 손글씨
산문이 소유한다. 여기서 나오지 않는 수치를 글이 주장해서는 안 된다.
"""
from __future__ import annotations

import re
from dataclasses import dataclass, field

from generator.pages.company import CATEGORY_LABEL, CATEGORY_ORDER

# 근무형태 5축 — combo.py `_WS_LABEL_MAP` 과 같은 라벨을 쓴다(같은 개념의 두 표기 금지).
WORK_STYLE_KEYS = ("remote", "flex", "unlimitedPTO", "refreshLeave", "overtime")
WORK_STYLE_LABEL = {
    "remote": "재택근무",
    "flex": "유연근무",
    "unlimitedPTO": "무제한 휴가",
    "refreshLeave": "리프레시 휴가",
    "overtime": "야근 있음(고지)",
}

_SAFE_URL = re.compile(r"^https?://", re.I)

TOP_BENEFIT_NAMES = 20  # 흔한 복지 이름 상위 N


@dataclass(frozen=True)
class Dist:
    """수치 분포 — 표본이 비면 대표값은 0이 아니라 None 이다.

    0 을 돌려주면 "복지 금액 중앙값 0원"처럼 **없는 사실을 주장**하게 된다.
    """

    values: tuple[float, ...]
    count: int
    min: float | None
    max: float | None
    median: float | None
    mean: float | None
    p25: float | None
    p75: float | None


def _quantile(sorted_vals: list[float], q: float) -> float:
    """선형보간 분위수. 표본이 작아도 결정적이며 numpy 의존을 만들지 않는다."""
    if len(sorted_vals) == 1:
        return sorted_vals[0]
    pos = (len(sorted_vals) - 1) * q
    lo = int(pos)
    hi = min(lo + 1, len(sorted_vals) - 1)
    frac = pos - lo
    return sorted_vals[lo] * (1 - frac) + sorted_vals[hi] * frac


def dist(values) -> Dist:
    """수치 목록 → `Dist`. 정렬·분위 계산은 여기 한 곳에만 둔다."""
    vals = sorted(float(v) for v in values)
    if not vals:
        return Dist((), 0, None, None, None, None, None, None)
    return Dist(
        values=tuple(vals),
        count=len(vals),
        min=vals[0],
        max=vals[-1],
        median=_quantile(vals, 0.5),
        mean=sum(vals) / len(vals),
        p25=_quantile(vals, 0.25),
        p75=_quantile(vals, 0.75),
    )


@dataclass(frozen=True)
class CategoryStat:
    key: str
    label: str
    item_count: int  # 이 카테고리에 속한 복지 행 수
    company_count: int  # 이 카테고리를 하나라도 가진 회사 수
    company_share: float  # 위를 전체 회사 수로 나눈 %


@dataclass(frozen=True)
class GroupStat:
    """업종·기업유형 등 회사 묶음 단위 집계."""

    name: str
    company_count: int
    benefit_count: int
    benefit_median: float | None
    top_categories: tuple[tuple[str, int], ...]  # [(라벨, 항목수)] 상위 3


@dataclass(frozen=True)
class WorkStyleStat:
    key: str
    label: str
    company_count: int
    share: float  # %


@dataclass(frozen=True)
class NameCount:
    name: str
    count: int


@dataclass(frozen=True)
class Stats:
    """가이드 A군·B군이 소비하는 집계 일체 (SP-GEN-14)."""

    company_count: int
    benefit_count: int
    benefits_per_company: Dist
    categories: tuple[CategoryStat, ...]
    industries: tuple[GroupStat, ...]
    company_types: tuple[GroupStat, ...]
    work_style: tuple[WorkStyleStat, ...]
    company_value: Dist  # 회사별 정량 복지 금액 합(만원)
    quantified_count: int
    qualitative_count: int
    amt_source: dict = field(default_factory=dict)  # stated/estimated/none 별 행 수
    badge_src: dict = field(default_factory=dict)  # scrape_official/ai_parse/… 별 행 수
    src_url_count: int = 0  # http(s) 출처 URL 을 가진 행 수
    src_url_share: float = 0.0  # 위를 전체 행 수로 나눈 %
    top_benefit_names: tuple[NameCount, ...] = ()


def _pct(part: int, whole: int) -> float:
    return (part / whole * 100) if whole else 0.0


def _top_categories(companies) -> tuple[tuple[str, int], ...]:
    counts: dict[str, int] = {}
    for c in companies:
        for b in c["benefits"]:
            cat = b["benefit_ctgr_cd"]
            if cat in CATEGORY_LABEL:
                counts[cat] = counts.get(cat, 0) + 1
    ordered = sorted(counts.items(), key=lambda kv: (-kv[1], CATEGORY_ORDER.index(kv[0])))
    return tuple((CATEGORY_LABEL[k], n) for k, n in ordered[:3])


def _group_stat(name: str, companies: list[dict]) -> GroupStat:
    per = [len(c["benefits"]) for c in companies]
    return GroupStat(
        name=name,
        company_count=len(companies),
        benefit_count=sum(per),
        benefit_median=dist(per).median,
        top_categories=_top_categories(companies),
    )


def _industry_groups(companies) -> tuple[GroupStat, ...]:
    """업종 토큰별 묶음. `_industry_tokens` 를 재사용해 회사 페이지의 업종 판정과
    같은 정규화를 쓴다 — 같은 개념을 두 곳에서 다르게 쪼개면 글과 사이트가 어긋난다.

    한 회사가 복수 토큰('전자/반도체')을 가지면 각 토큰에 모두 계상된다. 따라서
    그룹 회사 수의 합은 전체 회사 수보다 클 수 있다(중복 계상은 의도).
    """
    buckets: dict[str, list[dict]] = {}
    for c in companies:
        raw = (c.get("industry_nm") or "").strip()
        if not raw:
            continue
        # 표시는 원문 토큰, 묶음 키는 casefold 정규화(같은 업종의 대소문자 분열 방지).
        for tok in re.split(r"[/·,&]", raw):
            tok = tok.strip()
            if tok:
                buckets.setdefault(tok.casefold(), []).append((tok, c))
    out = []
    for _, pairs in buckets.items():
        label = pairs[0][0]
        out.append(_group_stat(label, [c for _, c in pairs]))
    return tuple(sorted(out, key=lambda g: (-g.company_count, g.name)))


def _company_type_groups(companies, types_by_cd) -> tuple[GroupStat, ...]:
    """기업유형별 묶음. **types 테이블에 없는 코드는 버린다** — 코드를 그대로
    노출하면 'unlisted' 같은 내부 값이 사용자 화면의 유형 이름이 되고, 라벨을
    지어내면 없는 유형을 주장하게 된다(UC-41 1a 정합).
    """
    buckets: dict[str, list[dict]] = {}
    for c in companies:
        t = types_by_cd.get(c["comp_tp_cd"])
        if not t or not t.get("comp_tp_nm"):
            continue
        buckets.setdefault(t["comp_tp_nm"], []).append(c)
    out = [_group_stat(name, cs) for name, cs in buckets.items()]
    return tuple(sorted(out, key=lambda g: (-g.company_count, g.name)))


def _category_stats(companies) -> tuple[CategoryStat, ...]:
    items: dict[str, int] = {}
    comps: dict[str, set] = {}
    for c in companies:
        for b in c["benefits"]:
            cat = b["benefit_ctgr_cd"]
            if cat not in CATEGORY_LABEL:
                continue
            items[cat] = items.get(cat, 0) + 1
            comps.setdefault(cat, set()).add(c["comp_eng_nm"])
    total = len(companies)
    return tuple(
        CategoryStat(
            key=k,
            label=CATEGORY_LABEL[k],
            item_count=items[k],
            company_count=len(comps[k]),
            company_share=_pct(len(comps[k]), total),
        )
        for k in CATEGORY_ORDER
        if k in items
    )


def _work_style_stats(companies) -> tuple[WorkStyleStat, ...]:
    total = len(companies)
    out = []
    for k in WORK_STYLE_KEYS:
        n = sum(1 for c in companies if (c.get("work_style_val") or {}).get(k))
        out.append(WorkStyleStat(k, WORK_STYLE_LABEL[k], n, _pct(n, total)))
    return tuple(out)


def _top_names(companies) -> tuple[NameCount, ...]:
    """복지 이름 빈도 상위 N.

    ⚠ 이름은 회사별로 기록된 원문이라 같은 복지가 다른 이름으로 잡힐 수 있다
    (식대 지원 / 중식 제공 …). 정규화로 합치면 그 판단이 곧 사실 주장이 되므로
    **합치지 않고** 원문 그대로 센다. 이 한계는 가이드 본문에도 그대로 적는다.
    """
    counts: dict[str, int] = {}
    for c in companies:
        for b in c["benefits"]:
            nm = (b.get("benefit_nm") or "").strip()
            if nm:
                counts[nm] = counts.get(nm, 0) + 1
    ordered = sorted(counts.items(), key=lambda kv: (-kv[1], kv[0]))
    return tuple(NameCount(nm, n) for nm, n in ordered[:TOP_BENEFIT_NAMES])


def build_stats(ctx) -> Stats:
    """빌드 컨텍스트 → 가이드가 소비할 집계 일체. 순수 함수(같은 번들 → 같은 결과)."""
    companies = ctx.companies
    rows = [b for c in companies for b in c["benefits"]]

    amt_source: dict[str, int] = {}
    badge_src: dict[str, int] = {}
    src_url_count = 0
    for b in rows:
        amt_source[b.get("amt_source") or "none"] = (
            amt_source.get(b.get("amt_source") or "none", 0) + 1
        )
        src = b.get("badge_src_cd") or "unknown"
        badge_src[src] = badge_src.get(src, 0) + 1
        if _SAFE_URL.match(b.get("badge_src_url_ctnt") or ""):
            src_url_count += 1

    # 회사별 정량 복지 금액 합(만원). 정성 항목(qual_yn)은 금액이 없으므로 제외한다 —
    # 0으로 더하면 "정성 복지 = 0원"이라는 주장이 되고, 그건 사실이 아니다.
    company_value = [
        sum(b["benefit_amt"] for b in c["benefits"] if not b["qual_yn"] and b["benefit_amt"])
        for c in companies
    ]

    return Stats(
        company_count=len(companies),
        benefit_count=len(rows),
        benefits_per_company=dist([len(c["benefits"]) for c in companies]),
        categories=_category_stats(companies),
        industries=_industry_groups(companies),
        company_types=_company_type_groups(companies, ctx.types_by_cd),
        work_style=_work_style_stats(companies),
        company_value=dist([v for v in company_value if v]),
        quantified_count=sum(1 for b in rows if not b["qual_yn"]),
        qualitative_count=sum(1 for b in rows if b["qual_yn"]),
        amt_source=amt_source,
        badge_src=badge_src,
        src_url_count=src_url_count,
        src_url_share=_pct(src_url_count, len(rows)),
        top_benefit_names=_top_names(companies),
    )


__all__ = [
    "CategoryStat",
    "Dist",
    "GroupStat",
    "NameCount",
    "Stats",
    "WorkStyleStat",
    "build_stats",
    "dist",
]
