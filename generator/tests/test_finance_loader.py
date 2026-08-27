"""생성기 재무 로더 순수 조립 계약 — `generator/finance.py::assemble` (SP-FIN-4, T-15.2.1).

실 DB 경로(aiomysql)는 `server/tests/test_corp_load.py::test_FN4_*` 가 본다. 여기서는 행 → 뷰
조립 규칙만 본다: 표시 기준 1벌, 연도 오름차순, 형제 페이지, DECIMAL→int, JSON 키 복원.
"""
from __future__ import annotations

import json
from decimal import Decimal

from generator.finance import ACCT_NET_INCOME, ACCT_OP_INCOME, ACCT_REVENUE, assemble, is_loaded
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
