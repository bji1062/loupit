"""웨이브 4 횡단 감사 — 코퍼스 138사와 함께 놓고 본다.

_precheck.py 의 확장본. 리포 모듈 실제 import(load._split_sql_statements ·
company_meta.parse_header_insert · generator.slug.slug_of).

사용: python3 _audit.py [섹션]
  codes   신규 코드 + 코드별 코퍼스 사용 현황
  consist 회사 간 일관성(같은 제도 다른 코드 / 같은 코드 다른 뜻 / 카테고리 편차)
  amt     금액 전수 + 코퍼스 앵커 대조
  reg     등록 INSERT 표 + INDUSTRY_NM 바이트 대조
  rows    12파일 전 행 덤프
  all     전부
"""
import re, glob, sys, os, collections, unicodedata
sys.path.insert(0, "/home/ubuntu/loupit")
os.chdir("/home/ubuntu/loupit")
from db.seed import load, company_meta
from generator.slug import slug_of

WAVE4 = ["GC녹십자.sql", "HL만도.sql", "JYP.sql", "농심.sql", "동국제약.sql", "이마트.sql",
         "제주반도체.sql", "티에스이.sql", "파두.sql", "풍산.sql", "피에스케이.sql", "현대백화점.sql"]
S = "db/seed/benefit/sql"          # 통합본(리포)
CORPUS = "db/seed/benefit/sql"     # 코퍼스 — 아래에서 WAVE4 를 뺀다
ROW = re.compile(
    r"\(@comp_id,\s*'((?:[^']|'')*)',\s*'((?:[^']|'')*)',\s*(NULL|[\d.]+),\s*'([a-z_]+)',"
    r"\s*'([a-z_]+)',\s*(NULL|'(?:[^']|'')*'),\s*(TRUE|FALSE),\s*(NULL|'(?:[^']|'')*'),\s*(\d+)\)",
    re.S,
)
HDR = re.compile(
    r"VALUES\s*\(\s*'([^']+)',\s*'([^']+)',\s*\(SELECT[^)]*'([a-z]+)'\)\s*,\s*"
    r"(NULL|'[^']*')\s*,\s*(NULL|'[^']*')\s*,\s*(NULL|'[^']*')"
)


def unq(x):
    return None if x == "NULL" else x[1:-1].replace("''", "'")


def parse(path):
    t = open(path, encoding="utf-8").read()
    body = re.sub(r"^\s*--.*$", "", t, flags=re.M)
    rows = []
    for m in ROW.finditer(body):
        cd, nm, amt, ctgr, badge, note, qual, qd, sort = m.groups()
        rows.append(dict(cd=cd, nm=nm.replace("''", "'"), amt=None if amt == "NULL" else amt,
                         ctgr=ctgr, badge=badge, note=unq(note), qual=qual,
                         qd=unq(qd), sort=int(sort)))
    return t, rows


# ── 코퍼스 138사 로드 ─────────────────────────────────────────────
corpus = {}          # comp_nm -> rows
corpus_meta = {}     # comp_nm -> (eng, slug, tp, ind, logo, url, file)
code_use = collections.defaultdict(list)   # code -> [(comp_nm, benefit_nm, ctgr)]
for f in sorted(glob.glob(CORPUS + "/*.sql")):
    if os.path.basename(f) in WAVE4:
        continue
    t, rows = parse(f)
    h = HDR.search(t)
    if not h:
        print("HDR MISS", f); continue
    g = h.groups()
    eng, nm, tp = g[0], g[1], g[2]
    ind, logo, url = [unq(x) for x in g[3:]]
    corpus[nm] = rows
    corpus_meta[nm] = (eng, slug_of(eng), tp, ind, logo, url, os.path.basename(f))
    for r in rows:
        code_use[r["cd"]].append((nm, r["nm"], r["ctgr"]))

wave = {}
wave_meta = {}
for f in sorted(os.path.join(S, b) for b in WAVE4):
    t, rows = parse(f)
    h = HDR.search(t)
    g = h.groups()
    eng, nm, tp = g[0], g[1], g[2]
    ind, logo, url = [unq(x) for x in g[3:]]
    wave[nm] = rows
    wave_meta[nm] = (eng, slug_of(eng), tp, ind, logo, url, os.path.basename(f))

vocab = dict(re.findall(r"^\| `([a-z_0-9]+)` \| *(\d+)", open(
    "docs/handoff/2026-09-19-evidence/_VOCAB.md", encoding="utf-8").read(), re.M))

sec = sys.argv[1] if len(sys.argv) > 1 else "all"


def want(x):
    return sec in (x, "all")


if want("rows"):
    print("=" * 100)
    print("전 행 덤프")
    for nm, rows in wave.items():
        print(f"\n--- {nm} ({len(rows)}행) ---")
        for r in rows:
            a = f" AMT={r['amt']}" if r["amt"] else ""
            print(f"  {r['sort']:>3} {r['cd']:<26} {r['ctgr']:<12} {r['nm']}{a}")
            if r["note"]:
                print(f"       NOTE: {r['note']}")
            print(f"       QUAL({r['qual']}): {r['qd']}")

if want("codes"):
    print("=" * 100)
    print("신규 코드 — 코퍼스 138사 + 어휘표 87종 대비")
    allcodes = collections.Counter()
    for nm, rows in wave.items():
        for r in rows:
            allcodes[r["cd"]] += 1
    new = [c for c in allcodes if c not in code_use]
    print(f"이번 웨이브 코드 종수 {len(allcodes)} · 코퍼스 미사용(=신규) {len(new)}: {sorted(new)}")
    novocab = [c for c in allcodes if c not in vocab]
    print(f"어휘표 미등재: {sorted(novocab)}")
    print("\n[코퍼스에 없는 코드 상세]")
    for c in sorted(new):
        for nm, rows in wave.items():
            for r in rows:
                if r["cd"] == c:
                    print(f"  {c:<22} {nm} SORT {r['sort']} [{r['ctgr']}] {r['nm']}")
                    print(f"      {r['qd']}")

if want("consist"):
    print("=" * 100)
    print("카테고리 편차 — 같은 코드가 코퍼스와 다른 카테고리로 간 것")
    for nm, rows in wave.items():
        for r in rows:
            if r["cd"] in code_use:
                cs = collections.Counter(c for _, _, c in code_use[r["cd"]])
                if r["ctgr"] not in cs:
                    print(f"  ⚠ {nm} SORT {r['sort']} {r['cd']}: 이번={r['ctgr']} 코퍼스={dict(cs)}")
                elif cs[r["ctgr"]] < sum(cs.values()) / 2:
                    print(f"  · {nm} SORT {r['sort']} {r['cd']}: 이번={r['ctgr']} 코퍼스={dict(cs)} (소수파)")
    print("\n웨이브 안 카테고리 편차 (같은 코드, 회사마다 다른 카테고리)")
    bycode = collections.defaultdict(set)
    for nm, rows in wave.items():
        for r in rows:
            bycode[r["cd"]].add((r["ctgr"]))
    for c, s in sorted(bycode.items()):
        if len(s) > 1:
            print(f"  ⚠ {c}: {s}")
            for nm, rows in wave.items():
                for r in rows:
                    if r["cd"] == c:
                        print(f"      {nm} SORT {r['sort']} [{r['ctgr']}] {r['nm']}")
    print("\n코드별 코퍼스 사용 수 (이번 웨이브에 쓰인 코드만)")
    for c in sorted(bycode):
        n = len(set(x[0] for x in code_use.get(c, [])))
        users = [nm for nm in wave if any(r["cd"] == c for r in wave[nm])]
        print(f"  {c:<26} 코퍼스 {n:>3}사 · 어휘표 n={vocab.get(c,'-'):>3} · 이번 {len(users)}사 {users}")

if want("amt"):
    print("=" * 100)
    print("이번 웨이브 AMT 전수")
    for nm, rows in wave.items():
        for r in rows:
            if r["amt"]:
                print(f"  {nm} SORT {r['sort']} {r['cd']} [{r['ctgr']}] AMT={r['amt']} QUAL_YN={r['qual']} QUAL_DESC={r['qd']}")
                print(f"      NM: {r['nm']}")
                print(f"      NOTE: {r['note']}")
    print("\n코퍼스 AMT 통계")
    amt_rows = [(nm, r) for nm, rows in corpus.items() for r in rows if r["amt"]]
    print(f"  AMT 있는 행 {len(amt_rows)} · 그중 QUAL_YN=TRUE {sum(1 for _, r in amt_rows if r['qual'] == 'TRUE')}")
    print(f"  그중 QUAL_DESC 있는 행 {sum(1 for _, r in amt_rows if r['qd'])}")
    for c in ("welfare_point", "housing_support", "holiday_gift", "leisure_ticket"):
        vals = sorted(((float(r["amt"]), nm, r["nm"]) for nm, r in amt_rows if r["cd"] == c), reverse=True)
        print(f"\n  [{c}] 코퍼스 {len(vals)}행")
        for v, nm, bn in vals:
            print(f"      {v:>10,.0f}  {nm:<16} {bn}")
    print("\n  앵커 반복 후보 (같은 (코드, 금액)이 이번 웨이브 + 코퍼스에 함께)")
    anchor = collections.defaultdict(list)
    for nm, r in amt_rows:
        anchor[(r["cd"], r["amt"])].append(nm)
    for nm, rows in wave.items():
        for r in rows:
            if r["amt"] and (r["cd"], r["amt"]) in anchor:
                print(f"      {r['cd']} {r['amt']}: 이번 {nm} ↔ 코퍼스 {anchor[(r['cd'], r['amt'])]}")

if want("reg"):
    print("=" * 100)
    print("등록 INSERT 12행")
    for nm, (eng, sl, tp, ind, logo, url, fn) in wave_meta.items():
        print(f"  {fn:<18} eng={eng:<16} nm={nm:<10} tp={tp:<6} ind={ind:<10} logo={logo}")
        print(f"      slug={sl}  url={url}")
    print("\nINDUSTRY_NM 바이트 대조")
    for nm in ("현대백화점", "이마트"):
        ind = wave_meta[nm][3]
        print(f"  {nm}: {ind!r} bytes={ind.encode('utf-8').hex()} NFC={unicodedata.is_normalized('NFC', ind)}")
    inds = collections.Counter(m[3] for m in corpus_meta.values())
    print(f"\n코퍼스 INDUSTRY_NM {len(inds)}종")
    for i, n in sorted(inds.items(), key=lambda x: -x[1]):
        print(f"  {n:>3}  {i}")
    print("\n이번 웨이브 INDUSTRY_NM 합류 결과")
    for nm, m in wave_meta.items():
        cur = inds.get(m[3], 0)
        same_wave = [x for x in wave_meta if wave_meta[x][3] == m[3]]
        print(f"  {nm:<10} {m[3]:<10} 코퍼스 {cur}사 + 이번 {len(same_wave)}사 = {cur+len(same_wave)}"
              + ("   ⚠ 신규 라벨" if cur == 0 else ""))
    print("\n로고 첫 글자 대조")
    for nm, m in wave_meta.items():
        print(f"  {nm:<10} logo={m[4]}  eng={m[0]}")
    print("\nslug 충돌")
    cs = {m[1]: nm for nm, m in corpus_meta.items()}
    for nm, m in wave_meta.items():
        print(f"  {m[1]:<16} {'COLLISION ' + cs[m[1]] if m[1] in cs else 'free'}")
