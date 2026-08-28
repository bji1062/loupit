"""DART 재무 수집기 계약 — FN-2·FN-3 (SP-FIN-3) · SP-MET-2·3·11 (T-15.1.2~15.1.4).

근거: `docs/SPEC/15-회사정보-재무.md` SP-FIN-3 · `docs/SPEC/17-회사정보-지표.md` SP-MET-2·3·11
(2026-08-28 DART 전수 실측) · `PLAN-회사정보-확장-2026-08-21.md` §5-2 · 함정 (68).

**이 테스트가 지키는 것은 "조용히 비는 실패"를 막는 다섯 가지 결정이다.**

  1. **지표는 `account_id` 로만 찾는다.** SK하이닉스는 손익을 `IS` 가 아니라 `CIS` 에 싣는다 —
     `sj_div` 로 거르면 에러 없이 그 회사 영업이익만 빈다(함정 (68)). 자산총계는 아예 `BS` 행이라
     이 규약이 없으면 통째로 빈다.
  2. **없는 계정은 NULL 이지 0 이 아니다.** 금융업은 `ifrs-full_Revenue` 가 정말로 없다.
     0 으로 넣으면 "매출 0원"이라는 거짓 수치가 화면에 나간다.
  3. **키가 없으면 즉시 실패하고, 키는 어디에도 찍히지 않는다.** 조용한 0건은 "수집했는데
     없더라"로 읽힌다(함정 (57)).
  4. **한 지표에 계정이 여럿이다(SP-MET-3).** 2019년 접두사 전환(`ifrs_` → `ifrs-full_`) 탓에
     신형만 등록하면 2018년 이전 매출·순이익이 조용히 빈다. 이 테스트가 그 연도를 지킨다.
  5. **두 계정이 다른 값이면 고르지 않고 실패로 찍는다(SP-MET-2).** 조용히 하나를 고르면 회사마다
     다른 정의가 같은 그래프에 섞인다. 그리고 금융의 필수는 이제 **영업이익·순이익·자산총계 3종**
     이다 — 지금까지 영업이익이 비었던 건 사실이 아니라 계정 ID 누락이었다.

HTTP 는 `fetch_fn(url)->dict` 주입으로 끊는다 — 픽스처 4사(삼성전자·SK하이닉스·삼성생명·LG)
는 `server/tests/fixtures/dart/*.json`. 무DB 계약은 기록용 fake 커서로, UNIQUE 멱등·결측
검사는 `clean_tx`(롤백 격리)로 실제 DDL 위에서 본다.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path
from urllib.parse import parse_qs, urlparse

import pytest

ROOT = Path(__file__).resolve().parents[2]
SEED_DIR = ROOT / "db" / "seed"
if str(SEED_DIR) not in sys.path:
    sys.path.insert(0, str(SEED_DIR))

import dart_finance as df  # noqa: E402  # db/seed/dart_finance.py

FIXTURES = Path(__file__).parent / "fixtures" / "dart"
NO_DATA = {"status": "013", "message": "조회된 데이타가 없습니다."}
# 절대 출력되면 안 되는 표식 — 예외 메시지·URL 로그 어디에도 이 문자열이 나오면 실패.
KEY = "test-key-DO-NOT-PRINT-0123456789abcdef"

SAMSUNG = {"corp_code": "00126380", "corp_nm": "삼성전자", "acct_set": "general"}
SKHYNIX = {"corp_code": "00164779", "corp_nm": "SK하이닉스", "acct_set": "general"}
SAMSUNG_LIFE = {"corp_code": "00126256", "corp_nm": "삼성생명", "acct_set": "financial"}
LG = {"corp_code": "00120021", "corp_nm": "LG", "acct_set": "general"}


def _fixture(name: str) -> dict:
    return json.loads((FIXTURES / f"{name}.json").read_text(encoding="utf-8"))


def _without(payload: dict, acct_id: str) -> dict:
    """픽스처에서 특정 계정만 뺀 변형(결측 재현용)."""
    return {**payload, "list": [r for r in payload["list"] if r["account_id"] != acct_id]}


def _with_row(payload: dict, row: dict) -> dict:
    """픽스처에 계정 행 하나를 더한 변형. 캡처본에 없는 계정을 재현할 때만 쓴다."""
    return {**payload, "list": [*payload["list"], {**row, "rcept_no": payload["list"][0]["rcept_no"]}]}


# ── 합성 응답 (SP-MET-2·3) ───────────────────────────────────────────────────
# 파일 픽스처 4사는 **실캡처**지만, 아래 셋은 **합성**이다 — 캡처본에는 2019년 이전 연도도, 영업이익
# 두 계정이 함께 온 보고서도 없기 때문이다. 파서가 보는 필드만 담는다(모르는 필드를 지어내지 않는다).
# 금액은 SPEC 17 에 적힌 실측값을 그대로 쓰고, 그 문서에 없는 항목만 형태용 값이다:
#   삼성전자 2017 매출 239.6조 · 2018 영업이익 58.9조 / 기업은행 2025 자산 5,006,926억 · 영업이익 36,555억.

def _row(acct_id: str, amount: str, *, sj_div: str = "IS", acct_nm: str = "계정", rcept_no: str = "20180402000001") -> dict:
    return {"rcept_no": rcept_no, "sj_div": sj_div, "account_id": acct_id, "account_nm": acct_nm,
            "thstrm_amount": amount}


def _payload(rows: list[dict]) -> dict:
    return {"status": "000", "message": "정상", "list": rows}


# 🚨 구접두사 — 2018년 이하는 `ifrs_Revenue`·`ifrs_ProfitLoss` 로 온다. 접두사가 안 바뀐
# `dart_OperatingIncomeLoss` 만 잡히면 "그 시절엔 영업이익만 냈나" 로 읽힌다(SP-MET-3).
SAMSUNG_2017 = _payload([
    _row("ifrs-full_Assets", "301,752,090,000,000", sj_div="BS", acct_nm="자산총계"),
    _row("ifrs_Revenue", "239,575,376,000,000", acct_nm="수익(매출액)"),          # 실측 239.6조
    _row("dart_OperatingIncomeLoss", "53,645,038,000,000", acct_nm="영업이익"),
    _row("ifrs_ProfitLoss", "42,186,747,000,000", acct_nm="당기순이익"),
])
SAMSUNG_2018 = _payload([
    _row("ifrs_Revenue", "243,771,415,000,000", acct_nm="수익(매출액)", rcept_no="20190401000002"),
    _row("dart_OperatingIncomeLoss", "58,886,669,000,000", acct_nm="영업이익", rcept_no="20190401000002"),  # 실측 58.9조
    _row("ifrs_ProfitLoss", "44,344,857,000,000", acct_nm="당기순이익", rcept_no="20190401000002"),
])
# 🚨 금융 세트 — 매출 계정은 없고, 영업이익·순이익·자산총계 3종이 있다(SP-MET-2, 7/7 실측).
IBK_2025 = _payload([
    _row("ifrs-full_Assets", "500,692,600,000,000", sj_div="BS", acct_nm="자산총계", rcept_no="20260318000010"),   # 5,006,926억
    _row("dart_OperatingIncomeLoss", "3,655,500,000,000", acct_nm="영업이익", rcept_no="20260318000010"),          # 36,555억
    _row("ifrs-full_ProfitLoss", "2,800,000,000,000", acct_nm="당기순이익", rcept_no="20260318000010"),
])
# 영업이익을 대안 계정으로만 내는 회사(별칭 2순위가 물어야 한다).
FIN_ALT_OP = _payload([
    _row("ifrs-full_Assets", "5,339,500,000,000", sj_div="BS", acct_nm="자산총계", rcept_no="20260318000011"),
    _row("ifrs-full_ProfitLossFromOperatingActivities", "50,300,000,000", acct_nm="영업이익", rcept_no="20260318000011"),
    _row("ifrs-full_ProfitLoss", "40,000,000,000", acct_nm="당기순이익", rcept_no="20260318000011"),
])
_OP_ALT = "ifrs-full_ProfitLossFromOperatingActivities"


class Router:
    """`(corp_code, year, fs_div)` → 응답. 라우트 밖은 013(조회 데이터 없음). 호출 URL 을 기록한다."""

    def __init__(self, routes: dict):
        self.routes = routes
        self.urls: list[str] = []

    def __call__(self, url: str) -> dict:
        self.urls.append(url)
        q = parse_qs(urlparse(url).query)
        key = (q["corp_code"][0], int(q["bsns_year"][0]), q["fs_div"][0])
        return self.routes.get(key, NO_DATA)


ROUTES = {
    ("00126380", 2025, "CFS"): _fixture("samsung_2025_cfs"),
    ("00126380", 2024, "CFS"): _fixture("samsung_2024_cfs"),
    ("00164779", 2025, "CFS"): _fixture("skhynix_2025_cfs"),
    ("00126256", 2025, "CFS"): _fixture("samsung_life_2025_cfs"),
    ("00120021", 2025, "CFS"): _fixture("lg_2025_cfs"),
    ("00120021", 2025, "OFS"): _fixture("lg_2025_ofs"),
}


class RecordingCursor:
    """무DB 계약용 — 실행된 (sql, params) 만 쌓는다."""

    def __init__(self):
        self.calls: list[tuple[str, tuple]] = []

    def execute(self, sql, params=()):
        self.calls.append((sql, tuple(params)))
        return 1

    def fetchall(self):
        return []

    def fetchone(self):
        return None


def _upsert_rows(cur: RecordingCursor) -> list[tuple]:
    return [p for sql, p in cur.calls if "INSERT INTO TCORP_FINANCE" in sql]


# ── 금액 파싱 ────────────────────────────────────────────────────────────────

@pytest.mark.parametrize("raw, expected", [
    ("47,206,300,000,000", 47_206_300_000_000),
    ("-1,234", -1234),
    ("0", 0),
    ("", None),
    ("-", None),
    (None, None),
    (" 12 ", 12),
])
def test_parse_amount_handles_dart_string_forms(raw, expected):
    """`thstrm_amount` 는 문자열이다 — 쉼표·음수·빈 문자열·'-' 가 섞여 온다."""
    assert df.parse_amount(raw) == expected


def test_parse_amount_rejects_garbage_loudly():
    with pytest.raises(ValueError):
        df.parse_amount("abc")


# ── 응답 해석: account_id 로만 ──────────────────────────────────────────────

def test_FN2_sk_hynix_operating_income_found_via_cis():
    """🚨 SK하이닉스는 손익이 `CIS` 에 있다 — `account_id` 로 찾으면 잡히고 `sj_div=='IS'` 면 빈다."""
    payload = _fixture("skhynix_2025_cfs")
    # 자기검증: 픽스처에 IS 행이 하나도 없어야 이 테스트가 함정을 실제로 재현한다
    assert not [r for r in payload["list"] if r["sj_div"] == "IS"], "픽스처가 함정 (68) 을 재현하지 않는다"
    found = df.extract_accounts(payload)
    assert found[df.ACCT_OP_INCOME]["amt"] == 47_206_300_000_000
    assert found[df.ACCT_OP_INCOME]["rcept_no"] == "20260320000003"


def test_FN2_samsung_life_has_no_revenue_account():
    """금융업은 **매출 계정이 없다** — 결과에 키 자체가 없어야 한다(0 으로 지어내지 않는다).

    자산총계는 `BS` 행이라 손익표만 훑으면 통째로 빈다 — 그것까지 여기서 못 박는다(SP-MET-2).
    ⓘ 이 캡처본에 영업이익이 없는 것은 SP-MET-2 이전에 3계정만 요청해 뜬 것이라, "금융엔 영업이익이
      없다"의 근거가 아니다. 실제로는 7/7 로 있다 — 아래 `test_MET2_*` 가 그 쪽을 지킨다.
    """
    found = df.extract_accounts(_fixture("samsung_life_2025_cfs"))
    assert df.ACCT_REVENUE not in found
    assert found[df.ACCT_NET_INCOME]["amt"] == 2_451_500_000_000
    assert found[df.ACCT_ASSETS]["amt"] == 330_000_000_000_000


def test_extract_returns_none_for_013_no_data():
    assert df.extract_accounts(NO_DATA) is None


def test_extract_raises_on_other_error_status():
    with pytest.raises(df.DartError):
        df.extract_accounts({"status": "020", "message": "요청 제한을 초과하였습니다."})


def test_extract_ignores_noise_accounts_and_blank_amounts():
    """표준계정 밖 행·빈 금액 행은 조용히 무시한다 — 3지표만 돌아온다."""
    found = df.extract_accounts(_fixture("samsung_2025_cfs"))
    assert set(found) == set(df.ACCT_IDS)


# ── 계정 별칭: 구접두사·대안 계정 (SP-MET-3·SP-MET-2) ───────────────────────

def test_MET3_old_prefix_revenue_and_net_income_are_found():
    """🚨 2018년 이하는 `ifrs_Revenue`·`ifrs_ProfitLoss` 로 온다 — 신형만 등록하면 조용히 빈다.

    별칭이 없으면 영업이익(접두사 불변)만 남아 "2018년 이전엔 매출이 없던 회사"가 된다. 에러가
    나지 않으므로 아무도 모른다 — 그래서 여기서 못 박는다."""
    # 자기검증: 픽스처가 실제로 구접두사여야 이 테스트가 함정을 재현한다
    assert not [r for r in SAMSUNG_2017["list"] if r["account_id"] == "ifrs-full_Revenue"]
    found = df.extract_accounts(SAMSUNG_2017)
    assert found[df.ACCT_REVENUE]["amt"] == 239_575_376_000_000       # SPEC 17 실측 239.6조
    assert round(found[df.ACCT_REVENUE]["amt"] / 1_000_000_000_000, 1) == 239.6
    assert found[df.ACCT_NET_INCOME]["amt"] == 42_186_747_000_000
    assert found[df.ACCT_OP_INCOME]["amt"] == 53_645_038_000_000
    # 어느 계정으로 잡았는지는 남는다 — 대표 ID 로 저장하므로 이 값이 유일한 단서다
    assert found[df.ACCT_REVENUE]["acct_id"] == "ifrs_Revenue"
    assert found[df.ACCT_OP_INCOME]["acct_id"] == df.ACCT_OP_INCOME


def test_MET3_2018_operating_income_is_the_measured_value():
    """SPEC 17 실측: 삼성전자 2018 영업이익 58.9조. 구접두사 연도에도 세 지표가 다 잡혀야 한다."""
    found = df.extract_accounts(SAMSUNG_2018)
    assert found[df.ACCT_OP_INCOME]["amt"] == 58_886_669_000_000
    assert round(found[df.ACCT_OP_INCOME]["amt"] / 1_000_000_000_000, 1) == 58.9
    assert found[df.ACCT_REVENUE]["amt"] == 243_771_415_000_000
    assert found[df.ACCT_NET_INCOME]["amt"] == 44_344_857_000_000


def test_MET3_old_prefix_rows_are_stored_under_the_canonical_acct_id():
    """저장은 **대표 계정 ID 하나로** — `ifrs_Revenue` 를 원문대로 넣으면 지표가 두 행으로 갈라져,
    한쪽만 아는 소비처에서 2018년 이전이 다시 조용히 빈다. 별칭으로 잡은 횟수는 세어 보고한다."""
    router = Router({("00126380", 2017, "CFS"): SAMSUNG_2017})
    cur = RecordingCursor()
    stats = df.collect(cur, [SAMSUNG], api_key=KEY, base_year=2017, years=1, fetch_fn=router, sleep_sec=0)
    by_acct = {r[3]: r for r in _upsert_rows(cur)}
    assert set(by_acct) == set(df.ACCT_IDS), "구접두사 ID 가 그대로 저장되면 소비처가 못 찾는다"
    assert by_acct[df.ACCT_REVENUE][5] == 239_575_376_000_000
    assert by_acct[df.ACCT_NET_INCOME][5] == 42_186_747_000_000
    assert by_acct[df.ACCT_REVENUE][4] == "수익(매출액)"  # 회사 표기 계정명은 원문 그대로 남긴다
    assert stats["legacy"] == {"ifrs_Revenue": 1, "ifrs_ProfitLoss": 1}


def test_MET2_financial_set_yields_op_income_net_income_and_assets():
    """🚨 금융 3종(영업이익·순이익·자산총계)이 잡힌다 — 매출만 정말로 없다.

    기업은행 2025 실측: 자산 5,006,926억 · 영업이익 36,555억. 영업이익이 그동안 빈 것은 사실이
    아니라 계정 ID 를 안 넣어서였다(SP-MET-2)."""
    found = df.extract_accounts(IBK_2025)
    assert df.ACCT_REVENUE not in found
    assert found[df.ACCT_ASSETS]["amt"] // 100_000_000 == 5_006_926
    assert found[df.ACCT_OP_INCOME]["amt"] // 100_000_000 == 36_555
    assert found[df.ACCT_NET_INCOME]["amt"] == 2_800_000_000_000
    assert found[df.ACCT_ASSETS]["rcept_no"] == "20260318000010"


def test_MET2_operating_income_falls_back_to_the_alias_account():
    """`dart_OperatingIncomeLoss` 가 없으면 `ifrs-full_ProfitLossFromOperatingActivities` 로 잡는다 —
    카카오페이 503억 자리. 대표 ID 로 저장되므로 소비처는 한 계정만 알면 된다."""
    found = df.extract_accounts(FIN_ALT_OP)
    assert found[df.ACCT_OP_INCOME]["amt"] == 50_300_000_000
    assert found[df.ACCT_OP_INCOME]["amt"] // 100_000_000 == 503
    assert found[df.ACCT_OP_INCOME]["acct_id"] == _OP_ALT
    assert df.acct_conflict(found[df.ACCT_OP_INCOME]) is None  # 하나뿐이면 충돌이 아니다


def test_MET3_empty_first_alias_does_not_swallow_the_second():
    """앞 별칭 행이 `-`(값 없음)이면 뒤 별칭의 실값을 쓴다 — 순서는 '있는 것들' 사이의 순서다.
    빈 행을 앞순위라고 채택하면 실값이 조용히 버려진다."""
    payload = _payload([
        _row("dart_OperatingIncomeLoss", "-", acct_nm="영업이익"),
        _row(_OP_ALT, "36,555,000,000", acct_nm="영업이익"),
    ])
    found = df.extract_accounts(payload)
    assert found[df.ACCT_OP_INCOME]["amt"] == 36_555_000_000
    assert found[df.ACCT_OP_INCOME]["acct_id"] == _OP_ALT


# ── 계정 충돌: 조용히 고르지 않는다 (SP-MET-2) ───────────────────────────────

def test_MET2_two_operating_income_accounts_with_different_values_conflict():
    """두 영업이익 계정이 함께 있고 값이 다르면 **충돌**이다 — 어느 쪽이 그 회사의 영업이익인지
    데이터가 답하지 못하므로, 목록 순서로 몰래 고르지 않는다."""
    payload = _payload([
        _row("dart_OperatingIncomeLoss", "3,655,500,000,000", acct_nm="영업이익"),
        _row(_OP_ALT, "3,100,000,000,000", acct_nm="영업이익"),
    ])
    clash = df.acct_conflict(df.extract_accounts(payload)[df.ACCT_OP_INCOME])
    assert clash == {"dart_OperatingIncomeLoss": 3_655_500_000_000, _OP_ALT: 3_100_000_000_000}


def test_MET2_two_operating_income_accounts_with_the_same_value_are_not_a_conflict():
    """값이 같으면 어느 쪽을 써도 같다 — 충돌이 아니고, 목록 순서대로 첫 계정을 쓴다."""
    payload = _payload([
        _row("dart_OperatingIncomeLoss", "3,655,500,000,000", acct_nm="영업이익"),
        _row(_OP_ALT, "3,655,500,000,000", acct_nm="영업이익"),
    ])
    entry = df.extract_accounts(payload)[df.ACCT_OP_INCOME]
    assert df.acct_conflict(entry) is None
    assert entry["acct_id"] == df.ACCT_OP_INCOME and entry["amt"] == 3_655_500_000_000


def test_MET2_collect_records_conflict_and_writes_null_instead_of_guessing():
    """충돌이면 실패 목록에 회사·연도를 찍고 값은 **NULL** 로 둔다 — 근거 없이 고른 수치를
    화면에 내보내는 것보다 '없음'이 낫다."""
    conflicted = _payload([
        _row("ifrs-full_Revenue", "10,000,000,000,000", acct_nm="매출액"),
        _row("dart_OperatingIncomeLoss", "3,655,500,000,000", acct_nm="영업이익"),
        _row(_OP_ALT, "3,100,000,000,000", acct_nm="영업이익"),
        _row("ifrs-full_ProfitLoss", "2,800,000,000,000", acct_nm="당기순이익"),
    ])
    router = Router({("00126380", 2025, "CFS"): conflicted})
    cur = RecordingCursor()
    stats = df.collect(cur, [SAMSUNG], api_key=KEY, base_year=2025, years=1, fetch_fn=router, sleep_sec=0)
    assert [(c["corp_nm"], c["year"], c["fs_div"], c["acct_id"]) for c in stats["conflicts"]] == [
        ("삼성전자", 2025, "CFS", df.ACCT_OP_INCOME)]
    by_acct = {r[3]: r for r in _upsert_rows(cur)}
    assert by_acct[df.ACCT_OP_INCOME][5] is None, "충돌인데 한쪽 값이 저장됐다 — 조용히 골랐다"
    assert by_acct[df.ACCT_REVENUE][5] == 10_000_000_000_000, "충돌은 그 지표에만 번진다"
    report = df.format_conflicts(stats["conflicts"])
    assert "삼성전자" in report and "3,655,500,000,000" in report and "3,100,000,000,000" in report


# ── URL·키 ───────────────────────────────────────────────────────────────────

def test_build_url_carries_annual_report_params():
    url = df.build_url(KEY, "00126380", 2025, "CFS")
    q = parse_qs(urlparse(url).query)
    assert url.startswith(df.API_URL)
    assert q["crtfc_key"] == [KEY]
    assert q["corp_code"] == ["00126380"]
    assert q["bsns_year"] == ["2025"]
    assert q["reprt_code"] == ["11011"]
    assert q["fs_div"] == ["CFS"]


def test_FN3_missing_key_fails_before_any_http_call():
    """키 없음 = 즉시 실패. fetch 는 한 번도 불리지 않고, 커서도 건드리지 않는다."""
    router = Router(ROUTES)
    with pytest.raises(df.DartError) as ei:
        df.collect(None, [SAMSUNG], api_key="", base_year=2025, fetch_fn=router, sleep_sec=0)
    assert router.urls == []
    assert "DART_API_KEY" in str(ei.value)


def test_FN3_fetch_failure_message_never_contains_key():
    """전송 실패를 감쌀 때 URL(키 포함)을 메시지에 싣지 않는다."""

    def boom(url):
        raise OSError(f"connection refused for {url}")

    cur = RecordingCursor()
    with pytest.raises(df.DartError) as ei:
        df.collect(cur, [SAMSUNG], api_key=KEY, base_year=2025, fetch_fn=boom, sleep_sec=0)
    assert KEY not in str(ei.value)
    assert "00126380" in str(ei.value)  # 어느 회사·연도에서 죽었는지는 말한다
    assert _upsert_rows(cur) == []


# ── 수집(무DB 계약) ──────────────────────────────────────────────────────────

def test_MET11_collect_defaults_to_eleven_years_times_two_divs():
    """기본 11개년(2015~2025) × CFS/OFS = 22 호출/사(SP-MET-11).

    기존 5 는 SPEC 15 에 "최근 5개년"으로 적혔을 뿐 근거가 없던 값이다 — 그래프는 5점으로 추이가
    되지 않는다. 100사면 2,200 호출로 일 한도 20,000 안이다."""
    router = Router(ROUTES)
    cur = RecordingCursor()
    stats = df.collect(cur, [SAMSUNG], api_key=KEY, base_year=2025, fetch_fn=router, sleep_sec=0)
    assert len(router.urls) == 22
    years = sorted({int(parse_qs(urlparse(u).query)["bsns_year"][0]) for u in router.urls})
    assert years == list(range(2015, 2026))
    assert stats["calls"] == 22
    assert stats["reports"] == 2  # 삼성 2025·2024 CFS 만 픽스처 있음


def test_collect_writes_all_four_accounts_per_report_even_when_absent():
    """보고서가 있으면 4계정(매출·영업이익·순이익·자산총계) 행을 모두 쓴다 —
    없는 계정은 AMT_VAL **NULL**(0 아님). 그래야 "보고서는 봤는데 계정이 없다"와
    "보고서가 없다"(행 자체 없음)가 구분된다."""
    router = Router(ROUTES)
    cur = RecordingCursor()
    df.collect(cur, [SAMSUNG_LIFE], api_key=KEY, base_year=2025, fetch_fn=router, sleep_sec=0)
    rows = _upsert_rows(cur)
    assert len(rows) == 4
    by_acct = {r[3]: r for r in rows}  # (CORP_CODE, BSNS_YEAR, FS_DIV_CD, ACCT_ID, ACCT_NM, AMT_VAL, RCEPT_NO)
    assert by_acct[df.ACCT_REVENUE][5] is None
    assert by_acct[df.ACCT_OP_INCOME][5] is None
    assert by_acct[df.ACCT_NET_INCOME][5] == 2_451_500_000_000
    assert by_acct[df.ACCT_ASSETS][5] == 330_000_000_000_000
    assert all(r[6] == "20260325000004" for r in rows), "결측 행에도 접수번호를 남긴다(어느 보고서를 봤는지)"


def test_collect_writes_nothing_for_years_without_report():
    router = Router(ROUTES)
    cur = RecordingCursor()
    df.collect(cur, [SKHYNIX], api_key=KEY, base_year=2025, fetch_fn=router, sleep_sec=0)
    rows = _upsert_rows(cur)
    assert {(r[1], r[2]) for r in rows} == {(2025, "CFS")}


def test_collect_stores_both_cfs_and_ofs_for_lg():
    router = Router(ROUTES)
    cur = RecordingCursor()
    df.collect(cur, [LG], api_key=KEY, base_year=2025, fetch_fn=router, sleep_sec=0)
    op = {r[2]: r[5] for r in _upsert_rows(cur) if r[3] == df.ACCT_OP_INCOME}
    assert op == {"CFS": 912_200_000_000, "OFS": 597_100_000_000}


# ── 실 DB: UNIQUE 멱등·결측 검사 ─────────────────────────────────────────────

def _mk_corps(conn, corps: list[dict]) -> None:
    """픽스처 법인을 TCORP 에 둔다. 같은 세션에서 `seeded_db` 가 먼저 돌았으면(load.py 마지막 단계가
    load_corp 를 부른다) 실 corp_code 가 이미 있으므로 upsert — clean_tx 라 어차피 롤백된다."""
    with conn.cursor() as cur:
        for c in corps:
            cur.execute(
                "INSERT INTO TCORP (CORP_CODE, CORP_NM, STOCK_CD, ACCT_SET_CD, FS_DIV_CD) VALUES (%s,%s,%s,%s,'CFS') "
                "AS new ON DUPLICATE KEY UPDATE ACCT_SET_CD=new.ACCT_SET_CD, FS_DIV_CD='CFS'",
                (c["corp_code"], c["corp_nm"], None, c["acct_set"]),
            )


def _rows(conn, corp_code: str) -> list[tuple]:
    with conn.cursor() as cur:
        cur.execute(
            "SELECT BSNS_YEAR, FS_DIV_CD, ACCT_ID, AMT_VAL, RCEPT_NO FROM TCORP_FINANCE "
            "WHERE CORP_CODE=%s ORDER BY BSNS_YEAR, FS_DIV_CD, ACCT_ID",
            (corp_code,),
        )
        return cur.fetchall()


def test_FN2_db_rerun_is_idempotent_and_keeps_cfs_ofs_apart(clean_tx):
    conn = clean_tx
    _mk_corps(conn, [LG, SAMSUNG_LIFE])
    with conn.cursor() as cur:
        df.collect(cur, [LG, SAMSUNG_LIFE], api_key=KEY, base_year=2025, fetch_fn=Router(ROUTES), sleep_sec=0)
        first = _rows(conn, LG["corp_code"]) + _rows(conn, SAMSUNG_LIFE["corp_code"])
        df.collect(cur, [LG, SAMSUNG_LIFE], api_key=KEY, base_year=2025, fetch_fn=Router(ROUTES), sleep_sec=0)
        second = _rows(conn, LG["corp_code"]) + _rows(conn, SAMSUNG_LIFE["corp_code"])
    assert first == second, "재실행이 행을 늘리거나 바꿨다 — UNIQUE 멱등이 깨졌다"
    lg = {(y, d, a): amt for y, d, a, amt, _ in _rows(conn, LG["corp_code"])}
    assert lg[(2025, "CFS", df.ACCT_OP_INCOME)] == 912_200_000_000
    assert lg[(2025, "OFS", df.ACCT_OP_INCOME)] == 597_100_000_000
    life = {a: amt for _, _, a, amt, _ in _rows(conn, SAMSUNG_LIFE["corp_code"])}
    assert life[df.ACCT_REVENUE] is None and life[df.ACCT_OP_INCOME] is None
    assert life[df.ACCT_NET_INCOME] == 2_451_500_000_000


def test_FN3_db_missing_check_flags_general_set_gap_but_not_financial(clean_tx):
    """일반 세트인데 최신연도 지표가 비면 실패 목록에 오른다. 금융은 매출을 요구하지 않는다.

    ⓘ 삼성생명 캡처본에는 영업이익이 없다(SP-MET-2 이전에 3계정만 요청해 뜬 것) — 실제로는 7/7 로
      있으므로 여기서 넣어 준다. 캡처의 공백을 사실로 굳히면 그게 다음 함정이 된다."""
    conn = clean_tx
    _mk_corps(conn, [SAMSUNG, SAMSUNG_LIFE])
    routes = dict(ROUTES)
    routes[("00126380", 2025, "CFS")] = _without(_fixture("samsung_2025_cfs"), df.ACCT_OP_INCOME)
    routes[("00126256", 2025, "CFS")] = _with_row(
        _fixture("samsung_life_2025_cfs"),
        _row(df.ACCT_OP_INCOME, "2,580,400,000,000", acct_nm="영업이익"),  # 삼성생명 2025 실측 25,804억
    )
    with conn.cursor() as cur:
        df.collect(cur, [SAMSUNG, SAMSUNG_LIFE], api_key=KEY, base_year=2025, fetch_fn=Router(routes), sleep_sec=0)
        missing = df.check_missing(cur, base_year=2025, corps=[SAMSUNG, SAMSUNG_LIFE])
    assert [(m["corp_nm"], m["year"], m["acct_id"]) for m in missing] == [("삼성전자", 2025, df.ACCT_OP_INCOME)]
    report = df.format_missing(missing)
    assert "삼성전자" in report and "2025" in report and df.ACCT_OP_INCOME in report


def test_MET2_db_financial_set_requires_op_income_and_assets_too(clean_tx):
    """🚨 금융의 필수는 이제 **영업이익·순이익·자산총계 3종**이다(SP-MET-2).

    삼성생명 캡처본은 영업이익이 없으므로 그것만 실패 목록에 올라야 한다 — 매출은 금융에서
    요구하지 않으니 올라오면 안 된다. 예전 규칙("금융은 순이익만")이면 이 결측은 **영영 안 보인다**:
    영업이익이 비어 있던 건 사실이 아니라 계정 ID 누락이었는데, 검사가 그 사실을 덮고 있었다."""
    conn = clean_tx
    _mk_corps(conn, [SAMSUNG_LIFE])
    with conn.cursor() as cur:
        df.collect(cur, [SAMSUNG_LIFE], api_key=KEY, base_year=2025, fetch_fn=Router(ROUTES), sleep_sec=0)
        missing = df.check_missing(cur, base_year=2025, corps=[SAMSUNG_LIFE])
    assert [m["acct_id"] for m in missing] == [df.ACCT_OP_INCOME]
    assert df.ACCT_ASSETS not in [m["acct_id"] for m in missing]  # 자산총계는 BS 에서 잡혔다
    assert df.ACCT_REVENUE not in [m["acct_id"] for m in missing]  # 금융에 매출을 요구하지 않는다


def test_MET2_db_financial_set_passes_when_all_three_are_present(clean_tx):
    """영업이익 계정을 넣어 준 금융 회사는 결측 0 — 7/7 실측이 재현되는지 확인한다."""
    conn = clean_tx
    _mk_corps(conn, [SAMSUNG_LIFE])
    routes = {("00126256", 2025, "CFS"): _with_row(
        _fixture("samsung_life_2025_cfs"), _row(_OP_ALT, "2,580,400,000,000", acct_nm="영업이익"))}
    with conn.cursor() as cur:
        df.collect(cur, [SAMSUNG_LIFE], api_key=KEY, base_year=2025, fetch_fn=Router(routes), sleep_sec=0)
        assert df.check_missing(cur, base_year=2025, corps=[SAMSUNG_LIFE]) == []
        rows = {a: amt for _, _, a, amt, _ in _rows(conn, SAMSUNG_LIFE["corp_code"])}
    assert rows[df.ACCT_OP_INCOME] == 2_580_400_000_000  # 대안 계정도 대표 ID 로 저장된다
    assert rows[df.ACCT_ASSETS] == 330_000_000_000_000
    assert rows[df.ACCT_REVENUE] is None


def test_FN3_db_missing_check_hints_when_other_basis_has_the_data(clean_tx):
    """표시 기준(CFS)엔 없고 별도(OFS)에만 있으면 — 비상장·무자회사 회사 — 힌트를 붙인다.
    운영자가 `TCORP.FS_DIV_CD` 를 OFS 로 바꾸면 되는 문제라는 걸 결측 목록이 말해 줘야 한다."""
    conn = clean_tx
    _mk_corps(conn, [LG])
    routes = {("00120021", 2025, "OFS"): _fixture("lg_2025_ofs")}  # CFS 는 013
    with conn.cursor() as cur:
        df.collect(cur, [LG], api_key=KEY, base_year=2025, fetch_fn=Router(routes), sleep_sec=0)
        missing = df.check_missing(cur, base_year=2025, corps=[LG])
    assert len(missing) == 3
    assert all("OFS" in (m.get("hint") or "") for m in missing)


def test_FN3_db_no_missing_when_all_present(clean_tx):
    conn = clean_tx
    _mk_corps(conn, [SAMSUNG, SKHYNIX, LG])
    with conn.cursor() as cur:
        df.collect(cur, [SAMSUNG, SKHYNIX, LG], api_key=KEY, base_year=2025, fetch_fn=Router(ROUTES), sleep_sec=0)
        assert df.check_missing(cur, base_year=2025, corps=[SAMSUNG, SKHYNIX, LG]) == []


class _NoCommit:
    """`main()` 이 commit 을 불러도 clean_tx 격리가 깨지지 않게 막는 프록시."""

    def __init__(self, conn):
        self._conn = conn

    def commit(self):
        pass

    def __getattr__(self, name):
        return getattr(self._conn, name)


def test_FN3_cli_exits_1_on_missing_metrics(clean_tx, capsys, monkeypatch):
    conn = clean_tx
    _mk_corps(conn, [SAMSUNG])
    routes = {("00126380", 2025, "CFS"): _without(_fixture("samsung_2025_cfs"), df.ACCT_REVENUE)}
    monkeypatch.setattr(df, "_api_key", lambda: KEY)
    router = Router(routes)
    rc = df.main(["--base-year", "2025", "--sleep", "0", "--corp", "00126380"], fetch_fn=router, conn=_NoCommit(conn))
    assert rc == 1
    out = capsys.readouterr()
    assert "삼성전자" in out.out + out.err
    assert KEY not in out.out + out.err
    # `--years` 를 안 주면 11개년(SP-MET-11) — CLI 기본값이 collect 기본값과 갈라지지 않게 못 박는다
    assert len(router.urls) == 22


def test_MET2_cli_exits_1_and_lists_both_accounts_on_conflict(clean_tx, capsys, monkeypatch):
    """🚨 두 영업이익 계정이 다른 값이면 종료 1 + 회사·연도·**두 값 모두** 출력. 조용히 고르지 않는다."""
    conn = clean_tx
    _mk_corps(conn, [SAMSUNG])
    routes = {("00126380", 2025, "CFS"): _with_row(
        _fixture("samsung_2025_cfs"), _row(_OP_ALT, "39,500,000,000,000", acct_nm="영업이익"))}
    monkeypatch.setattr(df, "_api_key", lambda: KEY)
    rc = df.main(["--base-year", "2025", "--years", "1", "--sleep", "0", "--corp", "00126380"],
                 fetch_fn=Router(routes), conn=_NoCommit(conn))
    assert rc == 1
    out = capsys.readouterr().out
    assert "삼성전자" in out and "2025" in out
    assert "40,000,000,000,000" in out and "39,500,000,000,000" in out, "어느 값들이 어긋났는지 말해야 한다"
    assert _OP_ALT in out and df.ACCT_OP_INCOME in out
    with conn.cursor() as cur:  # 값은 NULL — 근거 없이 고른 수치를 남기지 않는다
        cur.execute("SELECT AMT_VAL FROM TCORP_FINANCE WHERE CORP_CODE=%s AND BSNS_YEAR=2025 AND ACCT_ID=%s",
                    (SAMSUNG["corp_code"], df.ACCT_OP_INCOME))
        assert [r[0] for r in cur.fetchall()] == [None]  # 보고서가 있는 CFS 한 행, 값은 비어 있다


def test_FN3_cli_refuses_without_key(monkeypatch, capsys):
    monkeypatch.setattr(df, "_api_key", lambda: "")
    router = Router(ROUTES)
    rc = df.main(["--base-year", "2025"], fetch_fn=router, conn=object())
    assert rc == 2
    assert router.urls == []
    assert "DART_API_KEY" in capsys.readouterr().err


def test_probe_summarises_one_call_without_touching_db(monkeypatch, capsys):
    """`--probe` 는 커서 없이 1회 호출만 — 요약(억원·접수번호)을 찍고 원문·키는 찍지 않는다."""
    monkeypatch.setattr(df, "_api_key", lambda: KEY)
    router = Router(ROUTES)
    rc = df.main(["--probe", "00164779", "--base-year", "2025", "--fs-div", "CFS"], fetch_fn=router, conn=None)
    assert rc == 0 and len(router.urls) == 1
    out = capsys.readouterr().out
    assert "472,063억원" in out and "20260320000003" in out
    assert KEY not in out and "thstrm_amount" not in out
    assert df.probe(KEY, "00126380", 2019, "CFS", fetch_fn=router) == {"status": "013", "rows": 0, "found": {}}


def test_MET3_probe_names_the_alias_account_it_matched(monkeypatch, capsys):
    """구접두사 연도 프로브는 **어느 계정으로 잡았는지**까지 찍는다 — 숫자만 보면 신형으로 잡힌 것과
    구별되지 않아, 별칭이 죽어도 프로브가 초록으로 보인다."""
    monkeypatch.setattr(df, "_api_key", lambda: KEY)
    rc = df.main(["--probe", "00126380", "--base-year", "2017", "--fs-div", "CFS"],
                 fetch_fn=Router({("00126380", 2017, "CFS"): SAMSUNG_2017}), conn=None)
    assert rc == 0
    out = capsys.readouterr().out
    assert "2,395,754억원" in out              # 239.6조를 억원으로
    assert "[ifrs_Revenue]" in out and "[ifrs_ProfitLoss]" in out
    assert "[dart_OperatingIncomeLoss]" not in out  # 대표 계정 그대로면 꼬리표를 붙이지 않는다
    assert KEY not in out


def test_settings_exposes_dart_api_key_without_forbidden_substring(monkeypatch):
    """`config.dart_api_key` 기본 "" — 금지 substring(jwt·oauth·password_reset·social) 규약 유지.
    `_env_file=None` 은 .env 만 끊는다 — conftest 의 load_dotenv 가 os.environ 에 부은 실키는 delenv 로
    걷어내야 '선언된 기본값'을 본다(함정 0079 와 같은 결: env 가 채워진 호스트에서만 빨강이 된다)."""
    from server.config import Settings

    monkeypatch.delenv("DART_API_KEY", raising=False)
    s = Settings(_env_file=None)
    assert s.dart_api_key == ""
    assert not any(bad in "dart_api_key" for bad in ("jwt", "oauth", "password_reset", "social"))


# ── 법인 단위 커밋 (2026-08-28 실사고) ───────────────────────────────────────

def test_FIN_commits_after_every_corporation_so_a_crash_keeps_what_it_got():
    """끝에서 한 번만 커밋하면 2,200 호출 중 마지막에 죽었을 때 **0행**이 남는다.

    직원 수집기가 실제로 그렇게 죽었고(셀트리온 2016 타임아웃), 같은 골격인 이 수집기도 같은
    위험을 안고 있었다. 법인이 경계인 이유는 그 안이 "한 회사의 연도들 × 기준"이라 부분 상태가
    의미를 갖는 최소 단위이고, UNIQUE upsert 라 재실행이 덮어쓰기 때문이다.
    """
    marks = []
    df.collect(RecordingCursor(), [SAMSUNG, SKHYNIX], api_key=KEY, base_year=2025, years=1,
               fetch_fn=Router(ROUTES), sleep_sec=0, commit=lambda: marks.append("c"))
    assert marks == ["c", "c"], "법인마다 한 번씩 커밋한다"


def test_FIN_a_failure_in_the_second_corporation_keeps_the_first():
    base = Router(ROUTES)

    def router(url):
        if parse_qs(urlparse(url).query)["corp_code"][0] == "00126380":
            return base(url)
        raise TimeoutError("timed out")

    marks = []
    with pytest.raises(df.DartError):
        df.collect(RecordingCursor(), [SAMSUNG, SKHYNIX], api_key=KEY, base_year=2025, years=1,
                   fetch_fn=router, sleep_sec=0, commit=lambda: marks.append("c"))
    assert marks == ["c"], "첫 법인은 이미 남았다"


def test_FIN_every_ifrs_metric_carries_its_old_prefix_alias():
    """🚨 접두사 변경(2019, SP-MET-3)은 **네 지표에 전부** 적용된다.

    초판은 매출·순이익에만 별칭을 달고 자산총계를 빠뜨렸고, 그 결과 2018년 이전 자산총계가
    조용히 비었다(실수집 확인: `ifrs-full_Assets` 커버리지 2019년부터 100%, 2015~2018 은 130건 중 3건).
    이 테스트는 **지표를 새로 추가할 때 같은 함정을 다시 밟는 것**을 막는다 — `ifrs-full_` 로 시작하는
    대표 계정이 있으면 `ifrs_` 짝이 목록에 있어야 한다.
    ⓘ `dart_` 접두사(영업이익)는 바뀐 적이 없어 이 규칙 밖이다.
    """
    for metric, ids in df.ACCT_ALIASES.items():
        modern = [a for a in ids if a.startswith("ifrs-full_")]
        for a in modern:
            legacy = a.replace("ifrs-full_", "ifrs_", 1)
            assert legacy in ids, f"{metric}: {a} 의 구접두사 {legacy} 가 별칭에 없다 — 2018년 이전이 조용히 빈다"


def test_FIN_assets_reads_the_old_prefix():
    """기업은행 2016 은 `ifrs_Assets` 로 온다(실측). 대표 계정 하나로 정규화해 저장한다."""
    payload = _payload([
        {"account_id": "ifrs_Assets", "account_nm": "자산총계", "thstrm_amount": "9162368431781",
         "sj_div": "BS", "rcept_no": "20170331000001"},
    ])
    found = df.extract_accounts(payload)
    assert found["ifrs-full_Assets"]["amt"] == 9_162_368_431_781
    assert found["ifrs-full_Assets"]["acct_id"] == "ifrs_Assets", "어느 계정으로 잡았는지는 남긴다"
