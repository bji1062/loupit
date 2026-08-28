"""SP-MET-5·6·7 — DART 직원현황 수집기: OpenDART `empSttus` → TCORP_EMPLOY.

근거: `docs/SPEC/17-회사정보-지표.md` SP-MET-4~7·SP-MET-11 · `dart_finance.py`(같은 골격·같은 규약).

**원문을 그대로 남긴다**(`RAW_TENURE_NM`·`RAW_SALARY_NM`). 아래 정규화 규칙은 앞으로 또 틀릴 것이고,
그때 1,100회 재수집 없이 다시 계산할 수 있어야 한다(SP-MET-4). 저장하는 것은 해석이고, 원문은 근거다.

🚨 **세 함정이 이 파일의 존재 이유다 — 전부 2026-08-28 DART 전수 실측이다.**

  1. **합계행**(SP-MET-5): 7사(삼성전자·LG전자·삼성물산·삼성바이오로직스·삼성전기·현대글로비스·
     효성중공업)가 부문행과 합계행을 **함께** 낸다. 그대로 더하면 삼성전자가 128,881 → **257,762 명**
     이 된다. `fo_bbm` 에 `합계`·`총계` 가 있으면 합계행으로 찍고(`TOTAL_ROW_YN`), 집계는 합계행이
     하나라도 있으면 합계행만 센다(`aggregation_rows`). 더 무서운 것은 **이름이 합계가 아닌 합계행**
     이라, 인원 합으로 되짚어 검사하고(`find_hidden_totals`) 걸리면 종료 코드 1 로 사람을 부른다.
  2. **급여 단위**(SP-MET-6): 같은 회사가 해마다 단위를 바꾼다. CJ ENM 은 `96,000,000`(2018, 원) ·
     `83`(2019, 백만원) · `84,283,000`(2020, 원). 자릿수로 단위를 복원하지 않으면 **2019년 평균연봉만
     조용히 0 원**이 된다 — 에러는 나지 않는다.
  3. **근속 표기**(SP-MET-7): `11.70` · `92개월` · `13년 6월` · `6년 4개월` · `-` 다섯 벌이 섞여 온다.
     `float()` 로 캐스팅하면 CJ ENM 이 **92년 근속**이 된다.

**없으면 NULL 이지 0 이 아니다.** 파싱 실패·타당 범위(2천만~5억) 밖은 NULL 로 두고 **개수를 세어
찍는다**. 0 으로 채우면 화면에 "평균연봉 0원"이라는 거짓이 나가고, 세지 않고 버리면 아무도 모른다.

⛔ **`fyer_salary_totamt`(연간급여총액)는 읽지도 저장하지도 않는다**(SP-MET-8). CJ CGV 는
`총액/인원` 이 공시 1인평균과 **4.8배** 어긋난다 — 저장해 두면 언젠가 누가 그걸로 계산한다.
성별(`sexdstn`)은 UNIQUE 키와 집계에만 쓰고 **화면에는 내지 않는다**(사용자 결정 2026-08-28).

**키가 없으면 즉시 실패한다.** 조용한 0건은 "수집했는데 없더라"로 읽힌다(함정 (57)). 키는
`server/.env DART_API_KEY` 이고 **로그·예외 메시지에 찍지 않는다**.

HTTP 는 `fetch_fn(url) -> dict` 주입(기본 urllib, 새 의존성 0) — 테스트는 픽스처로 무접촉.
멱등: `(CORP_CODE, BSNS_YEAR, SEGMENT_NM, SEX_CD)` UNIQUE 위 upsert. 재실행은 안전하다.
호출량: 100사 × 11년 = **1,100**(재무 2,200 과 합쳐 3,300 / 일 20,000 안). 호출 간 `sleep_sec`.

CLI: `python3 db/seed/dart_employ.py [--base-year 2025] [--years 11] [--corp 00126380 …] [--sleep 0.1]`
  종료 코드 0 = 결측·이상 0 · 1 = 있음(목록 출력) · 2 = 설정 오류(키 없음).
  `--probe 00126380 [--base-year 2025]` = **DB 무접촉** 1회 호출 스모크 — 합계행 판정과 단위·근속
  정규화 결과만 요약해 찍는다. 응답 원문·키는 출력하지 않는다.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
import time
import urllib.parse
import urllib.request

import dart_http
from pathlib import Path

SEED_DIR = Path(__file__).resolve().parent
ROOT = SEED_DIR.parents[1]
if str(SEED_DIR) not in sys.path:
    sys.path.insert(0, str(SEED_DIR))

# 금액 문자열 규칙(쉼표·'-'·빈 문자열·형식 오류)은 **한 곳에만** 둔다. 두 벌이 되면 반드시 갈라진다
# — 같은 규칙을 두 언어로 나눠 적었다가 배지가 조용히 죽은 적이 있다(배지 함정).
from dart_finance import DartError, parse_amount  # noqa: E402  # db/seed/dart_finance.py

API_URL = "https://opendart.fss.or.kr/api/empSttus.json"
REPRT_ANNUAL = "11011"  # 사업보고서 — 직원현황은 사업보고서에만 실린다
YEARS_DEFAULT = 11  # SP-MET-11. 2015~2025 11개년이 전부 조회된다(SP-MET-1 실측)
SLEEP_DEFAULT = 0.1

_STATUS_OK = "000"
_STATUS_NO_DATA = "013"

# 타당 범위(SP-MET-6) — 상장사 1인평균급여. 밖으로 나가면 **지어내지 않고 결측**으로 둔다.
SALARY_MIN, SALARY_MAX = 20_000_000, 500_000_000

# 합계행 표식. 실측 표기는 `성별합계`·`성별 총계` 라 부분 문자열로 본다(공백·접두사가 회사마다 다르다).
TOTAL_ROW_MARKS = ("합계", "총계")

# 합계행 미탐 검사의 허용 오차(SP-MET-5). **정확히 같을 때만 잡으면 놓친다** — 합계행이 임원·기타를
# 포함해 부문 합과 몇 명 어긋나는 공시가 있다. 그래서 5% 안이면 후보로 올리고, 대신 오탐을 사람이
# 걷어낸다(`KNOWN_NOT_TOTAL`). 놓치면 인원이 두 배가 되지만, 오탐은 목록 한 줄일 뿐이다.
TOTAL_MATCH_TOL = 0.05

# 🚨 사람이 확인한 예외만 여기 넣는다. 자동 제외 금지 — 자동으로 빠지기 시작하면 검사가 없는 것과 같다.
# 키는 `(corp_code, fo_bbm)` 이다. 연도를 넣지 않은 이유: 같은 인력 구성이면 다음 해에도 그대로
# 걸리는데, 해마다 다시 승인하게 만들면 사람이 목록에 연도만 늘리고 근거는 안 본다.
# 대신 **면제된 건수를 매 실행 요약에 찍어** 예외가 조용히 눌러앉는 것을 막는다.
KNOWN_NOT_TOTAL = {
    # 셀트리온(2026-08-28 사람 확인): 생산직 1,565명 vs 나머지 부문 합 1,588명 — 1.4% 차라 위 오차
    # 안에 들어오지만 **우연의 일치**다. 공시 원문에 합계행이 아예 없고, 생산직은 부문행 중 하나다.
    ("00413046", "생산직"): "셀트리온 생산직 1,565 vs 나머지 1,588 — 합계행 아님(2026-08-28 원문 확인)",
    # ── 아래는 2026-08-28 **실수집 100법인 × 11개년** 검수에서 확인한 근사 일치들이다.
    # 전부 이름 붙은 합계행이 없는 회사·연도라 검사에 걸렸고, 원문을 보면 **부문 중 하나**다.
    # (정확히 일치한 것은 두 건뿐이었고 그중 진짜 합계행은 NC `전사` 하나다 — `KNOWN_TOTAL` 참고.)
    ("00265324", "방송사업"): "CJ ENM 방송사업 2019 1,824 vs 나머지 1,856 · 2020 1,681 vs 1,722 — 6개 부문 중 하나",
    ("00164645", "육상직"): "HMM 2015 육상직 845 vs 해상직 810 — 부문이 둘뿐이라 서로가 '나머지'가 된다",
    ("00164645", "해상직"): "HMM 2015 해상직 810 vs 육상직 845 — 위와 같은 쌍의 반대편",
    ("00105952", "재경/지원부문"): "LS 2015 재경/지원부문 34 == 전략기획 18 + 인재육성 16 — 정확히 같지만 우연(3개 부문 중 하나)",
    ("00302926", "철도부문"): "현대로템 철도부문 2015·2017~2019·2022 — 4개 부문 중 가장 큰 하나, 합계행 아님",
}

# 🚨 반대 방향의 예외 — **이름이 합계가 아닌데 사람이 합계행이라고 확인한 것.**
# `KNOWN_NOT_TOTAL` 만 있으면 검사에 걸린 진짜 합계행을 통과시킬 방법이 없고, 그 회사는 인원이
# 영영 두 배로 남는다(검사는 매번 빨간불인데 고칠 손잡이가 없는 상태). 키는 같은 `(corp_code, fo_bbm)`.
# ⚠ 이름 규칙(`TOTAL_ROW_MARKS`)에 `전사` 를 넣지 **않은** 이유: 실측 3,840행에서 `전사` 는 226번
#   쓰이고 그중 127 회사·연도는 그 행 하나뿐이며, 삼성전기 2015 의 `전사지원`(2,491명)은 나머지
#   9,283명과 전혀 다른 **진짜 부문**이다. 이름으로 일괄 판정하면 그런 부문을 합계로 오판한다.
KNOWN_TOTAL = {
    # NC(2026-08-28 사람 확인): 2018 만 `전사` 표기를 썼다(2019~2024 는 `성별합계`, 2025 는 단독).
    # 전사 남 2,367 + 여 1,091 = 3,458 이고 관리사무직 1,090 + 연구개발 2,368 = 3,458 로 **정확히**
    # 같다 — 다 더하면 6,916 명(정확히 두 배). 급여도 전사행에만 있고 부문행은 NULL 이다.
    ("00261443", "전사"): "NC 2018 전사 3,458 == 관리사무직 1,090 + 연구개발 2,368 (2026-08-28 원문 확인)",
}

_SQL_UPSERT = (
    "INSERT INTO TCORP_EMPLOY (CORP_CODE, BSNS_YEAR, SEGMENT_NM, SEX_CD, TOTAL_ROW_YN, HEADCNT, "
    "TENURE_YEAR, AVG_SALARY_AMT, RAW_TENURE_NM, RAW_SALARY_NM, RCEPT_NO) "
    "VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s) AS new "
    "ON DUPLICATE KEY UPDATE TOTAL_ROW_YN = new.TOTAL_ROW_YN, HEADCNT = new.HEADCNT, "
    "TENURE_YEAR = new.TENURE_YEAR, AVG_SALARY_AMT = new.AVG_SALARY_AMT, "
    "RAW_TENURE_NM = new.RAW_TENURE_NM, RAW_SALARY_NM = new.RAW_SALARY_NM, RCEPT_NO = new.RCEPT_NO"
)
# 🚨 재수집은 **그 회사·그 연도를 통째로 갈아 끼운다**(2026-08-28 검토 확정).
# upsert 만으로는 부족하다: UNIQUE 키가 `(CORP_CODE, BSNS_YEAR, SEGMENT_NM, SEX_CD)` 인데
# `SEGMENT_NM`·`SEX_CD` 는 DART 자유 텍스트다. 회사가 정정공시를 내거나 부문명을 `"커머스부문"`
# → `"커머스 부문"` 처럼 한 글자만 바꾸면 **키가 달라져 새 행이 들어오고 옛 행은 남는다.**
# 그러면 집계(`generator/employ.py::aggregate`)가 두 벌을 다 세어 인원이 늘어난다 — SP-MET-5 가
# 막으려던 "정확히 두 배" 사고가 정정공시라는 다른 문으로 그대로 재현되고, 수집기는 종료 0,
# 빌드는 예외 없음, 화면에는 아무 표시도 없다.
# ⚠ 지우는 시점은 **쓸 행을 이미 손에 쥔 뒤**다. 응답이 없거나(013) 실패한 해를 먼저 지우면
#   재수집이 멀쩡한 과거 데이터를 날리는 도구가 된다.
_SQL_DELETE_YEAR = "DELETE FROM TCORP_EMPLOY WHERE CORP_CODE = %s AND BSNS_YEAR = %s"
_SQL_CORPS = "SELECT CORP_CODE, CORP_NM FROM TCORP ORDER BY CORP_NM"
# 결측 검사는 "행이 있느냐"가 아니라 "**셀 수 있는 인원이 있느냐**"로 본다. 보고서는 봤는데 인원이
# 전부 NULL 인 회사는 행이 있어도 화면에는 아무것도 못 낸다.
_SQL_YEAR_COUNTS = (
    "SELECT CORP_CODE, COUNT(HEADCNT) FROM TCORP_EMPLOY WHERE BSNS_YEAR = %s GROUP BY CORP_CODE"
)

# 이상 표식 → 요약에 찍을 한국어 라벨. 표식이 늘면 여기에도 넣어라(없으면 표식 그대로 찍힌다).
NOTE_LABELS = {
    "salary_out_of_range": "급여 범위밖",
    "salary_unparsed": "급여 형식오류",
    "salary_missing": "급여 원문 없음",
    "tenure_unparsed": "근속 미파싱",
    "tenure_missing": "근속 원문 없음",
    "headcount_unparsed": "인원 형식오류",
    "headcount_missing": "인원 없음",
    "truncated": "원문 잘림",
}
_SAMPLE_LIMIT = 20  # 표본은 사람이 읽는 용도다. 전량을 찍으면 아무도 안 읽는다 — 개수는 따로 전부 센다.


# ── 순수 파서 ────────────────────────────────────────────────────────────────

# "13년 6월" · "6년 4개월" · "13년"  (월이 없어도 받는다)
_RE_TENURE_YM = re.compile(r"^(?P<y>\d+(?:\.\d+)?)\s*년\s*(?:(?P<m>\d+(?:\.\d+)?)\s*(?:개월|월))?$")
# "92개월" · "92월"
_RE_TENURE_M = re.compile(r"^(?P<m>\d+(?:\.\d+)?)\s*(?:개월|월)$")
# "11.70" · "12"
_RE_TENURE_NUM = re.compile(r"^\d+(?:\.\d+)?$")
_BLANKS = ("", "-", "–", "—", "N/A", "n/a")


def tenure_years(raw) -> float | None:
    """근속 원문 → 년(float). 규칙에 없는 표기는 **None**(0 이 아니다 — 0년 근속은 거짓이다).

    5종 실측(SP-MET-7): `11.70` · `92개월` · `13년 6월` · `6년 4개월` · `-`.
    `float()` 한 방으로 처리하면 `92개월` 이 **92년**이 되어 화면에서 그 회사만 극단값이 된다.
    소수 2자리로 맞추는 이유: 컬럼이 `DECIMAL(5,2)` 라 어차피 DB 가 반올림한다. 여기서 미리 맞추면
    저장 전 값과 저장 후 값이 같아 테스트가 DB 왕복 없이 같은 수를 본다.
    """
    if raw is None:
        return None
    s = str(raw).replace("\u00a0", " ").replace(",", "").strip()
    if s in _BLANKS:
        return None
    m = _RE_TENURE_YM.match(s)
    if m:
        return round(float(m.group("y")) + float(m.group("m") or 0) / 12, 2)
    m = _RE_TENURE_M.match(s)
    if m:
        return round(float(m.group("m")) / 12, 2)
    if _RE_TENURE_NUM.match(s):
        return round(float(s), 2)
    return None


def salary_won(v) -> int | None:
    """1인평균급여 → 원(int). 자릿수로 단위를 복원하고, 타당 범위 밖은 **None**(SP-MET-6).

    회사가 해마다 원/천원/백만원을 바꾸는데 응답에는 단위가 없다. 그래서 크기로 되짚는다 —
    상장사 1인평균이 1천만원(백만원 단위) 미만일 수 없고, 1백만(천원 단위) 미만일 수도 없다.
    범위 밖(2천만~5억)은 **고쳐 쓰지 않고 버린다**. 지어낸 값 하나가 회사 페이지 전체를 거짓으로
    만든다 — 대신 버린 개수를 센다(`salary_out_of_range`).
    """
    if not v:  # None·0 — 공시에 "1인평균급여 0원"은 없다. 0 은 결측의 다른 표기다.
        return None
    if v < 1_000:  # 백만원 단위 — CJ ENM 2019 의 `83`
        v *= 1_000_000
    elif v < 1_000_000:  # 천원 단위
        v *= 1_000
    return int(v) if SALARY_MIN <= v <= SALARY_MAX else None


def is_total_row(fo_bbm, corp_code: str | None = None) -> bool:
    """`fo_bbm` 이 합계행인가(SP-MET-5). 실측 표기는 `성별합계`·`성별 총계`.

    부분 문자열로 보는 이유: 접두사·공백이 회사마다 다르다. 반대로 이름에 `합계` 가 든 **부문**을
    합계행으로 오판할 여지가 있지만, 실측 100사에는 없었고 오판의 방향이 안전하다 —
    합계행으로 찍히면 그 행만 세므로 인원이 두 배가 되는 사고(이 검사의 목적)는 나지 않는다.

    `corp_code` 가 있으면 **사람이 확인한 예외**(`KNOWN_TOTAL`)를 먼저 본다. 이름 규칙으로는
    잡을 수 없는 표기(NC 2018 의 `전사`)를 회사 단위로만 통과시키기 위한 손잡이다 —
    그 이름을 규칙에 넣으면 같은 글자를 쓰는 진짜 부문(삼성전기 `전사지원`)까지 합계가 된다.
    """
    if corp_code and (corp_code, str(fo_bbm or "")) in KNOWN_TOTAL:
        return True
    return any(mark in str(fo_bbm or "") for mark in TOTAL_ROW_MARKS)


def aggregation_rows(rows: list[dict]) -> list[dict]:
    """집계 대상 행 선택(SP-MET-5): **합계행이 하나라도 있으면 합계행만**, 없으면 부문행 전부.

    수집기와 생성기가 이 규칙을 따로 적으면 언젠가 갈라진다 — 규칙은 여기 하나만 둔다.
    """
    totals = [r for r in rows if r["total_row"]]
    return totals if totals else list(rows)


def find_hidden_totals(rows: list[dict]) -> list[dict]:
    """이름이 합계가 아닌 합계행 후보(SP-MET-5 필수 검사).

    합계행으로 판정되지 **않은** 부문 중, 그 부문 인원 합이 나머지 전부와 사실상 같은 것을 고른다.
    같다는 것은 그 행이 사실은 합계라는 뜻이고, 그대로 두면 그 회사 인원이 두 배가 된다.
    반환은 후보 목록일 뿐 판정이 아니다 — 걸린 건은 사람이 원문을 보고 `KNOWN_NOT_TOTAL` 로
    통과시키거나 표식을 고친다. 자동 제외는 하지 않는다.
    """
    if any(r["total_row"] for r in rows):
        # 합계행이 **이미 식별돼 있다.** 이 검사의 목적은 '이름이 합계가 아닌 합계행'을 찾는 것이고,
        # 라벨이 붙은 합계행이 있으면 집계는 그 행만 세므로(`aggregation_rows`) 인원이 두 배가 되는
        # 사고 자체가 성립하지 않는다. 이 줄이 없으면 삼성전자 DS·삼성바이오 공정직처럼 **가장 큰
        # 부문**이 매 실행 실패 목록에 오르고(2026-08-28 실수집에서 9건), 게이트가 영영 빨간불이라
        # 아무도 안 보게 된다 — 그때부터 진짜 합계행도 같이 묻힌다.
        return []
    sums: dict[str, int] = {}
    for r in rows:
        if r["total_row"] or r["headcount"] is None:
            continue
        sums[r["segment"]] = sums.get(r["segment"], 0) + r["headcount"]
    if len(sums) < 2:  # 부문이 하나면 "나머지"가 없다 — 비교 자체가 성립하지 않는다
        return []
    grand = sum(sums.values())
    out = []
    for seg, n in sorted(sums.items()):
        rest = grand - n
        if n <= 0 or rest <= 0:
            continue
        if abs(n - rest) <= TOTAL_MATCH_TOL * max(n, rest):
            out.append({"segment": seg, "headcount": n, "rest": rest})
    return out


def build_url(api_key: str, corp_code: str, year: int) -> str:
    q = urllib.parse.urlencode({
        "crtfc_key": api_key, "corp_code": corp_code, "bsns_year": str(year),
        "reprt_code": REPRT_ANNUAL,
    })
    return f"{API_URL}?{q}"


def default_fetch(url: str, timeout: float = 20.0) -> dict:
    """GET → JSON dict. 일시적 실패는 `dart_http` 가 재시도하고, 최종 예외는 호출자(collect)가
    키를 가린 채 감싼다. 재시도 정책을 여기 적지 않는 이유는 그 모듈 머리말 참고."""
    return dart_http.fetch_json(url, timeout=timeout, user_agent="loupit-dart-employ/1.0")


def _fit(s: str | None, limit: int, notes: list[str]) -> str | None:
    """컬럼 길이에 맞춘다. `RAW_*` 는 VARCHAR(50) 이고 strict 모드에서 초과는 **에러**라,
    한 행 때문에 1,100회 수집이 죽는다. 자르되 잘랐다는 사실을 남긴다(조용히 자르지 않는다)."""
    if s is not None and len(s) > limit:
        notes.append("truncated")
        return s[:limit]
    return s


def _text(v) -> str | None:
    s = None if v is None else str(v).replace("\u00a0", " ").strip()
    return None if s in (None, "") else s


def parse_row(item: dict, corp_code: str | None = None) -> dict:
    """`empSttus` 행 하나 → 저장 형태. 해석과 **원문을 함께** 담는다.

    `notes` 는 이 행에서 일어난 이상·결측의 표식이다 — 값을 조용히 비우고 끝내지 않기 위한 장치이고,
    호출자가 세어서 요약에 찍는다.
    """
    notes: list[str] = []
    segment = _fit(_text(item.get("fo_bbm")) or "", 200, notes)
    sex = _fit(_text(item.get("sexdstn")) or "", 10, notes)
    raw_tenure = _fit(_text(item.get("avrg_cnwk_sdytrn")), 50, notes)
    raw_salary = _fit(_text(item.get("jan_salary_am")), 50, notes)

    headcount = None
    try:
        headcount = parse_amount(item.get("sm"))
    except ValueError:  # 숫자가 아닌 인원 — 던지지 않고 세어 둔다(한 행이 1,100회 수집을 죽이지 않게)
        notes.append("headcount_unparsed")
    else:
        if headcount is None:
            notes.append("headcount_missing")

    tenure = None
    if raw_tenure is None:
        notes.append("tenure_missing")
    else:
        tenure = tenure_years(raw_tenure)
        if tenure is None:
            # `-` 는 5종 표기 중 하나다(SP-MET-7) — **정상적인 결측**이지 규칙 실패가 아니다.
            # 둘을 한 칸에 세면 매 실행이 빨간불이 되어 진짜 미파싱 표기가 묻힌다.
            notes.append("tenure_missing" if raw_tenure in _BLANKS else "tenure_unparsed")

    salary = None
    if raw_salary is None:
        notes.append("salary_missing")
    else:
        try:
            amount = parse_amount(raw_salary)
        except ValueError:
            notes.append("salary_unparsed")
        else:
            salary = salary_won(amount)
            if salary is None:
                # 단위 복원 뒤에도 2천만~5억 밖이면 버린 개수를 센다(SP-MET-6). `0`·`-` 는 결측 쪽이다.
                notes.append("salary_out_of_range" if amount else "salary_missing")

    return {
        "segment": segment, "sex": sex, "total_row": is_total_row(segment, corp_code),
        "headcount": headcount, "tenure": tenure, "salary": salary,
        "raw_tenure": raw_tenure, "raw_salary": raw_salary,
        "rcept_no": _text(item.get("rcept_no")), "notes": notes,
    }


def extract_rows(payload: dict, corp_code: str | None = None) -> list[dict] | None:
    """응답 → 행 목록. 013(조회 데이터 없음) → None. 그 외 오류 상태는 예외.

    응답이 비었는지(`None`)와 "보고서는 있는데 값이 없다"(행은 있고 값이 NULL)를 구분한다 —
    이 구분이 없으면 나중에 "수집을 안 한 건지 회사가 안 낸 건지" 아무도 모른다.
    """
    status = str(payload.get("status", ""))
    if status == _STATUS_NO_DATA:
        return None
    if status != _STATUS_OK:
        raise DartError(f"DART 응답 오류 status={status} — {payload.get('message', '')}")
    items = payload.get("list") or []
    if not items:
        return None
    return [parse_row(it, corp_code) for it in items]


def _report_rcept_no(rows: list[dict]) -> str | None:
    for r in rows:
        if r.get("rcept_no"):
            return r["rcept_no"]
    return None


# ── 수집 ─────────────────────────────────────────────────────────────────────

def load_corps(cur, corp_codes: list[str] | None = None) -> list[dict]:
    """TCORP → 수집 대상 목록. `corp_codes` 로 부분 실행."""
    cur.execute(_SQL_CORPS)
    corps = [{"corp_code": c, "corp_nm": nm} for c, nm in cur.fetchall()]
    if corp_codes:
        wanted = set(corp_codes)
        corps = [c for c in corps if c["corp_code"] in wanted]
    return corps


def _new_stats() -> dict:
    return {"calls": 0, "reports": 0, "rows": 0, "no_data": 0, "dup_keys": 0, "waived": 0,
            "notes": {}, "samples": [], "suspects": []}


def _sample(stats: dict, line: str) -> None:
    if len(stats["samples"]) < _SAMPLE_LIMIT:
        stats["samples"].append(line)


def collect(cur, corps: list[dict], *, api_key: str, base_year: int, years: int = YEARS_DEFAULT,
            fetch_fn=default_fetch, sleep_sec: float = SLEEP_DEFAULT, commit=None) -> dict:
    """법인 목록 × 최근 `years`개년을 받아 TCORP_EMPLOY 에 upsert (커밋은 호출자 몫).

    보고서가 있으면 **받은 행을 전부** 쓴다 — 합계행도 부문행도, 값이 NULL 인 행도. 어느 행을 셀지는
    저장이 아니라 집계(`aggregation_rows`)의 결정이고, 저장 단계에서 버리면 규칙이 바뀔 때 되돌릴 수
    없다. 접수번호가 빈 행에는 같은 보고서의 접수번호를 채운다(어느 공시를 봤는지가 남아야 한다).
    """
    if not api_key:
        raise DartError("DART_API_KEY 미설정 — server/.env 에 넣어라. 키 없이 0건 수집은 허용하지 않는다")
    stats = _new_stats()
    for corp in corps:
        code, nm = corp["corp_code"], corp.get("corp_nm", "")
        for year in range(base_year - years + 1, base_year + 1):
            url = build_url(api_key, code, year)
            try:
                payload = fetch_fn(url)
            except Exception as exc:  # noqa: BLE001 — 전송 계층 전부: 키를 가리고 다시 던진다
                detail = str(exc).replace(api_key, "***")
                raise DartError(f"DART 호출 실패 — {nm}({code}) {year}: {type(exc).__name__}: {detail}") from None
            stats["calls"] += 1
            if sleep_sec:
                time.sleep(sleep_sec)
            try:
                rows = extract_rows(payload, code)
            except DartError as exc:
                raise DartError(f"{nm}({code}) {year}: {exc}") from None
            if rows is None:
                stats["no_data"] += 1
                continue
            stats["reports"] += 1
            # 이 해를 통째로 갈아 끼운다(`_SQL_DELETE_YEAR` 주석). 여기까지 왔다는 것은 쓸 행을
            # 이미 손에 쥐었다는 뜻이라, 지운 자리는 바로 아래에서 반드시 다시 채워진다.
            cur.execute(_SQL_DELETE_YEAR, (code, year))
            rcept = _report_rcept_no(rows)
            seen: set[tuple[str, str]] = set()
            for r in rows:
                key = (r["segment"], r["sex"])
                if key in seen:
                    # UNIQUE (CORP_CODE, BSNS_YEAR, SEGMENT_NM, SEX_CD) 라 **뒤 행이 앞 행을 덮는다**.
                    # 에러 없이 사람이 사라지는 자리다 — 세고 표본을 남겨 사람이 원문을 보게 한다.
                    stats["dup_keys"] += 1
                    _sample(stats, f"{nm}({code}) {year} 키 중복 {key} — 앞 행이 덮인다(UNIQUE)")
                seen.add(key)
                for note in r["notes"]:
                    stats["notes"][note] = stats["notes"].get(note, 0) + 1
                if "salary_out_of_range" in r["notes"]:
                    _sample(stats, f"{nm}({code}) {year} {r['segment']}/{r['sex']} "
                                   f"급여 원문 {r['raw_salary']!r} → 범위 밖이라 NULL")
                if "tenure_unparsed" in r["notes"]:
                    _sample(stats, f"{nm}({code}) {year} {r['segment']}/{r['sex']} "
                                   f"근속 원문 {r['raw_tenure']!r} → 5종 규칙 밖이라 NULL")
                cur.execute(_SQL_UPSERT, (
                    code, year, r["segment"], r["sex"], r["total_row"], r["headcount"],
                    r["tenure"], r["salary"], r["raw_tenure"], r["raw_salary"],
                    r["rcept_no"] or rcept,
                ))
                stats["rows"] += 1
            for cand in find_hidden_totals(rows):
                waiver = KNOWN_NOT_TOTAL.get((code, cand["segment"]))
                if waiver:
                    # 통과시키되 **왜 통과했는지를 매 실행 출력에 남긴다**. 개수만 세면 예외 목록이
                    # 언제 근거를 잃었는지 아무도 모른 채 눌러앉는다.
                    stats["waived"] += 1
                    _sample(stats, f"{nm}({code}) {year} {cand['segment']} — 예외 통과: {waiver}")
                    continue
                stats["suspects"].append({"corp_code": code, "corp_nm": nm, "year": year, **cand})
        if commit:
            commit()  # 법인 하나 완료 = 안전한 경계(다음 법인에서 죽어도 여기까지는 남는다)
    return stats


def check_missing(cur, base_year: int, corps: list[dict] | None = None) -> list[dict]:
    """최신연도에 **셀 수 있는 인원이 한 행도 없는** 회사 목록.

    커버리지는 99/100 실측(SP-MET-1)이라 이 목록은 "0 이어야 하는 값"이 아니라 **다음 실행의
    출발점**이다. 그래도 종료 코드 1 로 올린다 — 98/100 로 줄어드는 날을 조용히 넘기지 않기 위해서다.
    """
    if corps is None:
        corps = load_corps(cur)
    cur.execute(_SQL_YEAR_COUNTS, (base_year,))
    have = {code: (cnt or 0) for code, cnt in cur.fetchall()}
    return [{"corp_code": c["corp_code"], "corp_nm": c.get("corp_nm", ""), "year": base_year}
            for c in corps if have.get(c["corp_code"], 0) == 0]


def format_missing(missing: list[dict]) -> str:
    lines = [f"결측 {len(missing)}건 — 최신연도 직원현황이 없는 법인:"]
    lines += [f"  {m['corp_nm']}({m['corp_code']}) {m['year']}" for m in missing]
    return "\n".join(lines)


def format_suspects(suspects: list[dict]) -> str:
    lines = [f"합계행 미탐 의심 {len(suspects)}건 — 이 부문 인원이 나머지 전부와 같다(SP-MET-5).",
             "  원문을 보고 합계행이면 표식을 고치고, 아니면 KNOWN_NOT_TOTAL 에 근거와 함께 넣어라:"]
    for s in suspects:
        lines.append(f"  {s['corp_nm']}({s['corp_code']}) {s['year']} "
                     f"{s['segment']} {s['headcount']:,}명 vs 나머지 {s['rest']:,}명")
    return "\n".join(lines)


def format_notes(stats: dict) -> str:
    """이상·결측 개수 한 줄. **항상 찍는다** — 0 건이라는 사실도 정보다(조용한 결측 금지)."""
    notes = stats.get("notes", {})
    parts = [f"{NOTE_LABELS.get(k, k)} {notes[k]}" for k in sorted(notes)]
    parts.append(f"키중복 {stats.get('dup_keys', 0)}")
    parts.append(f"예외통과(KNOWN_NOT_TOTAL) {stats.get('waived', 0)}")
    return "  이상: " + " · ".join(parts)


# ── 스모크 ───────────────────────────────────────────────────────────────────

def probe(api_key: str, corp_code: str, year: int, fetch_fn=default_fetch) -> dict:
    """DB 무접촉 1회 호출 → 합계행 판정·정규화 결과 요약. 실응답 파서 스모크용.

    가중평균(SP-MET-8)은 여기서 계산하지 않는다 — 집계식은 생성기 한 곳에만 둔다. 여기서 보고 싶은
    것은 "행을 제대로 갈랐는가, 단위·근속이 복원됐는가" 뿐이다.
    """
    if not api_key:
        raise DartError("DART_API_KEY 미설정 — server/.env 에 넣어라")
    try:
        payload = fetch_fn(build_url(api_key, corp_code, year))
    except Exception as exc:  # noqa: BLE001
        raise DartError(f"DART 호출 실패 — {corp_code} {year}: {type(exc).__name__}: "
                        f"{str(exc).replace(api_key, '***')}") from None
    rows = extract_rows(payload, corp_code) or []
    picked = aggregation_rows(rows)
    heads = [r["headcount"] for r in picked if r["headcount"] is not None]
    notes: dict[str, int] = {}
    for r in rows:
        for n in r["notes"]:
            notes[n] = notes.get(n, 0) + 1
    return {
        "status": str(payload.get("status", "")),
        "rows": len(rows),
        "total_rows": sum(1 for r in rows if r["total_row"]),
        "picked": [{"segment": r["segment"], "sex": r["sex"], "headcount": r["headcount"],
                    "tenure": r["tenure"], "salary": r["salary"],
                    "raw_tenure": r["raw_tenure"], "raw_salary": r["raw_salary"]} for r in picked],
        "headcount": sum(heads) if heads else None,
        "notes": notes,
        "suspects": find_hidden_totals(rows),
        "rcept_no": _report_rcept_no(rows),
    }


def _api_key() -> str:
    """`server/.env DART_API_KEY` — pydantic Settings 경유(키는 여기서만 읽고 어디에도 찍지 않는다)."""
    if str(ROOT) not in sys.path:
        sys.path.insert(0, str(ROOT))
    from server.config import get_settings

    return get_settings().dart_api_key or ""


def main(argv=None, *, fetch_fn=default_fetch, conn=None) -> int:
    ap = argparse.ArgumentParser(description="DART 직원현황 수집 → TCORP_EMPLOY")
    ap.add_argument("--base-year", type=int, default=time.localtime().tm_year - 1, help="기준 연도(기본 올해-1)")
    ap.add_argument("--years", type=int, default=YEARS_DEFAULT, help=f"기준 연도부터 거슬러 몇 개년(기본 {YEARS_DEFAULT})")
    ap.add_argument("--corp", nargs="*", help="corp_code 부분 실행(기본 TCORP 전량)")
    ap.add_argument("--sleep", type=float, default=SLEEP_DEFAULT, help="호출 간 대기(초)")
    ap.add_argument("--probe", metavar="CORP_CODE", help="DB 무접촉 1회 호출 스모크(요약만 출력)")
    a = ap.parse_args(argv)

    api_key = _api_key()
    if not api_key:
        print("dart_employ refused: DART_API_KEY 미설정(server/.env) — 조용한 0건 수집은 하지 않는다", file=sys.stderr)
        return 2

    if a.probe:
        try:
            summary = probe(api_key, a.probe, a.base_year, fetch_fn=fetch_fn)
        except DartError as exc:
            print(f"dart_employ probe failed: {exc}", file=sys.stderr)
            return 1
        print(f"dart_employ probe: corp={a.probe} year={a.base_year} status={summary['status']} "
              f"rows={summary['rows']} 합계행={summary['total_rows']} rcept_no={summary['rcept_no']}")
        for r in summary["picked"]:
            salary = f"{r['salary']:,}원" if r["salary"] is not None else "없음"
            tenure = f"{r['tenure']}년" if r["tenure"] is not None else "없음"
            head = f"{r['headcount']:,}명" if r["headcount"] is not None else "없음"
            print(f"  {r['segment']}/{r['sex']} {head} · 근속 {r['raw_tenure']!r}→{tenure} "
                  f"· 급여 {r['raw_salary']!r}→{salary}")
        print(f"  집계 대상 인원 합: {summary['headcount']:,}명" if summary["headcount"] is not None
              else "  집계 대상 인원 합: 없음")
        if summary["notes"]:
            print("  이상: " + " · ".join(f"{NOTE_LABELS.get(k, k)} {v}" for k, v in sorted(summary["notes"].items())))
        for s in summary["suspects"]:
            # 예외 목록에 있어도 **찾은 것은 찾았다고 말한다**. 다만 수집이 왜 이걸 실패로 올리지
            # 않는지(사람이 이미 확인했다)를 같은 줄에서 밝힌다 — 안 그러면 스모크와 수집 결과가
            # 어긋나 보여 다음 사람이 둘 중 하나를 고치려 든다.
            waiver = KNOWN_NOT_TOTAL.get((a.probe, s["segment"]))
            print(f"  ⚠ 합계행 미탐 의심: {s['segment']} {s['headcount']:,} vs 나머지 {s['rest']:,}"
                  + (f" — 예외 통과: {waiver}" if waiver else ""))
        return 0 if summary["rows"] else 1

    owned = conn is None  # 주입된 커넥션은 호출자 소유 — 닫지 않는다
    if owned:
        import load as seed_load  # db/seed/load.py — 접속(server/.env)만 빌린다

        conn = seed_load.connect()
    try:
        with conn.cursor() as cur:
            cur.execute("SET NAMES utf8mb4")
            corps = load_corps(cur, a.corp)
            # 조용한 0건 금지(함정 (57))는 키에만 적용되는 규칙이 아니다. `--corp` 오타나 법인 미적재는
            # "calls=0 · 결측 0 · 종료 0" 으로 나타나 **성공과 구분되지 않는다**. 여기서 세워라.
            unknown = sorted(set(a.corp or ()) - {c["corp_code"] for c in corps})
            if unknown:
                raise DartError(f"TCORP 에 없는 corp_code: {', '.join(unknown)} — 오타면 아무 일도 "
                                f"일어나지 않은 채 성공으로 보인다")
            if not corps:
                raise DartError("수집 대상 법인이 0건 — 법인 적재(db/seed/load_corp.py)가 먼저다")
            stats = collect(cur, corps, api_key=api_key, base_year=a.base_year, years=a.years,
                            fetch_fn=fetch_fn, sleep_sec=a.sleep, commit=conn.commit)
            missing = check_missing(cur, a.base_year, corps)
        conn.commit()  # 이상이 있어도 받은 것은 남긴다 — 실패 목록이 다음 실행의 출발점이다
    except DartError as exc:
        conn.rollback()  # 법인 단위로 커밋했으므로 되돌아가는 것은 마지막 법인의 미완 부분뿐이다
        print(f"dart_employ failed: {exc}", file=sys.stderr)
        return 1
    finally:
        if owned:
            conn.close()

    print(f"dart_employ done: corps={len(corps)} calls={stats['calls']} reports={stats['reports']} "
          f"rows={stats['rows']} no_data={stats['no_data']}")
    print(format_notes(stats))
    for line in stats["samples"]:
        print(f"    {line}")
    rc = 0
    if stats["suspects"]:
        print(format_suspects(stats["suspects"]))
        rc = 1
    if missing:
        print(format_missing(missing))
        rc = 1
    return rc


if __name__ == "__main__":
    raise SystemExit(main())
