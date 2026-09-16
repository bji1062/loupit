"""generator/legal.py — 법정 기준선 조회 (SP-LEGAL-1, 2026-09-16).

복지는 「회사가 주는 것」이 아니라 **「법이 시킨 것 위에 더 얹은 것」**이다.
그 기준선을 `data/legal_baseline.json` 하나가 갖고, 이 모듈만 읽는다.

**사용자 결정(2026-09-16) — 이 둘을 바꾸려면 결정을 다시 받아야 한다:**
  1. 금액 환산은 **이직 계산기에서만** 한다. 회사 상세·복지 비교에는 배지(일수·사실)까지만
     싣는다 — 사용자 맥락이 없는 화면에 금액을 박으면 연봉 4천인 사람에게도 1억인 사람에게도
     같은 숫자가 나가고, 둘 다 틀린다.
  2. 환산 단가는 **사용자가 입력한 연봉**이다. 회사 평균연봉(DART)을 단가로 쓰지 않는다 —
     회사마다 기준이 달라지고, 평균연봉 수집 오류가 그대로 금액으로 증폭된다
     (실제로 올릭스 2025 평균연봉이 전년 2.9배로 적재돼 라이브에 나가 있다).

⚠ **근로시간 상수는 여기 없다.** `MONTHLY_STD_HRS`·`OT_MULT`·`LEGAL_WEEK_HRS` 의 정본은
`web/assets/js/calc.js` 다. 같은 값을 두 곳에 두면 조용히 갈라진다 — 이 저장소가 배지 계보로
이미 한 번 밟은 함정이다. 여기서는 분모를 인자로 받아 쓰기만 한다.
"""
from __future__ import annotations

import json
import os
from functools import lru_cache

_PATH = os.path.join(os.path.dirname(__file__), "data", "legal_baseline.json")

# calc.js MONTHLY_STD_HRS 와 같은 값. 정본이 아니라 **기본값**이다 —
# 호출자가 넘기면 그쪽이 이긴다(테스트가 두 값의 일치를 강제한다).
DEFAULT_MONTHLY_STD_HRS = 209
HOURS_PER_DAY = 8


@lru_cache(maxsize=1)
def raw() -> dict:
    """표 전체. 캐시한다 — 빌드 중 여러 번 읽힌다."""
    with open(_PATH, encoding="utf-8") as f:
        return json.load(f)


def items() -> list[dict]:
    return raw()["items"]


def by_key(key: str) -> dict | None:
    return next((it for it in items() if it["key"] == key), None)


def identify_keys() -> list[str]:
    """법정 제도로 **식별**할 항목 — 배지 표기와 복지 항목 수 집계 제외에 쓴다."""
    return [it["key"] for it in items() if it["identify"]]


def convertible_keys() -> list[str]:
    """금액으로 **환산**할 항목. 연차 하나뿐이다(사용자 결정)."""
    return [it["key"] for it in items() if it["convert"]]


def benefit_cd_is_legal(benefit_cd: str) -> bool:
    """이 복지 항목 코드가 법정 제도에 걸리는가 — 항목 수 집계에서 뺄지 판단하는 입구."""
    return any(benefit_cd in (it.get("benefit_cds") or []) for it in items() if it["identify"])


# ── 연차 (근로기준법 제60조) ────────────────────────────────────────────────


def annual_leave_days(tenure_years: float | None) -> int:
    """근속연수별 **법정** 연차 일수.

    1년 미만 11일 · 1년 이상 15일 · 3년 이상부터 2년마다 1일 가산, 한도 25일.
    `tenure_years=None` 이면 **입사 1년차**로 본다 — 이직 계산기의 기본 상황이고,
    맥락 없는 화면에서 장기근속 기준을 쓰면 초과분이 부풀려진다.
    """
    if tenure_years is None:
        tenure_years = 1
    if tenure_years < 1:
        return 11
    if tenure_years < 3:
        return 15
    return min(15 + int((tenure_years - 1) // 2), 25)


def annual_leave_surplus(company_days: float | None, tenure_years: float | None = None) -> int | None:
    """회사 연차 − 법정 연차. **모르면 None**(0 아님).

    `None` 과 `0` 을 섞으면 일수를 못 모은 회사를 「더 안 주는 회사」로 깎게 된다.
    음수는 clamp 하지 않는다 — 법정 미달 표기는 우리 데이터가 낡았다는 신호다.
    """
    if company_days is None:
        return None
    return int(company_days) - annual_leave_days(tenure_years)


def daily_wage_manwon(annual_salary_manwon: float | None,
                      monthly_std_hours: int = DEFAULT_MONTHLY_STD_HRS) -> float | None:
    """통상임금 1일분(만원). 연봉 ÷ 12 ÷ 209 × 8.

    ⚠ 분모 209 는 **주휴시간을 포함**한 월 소정근로시간이다. 「근무일 21일」로 나누면
    같은 연봉에 일당이 약 24% 커져 초과분 금액이 통째로 부풀려진다.
    """
    if not annual_salary_manwon:
        return None
    return annual_salary_manwon / 12 / monthly_std_hours * HOURS_PER_DAY


def annual_leave_value(company_days: float | None,
                       annual_salary_manwon: float | None,
                       tenure_years: float | None = None,
                       monthly_std_hours: int = DEFAULT_MONTHLY_STD_HRS) -> dict:
    """연차 초과분의 연봉 환산 가치 — **이직 계산기 전용**.

    반환 `value_manwon` 은 「받는 돈」이 아니라 **「연봉 환산 가치」**다. 연차는 미사용 시
    수당 정산이 원칙이지만 사용촉진(제61조)을 쓰면 소멸하므로, 화면 문구를 그렇게 적어야 한다.
    단가가 없으면 금액을 만들지 않는다 — 회사 평균연봉으로 대체하지 않는다.
    """
    baseline = annual_leave_days(tenure_years)
    surplus = annual_leave_surplus(company_days, tenure_years)
    daily = daily_wage_manwon(annual_salary_manwon, monthly_std_hours)
    value = None if (surplus is None or daily is None) else round(surplus * daily, 1)
    return {
        "baseline_days": baseline,
        "company_days": company_days,
        "surplus_days": surplus,
        "daily_wage_manwon": daily,
        "value_manwon": value,
        "basis": "입사 1년차 기준" if tenure_years in (None, 1) else f"근속 {tenure_years}년 기준",
    }
