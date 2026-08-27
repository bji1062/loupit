"""DART 재무 수집기 계약 — FN-2·FN-3 (SP-FIN-3, T-15.1.2~15.1.4).

근거: `docs/SPEC/15-회사정보-재무.md` SP-FIN-3 · `PLAN-회사정보-확장-2026-08-21.md` §5-2 · 함정 (68).

**이 테스트가 지키는 것은 "조용히 비는 실패"를 막는 세 가지 결정이다.**

  1. **지표는 `account_id` 로만 찾는다.** SK하이닉스는 손익을 `IS` 가 아니라 `CIS` 에 싣는다 —
     `sj_div` 로 거르면 에러 없이 그 회사 영업이익만 빈다(함정 (68)).
  2. **없는 계정은 NULL 이지 0 이 아니다.** 삼성생명(금융)은 `ifrs-full_Revenue` 가 아예 없다.
     0 으로 넣으면 "매출 0원"이라는 거짓 수치가 화면에 나간다.
  3. **키가 없으면 즉시 실패하고, 키는 어디에도 찍히지 않는다.** 조용한 0건은 "수집했는데
     없더라"로 읽힌다(함정 (57)).

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
    """금융업은 매출·영업이익 계정이 **없다** — 결과에 키 자체가 없어야 한다(0 으로 지어내지 않는다)."""
    found = df.extract_accounts(_fixture("samsung_life_2025_cfs"))
    assert df.ACCT_REVENUE not in found
    assert df.ACCT_OP_INCOME not in found
    assert found[df.ACCT_NET_INCOME]["amt"] == 2_451_500_000_000


def test_extract_returns_none_for_013_no_data():
    assert df.extract_accounts(NO_DATA) is None


def test_extract_raises_on_other_error_status():
    with pytest.raises(df.DartError):
        df.extract_accounts({"status": "020", "message": "요청 제한을 초과하였습니다."})


def test_extract_ignores_noise_accounts_and_blank_amounts():
    """표준계정 밖 행·빈 금액 행은 조용히 무시한다 — 3지표만 돌아온다."""
    found = df.extract_accounts(_fixture("samsung_2025_cfs"))
    assert set(found) == set(df.ACCT_IDS)


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

def test_collect_calls_five_years_times_two_divs_per_corp():
    router = Router(ROUTES)
    cur = RecordingCursor()
    stats = df.collect(cur, [SAMSUNG], api_key=KEY, base_year=2025, fetch_fn=router, sleep_sec=0)
    assert len(router.urls) == 10
    years = sorted({int(parse_qs(urlparse(u).query)["bsns_year"][0]) for u in router.urls})
    assert years == [2021, 2022, 2023, 2024, 2025]
    assert stats["calls"] == 10
    assert stats["reports"] == 2  # 삼성 2025·2024 CFS 만 픽스처 있음


def test_collect_writes_all_three_accounts_per_report_even_when_absent():
    """보고서가 있으면 3계정 행을 모두 쓴다 — 없는 계정은 AMT_VAL **NULL**(0 아님)."""
    router = Router(ROUTES)
    cur = RecordingCursor()
    df.collect(cur, [SAMSUNG_LIFE], api_key=KEY, base_year=2025, fetch_fn=router, sleep_sec=0)
    rows = _upsert_rows(cur)
    assert len(rows) == 3
    by_acct = {r[3]: r for r in rows}  # (CORP_CODE, BSNS_YEAR, FS_DIV_CD, ACCT_ID, ACCT_NM, AMT_VAL, RCEPT_NO)
    assert by_acct[df.ACCT_REVENUE][5] is None
    assert by_acct[df.ACCT_OP_INCOME][5] is None
    assert by_acct[df.ACCT_NET_INCOME][5] == 2_451_500_000_000
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
    """일반 세트인데 최신연도 지표가 비면 실패 목록에 오른다. 금융은 순이익만 본다."""
    conn = clean_tx
    _mk_corps(conn, [SAMSUNG, SAMSUNG_LIFE])
    routes = dict(ROUTES)
    routes[("00126380", 2025, "CFS")] = _without(_fixture("samsung_2025_cfs"), df.ACCT_OP_INCOME)
    with conn.cursor() as cur:
        df.collect(cur, [SAMSUNG, SAMSUNG_LIFE], api_key=KEY, base_year=2025, fetch_fn=Router(routes), sleep_sec=0)
        missing = df.check_missing(cur, base_year=2025, corps=[SAMSUNG, SAMSUNG_LIFE])
    assert [(m["corp_nm"], m["year"], m["acct_id"]) for m in missing] == [("삼성전자", 2025, df.ACCT_OP_INCOME)]
    report = df.format_missing(missing)
    assert "삼성전자" in report and "2025" in report and df.ACCT_OP_INCOME in report


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
    rc = df.main(["--base-year", "2025", "--sleep", "0", "--corp", "00126380"], fetch_fn=Router(routes), conn=_NoCommit(conn))
    assert rc == 1
    out = capsys.readouterr()
    assert "삼성전자" in out.out + out.err
    assert KEY not in out.out + out.err


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


def test_settings_exposes_dart_api_key_without_forbidden_substring(monkeypatch):
    """`config.dart_api_key` 기본 "" — 금지 substring(jwt·oauth·password_reset·social) 규약 유지.
    `_env_file=None` 은 .env 만 끊는다 — conftest 의 load_dotenv 가 os.environ 에 부은 실키는 delenv 로
    걷어내야 '선언된 기본값'을 본다(함정 0079 와 같은 결: env 가 채워진 호스트에서만 빨강이 된다)."""
    from server.config import Settings

    monkeypatch.delenv("DART_API_KEY", raising=False)
    s = Settings(_env_file=None)
    assert s.dart_api_key == ""
    assert not any(bad in "dart_api_key" for bad in ("jwt", "oauth", "password_reset", "social"))
