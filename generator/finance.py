"""generator/finance.py — 생성기 전용 재무 로더·뷰모델 (SP-FIN-4·5).

근거: `docs/SPEC/15-회사정보-재무.md` · `PLAN-회사정보-확장-2026-08-21.md` §3 · 함정 (55)(69).

**왜 번들이 아니라 별도 로더인가.** 번들(`build_reference_bundle`)은 런타임 API `reference/all`
과 단일 소스다. 거기에 재무를 넣으면 600KB 응답·`models/reference.py` 화이트리스트·클라이언트
정규화까지 같이 움직여야 한다(함정 (55)). 재무의 소비처는 정적 페이지뿐이므로 생성기 전용
로더로 싣고, `build_context(bundle, finance=…)` 인자로 **번들 옆에** 흘린다.

**법인 단위 → 회사 단위.** 재무는 `TCORP_FINANCE`(법인)에 있고 화면은 회사(페이지)다. CJ ENM
두 부문처럼 한 법인을 여러 페이지가 가리키면 같은 `years` 를 받고 서로를 `siblings` 로 안다.
표시 기준은 `TCORP.FS_DIV_CD` 1벌(연결/별도) — 기준을 안 적으면 그 자체가 부정확한 주장이다.

FinanceView = {corp_nm, stock_cd, acct_set, fs_div, years:[{year, revenue, op_income, net_income,
rcept_no}], siblings:[comp_id…]}  — 금액은 원 단위 int, None = 그 계정이 없음(0 이 아니다).
"""
from __future__ import annotations

from collections import defaultdict

from generator.format import krw_eok, pct_delta

# 표준계정 ID — `account_nm` 이 아니다(회사마다 표기가 다르고, `sj_div` 로 거르면 SK하이닉스처럼
# CIS 에 싣는 회사가 조용히 빈다, 함정 (68)). 수집기(`db/seed/dart_finance.py`)와 같은 값.
ACCT_REVENUE = "ifrs-full_Revenue"
ACCT_OP_INCOME = "dart_OperatingIncomeLoss"
ACCT_NET_INCOME = "ifrs-full_ProfitLoss"
_ACCT_FIELD = {ACCT_REVENUE: "revenue", ACCT_OP_INCOME: "op_income", ACCT_NET_INCOME: "net_income"}
_FIELDS = ("revenue", "op_income", "net_income")

BASIS_LABEL = {"CFS": "연결 기준", "OFS": "별도 기준"}
BASIS_SHORT = {"CFS": "연결", "OFS": "별도"}
DART_VIEWER = "https://dart.fss.or.kr/dsaf001/main.do?rcpNo="
NONE_TEXT = "공시 데이터 없음(비상장 또는 미제출)"

_SQL_MAP = """
  SELECT cc.COMP_ID AS comp_id, cc.CORP_CODE AS corp_code, k.CORP_NM AS corp_nm,
         k.STOCK_CD AS stock_cd, k.ACCT_SET_CD AS acct_set, k.FS_DIV_CD AS fs_div
    FROM TCOMPANY_CORP cc JOIN TCORP k ON k.CORP_CODE = cc.CORP_CODE
   ORDER BY cc.COMP_ID"""

_SQL_FIN = """
  SELECT CORP_CODE AS corp_code, BSNS_YEAR AS year, FS_DIV_CD AS fs_div, ACCT_ID AS acct_id,
         AMT_VAL AS amt, RCEPT_NO AS rcept_no
    FROM TCORP_FINANCE ORDER BY CORP_CODE, BSNS_YEAR, FS_DIV_CD, FIN_ID"""


def _int_or_none(v):
    """DECIMAL(24,0) → int(JSON 덤프 가능). NULL 은 NULL 로 — 0 으로 지어내지 않는다."""
    return None if v is None else int(v)


def assemble(map_rows: list[dict], fin_rows: list[dict]) -> dict[int, dict]:
    """매핑 행 + 재무 행 → `{comp_id: FinanceView}` (순수 조립, DB 무관).

    `map_rows`: TCOMPANY_CORP ⋈ TCORP (comp_id, corp_code, corp_nm, stock_cd, acct_set, fs_div)
    `fin_rows`: TCORP_FINANCE (corp_code, year, fs_div, acct_id, amt, rcept_no)
    표시 기준(`fs_div`)의 행만 싣는다. 매핑만 있고 재무가 없는 회사도 `years=[]` 로 남긴다 —
    인덱스가 일반/금융 섹션을 가를 때 `acct_set` 이 필요하다.
    """
    by_key: dict[tuple[str, str], dict[int, dict]] = {}
    for r in fin_rows:
        field = _ACCT_FIELD.get(r["acct_id"])
        if field is None:
            continue
        years = by_key.setdefault((r["corp_code"], r["fs_div"]), {})
        slot = years.setdefault(
            int(r["year"]),
            {"year": int(r["year"]), "revenue": None, "op_income": None, "net_income": None, "rcept_no": None},
        )
        slot[field] = _int_or_none(r["amt"])
        if r.get("rcept_no") and not slot["rcept_no"]:
            slot["rcept_no"] = r["rcept_no"]

    out: dict[int, dict] = {}
    pages_by_corp: dict[str, list[int]] = defaultdict(list)
    for m in map_rows:
        comp_id = int(m["comp_id"])
        years = by_key.get((m["corp_code"], m["fs_div"]), {})
        out[comp_id] = {
            "corp_nm": m["corp_nm"],
            "stock_cd": m["stock_cd"],
            "acct_set": m["acct_set"],
            "fs_div": m["fs_div"],
            "years": [dict(years[y]) for y in sorted(years)],
            "siblings": [],
        }
        pages_by_corp[m["corp_code"]].append(comp_id)
    for ids in pages_by_corp.values():
        for cid in ids:
            out[cid]["siblings"] = [o for o in ids if o != cid]
    return out


async def load_finance(conn) -> dict[int, dict]:
    """빌드타임 로더(aiomysql DictCursor 커넥션) — `bundle.load_bundle_with_finance` 가 번들과
    **같은 커넥션**으로 호출한다(두 로더가 같은 시점의 DB 를 본다)."""
    async with conn.cursor() as cur:
        await cur.execute(_SQL_MAP)
        map_rows = await cur.fetchall()
        await cur.execute(_SQL_FIN)
        fin_rows = await cur.fetchall()
    return assemble(map_rows, fin_rows)


def is_loaded(finance) -> bool:
    """수치가 한 건이라도 있는가. 매핑만 있고 0건이면 '미적재'다(수집 전 릴리스가 102개사 전부에
    "미제출"을 찍지 않게 하는 경계)."""
    return bool(finance) and any(v.get("years") for v in finance.values())


def _josa(name: str, with_batchim: str, without: str) -> str:
    """한글 받침 유무로 조사 선택(과/와). 한글이 아니면 받침 없음으로 본다."""
    if not name:
        return without
    code = ord(name[-1])
    if 0xAC00 <= code <= 0xD7A3 and (code - 0xAC00) % 28:
        return with_batchim
    return without


def company_view(fin: dict | None, comp_nm: str, sibling_names: list[str]) -> dict:
    """회사 상세 '실적' 섹션 뷰모델 (SP-FIN-5). 표시는 사실만 — 수치·전년 대비·기준·출처.

    행은 **최신 연도 먼저**(모바일에서 가장 궁금한 줄이 위). 증감률은 오름차순으로 계산한 뒤
    뒤집는다. 출처 링크는 최신 보고서 하나 — 사업보고서는 3개년 비교치를 함께 싣는다.
    접수번호가 숫자가 아니면 링크를 만들지 않는다(URL 주입 경로 차단).
    """
    if not fin or not fin.get("years"):
        return {"present": False, "none_text": NONE_TEXT}
    financial = fin.get("acct_set") == "financial"
    years = sorted(fin["years"], key=lambda y: y["year"])
    rows, prev = [], None
    for y in years:
        row = {"year": y["year"]}
        for f in _FIELDS:
            row[f] = krw_eok(y.get(f))
            row[f"{f}_delta"] = pct_delta(prev.get(f) if prev else None, y.get(f)) or "—"
        rows.append(row)
        prev = y
    rows.reverse()
    basis = BASIS_LABEL.get(fin.get("fs_div"), fin.get("fs_div") or "")
    rcept = str(years[-1].get("rcept_no") or "")
    names = [n for n in sibling_names if n]
    sibling_note = None
    if names:
        joined = " · ".join(names)
        sibling_note = f"법인 기준 공시 — {joined}{_josa(joined, '과', '와')} 같은 법인의 수치입니다."
    return {
        "present": True,
        "financial": financial,
        "basis": basis,
        "rows": rows,
        "rcept_no": rcept,
        "rcept_url": DART_VIEWER + rcept if rcept.isdigit() else None,
        "sibling_note": sibling_note,
        "caption": f"{comp_nm} 연도별 실적 — {basis}, 단위 억원",
    }


def index_row(fin: dict | None) -> dict:
    """`/companies` 행의 재무 열 — 최신 사업연도 수치(억원)·기준. 없으면 전부 '—'."""
    if not fin or not fin.get("years"):
        return {"year": "—", "revenue": "—", "op_income": "—", "net_income": "—", "basis": "—"}
    latest = max(fin["years"], key=lambda y: y["year"])
    return {
        "year": str(latest["year"]),
        "revenue": krw_eok(latest.get("revenue")),
        "op_income": krw_eok(latest.get("op_income")),
        "net_income": krw_eok(latest.get("net_income")),
        "basis": BASIS_SHORT.get(fin.get("fs_div"), fin.get("fs_div") or "—"),
    }
