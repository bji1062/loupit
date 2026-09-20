"""웨이브 4 감사 — 형식 재현 (웨이브 2 _precheck.py 를 경로만 바꾼 것).

리포 모듈을 실제로 import 해서 돌린다: load._split_sql_statements ·
company_meta.parse_header_insert · generator.slug.slug_of.
"""
import re, glob, sys, os, collections
sys.path.insert(0, "/home/ubuntu/loupit")
os.chdir("/home/ubuntu/loupit")
from db.seed import load, company_meta
from generator.slug import slug_of

S = "/tmp/claude-0/-home-ubuntu-loupit/f1d13a36-92d2-4e1c-9ce2-b6e64e0505ce/scratchpad"
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

# 기존 코퍼스 — slug/COMP_NM 양쪽으로 충돌을 본다(파일명 ≠ 표시명 10곳)
existing_slug, existing_nm = {}, {}
for f in glob.glob("db/seed/benefit/sql/*.sql"):
    t = open(f, encoding="utf-8").read()
    m = re.search(r"VALUES\s*\('([^']+)',\s*'([^']+)'", t)
    if m:
        existing_slug[slug_of(m.group(1))] = (m.group(2), os.path.basename(f))
        existing_nm[m.group(2)] = os.path.basename(f)

total = 0
newcodes = collections.defaultdict(list)
amts = []
rows_by_company = {}
print(f"기존 코퍼스 파일 {len(existing_slug)}개 · 어휘표 {len(vocab)}종\n")
for f in sorted(glob.glob(S + "/wave4/*.sql")):
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
    rows_by_company[nm] = (name, eng, sl, tp, ind, logo, url, rows)
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
