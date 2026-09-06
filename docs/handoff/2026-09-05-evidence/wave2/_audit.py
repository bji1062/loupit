#!/usr/bin/env python3
"""웨이브 2 코퍼스 횡단 감사 — _precheck.py 확장 확정본 (읽기 전용).

실제 임포트: db.seed.load._split_sql_statements · db.seed.company_meta.parse_header_insert
             · generator.slug.slug_of · db.seed.load_corp._DART_NM_RE

웨이브 1 `_audit2.py` 의 교훈 반영:
  - 문장 종류 판정은 **주석 제거 후** 선두 토큰으로(주석을 본문으로 오인하면 오탐 35건)
  - 인라인 꼬리 주석의 홑따옴표를 따로 본다(분할기가 문자열로 삼킨다)

사용: python3 _audit.py [--json]
"""
from __future__ import annotations

import collections
import csv
import glob
import json
import os
import re
import sys

ROOT = "/home/ubuntu/loupit"
S = "/tmp/claude-0/-home-ubuntu-loupit/bc404160-59bd-48dd-b2d7-94c4ce001a43/scratchpad"
W2 = S + "/wave2"
sys.path.insert(0, ROOT)
sys.path.insert(0, ROOT + "/db/seed")

from db.seed import load, company_meta          # noqa: E402
from generator.slug import slug_of              # noqa: E402
import load_corp                                # noqa: E402

# ── 상수 ──────────────────────────────────────────────────────────────────────
CTGR = {"compensation", "health", "family", "leisure", "perks",
        "growth", "time_off", "flexibility", "work_env"}
CORPUS_ROWS = 1755          # 실측(db/seed/benefit/sql/*.sql), test_seed_counts.py SD-4 핀
CORPUS_COMPANIES = 113

ROW = re.compile(
    r"\(@comp_id,\s*'([a-z_0-9]+)',\s*'((?:[^']|'')*)',\s*(NULL|\d+),\s*'([a-z_]+)',\s*"
    r"'([a-z_]+)',\s*(NULL|'(?:[^']|'')*'),\s*(TRUE|FALSE),\s*(NULL|'(?:[^']|'')*'),\s*(\d+)\)",
    re.S)
HDR = re.compile(
    r"VALUES\s*\('([^']+)',\s*'([^']+)',\s*\(SELECT[^)]*\),\s*'([^']*)',\s*'([^']*)',\s*'([^']*)'")
URL_CMT = re.compile(r"^--\s*URL:\s*(\S+)", re.M)
SRC_CMT = re.compile(r"^--\s*출처:\s*(.+)$", re.M)
UPD_URL = re.compile(r"CAREERS_BENEFIT_URL\s*=\s*'([^']*)'")
DEL_EST = "DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est'"

# VARCHAR 상한(계약)
LIMITS = {"cd": 30, "nm": 100, "note": 200, "qual": 500,
          "eng": 30, "comp_nm": 100, "industry": 50, "logo": 10, "url": 500}

# §9 편집 주석 — 사용자 노출 필드(QUAL_DESC / NOTE / BENEFIT_NM)에 있으면 안 되는 내부·공정 용어
EDIT_TERMS = [
    "코퍼스", "선례", "어휘표", "규칙 ", "수집기", "검증자", "검증 ", "병합", "미수록",
    "회피", "흡수", "정본", "판독", "시드", "SI-B2", "SI-M4", "별도 행", "합쳤다",
    "수록", "정성 항목", "분할기", "UNIQUE", "코드", "행으로", "1행", "AMT",
    "앵커", "함정", "웨이브", "배치", "evidence", "SQL",
]
# 계약이 허용하는 표기(오탐 제거) — 이 문자열을 포함한 매치는 무시
EDIT_ALLOW = ["미기재", "공식 페이지", "공식 채용 페이지", "그룹 채용사이트", "채용사이트",
              "복리후생 페이지", "인사제도 페이지"]


def strip_comments(sql: str) -> str:
    return re.sub(r"^\s*--.*$", "", sql, flags=re.M)


def lead_token(stmt: str) -> str:
    body = strip_comments(stmt).strip()
    return " ".join(body.split()[:3]).upper()


def unesc(s: str) -> str:
    return s.replace("''", "'")


# ── 코퍼스 로드 ───────────────────────────────────────────────────────────────
def load_corpus():
    """기존 113파일 → {eng: (comp_nm, [row…])} · 코드별 사용처."""
    corp, codes = {}, collections.defaultdict(list)
    for f in sorted(glob.glob(ROOT + "/db/seed/benefit/sql/*.sql")):
        t = open(f, encoding="utf-8").read()
        h = HDR.search(t)
        if not h:
            m = re.search(r"VALUES\s*\('([^']+)',\s*'([^']+)'", t)
            eng, nm = (m.group(1), m.group(2)) if m else (os.path.basename(f), "?")
            ind = logo = ""
        else:
            eng, nm, ind, logo = h.group(1), h.group(2), h.group(3), h.group(4)
        rows = ROW.findall(t)
        corp[eng] = dict(nm=nm, industry=ind, logo=logo, rows=rows,
                         file=os.path.basename(f))
        for r in rows:
            codes[r[0]].append((eng, nm, unesc(r[1]), r[3], r[2]))
    return corp, codes


# ── 웨이브 2 로드 + 구조 검사 ────────────────────────────────────────────────
def audit_file(path, corpus, corpus_slugs):
    t = open(path, encoding="utf-8").read()
    name = os.path.basename(path)
    probs = []

    # (1) 실제 분할기
    try:
        stmts = load._split_sql_statements(t)
    except Exception as e:                                   # pragma: no cover
        return dict(file=name, fatal=f"split ERR {e}"), t
    if len(stmts) != 5:
        probs.append(f"BLOCK 문장 수 {len(stmts)}≠5")
    want = ["INSERT IGNORE INTO", "SET @COMP_ID", "UPDATE TCOMPANY",
            "DELETE FROM TCOMPANY_BENEFIT", "INSERT INTO TCOMPANY_BENEFIT"]
    for i, w in enumerate(want[:len(stmts)]):
        lt = lead_token(stmts[i])
        if not lt.startswith(w.split()[0]) or w.split()[-1].replace("TCOMPANY_BENEFIT", "") not in lt.replace(" ", " "):
            pass
    kinds = [lead_token(s) for s in stmts]
    if len(stmts) == 5:
        exp = ["INSERT IGNORE INTO", "SET @COMP_ID =", "UPDATE TCOMPANY SET",
               "DELETE FROM TCOMPANY_BENEFIT", "INSERT INTO TCOMPANY_BENEFIT"]
        for got, e in zip(kinds, exp):
            if not got.startswith(e.split()[0]):
                probs.append(f"문장 종류 {got!r} ≠ {e!r}")

    # (2) 실제 헤더 파서
    try:
        eng, nm, tp = company_meta.parse_header_insert(t)
    except Exception as e:
        eng = nm = tp = None
        probs.append(f"BLOCK parse_header_insert ERR {e}")

    h = HDR.search(t)
    ind = h.group(3) if h else "?"
    logo = h.group(4) if h else "?"
    url_ins = h.group(5) if h else "?"

    # (3) slug
    sl = slug_of(eng) if eng else "?"
    if sl in corpus_slugs:
        probs.append(f"BLOCK slug 충돌 {sl}={corpus_slugs[sl]}")
    if eng and eng in corpus:
        probs.append(f"BLOCK eng 충돌 {eng}")
    if nm and any(v["nm"] == nm for v in corpus.values()):
        probs.append(f"BLOCK COMP_NM 충돌 {nm}")

    # (4) 행 파싱 — 엄격 정규식 vs 원시 개수
    rows = ROW.findall(t)
    raw = len(re.findall(r"^\s*\(@comp_id,", t, re.M))
    if len(rows) != raw:
        probs.append(f"BLOCK 행 정규식 {len(rows)} ≠ 원시 {raw} (10컬럼 형식 이탈)")

    codes = [r[0] for r in rows]
    dup = [c for c, k in collections.Counter(codes).items() if k > 1]
    if dup:
        probs.append(f"BLOCK BENEFIT_CD 중복(UNIQUE) {dup}")
    sorts = [int(r[8]) for r in rows]
    if len(set(sorts)) != len(sorts):
        probs.append("BLOCK SORT 중복")
    if sorts != sorted(sorts):
        probs.append("SORT 단조 아님")
    bad = sorted({r[3] for r in rows} - CTGR)
    if bad:
        probs.append(f"BLOCK 카테고리 도메인 밖 {bad}")
    badge = sorted({r[4] for r in rows} - {"est"})
    if badge:
        probs.append(f"BADGE_CD est 아님 {badge}")

    # (5) QUAL_YN ↔ AMT 불변식
    for r in rows:
        cd, nmv, amt, _c, _b, note, qy, qd, so = r
        if qy == "TRUE":
            if amt != "NULL":
                probs.append(f"BLOCK 불변식 SORT{so} {cd}: QUAL_YN TRUE 인데 AMT={amt}")
            if qd == "NULL":
                probs.append(f"BLOCK 불변식 SORT{so} {cd}: QUAL_YN TRUE 인데 QUAL_DESC NULL")
            if note != "NULL":
                probs.append(f"불변식 SORT{so} {cd}: QUAL TRUE 인데 NOTE 있음")
        else:
            if amt == "NULL":
                probs.append(f"BLOCK 불변식 SORT{so} {cd}: QUAL_YN FALSE 인데 AMT NULL")
            if qd != "NULL":
                probs.append(f"BLOCK 불변식 SORT{so} {cd}: QUAL_YN FALSE 인데 QUAL_DESC 있음")
            if note == "NULL":
                probs.append(f"불변식 SORT{so} {cd}: QUAL FALSE 인데 NOTE NULL")

    # (6) 길이
    for r in rows:
        cd, nmv, _a, _c, _b, note, _q, qd, so = r
        if len(cd) > LIMITS["cd"]:
            probs.append(f"BLOCK 길이 CD {cd}")
        if len(unesc(nmv)) > LIMITS["nm"]:
            probs.append(f"BLOCK 길이 NM SORT{so} {len(unesc(nmv))}")
        if note != "NULL" and len(unesc(note[1:-1])) > LIMITS["note"]:
            probs.append(f"BLOCK 길이 NOTE SORT{so} {len(unesc(note[1:-1]))}>200")
        if qd != "NULL" and len(unesc(qd[1:-1])) > LIMITS["qual"]:
            probs.append(f"BLOCK 길이 QUAL SORT{so} {len(unesc(qd[1:-1]))}>500")
    if eng and len(eng) > LIMITS["eng"]:
        probs.append("BLOCK 길이 ENG")
    if nm and len(nm) > LIMITS["comp_nm"]:
        probs.append("BLOCK 길이 COMP_NM")
    if len(ind) > LIMITS["industry"]:
        probs.append("BLOCK 길이 INDUSTRY")
    if len(logo) > LIMITS["logo"]:
        probs.append("BLOCK 길이 LOGO")
    if len(url_ins) > LIMITS["url"]:
        probs.append("BLOCK 길이 URL")

    # (7) 따옴표 위생 — 겹따옴표 · 주석 안 홑따옴표
    dq = t.count('"')
    if dq:
        probs.append(f"BLOCK 겹따옴표 {dq}개")
    cmt_q = []
    for i, line in enumerate(t.splitlines(), 1):
        st = line.strip()
        if st.startswith("--") and "'" in st:
            cmt_q.append(i)
        elif "--" in line and not st.startswith("--"):
            tail = line.split("--", 1)[1]
            if "'" in tail and line.count("'") % 2:
                cmt_q.append(i)
    if cmt_q:
        probs.append(f"BLOCK 주석 안 홑따옴표 줄 {cmt_q}")

    # (8) 표준 문장·URL 3중 일치·헤더 규약
    if DEL_EST not in re.sub(r"\s+", " ", t):
        probs.append("DELETE est 표준형 불일치")
    if "ON DUPLICATE KEY UPDATE" not in t:
        probs.append("BLOCK ON DUPLICATE KEY UPDATE 없음")
    u_c = URL_CMT.search(t)
    u_u = UPD_URL.search(t)
    urls = {("주석", u_c.group(1) if u_c else None),
            ("INSERT", url_ins),
            ("UPDATE", u_u.group(1) if u_u else None)}
    if len({v for _, v in urls}) != 1:
        probs.append(f"URL 3중 불일치 {sorted(urls)}")
    if not u_c or not u_c.group(1).startswith("http"):
        probs.append("헤더 URL 실 http 아님 (SB-10 scrape_official 근거 없음)")
    src = SRC_CMT.search(t)
    if not src or "AI 파싱" not in src.group(1):
        probs.append("헤더 '출처: AI 파싱' 규약 이탈")

    return dict(file=name, eng=eng, nm=nm, tp=tp, industry=ind, logo=logo,
                url=url_ins, rows=rows, n=len(rows), probs=probs,
                stmts=len(stmts)), t


# ── §9 편집 주석 스캔 ─────────────────────────────────────────────────────────
def scan_editorial(files):
    hits = []
    for f in files:
        for r in f["rows"]:
            cd, nmv, _a, _c, _b, note, _q, qd, so = r
            for fld, raw in (("BENEFIT_NM", nmv),
                             ("NOTE_CTNT", note[1:-1] if note != "NULL" else ""),
                             ("QUAL_DESC", qd[1:-1] if qd != "NULL" else "")):
                s = unesc(raw)
                if not s:
                    continue
                found = []
                for term in EDIT_TERMS:
                    for m in re.finditer(re.escape(term), s):
                        seg = s[max(0, m.start() - 22):m.end() + 22]
                        if any(a in seg for a in EDIT_ALLOW):
                            continue
                        found.append((term, seg))
                if found:
                    hits.append(dict(company=f["nm"], sort=int(so), code=cd,
                                     field=fld, text=s, terms=found))
    return hits


# ── 일관성: 같은 제도가 다른 코드로 ──────────────────────────────────────────
CONCEPTS = {
    "지역전문가·해외파견·학술연수": ["지역전문가", "해외 파견", "해외파견", "학술연수", "학술 연수", "주재원", "국제 파견"],
    "MBA·학위과정": ["MBA", "석사", "대학원", "학위"],
    "명상실·힐링·마음건강": ["명상실", "힐링", "마음건강", "명상"],
    "사택": ["사택"],
    "기숙사": ["기숙사"],
    "셔틀·통근버스": ["셔틀", "통근버스", "통근 버스", "출퇴근 버스"],
    "택시비·귀향버스·유류비": ["택시", "귀향", "유류", "자가운전", "교통보조", "통행료"],
    "웨딩홀·결혼식장 대관": ["결혼식장", "웨딩", "예식"],
    "자녀 입학축하금": ["입학 축하", "입학축하", "입학자녀"],
    "상담실·심리상담": ["심리상담", "상담실", "심리 상담"],
    "사내 병원·건강관리실": ["부속의원", "사내병원", "사내 병원", "보건실", "건강관리실", "헬스케어"],
    "휴게실·라운지": ["휴게실", "라운지", "휴게공간", "휴게 공간"],
    "수면실·안마": ["수면실", "안마", "마사지"],
    "사내 어학·외국어": ["외국어", "어학"],
    "자격증": ["자격증"],
    "사내대출·주택자금": ["주택자금", "주택 구입", "전세", "대출"],
    "복지몰·할인": ["복지몰", "할인"],
    "콘도·리조트·휴양": ["콘도", "리조트", "휴양"],
}


def consistency(files, corpus_codes):
    """개념별로 웨이브 2 + 코퍼스에서 쓰인 코드 분포."""
    out = {}
    for concept, kws in CONCEPTS.items():
        w2 = collections.defaultdict(list)
        for f in files:
            for r in f["rows"]:
                cd, nmv, _a, ctg, _b, note, _q, qd, so = r
                blob = unesc(nmv) + " " + unesc(qd[1:-1] if qd != "NULL" else "") + \
                       " " + unesc(note[1:-1] if note != "NULL" else "")
                if any(k in blob for k in kws):
                    w2[cd].append(f"{f['nm']}:SORT{so}:{unesc(nmv)}")
        cp = collections.Counter()
        for cd, uses in corpus_codes.items():
            for eng, nm, bnm, ctg, amt in uses:
                if any(k in bnm for k in kws):
                    cp[cd] += 1
        if len(w2) > 1 or (w2 and cp and set(w2) - set(cp)):
            out[concept] = dict(wave2={k: v for k, v in w2.items()},
                                corpus=dict(cp.most_common(8)))
    return out


def category_drift(files, corpus_codes):
    """같은 코드가 코퍼스 최빈 카테고리와 다른 카테고리로 간 행."""
    dom = {}
    for cd, uses in corpus_codes.items():
        c = collections.Counter(u[3] for u in uses)
        dom[cd] = c.most_common(1)[0][0] if c else None
    drift = []
    for f in files:
        for r in f["rows"]:
            cd, nmv, _a, ctg, _b, _n, _q, _qd, so = r
            if cd in dom and dom[cd] and ctg != dom[cd]:
                cnt = collections.Counter(u[3] for u in corpus_codes[cd])
                drift.append((f["nm"], int(so), cd, ctg, dom[cd], dict(cnt)))
    return drift


def amount_check(files, corpus_codes):
    """AMT 있는 행 + 무관 회사 간 동일 (코드·금액) 앵커 반복(M-4 강등)."""
    out = []
    anchors = collections.defaultdict(list)
    for cd, uses in corpus_codes.items():
        for eng, nm, bnm, ctg, amt in uses:
            if amt != "NULL":
                anchors[(cd, amt)].append(nm)
    for f in files:
        for r in f["rows"]:
            cd, nmv, amt, _c, _b, note, qy, _qd, so = r
            if amt != "NULL":
                key = (cd, amt)
                out.append(dict(company=f["nm"], sort=int(so), code=cd,
                                nm=unesc(nmv), amt=int(amt),
                                note=unesc(note[1:-1]) if note != "NULL" else None,
                                anchor_hit=anchors.get(key, [])))
    return out


def registration(files):
    """등록 데이터 — 적용된 리포 상태와 대조."""
    rep = {}
    # corp_code_map
    rows = list(csv.DictReader(open(ROOT + "/db/seed/corp_code_map.csv", encoding="utf-8")))
    by_nm = {r["comp_nm"]: r for r in rows}
    # krx_sector
    krx = {r["corp_nm"]: r for r in
           csv.DictReader(open(ROOT + "/generator/data/krx_sector.csv", encoding="utf-8"))}
    # aliases
    aliases = company_meta.WAVE2_ALIASES
    # email
    email = open(ROOT + "/db/seed/company_email_domain.sql", encoding="utf-8").read()

    tbl = []
    for f in files:
        nm, eng = f["nm"], f["eng"]
        cm = by_nm.get(nm)
        dart_ok = None
        if cm and "DART" in (cm["note"] or ""):
            dart_ok = bool(load_corp._DART_NM_RE.search(cm["note"]))
        tbl.append(dict(
            nm=nm, eng=eng, industry=f["industry"], logo=f["logo"], tp=f["tp"],
            corp_map=bool(cm), corp_code=cm["corp_code"] if cm else None,
            comp_id=cm["comp_id"] if cm else None,
            dart_note=(cm["note"] if cm else None) or None, dart_quoted=dart_ok,
            krx=krx.get(nm, {}).get("sector_nm"),
            aliases=aliases.get(eng),
            email=[d for d in re.findall(r"'([a-z0-9.\-]+\.[a-z]{2,})'", email)
                   if f"'{eng}'" in email and d] and None,
            logo_ok=bool(re.fullmatch(r"[A-Z]{1,2}", f["logo"])),
        ))
        # 이메일: eng 가 어느 줄에 등장하는지
        for line in email.splitlines():
            pass
    rep["companies"] = tbl

    # eng 별 이메일 도메인 추출
    dom_by_eng = collections.defaultdict(list)
    email_nc = strip_comments(email)   # ⚠ IN(...) 안의 주석에 괄호가 있어 주석을 먼저 걷는다
    for m in re.finditer(r"SELECT COMP_ID, '([^']+)', TRUE FROM TCOMPANY\s*"
                         r"(?:WHERE COMP_ENG_NM = '([^']+)'|WHERE COMP_ENG_NM IN \(([^)]*)\))",
                         email_nc, re.S):
        dom, single, group = m.group(1), m.group(2), m.group(3)
        if single:
            dom_by_eng[single].append(dom)
        elif group:
            for e in re.findall(r"'([a-z0-9_]+)'", group):
                dom_by_eng[e].append(dom)
    rep["email"] = {t["eng"]: dom_by_eng.get(t["eng"], []) for t in tbl}
    rep["rejected"] = re.findall(r"@rejected:\s*([^\n]+)", email)
    return rep


def main():
    corpus, corpus_codes = load_corpus()
    corpus_slugs = {slug_of(e): v["nm"] for e, v in corpus.items()}
    vocab = set(corpus_codes)

    files, texts = [], {}
    for p in sorted(glob.glob(W2 + "/*.sql")):
        f, t = audit_file(p, corpus, corpus_slugs)
        files.append(f)
        texts[f["file"]] = t

    print("═" * 100)
    print("§A 구조 전수 — 실제 임포트(_split_sql_statements · parse_header_insert · slug_of)")
    print("═" * 100)
    for f in files:
        st = "OK" if not f["probs"] else "⚠"
        print(f"{f['file']:22s} eng={f['eng']:18s} nm={f['nm']:10s} tp={f['tp']:5s} "
              f"ind={f['industry']:12s} logo={f['logo']:2s} rows={f['n']:2d} stmts={f['stmts']} {st}")
        for p in f["probs"]:
            print(f"    → {p}")
    total = sum(f["n"] for f in files)
    print(f"\n합계 {total}행 · SD-4 = {CORPUS_ROWS} + {total} = {CORPUS_ROWS + total}")
    print(f"slug 충돌 0 가정 시 회사 {CORPUS_COMPANIES} + {len(files)} = {CORPUS_COMPANIES + len(files)}")

    print("\n" + "═" * 100)
    print("§B 신규 BENEFIT_CD (코퍼스 실측 %d종 대비)" % len(vocab))
    print("═" * 100)
    new = collections.defaultdict(list)
    for f in files:
        for r in f["rows"]:
            if r[0] not in vocab:
                new[r[0]].append(f"{f['nm']}:SORT{r[8]}:{unesc(r[1])}:{r[3]}")
    for c, v in sorted(new.items()):
        print(f"  {c}: {v}")
    if not new:
        print("  (없음)")
    print("  benefit_edit 코드 정규식 ^[a-z][a-z0-9_]{1,29}$ 통과:",
          all(re.fullmatch(r"[a-z][a-z0-9_]{1,29}", c) for c in new) if new else "n/a")

    print("\n" + "═" * 100)
    print("§C 카테고리 편차 (코퍼스 최빈 대비)")
    print("═" * 100)
    for d in category_drift(files, corpus_codes):
        print(f"  {d[0]} SORT{d[1]} {d[2]}: {d[3]} vs 코퍼스 최빈 {d[4]} {d[5]}")

    print("\n" + "═" * 100)
    print("§D 회사 간 일관성 — 개념별 코드 분포")
    print("═" * 100)
    for k, v in consistency(files, corpus_codes).items():
        print(f"\n  ▸ {k}")
        for cd, uses in sorted(v["wave2"].items()):
            print(f"      W2 {cd:22s} {uses}")
        if v["corpus"]:
            print(f"      코퍼스 {v['corpus']}")

    print("\n" + "═" * 100)
    print("§E 금액 행 + 앵커(M-4) 대조")
    print("═" * 100)
    for a in amount_check(files, corpus_codes):
        print(f"  {a['company']} SORT{a['sort']} {a['code']}={a['amt']} 「{a['nm']}」"
              f" note={a['note']}")
        print(f"      코퍼스 동일 (코드,금액) 앵커: {a['anchor_hit'] or '없음'}")

    print("\n" + "═" * 100)
    print("§F 사용자 노출 필드 편집 주석 전수")
    print("═" * 100)
    hits = scan_editorial(files)
    for h in hits:
        print(f"  {h['company']} SORT{h['sort']} {h['code']} [{h['field']}]"
              f" 용어={sorted({t for t, _ in h['terms']})}")
        print(f"      {h['text']}")
    print(f"  → 지목 행 {len({(h['company'], h['sort']) for h in hits})}개 · 필드 {len(hits)}건")

    print("\n" + "═" * 100)
    print("§G 등록 데이터 (리포 적용 상태와 대조)")
    print("═" * 100)
    rep = registration(files)
    for t in rep["companies"]:
        flags = []
        if not t["corp_map"]:
            flags.append("corp_map 없음")
        if t["dart_note"] and t["dart_quoted"] is False:
            flags.append("BLOCK DART 명 홑따옴표 없음 → CORP_NM 우리 표시명으로 굳음")
        if not t["krx"]:
            flags.append("krx_sector 없음")
        if not t["aliases"]:
            flags.append("별칭 없음")
        if not t["logo_ok"]:
            flags.append(f"LOGO '{t['logo']}' 한글/형식 이탈")
        if not rep["email"].get(t["eng"]):
            flags.append("이메일 도메인 미등록")
        print(f"  {t['nm']:10s} {t['eng']:18s} id={t['comp_id']} corp={t['corp_code']} "
              f"krx={t['krx']} ind={t['industry']} logo={t['logo']} "
              f"mail={rep['email'].get(t['eng'])}")
        if t["aliases"]:
            print(f"      별칭 {t['aliases']}")
        if flags:
            print(f"      ⚠ {'; '.join(flags)}")
    print(f"\n  @rejected 목록: {rep['rejected']}")

    if "--json" in sys.argv:
        json.dump(dict(files=[{k: v for k, v in f.items() if k != "rows"} for f in files],
                       new_codes={k: v for k, v in new.items()},
                       editorial=hits, amounts=amount_check(files, corpus_codes)),
                  open(W2 + "/_audit_rows.json", "w"), ensure_ascii=False, indent=1)
        print("\n  → _audit_rows.json 기록")


if __name__ == "__main__":
    main()
