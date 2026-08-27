"""SP-FIN-3 — DART 재무 수집기: OpenDART `fnlttSinglAcntAll` → TCORP_FINANCE.

근거: `docs/SPEC/15-회사정보-재무.md` SP-FIN-3 · `PLAN-회사정보-확장-2026-08-21.md` §5-2 · 함정 (57)(68).

**지표는 `account_id`(표준계정 ID) 로만 찾는다.** `sj_div`·`account_nm` 으로 거르지 않는다 —
SK하이닉스는 손익을 `IS` 가 아니라 `CIS`(포괄손익계산서)에 싣고, 계정 이름은 회사마다 다르다.
그렇게 거르면 **에러 없이 그 회사만 빈다**(함정 (68)). 그래서 수집 뒤 **결측 검사**가 필수다:
일반 세트인데 최신연도 3지표 중 하나라도 없으면 회사·연도·지표를 실패 목록으로 찍고 종료 코드 1.

**없는 계정은 NULL 이지 0 이 아니다.** 금융 세트(`ACCT_SET_CD=financial`)는 매출·영업이익 계정이
아예 없다(삼성생명 실측). 순이익만 필수로 보고 나머지는 NULL 로 둔다.
  OI-D(미결): 금융업 '영업수익' 계정은 첫 실수집에서 실측해 확정한다 — 확정 전엔 싣지 않는다.

**키가 없으면 즉시 실패한다.** 조용한 0건은 "수집했는데 없더라"로 읽힌다(함정 (57)). 키는
`server/.env DART_API_KEY`(pydantic `dart_api_key`) 이고 **로그·예외 메시지에 찍지 않는다**.

HTTP 는 `fetch_fn(url) -> dict` 주입(기본 urllib, 새 의존성 0) — 테스트는 픽스처 4사로 무접촉.
멱등: `(CORP_CODE, BSNS_YEAR, FS_DIV_CD, ACCT_ID)` UNIQUE 위 upsert. 재실행은 안전하다.
호출량: 102사 × 5년 × 2기준 ≈ 1,020 (일 20,000 안). 호출 간 `sleep_sec`(기본 0.05s).

CLI: `python3 db/seed/dart_finance.py [--base-year 2025] [--years 5] [--corp 00126380 …] [--sleep 0.05]`
  종료 코드 0 = 결측 0 · 1 = 결측 있음(목록 출력) · 2 = 설정 오류(키 없음).
  `--probe 00126380 [--base-year 2025] [--fs-div CFS]` = **DB 무접촉** 1회 호출 스모크 — 파서가 실응답을
  읽는지 요약(계정·억원·접수번호)만 찍는다. 응답 원문·키는 출력하지 않는다.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
import time
import urllib.parse
import urllib.request
from decimal import Decimal
from pathlib import Path

SEED_DIR = Path(__file__).resolve().parent
ROOT = SEED_DIR.parents[1]
if str(SEED_DIR) not in sys.path:
    sys.path.insert(0, str(SEED_DIR))

API_URL = "https://opendart.fss.or.kr/api/fnlttSinglAcntAll.json"
REPRT_ANNUAL = "11011"  # 사업보고서
FS_DIVS = ("CFS", "OFS")  # 연결 / 별도 — 둘 다 저장, 화면은 TCORP.FS_DIV_CD 1벌

# 표준계정 ID — `generator/finance.py` 와 같은 값. 여기 아닌 곳(sj_div·account_nm)으로 거르지 마라.
ACCT_REVENUE = "ifrs-full_Revenue"
ACCT_OP_INCOME = "dart_OperatingIncomeLoss"
ACCT_NET_INCOME = "ifrs-full_ProfitLoss"
ACCT_IDS = (ACCT_REVENUE, ACCT_OP_INCOME, ACCT_NET_INCOME)
# 세트별 필수 지표 — 금융은 순이익만(OI-D: 영업수익 계정은 실측 후 확정).
REQUIRED_BY_SET = {"general": ACCT_IDS, "financial": (ACCT_NET_INCOME,)}

_STATUS_OK = "000"
_STATUS_NO_DATA = "013"

_SQL_UPSERT = (
    "INSERT INTO TCORP_FINANCE (CORP_CODE, BSNS_YEAR, FS_DIV_CD, ACCT_ID, ACCT_NM, AMT_VAL, RCEPT_NO) "
    "VALUES (%s, %s, %s, %s, %s, %s, %s) AS new "
    "ON DUPLICATE KEY UPDATE ACCT_NM = new.ACCT_NM, AMT_VAL = new.AMT_VAL, RCEPT_NO = new.RCEPT_NO"
)
_SQL_CORPS = "SELECT CORP_CODE, CORP_NM, ACCT_SET_CD, FS_DIV_CD FROM TCORP ORDER BY CORP_NM"
_SQL_YEAR_ROWS = "SELECT CORP_CODE, FS_DIV_CD, ACCT_ID, AMT_VAL FROM TCORP_FINANCE WHERE BSNS_YEAR = %s"


class DartError(RuntimeError):
    """수집 실패(키 없음·응답 오류·전송 실패). 메시지에 키를 싣지 않는다."""


def parse_amount(raw) -> int | None:
    """`thstrm_amount` 문자열 → 원 단위 int. 빈 문자열·'-'·None → None. 형식이 아니면 ValueError.

    쉼표·음수(`-1,234`)를 받는다. 조용히 0 으로 바꾸지 않는다 — 형식 오류는 데이터 문제라 들려야 한다.
    """
    if raw is None:
        return None
    s = str(raw).strip().replace(",", "")
    if s in ("", "-"):
        return None
    if not re.fullmatch(r"-?\d+(\.\d+)?", s):
        raise ValueError(f"금액 형식 아님: {raw!r}")
    return int(Decimal(s))


def build_url(api_key: str, corp_code: str, year: int, fs_div: str) -> str:
    q = urllib.parse.urlencode({
        "crtfc_key": api_key, "corp_code": corp_code, "bsns_year": str(year),
        "reprt_code": REPRT_ANNUAL, "fs_div": fs_div,
    })
    return f"{API_URL}?{q}"


def default_fetch(url: str, timeout: float = 20.0) -> dict:
    """urllib 기반 GET → JSON dict. 예외는 호출자(collect)가 키를 가린 채 감싼다."""
    req = urllib.request.Request(url, headers={"User-Agent": "loupit-dart-finance/1.0"})
    with urllib.request.urlopen(req, timeout=timeout) as resp:  # noqa: S310 — 고정 https 호스트
        return json.loads(resp.read().decode("utf-8"))


def extract_accounts(payload: dict) -> dict[str, dict] | None:
    """응답 → `{account_id: {amt, acct_nm, rcept_no}}` (3지표만). 013(조회 데이터 없음) → None.

    같은 `account_id` 가 IS·CIS 에 두 번 실릴 수 있다 — 금액이 있는 첫 행을 쓴다.
    그 외 상태 코드는 예외(요청 제한 020 등) — 조용히 빈 결과로 만들지 않는다.
    """
    status = str(payload.get("status", ""))
    if status == _STATUS_NO_DATA:
        return None
    if status != _STATUS_OK:
        raise DartError(f"DART 응답 오류 status={status} — {payload.get('message', '')}")
    items = payload.get("list") or []
    if not items:
        return None
    found: dict[str, dict] = {}
    for it in items:
        acct = it.get("account_id")
        if acct not in ACCT_IDS:
            continue
        if acct in found and found[acct]["amt"] is not None:
            continue
        found[acct] = {
            "amt": parse_amount(it.get("thstrm_amount")),
            "acct_nm": it.get("account_nm"),
            "rcept_no": it.get("rcept_no"),
        }
    return found


def _report_rcept_no(payload: dict) -> str | None:
    for it in payload.get("list") or []:
        if it.get("rcept_no"):
            return it["rcept_no"]
    return None


def load_corps(cur, corp_codes: list[str] | None = None) -> list[dict]:
    """TCORP → 수집 대상 목록. `corp_codes` 로 부분 실행."""
    cur.execute(_SQL_CORPS)
    corps = [{"corp_code": c, "corp_nm": nm, "acct_set": acct, "fs_div": div} for c, nm, acct, div in cur.fetchall()]
    if corp_codes:
        wanted = set(corp_codes)
        corps = [c for c in corps if c["corp_code"] in wanted]
    return corps


def collect(cur, corps: list[dict], *, api_key: str, base_year: int, years: int = 5,
            fetch_fn=default_fetch, sleep_sec: float = 0.05) -> dict:
    """법인 목록 × 최근 `years`개년 × CFS/OFS 를 받아 TCORP_FINANCE 에 upsert (커밋은 호출자 몫).

    보고서가 있으면(응답 000 + list) 3계정 행을 **모두** 쓴다 — 없는 계정은 AMT_VAL NULL, 접수번호는
    그 보고서 것. 그래야 "보고서는 봤는데 계정이 없다"와 "보고서가 없다"(행 없음)가 구분된다.
    """
    if not api_key:
        raise DartError("DART_API_KEY 미설정 — server/.env 에 넣어라. 키 없이 0건 수집은 허용하지 않는다")
    stats = {"calls": 0, "reports": 0, "rows": 0, "no_data": 0}
    for corp in corps:
        code, nm = corp["corp_code"], corp.get("corp_nm", "")
        for year in range(base_year - years + 1, base_year + 1):
            for fs_div in FS_DIVS:
                url = build_url(api_key, code, year, fs_div)
                try:
                    payload = fetch_fn(url)
                except Exception as exc:  # noqa: BLE001 — 전송 계층 전부: 키를 가리고 다시 던진다
                    detail = str(exc).replace(api_key, "***")
                    raise DartError(f"DART 호출 실패 — {nm}({code}) {year} {fs_div}: {type(exc).__name__}: {detail}") from None
                stats["calls"] += 1
                if sleep_sec:
                    time.sleep(sleep_sec)
                try:
                    found = extract_accounts(payload)
                except DartError as exc:
                    raise DartError(f"{nm}({code}) {year} {fs_div}: {exc}") from None
                if found is None:
                    stats["no_data"] += 1
                    continue
                stats["reports"] += 1
                rcept = _report_rcept_no(payload)
                for acct_id in ACCT_IDS:
                    v = found.get(acct_id)
                    cur.execute(_SQL_UPSERT, (
                        code, year, fs_div, acct_id,
                        v["acct_nm"] if v else None,
                        v["amt"] if v else None,
                        (v or {}).get("rcept_no") or rcept,
                    ))
                    stats["rows"] += 1
    return stats


def check_missing(cur, base_year: int, corps: list[dict] | None = None) -> list[dict]:
    """회사별 필수 지표 결측 검사(함정 (68)) — 최신연도·표시 기준(`TCORP.FS_DIV_CD`) 에서 필수 계정의
    AMT_VAL 이 NULL/부재인 것을 `[{corp_code, corp_nm, year, fs_div, acct_id, hint}]` 로.

    `hint`: 반대 기준(별도↔연결)에는 있으면 알려 준다 — 자회사가 없어 연결을 안 내는 회사는 데이터
    문제가 아니라 `FS_DIV_CD` 설정 문제다.
    """
    if corps is None:
        corps = load_corps(cur)
    cur.execute(_SQL_YEAR_ROWS, (base_year,))
    have = {(code, div, acct): amt for code, div, acct, amt in cur.fetchall()}
    if any("fs_div" not in c for c in corps):  # 테스트 등에서 fs_div 없이 넘기면 TCORP 에서 보충
        by_code = {c["corp_code"]: c for c in load_corps(cur)}
        corps = [{**by_code.get(c["corp_code"], {"fs_div": "CFS"}), **c} for c in corps]
    missing = []
    for c in corps:
        code, fs_div = c["corp_code"], c.get("fs_div") or "CFS"
        other = "OFS" if fs_div == "CFS" else "CFS"
        for acct in REQUIRED_BY_SET.get(c.get("acct_set", "general"), ACCT_IDS):
            if have.get((code, fs_div, acct)) is not None:
                continue
            hint = None
            if have.get((code, other, acct)) is not None:
                hint = f"{other} 에는 있음 — TCORP.FS_DIV_CD 를 확인하라"
            missing.append({"corp_code": code, "corp_nm": c.get("corp_nm", ""), "year": base_year,
                            "fs_div": fs_div, "acct_id": acct, "hint": hint})
    return missing


def format_missing(missing: list[dict]) -> str:
    lines = [f"결측 {len(missing)}건 — 일반 세트 3지표 / 금융 세트 순이익 (최신연도 기준):"]
    for m in missing:
        tail = f"  ← {m['hint']}" if m.get("hint") else ""
        lines.append(f"  {m['corp_nm']}({m['corp_code']}) {m['year']} {m['fs_div']} {m['acct_id']}{tail}")
    return "\n".join(lines)


def probe(api_key: str, corp_code: str, year: int, fs_div: str, fetch_fn=default_fetch) -> dict:
    """DB 무접촉 1회 호출 → 요약 `{status, rows, found:{acct_id: {eok, rcept_no}}}`. 실응답 파서 스모크용."""
    if not api_key:
        raise DartError("DART_API_KEY 미설정 — server/.env 에 넣어라")
    try:
        payload = fetch_fn(build_url(api_key, corp_code, year, fs_div))
    except Exception as exc:  # noqa: BLE001
        raise DartError(f"DART 호출 실패 — {corp_code} {year} {fs_div}: {type(exc).__name__}: "
                        f"{str(exc).replace(api_key, '***')}") from None
    found = extract_accounts(payload)
    return {
        "status": str(payload.get("status", "")),
        "rows": len(payload.get("list") or []),
        "found": {
            acct: {"eok": None if v["amt"] is None else round(v["amt"] / 100_000_000), "rcept_no": v["rcept_no"]}
            for acct, v in (found or {}).items()
        },
    }


def _api_key() -> str:
    """`server/.env DART_API_KEY` — pydantic Settings 경유(키는 여기서만 읽고 어디에도 찍지 않는다)."""
    if str(ROOT) not in sys.path:
        sys.path.insert(0, str(ROOT))
    from server.config import get_settings

    return get_settings().dart_api_key or ""


def main(argv=None, *, fetch_fn=default_fetch, conn=None) -> int:
    ap = argparse.ArgumentParser(description="DART 재무 수집 → TCORP_FINANCE")
    ap.add_argument("--base-year", type=int, default=time.localtime().tm_year - 1, help="기준 연도(기본 올해-1)")
    ap.add_argument("--years", type=int, default=5, help="기준 연도부터 거슬러 몇 개년(기본 5)")
    ap.add_argument("--corp", nargs="*", help="corp_code 부분 실행(기본 TCORP 전량)")
    ap.add_argument("--sleep", type=float, default=0.05, help="호출 간 대기(초)")
    ap.add_argument("--probe", metavar="CORP_CODE", help="DB 무접촉 1회 호출 스모크(요약만 출력)")
    ap.add_argument("--fs-div", default="CFS", choices=FS_DIVS, help="--probe 의 기준(기본 CFS)")
    a = ap.parse_args(argv)

    api_key = _api_key()
    if not api_key:
        print("dart_finance refused: DART_API_KEY 미설정(server/.env) — 조용한 0건 수집은 하지 않는다", file=sys.stderr)
        return 2

    if a.probe:
        try:
            summary = probe(api_key, a.probe, a.base_year, a.fs_div, fetch_fn=fetch_fn)
        except DartError as exc:
            print(f"dart_finance probe failed: {exc}", file=sys.stderr)
            return 1
        print(f"dart_finance probe: corp={a.probe} year={a.base_year} fs_div={a.fs_div} "
              f"status={summary['status']} rows={summary['rows']}")
        for acct in ACCT_IDS:
            v = summary["found"].get(acct)
            print(f"  {acct}: " + (f"{v['eok']:,}억원 rcept_no={v['rcept_no']}" if v and v["eok"] is not None else "없음"))
        return 0 if summary["found"] else 1

    owned = conn is None  # 주입된 커넥션은 호출자 소유 — 닫지 않는다
    if owned:
        import load as seed_load  # db/seed/load.py — 접속(server/.env)만 빌린다

        conn = seed_load.connect()
    try:
        with conn.cursor() as cur:
            cur.execute("SET NAMES utf8mb4")
            corps = load_corps(cur, a.corp)
            stats = collect(cur, corps, api_key=api_key, base_year=a.base_year, years=a.years,
                            fetch_fn=fetch_fn, sleep_sec=a.sleep)
            missing = check_missing(cur, a.base_year, corps)
        conn.commit()  # 결측이 있어도 받은 것은 남긴다 — 실패 목록이 다음 실행의 출발점이다
    except DartError as exc:
        conn.rollback()
        print(f"dart_finance failed: {exc}", file=sys.stderr)
        return 1
    finally:
        if owned:
            conn.close()

    print(f"dart_finance done: corps={len(corps)} calls={stats['calls']} reports={stats['reports']} "
          f"rows={stats['rows']} no_data={stats['no_data']}")
    if missing:
        print(format_missing(missing))
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
