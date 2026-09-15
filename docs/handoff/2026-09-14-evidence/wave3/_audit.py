#!/usr/bin/env python3
"""웨이브 3 코퍼스 횡단 감사 — _precheck.py 확장본 (읽기 전용, 2026-09-15).

실제 임포트: db.seed.load._split_sql_statements · db.seed.company_meta.parse_header_insert
             · db.seed.company_meta.build_company_meta · generator.slug.slug_of
             · db.seed.load_corp(_DART_NM_RE · read_map · dart_corp_nm)
             · server/tests/test_seed_email_domain.py(_parse · _rejected · SED-5 · SED-7 본체)

웨이브 2 `_audit.py` 뼈대 + 웨이브 3 추가:
  - 법정 제도 문구 스캔(규칙 3) — 편집 주석 스캔과 분리해 행별로 낸다
  - 개념 사전을 이번 웨이브 쟁점(리프레시·집중휴가·보상휴가·사내근로복지기금·보조금·주말농장·장애·
    스톡옵션·데스크테리어·AI 도구·수유실·자기계발 포인트·출산장려금·식대 일액)으로 교체
  - 코퍼스 refresh_leave 전 행 · parenting AMT 행 · meal 240일 환산 행 덤프
  - corp_code 공유 · CSV 줄끝(CRLF/LF) · 별칭 회사 간 충돌 · 이메일 SED-5/7 실제 함수 호출
  - company_registrations.json 대조

사용: python3 _audit.py [--json]
"""
from __future__ import annotations

import collections
import csv
import glob
import importlib.util
import json
import os
import re
import sys

ROOT = "/home/ubuntu/loupit"
S = "/tmp/claude-0/-home-ubuntu-loupit/723f8817-c77d-4e78-ab10-c256a6b1bdd7/scratchpad"
W3 = S + "/wave3"
sys.path.insert(0, ROOT)
sys.path.insert(0, ROOT + "/db/seed")

from db.seed import load, company_meta          # noqa: E402
from generator.slug import slug_of              # noqa: E402
import load_corp                                # noqa: E402

CTGR = {"compensation", "health", "family", "leisure", "perks",
        "growth", "time_off", "flexibility", "work_env"}
CORPUS_ROWS = 2032          # test_seed_counts.py SD-4 현재 핀
CORPUS_COMPANIES = 126

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
LIMITS = {"cd": 30, "nm": 100, "note": 200, "qual": 500,
          "eng": 30, "comp_nm": 100, "industry": 50, "logo": 10, "url": 500}

# §9 편집 주석 — 웨이브 2 목록 + 통합 계약 규칙 4 목록
EDIT_TERMS = [
    "코퍼스", "선례", "어휘", "규칙", "수집기", "수집", "검증", "병합", "미수록",
    "회피", "흡수", "정본", "판독", "시드", "SI-B2", "별도 행", "합쳤다", "합침",
    "수록", "정성 항목", "부연", "우리 판단", "⚠", "분할기", "UNIQUE", "코드", "행으로",
    "1행", "AMT", "앵커", "함정", "웨이브", "evidence", "SQL", "환산", "추정", "분리",
    "이미지", "교차 확인", "원문에 없", "한 행에", "같은 코드", "조각", "단정",
]
EDIT_ALLOW = []   # 웨이브 2 는 허용 표기로 오탐을 걷었으나, 이번엔 전부 내고 사람이 판정한다
# 규칙 3 — 법정 제도 문구(행이든 서술이든 금지. 원문이 상회분을 스스로 나눠 밝힌 경우만 예외 판정)
LEGAL_TERMS = [
    "법정", "시차 출근", "시차출근", "난임 휴가", "난임휴가", "난임치료휴가", "근로자의 날", "노동절",
    "출산휴가", "출산 휴가", "출산전후", "출산 전후", "산전후", "배우자 출산", "육아휴직", "육아 휴직",
    "육아기", "임신기", "가족돌봄", "가족 돌봄", "4대", "사회보험", "퇴직연금", "퇴직금", "연차",
    "주5일", "주 5일", "태아 검진", "유산", "사산", "수유", "모성보호", "근로기준법",
]


def strip_comments(sql: str) -> str:
    return re.sub(r"^\s*--.*$", "", sql, flags=re.M)


def lead_token(stmt: str) -> str:
    body = strip_comments(stmt).strip()
    return " ".join(body.split()[:3]).upper()


def unesc(s: str) -> str:
    return s.replace("''", "'")


def fields(r):
    cd, nmv, amt, ctg, _b, note, qy, qd, so = r
    return dict(cd=cd, nm=unesc(nmv), amt=amt, ctg=ctg, qy=qy, so=int(so),
                note=unesc(note[1:-1]) if note != "NULL" else "",
                qual=unesc(qd[1:-1]) if qd != "NULL" else "")


# ── 코퍼스 ────────────────────────────────────────────────────────────────────
def load_corpus():
    corp, codes = {}, collections.defaultdict(list)
    raw_total = regex_total = 0
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
        raw = len(re.findall(r"^\s*\(@comp_id,", t, re.M))
        raw_total += raw
        regex_total += len(rows)
        corp[eng] = dict(nm=nm, industry=ind, logo=logo, rows=rows,
                         file=os.path.basename(f), raw=raw)
        for r in rows:
            codes[r[0]].append((eng, nm, r))
    return corp, codes, raw_total, regex_total


# ── 웨이브 3 파일 구조 검사 ───────────────────────────────────────────────────
def audit_file(path, corpus, corpus_slugs):
    t = open(path, encoding="utf-8").read()
    name = os.path.basename(path)
    probs = []
    stmts = load._split_sql_statements(t)
    if len(stmts) != 5:
        probs.append(f"BLOCK 문장 수 {len(stmts)}≠5")
    else:
        exp = ["INSERT", "SET", "UPDATE", "DELETE", "INSERT"]
        for got, e in zip([lead_token(s) for s in stmts], exp):
            if not got.startswith(e):
                probs.append(f"문장 종류 {got!r} ≠ {e!r}")
        if "TCOMPANY_BENEFIT" not in lead_token(stmts[4]).replace(" ", " ") and \
                "TCOMPANY_BENEFIT" not in strip_comments(stmts[4])[:80]:
            probs.append("5번째 문장이 TCOMPANY_BENEFIT INSERT 가 아님")
    try:
        eng, nm, tp = company_meta.parse_header_insert(t)
    except Exception as e:
        eng = nm = tp = None
        probs.append(f"BLOCK parse_header_insert ERR {e}")
    h = HDR.search(t)
    ind, logo, url_ins = (h.group(3), h.group(4), h.group(5)) if h else ("?", "?", "?")
    sl = slug_of(eng) if eng else "?"
    if sl in corpus_slugs:
        probs.append(f"BLOCK slug 충돌 {sl}={corpus_slugs[sl]}")
    if eng and eng in corpus:
        probs.append(f"BLOCK eng 충돌 {eng}")
    if nm and any(v["nm"] == nm for v in corpus.values()):
        probs.append(f"BLOCK COMP_NM 충돌 {nm}")
    rows = ROW.findall(t)
    raw = len(re.findall(r"^\s*\(@comp_id,", t, re.M))
    if len(rows) != raw:
        probs.append(f"BLOCK 행 정규식 {len(rows)} ≠ 원시 {raw}")
    codes = [r[0] for r in rows]
    dup = [c for c, k in collections.Counter(codes).items() if k > 1]
    if dup:
        probs.append(f"BLOCK BENEFIT_CD 중복 {dup}")
    sorts = [int(r[8]) for r in rows]
    if len(set(sorts)) != len(sorts):
        probs.append("BLOCK SORT 중복")
    if sorts != sorted(sorts):
        probs.append("SORT 단조 아님")
    # 섹션 규칙: 같은 10단위 섹션 안 카테고리 1종
    sec = collections.defaultdict(set)
    for r in rows:
        sec[int(r[8]) // 10].add(r[3])
    mixed = {k * 10: v for k, v in sec.items() if len(v) > 1}
    if mixed:
        probs.append(f"SORT 섹션 안 카테고리 혼재 {mixed}")
    bad = sorted({r[3] for r in rows} - CTGR)
    if bad:
        probs.append(f"BLOCK 카테고리 도메인 밖 {bad}")
    badge = sorted({r[4] for r in rows} - {"est"})
    if badge:
        probs.append(f"BADGE_CD est 아님 {badge}")
    for r in rows:
        cd, nmv, amt, _c, _b, note, qy, qd, so = r
        if qy == "TRUE":
            if amt != "NULL":
                probs.append(f"BLOCK 불변식 SORT{so} {cd}: QUAL TRUE·AMT={amt}")
            if qd == "NULL":
                probs.append(f"BLOCK 불변식 SORT{so} {cd}: QUAL TRUE·QUAL_DESC NULL")
            if note != "NULL":
                probs.append(f"불변식 SORT{so} {cd}: QUAL TRUE·NOTE 있음")
        else:
            if amt == "NULL":
                probs.append(f"BLOCK 불변식 SORT{so} {cd}: QUAL FALSE·AMT NULL")
            if qd != "NULL":
                probs.append(f"BLOCK 불변식 SORT{so} {cd}: QUAL FALSE·QUAL_DESC 있음")
            if note == "NULL":
                probs.append(f"불변식 SORT{so} {cd}: QUAL FALSE·NOTE NULL")
        if len(cd) > LIMITS["cd"]:
            probs.append(f"BLOCK 길이 CD {cd}")
        if len(unesc(nmv)) > LIMITS["nm"]:
            probs.append(f"BLOCK 길이 NM SORT{so}")
        if note != "NULL" and len(unesc(note[1:-1])) > LIMITS["note"]:
            probs.append(f"BLOCK 길이 NOTE SORT{so} {len(unesc(note[1:-1]))}>200")
        if qd != "NULL" and len(unesc(qd[1:-1])) > LIMITS["qual"]:
            probs.append(f"BLOCK 길이 QUAL SORT{so} {len(unesc(qd[1:-1]))}>500")
        if not re.fullmatch(r"[a-z][a-z0-9_]{1,29}", cd):
            probs.append(f"BLOCK 코드 정규식 이탈 {cd}")
    for k, v in (("eng", eng), ("comp_nm", nm), ("industry", ind), ("logo", logo), ("url", url_ins)):
        if v and len(v) > LIMITS[k]:
            probs.append(f"BLOCK 길이 {k}")
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
    ent = re.findall(r"&[a-zA-Z]+;|&#\d+;", t)
    if ent:
        probs.append(f"BLOCK HTML 엔티티(세미콜론이 분할기를 쪼갬) {ent}")
    zw = [hex(ord(c)) for c in t if c in "​‌‍﻿ ᆞ"]
    if zw:
        probs.append(f"보이지 않는 문자 {collections.Counter(zw)}")
    if DEL_EST not in re.sub(r"\s+", " ", t):
        probs.append("DELETE est 표준형 불일치")
    if "ON DUPLICATE KEY UPDATE" not in t:
        probs.append("BLOCK ON DUPLICATE KEY UPDATE 없음")
    u_c, u_u = URL_CMT.search(t), UPD_URL.search(t)
    urls = {u_c.group(1) if u_c else None, url_ins, u_u.group(1) if u_u else None}
    if len(urls) != 1:
        probs.append(f"URL 3중 불일치 {urls}")
    if not u_c or not u_c.group(1).startswith("http"):
        probs.append("헤더 URL 실 http 아님")
    src = SRC_CMT.search(t)
    if not src or "AI 파싱" not in src.group(1):
        probs.append("헤더 출처: AI 파싱 규약 이탈")
    return dict(file=name, eng=eng, nm=nm, tp=tp, industry=ind, logo=logo,
                url=url_ins, rows=rows, n=len(rows), probs=probs, stmts=len(stmts),
                slug=sl)


def scan_terms(files, terms, allow=()):
    hits = []
    for f in files:
        for r in f["rows"]:
            d = fields(r)
            for fld, s in (("BENEFIT_NM", d["nm"]), ("NOTE_CTNT", d["note"]), ("QUAL_DESC", d["qual"])):
                if not s:
                    continue
                found = []
                for term in terms:
                    for m in re.finditer(re.escape(term), s):
                        seg = s[max(0, m.start() - 18):m.end() + 18]
                        if any(a in seg for a in allow):
                            continue
                        found.append((term, seg))
                if found:
                    hits.append(dict(company=f["nm"], sort=d["so"], code=d["cd"], field=fld,
                                     text=s, terms=sorted({t for t, _ in found}),
                                     segs=[g for _, g in found]))
    return hits


CONCEPTS = {
    "리프레시·안식·힐링데이": ["리프레시", "리프레쉬", "Refresh", "refresh", "안식", "힐링데이", "힐링 Day", "돌봄데이", "돌봄 Day", "Re-Fill"],
    "집중휴가·단체휴가": ["집중 휴가", "집중휴가", "休weeks", "단체휴가", "단체 휴가"],
    "보상휴가·출장·심야": ["보상휴가", "출장", "심야", "Overnight"],
    "장기근속 포상/휴가": ["장기근속", "장기 근속", "근속휴가", "근속 휴가", "근속포상"],
    "하계·여름·동계 휴가(비)": ["하계", "하기", "여름 휴가", "여름휴가", "동계"],
    "사내근로복지기금": ["근로복지기금", "복지기금"],
    "대출(용도 미특정 포함)": ["대출", "대부"],
    "차량·교통 보조금": ["차량", "보조금", "자가운전", "유류", "교통비"],
    "통근·셔틀": ["통근", "셔틀", "출근버스", "출퇴근 버스"],
    "MBA·석사·대학원·지역전문가": ["MBA", "석사", "대학원", "지역전문가", "지역 전문가", "유학", "학위"],
    "자격증": ["자격증", "자격 취득"],
    "어학": ["어학", "외국어", "영어", "Luniversal", "루니버셜"],
    "주말농장·농장": ["농장", "텃밭"],
    "장애": ["장애"],
    "스톡옵션·우리사주": ["스톡옵션", "주식매수", "우리사주", "주식"],
    "데스크테리어·가구": ["데스크테리어", "가구", "의자", "책상"],
    "AI·소프트웨어·장비": ["AI Tool", "AI 도구", "소프트웨어", "SaaS", "장비", "노트북", "모니터"],
    "어린이집·보육": ["어린이집", "보육"],
    "수유실·Nursing": ["수유", "Nursing", "모유"],
    "복지몰·할인몰": ["복지몰", "할인몰", "제휴 할인", "제휴할인"],
    "자기계발 포인트": ["자기계발 포인트", "자기개발포인트", "자기계발포인트"],
    "선물(생일·기념일·출산·명절·창립)": ["선물"],
    "출산장려금·축하금": ["출산장려금", "출산 장려금", "출산축하금", "출산 축하금"],
    "식대 일액": ["식대", "식비"],
    "재택·원격": ["재택", "원격"],
    "주4일·해피프라이데이·놀금": ["주 4일", "주4일", "해피프라이데이", "놀금", "금요일"],
    "결혼식장·예식·신혼여행": ["결혼식", "예식", "신혼여행", "웨딩"],
    "명상·힐링·마음건강": ["명상", "힐링", "마음"],
    "독감·예방접종": ["독감", "예방접종"],
    "릴렉스·안마·휴게": ["릴렉스", "안마", "휴게", "휴식공간", "리클라이너"],
    "이사·정착·숙소": ["이사", "정착", "숙소"],
    "사택·기숙사": ["사택", "기숙사"],
    "가족친화 프로그램·행사": ["가족 친화", "가족친화", "송년회", "워크샵", "체육대회", "사내 이벤트"],
    "회식": ["회식"],
    "북카페·도서": ["북카페", "도서"],
    "스마트오피스·거점": ["스마트오피스", "스마트 오피스", "거점"],
    "학회·컨퍼런스": ["학회", "컨퍼런스", "세미나"],
    "상병·진료예약·중증": ["상병", "진료예약", "중증", "중대 질환"],
    "교복·취학·수능·돌반지": ["교복", "취학", "수능", "돌반지"],
    "캐리비안·이용권·영화": ["캐리비안", "이용권", "영화"],
}


def consistency(files, corpus_codes):
    out = {}
    for concept, kws in CONCEPTS.items():
        w3 = collections.defaultdict(list)
        for f in files:
            for r in f["rows"]:
                d = fields(r)
                blob = d["nm"] + " " + d["qual"] + " " + d["note"]
                if any(k in blob for k in kws):
                    w3[d["cd"]].append(f"{f['nm']}:{d['so']}:{d['nm']}")
        cp = collections.Counter()
        ex = collections.defaultdict(list)
        for cd, uses in corpus_codes.items():
            for eng, nm, r in uses:
                d = fields(r)
                if any(k in d["nm"] for k in kws):
                    cp[cd] += 1
                    if len(ex[cd]) < 4:
                        ex[cd].append(f"{nm}:{d['nm']}")
        if w3:
            out[concept] = dict(wave3=dict(w3), corpus=dict(cp.most_common(10)),
                                examples={k: ex[k] for k, _ in cp.most_common(10)})
    return out


def category_drift(files, corpus_codes):
    drift = []
    for f in files:
        for r in f["rows"]:
            d = fields(r)
            uses = corpus_codes.get(d["cd"])
            if not uses:
                continue
            cnt = collections.Counter(u[2][3] for u in uses)
            top = cnt.most_common(1)[0][0]
            if d["ctg"] != top:
                drift.append((f["nm"], d["so"], d["cd"], d["ctg"], top, dict(cnt)))
    return drift


def amounts(files, corpus_codes):
    anchors = collections.defaultdict(list)
    for cd, uses in corpus_codes.items():
        for eng, nm, r in uses:
            if r[2] != "NULL":
                anchors[(cd, r[2])].append(nm)
    out = []
    for f in files:
        for r in f["rows"]:
            d = fields(r)
            if d["amt"] != "NULL":
                out.append(dict(company=f["nm"], sort=d["so"], code=d["cd"], nm=d["nm"],
                                amt=int(d["amt"]), note=d["note"],
                                anchor_hit=anchors.get((d["cd"], d["amt"]), [])))
    return out


def corpus_dump(corpus_codes, code, pred=lambda d: True):
    rows = []
    for eng, nm, r in corpus_codes.get(code, []):
        d = fields(r)
        if pred(d):
            rows.append((nm, d["so"], d["nm"], d["amt"], d["ctg"], d["note"][:90], d["qual"][:110]))
    return rows


def registration(files, corpus):
    rep = {}
    cmap = load_corp.read_map()
    by_nm = {r["comp_nm"]: r for r in cmap}
    mapped = [r for r in cmap if r["status"] != "UNMAPPED"]
    rep["fn1"] = (len(mapped), len({r["corp_code"] for r in mapped}))
    cc = collections.Counter(r["corp_code"] for r in mapped)
    rep["shared_corp"] = {k: [r["comp_nm"] for r in mapped if r["corp_code"] == k]
                          for k, v in cc.items() if v > 1}
    dart = {r["name"]: r for r in csv.DictReader(open(S + "/corp_codes_wave3.csv", encoding="utf-8"))}
    krx = {r["corp_nm"]: r for r in csv.DictReader(open(ROOT + "/generator/data/krx_sector.csv", encoding="utf-8"))}
    krx_stock = collections.Counter(r["stock_cd"] for r in krx.values())
    meta = company_meta.build_company_meta()
    alias_owner = collections.defaultdict(set)
    for e, m in meta.items():
        for a in m.get("aliases", []):
            alias_owner[a.strip().lower()].add(e)
    names_owner = collections.defaultdict(set)
    for e, v in corpus.items():
        names_owner[v["nm"].lower()].add(e)
    tbl = []
    for f in files:
        nm, eng = f["nm"], f["eng"]
        cm = by_nm.get(nm)
        dn = dart.get(nm)
        al = (meta.get(eng) or {}).get("aliases")
        waves3 = company_meta.WAVE3_ALIASES.get(eng, [])
        cross = {a: sorted(alias_owner[a.lower()] - {eng}) for a in (al or []) if alias_owner[a.lower()] - {eng}}
        cross_nm = {a: sorted(names_owner[a.lower()]) for a in (al or []) if a.lower() in names_owner and eng not in names_owner[a.lower()]}
        tbl.append(dict(
            nm=nm, eng=eng, tp=f["tp"], industry=f["industry"], logo=f["logo"],
            corp_map=bool(cm), comp_id=cm["comp_id"] if cm else None,
            corp_code=cm["corp_code"] if cm else None, stock=cm["stock_code"] if cm else None,
            note=cm["note"] if cm else None,
            dart_nm_parsed=load_corp.dart_corp_nm(cm) if cm and hasattr(load_corp, "dart_corp_nm") else None,
            dart_csv=dn["dart_name"] if dn else None,
            dart_code_ok=(dn["corp_code"] == cm["corp_code"] and dn["stock_code"] == cm["stock_code"]) if (dn and cm) else None,
            krx=krx.get(nm, {}).get("sector_nm"), krx_stock=krx.get(nm, {}).get("stock_cd"),
            aliases=al, wave3_aliases=waves3, alias_cross=cross, alias_vs_other_compnm=cross_nm,
        ))
    rep["companies"] = tbl
    rep["krx_dup_stock"] = [k for k, v in krx_stock.items() if v > 1]
    # 이메일 — 테스트 모듈 본체를 그대로 부른다
    spec = importlib.util.spec_from_file_location("sed", ROOT + "/server/tests/test_seed_email_domain.py")
    sed = importlib.util.module_from_spec(spec)
    try:
        spec.loader.exec_module(sed)
        pairs = sed._parse()
        rep["email"] = {t["eng"]: sorted({(d, sh) for s, d, sh in pairs if s == t["eng"]}) for t in tbl}
        rep["rejected"] = sed._rejected()
        try:
            sed.test_SED5_single_company_domain_is_not_reused()
            rep["SED5"] = "PASS"
        except AssertionError as e:
            rep["SED5"] = f"FAIL {e}"
        try:
            sed.test_SED7_rejected_domains_are_not_registered()
            sed.test_SED7_rejected_entries_carry_a_reason()
            rep["SED7"] = "PASS"
        except AssertionError as e:
            rep["SED7"] = f"FAIL {e}"
        try:
            sed.test_SED3_no_freemail_domains()
            rep["SED3"] = "PASS"
        except AssertionError as e:
            rep["SED3"] = f"FAIL {e}"
        bad_fmt = [d for _, d, _ in pairs if not sed._DOMAIN_RE.match(d)]
        rep["SED4_bad"] = bad_fmt
        grp = collections.defaultdict(set)
        for s, d, sh in pairs:
            grp[d].add(s)
        rep["group_domains"] = {d: sorted(v) for d, v in grp.items() if len(v) > 1}
    except Exception as e:  # pragma: no cover
        rep["email_err"] = repr(e)
    # 줄끝
    ends = {}
    for p in ("generator/data/krx_sector.csv", "db/seed/corp_code_map.csv"):
        b = open(ROOT + "/" + p, "rb").read()
        lines = b.split(b"\n")[:-1]
        new = [l for l in lines if any(x["nm"].encode() in l for x in files)]
        ends[p] = dict(total=len(lines), crlf=sum(l.endswith(b"\r") for l in lines),
                       new=len(new), new_crlf=sum(l.endswith(b"\r") for l in new),
                       ends_nl=b.endswith(b"\n"))
    rep["line_endings"] = ends
    # 등록 이력
    reg = json.load(open(ROOT + "/generator/data/company_registrations.json", encoding="utf-8"))
    listed = {e for w in reg["waves"] for e in w["companies"]}
    rep["registrations_missing"] = sorted(t["eng"] for t in tbl if t["eng"] not in listed)
    rep["registrations_waves"] = [(w["date"], w["label"], len(w["companies"])) for w in reg["waves"]]
    return rep


def main():
    corpus, corpus_codes, raw_total, regex_total = load_corpus()
    corpus_slugs = {slug_of(e): v["nm"] for e, v in corpus.items()}
    vocab = set(corpus_codes)
    files = [audit_file(p, corpus, corpus_slugs) for p in sorted(glob.glob(W3 + "/*.sql"))]
    w3_slugs = collections.Counter(f["slug"] for f in files)

    P = print
    P("═" * 100)
    P(f"§0 코퍼스 실측: 파일 {len(corpus)} · 원시 행 {raw_total} · 엄격 정규식 행 {regex_total} · 코드 {len(vocab)}종")
    for e, v in corpus.items():
        if v["raw"] != len(v["rows"]):
            P(f"   코퍼스 정규식 누락: {v['file']} raw {v['raw']} vs regex {len(v['rows'])}")
    P("§A 구조 전수 — 실제 임포트(_split_sql_statements · parse_header_insert · slug_of)")
    P("═" * 100)
    for f in files:
        st = "OK" if not f["probs"] else "⚠"
        P(f"{f['file']:22s} eng={f['eng']:14s} slug={f['slug']:14s} nm={f['nm']:10s} tp={f['tp']:5s} "
          f"ind={f['industry']:8s} logo={f['logo']} rows={f['n']:2d} stmts={f['stmts']} {st}")
        for p in f["probs"]:
            P(f"    → {p}")
    if any(v > 1 for v in w3_slugs.values()):
        P(f"  BLOCK 웨이브 안 slug 충돌 {w3_slugs}")
    total = sum(f["n"] for f in files)
    P(f"\n합계 {total}행 · 현 SD-4 {CORPUS_ROWS} + {total} = {CORPUS_ROWS + total} (조치 전)")

    P("\n" + "═" * 100)
    P(f"§B 신규 BENEFIT_CD (코퍼스 실측 {len(vocab)}종 대비)")
    P("═" * 100)
    new = collections.defaultdict(list)
    for f in files:
        for r in f["rows"]:
            if r[0] not in vocab:
                d = fields(r)
                new[r[0]].append(f"{f['nm']}:SORT{d['so']}:{d['nm']}:{d['ctg']}")
    for c, v in sorted(new.items()):
        P(f"  {c}: {v}")
    P("  코드 사용처(리포 SQL 밖 참조):")
    for c in sorted(new):
        hits = os.popen(f"grep -rl --exclude-dir=.git --exclude-dir=node_modules '{c}' {ROOT} 2>/dev/null | head -5").read().split()
        P(f"    {c}: {hits or '없음'}")

    P("\n" + "═" * 100)
    P("§C 카테고리 편차 (코퍼스 최빈 대비)")
    P("═" * 100)
    for d in category_drift(files, corpus_codes):
        P(f"  {d[0]} SORT{d[1]} {d[2]}: {d[3]} vs 최빈 {d[4]} {d[5]}")

    P("\n" + "═" * 100)
    P("§D 회사 간 일관성 — 개념별 코드 분포(웨이브 3 전 행 NM+QUAL+NOTE / 코퍼스 NM)")
    P("═" * 100)
    for k, v in consistency(files, corpus_codes).items():
        P(f"\n  ▸ {k}")
        for cd, uses in sorted(v["wave3"].items()):
            P(f"      W3 {cd:22s} {uses}")
        if v["corpus"]:
            P(f"      코퍼스 {v['corpus']}")
            for cd, exs in v["examples"].items():
                P(f"         {cd}: {exs}")

    P("\n" + "═" * 100)
    P("§E 금액 행 + (코드,금액) 앵커")
    P("═" * 100)
    for a in amounts(files, corpus_codes):
        P(f"  {a['company']} SORT{a['sort']} {a['code']}={a['amt']} 「{a['nm']}」 NOTE={a['note']}")
        P(f"      코퍼스 동일 (코드,금액): {a['anchor_hit'] or '없음'}")
    P("\n  코퍼스 parenting·fertility_support·wedding·event AMT 행(1회성 지급 선례):")
    for code in ("parenting", "fertility_support", "wedding", "event", "child_edu"):
        for row in corpus_dump(corpus_codes, code, lambda d: d["amt"] != "NULL"):
            P(f"     {code:18s} {row[0]:10s} {row[2]} = {row[3]} | {row[5]}")
    P("\n  코퍼스 meal AMT 행 중 일액 환산(240·일·x) 표기:")
    n432 = 0
    for row in corpus_dump(corpus_codes, "meal", lambda d: d["amt"] != "NULL"):
        if row[3] == "432":
            n432 += 1
        if re.search(r"240|일\s*\d|x|×|\*|추정", row[5]):
            P(f"     {row[0]:10s} {row[2]} = {row[3]} | {row[5]}")
    P(f"     meal=432 행 수 {n432}")
    P("\n  코퍼스 resort·welfare_point 에서 격년·포인트 환산 표기:")
    for code in ("resort", "welfare_point"):
        for row in corpus_dump(corpus_codes, code, lambda d: d["amt"] != "NULL" and re.search(r"격년|환산|2년", d["note"])):
            P(f"     {code} {row[0]} {row[2]} = {row[3]} | {row[5]}")

    P("\n" + "═" * 100)
    P("§F 코퍼스 refresh_leave 전 행 · long_service_leave 중 리프레시 · leave_general 중 집중/보상/단체")
    P("═" * 100)
    for row in corpus_dump(corpus_codes, "refresh_leave"):
        P(f"  RL  {row[0]:12s} {row[2]:28s} amt={row[3]} | {row[6] or row[5]}")
    for row in corpus_dump(corpus_codes, "long_service_leave", lambda d: re.search(r"리프레|Refresh|refresh|안식", d["nm"] + d["qual"])):
        P(f"  LSL {row[0]:12s} {row[2]:28s} | {row[6]}")
    for row in corpus_dump(corpus_codes, "leave_general", lambda d: re.search(r"집중|보상|단체|출장|심야|리프레|Refresh", d["nm"] + d["qual"])):
        P(f"  LG  {row[0]:12s} {row[2]:28s} | {row[6]}")
    for row in corpus_dump(corpus_codes, "summer_leave", lambda d: re.search(r"집중|休", d["nm"] + d["qual"])):
        P(f"  SL  {row[0]:12s} {row[2]:28s} | {row[6]}")
    for code in ("welfare_fund_loan", "stock_option", "office_furniture", "work_tools", "welcome_kit", "family_day", "leisure_ticket", "company_event", "remote_work", "mba", "career", "self_development", "lang"):
        P(f"\n  [{code}]")
        for row in corpus_dump(corpus_codes, code):
            P(f"     {row[0]:12s} {row[2]:30s} {row[4]} | {row[6][:90]}")

    P("\n" + "═" * 100)
    P("§G 편집 주석(내부 용어) 스캔 — 전부 출력, 사람이 판정")
    P("═" * 100)
    ed = scan_terms(files, EDIT_TERMS, EDIT_ALLOW)
    for h in ed:
        P(f"  {h['company']} SORT{h['sort']} {h['code']} [{h['field']}] {h['terms']} :: {h['segs'][:3]}")
    P(f"  → 필드 {len(ed)}건")
    P("\n§G2 법정 제도 문구 스캔")
    lg = scan_terms(files, LEGAL_TERMS)
    for h in lg:
        P(f"  {h['company']} SORT{h['sort']} {h['code']} [{h['field']}] {h['terms']} :: {h['text']}")
    P(f"  → 필드 {len(lg)}건")
    P("\n§G3 법인명·출처 문구(더존비즈온 채용공고·지속가능경영보고서 등) 행 수")
    for f in files:
        c = sum(1 for r in f["rows"] if "채용공고" in fields(r)["qual"] or "보고서" in fields(r)["qual"] + fields(r)["note"])
        g = sum(1 for r in f["rows"] if "그룹 통합 채용 기준" in fields(r)["qual"] + fields(r)["note"])
        if c or g:
            P(f"  {f['nm']}: 공고/보고서 출처 {c}행 · 그룹 각주 {g}행 / {f['n']}")

    P("\n" + "═" * 100)
    P("§H 등록 데이터 (리포 브랜치 반영본과 대조)")
    P("═" * 100)
    rep = registration(files, corpus)
    P(f"  FN-1 실측 read_map: mapped {rep['fn1'][0]} · 고유 corp_code {rep['fn1'][1]} · 공유 {rep['shared_corp']}")
    for t in rep["companies"]:
        P(f"  {t['nm']:10s} {t['eng']:14s} tp={t['tp']} ind={t['industry']} logo={t['logo']} id={t['comp_id']} "
          f"corp={t['corp_code']} stock={t['stock']} DARTcsv={t['dart_csv']} dart_nm()={t['dart_nm_parsed']} "
          f"codes_match_csv={t['dart_code_ok']} krx={t['krx']}({t['krx_stock']}) mail={rep.get('email', {}).get(t['eng'])}")
        P(f"      note={t['note']!r} · 별칭={t['aliases']} · W3={t['wave3_aliases']}")
        if t["alias_cross"]:
            P(f"      ⚠ 별칭이 다른 회사에도 있음 {t['alias_cross']}")
        if t["alias_vs_other_compnm"]:
            P(f"      ⚠ 별칭이 다른 회사 COMP_NM 과 같음 {t['alias_vs_other_compnm']}")
    P(f"  krx 중복 stock_cd {rep['krx_dup_stock']}")
    P(f"  SED-3 {rep.get('SED3')} · SED-4 형식 이탈 {rep.get('SED4_bad')} · SED-5 {rep.get('SED5')} · SED-7 {rep.get('SED7')}")
    P(f"  그룹 도메인 {rep.get('group_domains')}")
    P(f"  @rejected {rep.get('rejected')}")
    P(f"  줄끝 {rep['line_endings']}")
    P(f"  등록 이력 미기재 {rep['registrations_missing']} · 현재 웨이브 {rep['registrations_waves']}")
    inds = collections.Counter(v["industry"] for v in corpus.values())
    P("  INDUSTRY_NM 합류:")
    for f in files:
        P(f"     {f['nm']:10s} {f['industry']:8s} 기존 {inds.get(f['industry'], 0)}사 {[v['nm'] for v in corpus.values() if v['industry'] == f['industry']]}")
    P(f"  건설/무역·유통·상사 계열 기존: {[(v['nm'], v['industry']) for v in corpus.values() if re.search('무역|상사|유통', v['industry'])]}")
    tps = collections.Counter(f["tp"] for f in files)
    P(f"  유형 분포 {dict(tps)}")

    if "--json" in sys.argv:
        json.dump(dict(files=[{k: v for k, v in f.items() if k != "rows"} for f in files],
                       rows={f["nm"]: [fields(r) for r in f["rows"]] for f in files},
                       new_codes=dict(new), editorial=ed, legal=lg,
                       amounts=amounts(files, corpus_codes),
                       registration={k: v for k, v in rep.items()}),
                  open(W3 + "/_audit_rows.json", "w"), ensure_ascii=False, indent=1, default=str)
        P("\n  → _audit_rows.json 기록")


if __name__ == "__main__":
    main()
