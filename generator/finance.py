"""generator/finance.py — 생성기 전용 재무 로더·뷰모델 (SP-FIN-4·5).

근거: `docs/SPEC/15-회사정보-재무.md` · `PLAN-회사정보-확장-2026-08-21.md` §3 · 함정 (55)(69).

**왜 번들이 아니라 별도 로더인가.** 번들(`build_reference_bundle`)은 런타임 API `reference/all`
과 단일 소스다. 거기에 재무를 넣으면 600KB 응답·`models/reference.py` 화이트리스트·클라이언트
정규화까지 같이 움직여야 한다(함정 (55)). 재무의 소비처는 정적 페이지뿐이므로 생성기 전용
로더로 싣고, `build_context(bundle, finance=…)` 인자로 **번들 옆에** 흘린다.

**법인 단위 → 회사 단위.** 재무는 `TCORP_FINANCE`(법인)에 있고 화면은 회사(페이지)다. CJ ENM
두 부문처럼 한 법인을 여러 페이지가 가리키면 같은 `years` 를 받고 서로를 `siblings` 로 안다.
표시 기준은 `TCORP.FS_DIV_CD` 1벌(연결/별도) — 기준을 안 적으면 그 자체가 부정확한 주장이다.

FinanceView = {corp_nm, stock_cd, acct_set, fs_div, years:[{year, revenue, assets, op_income,
net_income, rcept_no}], siblings:[comp_id…]}  — 금액은 원 단위 int, None = 그 계정이 없음(0 이 아니다).
"""
from __future__ import annotations

from collections import defaultdict

from generator.format import krw_eok, pct_delta

# 표준계정 ID — `account_nm` 이 아니다(회사마다 표기가 다르고, `sj_div` 로 거르면 SK하이닉스처럼
# CIS 에 싣는 회사가 조용히 빈다, 함정 (68)). 수집기(`db/seed/dart_finance.py`)와 같은 값.
# ⚠ 수집기는 구접두사(`ifrs_Revenue` 등, SP-MET-3)를 **대표 계정 하나로 정규화해서** 저장한다.
#   그래서 여기서는 별칭을 다시 알 필요가 없다 — 알아야 한다면 저장이 잘못된 것이다.
ACCT_REVENUE = "ifrs-full_Revenue"
ACCT_OP_INCOME = "dart_OperatingIncomeLoss"
ACCT_NET_INCOME = "ifrs-full_ProfitLoss"
ACCT_ASSETS = "ifrs-full_Assets"  # SP-MET-2 — 금융 세트의 세 번째 지표(매출 자리)
_ACCT_FIELD = {ACCT_REVENUE: "revenue", ACCT_OP_INCOME: "op_income",
               ACCT_NET_INCOME: "net_income", ACCT_ASSETS: "assets"}
# 저장 슬롯 전부. **표시 3종과 다르다** — 자산총계는 일반 회사에도 들어오고(BS 행이라 늘 있다),
# 매출은 금융 회사에도 이따금 들어온다(카카오뱅크·카카오페이 2/7). 무엇을 받았는지는 그대로 두고,
# 무엇을 보여줄지만 `METRIC_COLUMNS` 가 정한다.
_FIELDS = ("revenue", "assets", "op_income", "net_income")

# 세트별 표시 3종(SP-MET-2 확정). **금융은 매출 자리가 자산총계다.** 은행·보험·증권은 단일
# "영업수익" 계정을 아예 내지 않고(이자수익·수수료수익·투자영업수익 등 구성요소로만 낸다),
# 그걸 더해 "매출"이라 부르면 그건 공시가 아니라 **우리가 만든 지표**다 — 회사마다 구성이 달라
# 나란히 놓으면 비교 불가능한 숫자를 비교 가능한 것처럼 보이게 한다(DEC-B 위반).
# 자산총계는 7/7 이고 은행·보험의 표준 규모 지표이며 공시 원문 그대로다.
# ⓘ 금융이 "순이익만"이던 것은 사실이 아니라 **계정 ID 누락**이었다(SP-MET-2 실측: 영업이익 계정을
#   넣자 7/7 — 기업은행 2025 영업이익 36,555억·카카오페이 503억). 그래서 세트가 달라도 열은 3종이다.
#   ⚠ 이 dict 가 "금융에는 무엇을 싣는가"의 유일한 답이다. 표(`company_view`)와 카드
#     (`employ.company_metrics`)가 각자 판단하면 같은 페이지에서 세 번째 지표가 갈라진다.
METRIC_COLUMNS = {
    "general": (("revenue", "매출"), ("op_income", "영업이익"), ("net_income", "순이익")),
    "financial": (("assets", "자산총계"), ("op_income", "영업이익"), ("net_income", "순이익")),
}

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


def metric_columns(acct_set) -> tuple[tuple[str, str], ...]:
    """세트 코드 → 표시 3종 `((필드, 이름), …)` (SP-MET-2).

    모르는 세트 코드는 일반으로 본다 — 수집기 `REQUIRED_BY_SET` 과 같은 규약이다. 여기서 떨어뜨리면
    새 세트 코드가 들어온 날 그 회사만 열이 통째로 비고, 아무 에러도 나지 않는다.
    """
    return METRIC_COLUMNS.get(acct_set or "general", METRIC_COLUMNS["general"])


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
            {"year": int(r["year"]), **{f: None for f in _FIELDS}, "rcept_no": None},
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

    `columns` 가 **어느 3종을 어떤 이름으로 보여줄지**를 정한다(SP-MET-2) — 금융 세트는 매출 자리에
    자산총계가 온다. 행 dict 에는 받은 네 계정을 **전부** 담는다: 표가 무엇을 고르든 데이터는 그대로
    두어야, 세트 판정이 바뀌어도 재수집 없이 열만 바꿔 끼울 수 있다.
    ⛔ `financial` 은 남기되 "금융은 순이익만"이라는 전제는 걷어냈다 — 그건 사실이 아니라 계정 ID
      누락이었고(SP-MET-2), 영업이익은 금융 7/7 로 들어온다.
    """
    if not fin or not fin.get("years"):
        return {"present": False, "none_text": NONE_TEXT}
    financial = fin.get("acct_set") == "financial"
    years = sorted(fin["years"], key=lambda y: y["year"])
    rows, prev = [], None
    for y in years:
        row = {"year": y["year"]}
        # '전년'은 직전 **행**이 아니라 직전 **연도**다. 연도가 통째로 빠진 회사가 실제로 있고
        # (LIG디펜스앤에어로스페이스 2018 이 연결 기준에서 없다, 2026-08-28 실측), 행 기준으로
        # 비교하면 2017 → 2019 의 2년치 변화를 "전년 대비"라고 적게 된다. 그건 틀린 문장이다.
        # 바로 아래 카드(`employ._card`)는 이미 연도 기준이라, 여기만 두면 같은 페이지에서
        # 표와 카드가 다른 숫자를 말한다.
        base = prev if prev is not None and prev["year"] == y["year"] - 1 else None
        for f in _FIELDS:
            row[f] = krw_eok(y.get(f))
            row[f"{f}_delta"] = pct_delta(base.get(f) if base else None, y.get(f)) or "—"
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
        "columns": [{"key": k, "name": n} for k, n in metric_columns(fin.get("acct_set"))],
        "basis": basis,
        "rows": rows,
        "rcept_no": rcept,
        "rcept_url": DART_VIEWER + rcept if rcept.isdigit() else None,
        "sibling_note": sibling_note,
        "caption": f"{comp_nm} 연도별 실적 — {basis}, 단위 억원",
    }


def index_row(fin: dict | None) -> dict:
    """`/companies` 행의 재무 열 — 최신 사업연도 수치(억원)·기준. 없으면 전부 '—'.

    네 계정을 모두 낸다. 금융 세트 행이 자산총계를 쓸 수 있어야 하고(SP-MET-2), 어느 열을 그릴지는
    `metric_columns` 를 보는 인덱스 쪽이 정한다 — 여기서 미리 골라 버리면 그 판단이 두 곳이 된다.
    """
    if not fin or not fin.get("years"):
        return {"year": "—", **{f: "—" for f in _FIELDS}, "basis": "—"}
    latest = max(fin["years"], key=lambda y: y["year"])
    return {
        "year": str(latest["year"]),
        **{f: krw_eok(latest.get(f)) for f in _FIELDS},
        "basis": BASIS_SHORT.get(fin.get("fs_div"), fin.get("fs_div") or "—"),
    }
