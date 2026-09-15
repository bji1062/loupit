# 웨이브 3 통합 — integration-audit.md §5·§9 조치를 스크래치 원본에 적용해 스테이징에 쓴다.
# 원본(wave3/*.sql)은 읽기만 한다. 대체 문안은 감사 문서에서 직접 추출(손 전사 없음).
import re, sys, os
S = "/tmp/claude-0/-home-ubuntu-loupit/723f8817-c77d-4e78-ab10-c256a6b1bdd7/scratchpad/wave3"
OUT = sys.argv[1] if len(sys.argv) > 1 else S + "/_integrated"
os.makedirs(OUT, exist_ok=True)
AUDIT = open(S + "/integration-audit.md", encoding="utf-8").read()

ROW_RE = re.compile(
    r"^  \(@comp_id, '(?P<code>[a-z_0-9]+)', '(?P<nm>[^']*)', (?P<amt>NULL|\d+), '(?P<ctgr>[a-z_]+)',\n"
    r"   '(?P<badge>est)', (?P<note>NULL|'[^']*'), (?P<qualyn>TRUE|FALSE), (?P<desc>NULL|'[^']*'), (?P<sort>\d+)\)(?P<end>,?)\n",
    re.M)


def section(title_prefix):
    """감사 §5-N 절 본문(다음 ### 전까지)."""
    i = AUDIT.index("### " + title_prefix)
    j = AUDIT.find("\n### ", i + 1)
    return AUDIT[i:j if j != -1 else len(AUDIT)]


def table_cell(sec, sort):
    """절 안에서 SORT 행(| 41 | 또는 | **40** |)의 4번째 칸."""
    hits = [l for l in sec.splitlines() if re.match(r"^\| (\*\*)?%s(\(신규\))?(\*\*)? \|" % sort, l)]
    assert len(hits) == 1, (sort, hits)
    cells = [c.strip() for c in hits[0].strip("|").split("|")]
    return cells[3]


def nm_qual(cell):
    nm = re.search(r"NM: `([^`]*)`", cell)
    q = re.search(r"QUAL: `([^`]*)`", cell)
    if q is None:  # QUAL 단독 교체 — 첫 백틱 값
        q = re.search(r"`([^`]*)`", cell)
    return (nm.group(1) if nm else None), q.group(1)


def find_row(text, code, sort):
    ms = [m for m in ROW_RE.finditer(text) if m.group("code") == code and m.group("sort") == str(sort)]
    assert len(ms) == 1, (code, sort, len(ms))
    return ms[0]


def del_row(text, code, sort):
    m = find_row(text, code, sort)
    assert m.group("end") == ",", "마지막 행 삭제는 문법 처리 필요"
    return text[:m.start()] + text[m.end():]


def set_row(text, code, sort, nm=None, desc=None, code_new=None, expect_nm=None):
    m = find_row(text, code, sort)
    if expect_nm is not None:
        assert m.group("nm") == expect_nm, (m.group("nm"), expect_nm)
    d = m.groupdict()
    if nm is not None:
        d["nm"] = nm
    if desc is not None:
        assert d["desc"] != "NULL"
        d["desc"] = "'" + desc + "'"
    if code_new is not None:
        d["code"] = code_new
    new = ("  (@comp_id, '{code}', '{nm}', {amt}, '{ctgr}',\n"
           "   '{badge}', {note}, {qualyn}, {desc}, {sort}){end}\n").format(**d)
    return text[:m.start()] + new + text[m.end():]


def insert_after(text, code, sort, tuple_text):
    m = find_row(text, code, sort)
    assert m.group("end") == ","
    return text[:m.end()] + tuple_text + text[m.end():]


def rep(text, old, new):
    assert text.count(old) == 1, (old[:60], text.count(old))
    return text.replace(old, new)


def header_block(label):
    """§9-5 의 「**label** … → 교체**」 다음 ``` 코드 블록."""
    i = AUDIT.index(label, AUDIT.index("### 9-5."))
    a = AUDIT.index("```\n", i) + 4
    b = AUDIT.index("```", a)
    return AUDIT[a:b]


def header_lines(text, first, last):
    lines = text.split("\n")
    return "\n".join(lines[first - 1:last]) + "\n"


def add_reflection(text, lines):
    # 헤더 닫는 ━ 줄(두 번째 ━ 줄) 바로 앞에 넣는다
    bars = [m.start() for m in re.finditer(r"^-- ━", text, re.M)]
    pos = bars[1]
    return text[:pos] + "".join(l + "\n" for l in lines) + text[pos:]


def load(name):
    return open(f"{S}/{name}.sql", encoding="utf-8").read()


def save(name, text):
    open(f"{OUT}/{name}.sql", "w", encoding="utf-8").write(text)


R = "⚠ 검증·감사 판정 반영(2026-09-15): "

# ── 5-1 포스코인터내셔널 ──
t = load("포스코인터내셔널"); sec = section("5-1.")
t = del_row(t, "refresh_leave", 40)
nm, q = nm_qual(table_cell(sec, 41))
t = set_row(t, "leave_general", 41, nm=nm, desc=q, expect_nm="심야근무 보상휴가")
t = add_reflection(t, [
    "--       " + R + "22 → 21행. SORT 40 출장 Refresh 휴가는 출장이라는 근무 사건에 붙는",
    "--       보상 휴가라 refresh_leave 에서 leave_general 로 옮겨 SORT 41 심야근무 보상휴가와 병합했다.",
])
save("포스코인터내셔널", t)

# ── 5-2 포스코퓨처엠 ──
t = load("포스코퓨처엠"); sec = section("5-2.")
_, q = nm_qual(table_cell(sec, 22))
old = find_row(t, "parenting", 22).group("desc")
assert old == "'본인/" + q + "'", "22 교체문이 「본인/」 삭제와 다르다"
t = set_row(t, "parenting", 22, desc=q)
t = add_reflection(t, [
    "--       " + R + "행 수 25 그대로. SORT 22 에서 본인 태아 검진 휴가(법정)를 빼고",
    "--       배우자 태아 검진 휴가만 남겼다. 신규 코드 disability_family_support 는 채택.",
])
save("포스코퓨처엠", t)

# ── 5-3 키움증권 (무조치) ──
t = load("키움증권")
t = add_reflection(t, [
    "--       " + R + "행 조치 없음(15행 그대로). SORT 40 childcare 유지 ·",
    "--       SORT 60 은 근속 연동 리프레시라 long_service_leave 유지.",
])
save("키움증권", t)

# ── 5-4 삼성증권 ──
t = load("삼성증권"); sec = section("5-4.")
t = del_row(t, "weekend_farm", 74)
nm, q = nm_qual(table_cell(sec, 73))
t = set_row(t, "company_event", 73, nm=nm, desc=q, expect_nm="가족 친화 프로그램")
t = add_reflection(t, [
    "--       " + R + "23 → 22행. 신규 코드 weekend_farm 기각 — SORT 74 가족 주말농장을",
    "--       삭제하고 SORT 73 가족 친화 프로그램(company_event) 행에 흡수했다(위 신규 코드 1개·23행은 반영 전 수치).",
])
save("삼성증권", t)

# ── 5-5 SK바이오팜 ──
t = load("SK바이오팜"); sec = section("5-5.")
t = del_row(t, "transport", 42)
nm, q = nm_qual(table_cell(sec, 41))
t = set_row(t, "commute_subsidy", 41, nm=nm, desc=q, expect_nm="출근버스")
sql = sec[sec.index("```sql\n") + 7:]
sql = sql[:sql.index("```")]
assert ROW_RE.fullmatch(sql), sql
t = insert_after(t, "edu_support", 70, sql)
old_hdr = header_lines(load("SK바이오팜"), 24, 25)
assert old_hdr.startswith("--       제외(교육 커리큘럼): 같은 페이지 구성원 역량 개발 표(New Comer·SKMS 워크숍·국내 MBA 등)는"), old_hdr
t = rep(t, old_hdr, header_block("**SK바이오팜 —"))
t = add_reflection(t, [
    "--       " + R + "16행 그대로(병합 −1 · 추가 +1). SORT 42 차량 보조금(transport)은 용도 미기재라",
    "--       원문 한 줄대로 SORT 41 출근버스(commute_subsidy)에 병합 · SORT 71 mba(국내 MBA 과정 지원) 추가.",
])
save("SK바이오팜", t)

# ── 5-6 대한전선 (무조치) ──
t = load("대한전선")
t = add_reflection(t, [
    "--       " + R + "행 조치 없음(10행 그대로). 선물 지급 1항목의 3행 분해(SORT 11·20·30)를 유지한다.",
])
save("대한전선", t)

# ── 5-7 에스티팜 ──
t = load("에스티팜"); sec = section("5-7.")
t = del_row(t, "discount", 41)
nm, q = nm_qual(table_cell(sec, 43))
t = set_row(t, "welfare_point", 43, nm=nm, desc=q, expect_nm="선택적 복지")
_, q = nm_qual(table_cell(sec, 70))
t = set_row(t, "long_service_bonus", 70, desc=q, expect_nm="장기근속 포상")
t = add_reflection(t, [
    "--       " + R + "18 → 17행. SORT 41 복지몰 운영(discount)은 영문판이 같은 칸을",
    "--       Selective welfare system 으로 옮겨 SORT 43 선택적 복지(welfare_point)에 병합 · SORT 70 미기재 사항 보강.",
])
save("에스티팜", t)

# ── 5-8 로보티즈 (무조치) ──
t = load("로보티즈")
t = add_reflection(t, [
    "--       " + R + "행 조치 없음(9행 그대로). SORT 10 식대 AMT NULL · SORT 30 work_tools 유지.",
])
save("로보티즈", t)

# ── 5-9 루닛 ──
t = load("루닛"); sec = section("5-9.")
nm, q = nm_qual(table_cell(sec, 21))
t = set_row(t, "stock_option", 21, nm=nm, desc=q, expect_nm="주식매수선택권·우리사주조합")
t = del_row(t, "remote_work", 71)
_, q = nm_qual(table_cell(sec, 70))
t = set_row(t, "flex_work", 70, desc=q, expect_nm="유연근무제")
old_hdr = header_lines(load("루닛"), 13, 14)
assert "p.32 주석이" in old_hdr and old_hdr.count("\n") == 2, old_hdr
t = rep(t, old_hdr, header_block("**루닛 `:13-14`"))
t = add_reflection(t, [
    "--       " + R + "23 → 22행. SORT 21 에서 선별 부여 스톡옵션을 걷어내고 우리사주조합만 남겼다 ·",
    "--       SORT 71 원격근무(remote_work) 삭제, 문구는 SORT 70 유연근무제 서술에 흡수. 복지포인트 120 은 원문 명시값이라 유지.",
])
save("루닛", t)

# ── 5-10 씨젠 ──
t = load("씨젠")
t = set_row(t, "refresh_leave", 41, code_new="leave_general", expect_nm="힐링데이·돌봄데이")
t = add_reflection(t, [
    "--       " + R + "행 수 19 그대로. SORT 41 힐링데이·돌봄데이는 원문에 휴가 부여 문구가 없어",
    "--       refresh_leave 에서 leave_general 로 재코딩했다.",
])
save("씨젠", t)

# ── 5-11 더존비즈온 — §9-1 14행 전문 ──
t = load("더존비즈온")
sec91 = AUDIT[AUDIT.index("### 9-1."):AUDIT.index("### 9-2.")]
n_changed = 0
for l in sec91.splitlines():
    m = re.match(r"^\| (\d+) \| `([a-z_]+)` \| (그대로 — )?`([^`]*)` \|$", l)
    if not m:
        continue
    sort, code, keep, q = int(m.group(1)), m.group(2), m.group(3), m.group(4)
    cur = find_row(t, code, sort).group("desc")
    assert q.endswith(" (그룹 통합 채용 기준)"), (sort, q)
    if keep:
        assert cur == "'" + q + "'", ("그대로 행 불일치", sort)
    else:
        t = set_row(t, code, sort, desc=q)
        n_changed += 1
assert n_changed == 11, n_changed
old_hdr = header_lines(load("더존비즈온"), 16, 23)
assert old_hdr.startswith("--   귀속 설계(리드 결정):") and "③ 그룹 페이지에만" in old_hdr, old_hdr
t = rep(t, old_hdr, header_block("**더존비즈온 `:16-23`"))
t = add_reflection(t, [
    "--   " + R + "행 수 14 그대로. 공고 출처 11행(SORT 10·11·12·20·21·30·40·60·61·62·63)의",
    "--     출처 표기를 더존ICT그룹 기준으로 바꾸고 (그룹 통합 채용 기준) 각주를 붙였다 — 14행 전부 그룹 기준.",
])
save("더존비즈온", t)

# ── 5-12 가온전선 ──
t = load("가온전선")
t = set_row(t, "refresh_leave", 60, code_new="leave_general", expect_nm="집중 휴가제 (休weeks)")
old_hdr = header_lines(load("가온전선"), 24, 24)
assert old_hdr.startswith("--         집중 휴가제(休weeks)는 하기휴가와 별도 항목이라") and "refresh_leave 로 두었다" in old_hdr, old_hdr
t = rep(t, old_hdr, header_block("**가온전선 —"))
t = add_reflection(t, [
    "--       " + R + "행 수 13 그대로. SORT 60 休weeks 는 부여 일수가 없어 refresh_leave 에서",
    "--       leave_general 로 재코딩했다.",
])
save("가온전선", t)

for f in sorted(os.listdir(OUT)):
    print(f, len(ROW_RE.findall(open(f"{OUT}/{f}", encoding="utf-8").read())))
