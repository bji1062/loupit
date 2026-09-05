"""generator/corpus.py — 등록 회사 전체를 한 번 훑어 만드는 비교 기준 (SP-GEN-5.6).

회사 페이지의 레이더 점선(카테고리별 평균)·축 최댓값·순위는 **한 회사만 보고는 만들 수 없다**.
빌드마다 한 번 계산해 전 회사가 같은 값을 쓴다 — 회사마다 따로 계산하면 O(n²) 이고, 더 나쁘게는
페이지마다 다른 기준이 섞일 여지가 생긴다.

⚠ **회사가 하나 추가되면 전 회사 페이지를 다시 만들어야 한다.** 평균·최댓값·순위가 전부
움직이기 때문이다(정적 재생성은 이미 이 프로젝트의 규칙이다 — 부분 렌더 `--only` 는 서빙 dist 로
스왑할 수 없게 막혀 있다).

**순위는 사실만 말한다**(DEC-B): 등수와 **동률 여부**를 함께 낸다. 동률을 숨긴 "2번째"는
거짓이 되기 때문이다(실측: SK텔레콤 27항목 = LG CNS 27항목).

🚨 **여기서 나가는 순위는 「등록 복지 항목 수」 하나뿐이다.** 금액 합(`amounts`)은 부제·카드의
합계 문구가 쓰는 값일 뿐, **등수도 몫도 만들지 않는다** — 등록 금액에는 대출 한도(CJ ENM 커머스
'주택자금 대출' = 1억)·일회성 포상 같은 연간 환산이 아닌 값이 섞여 있어 그 합의 순위는 무엇으로
표현하든 거짓이다(D-6, SPEC 07). 키를 만들지 않는 것이 방어선이다: `render.py` 가
`StrictUndefined` 라 템플릿이 없는 키를 쓰는 순간 빌드가 죽는다.
"""
from __future__ import annotations

from dataclasses import dataclass


def _amount(benefits) -> int:
    """정량 복지 금액 합(만원). 정성·금액 미기재는 0 — 없는 값을 0 으로 **더하는** 것은 사실이다
    (0 으로 **표시**하는 것과 다르다)."""
    return sum(int(b["benefit_amt"]) for b in benefits
               if not b.get("qual_yn") and b.get("benefit_amt"))


def _rank(value: int, values: list[int]) -> tuple[int, int]:
    """(등수, 같은 값 회사 수). 경쟁 순위 — 동률이면 같은 등수를 갖고 다음 등수는 건너뛴다.

    **항목 수 전용이다.** 금액 합에 이 함수를 다시 물리지 마라(D-6)."""
    return 1 + sum(1 for v in values if v > value), sum(1 for v in values if v == value)


@dataclass(frozen=True)
class Corpus:
    """전 회사 기준값. `category_order` 순서의 리스트로 들고 다닌다(템플릿이 zip 하기 좋게)."""

    total: int  # 등록 회사 수
    avgs: dict[str, float]  # 카테고리별 평균 항목 수
    rmax: int  # 레이더 축 최댓값 = 한 카테고리 항목 수의 전 회사 최댓값
    items: dict[int, int]  # comp_id → 복지 항목 수
    amounts: dict[int, int]  # comp_id → 정량 금액 합(만원)

    def rank_of(self, comp_id: int) -> dict:
        """이 회사의 **항목 수 순위 + 동률 수**. 화면 문구는 템플릿이 만든다.

        금액 순위는 만들지 않는다 — 등록 금액에는 대출 한도·일회성 포상이 섞여 있어 등수든
        몫이든 거짓이 된다(D-6). 없는 키를 템플릿이 쓰면 `StrictUndefined` 가 빌드를 죽인다.
        """
        i_rank, i_tied = _rank(self.items.get(comp_id, 0), list(self.items.values()))
        return {
            "total": self.total,
            "item_count": self.items.get(comp_id, 0),
            "items_rank": i_rank,
            "items_tied": i_tied > 1,
        }


def build(companies: list[dict], category_order: list[str]) -> Corpus:
    """등록 회사 전체 → `Corpus`. 회사 0곳(빈 번들)도 죽지 않는다."""
    total = len(companies)
    counts: dict[str, list[int]] = {k: [] for k in category_order}
    rmax = 0
    items, amounts = {}, {}
    for c in companies:
        per: dict[str, int] = {k: 0 for k in category_order}
        for b in c["benefits"]:
            cat = b["benefit_ctgr_cd"]
            if cat in per:
                per[cat] += 1
        for k, v in per.items():
            counts[k].append(v)
            rmax = max(rmax, v)
        items[c["comp_id"]] = len(c["benefits"])
        amounts[c["comp_id"]] = _amount(c["benefits"])
    avgs = {k: (sum(v) / len(v) if v else 0.0) for k, v in counts.items()}
    return Corpus(total=total, avgs=avgs, rmax=max(rmax, 1), items=items, amounts=amounts)
