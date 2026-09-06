import re, glob, sys, os, collections
sys.path.insert(0, "/home/ubuntu/loupit")
from db.seed import load, company_meta
from generator.slug import slug_of
S="/tmp/claude-0/-home-ubuntu-loupit/bc404160-59bd-48dd-b2d7-94c4ce001a43/scratchpad"
ROW = re.compile(r"\(@comp_id,\s*'([a-z_0-9]+)',\s*'([^']*)',\s*(NULL|\d+),\s*'([a-z_]+)',\s*'([a-z_]+)',\s*(NULL|'[^']*'),\s*(TRUE|FALSE),\s*(NULL|'[^']*'),\s*(\d+)\)", re.S)
HDR = re.compile(r"VALUES\s*\('([^']+)',\s*'([^']+)',\s*\(SELECT[^)]*\),\s*'([^']*)',\s*'([^']*)',\s*'([^']*)'")
CTGR={"compensation","health","family","leisure","perks","growth","time_off","flexibility","work_env"}
vocab=set(re.findall(r"^\| `([a-z_0-9]+)`", open("docs/handoff/2026-09-05-evidence/_VOCAB.md",encoding="utf-8").read(), re.M))
existing={}
for f in glob.glob("db/seed/benefit/sql/*.sql"):
    m=re.search(r"VALUES\s*\('([^']+)',\s*'([^']+)'", open(f,encoding="utf-8").read())
    if m: existing[slug_of(m.group(1))]=m.group(2)
total=0; newcodes=collections.defaultdict(list); amts=[]
for f in sorted(glob.glob(S+"/wave2/*.sql")):
    t=open(f,encoding="utf-8").read(); name=os.path.basename(f)
    probs=[]
    try:
        stmts=load._split_sql_statements(t); ns=len(stmts)
    except Exception as e: ns=f"ERR {e}"
    if ns!=5: probs.append(f"stmts={ns}")
    try: eng,nm,tp=company_meta.parse_header_insert(t)
    except Exception as e: eng=nm=tp=None; probs.append(f"header ERR {e}")
    h=HDR.search(t); ind=h.group(3) if h else "?"; logo=h.group(4) if h else "?"; url=h.group(5) if h else "?"
    sl=slug_of(eng) if eng else "?"
    if sl in existing: probs.append(f"SLUG COLLISION {sl}={existing[sl]}")
    rows=ROW.findall(t); n=len(rows); raw=len(re.findall(r"^\s*\(@comp_id,",t,re.M))
    if n!=raw: probs.append(f"regex {n}!=raw {raw}")
    codes=[r[0] for r in rows]; dup=[c for c,k in collections.Counter(codes).items() if k>1]
    if dup: probs.append(f"DUP {dup}")
    bad=[r[3] for r in rows if r[3] not in CTGR]
    if bad: probs.append(f"CTGR {set(bad)}")
    badge=[r[4] for r in rows if r[4]!="est"]
    if badge: probs.append(f"BADGE {set(badge)}")
    sorts=[int(r[8]) for r in rows]
    if len(set(sorts))!=len(sorts): probs.append("SORT dup")
    dq=t.count('"')
    if dq: probs.append(f'dquote {dq}')
    for r in rows:
        if r[0] not in vocab: newcodes[r[0]].append(f"{nm}:{r[1]}")
        if r[2]!="NULL": amts.append((nm,r[0],r[1],r[2],r[6][:60] if r[6]!='NULL' else '', r[7]))
    total+=n
    print(f"{name:20s} eng={eng:18s} nm={nm:12s} tp={tp:5s} ind={ind:12s} logo={logo} rows={n:2d} url={url[:60]} {'⚠ '+'; '.join(probs) if probs else 'OK'}")
print("TOTAL rows", total, "=> SD-4 would be", 1755+total)
print("\nNEW CODES (not in vocab 85):")
for c,v in sorted(newcodes.items()): print(f"  {c}: {v}")
print("\nAMOUNT ROWS:")
for a in amts: print("  ",a)
