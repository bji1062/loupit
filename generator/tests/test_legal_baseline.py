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


# ── 법정 행 — 표시는 남기고 집계에서만 뺀다 (SP-LEGAL-5) ────────────────────


def test_legal_rows_lookup_is_by_company_code_and_name():
    """같은 코드(`parenting`·`leave_general`)에 법정 행과 진짜 복지 행이 섞여 있다.
    코드만 보고 판정하면 멀쩡한 복지가 통째로 빠진다."""
    assert legal.is_legal_row("rainbow_robotics", "parenting", "육아휴직")
    assert not legal.is_legal_row("yuhan", "leave_general", "연차휴가 (법정 상회)")
    assert not legal.is_legal_row("rainbow_robotics", "parenting", "다른 이름")


def test_legal_rows_all_exist_in_seed_sql():
    """참조 파일이 낡으면 빌드를 깨뜨린다.

    이 목록은 시드 SQL 이 아니라 생성기 참조 파일이다(`company_registrations.json` 선례).
    시드에서 행이 사라지거나 항목명이 바뀌면 판정이 조용히 False 가 되어 법정 행이 다시
    복지로 세어진다 — 그 침묵을 여기서 막는다.
    """
    from pathlib import Path

    import re

    seed_dir = Path(__file__).resolve().parents[2] / "db" / "seed" / "benefit" / "sql"
    # 회사 파일 단위로 좁힌다. 시드 전체를 한 덩어리로 이어 붙여 이름만 찾으면
    # 다른 회사가 같은 이름을 들고 있는 행은 자기 시드에서 사라져도 통과한다
    # (2026-09-21 실측: 등록 13행 중 4행이 그 상태였다 — 「출산/육아 지원」 7사 공유 등).
    by_slug = {}
    for path in seed_dir.glob("*.sql"):
        src = path.read_text(encoding="utf-8")
        m = re.search(r"COMP_ENG_NM\s*=\s*'([A-Za-z0-9_]+)'", src)
        if m:
            by_slug[m.group(1)] = src
    missing = [f"{r['comp_eng_nm']}/{r['benefit_nm']}" for r in legal.legal_rows()
               if f"'{r['benefit_nm']}'" not in by_slug.get(r["comp_eng_nm"], "")]
    assert not missing, f"시드에서 사라진 법정 행: {missing}"


def test_legal_rows_cover_the_audited_companies():
    rows = legal.legal_rows()
    # 2026-09-20: 시간·2시간 단위 휴가 5행을 복지로 되돌려 등록 해제(사용자 결정)
    assert len(rows) == 13
    assert len({r["comp_eng_nm"] for r in rows}) == 12
    for r in rows:
        assert r["desc_at_review"] and r["why"], f"{r['comp_eng_nm']} 판정 근거가 비었다"


def _fake_company(eng, benefit_names, ctgr="leave_general"):
    return {
        "comp_id": 1, "comp_eng_nm": eng, "comp_nm": eng,
        "benefits": [{"benefit_cd": ctgr, "benefit_nm": nm, "benefit_amt": None,
                      "benefit_ctgr_cd": "time_off", "qual_yn": True,
                      "qual_desc_ctnt": nm, "badge_cd": "est"} for nm in benefit_names],
    }


def test_corpus_excludes_legal_rows_from_item_count():
    """법정 행이 항목 수에 들어가면 근로기준법을 지키는 것만으로 순위가 오른다."""
    from generator import corpus as corpus_mod
    from generator.pages.company import CATEGORY_ORDER

    c = _fake_company("rainbow_robotics", ["육아휴직", "하계휴가"], ctgr="parenting")
    built = corpus_mod.build([c], CATEGORY_ORDER)
    assert built.items[1] == 1, "법정 행 1개가 항목 수에서 빠져야 한다"


def test_corpus_counts_normal_rows_of_the_same_code():
    """같은 코드의 진짜 복지 행까지 빠지면 안 된다."""
    from generator import corpus as corpus_mod
    from generator.pages.company import CATEGORY_ORDER

    c = _fake_company("yuhan", ["연차휴가 (법정 상회)", "하계휴가"])
    assert corpus_mod.build([c], CATEGORY_ORDER).items[1] == 2


def test_ledger_keeps_the_legal_row_but_flags_it(fake_now):
    """행은 남는다 — 「이 회사가 연차를 준다」는 사실은 정보다. 배지만 붙는다."""
    from generator.pages.company import _group_benefits

    c = _fake_company("rainbow_robotics", ["육아휴직", "하계휴가"], ctgr="parenting")
    groups = _group_benefits(c["benefits"], fake_now, comp_eng_nm="rainbow_robotics")
    items = [i for _, _, its in groups for i in its]
    assert len(items) == 2, "원장에서 행을 지우지 않는다"
    assert [i["legal"] for i in items].count(True) == 1


def test_group_benefits_without_company_name_flags_nothing(fake_now):
    """회사 이름이 없으면 판정이 전부 False 가 된다 — 조합 페이지가 eng 를 꼭 넘겨야 하는 이유."""
    from generator.pages.company import _group_benefits

    c = _fake_company("rainbow_robotics", ["육아휴직"], ctgr="parenting")
    groups = _group_benefits(c["benefits"], fake_now)
    assert all(not i["legal"] for _, _, its in groups for i in its)
