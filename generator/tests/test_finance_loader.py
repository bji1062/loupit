"""생성기 재무 로더 순수 조립 계약 — `generator/finance.py::assemble` (SP-FIN-4, T-15.2.1).

실 DB 경로(aiomysql)는 `server/tests/test_corp_load.py::test_FN4_*` 가 본다. 여기서는 행 → 뷰
조립 규칙만 본다: 표시 기준 1벌, 연도 오름차순, 형제 페이지, DECIMAL→int, JSON 키 복원.

2026-08-28(SP-MET-2)로 늘어난 계약도 여기서 본다: **자산총계**가 실리고, 금융 세트의 세 번째
표시 지표가 매출이 아니라 자산총계이며, "금융은 순이익만"이라는 전제가 사라졌다는 것.
"""
from __future__ import annotations

import json
from decimal import Decimal

from generator.finance import (
    ACCT_ASSETS,
    ACCT_NET_INCOME,
    ACCT_OP_INCOME,
    ACCT_REVENUE,
    assemble,
    company_view,
    index_row,
    is_loaded,
    metric_columns,
)
from generator.bundle import load_finance_json

MAP_ROWS = [
    {"comp_id": 98, "corp_code": "00265324", "corp_nm": "씨제이이엔엠", "stock_cd": "035760", "acct_set": "general", "fs_div": "CFS"},
    {"comp_id": 99, "corp_code": "00265324", "corp_nm": "씨제이이엔엠", "stock_cd": "035760", "acct_set": "general", "fs_div": "CFS"},
    {"comp_id": 38, "corp_code": "00126256", "corp_nm": "삼성생명", "stock_cd": "032830", "acct_set": "financial", "fs_div": "CFS"},
    {"comp_id": 6, "corp_code": "00120021", "corp_nm": "엘지", "stock_cd": "003550", "acct_set": "general", "fs_div": "OFS"},
]
FIN_ROWS = [
    {"corp_code": "00265324", "year": 2025, "fs_div": "CFS", "acct_id": ACCT_REVENUE, "amt": Decimal("4795000000000"), "rcept_no": "20260319000009"},
    {"corp_code": "00265324", "year": 2025, "fs_div": "CFS", "acct_id": ACCT_NET_INCOME, "amt": Decimal("-50000000000"), "rcept_no": "20260319000009"},
    {"corp_code": "00265324", "year": 2024, "fs_div": "CFS", "acct_id": ACCT_REVENUE, "amt": Decimal("4500000000000"), "rcept_no": "20250320000008"},
    {"corp_code": "00265324", "year": 2025, "fs_div": "OFS", "acct_id": ACCT_REVENUE, "amt": Decimal("1000000000000"), "rcept_no": "20260319000009"},
    {"corp_code": "00120021", "year": 2025, "fs_div": "CFS", "acct_id": ACCT_OP_INCOME, "amt": Decimal("912200000000"), "rcept_no": "20260317000005"},
    {"corp_code": "00120021", "year": 2025, "fs_div": "OFS", "acct_id": ACCT_OP_INCOME, "amt": Decimal("597100000000"), "rcept_no": "20260317000005"},
    {"corp_code": "00126256", "year": 2025, "fs_div": "CFS", "acct_id": ACCT_REVENUE, "amt": None, "rcept_no": "20260325000004"},
    {"corp_code": "00126256", "year": 2025, "fs_div": "CFS", "acct_id": ACCT_NET_INCOME, "amt": Decimal("2451500000000"), "rcept_no": "20260325000004"},
    # 금융 세트(삼성생명)는 매출이 NULL 이어도 **영업이익·자산총계**가 있다 — SP-MET-2 실측 구조.
    {"corp_code": "00126256", "year": 2025, "fs_div": "CFS", "acct_id": ACCT_OP_INCOME, "amt": Decimal("2580400000000"), "rcept_no": "20260325000004"},
    {"corp_code": "00126256", "year": 2025, "fs_div": "CFS", "acct_id": ACCT_ASSETS, "amt": Decimal("350685700000000"), "rcept_no": "20260325000004"},
]


def test_assemble_groups_by_company_with_siblings_sharing_one_corporation():
    fin = assemble(MAP_ROWS, FIN_ROWS)
    assert set(fin) == {98, 99, 38, 6}
    assert fin[98]["years"] == fin[99]["years"]
    assert fin[98]["siblings"] == [99] and fin[99]["siblings"] == [98]
    assert fin[38]["siblings"] == []
    assert fin[98]["corp_nm"] == "씨제이이엔엠" and fin[98]["stock_cd"] == "035760"


def test_assemble_keeps_only_display_basis_and_orders_years_ascending():
    fin = assemble(MAP_ROWS, FIN_ROWS)
    years = fin[98]["years"]
    assert [y["year"] for y in years] == [2024, 2025]
    assert years[1]["revenue"] == 4_795_000_000_000  # CFS 만 — OFS 1조 는 섞이지 않는다
    assert years[1]["net_income"] == -50_000_000_000
    assert years[1]["op_income"] is None
    assert years[0]["rcept_no"] == "20250320000008"
    # LG 는 표시 기준이 OFS 라 별도 수치가 실린다
    assert fin[6]["fs_div"] == "OFS"
    assert fin[6]["years"][0]["op_income"] == 597_100_000_000


def test_assemble_converts_decimal_to_int_and_keeps_null():
    fin = assemble(MAP_ROWS, FIN_ROWS)
    y = fin[38]["years"][0]
    assert y["revenue"] is None and isinstance(y["net_income"], int)
    json.dumps(fin)  # --finance-json 덤프 가능


def test_assemble_mapped_company_without_rows_has_empty_years():
    fin = assemble(MAP_ROWS, [])
    assert fin[38] == {"corp_nm": "삼성생명", "stock_cd": "032830", "acct_set": "financial", "fs_div": "CFS", "years": [], "siblings": []}
    assert not is_loaded(fin)
    assert is_loaded(assemble(MAP_ROWS, FIN_ROWS))
    assert not is_loaded({}) and not is_loaded(None)


def test_load_finance_json_restores_int_keys(tmp_path):
    fin = assemble(MAP_ROWS, FIN_ROWS)
    p = tmp_path / "finance.json"
    p.write_text(json.dumps(fin, ensure_ascii=False), encoding="utf-8")
    back = load_finance_json(str(p))
    assert back == fin
    assert all(isinstance(k, int) for k in back)


# ── SP-MET-2: 금융 세트의 세 번째 지표는 자산총계다 ──────────────────────────

def test_assemble_carries_total_assets_alongside_the_income_statement():
    """자산총계는 BS 행이라 손익만 훑으면 통째로 빈다(함정 (68)의 다음 판). 계정 ID 로만 잡는다."""
    fin = assemble(MAP_ROWS, FIN_ROWS)
    y = fin[38]["years"][0]
    assert y["assets"] == 350_685_700_000_000 and y["op_income"] == 2_580_400_000_000
    assert y["revenue"] is None, "금융업은 매출 계정이 없다 — 0 이 아니라 없음이다"
    # 일반 회사에 자산총계가 없는 것은 그 회사가 안 낸 것이 아니라 이 픽스처가 안 넣은 것이다.
    # 슬롯은 언제나 네 칸이어야 소비처가 키 존재 여부로 갈라지지 않는다.
    assert set(fin[98]["years"][0]) == {"year", "revenue", "assets", "op_income", "net_income", "rcept_no"}


def test_metric_columns_swaps_revenue_for_total_assets_only_in_the_financial_set():
    """🚨 이자수익+수수료수익을 더해 "매출"이라 부르는 것은 우리가 만든 지표다(DEC-B 위반).
    금융의 세 번째 자리는 공시 원문 그대로의 자산총계이고, 그 판단은 이 함수 하나가 내린다."""
    assert metric_columns("general") == (("revenue", "매출"), ("op_income", "영업이익"), ("net_income", "순이익"))
    assert metric_columns("financial") == (("assets", "자산총계"), ("op_income", "영업이익"), ("net_income", "순이익"))
    # 모르는 세트 코드·None 은 일반으로 본다 — 떨어뜨리면 그 회사만 열이 통째로 비고 에러도 없다
    assert metric_columns(None) == metric_columns("general") == metric_columns("mystery")


def test_company_view_tells_the_template_which_three_metrics_to_show():
    """표는 `columns` 를 보고 열을 만든다. '금융은 순이익만'은 사실이 아니라 계정 ID 누락이었다 —
    영업이익은 금융 7/7 로 들어오므로 열은 세트와 무관하게 3종이다(SP-MET-2)."""
    fin = assemble(MAP_ROWS, FIN_ROWS)
    view = company_view(fin[38], "삼성생명", [])
    assert view["financial"] is True
    assert [c["key"] for c in view["columns"]] == ["assets", "op_income", "net_income"]
    assert [c["name"] for c in view["columns"]] == ["자산총계", "영업이익", "순이익"]
    row = view["rows"][0]
    assert row["assets"] == "3,506,857" and row["op_income"] == "25,804"  # 억원
    assert row["revenue"] == "—", "없는 계정은 '—' 지 0 이 아니다"
    assert [c["key"] for c in company_view(fin[98], "CJ ENM", [])["columns"]] == [
        "revenue", "op_income", "net_income"]


def test_index_row_carries_all_four_accounts_so_the_index_can_pick():
    fin = assemble(MAP_ROWS, FIN_ROWS)
    assert index_row(fin[38]) == {"year": "2025", "revenue": "—", "assets": "3,506,857",
                                  "op_income": "25,804", "net_income": "24,515", "basis": "연결"}
    assert index_row(None) == {"year": "—", "revenue": "—", "assets": "—", "op_income": "—",
                               "net_income": "—", "basis": "—"}


def test_row_delta_compares_the_previous_year_not_the_previous_row():
    """'전년 대비'는 직전 **행**이 아니라 직전 **연도**다.

    연도가 통째로 빠진 회사가 실제로 있다 — LIG디펜스앤에어로스페이스는 연결 기준 2018 이 없다
    (2026-08-28 실측). 행 기준으로 비교하면 2017 → 2019 의 2년치 변화를 "전년 대비"라고 적게 되고,
    바로 아래 카드(`employ._card`)는 같은 자리를 비우므로 **한 페이지가 두 말을 한다**.
    """
    from generator.finance import company_view

    fin = {"corp_nm": "구멍회사", "acct_set": "general", "fs_div": "CFS", "siblings": [], "years": [
        {"year": 2017, "revenue": 100_000_000_000, "op_income": None, "net_income": None, "rcept_no": "1"},
        {"year": 2019, "revenue": 200_000_000_000, "op_income": None, "net_income": None, "rcept_no": "2"},
        {"year": 2020, "revenue": 220_000_000_000, "op_income": None, "net_income": None, "rcept_no": "3"},
    ]}
    rows = {r["year"]: r for r in company_view(fin, "구멍회사", [])["rows"]}
    assert rows[2019]["revenue_delta"] == "—", "2018 이 없으므로 2019 에는 전년이 없다"
    assert rows[2020]["revenue_delta"] == "+10.0%", "연속된 해는 그대로 비교한다"
    assert rows[2017]["revenue_delta"] == "—"
