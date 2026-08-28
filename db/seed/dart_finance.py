"""SP-FIN-3 · SP-MET-2·3 — DART 재무 수집기: OpenDART `fnlttSinglAcntAll` → TCORP_FINANCE.

근거: `docs/SPEC/15-회사정보-재무.md` SP-FIN-3 · `docs/SPEC/17-회사정보-지표.md` SP-MET-2·3·11
(2026-08-28 DART 전수 실측) · `PLAN-회사정보-확장-2026-08-21.md` §5-2 · 함정 (57)(68).

**지표는 `account_id`(표준계정 ID) 로만 찾는다.** `sj_div`·`account_nm` 으로 거르지 않는다 —
SK하이닉스는 손익을 `IS` 가 아니라 `CIS`(포괄손익계산서)에 싣고, 계정 이름은 회사마다 다르다.
그렇게 거르면 **에러 없이 그 회사만 빈다**(함정 (68)). 그래서 수집 뒤 **결측 검사**가 필수다:
최신연도 필수 3지표 중 하나라도 없으면 회사·연도·지표를 실패 목록으로 찍고 종료 코드 1.

**한 지표에 계정이 여럿이다(SP-MET-3·`ACCT_ALIASES`).** 2019년에 IFRS 표준계정 접두사가
`ifrs_` → `ifrs-full_` 로 바뀌어, 신형만 등록하면 **2018년 이전 매출·순이익이 조용히 빈다**
(접두사가 안 바뀐 영업이익만 들어와 "옛날엔 매출을 안 냈나"로 읽힌다 — 삼성전자 2017 매출
239.6조는 `ifrs_Revenue` 로 온다). 여러 계정이 잡히면 **목록 순서**로 고른다.

**없는 계정은 NULL 이지 0 이 아니다.** 다만 금융 세트(`ACCT_SET_CD=financial`)가 "순이익만"이었던
것은 **사실이 아니라 매핑 누락**이었다(SP-MET-2). 영업이익 계정 ID 를 넣자 7/7 로 잡힌다 —
기업은행 2025 영업이익 36,555억·카카오페이 503억. 진짜로 없는 것은 **매출**뿐이고(은행·보험·증권은
단일 영업수익 계정을 내지 않는다) 그 자리는 `ifrs-full_Assets`(자산총계, 7/7)가 대신한다.
그래서 금융도 **영업이익·순이익·자산총계 3종이 필수**다.

**키가 없으면 즉시 실패한다.** 조용한 0건은 "수집했는데 없더라"로 읽힌다(함정 (57)). 키는
`server/.env DART_API_KEY`(pydantic `dart_api_key`) 이고 **로그·예외 메시지에 찍지 않는다**.

HTTP 는 `fetch_fn(url) -> dict` 주입(기본 urllib, 새 의존성 0) — 테스트는 픽스처 4사로 무접촉.
멱등: `(CORP_CODE, BSNS_YEAR, FS_DIV_CD, ACCT_ID)` UNIQUE 위 upsert. 재실행은 안전하다.
호출량: 100사 × 11년 × 2기준 = 2,200 (일 20,000 안). 호출 간 `sleep_sec`(기본 0.05s).

CLI: `python3 db/seed/dart_finance.py [--base-year 2025] [--years 11] [--corp 00126380 …] [--sleep 0.05]`
  종료 코드 0 = 결측·충돌 0 · 1 = 있음(목록 출력) · 2 = 설정 오류(키 없음).
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

import dart_http
from decimal import Decimal
from pathlib import Path

SEED_DIR = Path(__file__).resolve().parent
ROOT = SEED_DIR.parents[1]
if str(SEED_DIR) not in sys.path:
    sys.path.insert(0, str(SEED_DIR))

API_URL = "https://opendart.fss.or.kr/api/fnlttSinglAcntAll.json"
REPRT_ANNUAL = "11011"  # 사업보고서
FS_DIVS = ("CFS", "OFS")  # 연결 / 별도 — 둘 다 저장, 화면은 TCORP.FS_DIV_CD 1벌

# 표준계정 ID — 여기 아닌 곳(sj_div·account_nm)으로 거르지 마라. **한 지표에 계정이 여럿이다**
# (SP-MET-3, 2026-08-28 전수 실측). 목록 순서가 우선순위다.
#   revenue    — 2019년 접두사 전환(`ifrs_` → `ifrs-full_`). 신형만 등록하면 2018년 이전이 조용히
#                빈다: 삼성전자 2017 매출 239.6조가 `ifrs_Revenue` 로 온다.
#   op_income  — `dart_OperatingIncomeLoss` 는 접두사가 안 바뀌었다. 대신 이 계정을 안 내고
#                `ifrs-full_ProfitLossFromOperatingActivities` 로 내는 회사가 있다(금융 세트에서 실측).
#   net_income — revenue 와 같은 접두사 전환.
#   assets     — SP-MET-2 로 새로 들어온다. 금융업은 매출이 없어 그 자리를 자산총계가 대신한다.
ACCT_ALIASES = {
    "revenue": ["ifrs-full_Revenue", "ifrs_Revenue"],
    # 영업이익의 **대표** 계정 `dart_OperatingIncomeLoss` 는 접두사가 바뀐 적이 없다. 뒤의 둘은
    # 금융업 대체 계정(SP-MET-2)이고, 그쪽은 2019년 경계를 그대로 겪으므로 구접두사도 함께 둔다 —
    # 규칙을 지표마다 다르게 적용하면 다음에 추가하는 지표에서 또 빠뜨린다.
    "op_income": ["dart_OperatingIncomeLoss", "ifrs-full_ProfitLossFromOperatingActivities",
                  "ifrs_ProfitLossFromOperatingActivities"],
    "net_income": ["ifrs-full_ProfitLoss", "ifrs_ProfitLoss"],
    # 🚨 자산총계도 2019년 접두사 변경을 그대로 겪는다 — SP-MET-3 을 처음 쓸 때 이 줄에만
    # 구접두사를 안 넣었고, 그 결과 **2018년 이전 자산총계가 조용히 비었다**(2026-08-28 실수집
    # 확인: `ifrs-full_Assets` 커버리지가 2019년부터 100%, 2015~2018 은 130건 중 3건).
    # 기업은행 2016 은 `ifrs_Assets` 로 온다. 지금 화면에 안 보이는 이유는 금융 7사가 2018년
    # 이하 보고서를 아예 안 내서일 뿐이고(DART 가 013 을 준다), 데이터가 비어 있다는 사실은 같다.
    "assets": ["ifrs-full_Assets", "ifrs_Assets"],
}
# 대표 계정 ID(목록 첫 값) — `generator/finance.py` 와 같은 값이고, **저장도 이 값 하나로 정규화**한다.
# 구접두사를 원문 그대로 넣으면 같은 지표가 `ifrs_Revenue`/`ifrs-full_Revenue` 두 행으로 갈라지고,
# 소비처가 한쪽만 알면 2018년 이전이 **다시 조용히 빈다** — SP-MET-3 이 막으려던 그 실패를 한 층
# 아래에서 반복하는 꼴이다. 어느 계정으로 잡았는지는 `ACCT_NM`(회사 표기)과 수집 통계의 `legacy`
# 집계로 남긴다(원문 추적은 `RCEPT_NO` 로 공시까지 간다).
ACCT_REVENUE = ACCT_ALIASES["revenue"][0]
ACCT_OP_INCOME = ACCT_ALIASES["op_income"][0]
ACCT_NET_INCOME = ACCT_ALIASES["net_income"][0]
ACCT_ASSETS = ACCT_ALIASES["assets"][0]
ACCT_IDS = (ACCT_REVENUE, ACCT_OP_INCOME, ACCT_NET_INCOME, ACCT_ASSETS)
_METRIC_OF = {acct: metric for metric, accts in ACCT_ALIASES.items() for acct in accts}
_CANON_OF = {metric: accts[0] for metric, accts in ACCT_ALIASES.items()}

# 세트별 필수 지표(최신연도) — 없으면 실패 목록에 오른다.
# 🚨 금융이 "순이익만"이던 것은 **사실이 아니라 계정 ID 누락**이었다(SP-MET-2). 영업이익 계정을
#    넣자 7/7 로 잡힌다 — 기업은행 2025 영업이익 36,555억·카카오페이 503억. 진짜 없는 것은
#    매출뿐이고, 그 자리는 자산총계(7/7)가 대신한다. 그래서 금융도 필수가 3종이다.
#    "금융은 원래 비는 것"이라고 넘겼다면 이 누락은 영영 드러나지 않았을 것이다.
REQUIRED_BY_SET = {
    "general": (ACCT_REVENUE, ACCT_OP_INCOME, ACCT_NET_INCOME),
    "financial": (ACCT_OP_INCOME, ACCT_NET_INCOME, ACCT_ASSETS),
}

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
    """GET → JSON dict. 일시적 실패는 `dart_http` 가 재시도하고, 최종 예외는 호출자(collect)가
    키를 가린 채 감싼다. 재시도 정책을 여기 적지 않는 이유는 그 모듈 머리말 참고."""
    return dart_http.fetch_json(url, timeout=timeout, user_agent="loupit-dart-finance/1.0")


def extract_accounts(payload: dict) -> dict[str, dict] | None:
    """응답 → `{대표 계정 ID: {amt, acct_nm, rcept_no, acct_id, by_acct}}` (4지표만).
    013(조회 데이터 없음) → None.

    `acct_id` 는 **실제로 값을 얻은 계정**(구접두사·대안 계정일 수 있다), `by_acct` 는 그 지표로
    잡힌 **모든** 계정의 금액이다. 고르기는 여기서 하되 본 것을 감추지 않는다 — 두 계정이 어긋난
    보고서를 어떻게 처리할지는 `collect` 가 정한다(`acct_conflict`).

    고르는 규칙: `ACCT_ALIASES` **목록 순서**로, 단 **금액이 있는** 계정 중에서. 값 없는 행(`-`)은
    "그 계정이 있다"가 아니다 — 그걸 앞순위라고 채택하면 뒤 별칭의 실값이 조용히 버려진다.
    전부 값이 없으면 첫 별칭 행을 그대로 남긴다(계정명·접수번호는 증거로 쓸모가 있다).

    `sj_div`·`account_nm` 으로는 거르지 않는다. SK하이닉스는 손익을 `CIS` 에 싣고(함정 (68)),
    `ifrs-full_Assets` 는 애초에 `BS` 행이다 — 손익표만 훑으면 자산총계가 통째로 빈다.
    같은 계정 ID 가 IS·CIS 에 두 번 실릴 수 있어 금액이 있는 첫 행을 쓴다.
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
    per_acct: dict[str, dict] = {}
    for it in items:
        acct = it.get("account_id")
        if acct not in _METRIC_OF:
            continue
        if acct in per_acct and per_acct[acct]["amt"] is not None:
            continue
        per_acct[acct] = {
            "amt": parse_amount(it.get("thstrm_amount")),
            "acct_nm": it.get("account_nm"),
            "rcept_no": it.get("rcept_no"),
            "acct_id": acct,
        }
    found: dict[str, dict] = {}
    for metric, aliases in ACCT_ALIASES.items():
        hits = [per_acct[a] for a in aliases if a in per_acct]  # 목록 순서 그대로
        if not hits:
            continue
        pick = next((h for h in hits if h["amt"] is not None), hits[0])
        found[_CANON_OF[metric]] = {**pick, "by_acct": {h["acct_id"]: h["amt"] for h in hits}}
    return found


def acct_conflict(entry: dict) -> dict | None:
    """한 지표에 잡힌 계정들이 **서로 다른 값**을 내면 그 내역 `{계정: 금액}`, 아니면 None.

    ⚠ 조용히 하나를 고르지 않는다(SP-MET-2). `dart_OperatingIncomeLoss` 와
    `ifrs-full_ProfitLossFromOperatingActivities` 가 한 보고서에 함께 있고 값이 다르면, 어느 쪽이
    그 회사의 '영업이익'인지 데이터는 답하지 못한다 — 사람이 공시를 보고 정할 문제다. 목록 순서로
    몰래 고르면 회사마다 다른 정의가 같은 그래프에 섞이고, 그건 비교 불가능한 숫자를 비교 가능한
    것처럼 보이게 한다(DEC-B 위반). 값이 같으면 어느 쪽을 써도 같으니 충돌이 아니다.
    """
    vals = {a: v for a, v in (entry.get("by_acct") or {}).items() if v is not None}
    return dict(vals) if len(set(vals.values())) > 1 else None


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


def collect(cur, corps: list[dict], *, api_key: str, base_year: int, years: int = 11,
            fetch_fn=default_fetch, sleep_sec: float = 0.05, commit=None) -> dict:
    """법인 목록 × 최근 `years`개년 × CFS/OFS 를 받아 TCORP_FINANCE 에 upsert (커밋은 호출자 몫).

    보고서가 있으면(응답 000 + list) 4계정 행을 **모두** 쓴다 — 없는 계정은 AMT_VAL NULL, 접수번호는
    그 보고서 것. 그래야 "보고서는 봤는데 계정이 없다"와 "보고서가 없다"(행 없음)가 구분된다.

    `years` 기본 11 — 2015~2025(SP-MET-11). 기존 5 는 SPEC 15 에 "최근 5개년"으로 적혀 있었을 뿐
    근거가 없던 값이고, 그래프는 5점으로는 추이가 되지 않는다. 100사 × 11년 × 2기준 = 2,200 호출로
    일 한도 20,000 안이다.

    통계에 `legacy`(구접두사·대안 계정으로 잡은 횟수)와 `conflicts`(같은 지표 두 계정이 다른 값 —
    실패 목록)를 함께 돌려준다. 세지 않으면 별칭이 실제로 동작하는지, 어긋난 회사가 있는지를
    아무도 모른 채 지나간다(조용한 실패 금지).

    `commit` 은 **법인 하나를 마칠 때마다** 부르는 커밋 콜백이다(없으면 커밋하지 않는다 — 무DB
    테스트 경로). 끝에서 한 번만 커밋하면 2,000 번째 호출에서 죽었을 때 앞의 1,999 개가 전부
    사라진다 — 2026-08-28 에 직원 수집기에서 실제로 그렇게 됐다. 법인이 경계인 이유는 그 안이
    "한 회사의 연도들"이라 부분 상태가 의미를 갖는 최소 단위이기 때문이고, upsert 라 재실행이 덮어쓴다.
    ⚠ 그래서 실패 시 `rollback` 이 되돌리는 것은 **마지막 법인의 미완 부분뿐**이다.
    """
    if not api_key:
        raise DartError("DART_API_KEY 미설정 — server/.env 에 넣어라. 키 없이 0건 수집은 허용하지 않는다")
    stats = {"calls": 0, "reports": 0, "rows": 0, "no_data": 0, "legacy": {}, "conflicts": []}
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
                    clash = acct_conflict(v) if v else None
                    if clash:
                        stats["conflicts"].append({"corp_code": code, "corp_nm": nm, "year": year,
                                                   "fs_div": fs_div, "acct_id": acct_id, "values": clash})
                    if v and v["acct_id"] != acct_id:
                        stats["legacy"][v["acct_id"]] = stats["legacy"].get(v["acct_id"], 0) + 1
                    cur.execute(_SQL_UPSERT, (
                        code, year, fs_div, acct_id,
                        v["acct_nm"] if v else None,
                        # 충돌이면 값을 **비운다**(NULL). 근거 없이 한쪽을 고를 바에는 화면에 "없음"이
                        # 나가는 게 맞고, 무엇이 어긋났는지는 실패 목록이 말한다. 앞선 실행이 넣어 둔
                        # 값도 덮어 쓴다 — 지금 그 값이 옳다는 근거가 없기 때문이다.
                        None if (v is None or clash) else v["amt"],
                        (v or {}).get("rcept_no") or rcept,
                    ))
                    stats["rows"] += 1
        if commit:
            commit()  # 법인 하나 완료 = 안전한 경계(다음 법인에서 죽어도 여기까지는 남는다)
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
        # 모르는 세트 코드는 일반 세트로 본다 — `ACCT_IDS` 로 떨어뜨리면 일반 회사에 자산총계까지
        # 필수가 돼 실패 목록이 무의미하게 길어진다(필수는 세트별 3종이다).
        for acct in REQUIRED_BY_SET.get(c.get("acct_set", "general"), REQUIRED_BY_SET["general"]):
            if have.get((code, fs_div, acct)) is not None:
                continue
            hint = None
            if have.get((code, other, acct)) is not None:
                hint = f"{other} 에는 있음 — TCORP.FS_DIV_CD 를 확인하라"
            missing.append({"corp_code": code, "corp_nm": c.get("corp_nm", ""), "year": base_year,
                            "fs_div": fs_div, "acct_id": acct, "hint": hint})
    return missing


def format_missing(missing: list[dict]) -> str:
    lines = [f"결측 {len(missing)}건 — 일반: 매출·영업이익·순이익 / 금융: 영업이익·순이익·자산총계 (최신연도 기준):"]
    for m in missing:
        tail = f"  ← {m['hint']}" if m.get("hint") else ""
        lines.append(f"  {m['corp_nm']}({m['corp_code']}) {m['year']} {m['fs_div']} {m['acct_id']}{tail}")
    return "\n".join(lines)


def format_conflicts(conflicts: list[dict]) -> str:
    """계정 충돌 실패 목록(SP-MET-2). 두 값을 **모두** 적는다 — 사람이 공시를 열어 정해야 하므로."""
    lines = [f"계정 충돌 {len(conflicts)}건 — 한 지표에 두 계정이 서로 다른 값으로 함께 있다(값은 NULL 로 두었다):"]
    for c in conflicts:
        vals = " / ".join(f"{a}={v:,}" for a, v in c["values"].items())
        lines.append(f"  {c['corp_nm']}({c['corp_code']}) {c['year']} {c['fs_div']} {c['acct_id']}: {vals}")
    return "\n".join(lines)


def probe(api_key: str, corp_code: str, year: int, fs_div: str, fetch_fn=default_fetch) -> dict:
    """DB 무접촉 1회 호출 → 요약 `{status, rows, found:{대표 계정 ID: {eok, rcept_no, acct_id}}}`.

    실응답 파서 스모크용. 구접두사 연도(2018 이하)를 프로브하면 `acct_id` 로 별칭이 물었는지 보인다."""
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
            # `acct_id` 를 함께 낸다 — 구접두사 연도(2018 이하)를 프로브할 때 별칭이 실제로 물었는지
            # 눈으로 확인할 유일한 자리다. 숫자만 보면 신형으로 잡힌 것과 구별되지 않는다.
            acct: {"eok": None if v["amt"] is None else round(v["amt"] / 100_000_000),
                   "rcept_no": v["rcept_no"], "acct_id": v["acct_id"]}
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
    # SP-MET-11: 기본 11(2015~2025). 기존 5 는 SPEC 15 에 "최근 5개년"으로 적혔을 뿐 근거가 없던
    # 값이다 — 그래프는 5점으로 추이가 되지 않고, 호출량은 2,200 으로 일 한도 20,000 안이다.
    ap.add_argument("--years", type=int, default=11, help="기준 연도부터 거슬러 몇 개년(기본 11)")
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
            if not v or v["eok"] is None:
                print(f"  {acct}: 없음")
                continue
            alias = "" if v["acct_id"] == acct else f" [{v['acct_id']}]"  # 별칭으로 잡았으면 그 계정을 밝힌다
            print(f"  {acct}: {v['eok']:,}억원 rcept_no={v['rcept_no']}{alias}")
        return 0 if summary["found"] else 1

    owned = conn is None  # 주입된 커넥션은 호출자 소유 — 닫지 않는다
    if owned:
        import load as seed_load  # db/seed/load.py — 접속(server/.env)만 빌린다

        conn = seed_load.connect()
    try:
        with conn.cursor() as cur:
            cur.execute("SET NAMES utf8mb4")
            corps = load_corps(cur, a.corp)
            stats = collect(cur, corps, api_key=api_key, base_year=a.base_year, years=a.years, commit=conn.commit,
                            fetch_fn=fetch_fn, sleep_sec=a.sleep)
            missing = check_missing(cur, a.base_year, corps)
        conn.commit()  # 결측이 있어도 받은 것은 남긴다 — 실패 목록이 다음 실행의 출발점이다
    except DartError as exc:
        conn.rollback()  # 법인 단위로 커밋했으므로 되돌아가는 것은 마지막 법인의 미완 부분뿐이다
        print(f"dart_finance failed: {exc}", file=sys.stderr)
        return 1
    finally:
        if owned:
            conn.close()

    legacy = ",".join(f"{a}:{n}" for a, n in sorted(stats["legacy"].items())) or "0"
    print(f"dart_finance done: corps={len(corps)} calls={stats['calls']} reports={stats['reports']} "
          f"rows={stats['rows']} no_data={stats['no_data']} legacy={legacy}")
    rc = 0
    # 충돌과 결측은 **둘 다** 찍는다. 하나를 먼저 만나 돌아가면 나머지는 다음 실행까지 안 보인다.
    if stats["conflicts"]:
        print(format_conflicts(stats["conflicts"]))
        rc = 1
    if missing:
        print(format_missing(missing))
        rc = 1
    return rc


if __name__ == "__main__":
    raise SystemExit(main())
