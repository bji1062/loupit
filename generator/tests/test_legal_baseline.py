"""법정 기준선 테이블 + 조회 (SP-LEGAL-1, 2026-09-16).

복지는 「회사가 주는 것」이 아니라 「법이 시킨 것 위에 더 얹은 것」이다. 그 기준선을
`generator/data/legal_baseline.json` 하나가 갖고, 이 모듈이 읽는다.

사용자 결정(2026-09-16):
  · 금액 환산은 **이직 계산기에서만**. 회사 상세·복지 비교는 배지(일수·사실)까지.
  · 환산 단가는 **사용자가 입력한 연봉**. 회사 평균연봉(DART)을 쓰지 않는다.
  · 환산 대상은 **연차 하나**. 2025 개정분 4건은 법 확인 전이라 잠가 둔다.
"""
from __future__ import annotations

import pytest

from generator import legal


# ── 표 자체의 계약 ──────────────────────────────────────────────────────────


def test_table_loads_and_every_item_has_the_required_fields():
    items = legal.items()
    assert len(items) >= 14
    for it in items:
        for f in ("key", "name", "law", "article", "identify", "convert", "baseline",
                  "paid", "confidence", "note"):
            assert f in it, f"{it.get('key')} 에 {f} 없음"


def test_keys_are_unique():
    keys = [it["key"] for it in legal.items()]
    assert len(keys) == len(set(keys))


def test_only_annual_leave_is_convertible():
    """환산은 연차 하나뿐(사용자 결정). 여기가 늘면 화면에 나가는 금액이 늘어난다 — 의도적으로만 늘릴 것."""
    assert legal.convertible_keys() == ["annual_leave"]


def test_every_item_is_identifiable():
    """식별은 15개 전부 — 법정 제도를 복지 항목 수에서 빼려면 전부 알아야 한다."""
    assert all(it["identify"] for it in legal.items())


def test_unconfirmed_items_are_locked_out_of_conversion():
    """2025 개정분은 법제처 확인 전이다. 확인 전에 금액이 나가면 그대로 틀린 숫자다."""
    for it in legal.items():
        if it["confidence"] == "확인필요":
            assert it["convert"] is False, f"{it['key']} 가 확인 전인데 환산 대상이다"


def test_unpaid_and_insurance_items_are_never_convertible():
    """무급·고용보험 부담은 회사 지출이 아니다 — 일당을 곱하면 없는 돈을 만든다."""
    for it in legal.items():
        if it["paid"] in ("unpaid", "insurance"):
            assert it["convert"] is False, f"{it['key']} 는 회사 지출이 아닌데 환산 대상이다"


def test_working_hour_constants_are_not_duplicated_here():
    """근로시간 상수의 정본은 calc.js 다. 여기 복제하면 두 값이 조용히 갈라진다."""
    raw = legal.raw()
    assert "MONTHLY_STD_HRS" not in str(raw.get("items")), "근로시간 상수를 items 에 복제하지 마라"
    assert raw["wage"]["monthly_std_hours_owner"].endswith("MONTHLY_STD_HRS")


def test_wage_source_is_user_input_not_company_average():
    """회사 평균연봉을 단가로 쓰면 회사마다 기준이 달라지고 수집 오류가 금액으로 증폭된다."""
    assert legal.raw()["wage"]["source"] == "user_input"


# ── 연차 법정 기준선(근속 함수) — 근로기준법 60조 ──────────────────────────


@pytest.mark.parametrize("years,expected", [
    (0, 11),    # 1년 미만: 1개월 개근 1일씩, 최대 11일
    (0.5, 11),
    (1, 15),    # 1년 이상 80% 출근: 15일
    (2, 15),
    (3, 16),    # 3년 이상부터 2년마다 +1
    (4, 16),
    (5, 17),
    (7, 18),
    (21, 25),   # 한도 25일
    (30, 25),
])
def test_annual_leave_baseline_by_tenure(years, expected):
    assert legal.annual_leave_days(years) == expected


def test_annual_leave_default_tenure_is_first_year():
    """맥락(근속)이 없으면 입사 1년차로 본다 — 이직 계산기의 기본 상황."""
    assert legal.annual_leave_days(None) == 15


# ── 초과분 ──────────────────────────────────────────────────────────────────


def test_surplus_is_company_days_minus_baseline():
    assert legal.annual_leave_surplus(22, tenure_years=1) == 7
    assert legal.annual_leave_surplus(15, tenure_years=1) == 0


def test_surplus_shrinks_for_long_tenure():
    """같은 22일도 10년차에겐 법정이 19일이라 초과가 3일뿐이다 — 15일 고정으로 보면 부풀려진다."""
    assert legal.annual_leave_days(10) == 19
    assert legal.annual_leave_surplus(22, tenure_years=10) == 3


def test_surplus_can_be_negative_and_is_not_clamped():
    """법정 미달은 숨기지 않는다 — 우리 데이터가 낡았다는 신호이기 때문이다(배우자 출산휴가 10일 사례)."""
    assert legal.annual_leave_surplus(12, tenure_years=1) == -3


def test_unknown_days_is_none_not_zero():
    """일수를 모르는 것과 초과분이 0인 것은 다르다. 섞으면 멀쩡한 회사를 0원으로 깎는다."""
    assert legal.annual_leave_surplus(None, tenure_years=1) is None


# ── 일당 — calc.js 통상임금 공식과 같은 값이어야 한다 ───────────────────────


def test_daily_wage_uses_ordinary_wage_formula():
    """통상임금 1일분 = 연봉 ÷ 12 ÷ 209 × 8. 209는 주휴시간을 포함하므로 근무일 21로 나누면 과대계상된다."""
    got = legal.daily_wage_manwon(10000)
    assert round(got, 2) == round(10000 / 12 / 209 * 8, 2)
    assert 31 < got < 33            # 연봉 1억 → 하루 약 31.9만원
    assert got < 10000 / 12 / 21    # ÷21 로 계산한 값보다 작아야 한다


def test_daily_wage_of_zero_or_missing_salary_is_none():
    assert legal.daily_wage_manwon(None) is None
    assert legal.daily_wage_manwon(0) is None


def test_annual_leave_value_end_to_end():
    """유한양행 연차 22일 · 사용자 연봉 1억 · 입사 1년차 → 7일 × 31.9만원."""
    v = legal.annual_leave_value(company_days=22, annual_salary_manwon=10000, tenure_years=1)
    assert v["surplus_days"] == 7
    assert v["baseline_days"] == 15
    assert 220 < v["value_manwon"] < 226


def test_value_is_none_when_days_unknown():
    v = legal.annual_leave_value(company_days=None, annual_salary_manwon=10000, tenure_years=1)
    assert v["surplus_days"] is None and v["value_manwon"] is None


def test_value_is_none_without_user_salary():
    """단가가 없으면 금액을 만들지 않는다 — 회사 평균연봉으로 대체하지 않는다."""
    v = legal.annual_leave_value(company_days=22, annual_salary_manwon=None, tenure_years=1)
    assert v["surplus_days"] == 7 and v["value_manwon"] is None


# ── 교차 언어 계약: calc.js 와 값이 갈리지 않는가 ───────────────────────────


def test_monthly_std_hours_matches_calc_js():
    """근로시간 상수의 정본은 `calc.js` 다. 파이썬 쪽 기본값이 그 값과 갈리면 같은 연차가
    화면(JS)과 생성기(파이썬)에서 다른 금액이 된다 — 이 저장소가 배지 계보로 이미 밟은 함정이다."""
    import re
    from pathlib import Path

    src = (Path(__file__).resolve().parents[2] / "web" / "assets" / "js" / "calc.js").read_text(encoding="utf-8")
    m = re.search(r"MONTHLY_STD_HRS\s*=\s*(\d+)", src)
    assert m, "calc.js 에서 MONTHLY_STD_HRS 를 못 찾았다 — 정본이 옮겨졌는지 확인하라"
    assert legal.DEFAULT_MONTHLY_STD_HRS == int(m.group(1))


def test_benefit_cd_lookup_flags_statutory_codes():
    """`leave_general`·`parenting` 은 법정 제도가 섞여 들어오는 코드다(2026-09-16 감사 80행)."""
    assert legal.benefit_cd_is_legal("leave_general")
    assert legal.benefit_cd_is_legal("parenting")
    assert not legal.benefit_cd_is_legal("meal")
