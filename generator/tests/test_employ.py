"""직원 현황 집계·지표 카드 계약 — `generator/employ.py` (SP-MET-8·10, 2026-08-28 DART 전수 실측).

여기서 못박는 것은 **수치가 조용히 틀어지는 네 자리**다. 전부 실측 근거가 있다.

  1. 합계행(SP-MET-5): 7사가 부문행과 합계행을 함께 낸다 — 다 더하면 삼성전자가 **257,762 명**이 된다.
  2. 가중평균(SP-MET-8): 단순평균은 남녀·부문 규모를 무시한다 — 삼성전자 2025 는 단순 14,850만원,
     인원 가중 **15,706만원**. 58개사가 5% 이상 틀어진다.
  3. 금융 세트(SP-MET-2): 세 번째 카드는 매출이 아니라 **자산총계**이고, 영업이익은 7/7 로 있다.
  4. 결측: 없는 값은 None 이지 0 이 아니고, 그림에서 자리를 비운다(0 으로 이으면 거짓이 된다).

수집·정규화(단위·근속 표기·합계행 판정)는 `server/tests/test_dart_employ.py` 가 본다. DB 는 여기서
건드리지 않는다 — 로더가 받는 **행 모양**만 픽스처로 재현한다(`TCORP_EMPLOY` SELECT 결과).
"""
from __future__ import annotations

import json
import re
from decimal import Decimal

import pytest

from generator import employ as employ_module
from generator.context import build_context
from generator.employ import (
    assemble,
    company_metrics,
    coverage,
    is_loaded,
    normalize,
    year_over_year,
)

SAMSUNG, CJ, KAKAOPAY = "00126380", "00265324", "00918444"

MAP_ROWS = [
    {"comp_id": 1, "corp_code": SAMSUNG},
    {"comp_id": 2, "corp_code": "00164779"},  # 매핑만 있고 직원 행이 없는 회사(1/100 실측)
    {"comp_id": 98, "corp_code": CJ},
    {"comp_id": 99, "corp_code": CJ},  # 형제 페이지 — 한 법인을 둘이 가리킨다(함정 (69))
]


def _row(corp_code, year, total, head, tenure, salary):
    """`TCORP_EMPLOY` SELECT 한 행. TENURE_YEAR 는 DECIMAL(5,2) 라 Decimal 로 온다."""
    return {"corp_code": corp_code, "year": year, "total_row": 1 if total else 0, "head": head,
            "tenure": None if tenure is None else Decimal(tenure), "salary": salary}


# 삼성전자 2025 — 부문 4행 + 성별합계 2행이 **함께** 온다(SP-MET-5 실측 구조).
# 합계행 인원 90,214 + 38,667 = 128,881(SP-MET-1 검증값), 부문행 합도 같은 128,881.
# 급여는 합계행과 부문행을 일부러 다르게 두었다 — 부문행이 섞이면 값에서 티가 나야 한다.
SAMSUNG_2025 = [
    _row(SAMSUNG, 2025, False, 60_000, "14.20", 100_000_000),
    _row(SAMSUNG, 2025, False, 25_000, "10.10", 90_000_000),
    _row(SAMSUNG, 2025, False, 30_214, "15.00", 200_000_000),
    _row(SAMSUNG, 2025, False, 13_667, "11.00", 80_000_000),
    _row(SAMSUNG, 2025, True, 90_214, "14.50", 169_900_000),
    _row(SAMSUNG, 2025, True, 38_667, "11.83", 127_100_000),
]
SAMSUNG_2024 = [
    _row(SAMSUNG, 2024, True, 88_000, "14.00", 160_000_000),
    _row(SAMSUNG, 2024, True, 37_000, "11.50", 120_000_000),
]

TOTAL_HEAD = 128_881
WEIGHTED_SALARY = round((90_214 * 169_900_000 + 38_667 * 127_100_000) / TOTAL_HEAD)
SIMPLE_SALARY = (169_900_000 + 127_100_000) // 2  # 148,500,000 — 이 수가 나오면 가중이 안 된 것이다


def _fin(acct_set, fs_div, years, corp_nm="삼성전자"):
    """`finance.assemble` 이 내는 FinanceView 모양(회사 한 곳 몫)."""
    return {"corp_nm": corp_nm, "stock_cd": "005930", "acct_set": acct_set, "fs_div": fs_div,
            "years": years, "siblings": []}


# 삼성전자 2025 연결(SP-MET-1 검증값: 매출 333.6조 · 영업이익 43.6조 · 순이익 45.2조)
SAMSUNG_FIN = _fin("general", "CFS", [
    {"year": 2024, "revenue": 300_000_000_000_000, "op_income": 32_000_000_000_000,
     "net_income": 34_000_000_000_000, "assets": None, "rcept_no": "20250311000002"},
    {"year": 2025, "revenue": 333_600_000_000_000, "op_income": 43_600_000_000_000,
     "net_income": 45_200_000_000_000, "assets": None, "rcept_no": "20260318000001"},
])

# 금융 세트 실측(SP-MET-2, 2025): 기업은행 자산 5,006,926억 · 영업이익 36,555억.
IBK_FIN = _fin("financial", "CFS", [
    {"year": 2025, "revenue": None, "assets": 500_692_600_000_000,
     "op_income": 3_655_500_000_000, "net_income": 2_800_000_000_000, "rcept_no": "20260320000010"},
], corp_nm="중소기업은행")

# 카카오페이 자산 53,395억 · 영업이익 503억 — **같은 금융 세트인데 자릿수가 두 단계 다르다**.
KAKAOPAY_FIN = _fin("financial", "CFS", [
    {"year": 2025, "revenue": None, "assets": 5_339_500_000_000,
     "op_income": 50_300_000_000, "net_income": -30_000_000_000, "rcept_no": "20260321000011"},
], corp_nm="카카오페이")


# ── 집계 (SP-MET-5·8) ────────────────────────────────────────────────────────

def test_MET5_total_rows_are_counted_once_not_twice():
    """🚨 이 테스트가 없으면 삼성전자 직원수가 257,762 명으로 나간다(합계행 + 부문행)."""
    emp = assemble(MAP_ROWS, SAMSUNG_2025)
    assert emp[1][2025]["head"] == TOTAL_HEAD
    assert emp[1][2025]["head"] != 257_762, "합계행과 부문행을 함께 더했다"


def test_MET8_average_is_weighted_by_headcount_not_a_simple_mean():
    """단순평균 14,850만원 vs 인원 가중 15,706만원 — 5.8% 차다(58개사가 이만큼 틀어진다)."""
    emp = assemble(MAP_ROWS, SAMSUNG_2025)
    assert emp[1][2025]["salary"] == WEIGHTED_SALARY
    assert emp[1][2025]["salary"] != SIMPLE_SALARY
    # 근속도 같은 가중이다: (90,214×14.5 + 38,667×11.83) / 128,881 = 13.70년(SP-MET-1 검증값)
    assert emp[1][2025]["tenure"] == 13.7

    view = company_metrics(SAMSUNG_FIN, emp[1])
    salary_card = view["cards"][0]
    assert salary_card["latest"] == 15_706, "만원 단위 표시값이 SP-MET-1 검증값과 달라졌다"
    assert salary_card["latest"] != 14_850
    assert [c["latest"] for c in view["cards"][1:3]] == [13.7, TOTAL_HEAD]


def test_MET5_without_a_total_row_every_segment_is_counted():
    """합계행이 없는 회사(93/100)는 부문행 전부를 센다 — 합계행 규칙이 부문행을 삼키지 않는다."""
    segments = [r for r in SAMSUNG_2025 if not r["total_row"]]
    emp = assemble(MAP_ROWS, segments)
    assert emp[1][2025]["head"] == TOTAL_HEAD
    expected = round((60_000 * 100_000_000 + 25_000 * 90_000_000
                      + 30_214 * 200_000_000 + 13_667 * 80_000_000) / TOTAL_HEAD)
    assert emp[1][2025]["salary"] == expected


def test_MET8_missing_values_stay_none_and_are_never_zero():
    """급여가 없는 해도 인원·근속은 살아 있다. 없는 값은 **0 이 아니라 None** 이다."""
    rows = [_row(SAMSUNG, 2020, True, 100_000, "12.00", None),
            _row(SAMSUNG, 2020, True, 20_000, None, None)]
    emp = assemble(MAP_ROWS, rows)
    assert emp[1][2020] == {"salary": None, "tenure": 12.0, "head": 120_000}


def test_MET8_a_row_without_headcount_cannot_be_weighted_and_is_left_out():
    """인원을 모르는 행은 가중할 수 없다 — 단순평균으로 슬쩍 대체하지 않는다(규칙이 갈라진다)."""
    rows = [_row(SAMSUNG, 2019, True, 1_000, "10.00", 50_000_000),
            _row(SAMSUNG, 2019, True, None, "20.00", 200_000_000)]
    emp = assemble(MAP_ROWS, rows)
    assert emp[1][2019] == {"salary": 50_000_000, "tenure": 10.0, "head": 1_000}
    # 단순평균이면 12,500만원·15년이 됐을 것이다 — 인원 없는 행이 평균을 끌고 가지 못한다
    assert emp[1][2019]["salary"] != 125_000_000


def test_MET8_year_with_nothing_countable_is_dropped_but_the_company_stays():
    rows = [_row(SAMSUNG, 2018, True, None, None, None)] + SAMSUNG_2025
    emp = assemble(MAP_ROWS, rows)
    assert sorted(emp[1]) == [2025]
    assert emp[2] == {}, "직원 행이 없는 회사도 키는 남는다(빈 dict)"


def test_MET8_gender_never_leaves_the_module():
    """⚠ 사용자 결정(2026-08-28): 성별은 가중치를 나누는 행 구분일 뿐 화면에 나가지 않는다.

    집계 결과와 카드 뷰모델 어디에도 남녀 흔적이 없어야 한다 — 한 번 실려 나가면 템플릿·툴팁·
    구조화 데이터로 번지고, 그때는 되돌릴 수 없다.
    """
    emp = assemble(MAP_ROWS, SAMSUNG_2025)
    view = company_metrics(SAMSUNG_FIN, emp[1])
    blob = json.dumps([emp, view], ensure_ascii=False)
    for token in ("sex", "sexdstn", "성별", "남", "여", "segment", "SEGMENT"):
        assert token not in blob, f"성별·부문이 뷰모델 밖으로 새어 나갔다: {token}"
    assert set(emp[1][2025]) == {"salary", "tenure", "head"}


def test_MET8_siblings_sharing_one_corporation_get_equal_but_separate_values():
    """CJ ENM 두 부문은 한 법인이라 같은 수치를 받는다. 다만 **같은 dict 를 나눠 쓰지는 않는다**."""
    rows = [_row(CJ, 2025, False, 3_000, "8.00", 96_000_000)]
    emp = assemble(MAP_ROWS, rows)
    assert emp[98] == emp[99] and emp[98][2025] is not emp[99][2025]


def test_MET8_normalize_restores_int_keys_after_a_json_round_trip():
    """JSON 은 **두 겹 다** 문자열 키로 떨어뜨린다. 연도가 문자열로 남으면 정렬이 사전순이 되고,
    전년 대비가 조용히 사라진다."""
    emp = assemble(MAP_ROWS, SAMSUNG_2025 + SAMSUNG_2024)
    back = normalize(json.loads(json.dumps(emp)))
    assert back == emp
    assert all(isinstance(k, int) for k in back)
    assert all(isinstance(y, int) for k in back for y in back[k])
    view = company_metrics(SAMSUNG_FIN, back[1])
    assert view["years"] == [2024, 2025]


def test_MET8_is_loaded_separates_not_collected_yet_from_no_data():
    assert not is_loaded({}) and not is_loaded(None)
    assert not is_loaded(assemble(MAP_ROWS, [])), "매핑만 있고 수치 0건은 '미적재'다"
    assert is_loaded(assemble(MAP_ROWS, SAMSUNG_2025))


def test_MET8_coverage_counts_missing_instead_of_hiding_it():
    """조용한 결측 금지 — 비었다는 사실은 **세어서** 내보낸다."""
    rows = SAMSUNG_2025 + [_row(SAMSUNG, 2024, True, 88_000, None, None)]
    assert coverage(assemble(MAP_ROWS, rows)) == {
        "companies": 1, "years": 2, "salary": 1, "tenure": 1, "head": 0}
    assert coverage({}) == {"companies": 0, "years": 0, "salary": 0, "tenure": 0, "head": 0}


def test_MET8_context_carries_employ_next_to_finance(fake_bundle, fake_now):
    """`build_context(bundle, employ=…)` — 재무와 같은 방식으로 번들 **옆에** 흐른다(함정 (55))."""
    emp = assemble(MAP_ROWS, SAMSUNG_2025)
    ctx = build_context(fake_bundle, now=fake_now, employ=json.loads(json.dumps(emp)))
    assert ctx.employ[1][2025]["head"] == TOTAL_HEAD  # 키가 int 로 복원됐다
    assert ctx.employ_loaded
    assert not build_context(fake_bundle, now=fake_now).employ_loaded


# ── 카드 6장 (SP-MET-2·10) ───────────────────────────────────────────────────

def test_MET10_six_cards_in_a_fixed_order():
    """회사마다 카드 수가 달라지면 세 회사를 나란히 둔 화면이 매번 다른 모양이 된다."""
    view = company_metrics(SAMSUNG_FIN, assemble(MAP_ROWS, SAMSUNG_2025)[1])
    assert [c["key"] for c in view["cards"]] == [
        "salary", "tenure", "head", "revenue", "op_income", "net_income"]
    assert [c["name"] for c in view["cards"]] == [
        "평균연봉", "평균근속", "직원수", "매출", "영업이익", "순이익"]
    assert [c["unit"] for c in view["cards"]] == ["만원", "년", "명", "조원", "조원", "조원"]
    assert view["basis"] == "연결 기준" and view["financial"] is False
    assert view["corp_nm"] == "삼성전자" and view["rcept_no"] == "20260318000001"
    assert all(len(c["values"]) == len(view["years"]) for c in view["cards"])


def test_MET2_financial_set_carries_total_assets_and_operating_income():
    """🚨 금융의 세 번째 지표는 매출이 아니라 **자산총계**다. 그리고 영업이익은 있다.

    "금융은 순이익만"은 사실이 아니라 계정 ID 누락이었다(SP-MET-2). 이자수익+수수료수익을 더해
    "매출"이라 부르는 것은 우리가 만든 지표이고 DEC-B 위반이다.
    """
    view = company_metrics(IBK_FIN, None)
    assert view["financial"] is True
    assert [c["key"] for c in view["cards"][3:]] == ["assets", "op_income", "net_income"]
    assert [c["name"] for c in view["cards"][3:]] == ["자산총계", "영업이익", "순이익"]
    assert "revenue" not in [c["key"] for c in view["cards"]]
    assets, op = view["cards"][3], view["cards"][4]
    assert (assets["latest"], op["latest"]) == (500.7, 3.7)  # 5,006,926억 · 36,555억
    assert op["empty_text"] is None, "영업이익이 비면 매핑 누락이 되살아난 것이다"


def test_MET10_money_unit_is_one_per_company_and_follows_the_smallest_value():
    """단위는 회사당 하나(SP-MET-10). 최솟값이 기준이라 카카오페이 영업이익 503억이 살아남는다 —
    조원으로 통일하면 그 카드가 `0.1조` 로 뭉개진다."""
    won = company_metrics(KAKAOPAY_FIN, None)
    assert won["money_unit"] == "억원"
    assert [c["latest"] for c in won["cards"][3:]] == [53_395, 503, -300]
    assert {c["unit"] for c in won["cards"][3:]} == {"억원"}, "한 회사 안에서 조와 억을 섞지 않는다"

    jo = company_metrics(IBK_FIN, None)
    assert jo["money_unit"] == "조원", "유효값 최솟값 2.8조 ≥ 1조 → 조원"


def test_MET10_year_over_year_has_four_branches():
    """부호가 뒤집히면 비율이 아니라 사건이다 — "+180%" 는 아무 뜻도 없다(SP-MET-10)."""
    assert year_over_year(10_000_000_000, -5_000_000_000) == ("적자 전환", "down")
    assert year_over_year(-5_000_000_000, 2_000_000_000) == ("흑자 전환", "up")
    assert year_over_year(-10_000_000_000, -16_000_000_000) == ("적자 확대 60.0%", "down")
    assert year_over_year(-10_000_000_000, -5_000_000_000) == ("적자 축소 50.0%", "up")
    assert year_over_year(300_000, 330_000) == ("+10.0%", "up")
    assert year_over_year(330_000, 300_000) == ("-9.1%", "down")
    # 비교할 수 없는 자리는 **빈 문자열**이다 — 0 이나 '—' 를 지어내지 않는다
    assert year_over_year(None, 100) == ("", "") and year_over_year(100, None) == ("", "")
    assert year_over_year(0, 100) == ("", ""), "0 을 분모로 비율을 만들 수 없다"
    assert year_over_year(-100, -100) == ("적자 유지", "")


def test_MET10_delta_compares_the_previous_year_only():
    """'전년'은 말 그대로 직전 연도다. 2019 → 2025 를 "전년 대비"라 적으면 틀린 문장이다."""
    gap = _fin("general", "CFS", [
        {"year": 2019, "revenue": 100_000_000_000, "op_income": None, "net_income": None,
         "assets": None, "rcept_no": "20200330000001"},
        {"year": 2025, "revenue": 200_000_000_000, "op_income": None, "net_income": None,
         "assets": None, "rcept_no": "20260330000001"},
    ])
    view = company_metrics(gap, None)
    revenue = view["cards"][3]
    assert revenue["latest"] == 2_000 and revenue["delta_text"] == ""
    assert view["years"] == [2019, 2025]
    assert revenue["values"] == [1_000, 2_000]


def test_MET10_tenure_delta_survives_the_integer_ratio_rule():
    """근속은 소수라 정수로 떨어뜨리면 13.7 과 13.4 가 **둘 다 13** 이 되어 변화가 사라진다."""
    rows = [_row(SAMSUNG, 2024, True, 100, "13.40", None), _row(SAMSUNG, 2025, True, 100, "13.70", None)]
    view = company_metrics(None, assemble(MAP_ROWS, rows)[1], corp_nm="삼성전자")
    assert view["cards"][1]["delta_text"] == "+2.2%" and view["cards"][1]["delta_dir"] == "up"
    assert view["basis"] == "", "직원 현황에는 연결/별도 기준이 없다"
    assert view["rcept_no"] is None


def test_MET10_gaps_stay_none_so_the_chart_can_break_the_line():
    """결측을 0 으로 채우면 "그해 매출이 0" 이라고 말하는 것이 된다(SP-MET-9)."""
    emp = assemble(MAP_ROWS, SAMSUNG_2025)  # 직원은 2025 만
    view = company_metrics(SAMSUNG_FIN, emp[1])  # 재무는 2024·2025
    assert view["years"] == [2024, 2025]
    assert view["cards"][0]["values"] == [None, 15_706]
    assert view["cards"][2]["values"] == [None, TOTAL_HEAD]
    assert view["cards"][3]["values"] == [300.0, 333.6]
    assert view["cards"][3]["delta_text"] == "+11.2%"


def test_MET10_an_empty_card_says_so_instead_of_disappearing():
    """없는 값은 비우고 **그렇게 말한다**(SP-MET-10). 카드가 사라지면 무엇이 없는지도 사라진다."""
    view = company_metrics(SAMSUNG_FIN, None)
    for card in view["cards"][:3]:
        assert card["values"] == [None, None] and card["latest"] is None
        assert card["delta_text"] == "" and card["delta_dir"] == ""
    assert [c["empty_text"] for c in view["cards"][:3]] == [
        "평균연봉 공시 값이 없습니다", "평균근속 공시 값이 없습니다", "직원수 공시 값이 없습니다"]
    assert all(c["empty_text"] is None for c in view["cards"][3:])


@pytest.mark.parametrize("fin,emp", [(None, None), (None, {}), ({}, {}),
                                     (_fin("general", "CFS", []), {})])
def test_MET10_no_numbers_means_no_section(fin, emp):
    assert company_metrics(fin, emp) is None


def test_MET10_receipt_number_is_not_exported_unless_it_is_a_number():
    """접수번호는 링크 재료다. 숫자가 아니면 내보내지 않는다(URL 주입 경로를 템플릿에 맡기지 않는다)."""
    fin = _fin("general", "CFS", [
        {"year": 2025, "revenue": 1_000_000_000_000, "op_income": None, "net_income": None,
         "assets": None, "rcept_no": '"><script>alert(1)</script>'},
    ])
    assert company_metrics(fin, None)["rcept_no"] is None


# ── 로더 배선 ────────────────────────────────────────────────────────────────

class _FakeCursor:
    """`load_employ` 가 쓰는 것만 흉내낸다(execute·fetchall·async with). 실 DB 경로가 아니라
    **쿼리 두 벌이 순서대로 나가고 그 결과가 집계로 들어가는지**만 본다."""

    def __init__(self, results):
        self._results, self.sql = list(results), []

    async def __aenter__(self):
        return self

    async def __aexit__(self, *exc):
        return False

    async def execute(self, sql):
        self.sql.append(sql)

    async def fetchall(self):
        return self._results.pop(0)


class _FakeConn:
    def __init__(self, results):
        self.cur = _FakeCursor(results)

    def cursor(self):
        return self.cur


def test_MET8_load_employ_runs_the_mapping_query_first_then_aggregates():
    import asyncio

    conn = _FakeConn([MAP_ROWS, SAMSUNG_2025])
    got = asyncio.run(employ_module.load_employ(conn))
    assert got == assemble(MAP_ROWS, SAMSUNG_2025)
    assert conn.cur.sql == [employ_module._SQL_MAP, employ_module._SQL_EMP]


def test_MET8_the_select_aliases_are_exactly_what_the_aggregator_reads():
    """🚨 별칭 하나를 고치고 읽는 쪽을 안 고치면 **에러 없이** 그 값이 통째로 빈다 — 이 저장소가
    반복해서 밟은 함정이다(화이트리스트가 필드를 조용히 떨구는 것과 같은 종류)."""
    assert set(re.findall(r"AS (\w+)", employ_module._SQL_MAP)) == {"comp_id", "corp_code"}
    assert set(re.findall(r"AS (\w+)", employ_module._SQL_EMP)) == {
        "corp_code", "year", "total_row", "head", "tenure", "salary"}
    # 원문 컬럼(성별·부문·RAW_*)은 애초에 읽지 않는다 — 읽지 않는 것이 새어 나가지 않는 가장 확실한 길
    for column in ("SEX_CD", "SEGMENT_NM", "RAW_SALARY_NM", "RAW_TENURE_NM"):
        assert column not in employ_module._SQL_EMP


# ── 금액 자릿수: 부호를 잃지 않는다 (2026-08-28 실데이터 검토) ────────────────

def test_MET10_a_small_loss_keeps_its_sign_instead_of_rounding_to_zero():
    """리메드 2025 순이익 **−35,468,721원**. 억원 정수로 자르면 `0` 이 되는데 0 에는 부호가 없다.

    그 결과가 화면에서 무엇이 되는지가 핵심이다: 카드는 `0억원`, 막대는 `v >= 0` 이라 기준선
    **위에 초록으로** 그려진다 — 적자가 흑자로 보인다. 숫자를 잃는 것보다 나쁜 것은 부호를 잃는 것이다.
    """
    fin = {"acct_set": "general", "fs_div": "CFS", "years": [
        {"year": 2024, "revenue": 30_000_000_000, "op_income": 1_200_000_000, "net_income": 900_000_000},
        {"year": 2025, "revenue": 28_000_000_000, "op_income": -400_000_000, "net_income": -35_468_721},
    ]}
    view = company_metrics(fin, None, "리메드")
    assert view["money_unit"] == "억원"
    net = next(c for c in view["cards"] if c["key"] == "net_income")
    assert net["decimals"] == 1, "최솟값이 1억 미만이면 소수 1자리라야 부호가 산다"
    assert net["latest"] == -0.4 and net["latest"] < 0
    assert net["values"][-1] < 0, "그래프도 같은 값을 받아야 막대가 기준선 아래로 간다"


def test_MET10_decimals_are_one_per_company_and_travel_on_the_card():
    """자릿수는 단위처럼 **회사당 하나**이고 카드가 들고 다닌다 — 단위 문자열에서 되짚을 수 없다."""
    big = {"acct_set": "general", "fs_div": "CFS", "years": [
        {"year": 2025, "revenue": 330_000_000_000_000, "op_income": 40_000_000_000_000,
         "net_income": 35_000_000_000_000}]}
    v = company_metrics(big, None, "삼성전자")
    assert v["money_unit"] == "조원"
    money = [c for c in v["cards"] if c["key"] in ("revenue", "op_income", "net_income")]
    assert {c["decimals"] for c in money} == {1}, "조원은 소수 1자리(5.6조를 6조로 자르면 추이가 죽는다)"
    assert next(c for c in v["cards"] if c["key"] == "salary")["decimals"] == 0
    assert next(c for c in v["cards"] if c["key"] == "tenure")["decimals"] == 1


def test_MET10_plain_eok_stays_an_integer():
    """1억 이상만 있는 회사는 억원 정수 그대로다 — 필요 없는 소수를 붙이지 않는다."""
    fin = {"acct_set": "general", "fs_div": "CFS", "years": [
        {"year": 2025, "revenue": 500_000_000_000, "op_income": 30_000_000_000,
         "net_income": 20_000_000_000}]}
    v = company_metrics(fin, None, "보통회사")
    assert v["money_unit"] == "억원"
    assert {c["decimals"] for c in v["cards"] if c["key"] == "revenue"} == {0}
