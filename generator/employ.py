"""generator/employ.py — 생성기 전용 직원현황 로더·지표 카드 뷰모델 (SP-MET-8·10).

근거: `docs/SPEC/17-회사정보-지표.md` SP-MET-1~10(2026-08-28 DART 전수 실측) ·
`db/seed/dart_employ.py`(수집·정규화) · `generator/finance.py`(같은 이유로 같은 골격) · 함정 (55)(69).

**왜 번들이 아니라 생성기 전용 로더인가.** 재무와 같은 이유다(`finance.py` 머리말). 번들
(`build_reference_bundle`)은 런타임 API `reference/all` 과 단일 소스라, 거기에 직원 현황을 얹으면
응답 크기·`server/models/reference.py` 화이트리스트·클라이언트 정규화가 함께 움직여야 한다
(함정 (55) — Pydantic 은 화이트리스트에 없는 필드를 **조용히 떨군다**). 소비처가 정적 페이지뿐이므로
여기서 읽어 `build_context(bundle, employ=…)` 로 번들 **옆에** 흘린다.

**법인 단위 → 회사 단위.** 직원 현황도 `TCORP_EMPLOY`(법인)에 있고 화면은 회사(페이지)다. CJ ENM
두 부문처럼 한 법인을 여러 페이지가 가리키면 같은 수치를 받는다(형제 관계 자체는 `finance.py` 가
이미 안다 — 두 벌로 만들지 않는다). 재무와 달리 **표시 기준(연결/별도)이 없다**: 직원 현황은
사업보고서에 법인 1벌로만 실린다.

**집계는 인원 가중평균이다**(SP-MET-8). 단순평균은 남녀·부문 규모를 무시해 58개사가 5% 이상
틀어진다 — 삼성전자 2025 는 단순 14,850만원 vs 가중 **15,706만원**이다.

⚠ **성별은 이 파일 밖으로 나가지 않는다**(사용자 결정 2026-08-28). `SEX_CD` 는 가중치를 나누는 행
구분일 뿐이고, 뷰모델에 남는 것은 회사-연도의 값 세 개뿐이다. 화면·표·툴팁 어디에도 남녀 구분은 없다.

EmployView = {comp_id: {year: {salary, tenure, head}}}
  salary = 원(int, 인원 가중평균) · tenure = 년(float, 소수 2자리) · head = 명(int)
  None = **그 값이 없다**(0 이 아니다 — "평균연봉 0원"·"근속 0년"은 화면에 나가는 순간 거짓이다).

MetricsView(`company_metrics`) = 재무 3종 + 직원 3종을 카드 6장으로 합친 화면 계약(SP-MET-10).
"""
from __future__ import annotations

from generator.finance import BASIS_LABEL, metric_columns
from generator.format import pct_delta

# 단위 — 카드마다 다르다. 금액만 회사당 하나로 통일한다(아래 `_money_scale`).
UNIT_SALARY, UNIT_TENURE, UNIT_HEAD = "만원", "년", "명"
UNIT_JO, UNIT_EOK = "조원", "억원"
JO = 1_000_000_000_000  # 1조
EOK = 100_000_000  # 1억
MAN = 10_000  # 1만

# 직원 3종의 이름. 금액 3종의 이름은 `finance.metric_columns` 가 세트별로 정한다(SP-MET-2).
EMPLOY_CARDS = (("salary", "평균연봉", UNIT_SALARY), ("tenure", "평균근속", UNIT_TENURE),
                ("head", "직원수", UNIT_HEAD))
EMPTY_FMT = "{name} 공시 값이 없습니다"  # SP-MET-10 — 없는 값은 비우고 **그렇게 말한다**

_SQL_MAP = """
  SELECT cc.COMP_ID AS comp_id, cc.CORP_CODE AS corp_code
    FROM TCOMPANY_CORP cc ORDER BY cc.COMP_ID"""

# 원문 컬럼(SEGMENT_NM·SEX_CD·RAW_*)은 읽지 않는다. 합계행 판정은 수집기가 이미 내린 결론
# (`TOTAL_ROW_YN`)이고, 여기서 이름을 다시 보면 판정이 두 곳이 된다(SP-MET-5).
_SQL_EMP = """
  SELECT CORP_CODE AS corp_code, BSNS_YEAR AS year, TOTAL_ROW_YN AS total_row,
         HEADCNT AS head, TENURE_YEAR AS tenure, AVG_SALARY_AMT AS salary
    FROM TCORP_EMPLOY ORDER BY CORP_CODE, BSNS_YEAR, EMPLOY_ID"""


# ── 집계 (SP-MET-5·8) ────────────────────────────────────────────────────────

def aggregate(rows: list[dict]) -> dict | None:
    """한 법인·한 연도의 행들 → `{salary, tenure, head}` · 셀 것이 하나도 없으면 None.

    🚨 **합계행이 하나라도 있으면 합계행만 센다**(SP-MET-5). 7사(삼성전자·LG전자·삼성물산·
    삼성바이오로직스·삼성전기·현대글로비스·효성중공업)가 부문행과 합계행을 **함께** 내기 때문에,
    전부 더하면 삼성전자가 128,881 → **257,762 명**이 된다. 에러는 나지 않는다.
    ⓘ 어떤 행이 합계행인가(`fo_bbm` 에 합계·총계)는 **수집기가 판정해 `TOTAL_ROW_YN` 으로 남긴다**
      — 이름을 다시 보지 않는 이유다. 여기 있는 것은 "합계행이 있으면 그것만"이라는 선택 규칙뿐이고,
      같은 규칙이 `db/seed/dart_employ.py::aggregation_rows` 에도 있다(수집기는 스모크 출력에 쓴다).
    ⚠ 이 함수는 그 (법인, 연도)에 **저장된 모든 행**을 센다. 그래서 재수집이 옛 행을 남기면 인원이
      늘어난다 — 수집기가 연도 단위로 지우고 다시 쓰는 이유다(`_SQL_DELETE_YEAR`).

    평균은 **인원 가중평균**이다(SP-MET-8): Σ(값 × 인원) / Σ(인원), 값이 있는 행만.
    ⛔ 인원을 모르는 행은 가중할 수 없으므로 평균에서 **뺀다**. 단순평균으로 슬쩍 대체하지 않는다 —
      그러면 그 회사만 다른 규칙으로 계산된 숫자가 같은 그래프에 섞인다(58개사가 5% 이상 틀어진다).
    ⛔ `fyer_salary_totamt`(연간급여총액)는 애초에 저장하지 않는다 — CJ CGV 는 `총액/인원` 이 공시
      1인평균과 **4.8배** 어긋난다(SP-MET-8).
    """
    picked = [r for r in rows if r.get("total_row")] or list(rows)
    heads = [int(r["head"]) for r in picked if r.get("head") is not None]
    head = sum(heads) if heads else None
    salary = _weighted(picked, "salary")
    tenure = _weighted(picked, "tenure")
    if salary is None and tenure is None and head is None:
        return None  # 보고서는 있었지만 셀 값이 없다 — 빈 연도로 그래프에 칸만 늘리지 않는다
    return {
        # 원 미만·소수 3자리는 공시에 없다. 여기서 한 번만 맞춰 두면 JSON 덤프와 DB 경로가 같은
        # 수를 낸다(표시 단계에서 또 반올림하지 않는다 — 두 곳에서 반올림하면 표와 그래프가 갈린다).
        "salary": None if salary is None else round(salary),
        "tenure": None if tenure is None else round(tenure, 2),
        "head": head,
    }


def _weighted(rows: list[dict], field: str) -> float | None:
    """Σ(값 × 인원) / Σ(인원) — 값과 인원이 **둘 다** 있는 행만. 가중치 합이 0 이면 None."""
    num, den = 0.0, 0
    for r in rows:
        v, h = r.get(field), r.get("head")
        if v is None or h is None:
            continue
        h = int(h)
        if h <= 0:  # 인원 0 인 부문은 평균을 움직이지 못한다(0 으로 나누는 자리도 막는다)
            continue
        num += float(v) * h
        den += h
    return num / den if den else None


def assemble(map_rows: list[dict], emp_rows: list[dict]) -> dict[int, dict[int, dict]]:
    """매핑 행 + 직원 행 → `{comp_id: {year: {salary, tenure, head}}}` (순수 조립, DB 무관).

    `map_rows`: TCOMPANY_CORP (comp_id, corp_code) / `emp_rows`: TCORP_EMPLOY
    (corp_code, year, total_row, head, tenure, salary).

    재무(`finance.assemble`)와 달리 **행이 없는 회사는 빈 dict** 를 받는다. 재무는 인덱스가
    일반/금융을 가르느라 `acct_set` 이 필요해 껍데기를 남겼지만, 직원 현황에는 그런 소비처가 없다.
    """
    by_corp: dict[str, dict[int, list[dict]]] = {}
    for r in emp_rows:
        by_corp.setdefault(r["corp_code"], {}).setdefault(int(r["year"]), []).append(r)

    agg: dict[str, dict[int, dict]] = {}
    for code, years in by_corp.items():
        for year in sorted(years):
            v = aggregate(years[year])
            if v is not None:
                agg.setdefault(code, {})[year] = v

    # 같은 법인을 가리키는 페이지가 여럿이면 각자 **복사본**을 받는다. 한 dict 를 나눠 쓰면 한
    # 페이지의 뷰 조립이 다른 페이지 값을 건드릴 수 있다(형제 페이지는 실제로 존재한다 — CJ ENM).
    return {int(m["comp_id"]): {y: dict(v) for y, v in agg.get(m["corp_code"], {}).items()}
            for m in map_rows}


async def load_employ(conn) -> dict[int, dict[int, dict]]:
    """빌드타임 로더(aiomysql DictCursor) — 번들·재무와 **같은 커넥션**으로 부른다(같은 시점의 DB).

    ⚠ 이 결과를 JSON 으로 덤프했다가 되읽으면 **comp_id 도 연도도 문자열 키**가 된다.
      되돌리는 곳은 `normalize` 하나다.
    """
    async with conn.cursor() as cur:
        await cur.execute(_SQL_MAP)
        map_rows = await cur.fetchall()
        await cur.execute(_SQL_EMP)
        emp_rows = await cur.fetchall()
    return assemble(map_rows, emp_rows)


def normalize(employ) -> dict[int, dict[int, dict]]:
    """키를 int 로 되돌린다(JSON 왕복 대비) — comp_id 와 **연도 둘 다**.

    재무는 한 겹(`{comp_id: …}`)이라 `int(k)` 한 번이면 됐지만 여기는 두 겹이다. 바깥만 되돌리면
    연도가 문자열로 남아 `years` 정렬이 사전순이 되고(`"2015" < "9999"`), 전년 대비가 조용히 사라진다.
    """
    return {int(k): _years(v) for k, v in (employ or {}).items()}


def _years(emp) -> dict[int, dict]:
    return {int(y): v for y, v in (emp or {}).items()}


def is_loaded(employ) -> bool:
    """수치가 한 건이라도 있는가. 매핑만 있고 0건이면 '미적재'다(수집 전 릴리스가 102개사 전부에
    "값 없음"을 찍지 않게 하는 경계 — `finance.is_loaded` 와 같은 규약)."""
    return bool(employ) and any(v for v in employ.values())


def coverage(employ) -> dict:
    """결측을 **세어서** 돌려준다(조용한 결측 금지). 빌드 로그가 이 숫자를 찍는다.

    `{"companies": 값이 있는 회사 수, "years": 회사×연도 수, "salary"/"tenure"/"head": 결측 칸 수}`.
    0 으로 채우면 화면에 거짓이 나가고, 세지 않고 비우면 **언제부터 비었는지 아무도 모른다** —
    이 프로젝트가 반복해서 밟은 함정이 정확히 그것이다.
    """
    out = {"companies": 0, "years": 0, "salary": 0, "tenure": 0, "head": 0}
    for years in (employ or {}).values():
        if not years:
            continue
        out["companies"] += 1
        for v in years.values():
            out["years"] += 1
            for f in ("salary", "tenure", "head"):
                if v.get(f) is None:
                    out[f] += 1
    return out


# ── 전년 대비 (SP-MET-10) ────────────────────────────────────────────────────

def year_over_year(prev, cur, scale: int = 1) -> tuple[str, str]:
    """전년 대비 문구·방향 `(delta_text, delta_dir)`. 비교할 수 없으면 `("", "")`.

    네 갈래(SP-MET-10). 부호가 뒤집히면 비율이 아니라 **사건**이라서 퍼센트를 말하지 않는다 —
    적자에서 흑자로 간 변화를 "+180%" 라고 적으면 그 수는 아무 뜻도 없다.
      · 흑자 → 적자 = `적자 전환` · 적자 → 흑자 = `흑자 전환`
      · 둘 다 음수 = `적자 확대/축소 N%`(절댓값 기준) · 그 외 = `+N.N%`

    비율 계산은 `format.pct_delta` **한 곳뿐**이다(분모가 `abs(prev)` 라 적자 기준에서도 부호가
    방향을 말한다). 다만 그 함수는 int 로 떨어뜨리므로, 소수를 가진 지표는 `scale` 로 정수 눈금에
    올려 넘긴다 — 근속을 그냥 넘기면 13.7 과 13.4 가 **둘 다 13** 이 되어 변화가 사라진다.

    `delta_dir` 은 값이 오르내린 **방향**이지 좋고 나쁨이 아니다(DEC-B: 평가·전망 금지).
    """
    if prev is None or cur is None:
        return "", ""
    direction = "up" if cur > prev else ("down" if cur < prev else "")
    if prev > 0 > cur:
        return "적자 전환", direction
    if prev < 0 < cur:
        return "흑자 전환", direction
    text = pct_delta(round(prev * scale), round(cur * scale))
    if text is None:  # 전년이 0 — 0 을 분모로 비율을 만들 수 없다(지어내지 않는다)
        return "", ""
    if prev < 0 and cur < 0:
        # `pct_delta` 는 이미 적자 기준으로 부호를 잡아 준다: 적자가 커지면 음수, 줄면 양수.
        # 부호는 라벨이 대신 말하므로 숫자만 떼어 쓴다.
        magnitude = text[1:]
        if magnitude.startswith("0.0"):
            return "적자 유지", ""  # 소수 첫째 자리에서 0 이 되는 변화를 '확대/축소'라 부를 수 없다
        return f"적자 {'확대' if text.startswith('-') else '축소'} {magnitude}", direction
    return text, direction


# ── 표시 단위 ────────────────────────────────────────────────────────────────

def _round_div(v: int, unit: int) -> int:
    """부호를 지키는 사사오입 나눗셈. 표(`format.krw_eok`)와 **같은 규칙**이라 같은 수를 낸다 —
    한 페이지에서 표는 400,000억, 카드는 399,999억 이면 둘 중 하나는 틀린 것으로 읽힌다."""
    sign = -1 if v < 0 else 1
    return sign * ((abs(int(v)) + unit // 2) // unit)


def _money_scale(values) -> tuple[str, int]:
    """금액 표시 단위와 **소수 자릿수** — 둘 다 회사당 하나다(SP-MET-10).

    기준은 유효값 절댓값의 **최솟값**이다. 가장 작은 값이 소수점 아래로 사라지면 안 되기 때문이다.
      · 최솟값 ≥ 1조 → 조원(소수 1자리). 정수로 자르면 5.6조가 6조가 되어 추이가 죽는다.
      · 그 밖 → 억원. 카카오페이는 자산 5.3조인데 영업이익이 503억이라, 조원으로 통일하면
        영업이익 카드가 `0.1조` 로 뭉개진다. 한 회사 안에서 조와 억을 섞으면 세 그래프를 나란히
        읽을 수 없으므로 단위는 하나로 고정하고, 해상도는 자릿수로 준다.
      · 🚨 억원인데 최솟값이 **1억 미만**이면 소수 1자리. 정수로 자르면 그 값이 `0` 이 되는데
        0 에는 부호가 없어 **적자가 흑자처럼 보인다** — 리메드 2025 순이익 −35,468,721원이
        `0억원` 이 되고 막대가 기준선 **위에** 초록으로 그려졌다(2026-08-28 실데이터 확인).
        숫자를 잃는 것보다 나쁜 것은 부호를 잃는 것이다.
    """
    vals = [abs(v) for v in values if v is not None]
    if not vals:
        return UNIT_EOK, 0
    lo = min(vals)
    if lo >= JO:
        return UNIT_JO, 1
    return UNIT_EOK, 1 if lo < EOK else 0


def _to_money(unit: str, decimals: int):
    """원 → 표시 단위. 자릿수만큼 눈금을 잘게 쪼갠 뒤 되돌린다(반올림은 `_round_div` 한 곳)."""
    step = JO if unit == UNIT_JO else EOK
    if decimals:
        div = 10 ** decimals
        return lambda v: _round_div(v, step // div) / div
    return lambda v: _round_div(v, step)


def _to_manwon(won) -> int:
    """원 → 만원(정수). 연봉은 만원이 이 사이트의 단위다(`format.krw_manwon` 과 같은 눈금)."""
    return _round_div(won, MAN)


def _to_year(v) -> float:
    """근속 → 소수 1자리. 저장은 2자리지만 화면에 13.69년이라고 적을 만큼 정밀한 값이 아니다."""
    return round(float(v), 1)


# 직원 3종의 (표시 함수, 비율 눈금, 소수 자릿수). 비율 눈금은 `year_over_year` 의 `scale` 이고,
# 근속만 소수라 100배로 올려 넘긴다(그냥 넘기면 13.7 과 13.4 가 둘 다 13 이 되어 변화가 사라진다).
_EMPLOY_DISPLAY = {"salary": (_to_manwon, 1, 0), "tenure": (_to_year, 100, 1), "head": (int, 1, 0)}


# ── 카드 6장 (SP-MET-10) ─────────────────────────────────────────────────────

def _card(key: str, name: str, unit: str, years: list[int], raw: dict, to_display,
          scale: int = 1, decimals: int = 0) -> dict:
    """카드 한 장. `values` 는 `years` 와 **같은 길이**이고 없는 해는 None 이다.

    결측을 0 으로 채우지 않는 이유는 그림이다(SP-MET-9): 선은 그 구간을 끊고 막대는 자리를 비운다.
    0 으로 그리면 "그해 매출이 0" 이라고 말하는 것이 된다.
    전년 대비는 **표시값이 아니라 원값**으로 계산한다 — 억원으로 자른 뒤 계산하면 반올림이 비율에
    섞인다. 그리고 '전년'은 말 그대로 직전 **연도**다: 연도가 건너뛴 자리(2019 → 2023)는 비교하지
    않는다. 5년 만의 변화를 "전년 대비"라 적으면 그건 틀린 문장이다.
    """
    values, latest, latest_year = [], None, None
    for y in years:
        v = raw.get(y)
        values.append(None if v is None else to_display(v))
        if v is not None:
            latest, latest_year = v, y
    prev = raw.get(latest_year - 1) if latest_year is not None else None
    text, direction = year_over_year(prev, latest, scale)
    return {
        "key": key,
        "name": name,
        "unit": unit,
        # 표시 자릿수는 **카드가 들고 다닌다.** 단위 문자열에서 되짚으면 같은 `억원` 이라도 회사마다
        # 자릿수가 다른 지금 규칙을 표현할 수 없고, 큰 숫자와 그래프 라벨이 갈라진다(SP-MET-10).
        "decimals": decimals,
        "values": values,
        "latest": None if latest is None else to_display(latest),
        "delta_text": text,
        "delta_dir": direction,
        "empty_text": None if latest is not None else EMPTY_FMT.format(name=name),
    }


def company_metrics(fin: dict | None, emp: dict | None, corp_nm: str = "") -> dict | None:
    """회사 상세 '연도별 추이' 섹션 뷰모델 — 카드 6장(SP-MET-10). 그릴 것이 없으면 None.

    `fin` = `finance.assemble` 의 회사 몫(FinanceView) · `emp` = 이 파일 `assemble` 의 회사 몫.
    둘 중 하나만 있어도 만든다 — 재무는 있는데 직원 현황이 없는 회사(1/100)가 실제로 있다.

    카드는 **항상 6장, 순서 고정**(평균연봉·평균근속·직원수 · 금액 3종)이다. 회사마다 카드 수가
    달라지면 세 회사를 나란히 둔 화면이 매번 다른 모양이 되고, 없는 값은 카드가 사라지는 게 아니라
    `empty_text` 로 **없다고 말한다**. 금융 세트는 매출 자리에 자산총계가 온다(SP-MET-2) — 그 판단은
    `finance.metric_columns` 하나가 내린다.

    표시 기준(`basis`)은 금액 3종에만 해당한다. 직원 현황은 사업보고서에 법인 1벌로 실려 연결/별도가
    없다 — 배지가 두 벌이면 읽는 사람이 근속에도 연결 기준이 있다고 오해한다.
    """
    fin = fin or {}
    emp_years = _years(emp)
    fin_years = {int(y["year"]): y for y in fin.get("years") or []}
    years = sorted(set(fin_years) | set(emp_years))
    if not years:
        return None

    columns = metric_columns(fin.get("acct_set"))
    money_raw = {key: {y: fin_years[y].get(key) for y in fin_years} for key, _ in columns}
    unit, decimals = _money_scale([v for per in money_raw.values() for v in per.values()])
    to_money = _to_money(unit, decimals)

    cards = [_card(key, name, card_unit, years, {y: emp_years[y].get(key) for y in emp_years},
                   *_EMPLOY_DISPLAY[key])
             for key, name, card_unit in EMPLOY_CARDS]
    cards += [_card(key, name, unit, years, money_raw[key], to_money, decimals=decimals)
              for key, name in columns]
    if all(c["latest"] is None for c in cards):
        return None  # 여섯 장 전부 빈 섹션은 내지 않는다(연도만 있고 값이 없는 경우)

    rcept = str(fin_years[max(fin_years)].get("rcept_no") or "") if fin_years else ""
    return {
        "corp_nm": corp_nm or fin.get("corp_nm") or "",
        "basis": BASIS_LABEL.get(fin.get("fs_div"), fin.get("fs_div") or ""),
        "financial": fin.get("acct_set") == "financial",
        "money_unit": unit,
        "years": years,
        # 접수번호는 링크 재료다. 숫자가 아니면 아예 내보내지 않는다 — `finance.company_view` 와
        # 같은 규칙이고, URL 주입 경로를 템플릿의 주의력에 맡기지 않기 위해서다.
        "rcept_no": rcept if rcept.isdigit() else None,
        "cards": cards,
    }
