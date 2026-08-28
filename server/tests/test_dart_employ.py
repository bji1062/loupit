"""DART 직원현황 수집기 계약 — SP-MET-5·6·7 (SPEC 17, `db/seed/dart_employ.py`).

근거: `docs/SPEC/17-회사정보-지표.md`(수치는 2026-08-28 DART 전수 실측) · `test_dart_finance.py`(같은 골격).

**이 테스트가 지키는 것은 "에러 없이 틀린 숫자가 나가는" 세 경로다.**

  1. **합계행**(SP-MET-5): 부문행과 합계행을 함께 내는 7사를 그대로 더하면 삼성전자가
     128,881 → **257,762 명**이 된다. 예외도 에러도 없이 두 배가 된다.
  2. **급여 단위**(SP-MET-6): CJ ENM 2019 의 `83` 을 그대로 쓰면 그 해만 평균연봉이 0원이 된다.
  3. **근속 표기**(SP-MET-7): `92개월` 을 `float()` 하면 그 회사만 92년 근속이 된다.

HTTP 는 `fetch_fn(url)->dict` 주입으로 끊는다. 픽스처를 **이 파일 안에** 둔 이유: 이 숫자들은
평범한 샘플이 아니라 **함정의 재현**이라(1,565 vs 1,588 같은 우연의 일치), 어떤 함정을 재현하는지
바로 옆에 적혀 있지 않으면 다음 사람이 값을 '정리'하다가 함정을 지운다.

무DB 계약은 기록용 fake 커서로 보고, **UNIQUE 멱등과 실 DDL 수용은 `clean_tx`(롤백 격리)로
진짜 테이블 위에서** 본다 — 컬럼 폭·DECIMAL(5,2)·BOOLEAN 을 픽스처로 대신하면 그 구간은 테스트가
없는 것과 같다(반복 함정). 화면까지 잇는 파이프라인 회귀는 SP-MET-12 가 따로 본다.
"""
from __future__ import annotations

import sys
from pathlib import Path
from urllib.parse import parse_qs, urlparse

import pytest

ROOT = Path(__file__).resolve().parents[2]
SEED_DIR = ROOT / "db" / "seed"
if str(SEED_DIR) not in sys.path:
    sys.path.insert(0, str(SEED_DIR))

import dart_employ as de  # noqa: E402  # db/seed/dart_employ.py

NO_DATA = {"status": "013", "message": "조회된 데이타가 없습니다."}
# 절대 출력되면 안 되는 표식 — 예외 메시지·요약 어디에도 이 문자열이 나오면 실패.
KEY = "test-key-DO-NOT-PRINT-0123456789abcdef"

SAMSUNG = {"corp_code": "00126380", "corp_nm": "삼성전자"}
CELLTRION = {"corp_code": "00413046", "corp_nm": "셀트리온"}
CJENM = {"corp_code": "00265324", "corp_nm": "CJ ENM"}
# 실측이 아니라 **검사가 살아 있는지** 보는 인공 법인 — 이름이 `합계`·`총계` 가 아닌 합계행을 내는 날을
# 가정한다. 그런 회사가 실제로 나타나면 표식 검사는 못 잡고 인원 검사만 잡는다.
FAKECORP = {"corp_code": "00999999", "corp_nm": "가상합계사(테스트 전용)"}


def _emp(fo_bbm, sexdstn, sm, tenure, salary, rcept_no="20260311000123"):
    """`empSttus` 응답 행 한 줄. 우리가 읽는 칸만 채운다 — 연간급여총액(`fyer_salary_totamt`)은
    일부러 넣지 않는다(SP-MET-8: 읽지도 저장하지도 않는다. CJ CGV 는 총액/인원이 4.8배 어긋난다)."""
    return {"rcept_no": rcept_no, "corp_code": "00000000", "corp_name": "-",
            "fo_bbm": fo_bbm, "sexdstn": sexdstn, "sm": sm,
            "avrg_cnwk_sdytrn": tenure, "jan_salary_am": salary}


def _ok(rows):
    return {"status": "000", "message": "정상", "list": rows}


# ── 픽스처: 삼성전자 2025 모양(부문행 4 + 성별합계 2) ─────────────────────────────
# 🚨 합계행 2줄만 세면 128,881명이고, 여섯 줄을 다 더하면 257,762명이다 — 정확히 두 배(SP-MET-5).
# 합계행의 인원 가중평균이 SP-MET-1 검증값(157,064,509원 · 13.7년)이 되도록 잡았다.
SAMSUNG_2025 = _ok([
    _emp("DX부문", "남", "50,000", "12.80", "150,000,000"),
    _emp("DX부문", "여", "20,000", "9년 3개월", "120,000,000"),
    _emp("DS부문", "남", "40,214", "15년 2월", "200,000,000"),
    _emp("DS부문", "여", "18,667", "108개월", "160,000,000"),
    _emp("성별합계", "남", "90,214", "14년 6월", "168,000,000"),
    _emp("성별합계", "여", "38,667", "11년 10개월", "131,550,909"),
])

# ── 픽스처: 셀트리온 2025 — 합계행이 **없는데** 미탐 검사에 걸리는 오탐(SP-MET-5) ──────────
# 생산직 1,565 vs 나머지(사무직 1,000 + 연구직 588 = 1,588). 1.4% 차 — 우연의 일치다.
# 이 픽스처의 존재 이유는 "검사가 오탐한다"가 아니라 **"오탐을 사람 확인 목록으로만 통과시킨다"**이다.
CELLTRION_2025 = _ok([
    _emp("생산직", "남", "1,000", "5.20", "70,000,000"),
    _emp("생산직", "여", "565", "4.80", "62,000,000"),
    _emp("사무직", "남", "600", "6년 4개월", "90,000,000"),
    _emp("사무직", "여", "400", "5년 1개월", "78,000,000"),
    _emp("연구직", "남", "350", "7.10", "95,000,000"),
    _emp("연구직", "여", "238", "6.40", "88,000,000"),
])

# ── 픽스처: CJ ENM — 같은 회사가 해마다 급여 단위를 바꾼다(SP-MET-6) ────────────────
# 2018 원 · 2019 **백만원** · 2020 원. 근속은 `92개월`(SP-MET-7) — float 캐스팅하면 92년이 된다.
CJENM_2018 = _ok([_emp("미디어", "남", "1,200", "88개월", "96,000,000"),
                  _emp("미디어", "여", "900", "80개월", "76,000,000")])
CJENM_2019 = _ok([_emp("미디어", "남", "1,250", "92개월", "83"),
                  _emp("미디어", "여", "950", "84개월", "72")])
CJENM_2020 = _ok([_emp("미디어", "남", "1,300", "96개월", "84,283,000"),
                  _emp("미디어", "여", "980", "88개월", "73,150,000")])

# ── 픽스처: 이름이 합계가 아닌 합계행 ──────────────────────────────────────────────
HIDDEN_TOTAL_2025 = _ok([
    _emp("전사", "-", "1,000", "10.00", "60,000,000"),   # ← 사실은 합계행인데 표식이 없다
    _emp("국내", "-", "600", "11.00", "62,000,000"),
    _emp("해외", "-", "400", "8.50", "57,000,000"),
])


class Router:
    """`(corp_code, year)` → 응답. 라우트 밖은 013(조회 데이터 없음). 호출 URL 을 기록한다."""

    def __init__(self, routes: dict):
        self.routes = routes
        self.urls: list[str] = []

    def __call__(self, url: str) -> dict:
        self.urls.append(url)
        q = parse_qs(urlparse(url).query)
        return self.routes.get((q["corp_code"][0], int(q["bsns_year"][0])), NO_DATA)


ROUTES = {
    ("00126380", 2025): SAMSUNG_2025,
    ("00413046", 2025): CELLTRION_2025,
    ("00265324", 2018): CJENM_2018,
    ("00265324", 2019): CJENM_2019,
    ("00265324", 2020): CJENM_2020,
    ("00999999", 2025): HIDDEN_TOTAL_2025,
}


class FakeCursor:
    """무DB 계약용 커서. 실행된 (sql, params) 를 쌓고, SELECT 는 미리 준 행을 돌려준다."""

    def __init__(self, corps=(), employ_counts=()):
        self.corps = list(corps)
        self.employ_counts = list(employ_counts)
        self.calls: list[tuple[str, tuple]] = []
        self._result: list = []

    def execute(self, sql, params=()):
        self.calls.append((sql, tuple(params)))
        if "FROM TCORP_EMPLOY" in sql:
            self._result = list(self.employ_counts)
        elif "FROM TCORP" in sql:
            self._result = list(self.corps)
        else:
            self._result = []
        return 1

    def fetchall(self):
        return list(self._result)

    def fetchone(self):
        return self._result[0] if self._result else None

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        return False


class FakeConn:
    def __init__(self, cur):
        self._cur = cur
        self.committed = self.rolled_back = self.closed = False

    def cursor(self):
        return self._cur

    def commit(self):
        self.committed = True

    def rollback(self):
        self.rolled_back = True

    def close(self):
        self.closed = True


def _upserts(cur: FakeCursor) -> list[tuple]:
    """(CORP_CODE, BSNS_YEAR, SEGMENT_NM, SEX_CD, TOTAL_ROW_YN, HEADCNT, TENURE_YEAR,
    AVG_SALARY_AMT, RAW_TENURE_NM, RAW_SALARY_NM, RCEPT_NO)"""
    return [p for sql, p in cur.calls if "INSERT INTO TCORP_EMPLOY" in sql]


def _weighted(rows, field):
    """SP-MET-8 인원 가중평균 — **테스트용 참조 구현**이다. 진짜 집계는 생성기 한 곳에만 있고,
    여기서는 수집기가 저장한 행으로 SP-MET-1 검증값이 재현되는지만 확인한다."""
    pairs = [(r[field], r["headcount"]) for r in rows if r[field] is not None and r["headcount"]]
    return sum(v * n for v, n in pairs) / sum(n for _, n in pairs)


# ── SP-MET-7 근속 표기 5종 ───────────────────────────────────────────────────

@pytest.mark.parametrize("raw, expected", [
    ("11.70", 11.7),        # 년(소수)
    ("92개월", 7.67),        # 개월 — float() 하면 92년이 된다
    ("13년 6월", 13.5),      # 년 + 월
    ("6년 4개월", 6.33),     # 년 + 개월
    ("-", None),            # 없음 — 0 이 아니다
])
def test_MET7_tenure_years_parses_the_five_measured_forms(raw, expected):
    assert de.tenure_years(raw) == expected


@pytest.mark.parametrize("raw", ["92월", "13년", "1,092개월", " 11.70 ", None, "", "미상", "약 13년"])
def test_MET7_tenure_never_returns_zero_for_unreadable_text(raw):
    """읽지 못한 표기는 **None** 이다. 0 을 돌려주면 '근속 0년'이라는 거짓이 화면에 나가고,
    가중평균에 0 이 섞여 회사 전체 근속이 조용히 내려앉는다."""
    v = de.tenure_years(raw)
    assert v is None or v > 0


def test_MET7_month_form_is_not_read_as_years():
    """🚨 CJ ENM 함정: `92개월` 은 7.67년이지 92년이 아니다."""
    assert de.tenure_years("92개월") == 7.67
    assert de.tenure_years("92개월") != float("92")


# ── SP-MET-6 급여 단위 ───────────────────────────────────────────────────────

@pytest.mark.parametrize("raw, expected", [
    (83, 83_000_000),            # 백만원 단위 — CJ ENM 2019
    (96_000, 96_000_000),        # 천원 단위
    (96_000_000, 96_000_000),    # 원 단위 — CJ ENM 2018
    (157_064_509, 157_064_509),  # 삼성전자 2025 검증값
])
def test_MET6_salary_unit_is_restored_from_magnitude(raw, expected):
    assert de.salary_won(raw) == expected


@pytest.mark.parametrize("raw", [19_999_999, 500_000_001, 1_000_000_000, 800_000])
def test_MET6_salary_outside_valid_range_is_dropped_not_invented(raw):
    """타당 범위(2천만~5억) 밖은 **None**. 800,000 은 천원 단위로 복원하면 8억이라 범위 밖이다 —
    맞는 단위를 알 수 없으니 지어내지 않고 버린다(대신 개수를 센다)."""
    assert de.salary_won(raw) is None


@pytest.mark.parametrize("raw", [0, None, ""])
def test_MET6_zero_salary_is_missing_not_zero(raw):
    """공시에 '1인평균급여 0원'은 없다 — 0 은 결측의 다른 표기다."""
    assert de.salary_won(raw) is None


# ── SP-MET-5 합계행 판정 ─────────────────────────────────────────────────────

@pytest.mark.parametrize("fo_bbm, expected", [
    ("성별합계", True), ("성별 총계", True), ("합계", True),
    ("DX부문", False), ("생산직", False), ("", False), (None, False),
])
def test_MET5_total_row_is_decided_by_the_measured_marks(fo_bbm, expected):
    assert de.is_total_row(fo_bbm) is expected


def test_MET5_samsung_shaped_response_flags_only_the_two_total_rows():
    """부문행 4 + 성별합계 2. 합계행만 True 여야 하고, 원문은 여섯 줄 모두 남는다."""
    rows = de.extract_rows(SAMSUNG_2025)
    assert len(rows) == 6
    assert [r["total_row"] for r in rows] == [False, False, False, False, True, True]
    assert [r["segment"] for r in rows if r["total_row"]] == ["성별합계", "성별합계"]


def test_MET5_counting_every_row_doubles_the_headcount():
    """🚨 이 테스트가 지키는 사고 그 자체 — 다 더하면 257,762명, 합계행만 세면 128,881명."""
    rows = de.extract_rows(SAMSUNG_2025)
    assert sum(r["headcount"] for r in rows) == 257_762
    assert sum(r["headcount"] for r in de.aggregation_rows(rows)) == 128_881


def test_MET5_aggregation_rows_falls_back_to_segment_rows_when_no_total_row():
    """합계행이 없으면 부문행 전부가 집계 대상이다(셀트리온 3,153명)."""
    rows = de.extract_rows(CELLTRION_2025)
    picked = de.aggregation_rows(rows)
    assert len(picked) == len(rows)
    assert sum(r["headcount"] for r in picked) == 3_153


def test_MET1_samsung_checksum_is_reproducible_from_stored_rows():
    """SP-MET-1 검증값: 128,881명 · 157,064,509원 · 13.7년. 못 내면 구현이 틀린 것이다."""
    picked = de.aggregation_rows(de.extract_rows(SAMSUNG_2025))
    assert sum(r["headcount"] for r in picked) == 128_881
    assert round(_weighted(picked, "salary")) == 157_064_509
    assert round(_weighted(picked, "tenure"), 1) == 13.7


# ── SP-MET-5 합계행 미탐 검사 ─────────────────────────────────────────────────

def test_MET5_hidden_total_row_without_the_mark_is_caught_by_headcount():
    """표식이 없어도 인원이 말한다 — `전사` 1,000명 = 나머지(600+400)."""
    cands = de.find_hidden_totals(de.extract_rows(HIDDEN_TOTAL_2025))
    assert [c["segment"] for c in cands] == ["전사"]
    assert cands[0] == {"segment": "전사", "headcount": 1_000, "rest": 1_000}


def test_MET5_properly_marked_total_rows_do_not_trip_the_check():
    """삼성전자는 합계행이 이미 판정됐으므로 부문행(70,000 vs 58,881)만 남아 걸리지 않는다."""
    assert de.find_hidden_totals(de.extract_rows(SAMSUNG_2025)) == []


def test_MET5_celltrion_is_a_false_positive_and_only_the_human_list_clears_it():
    """🚨 오탐 실측: 생산직 1,565 vs 나머지 1,588 — 우연의 일치다.

    검사는 **걸어야 하고**(자동 제외 금지), 통과는 사람이 확인한 `KNOWN_NOT_TOTAL` 로만 이뤄진다.
    예외 항목에는 근거 문장이 붙어 있어야 한다 — 근거 없는 예외는 다음 사람이 지울 수도 늘릴 수도 없다.
    """
    cands = de.find_hidden_totals(de.extract_rows(CELLTRION_2025))
    assert [(c["segment"], c["headcount"], c["rest"]) for c in cands] == [("생산직", 1_565, 1_588)]
    waiver = de.KNOWN_NOT_TOTAL[(CELLTRION["corp_code"], "생산직")]
    assert "1,565" in waiver and "1,588" in waiver

    cur = FakeCursor()
    stats = de.collect(cur, [CELLTRION], api_key=KEY, base_year=2025, years=1,
                       fetch_fn=Router(ROUTES), sleep_sec=0)
    assert stats["suspects"] == [], "사람이 확인한 예외가 실패 목록에 다시 올라왔다"
    assert stats["waived"] == 1, "면제 건수를 세지 않으면 예외 목록이 조용히 눌러앉는다"


def test_MET5_waiver_is_scoped_to_the_company_and_segment():
    """예외는 그 회사의 그 부문에만 적용된다 — 다른 회사가 같은 이름을 써도 통과하지 않는다."""
    cur = FakeCursor()
    stats = de.collect(cur, [{"corp_code": "00111111", "corp_nm": "다른회사"}], api_key=KEY,
                       base_year=2025, years=1,
                       fetch_fn=Router({("00111111", 2025): CELLTRION_2025}), sleep_sec=0)
    assert [s["segment"] for s in stats["suspects"]] == ["생산직"]
    assert stats["waived"] == 0


# ── 원문 보존·결측 세기 ──────────────────────────────────────────────────────

def test_MET4_raw_text_is_kept_even_when_the_value_is_dropped():
    """규칙이 바뀌어도 재수집 없이 재계산하려면 원문이 남아야 한다(SP-MET-4).
    범위 밖 급여·규칙 밖 근속은 값이 NULL 이 되지만 **원문은 그대로** 저장된다."""
    r = de.parse_row(_emp("연구", "여", "10", "약 13년", "1,900,000,000"))
    assert r["tenure"] is None and r["raw_tenure"] == "약 13년"
    assert r["salary"] is None and r["raw_salary"] == "1,900,000,000"
    assert "tenure_unparsed" in r["notes"] and "salary_out_of_range" in r["notes"]


def test_MET7_dash_is_a_normal_absence_not_a_parse_failure():
    """`-` 는 5종 표기 중 하나다. 미파싱으로 세면 매 실행이 빨간불이 되어 진짜 이상이 묻힌다."""
    r = de.parse_row(_emp("연구", "여", "-", "-", "-"))
    assert r["notes"] == ["headcount_missing", "tenure_missing", "salary_missing"]
    assert (r["headcount"], r["tenure"], r["salary"]) == (None, None, None)


def test_collect_counts_out_of_range_salaries_and_keeps_a_sample():
    """SP-MET-6: 범위 밖으로 떨어진 행은 **개수를 세어 보고**한다(조용한 결측 금지)."""
    payload = _ok([_emp("A", "남", "100", "5.00", "1,900,000,000"),
                   _emp("B", "여", "100", "5.00", "80,000,000")])
    cur = FakeCursor()
    stats = de.collect(cur, [SAMSUNG], api_key=KEY, base_year=2025, years=1,
                       fetch_fn=Router({("00126380", 2025): payload}), sleep_sec=0)
    assert stats["notes"]["salary_out_of_range"] == 1
    assert any("범위 밖" in s and "삼성전자" in s for s in stats["samples"])
    assert de.format_notes(stats).startswith("  이상: ")
    assert "급여 범위밖 1" in de.format_notes(stats)


def test_collect_counts_duplicate_unique_keys_because_the_later_row_overwrites():
    """같은 (부문, 성별)이 두 번 오면 UNIQUE 때문에 뒤 행이 앞 행을 덮는다 — 사람이 조용히 사라진다."""
    payload = _ok([_emp("A", "남", "100", "5.00", "80,000,000"),
                   _emp("A", "남", "200", "6.00", "90,000,000")])
    cur = FakeCursor()
    stats = de.collect(cur, [SAMSUNG], api_key=KEY, base_year=2025, years=1,
                       fetch_fn=Router({("00126380", 2025): payload}), sleep_sec=0)
    assert stats["dup_keys"] == 1
    assert any("키 중복" in s for s in stats["samples"])


# ── 응답 상태 ────────────────────────────────────────────────────────────────

def test_extract_returns_none_for_013_no_data():
    assert de.extract_rows(NO_DATA) is None


def test_extract_raises_on_other_error_status():
    """요청 제한(020) 같은 상태를 조용히 '데이터 없음'으로 만들면 그날 수집이 통째로 빈다."""
    with pytest.raises(de.DartError):
        de.extract_rows({"status": "020", "message": "요청 제한을 초과하였습니다."})


# ── URL·키 ───────────────────────────────────────────────────────────────────

def test_build_url_carries_annual_report_params():
    q = parse_qs(urlparse(de.build_url(KEY, "00126380", 2025)).query)
    assert de.build_url(KEY, "00126380", 2025).startswith(de.API_URL)
    assert q["crtfc_key"] == [KEY] and q["corp_code"] == ["00126380"]
    assert q["bsns_year"] == ["2025"] and q["reprt_code"] == ["11011"]


def test_missing_key_fails_before_any_http_call():
    router = Router(ROUTES)
    with pytest.raises(de.DartError) as ei:
        de.collect(None, [SAMSUNG], api_key="", base_year=2025, fetch_fn=router, sleep_sec=0)
    assert router.urls == []
    assert "DART_API_KEY" in str(ei.value)


def test_fetch_failure_message_never_contains_the_key():
    def boom(url):
        raise OSError(f"connection refused for {url}")

    cur = FakeCursor()
    with pytest.raises(de.DartError) as ei:
        de.collect(cur, [SAMSUNG], api_key=KEY, base_year=2025, years=1, fetch_fn=boom, sleep_sec=0)
    assert KEY not in str(ei.value)
    assert "00126380" in str(ei.value)  # 어느 회사·연도에서 죽었는지는 말한다
    assert _upserts(cur) == []


# ── 수집 ─────────────────────────────────────────────────────────────────────

def test_collect_covers_eleven_years_by_default():
    """SP-MET-11: 기본 11개년(2015~2025). 재무처럼 5년으로 두면 그래프가 5칸짜리가 된다."""
    router = Router(ROUTES)
    stats = de.collect(FakeCursor(), [SAMSUNG], api_key=KEY, base_year=2025,
                       fetch_fn=router, sleep_sec=0)
    years = sorted(int(parse_qs(urlparse(u).query)["bsns_year"][0]) for u in router.urls)
    assert years == list(range(2015, 2026))
    assert de.YEARS_DEFAULT == 11
    assert stats["calls"] == 11 and stats["reports"] == 1 and stats["no_data"] == 10


def test_collect_stores_every_row_with_its_total_flag_and_raw_text():
    cur = FakeCursor()
    de.collect(cur, [SAMSUNG], api_key=KEY, base_year=2025, years=1,
               fetch_fn=Router(ROUTES), sleep_sec=0)
    rows = _upserts(cur)
    assert len(rows) == 6
    by_key = {(r[2], r[3]): r for r in rows}
    total_m = by_key[("성별합계", "남")]
    assert total_m[0:2] == ("00126380", 2025)
    assert total_m[4] is True and total_m[5] == 90_214
    assert (total_m[6], total_m[7]) == (14.5, 168_000_000)
    assert (total_m[8], total_m[9]) == ("14년 6월", "168,000,000")  # 원문 그대로
    assert total_m[10] == "20260311000123"
    assert by_key[("DX부문", "남")][4] is False


def test_MET6_cjenm_2019_million_unit_row_is_restored_to_won():
    """🚨 `83` → 8,300만원. 그대로 저장하면 2019년 평균연봉이 83원이 되고, 0 으로 채우면 그 해가
    조용히 빈다. 원문 `83` 은 그대로 남는다."""
    cur = FakeCursor()
    de.collect(cur, [CJENM], api_key=KEY, base_year=2020, years=3,
               fetch_fn=Router(ROUTES), sleep_sec=0)
    male = {r[1]: r for r in _upserts(cur) if r[3] == "남"}
    assert male[2018][7] == 96_000_000
    assert male[2019][7] == 83_000_000
    assert male[2019][9] == "83"
    assert male[2020][7] == 84_283_000
    assert male[2019][6] == 7.67 and male[2019][8] == "92개월"  # 92년이 아니다


def test_upsert_is_idempotent_on_the_unique_key():
    """재실행이 행을 늘리지 않는다 — UNIQUE `(CORP_CODE, BSNS_YEAR, SEGMENT_NM, SEX_CD)` 위 upsert.
    키 컬럼은 UPDATE 절에서 건드리지 않는다(건드리면 그건 다른 행을 만드는 것이다)."""
    sql = de._SQL_UPSERT
    assert "ON DUPLICATE KEY UPDATE" in sql
    assert "(CORP_CODE, BSNS_YEAR, SEGMENT_NM, SEX_CD," in sql
    for col in ("CORP_CODE", "BSNS_YEAR", "SEGMENT_NM", "SEX_CD"):
        assert f"{col} = new." not in sql

    first, second = FakeCursor(), FakeCursor()
    for cur in (first, second):
        de.collect(cur, [SAMSUNG], api_key=KEY, base_year=2025, years=1,
                   fetch_fn=Router(ROUTES), sleep_sec=0)
    assert _upserts(first) == _upserts(second)
    assert len({(r[0], r[1], r[2], r[3]) for r in _upserts(first)}) == len(_upserts(first))


# ── 결측 검사 ────────────────────────────────────────────────────────────────

def test_check_missing_lists_corps_without_countable_headcount():
    """행이 있어도 인원이 전부 NULL 이면 화면에는 아무것도 못 낸다 — 결측으로 센다."""
    cur = FakeCursor(employ_counts=[("00126380", 6), ("00265324", 0)])
    missing = de.check_missing(cur, 2025, [SAMSUNG, CJENM, CELLTRION])
    assert [(m["corp_nm"], m["year"]) for m in missing] == [("CJ ENM", 2025), ("셀트리온", 2025)]
    report = de.format_missing(missing)
    assert "CJ ENM" in report and "셀트리온" in report and "2025" in report


def test_load_corps_can_run_a_subset():
    cur = FakeCursor(corps=[("00126380", "삼성전자"), ("00413046", "셀트리온")])
    assert de.load_corps(cur, ["00413046"]) == [{"corp_code": "00413046", "corp_nm": "셀트리온"}]
    assert len(de.load_corps(cur)) == 2


# ── CLI ──────────────────────────────────────────────────────────────────────

def test_cli_refuses_without_key(monkeypatch, capsys):
    """키 없는 조용한 0건 수집은 하지 않는다(함정 (57)) — 종료 2, 호출 0."""
    monkeypatch.setattr(de, "_api_key", lambda: "")
    router = Router(ROUTES)
    assert de.main(["--base-year", "2025"], fetch_fn=router, conn=object()) == 2
    assert router.urls == []
    assert "DART_API_KEY" in capsys.readouterr().err


def test_cli_exits_1_on_hidden_total_suspect(monkeypatch, capsys):
    monkeypatch.setattr(de, "_api_key", lambda: KEY)
    cur = FakeCursor(corps=[(FAKECORP["corp_code"], FAKECORP["corp_nm"])],
                     employ_counts=[(FAKECORP["corp_code"], 3)])
    conn = FakeConn(cur)
    rc = de.main(["--base-year", "2025", "--years", "1", "--sleep", "0", "--corp", "00999999"],
                 fetch_fn=Router(ROUTES), conn=conn)
    out = capsys.readouterr()
    assert rc == 1
    assert "합계행 미탐 의심" in out.out and "전사" in out.out
    assert "KNOWN_NOT_TOTAL" in out.out  # 사람이 무엇을 해야 하는지까지 말한다
    assert conn.committed, "이상이 있어도 받은 것은 남긴다"
    assert KEY not in out.out + out.err


def test_cli_exits_1_when_the_latest_year_has_no_rows(monkeypatch, capsys):
    monkeypatch.setattr(de, "_api_key", lambda: KEY)
    cur = FakeCursor(corps=[("00126380", "삼성전자")], employ_counts=[])
    rc = de.main(["--base-year", "2025", "--years", "1", "--sleep", "0"],
                 fetch_fn=Router({}), conn=FakeConn(cur))
    out = capsys.readouterr().out
    assert rc == 1 and "결측 1건" in out and "삼성전자" in out


def test_cli_exits_0_and_always_prints_anomaly_counts(monkeypatch, capsys):
    """이상이 0 건이어도 줄을 찍는다 — '안 찍혔다'와 '0 이다'가 같아 보이면 안 된다."""
    monkeypatch.setattr(de, "_api_key", lambda: KEY)
    cur = FakeCursor(corps=[("00126380", "삼성전자")], employ_counts=[("00126380", 6)])
    conn = FakeConn(cur)
    rc = de.main(["--base-year", "2025", "--years", "1", "--sleep", "0"],
                 fetch_fn=Router(ROUTES), conn=conn)
    out = capsys.readouterr().out
    assert rc == 0
    assert "dart_employ done: corps=1 calls=1 reports=1 rows=6" in out
    assert "이상:" in out and "예외통과(KNOWN_NOT_TOTAL) 0" in out
    assert conn.committed and not conn.closed  # 주입한 커넥션은 호출자 소유 — 닫지 않는다


def test_cli_refuses_a_corp_code_that_is_not_in_tcorp(monkeypatch, capsys):
    """`--corp` 오타는 "calls=0 · 결측 0 · 종료 0" 이라 **성공과 구분되지 않는다** — 세워서 말한다."""
    monkeypatch.setattr(de, "_api_key", lambda: KEY)
    router = Router(ROUTES)
    cur = FakeCursor(corps=[("00126380", "삼성전자")])
    rc = de.main(["--base-year", "2025", "--years", "1", "--sleep", "0", "--corp", "00126381"],
                 fetch_fn=router, conn=FakeConn(cur))
    assert rc == 1 and router.urls == []
    assert "00126381" in capsys.readouterr().err


def test_cli_refuses_when_no_corp_is_loaded_at_all(monkeypatch, capsys):
    """TCORP 가 비었는데 조용히 0건 수집하고 성공을 찍으면, 다음 사람은 '수집했는데 없더라'로 읽는다."""
    monkeypatch.setattr(de, "_api_key", lambda: KEY)
    rc = de.main(["--base-year", "2025", "--years", "1", "--sleep", "0"],
                 fetch_fn=Router(ROUTES), conn=FakeConn(FakeCursor()))
    assert rc == 1 and "load_corp" in capsys.readouterr().err


def test_probe_summarises_one_call_without_touching_db(monkeypatch, capsys):
    """`--probe` 는 커서 없이 1회 호출 — 합계행 판정과 단위·근속 정규화 결과만 찍는다(SP-MET-11)."""
    monkeypatch.setattr(de, "_api_key", lambda: KEY)
    router = Router(ROUTES)
    rc = de.main(["--probe", "00126380", "--base-year", "2025"], fetch_fn=router, conn=None)
    out = capsys.readouterr().out
    assert rc == 0 and len(router.urls) == 1
    assert "합계행=2" in out
    assert "128,881명" in out                      # 합계행만 센 인원
    assert "'14년 6월'→14.5년" in out              # 근속 원문 → 정규화
    assert "'168,000,000'→168,000,000원" in out    # 급여 원문 → 정규화
    assert KEY not in out and "fyer_salary_totamt" not in out


def test_probe_reports_a_hidden_total_suspect_before_anything_is_stored(monkeypatch, capsys):
    monkeypatch.setattr(de, "_api_key", lambda: KEY)
    rc = de.main(["--probe", "00999999", "--base-year", "2025"], fetch_fn=Router(ROUTES), conn=None)
    out = capsys.readouterr().out
    assert rc == 0
    assert "합계행 미탐 의심" in out and "전사 1,000 vs 나머지 1,000" in out


def test_probe_shows_the_waiver_next_to_the_known_false_positive(monkeypatch, capsys):
    """스모크는 찾은 것을 감추지 않되, 수집이 왜 이걸 실패로 올리지 않는지 같은 줄에서 밝힌다."""
    monkeypatch.setattr(de, "_api_key", lambda: KEY)
    de.main(["--probe", CELLTRION["corp_code"], "--base-year", "2025"],
            fetch_fn=Router(ROUTES), conn=None)
    out = capsys.readouterr().out
    assert "합계행 미탐 의심: 생산직 1,565 vs 나머지 1,588" in out
    assert "예외 통과: 셀트리온" in out


def test_probe_exits_1_when_the_company_reported_nothing(monkeypatch, capsys):
    monkeypatch.setattr(de, "_api_key", lambda: KEY)
    assert de.main(["--probe", "00126380", "--base-year", "2011"],
                   fetch_fn=Router(ROUTES), conn=None) == 1
    assert "status=013" in capsys.readouterr().out


# ── 실 DB: DDL 수용·UNIQUE 멱등 ───────────────────────────────────────────────

def _mk_corp(conn, corp: dict) -> None:
    """FK 부모(TCORP)를 둔다. `seeded_db` 가 먼저 돌아 실 corp_code 가 이미 있을 수 있으므로
    upsert — 어차피 `clean_tx` 가 롤백한다."""
    with conn.cursor() as cur:
        cur.execute(
            "INSERT INTO TCORP (CORP_CODE, CORP_NM, STOCK_CD, ACCT_SET_CD, FS_DIV_CD) "
            "VALUES (%s, %s, NULL, 'general', 'CFS') AS new ON DUPLICATE KEY UPDATE CORP_NM = new.CORP_NM",
            (corp["corp_code"], corp["corp_nm"]),
        )


def _db_rows(conn, corp_code: str) -> list[tuple]:
    with conn.cursor() as cur:
        cur.execute(
            "SELECT SEGMENT_NM, SEX_CD, TOTAL_ROW_YN, HEADCNT, TENURE_YEAR, AVG_SALARY_AMT, "
            "RAW_TENURE_NM, RAW_SALARY_NM, RCEPT_NO FROM TCORP_EMPLOY "
            "WHERE CORP_CODE = %s AND BSNS_YEAR = 2025 ORDER BY SEGMENT_NM, SEX_CD",
            (corp_code,),
        )
        return cur.fetchall()


def test_db_ddl_accepts_what_the_collector_stores_and_rerun_is_idempotent(clean_tx):
    """🚨 재실행이 행을 늘리면 삼성전자가 다시 두 배가 된다 — 이번엔 UNIQUE 를 잘못 잡아서.

    `DECIMAL(5,2)`·`BOOLEAN`·`VARCHAR(50)` 을 실제로 통과시켜 본다. 파이썬 값이 그대로 돌아와야
    집계(SP-MET-8)가 저장 전 값으로 검증한 그 수를 낸다.
    """
    conn = clean_tx
    _mk_corp(conn, SAMSUNG)
    with conn.cursor() as cur:
        de.collect(cur, [SAMSUNG], api_key=KEY, base_year=2025, years=1,
                   fetch_fn=Router(ROUTES), sleep_sec=0)
        first = _db_rows(conn, SAMSUNG["corp_code"])
        de.collect(cur, [SAMSUNG], api_key=KEY, base_year=2025, years=1,
                   fetch_fn=Router(ROUTES), sleep_sec=0)
        second = _db_rows(conn, SAMSUNG["corp_code"])
    assert len(first) == 6
    assert first == second, "재실행이 행을 늘리거나 바꿨다 — UNIQUE 멱등이 깨졌다"
    by_key = {(r[0], r[1]): r for r in first}
    total_m = by_key[("성별합계", "남")]
    assert total_m[2] == 1 and total_m[3] == 90_214          # TOTAL_ROW_YN · HEADCNT
    assert float(total_m[4]) == 14.5 and total_m[5] == 168_000_000
    assert (total_m[6], total_m[7]) == ("14년 6월", "168,000,000")  # 원문 왕복
    assert by_key[("DX부문", "남")][2] == 0
    totals = [r for r in first if r[2] == 1]
    assert sum(r[3] for r in totals) == 128_881, "합계행만 세면 128,881 명이다(다 더하면 257,762)"


def test_db_check_missing_reads_countable_headcount_not_row_presence(clean_tx):
    """행이 아니라 **셀 수 있는 인원**을 본다. 2025 는 채워졌고 2024 는 보고서가 없어 결측이다."""
    conn = clean_tx
    _mk_corp(conn, SAMSUNG)
    with conn.cursor() as cur:
        de.collect(cur, [SAMSUNG], api_key=KEY, base_year=2025, years=1,
                   fetch_fn=Router(ROUTES), sleep_sec=0)
        assert de.check_missing(cur, 2025, [SAMSUNG]) == []
        missing = de.check_missing(cur, 2024, [SAMSUNG])
    assert [(m["corp_nm"], m["year"]) for m in missing] == [("삼성전자", 2024)]


# ── 법인 단위 커밋 (2026-08-28 실사고) ───────────────────────────────────────

def test_MET11_commits_after_every_corporation_so_a_crash_keeps_what_it_got():
    """끝에서 한 번만 커밋하면 1,100 호출 중 마지막에 죽었을 때 **0행**이 남는다 — 실제로 그랬다.

    법인이 경계인 이유: 그 안이 "한 회사의 연도들"이라 부분 상태가 의미를 갖는 최소 단위이고,
    UNIQUE upsert 라 재실행이 덮어쓴다.
    """
    marks = []
    de.collect(FakeCursor(), [SAMSUNG], api_key=KEY, base_year=2025, years=1,
               fetch_fn=Router(ROUTES), sleep_sec=0, commit=lambda: marks.append("c"))
    assert marks == ["c"], "법인 하나를 마쳤으면 한 번 커밋한다"


def test_MET11_without_a_commit_callback_nothing_is_committed():
    """무DB 테스트 경로는 커밋 콜백을 주지 않는다 — 그 경우 조용히 아무 일도 하지 않아야 한다."""
    de.collect(FakeCursor(), [SAMSUNG], api_key=KEY, base_year=2025, years=1,
               fetch_fn=Router(ROUTES), sleep_sec=0)  # commit 미전달 — 예외 없이 끝난다


def test_MET11_a_failure_in_the_second_corporation_keeps_the_first():
    """두 번째 법인에서 전송이 죽어도 첫 법인의 커밋은 이미 일어났다."""
    base = Router(ROUTES)

    def router(url):
        if parse_qs(urlparse(url).query)["corp_code"][0] == "00126380":
            return base(url)
        raise TimeoutError("timed out")

    marks = []
    with pytest.raises(de.DartError):
        de.collect(FakeCursor(), [SAMSUNG, CELLTRION], api_key=KEY, base_year=2025, years=1,
                   fetch_fn=router, sleep_sec=0, commit=lambda: marks.append("c"))
    assert marks == ["c"], "첫 법인은 이미 남았다"


# ── 합계행 판정: 실수집 검수로 배운 것 (2026-08-28) ──────────────────────────

def test_MET5_a_named_total_row_ends_the_hidden_total_search():
    """이름 붙은 합계행이 이미 있으면 '숨은 합계' 를 찾을 이유가 없다.

    이 규칙이 없으면 삼성전자 DS·삼성바이오 공정직처럼 **가장 큰 부문**이 매 실행 실패 목록에
    오른다(실수집 100법인에서 9건). 게이트가 영영 빨간불이면 아무도 안 보게 되고, 그때부터
    진짜 합계행도 같이 묻힌다 — 검사를 죽이는 가장 흔한 방법은 지우는 게 아니라 시끄럽게 두는 것이다.
    ⓘ 안전한 이유: 집계(`aggregation_rows`)는 합계행이 있으면 그 행만 세므로 두 배 사고가 성립하지 않는다.
    """
    rows = de.extract_rows(_ok([
        _emp("성별합계", "남", "100", "5.0", "50,000,000"),
        _emp("성별합계", "여", "100", "5.0", "50,000,000"),
        _emp("DS", "남", "100", "5.0", "50,000,000"),   # 부문 합 200 == 합계 200
        _emp("DS", "여", "100", "5.0", "50,000,000"),
    ]))
    assert de.find_hidden_totals(rows) == []
    assert [r["headcount"] for r in de.aggregation_rows(rows)] == [100, 100], "집계는 합계행만 센다"


def test_MET5_without_a_named_total_the_search_still_fires():
    """위 규칙이 검사를 통째로 끄지는 않는다 — 라벨이 없으면 그대로 걸린다."""
    rows = de.extract_rows(_ok([
        _emp("전사", "남", "200", "5.0", "50,000,000"),
        _emp("관리", "남", "120", "5.0", "50,000,000"),
        _emp("연구", "남", "80", "5.0", "50,000,000"),
    ]))
    assert [c["segment"] for c in de.find_hidden_totals(rows)] == ["전사"]


def test_MET5_known_total_lets_a_human_mark_an_unlabelled_total_row():
    """NC 2018 의 `전사` — 이름 규칙으로는 못 잡지만 사람이 확인한 진짜 합계행이다.

    전사 남 2,367 + 여 1,091 = 3,458 이고 관리사무직 1,090 + 연구개발 2,368 = 3,458 로 정확히 같다.
    표식을 못 고치면 그 회사는 인원이 영영 6,916 명(두 배)으로 남는다.
    """
    assert ("00261443", "전사") in de.KNOWN_TOTAL
    assert de.is_total_row("전사", "00261443") is True
    assert de.is_total_row("전사") is False, "corp_code 없이는 이름 규칙 그대로다"


def test_MET5_known_total_is_scoped_to_one_company_not_to_the_name():
    """⚠ `전사` 를 이름 규칙에 넣으면 같은 글자를 쓰는 **진짜 부문**까지 합계가 된다.

    실측 3,840행에서 `전사` 는 226번 쓰이고, 삼성전기 2015 의 `전사지원`(2,491명)은 나머지
    9,283명과 전혀 다른 부문이다. 그래서 예외는 이름이 아니라 **회사** 단위다.
    """
    assert de.is_total_row("전사", "00126371") is False, "다른 회사의 '전사' 는 부문이다"
    assert de.is_total_row("전사지원", "00261443") is False, "부분 문자열로 번지지 않는다"
    for (code, seg), why in de.KNOWN_TOTAL.items():
        assert len(code) == 8 and seg and len(why) > 20, (code, seg)


def test_MET5_known_total_actually_changes_the_aggregate():
    """예외가 집계까지 닿는가 — 안 닿으면 목록만 예쁘고 인원은 그대로 두 배다."""
    payload = _ok([
        _emp("관리사무직", "남", "1090", "5.6", "50,000,000"),
        _emp("연구개발", "남", "2368", "5.1", "50,000,000"),
        _emp("전사", "남", "3458", "5.2", "101,815,000"),
    ])
    plain = de.aggregation_rows(de.extract_rows(payload))
    marked = de.aggregation_rows(de.extract_rows(payload, "00261443"))
    assert sum(r["headcount"] for r in plain) == 6916, "예외 없이는 정확히 두 배다"
    assert sum(r["headcount"] for r in marked) == 3458
    assert de.find_hidden_totals(de.extract_rows(payload, "00261443")) == []


def test_MET5_every_waiver_carries_evidence_a_human_can_recheck():
    """근거 없는 예외는 다음 사람이 지울 수도 늘릴 수도 없다 — 두 목록 다 같은 규약이다."""
    for table in (de.KNOWN_NOT_TOTAL, de.KNOWN_TOTAL):
        for (code, seg), why in table.items():
            assert len(code) == 8, code
            assert any(ch.isdigit() for ch in why), f"{seg}: 근거에 숫자가 없다 — 되짚을 수 없는 문장이다"


def test_MET5_recollecting_a_year_replaces_it_instead_of_piling_up():
    """재수집은 그 회사·연도를 **통째로 갈아 끼운다**(2026-08-28 검토 확정).

    upsert 만으로는 부족하다: UNIQUE 키에 든 `SEGMENT_NM`·`SEX_CD` 가 DART 자유 텍스트라,
    부문명이 `"커머스부문"` → `"커머스 부문"` 으로 한 글자만 바뀌어도 키가 달라져 **새 행이 들어오고
    옛 행은 남는다.** 그러면 집계가 두 벌을 다 세어 인원이 늘고, 수집기는 종료 0·빌드는 무예외·
    화면에는 아무 표시도 없다 — SP-MET-5 가 막으려던 두 배 사고의 다른 입구다.
    """
    cur = FakeCursor()
    de.collect(cur, [SAMSUNG], api_key=KEY, base_year=2025, years=1,
               fetch_fn=Router(ROUTES), sleep_sec=0)
    deletes = [(sql, prm) for sql, prm in cur.calls if sql.startswith("DELETE")]
    assert deletes == [(de._SQL_DELETE_YEAR, ("00126380", 2025))]
    # 순서가 계약이다 — 지우고 나서 쓴다.
    kinds = [sql.split()[0] for sql, _ in cur.calls]
    assert kinds.index("DELETE") < kinds.index("INSERT")


def test_MET5_a_year_without_a_report_is_never_deleted():
    """⚠ 응답이 없는 해(013)를 지우면 재수집이 **멀쩡한 과거 데이터를 날리는 도구**가 된다.

    보고서를 못 받았을 때 지워 버리면, 일시적으로 DART 가 013 을 주는 날 그 해가 사라지고
    다음 빌드에서 조용히 빈칸이 된다.
    """
    cur = FakeCursor()
    de.collect(cur, [SAMSUNG], api_key=KEY, base_year=2024, years=1,  # ROUTES 에 2024 없음 → 013
               fetch_fn=Router(ROUTES), sleep_sec=0)
    assert [sql for sql, _ in cur.calls if sql.startswith("DELETE")] == []
