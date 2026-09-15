# 통합 후 재스캔 — 리포 12파일의 사용자 노출 3필드·주석·파일 전체
import re, collections
REPO = "/home/ubuntu/loupit/db/seed/benefit/sql"
WAVE3 = ["포스코인터내셔널","포스코퓨처엠","키움증권","삼성증권","SK바이오팜","대한전선","에스티팜","로보티즈","루닛","씨젠","더존비즈온","가온전선"]
ROW = re.compile(r"^  \(@comp_id, '([a-z_0-9]+)', '([^']*)', (NULL|\d+), '([a-z_]+)',\n   'est', (NULL|'[^']*'), (TRUE|FALSE), (NULL|'[^']*'), (\d+)\),?\n", re.M)
# 통합 계약 규칙 4 목록
CONTRACT_TERMS = ["코퍼스","선례","어휘표","규칙","수집기","검증","병합","미수록","회피","흡수","정본","판독","시드",
                  "SI-B2","별도 행","합쳤다","수록","정성 항목","부연","우리 판단","⚠"]
# 감사 _audit.py EDIT_TERMS(45) — 기대 2건(루닛 50 「행으로」 오탐 · 포스코인터내셔널 51 NOTE 「환산」 허용)
EDIT_TERMS = ["코퍼스","선례","어휘","규칙","수집기","수집","검증","병합","미수록","회피","흡수","정본","판독","시드",
              "SI-B2","별도 행","합쳤다","합침","수록","정성 항목","부연","우리 판단","⚠","분할기","UNIQUE","코드","행으로",
              "1행","AMT","앵커","함정","웨이브","evidence","SQL","환산","추정","분리","이미지","교차 확인","원문에 없",
              "한 행에","같은 코드","조각","단정"]
LEGAL_TERMS = ["법정","시차 출근","시차출근","난임 휴가","난임휴가","난임치료휴가","근로자의 날","노동절","출산휴가","출산 휴가",
               "출산전후","출산 전후","산전후","배우자 출산","육아휴직","육아 휴직","육아기","임신기","가족돌봄","가족 돌봄","4대",
               "사회보험","퇴직연금","퇴직금","연차","주5일","주 5일","태아 검진","유산","사산","수유","모성보호","근로기준법"]
LIMITS = {"nm": 100, "note": 200, "qual": 500}

def uq(s): return None if s == "NULL" else s[1:-1]

total = 0; c_hits = []; e_hits = []; l_hits = []; problems = []
seoul = 0; group_fn = {}; refresh = 0
for n in WAVE3:
    t = open(f"{REPO}/{n}.sql", encoding="utf-8").read()
    rows = ROW.findall(t); total += len(rows)
    raw = len(re.findall(r"^\s*\(@comp_id,", t, re.M))
    if raw != len(rows): problems.append(f"{n}: strict regex {len(rows)} != raw {raw}")
    # 파일 전체: HTML 엔티티 · 겹따옴표 · 보이지 않는 문자
    for pat, lab in ((r"&[a-z]+;", "HTML entity"), ('"', "dquote"), ("​", "U+200B"), ("ᆞ", "U+119E"), ("﻿", "BOM")):
        k = len(re.findall(pat, t))
        if k: problems.append(f"{n}: {lab} {k}")
    # 주석 줄 홑따옴표 · 비주석 줄 홑따옴표 짝수
    for i, line in enumerate(t.split("\n"), 1):
        if line.lstrip().startswith("--"):
            if "'" in line: problems.append(f"{n}:{i} comment apostrophe")
        elif line.count("'") % 2:
            problems.append(f"{n}:{i} odd quote count")
    # 코드·SORT UNIQUE · SORT 섹션 카테고리 단일
    codes = collections.Counter(r[0] for r in rows); sorts = collections.Counter(r[7] for r in rows)
    if any(v > 1 for v in codes.values()): problems.append(f"{n}: dup code")
    if any(v > 1 for v in sorts.values()): problems.append(f"{n}: dup sort")
    sec = collections.defaultdict(set); cat = collections.defaultdict(set)
    for r in rows:
        sec[int(r[7]) // 10].add(r[3]); cat[r[3]].add(int(r[7]) // 10)
    for k, v in sec.items():
        if len(v) > 1: problems.append(f"{n}: section {k*10} mixed {v}")
    for k, v in cat.items():
        if len(v) > 1: problems.append(f"{n}: category {k} split {v}")
    fn = 0
    for code, nm, amt, ctgr, note, qy, qual, so in rows:
        note, qual = uq(note), uq(qual)
        if (amt == "NULL") != (qy == "TRUE") or (amt == "NULL") != (note is None) or (amt == "NULL") == (qual is None):
            problems.append(f"{n} {so}: QUAL/AMT invariant")
        for fld, s in (("nm", nm), ("note", note), ("qual", qual)):
            if s is None: continue
            if len(s) > LIMITS[fld]: problems.append(f"{n} {so} {fld} len {len(s)}")
            for term in CONTRACT_TERMS:
                if term in s: c_hits.append((n, so, fld, term))
            for term in EDIT_TERMS:
                for m in re.finditer(re.escape(term), s):
                    e_hits.append((n, so, fld, term, s[max(0, m.start()-12):m.end()+12]))
            for term in LEGAL_TERMS:
                for m in re.finditer(re.escape(term), s):
                    l_hits.append((n, so, fld, term, s[max(0, m.start()-15):m.end()+15]))
            if "서울 오피스 기준이며 오피스 위치에 따라 상이할 수 있음" in s: seoul += 1
            if fld == "qual" and n == "더존비즈온" and s.endswith(" (그룹 통합 채용 기준)"): fn += 1
            if "더존비즈온 채용공고" in s: problems.append(f"{n} {so}: 더존비즈온 채용공고 잔존")
            if "본인/배우자 태아" in s: problems.append(f"{n} {so}: 본인/배우자 태아 잔존")
            if "스톡옵션" in s or "주식매수선택권" in s: problems.append(f"{n} {so}: 스톡옵션 잔존")
        if code in ("refresh_leave", "weekend_farm"): refresh += 1; problems.append(f"{n} {so}: {code} 잔존")
    if n == "더존비즈온": group_fn[n] = (fn, len(rows))

print("TOTAL", total)
print("contract rule-4 term hits:", len(c_hits), c_hits)
print("audit EDIT_TERMS hits:", len(e_hits))
for h in e_hits: print("  ", h)
print("LEGAL_TERMS hits:", len(l_hits))
for h in l_hits: print("  ", h)
print("루닛 서울 오피스 한정 필드:", seoul, "(기대 11)")
print("더존비즈온 그룹 각주:", group_fn)
print("PROBLEMS:", len(problems))
for p in problems: print("  ", p)
