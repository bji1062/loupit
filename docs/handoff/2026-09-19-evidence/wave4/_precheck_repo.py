"""웨이브 4 통합 — 리포 경로 사전 점검 (_precheck.py 의 사본).

차이는 두 곳뿐이다.
  · 글롭을 스크래치패드가 아니라 리포 db/seed/benefit/sql/ 의 이번 12파일로 잡는다.
  · 기존 slug/COMP_NM 충돌 검사는 이번 12파일을 제외한 코퍼스 138파일과 한다.
리포 모듈을 실제로 import 한다: load._split_sql_statements ·
company_meta.parse_header_insert · generator.slug.slug_of.
"""
import re, glob, sys, os, collections
sys.path.insert(0, "/home/ubuntu/loupit")
os.chdir("/home/ubuntu/loupit")
from db.seed import load, company_meta
from generator.slug import slug_of

WAVE4 = ["GC녹십자.sql", "HL만도.sql", "JYP.sql", "농심.sql", "동국제약.sql", "이마트.sql",
         "제주반도체.sql", "티에스이.sql", "파두.sql", "풍산.sql", "피에스케이.sql", "현대백화점.sql"]
SQLDIR = "db/seed/benefit/sql"
ROW = re.compile(
    r"\(@comp_id,\s*'((?:[^']|'')*)',\s*'((?:[^']|'')*)',\s*(NULL|[\d.]+),\s*'([a-z_]+)',"
    r"\s*'([a-z_]+)',\s*(NULL|'(?:[^']|'')*'),\s*(TRUE|FALSE),\s*(NULL|'(?:[^']|'')*'),\s*(\d+)\)",
    re.S,
)
HDR = re.compile(
    r"VALUES\s*\('([^']+)',\s*'([^']+)',\s*\(SELECT[^)]*\),\s*'([^']*)',\s*'([^']*)',\s*'([^']*)'"
)
CTGR = {"compensation", "health", "family", "leisure", "perks", "growth",
        "time_off", "flexibility", "work_env"}
vocab = set(re.findall(
    r"^\| `([a-z_0-9]+)`",
    open("docs/handoff/2026-09-19-evidence/_VOCAB.md", encoding="utf-8").read(), re.M))

# 기존 코퍼스 — 이번 12파일은 뺀다
existing_slug, existing_nm = {}, {}
for f in glob.glob(SQLDIR + "/*.sql"):
    if os.path.basename(f) in WAVE4:
        continue
    t = open(f, encoding="utf-8").read()
    m = re.search(r"VALUES\s*\('([^']+)',\s*'([^']+)'", t)
    if m:
        existing_slug[slug_of(m.group(1))] = (m.group(2), os.path.basename(f))
        existing_nm[m.group(2)] = os.path.basename(f)

total = 0
newcodes = collections.defaultdict(list)
amts = []
print(f"기존 코퍼스 파일 {len(existing_slug)}개 · 어휘표 {len(vocab)}종\n")
for f in sorted(os.path.join(SQLDIR, b) for b in WAVE4):
    t = open(f, encoding="utf-8").read()
    name = os.path.basename(f)
    probs = []
    try:
        stmts = load._split_sql_statements(t)
        ns = len(stmts)
    except Exception as e:
        ns = f"ERR {e}"
    if ns != 5:
        probs.append(f"stmts={ns}")
    try:
        eng, nm, tp = company_meta.parse_header_insert(t)
    except Exception as e:
        eng = nm = tp = None
        probs.append(f"header ERR {e}")
    h = HDR.search(t)
    ind = h.group(3) if h else "?"
    logo = h.group(4) if h else "?"
    url = h.group(5) if h else "?"
    sl = slug_of(eng) if eng else "?"
    if sl in existing_slug:
        probs.append(f"SLUG COLLISION {sl}={existing_slug[sl]}")
    if nm in existing_nm:
        probs.append(f"COMP_NM COLLISION {nm}={existing_nm[nm]}")
    rows = ROW.findall(t)
    n = len(rows)
    raw = len(re.findall(r"^\s*\(@comp_id,", t, re.M))
    if n != raw:
        probs.append(f"regex {n}!=raw {raw}")
    codes = [r[0] for r in rows]
    dup = [c for c, k in collections.Counter(codes).items() if k > 1]
    if dup:
        probs.append(f"DUP {dup}")
    bad = [r[3] for r in rows if r[3] not in CTGR]
    if bad:
        probs.append(f"CTGR {set(bad)}")
    badge = [r[4] for r in rows if r[4] != "est"]
    if badge:
        probs.append(f"BADGE {set(badge)}")
    sorts = [int(r[8]) for r in rows]
    if len(set(sorts)) != len(sorts):
        probs.append("SORT dup")
    dq = t.count('"')
    if dq:
        probs.append(f"dquote {dq}")
    for r in rows:
        if r[0] not in vocab:
            newcodes[r[0]].append(f"{nm}:{r[1]} (SORT {r[8]}, ctgr {r[3]})")
        if r[2] != "NULL":
            amts.append((nm, r[0], r[1], r[2], r[7], (r[8])))
    total += n
    print(f"{name:20s} eng={str(eng):16s} nm={str(nm):10s} tp={str(tp):6s} "
          f"ind={ind:10s} logo={logo} rows={n:2d} stmts={ns} "
          f"{'⚠ ' + '; '.join(probs) if probs else 'OK'}")
    print(f"{'':20s} url={url}")

print("\nTOTAL rows", total, "=> SD-4 would be", 2233 + total)
print(f"\nNEW CODES (어휘표 {len(vocab)}종에 없는 것):")
for c, v in sorted(newcodes.items()):
    print(f"  {c}:")
    for x in v:
        print(f"      {x}")
print("\nAMOUNT ROWS (nm, code, benefit_nm, amt, QUAL_YN, SORT):")
for a in amts:
    print("  ", a)
