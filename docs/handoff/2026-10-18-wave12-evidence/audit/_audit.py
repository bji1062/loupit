#!/usr/bin/env python3
"""웨이브 12(후보 풀 3차 첫 웨이브 · 18사) 코퍼스 횡단 감사 — 재현 스크립트 (2026-10-18).

출발점: /home/ubuntu/loupit-evidence/2026-10-16-paste1/audit/_audit.py (웨이브 11 감사 — 조치 모델 · simulate · check-seed)
바꾼 것: 경로(W = 2026-10-18-wave12 · 코퍼스 = wave12 worktree 시드 257파일(= main 51fefa7) · 리포 모듈도 그 worktree 에서 import) ·
        대상 18파일 · DART 대응은 로컬 W/dart/company-20.json(induty_code · 법인 상호) + pool3 corpCode.zip(2026-10-17 목록 이름) +
        W/dart/check-2026-10-18.json(재무 · 직원 축) · 조치 문자열은 _extract.json(검증 보고서 절 7 · 절 8 백틱 · 절 4 완성 튜플 ·
        JSON 기계 추출)에서 읽는다 · 항목 페이지 예외의 코드는 JSON 의 h 를 모의 최종 문안 해시와 맞춰 기계로 찾는다 ·
        형제 · 경계 축 · 업종 정규식 · 헤더 한 줄 · 별칭 초안을 웨이브 12 에 맞춤.
        어휘표(wave-lite 93종) · 행 점검기(wave-lite/_row_check.py)는 그대로.

리포 모듈을 **실제로 import** 해서 돌린다(추측 금지 — 리포는 읽기만 · 바이트코드도 쓰지 않는다):
  db.seed.load._split_sql_statements            분할기(5문장 · 셋째 = UPDATE TCOMPANY SET CAREERS_BENEFIT_URL)
  db.seed.company_meta.parse_header_insert       등록 문장 파서 · ws_conditions · derive_work_style(근무형태 칩)
  generator.slug.slug_of                         slug
  db.seed.backfill_dec2._DATE_RE · _URL_RE · derive_amt_source   확인일 · 출처 URL · 금액 출처
  generator.benefit_rules load_pages · classify · text_hash · validate_all   항목 페이지(worktree 설정)
  generator.pages.find _most_common · LABEL_OVERRIDE                           /find 대표 이름
  wave-lite/_row_check.py check()                SI-9 · SI-11 · SI-12 · SI-13d · SI-B2 사전 점검(게이트와 같은 함수)
  /home/ubuntu/loupit-evidence/2026-10-02-recollect-3-7/_len_check.py  필드 길이 · 행 파서(parse_values)

사용:
  python3 -I _audit.py [섹션 ...]          섹션 없으면 all(actions 제외)
    fmt codes consist amt reg legal pages chips final combined actions simulate
  python3 -I _audit.py check-seed <폴더>   그 폴더의 18파일을 최종본 모델과 행 단위 · 전 필드 대조 → 「형식 문제 n · 불일치 n」
  python3 -I _audit.py search <정규식>     코퍼스 257파일 행(이름 · NOTE · 서술)에서 정규식 검색(주석 제외)
"""
from __future__ import annotations

import sys

sys.dont_write_bytecode = True  # 리포 쓰기 0 — import 가 __pycache__ 를 만들지 않게

import collections  # noqa: E402
import copy  # noqa: E402
import glob  # noqa: E402
import importlib.util  # noqa: E402
import json  # noqa: E402
import os  # noqa: E402
import re  # noqa: E402
import subprocess  # noqa: E402

WT = "/home/ubuntu/loupit/.claude/worktrees/wave12"  # 웨이브 12 worktree(51fefa7 = main · 읽기만)
W9 = "/home/ubuntu/loupit-evidence/2026-10-18-wave12"   # (변수 이름은 웨이브 9 판 그대로 — 값은 웨이브 12 폴더)
LITE = "/home/ubuntu/loupit-evidence/wave-lite"
COLLECT = W9 + "/collect"
SIM = W9 + "/audit/sim"
CORPUS = WT + "/db/seed/benefit/sql"                  # 리드 칸: 이것 하나만 센다(257파일)
VOCAB = LITE + "/_VOCAB.md"
LEN_CHECK = "/home/ubuntu/loupit-evidence/2026-10-02-recollect-3-7/_len_check.py"
LEGAL_SCAN = WT + "/docs/handoff/2026-09-19-evidence/_legal_scan.py"
ROW_CHECK = LITE + "/_row_check.py"
EXTRACT = W9 + "/audit/_extract.json"

sys.path.insert(0, WT)
from db.seed import load  # noqa: E402
from db.seed.backfill_dec2 import _DATE_RE, _URL_RE, derive_amt_source  # noqa: E402
from db.seed.company_meta import _WS_CODE_KEY, derive_work_style, parse_header_insert, ws_conditions  # noqa: E402
from generator import benefit_rules as br  # noqa: E402
from generator.slug import slug_of  # noqa: E402


def _mod(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m


lc = _mod("len_check", LEN_CHECK)
rc = _mod("row_check", ROW_CHECK)

# 리드 칸 대상 18파일(리드 프롬프트 「예상 최종 행」 순서)
FILES = ["하나투어", "SM엔터테인먼트", "웅진씽크빅", "매일유업", "KG모빌리티", "남양유업", "대교", "메가스터디교육", "LX하우시스",
         "롯데하이마트", "제주항공", "애경산업", "트리니티항공", "동아에스티", "넥센타이어", "신세계인터내셔날", "DB하이텍", "대상"]
EXPECT_FINAL = {"하나투어": 18, "SM엔터테인먼트": 23, "웅진씽크빅": 30, "매일유업": 28, "KG모빌리티": 24, "남양유업": 21, "대교": 19,
                "메가스터디교육": 20, "LX하우시스": 31, "롯데하이마트": 26, "제주항공": 26, "애경산업": 30, "트리니티항공": 21,
                "동아에스티": 32, "넥센타이어": 33, "신세계인터내셔날": 17, "DB하이텍": 28, "대상": 30}   # 리드 칸(검증 + 리드 판정 기준)
MAXLEN = {"nm": 100, "note": 200, "qd": 500}  # db/schema.sql — BENEFIT_NM · NOTE_CTNT · QUAL_DESC_CTNT
META_MAX = {"eng": 30, "nm": 100, "ind": 50, "logo": 10, "url": 500}  # db/schema.sql TCOMPANY
CTGR = {"compensation", "health", "family", "leisure", "perks", "growth", "time_off", "flexibility", "work_env"}
HDR_INSERT = rc.HDR_INSERT
UPD = rc.UPD
TUPLE = re.compile(  # 원문 텍스트 안 튜플 위치(모의본 쓰기용) — 행 파서는 lc.parse_values 가 정본
    r"\(\s*@comp_id\s*,\s*'((?:[^']|'')*)'\s*,\s*'((?:[^']|'')*)'\s*,\s*(NULL|-?[\d.]+)\s*,\s*'([a-z_]+)'\s*,"
    r"\s*'([a-z_]+)'\s*,\s*(NULL|'(?:[^']|'')*')\s*,\s*(TRUE|FALSE)\s*,\s*(NULL|'(?:[^']|'')*')\s*,\s*(\d+)\s*\)",
    re.S)
ROSTER_NM = {  # eng(slug) → 리드 명단 이름(= 파일명 = 표시명)
    "hanatour": "하나투어", "sm_entertainment": "SM엔터테인먼트", "woongjin_thinkbig": "웅진씽크빅", "maeil_dairies": "매일유업",
    "kg_mobility": "KG모빌리티", "namyang_dairy": "남양유업", "daekyo": "대교", "megastudy_edu": "메가스터디교육",
    "lx_hausys": "LX하우시스", "lotte_himart": "롯데하이마트", "jeju_air": "제주항공", "aekyung_industrial": "애경산업",
    "trinity_air": "트리니티항공", "dong_a_st": "동아에스티", "nexen_tire": "넥센타이어", "shinsegae_intl": "신세계인터내셔날",
    "db_hitek": "DB하이텍", "daesang": "대상"}
# DART 대응 — 로컬 사본만(새 요청 0): W/dart/company-20.json(리드가 받은 company.json 요약 — 법인 상호 · induty_code · 종목 ·
# 설립일 · 홈) · 목록 이름 = 풀 3차 corpCode.zip(2026-10-17 사본 · 압축을 풀지 않고 읽음) · 재무 · 직원 축 = W/dart/check-2026-10-18.json
DART_COMPANY_20 = W9 + "/dart/company-20.json"
DART_CHECK = W9 + "/dart/check-2026-10-18.json"
CORPCODE_ZIP = "/home/ubuntu/loupit-evidence/2026-10-17-pool3/_raw/dart/corpCode/corpCode.zip"
COMPANY20_NAME = {"SM엔터테인먼트": "에스엠"}   # company-20.json 의 name 이 표시명과 다른 곳(종목명)
COLS = ["COMP_ID", "BENEFIT_CD", "BENEFIT_NM", "BENEFIT_AMT", "BENEFIT_CTGR_CD", "BADGE_CD", "NOTE_CTNT", "QUAL_YN",
        "QUAL_DESC_CTNT", "SORT_ORDER_NO"]

# ── 파싱 ─────────────────────────────────────────────────────────────────────
def _row_from(r: dict) -> dict:
    amt = r.get("BENEFIT_AMT")
    return dict(cd=r["BENEFIT_CD"], nm=r["BENEFIT_NM"], amt=None if amt is None else int(float(amt)),
                ctgr=r["BENEFIT_CTGR_CD"], badge=r["BADGE_CD"], note=r.get("NOTE_CTNT"),
                qual=(r.get("QUAL_YN") == "TRUE"), qd=r.get("QUAL_DESC_CTNT"), sort=int(r["SORT_ORDER_NO"]))


def parse_text(t: str) -> dict:
    h = HDR_INSERT.search(t)
    meta = None
    if h:
        eng, nm, tp, ind, logo, url = h.groups()
        meta = dict(eng=eng, nm=nm, tp=tp, ind=ind, logo=logo, url=url)
    m = lc.INS.search(t)
    rows = []
    if m:
        cols = [c.strip().strip("`") for c in m.group(1).replace("\n", " ").split(",")]
        for tup in lc.parse_values(t, m.end()):
            rows.append(_row_from(dict(zip(cols, tup))))
    return dict(text=t, meta=meta, rows=rows)


def parse_file(path: str) -> dict:
    d = parse_text(open(path, encoding="utf-8").read())
    d["path"] = path
    return d


def load_collect() -> dict:
    out = {}
    for fn in FILES:
        d = parse_file(f"{COLLECT}/{fn}.sql")
        d["file"] = fn
        out[d["meta"]["eng"]] = d
    return out


_CORPUS_META = re.compile(r"VALUES\s*\(\s*'([^']+)',\s*'([^']+)',\s*\(SELECT[^)]*'([a-z]+)'\)\s*,\s*"
                          r"(NULL|'[^']*')\s*,\s*(NULL|'[^']*')\s*,\s*(NULL|'[^']*')")


def load_corpus() -> dict:
    """코퍼스(옛 파일은 등록 문장 모양이 조금씩 달라 웨이브 6 감사의 느슨한 정규식으로 읽는다). 행은 _len_check 파서로
    파일 안 TCOMPANY_BENEFIT INSERT 를 전부 읽는다."""
    out = {}
    u = lambda x: None if x == "NULL" else x[1:-1]  # noqa: E731
    for f in sorted(glob.glob(CORPUS + "/*.sql")):
        t = open(f, encoding="utf-8").read()
        m = _CORPUS_META.search(t)
        meta = dict(eng=m.group(1), nm=m.group(2), tp=m.group(3), ind=u(m.group(4)), logo=u(m.group(5)), url=u(m.group(6)))
        rows = []
        for mi in lc.INS.finditer(t):
            cols = [c.strip().strip("`") for c in mi.group(1).replace("\n", " ").split(",")]
            for tup in lc.parse_values(t, mi.end()):
                rows.append(_row_from(dict(zip(cols, tup))))
        out[meta["eng"]] = dict(file=os.path.basename(f)[:-4], meta=meta, rows=rows, text=t, path=f)
    return out


def vocab_table() -> dict:
    out = {}
    for line in open(VOCAB, encoding="utf-8"):
        m = re.match(r"^\| `([a-z0-9_]+)` \| (\d+) \| ([a-z_]+)", line)
        if m:
            out[m.group(1)] = (int(m.group(2)), m.group(3))
    return out


def rtext(r: dict) -> str:
    return " ".join(x for x in (r["nm"], r["note"] or "", r["qd"] or ""))


def search(pattern: str, corpus: dict) -> list:
    pat = re.compile(pattern)
    hits = []
    for e, c in corpus.items():
        for r in c["rows"]:
            t = rtext(r)
            m = pat.search(t)
            if m:
                s = max(0, m.start() - 40)
                hits.append((c["file"], r["sort"], r["cd"], r["nm"], t[s:m.end() + 40]))
    return hits


# ── 검증 보고서에서 기계로 뽑은 문자열 ─────────────────────────────────────────
_EX = json.load(open(EXTRACT, encoding="utf-8"))


def X(fn: str, i: int) -> str:
    """검증 보고서 <fn> 의 i 번째 백틱 글자(_extract.py 출력 — 손 옮김 0)."""
    it = _EX[fn][i]
    assert it["i"] == i
    return it["text"]


def T(fn: str, i: int) -> dict:
    """검증 보고서의 완성 VALUES 튜플 → 행 dict(끝 쉼표는 집행 규약이 정하므로 걷는다)."""
    s = X(fn, i).rstrip().rstrip(",")
    assert s.startswith("(@comp_id"), (fn, i, s[:30])
    vals = lc.parse_values("VALUES " + s, len("VALUES "))
    assert len(vals) == 1 and len(vals[0]) == 10, (fn, i)
    return _row_from(dict(zip(COLS, vals[0])))


def J(fn: str, i: int) -> dict:
    return json.loads(X(fn, i))


def _row(cd, nm, amt, ctgr, note, qual, qd, sort):
    return dict(cd=cd, nm=nm, amt=amt, ctgr=ctgr, badge="est", note=note, qual=qual, qd=qd, sort=sort)


def SEC(s: str) -> str:
    """섹션 머리 주석 — 시드의 다른 섹션 머리와 같은 들여쓰기(2칸)."""
    return "  " + s.strip()




def XQ(fn: str, i: int) -> str:
    """신영증권 보고서처럼 백틱 안에 SQL 홑따옴표까지 넣은 값 — 양 끝 따옴표만 걷는다."""
    s = X(fn, i)
    assert s.startswith("'") and s.endswith("'") and "'" not in s[1:-1], (fn, i, s[:40])
    return s[1:-1]


def TA(s: str) -> dict:
    """감사가 쓴 완성 VALUES 튜플(보고서 §5 에 같은 글자로 찍힌다) → 행 dict."""
    vals = lc.parse_values("VALUES " + s, len("VALUES "))
    assert len(vals) == 1 and len(vals[0]) == 10, s[:60]
    return _row_from(dict(zip(COLS, vals[0])))



# ── §5 조치 모델 (보고서 §5 와 1:1 — 통합 결과는 check-seed 로 이 모델과 대조한다) ─────────────────
# 종류: ("set", SORT, {필드: 값}) · ("replace", SORT, 필드, 옛 구절, 새 구절) · ("delete", SORT)
#       ("add", 행 dict, 섹션 머리 주석|None) · ("move", 옛 SORT, 새 행 dict, 섹션 머리 주석|None)
#       set 의 필드에 cd 가 있으면 같은 SORT 제자리 재코딩(카테고리는 따로 적을 때만 바뀐다)
DATE = "2026-10-23"   # 반영일(리드 칸) — 헤더 한 줄 날짜는 감사일(2026-10-18 · 아래 _H)
_CROW_CACHE: dict = {}


def _C(fn: str, sort: int) -> dict:
    """수집본 <fn> 의 SORT 행(감사 조치 문자열을 수집본 글자에서 기계로 만들 때만 쓴다 — 손 옮김 0)."""
    if fn not in _CROW_CACHE:
        _CROW_CACHE[fn] = {r["sort"]: r for r in parse_file(f"{COLLECT}/{fn}.sql")["rows"]}
    return _CROW_CACHE[fn][sort]


def _swap(s: str, *pairs) -> str:
    for old, new in pairs:
        assert s.count(old) == 1, (old, s)
        s = s.replace(old, new)
    return s


ACTIONS: dict[str, list] = {
    "hanatour": [],
    "sm_entertainment": [
        ("set", 13, dict(qd=X("SM엔터테인먼트", 1))),
    ],
    "woongjin_thinkbig": [
        ("add", T("웅진씽크빅", 1), None),
        ("set", 81, dict(qd=X("웅진씽크빅", 3))),
    ],
    "maeil_dairies": [
        ("add", T("매일유업", 4), None),
        ("add", T("매일유업", 6), None),
        ("add", T("매일유업", 8), None),
        ("set", 21, dict(nm=X("매일유업", 10), qd=X("매일유업", 11))),
    ],
    "kg_mobility": [
        ("delete", 25),
        ("set", 23, dict(nm=X("KG모빌리티", 2), qd=X("KG모빌리티", 3))),
    ],
    "namyang_dairy": [
        ("set", 20, dict(qd=X("남양유업", 1))),
        ("set", 51, dict(qd=X("남양유업", 3))),
    ],
    "daekyo": [
        ("set", 10, dict(qd=X("대교", 1))),
        ("set", 11, dict(nm=X("대교", 3), qd=X("대교", 4))),
    ],
    "megastudy_edu": [
        ("set", 22, dict(nm=X("메가스터디교육", 2), qd=X("메가스터디교육", 3))),
        ("add", T("메가스터디교육", 6), SEC(X("메가스터디교육", 5))),
    ],
    "lx_hausys": [
        ("set", 10, dict(qd=X("LX하우시스", 2))),
    ],
    "lotte_himart": [
        ("set", 40, dict(nm=X("롯데하이마트", 2), qd=X("롯데하이마트", 4))),
        # 리드 판정 (157) — 검증 보고서 8절 대안 글자(「60 mba 서술 끝(꼬리 앞)에 덧붙임」) 그대로: 첫 「 — 」 바로 앞에 끼운 서술 전체
        #   (통합이 헷갈리지 않게 구절 교체가 아니라 새 서술 전체를 준다 — 수집본 60 서술 + 대안 글자를 기계로 이음)
        ("set", 60, dict(qd=_swap(_C("롯데하이마트", 60)["qd"], (" — ", X("롯데하이마트", 11) + " — ")))),
    ],
    "jeju_air": [
        ("set", 11, dict(nm=XQ("제주항공", 1), qd=XQ("제주항공", 2))),
        ("set", 43, dict(nm=XQ("제주항공", 4), qd=XQ("제주항공", 5))),
        ("set", 60, dict(qd=XQ("제주항공", 7))),
    ],
    "aekyung_industrial": [
        ("set", 80, dict(qd=XQ("애경산업", 3))),
        ("add", T("애경산업", 7), None),
        ("add", T("애경산업", 5), None),
    ],
    "trinity_air": [],
    "dong_a_st": [
        ("set", 31, dict(qd=X("동아에스티", 4))),
        ("set", 50, dict(nm=X("동아에스티", 1), qd=X("동아에스티", 2))),
    ],
    "nexen_tire": [
        ("add", T("넥센타이어", 1), None),
        ("set", 80, dict(nm=X("넥센타이어", 2), qd=X("넥센타이어", 3))),
        # 검증 조치 3 — 서술 안 구절 교체(옛 → 새 구절은 검증 §7 백틱) 결과의 서술 전체
        ("set", 83, dict(qd=_swap(_C("넥센타이어", 83)["qd"], (X("넥센타이어", 4), X("넥센타이어", 5))))),
    ],
    "shinsegae_intl": [
        ("set", 32, dict(qd=X("신세계인터내셔날", 0))),
        ("set", 40, dict(nm=X("신세계인터내셔날", 4), qd=X("신세계인터내셔날", 5))),
        ("set", 50, dict(qd=X("신세계인터내셔날", 3))),
    ],
    "db_hitek": [
        ("set", 54, dict(qd=X("DB하이텍", 1))),
    ],
    "daesang": [
        ("set", 31, dict(nm=X("대상", 4))),
        ("set", 42, dict(qd=X("대상", 1))),
        ("set", 72, dict(nm=X("대상", 9), qd=X("대상", 10))),
        ("set", 80, dict(qd=X("대상", 6))),
    ],
}
# 검증 §7 의 완성 튜플과 §4 MISSED 표의 튜플이 글자까지 같은지 — 둘 중 하나를 골라 쓰지 않게
assert X("웅진씽크빅", 0) == X("웅진씽크빅", 1)
assert X("매일유업", 0) == X("매일유업", 4) and X("매일유업", 1) == X("매일유업", 6) and X("매일유업", 2) == X("매일유업", 8)
assert X("메가스터디교육", 0) == X("메가스터디교육", 6)
assert X("애경산업", 0) == X("애경산업", 5) and X("애경산업", 1) == X("애경산업", 7)
assert X("넥센타이어", 0) == X("넥센타이어", 1)
# 신세계인터내셔날 50 — 검증 §7 조치 2 의 「옛 꼬리 → 새 꼬리」와 「새 서술 전체」가 같은 결과인지(둘 중 하나를 골라 쓰지 않게)
assert _swap(_C("신세계인터내셔날", 50)["qd"], (X("신세계인터내셔날", 1), X("신세계인터내셔날", 2))) == X("신세계인터내셔날", 3)
# 넥센타이어 83 — 옛 구절이 수집본 서술에 정확히 한 번
assert _C("넥센타이어", 83)["qd"].count(X("넥센타이어", 4)) == 1

# 감사가 새로 더한 시드 조치(검증 보고서에 없는 것) — §2-6 · §13-2: 제주항공 22 「임직원몰」(포인트 · 배정 낱말 없음)을
#   웨이브 11 감사 §1-2 ① 잣대(코퍼스 「임직원몰」 단독 라벨 discount 4 : welfare_point 1)대로 20 discount 에 병합하고 22 를 지운다.
#   새 글자는 수집본 20 · 22 글자에서 기계로 만든다(원문 낱말 「임직원몰」 · 출처 괄호는 수집본 22 의 것과 같은 62쪽 임직원 복리후생 항목).
_JJ20 = _C("제주항공", 20)
_JJ22 = _C("제주항공", 22)
assert _JJ22["cd"] == "welfare_point" and _JJ22["nm"] == "임직원몰"
assert "(2026 지속가능경영보고서 62쪽 임직원 복리후생 항목)" in _JJ22["qd"]
AUDIT_ACTIONS: dict[str, list] = {
    "jeju_air": [
        ("set", 20, dict(
            nm=_JJ20["nm"] + "·" + _JJ22["nm"],
            qd=_swap(_JJ20["qd"],
                     (" (2026 지속가능경영보고서 62쪽 임직원 복리후생 항목)", ", " + _JJ22["nm"] + " (2026 지속가능경영보고서 62쪽 임직원 복리후생 항목)"),
                     (" — 할인율·연간 이용 매수·가족 적용 범위 미기재", " — 할인율·연간 이용 매수·가족 적용 범위, 임직원몰 이용 혜택 미기재")))),
        ("delete", 22),
    ],
}

# 정본 URL 교체(머리말 · INSERT · UPDATE 세 곳) — 이번 웨이브 없음(정본 18 모두 수집본 주소 유지 — §4-3)
URL_CHANGE: dict = {}
# 등록 값 교체(INSERT 한 곳의 글자) — 이번 웨이브 없음(업종 18사 수집본 값 유지 — §4-2)
META_CHANGE: dict = {}
HEADER_EDIT: dict = {}  # 참고 블록의 옛 문장은 고치지 않는다(계약 B · A 5) — 헤더 한 줄이 뒤집힘을 적는다
SECTION_EDIT: dict = {}  # 섹션 머리 주석 교체 — 이번 웨이브 없음(메가스터디교육 work_env 는 새 섹션 머리 = add 의 머리 주석)

# 항목 페이지 동반 조치(리드 집행 — generator/data/benefit_pages/<code>.json overrides)
#   검증 보고서의 JSON 을 기계로 뽑았다. 코드는 JSON 의 h 를 모의 최종 문안 해시와 맞춰 찾는다(resolve_overrides).
OVERRIDE_JSON: list[dict] = [
    J("하나투어", 1),
    J("SM엔터테인먼트", 2), J("SM엔터테인먼트", 3),
    J("KG모빌리티", 4),
    J("메가스터디교육", 11),
    J("LX하우시스", 5), J("LX하우시스", 6),
    J("애경산업", 9), J("애경산업", 10), J("애경산업", 11),
    J("동아에스티", 8), J("동아에스티", 9),
    J("넥센타이어", 6), J("넥센타이어", 7), J("넥센타이어", 8), J("넥센타이어", 9),
    J("DB하이텍", 4),
    J("대상", 12),
]
OVERRIDES: list[tuple[str, dict]] = []         # resolve_overrides() 가 (코드, JSON) 으로 채운다
AUDIT_OVERRIDES: list[tuple[str, dict]] = []   # 감사가 더하는 예외(§10)

# 감사가 더하는 예외(§10-1) — 아래 sec_pages 결과로 정한다(없으면 빈 목록).
AUDIT_OVERRIDE_JSON: list[dict] = []


def resolve_overrides(final: dict) -> None:
    """JSON 의 h 를 그 회사 최종본 행의 text_hash 와 맞춰 코드를 정한다 — 한 행에만 맞아야 한다."""
    OVERRIDES.clear()
    AUDIT_OVERRIDES.clear()
    for src, dst in ((OVERRIDE_JSON, OVERRIDES), (AUDIT_OVERRIDE_JSON, AUDIT_OVERRIDES)):
        for ov in src:
            hits = [r for r in final[ov["comp"]] if br.text_hash(r["qd"], r["note"]) == ov["h"]]
            assert len(hits) == 1, (ov["comp"], ov["h"], len(hits))
            dst.append((hits[0]["cd"], ov))


# §8-2 db/seed/company_meta.py WAVE12_ALIASES 초안(보고서와 같은 글자 — combined 섹션이 충돌을 잰다)
WAVE10_ALIASES: dict[str, list[str]] = {   # (변수 이름은 웨이브 10 판 그대로 — 값은 WAVE12_ALIASES 초안 · 근거 = 보고서 §8-2 표)
    "hanatour": ["Hanatour"],
    "sm_entertainment": ["에스엠", "에스엠엔터테인먼트", "SM Entertainment"],
    "woongjin_thinkbig": ["Woongjin Thinkbig"],
    "maeil_dairies": ["Maeil Dairies"],
    "kg_mobility": ["쌍용자동차", "케이지모빌리티", "KG Mobility", "KGM"],
    "namyang_dairy": ["Namyang Dairy Products"],
    "daekyo": ["Daekyo"],
    "megastudy_edu": ["MegaStudyEdu"],
    "lx_hausys": ["LG하우시스", "엘엑스하우시스", "LX Hausys"],
    "lotte_himart": ["LOTTE Himart"],
    "jeju_air": ["Jeju Air"],
    "aekyung_industrial": ["Aekyung Industrial"],
    "trinity_air": ["티웨이항공", "Trinity Airways"],
    "dong_a_st": ["동아ST", "Dong-A ST"],
    "nexen_tire": ["Nexen Tire"],
    "shinsegae_intl": ["Shinsegae International"],
    "db_hitek": ["동부하이텍", "DB HiTek"],
    "daesang": ["대상주식회사", "Daesang Corporation"],
}
HEADER_LINE: dict[str, str] = {}   # 아래 _header_lines() 가 채운다(최종 행 수를 모델에서 센다)
WHY: dict[str, list[str]] = {}     # §5 표의 「근거」 열
KEEP: dict[str, list[tuple]] = {}  # §5 「바꾸지 않는 것」


def all_actions(eng: str) -> list:
    return ACTIONS.get(eng, []) + AUDIT_ACTIONS.get(eng, [])


# ── 조치 적용 ─────────────────────────────────────────────────────────────────
def apply_actions(collect: dict) -> dict:
    final = {}
    for eng, c in collect.items():
        rows = copy.deepcopy(c["rows"])
        by_sort = {r["sort"]: r for r in rows}
        for act in all_actions(eng):
            kind = act[0]
            if kind == "set":
                assert act[1] in by_sort, (eng, act[:2])
                if "cd" in act[2]:  # 같은 SORT 제자리 재코딩 — 새 코드가 회사 안에 없어야 한다
                    assert act[2]["cd"] not in {r["cd"] for r in rows}, (eng, act)
                by_sort[act[1]].update(act[2])
            elif kind == "replace":
                _, sort, fld, old, new = act
                v = by_sort[sort][fld]
                assert v.count(old) == 1, (eng, sort, fld, old)
                by_sort[sort][fld] = v.replace(old, new)
            elif kind == "delete":
                assert act[1] in by_sort, (eng, act)
                rows = [r for r in rows if r["sort"] != act[1]]
                by_sort.pop(act[1])
            elif kind == "move":
                assert act[1] in by_sort, (eng, act)
                rows = [r for r in rows if r["sort"] != act[1]]
                by_sort.pop(act[1])
                nr = dict(act[2])
                assert nr["sort"] not in by_sort and nr["cd"] not in {r["cd"] for r in rows}, (eng, nr)
                rows.append(nr)
                by_sort[nr["sort"]] = nr
            elif kind == "add":
                nr = dict(act[1])
                assert nr["sort"] not in by_sort, (eng, nr["sort"])
                assert nr["cd"] not in {r["cd"] for r in rows}, (eng, nr["cd"])
                rows.append(nr)
                by_sort[nr["sort"]] = nr
            else:
                raise ValueError(act)
        rows.sort(key=lambda r: r["sort"])
        final[eng] = rows
    return final


def expected_meta(eng: str, collect: dict) -> dict:
    m = dict(collect[eng]["meta"])
    if eng in URL_CHANGE:
        m["url"] = URL_CHANGE[eng][1]
    if eng in META_CHANGE:
        m.update(META_CHANGE[eng][2])
    return m


def sv(v):  # SQL 문자열 값
    return "NULL" if v is None else "'" + v + "'"


def render_tuple(r: dict) -> str:
    amt = "NULL" if r["amt"] is None else str(r["amt"])
    return (f"  (@comp_id, '{r['cd']}', '{r['nm']}', {amt}, '{r['ctgr']}',\n"
            f"   'est', {sv(r['note'])}, {'TRUE' if r['qual'] else 'FALSE'}, {sv(r['qd'])}, {r['sort']})")


def _section_comments(eng: str) -> dict:
    out = {}
    for act in all_actions(eng):
        if act[0] == "add" and act[2]:
            out[act[1]["sort"]] = act[2]
        if act[0] == "move" and act[3]:
            out[act[2]["sort"]] = act[3]
    return out


# ── 모의 최종본 ───────────────────────────────────────────────────────────────
def simulate(collect: dict, final: dict, out_dir: str = SIM) -> str:
    """수집본 텍스트에 §5 조치를 적용해 out_dir/<파일명>.sql 을 쓴다. 바뀐 튜플만 다시 쓰고
    나머지 글자(주석 · 문장 · 줄바꿈)는 수집본 그대로 둔다. 새 행은 SORT 바로 앞 행 뒤에 넣는다."""
    os.makedirs(out_dir, exist_ok=True)
    for eng, c in collect.items():
        t = c["text"]
        orig = {r["sort"]: r for r in c["rows"]}
        want = {r["sort"]: r for r in final[eng]}
        spans = [(m.start(), m.end(), int(m.group(9))) for m in TUPLE.finditer(t)]
        assert len(spans) == len(c["rows"]), (eng, len(spans), len(c["rows"]))
        # 1) 바꾼 행 · 지운 행 — 뒤에서부터 고쳐 앞 위치가 흔들리지 않게
        for idx in range(len(spans) - 1, -1, -1):
            s, e, sort = spans[idx]
            if sort in want and sort in orig:  # 같은 SORT — 바뀐 필드(재코딩 포함)만 있으면 제자리 다시 쓰기
                if want[sort] != orig[sort]:
                    t = t[:s] + render_tuple(want[sort]).lstrip() + t[e:]
            else:  # 삭제
                assert sort not in want, (eng, sort)
                if t[e:e + 1] == ",":  # 가운데 튜플 — 튜플 줄 전체와 뒤 쉼표 · 줄바꿈을 지운다
                    line_start = t.rfind("\n", 0, s) + 1
                    end = e + 1
                    nl = t.find("\n", end)
                    end = nl + 1 if nl != -1 and t[end:nl].strip() == "" else end
                    t = t[:line_start] + t[end:]
                else:  # 마지막 튜플 — 앞 튜플 끝 쉼표부터 이 튜플 끝까지 지운다(빈 줄 남기지 않음)
                    prev_e = spans[idx - 1][1]
                    between = t[prev_e:s]
                    assert between.lstrip().startswith(",") and "--" not in between, (eng, sort, between)
                    t = t[:prev_e] + t[e:]
        # 2) 새 행 — SORT 순서 자리(바로 앞 SORT 의 튜플 뒤) · 새 섹션이면 머리 주석을 앞에
        secs = _section_comments(eng)
        for r in sorted([x for x in final[eng] if x["sort"] not in orig], key=lambda x: x["sort"]):
            spans2 = [(m.start(), m.end(), int(m.group(9))) for m in TUPLE.finditer(t)]
            prev = max((sp for sp in spans2 if sp[2] < r["sort"]), key=lambda sp: sp[2])
            e = prev[1]
            head = (secs[r["sort"]] + "\n") if r["sort"] in secs else ""
            if t[e:e + 1] == ",":
                t = t[:e + 1] + "\n" + head + render_tuple(r) + "," + t[e + 1:]
            else:  # 마지막 튜플 뒤
                t = t[:e] + ",\n" + head + render_tuple(r) + t[e:]
        # 3) 정본 URL(세 곳) · 머리말 줄
        for old, new in [URL_CHANGE[eng]] if eng in URL_CHANGE else []:
            assert t.count(old) == 3, (eng, t.count(old))
            t = t.replace(old, new)
        if eng in META_CHANGE:  # 등록 INSERT 한 곳의 글자(업종 등)
            o, n, _ = META_CHANGE[eng]
            assert t.count(o) == 1, (eng, o)
            t = t.replace(o, n)
        for old_line, new_line in HEADER_EDIT.get(eng, []) + SECTION_EDIT.get(eng, []):
            assert t.count(old_line) == 1, (eng, old_line)
            t = t.replace(old_line, new_line)
        # 4) 헤더 한 줄 — 「참고」 블록 끝(닫는 ━━━ 줄 바로 위)
        lines = t.split("\n")
        rule_idx = [i for i, ln in enumerate(lines) if ln.startswith("-- ━━━")]
        assert len(rule_idx) >= 2, eng
        lines.insert(rule_idx[1], HEADER_LINE[eng])
        t = "\n".join(lines)
        with open(f"{out_dir}/{c['file']}.sql", "w", encoding="utf-8") as fh:
            fh.write(t)
    return out_dir


# ── 형식 점검(수집본 · 모의본 · 통합본 공통) ───────────────────────────────────
def fmt_problems(d: dict, want_meta: dict | None = None, header_line: str | None = None) -> list[str]:
    p = []
    t = d["text"]
    try:
        st = load._split_sql_statements(t)
    except Exception as e:  # noqa: BLE001
        return [f"분할기 실패 {e}"]
    if len(st) != 5:
        p.append(f"분할기 문장 수 {len(st)}")
    elif not re.sub(r"^(\s*--[^\n]*\n)*\s*", "", st[2]).startswith("UPDATE TCOMPANY SET CAREERS_BENEFIT_URL"):
        p.append("셋째 문장이 UPDATE CAREERS_BENEFIT_URL 아님")
    dm, um = _DATE_RE.search(t), _URL_RE.search(t)
    if not dm:
        p.append("머리말 출처 날짜 줄 없음")
    if not um:
        p.append("머리말 URL 줄 없음")
    try:
        eng, nm, tp = parse_header_insert(t)
    except Exception as e:  # noqa: BLE001
        p.append(f"parse_header_insert 실패 {e}")
        eng = nm = tp = None
    meta = d["meta"]
    if not meta:
        p.append("등록 INSERT 모양 다름")
    else:
        u = UPD.search(t)
        urls = {meta["url"], u.group(1) if u else None, um.group(1) if um else None}
        if len(urls) != 1:
            p.append(f"정본 URL 세 곳 불일치 {urls}")
        if (eng, nm, tp) != (meta["eng"], meta["nm"], meta["tp"]):
            p.append("parse_header_insert ≠ 등록 문장")
        for k, lim in META_MAX.items():
            if meta[k] and len(meta[k]) > lim:
                p.append(f"등록 {k} 길이 {len(meta[k])} > {lim}")
        if want_meta and meta != want_meta:
            p.append(f"등록 값 ≠ 기대값 {meta} ≠ {want_meta}")
    for i, ln in enumerate(t.splitlines(), 1):
        if ln.lstrip().startswith("--") and ("'" in ln or '"' in ln):
            p.append(f"{i}행 주석 따옴표")
    if "''" in t:
        p.append("문자열 안 홑따옴표 이스케이프")
    if '"' in re.sub(r"^\s*--.*$", "", t, flags=re.M):
        p.append("겹따옴표")
    codes = [r["cd"] for r in d["rows"]]
    sorts = [r["sort"] for r in d["rows"]]
    if len(set(codes)) != len(codes):
        p.append(f"코드 중복 {[c for c in set(codes) if codes.count(c) > 1]}")
    if len(set(sorts)) != len(sorts):
        p.append("SORT 중복")
    for r in d["rows"]:
        for k, lim in MAXLEN.items():
            if r[k] and len(r[k]) > lim:
                p.append(f"SORT {r['sort']} {k} 길이 {len(r[k])} > {lim}")
        if r["ctgr"] not in CTGR:
            p.append(f"SORT {r['sort']} 카테고리 {r['ctgr']}")
        if r["badge"] != "est":
            p.append(f"SORT {r['sort']} BADGE {r['badge']}")
        if (r["amt"] is None) != r["qual"] or (r["amt"] is None and r["note"] is not None) or (r["amt"] is not None and r["qd"] is not None):
            p.append(f"SORT {r['sort']} 금액 행 / 정성 행 모양")
    if header_line is not None and header_line not in t.split("\n"):
        p.append("헤더 한 줄(검증 · 감사 판정 반영) 없음")
    return p


def check_seed(d: str, collect: dict, final: dict) -> int:
    print(f"[check-seed] {d} ↔ 최종본 모델(§5)")
    fmt_n = bad = 0
    for fn in FILES:
        path = f"{d}/{fn}.sql"
        if not os.path.exists(path):
            print(f"  ⚠ {fn}.sql 없음")
            bad += 1
            continue
        got = parse_file(path)
        eng = got["meta"]["eng"] if got["meta"] else None
        if eng not in collect:
            print(f"  ⚠ {fn}: 등록 eng {eng} 가 대상 18사가 아니다")
            bad += 1
            continue
        probs = fmt_problems(got, expected_meta(eng, collect), HEADER_LINE[eng])
        lines_got = got["text"].split("\n")
        for old_line, new_line in SECTION_EDIT.get(eng, []):  # 섹션 머리 주석 교체가 집행됐는지
            if new_line not in lines_got or old_line in lines_got:
                probs.append(f"섹션 머리 주석 교체 미집행: {new_line.strip()[:60]}")
        for x in probs:
            print(f"  ⚠ 형식 {fn}: {x}")
        fmt_n += len(probs)
        want = {r["cd"]: r for r in final[eng]}
        have = {r["cd"]: r for r in got["rows"]}
        for cd in sorted(set(want) | set(have)):
            if cd not in have:
                print(f"  ⚠ {fn} {cd} 누락")
                bad += 1
                continue
            if cd not in want:
                print(f"  ⚠ {fn} {cd} 모델에 없는 행")
                bad += 1
                continue
            for f in ("nm", "amt", "ctgr", "badge", "note", "qual", "qd", "sort"):
                if want[cd][f] != have[cd][f]:
                    print(f"  ⚠ {fn} {cd} {f}: 모델 {want[cd][f]!r} ≠ 통합본 {have[cd][f]!r}")
                    bad += 1
        print(f"  {fn}: 행 {len(have)} (모델 {len(want)})")
    print(f"[check-seed] 형식 문제 {fmt_n} · 불일치 {bad}")
    return 1 if (fmt_n or bad) else 0


# ── 섹션 ─────────────────────────────────────────────────────────────────────
SECTIONS: dict = {}


def section(name):
    def deco(fn):
        SECTIONS[name] = fn
        return fn
    return deco


def _header_lines(collect: dict, final: dict) -> None:
    for eng in collect:
        HEADER_LINE[eng] = HEADER_TEXT[eng].replace("{N}", str(len(final[eng])))


def main(argv):
    collect = load_collect()
    final = apply_actions(collect)
    resolve_overrides(final)
    _header_lines(collect, final)
    if argv and argv[0] == "check-seed":
        return check_seed(argv[1], collect, final)
    corpus = load_corpus()
    if argv and argv[0] == "search":
        for h in search(argv[1], corpus):
            print("  ", h)
        return 0
    secs = argv or ["all"]
    if "simulate" in secs or "all" in secs:
        simulate(collect, final)
        rcd = check_seed(SIM, collect, final)
        if secs == ["simulate"]:
            return rcd
    for name, fn in SECTIONS.items():
        if name in secs or ("all" in secs and name != "actions"):
            fn(collect, final, corpus)
    return 0




_H = "-- 검증 · 감사 판정 반영(2026-10-18): "
HEADER_TEXT: dict[str, str] = {  # 회사별 헤더 한 줄 — 따옴표 없음 · 최종 행 수는 모델에서 센다({N})
    "hanatour": _H + "행 조치 없음 · 수집본 18행 그대로 · 임직원 전용 여행상품 discount 유지 · 입사 1년 미만 여행과 2시간 단위 휴가 leave_general 한 행 · 새 업종 여행 · 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 {N}행",
    "sm_entertainment": _H + "SM 포토부스 leisure_room 서술을 원문 낱말로 교체(공간 낱말 걷음) · 스탁그랜트 stock_grant 유지(주식기준보상 미운영 주석은 임원 보수 표 주석) · 무한 성장(조기 승급) 제외 유지 · 항목 페이지 예외 2(통합 밖 리드 집행) — 최종 {N}행",
    "woongjin_thinkbig": _H + "2026 반기보고서 그 밖의 우발채무 문단의 종업원 단체상해보험 insurance 추가(주어가 연결실체라 통합 보고 각주) · 자격증 과정 self_development 서술에서 다른 직무 과정 이름 걷기 · 참고 블록의 위험 표시 없음은 이 판정으로 뒤집힘 — 최종 {N}행",
    "maeil_dairies": _H + "날짜 없는 정본 현행 인정 · ESG 정보 공개 게시물(이해관계자 소통 2026-06-25 · 주요 안전보건 활동 2026-02-26) 근거 워케이션 workation · 건강관리실 clinic · 체력단련실 fitness 추가 · 휴게실을 여성휴게실 lounge 행에 병합(리드 판정 154) · 참고 블록 보조 출처 줄에 두 게시물이 없는 것은 이 판정으로 뒤집힘 — 최종 {N}행",
    "kg_mobility": _H + "사내정비소 car_wash 행 삭제 · 자사 차량 구입 혜택 discount 행에 사내정비소 운영 병합(코드 이름의 세차가 원문에 없음) · 명절 선물/현금 holiday_gift 항목 페이지 예외 1(통합 밖 리드 집행) · 참고 블록의 공고 근거 0행 / 전체 25행은 전체 24행 — 최종 {N}행",
    "namyang_dairy": _H + "재택근무제 remote_work 서술에 공시 원격근무제 다섯 기간 사용자 수 - 와 ESG 정보공개 26쪽 출처를 더함(맨 칩 유지) · 하기 휴가 summer_leave 꼬리에 별도 부여 여부 미기재 · 현지 출퇴근 제도는 싣지 않음(리드 판정 155) — 최종 {N}행",
    "daekyo": _H + "jrs.jobkorea.co.kr/daekyo 는 회사 계정 채용 사이트(ATS) · 직무 전환 career 서술에 교사·교육관리직 트랙 출처와 다른 직군 적용 여부 미기재 · 온라인 직무 교육 상시 지원을 edu_support 에 병합 · 참고 블록의 공고 근거 17행 / 전체 19행은 16행(공시 단독 3행) · 제외 줄의 온라인 직무 교육은 이 판정으로 뒤집힘 — 최종 {N}행",
    "megastudy_edu": _H + "사내 카페·메가스낵존 snack_bar 이름과 서술에 원문 매점 낱말 살림 · 지하2층 사내 공간 소개 페이지 라운지 lounge 를 work_env 새 섹션으로 추가(리드 판정 154) · 참고 블록의 공고 근거 3행 / 전체 19행은 전체 20행 · 보조 출처와 SORT 섹션 순서 줄에 사내 공간 소개가 없는 것과 제외 줄의 사옥 시설 소개는 이 판정으로 뒤집힘 · 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 {N}행",
    "lx_hausys": _H + "주택자금 housing_loan 꼬리의 이자 지원율 미기재를 지원 방식·한도 미기재로(원문에 이자 없음) · 항목 페이지 예외 2(통합 밖 리드 집행) · 24 난임 치료 휴가 유급 3일은 2026-11-27 개정 재계산 대상 — 최종 {N}행",
    "lotte_himart": _H + "사우회를 경조제도 event 행에 병합 · 핵심 인재 경영 역량 향상 과정 Lotte MBA 를 위탁 사내대학 mba 서술에 병합(리드 판정 157) · 40쪽 온실가스 산정 범위의 사내 식당 meal 과 휴양소 resort 몫 유지(리드 판정 156) · 참고 블록 제외 줄의 사우회와 Lotte MBA 는 이 판정으로 뒤집힘 — 최종 {N}행",
    "jeju_air": _H + "그룹 인문교육을 edu_support 에 · 모두락 헬스케어를 clinic 에 병합하고 clinic 서술에서 심리 몫 걷기 · flex_work 공시 출처를 2026 반기보고서로 · 임직원몰을 welfare_point 에서 discount 임직원 항공권 행으로 옮겨 병합하고 welfare_point 행 삭제(감사 · 웨이브 11 임직원몰 잣대) · 애경 그룹 임직원 혜택 resort 는 단독 보고서의 자기 제도라 각주 없음 · 참고 블록 제외 줄의 모두락 헬스케어와 보조 출처 줄은 이 판정으로 뒤집힘 — 최종 {N}행",
    "aekyung_industrial": _H + "힐링테라스 멘탈 건강 상담 mental 행 추가 · 사내 의무실 clinic 서술에서 그 몫 걷기 · AK LIFE 주니어쌀롱 company_event 추가 · 우리사주 stock_option 유지 · 제주항공 기업 우대 서비스 discount 유지 · 항목 페이지 예외 3(통합 밖 리드 집행) · 참고 블록 제외 줄의 주니어쌀롱은 이 판정으로 뒤집힘 — 최종 {N}행",
    "trinity_air": _H + "행 조치 없음 · 수집본 21행 그대로 · 옛 사명 티웨이항공(2026-03-31 상호 변경 · 같은 법인) · 정본 점검기 blocked(점검기 UA 403 · 브라우저 200) 배포 시 주의 · 정기 건강진단(일반/특수)은 싣지 않음(리드 판정 147) — 최종 {N}행",
    "dong_a_st": _H + "leave_general 이름과 서술의 최소 22일을 연간 휴가 최소 22일로(연차와 별개 휴가로 읽히지 않게) · 자녀 학자금 child_edu 에서 발행일 없는 채용 페이지의 고교 몫 걷기 · 비연고지 근무 지원 relocation 유지 · 항목 페이지 예외 2(통합 밖 리드 집행) — 최종 {N}행",
    "nexen_tire": _H + "넥센유니버스는 캠페인 도메인이 아니라 상시 인재 브랜드 사이트 · 노사 소통 프로그램 저기요 team_dinner 추가 · 사내 원데이 클래스를 edu_support 에 병합 · SDU 학위 mba 서술에 선발 방식 표 칸 이름 살림 · 식대 864 유지 · 항목 페이지 예외 4(통합 밖 리드 집행) · 정본 도메인 만료 2026-11-08 배포 시 주의 — 최종 {N}행",
    "shinsegae_intl": _H + "Mini MBA·Junior MBA mba 서술에 교육체계도 BAND 직급 · 장기근속 long_service_bonus 각주를 (그룹 통합 채용 기준) 꼴로 · ESG 정보공시 사회13 감정노동자 멘탈관리 프로그램을 심리 상담 mental 에 병합 · 그룹 통합 채용 포털 근거 9행 각주 유지 — 최종 {N}행",
    "db_hitek": _H + "사내 체육시설 fitness 서술에 2025-2026 ESG경영보고서 59쪽 전문 헬스 트레이너 요가·GX 구절 추가(수집기 예외 후보 coach 빼기 기각) · 식대 864 · RSU 희망자 전환 stock_grant 유지 · 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 {N}행",
    "daesang": _H + "그룹 단서 판정은 가능(그룹 각주) 유지(리드 판정 158) · 성과 배분제 incentive 에 2026 지속가능경영보고서 76쪽 성과급 산정 구절 추가 · parenting 이름에 법적 사항 외 살림 · 하계휴가 summer_leave 서술의 법조문 낱말 걷기 · 온라인 교육 시스템을 edu_support 에 병합 · 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 {N}행",
}
assert set(HEADER_TEXT) == set(ROSTER_NM)
assert not any(("'" in v or '"' in v) for v in HEADER_TEXT.values())

WHY.update({
    "sm_entertainment": [
        "검증 SUSPECT · 조치 1 — 원문 「SM 포토부스 / 우리 SM만의 이색문화! 다양한 아티스트 앨범 / 프레임으로 동료들과 함께 촬영할 수 있습니다.」(`raw/recruit_benefit.txt:86-88`) · 서술의 「문화 공간」 중 「공간」은 원문 밖 낱말(3-11) · 코드 leisure_room 유지, 문안 교체 그대로",
    ],
    "woongjin_thinkbig": [
        "검증 MISSED · 조치 1 — 2026 반기보고서 XI-2 그 밖의 우발채무 「연결실체는 … 종업원에 대해서는 단체상해보험에 가입」(`dart/half2026.txt:17997` · 사업 `annual2025.txt:22689` 같은 문장) · 주어가 연결실체(법인 구분 없음)라 계약 3-5 ③ 통합 보고 각주 · 회사 배상 보험 둘은 행 아님, 완성 튜플 그대로(health 섹션 SORT 12 뒤)",
        "검증 SUSPECT · 조치 2 — 「기획/AI/마케팅/자격증 과정 등」 중 이 행 몫(자격증)만(3-11 「각 행은 자기 몫만」) · 코드 유지, 문안 교체 그대로",
    ],
    "maeil_dairies": [
        "검증 MISSED · 조치 1 — ESG 게시물 「이해관계자 소통」(2026-06-25) 임직원 주요 활동 칸 「유연근무및 워케이션 프로그램 등 다양한 근로환경 조성」 · 계약 3-1 「최신 판 주요 활동 칸의 지금 하는 일 = 행」, 완성 튜플 그대로(flexibility 섹션 SORT 42 뒤)",
        "검증 MISSED · 조치 2 · 리드 판정 (154) — 「주요 안전보건 활동」(2026-02-26) 4쪽 시설현황 「건강관리실등 : 8개소」 · 어휘 clinic(법정 열거 밖), 완성 튜플 그대로(health 섹션 SORT 34 뒤)",
        "검증 MISSED · 조치 3 · 리드 판정 (154) — 같은 쪽 「휴게실/체력단련실 : 52개소(+2)」의 체력단련실 몫 · 어휘 fitness, 완성 튜플 그대로(health 섹션 SORT 35 뒤)",
        "검증 조치 4 · 리드 판정 (154) — 같은 줄의 휴게실 몫을 lounge 한 행(여성휴게실)에 병합(회사당 한 행) · 이름 · 문안 교체 그대로",
    ],
    "kg_mobility": [
        "검증 SUSPECT · 조치 1 — 「사내정비소운영」(`src/social_report.txt:260`)에 세차 낱말 없음 · 코퍼스 car_wash 4행 모두 세차 · 비교 화면에 「세차」로 나간다 → 행 삭제(항목은 아래 병합으로 살림)",
        "검증 조치 2 — 선례 현대자동차 discount 「차량관리를 위한 자가정비코너 운영」 · 사용자 기준 「지우는 규칙보다 남기기」 · 이름 · 문안 교체 그대로",
    ],
    "namyang_dairy": [
        "검증 SUSPECT · 조치 1 — 반기 `dart_h2026.txt:11779` · 사업 `dart_a2025.txt:17063` 원격근무제 다섯 기간 모두 「-」 · 굳은 규칙(회사 자기 목록이 밝히면 싣고 「-」는 빼는 근거 아님)으로 행 · 맨 칩 유지, 서술에 공시 숫자를 드러냄(같은 웨이브 매일유업 41 꼴), 문안 교체 그대로",
        "검증 SUSPECT · 조치 2 — 「하기 휴가 및 휴가비 지원」에 일수 · 별도 부여 문장 없음 · 코드 유지(코퍼스 이름만 하계휴가 summer_leave 선례) · 꼬리에 별도 부여 여부 미기재, 문안 교체 그대로",
    ],
    "daekyo": [
        "검증 SUSPECT · 조치 1 — 「추후 개별 지원 및 선발 과정을 통해 … 직무 전환 가능」은 교사 직무 발령 → 교육관리직 트랙 「직무 비전」 칸 문장(`image_transcript.txt:13`) · 직군 한정은 서술에 대상(3-5), 문안 교체 그대로",
        "검증 MISSED · 조치 2 — 「직무 전문성, 꾸준히 강화해요 — 온라인 직무 교육 상시 지원」(`image_transcript.txt:34`) · 필수 · 의무 낱말 없는 상시 수강 지원(3-9 자율 수강 온라인 과정) · edu_support 한 행에 병합 · 이름 · 문안 교체 그대로",
    ],
    "megastudy_edu": [
        "검증 SUSPECT · 조치 1 — 「밥 먹고 매점에 들려 간식까지 가져가기 좋은 동선」 · 「구내식당과 매점 소개」(`greeting_restaurant.html`) — 매점을 떨구면 무료 간식으로 읽힘 · 이름 · 문안 교체 그대로(항목 페이지 store 면)",
        "검증 MISSED · 조치 2 · 리드 판정 (154) — 「잠시 쉬어가는 공간 B2 라운지 — … 업무 중 재충전은 물론 … 라운지를 조성」(검증 판독 `b2_transcript.txt:9`) · 어휘 lounge 정의 그대로 · 같은 페이지 회의실 · 면접실 · 교육장 · 폰부스 · 굿즈 존은 업무 공간이라 행 아님, 완성 튜플 + 섹션 머리 주석 그대로(보조 출처에만 있는 카테고리 → 끝 · SORT 81 뒤 · VALUES 마지막 행)",
    ],
    "lx_hausys": [
        "검증 SUSPECT · 조치 1 — 「은행을 통한 전세/구입 주택자금을 지원」(`careers_welfare.txt:50~51`)에 이자 · 이자 지원 없음 — 꼬리 「이자 지원율」은 원문에 없는 제도를 전제(꼬리도 사용자 노출 문안), 문안 교체 그대로",
    ],
    "lotte_himart": [
        "검증 MISSED · 조치 1 — 정본 복리후생 목록 「사우회 / … 상호부조와 복리증진을 위해 입사와 동시에 가입, 운영」(`recruit_weal.txt:49~51`) · 3-12 같은 목록 같은 기준 · 상호부조 = 경조 영역이라 event 병합(welfare_fund 는 원문 낱말 밖) · 이름 · 문안 교체 그대로",
        "리드 판정 (157) — 「핵심 인재 경영 역량 향상 과정(Lotte MBA)」(`sr2025.txt:5811` · 78쪽) · 굳은 규칙 (132) 「MBA 는 선발형이어도 mba」 · 형제 롯데케미칼 · 롯데정밀화학 선례 · 검증 보고서 8절 대안 글자 「, 핵심 인재 경영 역량 향상 과정(Lotte MBA) (78쪽 인재육성체계 항목)」를 60 서술의 첫 「 — 」 앞에 그대로 덧붙인 서술 전체(이름 · 꼬리 그대로 · 행 신설 없음)",
    ],
    "jeju_air": [
        "검증 MISSED · 조치 1 — 교육 체계도 「그룹 인문교육」 막대가 부서원 행(렌더 `s12_p1.png`) · 인문 = 교양 강좌(3-9 싣는다) · edu_support 한 행에 병합 · 이름 · 문안 교체 그대로(값의 SQL 홑따옴표만 기계로 걷음)",
        "검증 SUSPECT + MISSED · 조치 2 — 43 서술이 42 mental 몫(심리 상담)을 되풀이 → 건강 몫만 · 「모두락(사내 카페, 네일아트, 헬스케어)」의 헬스케어(3-12 같은 괄호 같은 기준) → clinic 병합 · 이름 · 문안 교체 그대로",
        "검증 SUSPECT · 조치 3 — 반기보고서에도 유연근무 표가 있다(`dart_half/20260814003505.txt:15853~15867` 시차출퇴근제 568 · 595 · 657) · 같은 표 · 같은 문장이면 출처 괄호를 최신 공시로(3-1), 문안 교체 그대로",
    ],
    "aekyung_industrial": [
        "검증 SUSPECT · 조치 1 — 「힐링테라스에서는 간단한 상처 치료를 비롯해 멘탈 건강 관리를 위한 상담과 휴식을 제공」(`AK_2025_SR_KOR.txt:3864~3865`) 한 행에 의무실 몫과 심리 상담 몫 → clinic 은 자기 몫만(3-11), 문안 교체 그대로",
        "검증 MISSED · 조치 3 — AK LIFE 조직문화 글 「주니어쌀롱」(`greeting_akculturejunior.txt:29~36`) · 회사가 마련한 교류 모임 · 「모두를 위한」으로 대상을 넓힘 · 온보딩 메뉴(AK IN)와 다름, 완성 튜플 그대로(leisure 섹션 SORT 24 뒤)",
        "검증 MISSED · 조치 2 — 같은 문장의 멘탈 건강 상담 몫 · 이름 없는 서비스도 급부를 밝히면 선다 · 같은 레인 제주항공 42 · 43 과 같은 처리(한 시설 두 영역 = 두 행), 완성 튜플 그대로(health 섹션 SORT 83 뒤)",
    ],
    "dong_a_st": [
        "검증 SUSPECT · 조치 2 — 보고서(2026-09 발행) 「대학교 학자금(8학기 전액 …), 약학대학, 의과대학 … 12학기」 vs 발행일 없는 채용 페이지 「고등학교 및 대학교 학자금」 → 3-1 발행일 있는 판을 따라 고교 몫 걷기(사용자 「옛 출처에만 있는 행은 빼기」), 문안 교체 그대로",
        "검증 SUSPECT · 조치 1 — 원문 「최소 22일의 유급 연차휴가 운영」(`sr2025_ko.blocks.txt:2276`) · 영문 「Minimum 22 days of paid annual leave」 = 연차를 포함한 연간 총 일수 · 「연차」만 걷으면 별개 휴가 22일로 읽힘 → 어휘 경계 「연간 휴가 총 N일」 꼴, 이름 · 문안 교체 그대로",
    ],
    "nexen_tire": [
        "검증 MISSED · 조치 1 — 보고서 60쪽 노사 소통 강화 프로그램 「저기요 • 매월 두 팀이 배달음식을 먹으며 팀원 간 소통 (감사인사, 짝지 운영)」 · 회사 운영 매월 상시 프로그램 · 코퍼스 다우기술 「회식 제도」 꼴, 완성 튜플 그대로(perks 섹션 SORT 56 뒤)",
        "검증 MISSED · 조치 2 — 넥센유니버스 조직문화 게시물 「사내 원데이 클래스」 연재(여러 사업장 · 10건 이상) · 회사가 여는 교양 · 문화 강좌(3-9) · edu_support 한 행에 병합 · 이름 · 문안 교체 그대로",
        "검증 조치 3 — 59쪽 표 칸 이름 「선발 방식」을 서술에 살려 항목 페이지 who 면(예외 없이) · 검증 §7 의 옛 구절 → 새 구절 교체를 적용한 서술 전체(나머지 글자 수집본 그대로)",
    ],
    "shinsegae_intl": [
        "검증 SUSPECT · 조치 1 — 사회10 2쪽 교육체계도(렌더 `s10p2_crop.png`)의 상자가 BAND1 · BAND2 / BAND3 · BAND4 행에 걸쳐 있음 → 꼬리 「대상 직급 미기재」는 원문과 어긋남 · 직급을 서술에, 문안 교체 그대로",
        "검증 MISSED · 조치 3 — ESG 정보공시 사회13 안전보건경영 중장기 로드맵 「감정노동자 멘탈관리 프로그램 운영」 · 법정 열거 밖 · 같은 코드라 mental 한 행에 병합 · 이름 · 문안 교체 그대로",
        "검증 SUSPECT · 조치 2 — 각주가 꼴 ① 밖 「(포상제도 문구는 그룹 통합 채용 기준)」 → 「(그룹 통합 채용 기준)」(코퍼스 자기 보고서 + 그룹 채용 사이트 병합 행 같은 꼴) · 서술 전체 교체 = 옛 꼬리 → 새 꼬리 교체와 같은 글자(`_audit.py` assert), 문안 교체 그대로",
    ],
    "db_hitek": [
        "검증 조치 1 — 보고서 59쪽 첫 문단 「전문 헬스 트레이너를 통해 요가·GX, 운동 및 식단 상담 등 … 건강관리를 지원」(검증 렌더 `p059_0.0_0.1.png`) · 수집기 판독 사본이 이 문단을 빠뜨림 → coach 면이 원문으로 켜짐(수집기 예외 후보 기각) · 수집본처럼 「 — 」 꼬리 없음(원문이 운영 방식을 다 밝힘), 문안 교체 그대로",
    ],
    "daesang": [
        "검증 SUSPECT · 조치 2 — 원문 「법적 사항 외 산전 휴가제도」(57쪽 상자) · 이름에서 「법적 사항 외」를 떼면 법정 출산전후휴가를 회사 복지로 단 것처럼 읽힘, 이름 교체 그대로",
        "검증 SUSPECT · 조치 1 — 유일 근거 인사제도 페이지는 헤더 메뉴에서 빠진 옛 탭 구조(홈 배너 링크만) · 더 새 원문 보고서 76쪽 「… KPI 달성률은 연봉 및 성과급 산정에 활용」(`esg_kr_2026.txt:5284-5285`)을 더함, 문안 교체 그대로",
        "검증 MISSED(병합) · 조치 4 — 52쪽 「인재육성 제도&인프라」 한 줄 넷(필수과정 이수 · 사외교육 · 어학교육 · 온라인 교육 시스템) 중 같은 줄 둘은 이름만으로 세웠는데 온라인 교육 시스템만 뺌(3-12 같은 표 같은 기준) · edu_support 한 행에 병합 · 이름 · 문안 교체 그대로",
        "검증 SUSPECT · 조치 3 — 서술 「근로기준법에서 규정한」 = 법조문(3-11 금지) · 「연차휴가 외 별도로」만으로 법정분 · 회사분 구분이 남음, 문안 교체 그대로",
    ],
})
# 감사 몫(AUDIT_ACTIONS) — ACTIONS 뒤에 붙는다(all_actions 순서)
WHY["jeju_air"] += [
    "**감사 §2-6 · §13-2** — 「임직원몰」(62쪽 임직원 복리후생 항목 · 같은 문단 「… 식권 제공, 임직원몰, 사내 동호회 등」 · 포인트 · 배정 낱말 없음)은 웨이브 11 감사 §1-2 ① 잣대(코퍼스 「임직원몰」 단독 라벨 discount 4 — LG생활건강 · LG유플러스 · 종근당 · 오뚜기 / welfare_point 1 — 영풍)대로 discount · 항목 페이지 discount 「온라인 몰·복지몰에서도 할인」 면이 이 낱말로 켜짐 · 회사당 한 행이라 20 discount 에 병합(원문 낱말 · 출처 괄호 그대로 · 꼬리에 임직원몰 이용 혜택 미기재) — 새 글자는 수집본 20 · 22 글자에서 기계로 만듦",
    "**감사** — 위 병합으로 22 welfare_point 행 삭제(제주항공 원문에 복지포인트 · 배정 문장 0 — 지우지 않으면 비교 화면이 복지포인트가 있는 회사로 그린다)",
]
_HDR_KEEP = ("—", "(머리말 참고 블록)", "고치지 않음",
             "계약 A 5 · B 7 — 참고 블록의 옛 문장은 고치지 않고 헤더 한 줄이 뒤집힘을 적는다(검증의 「머리말 참고 블록 정정」 권고는 집행하지 않음 · 근거표 정정은 §14-5)")
KEEP.update({
    "hanatour": [
        (10, "discount", "임직원 전용 여행상품 discount 유지", "검증 SUSPECT(할인 낱말 없음) · 유지 권고 — 어휘 discount 「항공권 · 자사 제품」 임직원 혜택 · 문안이 할인을 단언하지 않음(꼬리 「혜택 방식·혜택 폭」)"),
        (20, "leave_general", "1년 미만 여행 + 2시간 단위 휴가 한 행", "검증 판정 — 「연차 사용 없이 여행」은 본인 휴가를 쓰지 않는 특별휴가 · 경비 지원 원문 없음(travel_support 아님) · 회사당 한 행"),
    ],
    "sm_entertainment": [
        (32, "stock_grant", "유지", "검증 판정 — 「주식기준보상제도를 운영하고 있지 않습니다」는 임원 보수 표 주1(4회) · 같은 3사업연도 직원 스톡그랜트 지급 문장과 대조"),
        (24, "housing_loan", "대여금 housing_loan 유지 + 예외 direct", "검증 판정 — 어휘 「주택 대출과 한 라벨이면 housing_loan」 · 서술에 대출 낱말 더하지 않음"),
    ],
    "woongjin_thinkbig": [_HDR_KEEP,
        (72, "remote_work", "원격근무제 유지(맨 칩)", "검증 판정 — 공시 「-」 + 주석 「원격근무 환경이 마련되어 있어, 전 직원이 상황에 맞게 활용」 = 유연근무 표 안의 운영 문장(굳은 규칙)"),
    ],
    "maeil_dairies": [_HDR_KEEP,
        ("—", "(정본 현행성)", "날짜 없는 정본 현행 인정", "검증 판정 — 홈 헤더 · 푸터 메뉴 링크 · 2026 반기보고서 가족친화제도 문장 · 2026-06 ESG 게시물 주요 활동이 받침 · 더 새 원문과 어긋나는 행 0"),
    ],
    "kg_mobility": [_HDR_KEEP,
        (24, "meal", "중식 288 추정 유지", "검증 판정 — 「통근버스 및 중식 무료 지원」의 「무료」는 두 항목에 다 걸림 · 1끼 × 12,000원 × 240일"),
        (61, "leave_general", "자율휴가제 이름만 · 개인 질병휴직 유지", "검증 판정 — 휴가 사용 방식 · 법정 휴직 아님(병가 경계)"),
    ],
    "namyang_dairy": [
        ("—", "(현지 출퇴근 제도 활성화)", "싣지 않음", "리드 판정 (155) — 영업 현장 직행 · 직퇴 같은 근무 운영 · flex_work 원문 근거 없음(검증 기본안)"),
        (50, "refresh_leave", "Refresh 휴가 유지", "검증 판정 — 「Refresh, 징검다리 휴가 활성화」 = 「A, B 휴가」 꼴 · 징검다리 몫은 장려라 뺌"),
    ],
    "daekyo": [_HDR_KEEP,
        ("—", "(공고 근거 16행)", "유지", "검증 판정 — jrs.jobkorea.co.kr/daekyo 는 잡코리아 채용관리 솔루션의 대교 계정(1-3 ATS) · 마감 공고지만 회사 계정 사이트에 공개 중 · 더 새 공고 없음 → (138) 처리 · 위험 표시 「한시적 출처」"),
        (43, "stock_grant", "자기주식 포상 별도 행 유지", "검증 판정 — 공시 자기주식 항목 「임직원 등 조직원 포상 목적」"),
    ],
    "megastudy_edu": [_HDR_KEEP,
        (20, "discount", "가족 강좌 수강료 discount 서술 유지", "검증 판정 1 — 자사 · 계열 상품 혜택"),
        ("60 · 71", "long_service_leave · long_service_bonus", "두 행", "검증 판정 2 — 원문이 휴가 · 휴가비 한 줄과 장기근속포상을 다른 항목으로 나눔(어휘 경계)"),
    ],
    "lx_hausys": [
        (60, "profit_sharing", "유지", "검증 판정 — 더 새 원문 2026 보고서 52쪽 「조직 성과를 반영한 경영성과급」(3-1) · 개인 차등 · 즉시 보상은 61 incentive 따로"),
        (50, "summer_leave", "유지", "검증 판정 — 단체 휴무 문장 없음 · 코퍼스 이름만 하계휴가 관례"),
        (11, "meal", "금액 NULL 유지", "검증 판정 — 제공 · 지원 · 무료 낱말 없는 「사내 식당 운영」(3-3)"),
        (24, "fertility_support", "유급 3일(법정 2일에 1일 추가) 지금 법 기준 유지", "🚨 2026-11-27 재계산 대상(§14-1)"),
    ],
    "lotte_himart": [_HDR_KEEP,
        ("23 · 80", "meal · resort", "40쪽 온실가스 산정 범위의 사내 식당 · 휴양소 몫 유지", "리드 판정 (156) — 이 법인 시설 · 복지 코드가 있는 시설 이름 · 롯데칠성음료 Scope3 통근버스 선례(검증 기본안)"),
        (42, "parenting", "자녀 돌봄 휴직 서술 유지", "검증 판정 — 법정 17항목에 자녀 입학 돌봄 휴직 없음 · 형제 4 : 1 갈림은 §14-2 별건"),
    ],
    "jeju_air": [_HDR_KEEP,
        (50, "resort", "애경 그룹 임직원 혜택 각주 없음", "검증 판정 — 제주항공 단독 보고서의 자기 제도 표 · 애경산업 사본에 같은 문장 0(그룹 템플릿 아님)"),
        (70, "long_service_leave", "유지(맨 칩)", "검증 판정 — 2026 판 라벨 「장기근속」 + 2025 판 「장기근속 포상휴가」(옛 판은 뜻 받침에만)"),
    ],
    "aekyung_industrial": [_HDR_KEEP,
        (62, "stock_option", "우리사주 유지", "검증 판정 — 보고서 83쪽 제도 문장 + 반기 담보 주석(주주 표 한 칸 아님)"),
        (12, "discount", "제주항공 기업 우대 서비스 유지", "검증 판정 — 단독 계정 채용 사이트 복리후생 목록 항목 · 형제 제주항공 사본에 대응 복지 문장 없음"),
        (13, "housing_loan", "예외 후보 unknown 기각", "검증 판정 — 「주택자금대출」 라벨 20사가 예외 없이 direct"),
    ],
    "trinity_air": [
        ("—", "(정본 점검기 blocked)", "1476 정본 유지", "검증 판정 — 3-1 정본 조건 충족(브라우저 200 · robots 허용) · 점검 가능한 자기 도메인 대안 없음 → 배포 시 주의(§14-8)"),
        ("—", "(정기 건강검진)", "싣지 않음", "리드 판정 (147) — 같은 페이지 「연령별 맞춤 정기 건강진단(일반/특수)」이 법정 검진 이름만"),
    ],
    "dong_a_st": [
        (45, "relocation", "유지", "검증 판정 3 — 원문에 주거 낱말 없음(근거표 수치 정정만 §14-5)"),
        (41, "snack_bar", "사내 카페테리아 유지", "검증 판정 1 — 코퍼스 snack_bar 이름 「사내 카페테리아」 6행"),
        ("—", "(은퇴설계 · 은퇴자 프로그램)", "싣지 않음", "검증 판정 4 — 1,000인 이상 · 대상 확대 문장 없음 → 법정 요약(웨이브 7 규칙)"),
    ],
    "nexen_tire": [
        ("—", "(정본 nexenuniverse.com)", "정본 · 9행 유지", "검증 판정 — 공식 홈 꼬리말 3쪽 링크 · 보고서 24쪽 임직원 소통 채널 · 사내 SSO · RDAP 갱신 흔적 → 캠페인 도메인 아님 · 만료 2026-11-08 배포 시 주의(§14-8)"),
        (50, "meal", "864 유지", "검증 판정 — 회사 전체 세 끼 무료 · 마곡만 석식 일부 부담(3-3 「사업장별 상이는 적힌 끼니로」)"),
    ],
    "shinsegae_intl": [
        ("—", "(그룹 통합 채용 포털 근거 9행)", "각주 ① 유지", "검증 판정 — 법인 채용 페이지 「지원하기」 = 그룹 포털 · 단서 없음 · 이마트는 이 포털 홈을 쓰지 않음(1-6 보류 아님)"),
        (30, "lang", "월 15만원 NULL 유지", "검증 판정 — 수강자만 받는 조건부 지원(3-3)"),
    ],
    "db_hitek": [
        (91, "stock_grant", "유지", "검증 판정 — 희망 임직원 누구나 고르는 성과급 자사주 전환(재량 RSU 아님) · 칸 문장이 직원 적용을 밝힘"),
        (13, "meal", "864 유지", "검증 판정 — 「조식, 중식, 석식, 야식 등 하루 4회 식사 타임 제공」 · 야식 제외 3끼"),
        ("—", "(물리치료실)", "싣지 않음", "검증 판정 5 — 더 새 판 보고서가 그 자리를 건강관리실로 바꿈(3-1)"),
    ],
    "daesang": [
        ("20행", "(각주 ②)", "가능(그룹 각주) 유지", "리드 판정 (158) — 그룹 채용 사이트판에만 붙은 「일부 차이가 있을 수」 단서는 법인 자기 도메인 정본을 조건부로 내리지 않는다"),
        (81, "leave_general", "長 Up-Day 유지 · 장기 Refresh 뺌 유지", "검증 판정 — 의무 집중휴가는 싣고 「장기 연차 사용을 독려」는 본인 연차(3-6)"),
    ],
})


@section("fmt")
def sec_fmt(collect, final, corpus):
    print("=" * 100)
    print("§fmt 수집본 · 모의본 형식 · 등록 · slug · 표시명 충돌")
    slugs = {slug_of(c["meta"]["eng"]): c["file"] for c in corpus.values()}
    names = {c["meta"]["nm"]: c["file"] for c in corpus.values()}
    wave_slugs = collections.Counter(slug_of(e) for e in collect)
    wave_names = collections.Counter(c["meta"]["nm"] for c in collect.values())
    for eng, c in collect.items():
        p = fmt_problems(c)
        ps = fmt_problems(parse_file(f"{SIM}/{c['file']}.sql"), expected_meta(eng, collect), HEADER_LINE[eng])
        sl = slug_of(eng)
        coll = []
        if sl in slugs:
            coll.append(f"slug 충돌 {slugs[sl]}")
        if c["meta"]["nm"] in names:
            coll.append(f"표시명 충돌 {names[c['meta']['nm']]}")
        if wave_slugs[sl] > 1 or wave_names[c["meta"]["nm"]] > 1:
            coll.append("웨이브 안 중복")
        st = len(load._split_sql_statements(open(f"{SIM}/{c['file']}.sql", encoding="utf-8").read()))
        st0 = len(load._split_sql_statements(c["text"]))
        print(f"  {c['file']:<10} eng={eng:<20} slug={sl:<20} 행 {len(c['rows']):>2} → 최종 {len(final[eng]):>2} · "
              f"수집본 문장 {st0} 형식 {p or 0} · 모의본 문장 {st} 형식 {ps or 0} · 충돌 {coll or 0}")
    # 표시명이 코퍼스 별칭(company_meta 의 aliases)과 겹치는지 — 검색 상자 충돌
    from db.seed import company_meta as cm
    meta = cm.build_company_meta()
    alias_owner = collections.defaultdict(set)
    for e, v in meta.items():
        for a in v.get("aliases", []):
            alias_owner[a].add(e)
    for eng, c in collect.items():
        hit = alias_owner.get(c["meta"]["nm"]) or alias_owner.get(eng)
        if hit:
            print(f"   ⚠ 표시명 · eng 가 기존 별칭과 겹침: {c['meta']['nm']} ↔ {sorted(hit)}")
    print(f"  build_company_meta(worktree 코퍼스) 회사 {len(meta)}")


@section("codes")
def sec_codes(collect, final, corpus):
    print("=" * 100)
    print("§codes 신규 코드 — 어휘표 93종 · 코퍼스 실사용 대비")
    voc = vocab_table()
    used = collections.defaultdict(set)
    for eng, c in corpus.items():
        for r in c["rows"]:
            used[r["cd"]].add(eng)
    print(f"  어휘표 코드 {len(voc)} · 코퍼스 실사용 코드 {len(used)} · 어휘표 ≠ 실사용 {sorted(set(voc) ^ set(used)) or 0}")
    print(f"  어휘표 n ≠ 코퍼스 실사용 회사 수: {[(c, voc[c][0], len(used[c])) for c in voc if voc[c][0] != len(used.get(c, ()))] or 0}")
    for label, rows_of in (("수집본", lambda e: collect[e]["rows"]), ("최종본", lambda e: final[e])):
        codes = collections.Counter(r["cd"] for e in collect for r in rows_of(e))
        new_v = sorted(c for c in codes if c not in voc)
        new_c = sorted(c for c in codes if c not in used)
        ctg = [(e, r["sort"], r["cd"], r["ctgr"], voc[r["cd"]][1]) for e in collect for r in rows_of(e)
               if r["cd"] in voc and voc[r["cd"]][1] != r["ctgr"]]
        bad_fmt = sorted(c for c in codes if not re.fullmatch(r"[a-z][a-z0-9_]{1,29}", c))
        print(f"  {label}: 행 {sum(codes.values())} · 코드 {len(codes)}종 · 어휘표 밖 {new_v or 0} · 코퍼스 미사용 {new_c or 0} · "
              f"카테고리 ≠ 어휘표 {ctg or 0} · 형식 위반 {bad_fmt or 0}")
    allc = set(used)
    for e in collect:
        allc |= {r["cd"] for r in final[e]}
    print(f"  최종 반영 뒤 쓰이는 코드 수 {len(allc)} (지금 {len(used)})")
    # 이번 웨이브가 처음 쓰는 회사 수가 적은 코드(코퍼스 1~3사) — 뜻이 맞는지 보려고
    fin_codes = collections.Counter(r["cd"] for e in collect for r in final[e])
    rare = sorted((len(used[c]), c, fin_codes[c]) for c in fin_codes if len(used.get(c, ())) <= 8)
    print(f"  코퍼스 8사 이하 코드를 이번에 쓰는 것(코퍼스 회사 수 · 코드 · 이번 행): {rare}")




SIBLINGS = {  # 이번 회사 eng → 기등록 형제 · 같은 그룹 · 같은 업종 회사 표시명(정규식) — 코퍼스 257 + 이번 웨이브 안
    "hanatour": r"하나투어|롯데관광개발|모두투어|대한항공|제주항공|트리니티항공|호텔신라|파라다이스",
    "sm_entertainment": r"카카오|하이브|JYP|와이지|에스엠|SM",
    "woongjin_thinkbig": r"웅진|대교|메가스터디",
    "maeil_dairies": r"매일|남양유업|빙그레|동원|오뚜기|대상$|롯데웰푸드",
    "kg_mobility": r"^KG|케이지|현대자동차|기아|쌍용",
    "namyang_dairy": r"남양|매일유업|빙그레|롯데웰푸드",
    "daekyo": r"대교|웅진씽크빅|메가스터디",
    "megastudy_edu": r"메가스터디|웅진씽크빅|대교",
    "lx_hausys": r"^LX|엘엑스|한샘|KCC",
    "lotte_himart": r"^롯데(?!관광)",
    "jeju_air": r"애경|대한항공|트리니티항공|제주항공",
    "aekyung_industrial": r"애경|제주항공|LG생활건강|아모레|코스메카|한국콜마|코스맥스",
    "trinity_air": r"대한항공|제주항공|티웨이|소노",
    "dong_a_st": r"동아|에스티팜",
    "nexen_tire": r"넥센|한국타이어|금호타이어",
    "shinsegae_intl": r"신세계|이마트|F&F|영원무역",
    "db_hitek": r"^DB|디비",
    "daesang": r"^대상|CJ제일제당|오뚜기|동원",
}
_SRC_PAREN = re.compile(r"\([^()]*(보고서|페이지|사이트|공시|항목|쪽|보도자료|채용|홈페이지|기준)[^()]*\)")


def _fragments(text: str) -> set:
    if not text:
        return set()
    t = text.split(" — ")[0]
    t = _SRC_PAREN.sub(" ", t)
    out = set()
    for f in re.split(r"[,·()「」/:]|\s-\s", t):
        f = re.sub(r"\s+", " ", f).strip()
        if len(f.replace(" ", "")) >= 10:
            out.add(f)
    return out




FOOTNOTE = re.compile(r"\(그룹 통합 채용 기준\)|공통 문구|통합 보고 기준\)|통합 채용 기준\)")




@section("consist")
def sec_consist(collect, final, corpus):
    print("=" * 100)
    print("§consist ① 각주 세 꼴 — ① 그룹 통합 채용(에코프로머티리얼즈) · ② 그룹 공통 문구(동원 · SKC Family 변형) · ③ 통합 보고(SKC 31)")
    for e in collect:
        for r in final[e]:
            t = r["qd"] or r["note"] or ""
            if FOOTNOTE.search(t) or "그룹 채용" in t or "통합 채용" in t or "그룹" in t:
                tail = rc.dash_tail_breaks(t)
                ends = t.rstrip().endswith("(그룹 통합 채용 기준)")
                print(f"   {collect[e]['file']}\tSORT {r['sort']}\t{r['cd']}\t각주={bool(FOOTNOTE.search(t))}\t맨끝={ends}\tSI-11깨짐={tail}\t…{t[-90:]}")
    per = collections.Counter(collect[e]["file"] + ":" + m.group(0) for e in collect for r in final[e]
                              for m in [FOOTNOTE.search(r["qd"] or r["note"] or "")] if m)
    print(f"   각주 낱말 행(회사:꼴) {dict(per)}")

    print("\n§consist ② 성과급 꼴 — incentive / profit_sharing(이번 웨이브 최종본)")
    pat = re.compile(r"경영\s*실적|경영\s*성과|회사\s*실적|영업이익|Profit Sharing|이익|전사|회사의 성과|회사 및 개인|사업 성과|경영목표|경영 목표|당사 실적|성과이익")
    other = re.compile(r"개인|조직|팀|부서|평가|차등|등급|KPI|PI\b|업적|역량")
    for e in collect:
        for r in final[e]:
            if r["cd"] in ("incentive", "profit_sharing"):
                t = rtext(r)
                only_company = bool(pat.search(t)) and not other.search(t)
                flag = "  ◀ 회사 실적만인데 incentive" if only_company and r["cd"] == "incentive" else ""
                flag += "  ◀ 평가 차등이 있는데 profit_sharing" if r["cd"] == "profit_sharing" and other.search(t) else ""
                print(f"   {collect[e]['file']}\tSORT {r['sort']}\t{r['cd']}\t회사실적={bool(pat.search(t))}\t평가·개인={bool(other.search(t))}\t{r['nm']}{flag}")

    print("\n§consist ③ 형제 이중 등록 · 문장 겹침(10자 이상 조각 · 출처 괄호 · 꼬리 제외) — 코퍼스 257 + 웨이브 안 18")
    wave = {e: dict(meta=collect[e]["meta"], rows=final[e], file=collect[e]["file"]) for e in collect}
    pool = dict(corpus)
    for e, v in wave.items():
        pool["W9:" + e] = v
    for e in collect:
        pat_s = re.compile(SIBLINGS[e])
        sibs = {x: c for x, c in pool.items() if x != "W9:" + e and pat_s.search(c["meta"]["nm"])}
        sib_text = " ".join(rtext(r) for c in sibs.values() for r in c["rows"])
        hits = []
        for r in final[e]:
            for f in _fragments(r["qd"] or r["note"]):
                if f in sib_text:
                    hits.append((r["sort"], r["cd"], f))
        print(f"   {collect[e]['file']}: 형제 {len(sibs)}({', '.join(('웨이브12 ' if k.startswith('W9:') else '') + c['meta']['nm'] for k, c in sibs.items()) or '없음'}) · 겹친 조각 {len(hits)}")
        for h in hits:
            print(f"      SORT {h[0]} {h[1]}: 「{h[2]}」")

    print("\n§consist ④ 난임 · 11-27(이번 웨이브 최종본 행 · 근거표 「11-27」 줄)")
    for e in collect:
        for r in final[e]:
            if "난임" in rtext(r):
                print(f"   행 {collect[e]['file']}\tSORT {r['sort']}\t{r['cd']}\t{r['nm']}\t…{(r['qd'] or r['note'])[:200]}")
        ev = open(f"{COLLECT}/{collect[e]['file']}.evidence.md", encoding="utf-8").read()
        lines = [ln.strip()[:220] for ln in ev.splitlines() if "11-27" in ln]
        print(f"   근거표 {collect[e]['file']}: 「난임」 줄 {sum(1 for ln in ev.splitlines() if '난임' in ln)} · 「11-27」 줄 {len(lines)}")
        for ln in lines:
            print(f"        {ln}")

    print("\n§consist ⑤ 같은 이름이 다른 코드(코퍼스 + 이번 웨이브)")
    by_name = collections.defaultdict(collections.Counter)
    for c in corpus.values():
        for r in c["rows"]:
            by_name[r["nm"]][r["cd"]] += 1
    for e in collect:
        for r in final[e]:
            cs = by_name.get(r["nm"])
            if cs and r["cd"] not in cs:
                print(f"   {collect[e]['file']}\tSORT {r['sort']}\t{r['cd']}\t「{r['nm']}」 코퍼스에서는 {dict(cs)}")
    wn = collections.defaultdict(set)
    for e in collect:
        for r in final[e]:
            wn[r["nm"]].add((r["cd"], collect[e]["file"]))
    for nm, s in wn.items():
        if len({x[0] for x in s}) > 1:
            print(f"   웨이브 안 같은 이름 다른 코드 「{nm}」 {sorted(s)}")

    print("\n§consist ⑥ 웨이브 10 경계 축 — 이름 · 서술 정규식 또는 코드 묶음")
    probes = [
        ("시간 단위 휴가 이름", r"시간 단위|분 단위|반일의 절반|반반차", ()),
        ("의무화 · 의무 사용", r"의무화|의무 육아|의무 사용|남성 의무", ()),
        ("conference 행", None, ("conference",)),
        ("remote_work · satellite_office 행", None, ("remote_work", "telecommute", "wfh", "satellite_office")),
        ("insurance · medical 행", None, ("insurance", "medical")),
        ("retirement_support 행 · 생애설계", r"생애 ?설계|재취업|전직", ("retirement_support",)),
        ("대출 · 기금 · 주거 행", None, ("welfare_fund", "welfare_fund_loan", "housing_loan", "housing_support", "relocation", "dormitory")),
        ("근속 행(long_service_*)", None, ("long_service_bonus", "long_service_leave")),
        ("학위 · MBA · 유학 · mba 행", r"학위|MBA|대학원|유학|석사", ("mba",)),
        ("노사협의회 · 협의회 근거 행", r"협의회|노사|행복씨|안건", ()),
        ("성과급 · 주식 행", None, ("incentive", "profit_sharing", "bonus", "stock_option", "stock_grant")),
        ("휴가 코드 행", None, ("refresh_leave", "leave_general", "summer_leave", "birthday_leave", "foundation_day_leave", "family_day")),
        ("식대 · 간식 행", None, ("meal", "snack_bar", "grocery_support")),
        ("기념일 · 선물 행", None, ("holiday_gift", "birthday_gift", "welcome_kit", "promotion_gift")),
        ("교육 행(lang · edu_support · self_development · books · library · career)", None, ("lang", "edu_support", "self_development", "books", "library", "career")),
        ("부문 · 사업부 · 사업장 · 직군 한정 이름", r"부문\)|사업부|사업장|직군|공장\)|해상|제주|본사\)", ()),
        ("재무제표 주석 · 장기종업원급여 근거", r"재무제표 주석|장기종업원급여|종업원급여|장기근속보상", ()),
        ("공고 근거 행", r"채용 공고|공고 ", ()),
        ("복지몰 · 포인트 행", r"복지몰|임직원몰|포인트", ("welfare_point", "discount")),
        ("효도 · 부모 · 간병(parent_care)", r"효도|부모|간병", ("parent_care",)),
        ("퇴직 · 퇴직금(severance_plus · retirement_support)", r"퇴직", ("severance_plus", "retirement_support")),
        ("영문 원문 서술", r"[A-Za-z]{4,} [a-z]{3,} [a-z]{3,}", ()),
        ("관리비 · 숙소 · 주거", r"관리비|숙소|주거", ()),
        ("우리사주 · 스톡 · 자기주식", r"우리사주|스톡|자사주|자기주식", ("stock_option", "stock_grant")),
        ("세차 · 이용원 · 시설 서비스", r"세차|이용원|이발", ("car_wash", "barber_shop")),
        ("각주 낱말", r"공통 문구|통합 채용 기준|통합 보고 기준", ()),
        ("한시 · 공고 · 기사 근거", r"채용공고|공고|뉴스|기사", ()),
    ]
    for label, rx, codes in probes:
        print(f"   [{label}]")
        for e in collect:
            for r in final[e]:
                t = rtext(r)
                if (rx and re.search(rx, t)) or r["cd"] in codes:
                    print(f"      {collect[e]['file']}\tSORT {r['sort']}\t{r['cd']}\t「{r['nm']}」\t…{(r['qd'] or r['note'])[:170]}")


@section("amt")
def sec_amt(collect, final, corpus):
    print("=" * 100)
    print("§amt 금액 행 전수(수집본 · 최종본) — 예측 금액 출처 derive_amt_source")
    for label, rows_of in (("수집본", lambda e: collect[e]["rows"]), ("최종본", lambda e: final[e])):
        n = 0
        for e in collect:
            for r in rows_of(e):
                if r["amt"] is not None:
                    n += 1
                    s = derive_amt_source(r["amt"], r["qual"], r["note"])
                    fa = rc.formula_amount(r["note"])
                    meals = rc.meals_in_text(r["nm"], r["note"]) if r["cd"] == "meal" else None
                    print(f"  [{label}] {collect[e]['file']}\tSORT {r['sort']}\t{r['cd']}\t{r['amt']}\t{s}\t꼬리식={fa}\t본문끼니={meals}\t{r['note']}")
        print(f"  [{label}] 금액 행 {n}")
    print("\n  원 · 만원 숫자가 서술에 있는데 금액 칸이 빈 행(최종본)")
    won = re.compile(r"\d[\d,.]*\s*(만\s*원|원|만원)|\d+\s*천만|\d+\s*억")
    for e in collect:
        for r in final[e]:
            if r["amt"] is None and won.search(r["qd"] or ""):
                ms = sorted({m.group(0) for m in won.finditer(r["qd"])})
                print(f"   {collect[e]['file']}\tSORT {r['sort']}\t{r['cd']}\t{r['nm']}\t숫자 {ms}")
    print("\n  코퍼스 금액 축 최댓값(이번 금액 행 코드)")
    for cd in sorted({r["cd"] for e in collect for r in final[e] if r["amt"] is not None}):
        vals = sorted((r["amt"], c["file"]) for c in corpus.values() for r in c["rows"] if r["cd"] == cd and r["amt"])
        print(f"   {cd}: 금액 행 {len(vals)} · 최댓값 {vals[-1] if vals else None} · 중간값 {vals[len(vals)//2] if vals else None}")


def _dart_local() -> dict:
    """로컬 사본만으로 DART 대응을 만든다(새 요청 0) — company-20.json · corpCode.zip 목록 이름 · check-2026-10-18.json 축."""
    import xml.etree.ElementTree as ET
    import zipfile
    out = {}
    c20 = {x["name"]: x for x in json.load(open(DART_COMPANY_20, encoding="utf-8"))}
    chk = json.load(open(DART_CHECK, encoding="utf-8"))
    z = zipfile.ZipFile(CORPCODE_ZIP)
    names = {}
    want = {x["corp_code"] for x in c20.values()}
    for el in ET.fromstring(z.read(z.namelist()[0])).iter("list"):
        if el.findtext("corp_code") in want:
            names[el.findtext("corp_code")] = (el.findtext("corp_name"), (el.findtext("stock_code") or "").strip(),
                                               el.findtext("corp_eng_name"), el.findtext("modify_date"))
    for e, fn in ROSTER_NM.items():
        c = c20[COMPANY20_NAME.get(fn, fn)]
        nm, sc, eng_nm, mod = names[c["corp_code"]]
        assert sc == c["stock_code"], (e, sc, c["stock_code"])
        k = chk[COMPANY20_NAME.get(fn, fn)]
        assert k["corp_code"] == c["corp_code"] and k["stock"] == c["stock_code"], (e, k)
        out[fn] = dict(corp_code=c["corp_code"], dart_name=nm, stock=c["stock_code"], market=c["market"],
                       induty=c["induty_code"], legal_nm=c["dart_name"], eng_nm=eng_nm, est=c["est_dt"], hm=c["hm_url"],
                       emp=c["employees"], fin=k["fin"], emp_axis=k["emp"], list_mod=mod)
    return out


@section("reg")
def sec_reg(collect, final, corpus):
    print("=" * 100)
    print("§reg 등록 값 · 업종 · corp_code")
    dart = _dart_local()
    inds = collections.Counter(c["meta"]["ind"] for c in corpus.values())
    import csv
    cmap = list(csv.DictReader(open(WT + "/db/seed/corp_code_map.csv", encoding="utf-8")))
    have_codes = collections.Counter(r["corp_code"] for r in cmap if r["corp_code"])
    have_names = {r["comp_nm"] for r in cmap}
    codes_here = []
    for eng, c in collect.items():
        m = expected_meta(eng, collect)
        dk = dart[ROSTER_NM[eng]]
        codes_here.append(dk["corp_code"])
        same = len([x for x in collect.values() if x["meta"]["ind"] == m["ind"]])
        print(f"  {c['file']}\t{eng}\t{m['nm']}\t{m['tp']}\t{m['ind']}(코퍼스 {inds.get(m['ind'], 0)} + 이번 {same})\t{m['logo']}\t"
              f"slug={slug_of(eng)}\tDART {dk['corp_code']} 목록 '{dk['dart_name']}' 상호 '{dk['legal_nm']}' 종목 {dk['stock']} {dk['market']} induty {dk['induty']} 직원 {dk['emp']}\t재무 {' '.join(dk['fin'])}\t직원축 {' '.join(dk['emp_axis'])}\t"
              f"csv corp 충돌 {have_codes.get(dk['corp_code'], 0)} · 이름 충돌 {m['nm'] in have_names} · 정식명=표시명 {dk['dart_name'] == m['nm']}\t{m['url']}")
    print(f"  이번 corp_code 중복 {len(codes_here) - len(set(codes_here))} · 기존 csv 와 겹침 "
          f"{sum(1 for x in codes_here if x in have_codes)} · csv 최대 comp_id {max(int(r['comp_id']) for r in cmap if r['comp_id'])} · csv 행 {len(cmap)} · "
          f"매핑(UNMAPPED 아님) {sum(1 for r in cmap if r['status'] != 'UNMAPPED')} · 법인 {len({r['corp_code'] for r in cmap if r['status'] != 'UNMAPPED'})}")
    new_inds = sorted(m for m in {expected_meta(e, collect)['ind'] for e in collect} if m not in inds)
    print(f"  INDUSTRY_NM 새 값 {new_inds or 0} · 바이트: " +
          ", ".join(f"{i}={i.encode().hex()}" for i in sorted({expected_meta(e, collect)['ind'] for e in collect})))
    print(f"  코퍼스 업종 값 {len(inds)}종 · 관련 값 {sorted(i for i in inds if i and re.search('식품|교육|여행|관광|호텔|카지노|항공|자동차|타이어|유통|반도체|가구|인테리어|건자재|제약|엔터|패션|의류|화장품|미디어|서비스|레저', i))}")
    print(f"  유형 large {sum(1 for c in corpus.values() if c['meta']['tp'] == 'large')} · mid {sum(1 for c in corpus.values() if c['meta']['tp'] == 'mid')} "
          f"→ 이번 large {sum(1 for c in collect.values() if c['meta']['tp'] == 'large')} · mid {sum(1 for c in collect.values() if c['meta']['tp'] == 'mid')}")
    after = inds + collections.Counter(expected_meta(e, collect)["ind"] for e in collect)
    print("  업종 1사 → 짝(이번 웨이브로 2 이상이 되는 값) / 여전히 1사인 이번 값:")
    for i in sorted({expected_meta(e, collect)["ind"] for e in collect}):
        print(f"     {i}: {inds.get(i, 0)} → {after[i]}{'  ◀ 새 짝' if inds.get(i, 0) == 1 and after[i] >= 2 else ''}{'  ◀ 짝 없음(trending 폴백 제외)' if after[i] == 1 else ''}")


_INTERNAL = re.compile(r"코퍼스|선례|어휘표|규칙\s*\d|수집기|수집|검증|감사|병합|미수록|회피|흡수|판독|정본|시드|⚠|구본|승계|앵커|틀 값|"
                       r"항목명 그대로|로 표기|로 기재|영문 표기|카드에는 별도|하나로 기재|전문:|을 합친|를 합친|덧붙|을 빼면|를 빼면|#\d")
_TRAIL = re.compile(r"(에서|까지|부터|으로|에게|을|를|이|가|은|는|에|와|과|도|며|고|서|하여|해|함|함\.|다|다\.)$")


@section("legal")
def sec_legal(collect, final, corpus):
    print("=" * 100)
    print("§legal _legal_scan.py — 수집본 · 모의본 + 편집 낱말 · 끝맺음 · 「 — 」 꼬리")
    for label, d in (("수집본", COLLECT), ("모의본", SIM)):
        paths = [f"{d}/{fn}.sql" for fn in FILES]
        out = subprocess.run([sys.executable, "-I", LEGAL_SCAN, *paths], capture_output=True, text=True).stdout
        tail = [ln for ln in out.splitlines() if ln.strip()][-1:]
        print(f"  [{label}] " + " / ".join(tail))
        if label == "모의본":
            open(W9 + "/audit/tmp/legal_scan_sim.txt", "w", encoding="utf-8").write(out)
    print("\n  편집 · 내부 낱말(계약 3-11 목록 — 이름 · NOTE · 서술, 최종본)")
    n = 0
    for e in collect:
        for r in final[e]:
            for fld in ("nm", "note", "qd"):
                v = r[fld] or ""
                for m in _INTERNAL.finditer(v):
                    n += 1
                    s = max(0, m.start() - 30)
                    print(f"   {collect[e]['file']}\tSORT {r['sort']}\t{r['cd']}\t{fld}\t「{m.group(0)}」\t…{v[s:m.end() + 30]}…")
    print(f"  편집 낱말 검출 {n}")
    print("\n  「연차」 · 「반차」 · 「반반차」(최종본)")
    for e in collect:
        for r in final[e]:
            for fld in ("nm", "note", "qd"):
                v = r[fld] or ""
                for m in re.finditer(r"반반차|반차|연차", v):
                    print(f"   {collect[e]['file']}\tSORT {r['sort']}\t{r['cd']}\t{fld}\t…{v[max(0, m.start() - 20):m.end() + 20]}…")
    print("\n  「 — 」 꼬리 수 · 끝맺음 · 출처 괄호 메모 낱말(최종본)")
    bad = 0
    for e in collect:
        for r in final[e]:
            v = (r["qd"] or r["note"] or "")
            k = len(re.findall(r" — ", v))
            if k != 1:
                print(f"   (꼬리 {k}) {collect[e]['file']}\tSORT {r['sort']}\t{r['cd']}\t…{v[-80:]}")
            body = v.split(" — ")[0]
            body = re.sub(r"\s*\([^()]*\)\s*$", "", body).strip()
            body = re.sub(r"\s*\([^()]*\)\s*$", "", body).strip()
            last = re.split(r"[\s,]", body)[-1] if body else ""
            if _TRAIL.search(last):
                bad += 1
                print(f"   (끝맺음) {collect[e]['file']}\tSORT {r['sort']}\t{r['cd']}\t끝 「{last}」")
            tailtxt = v.split(" — ", 1)[1] if " — " in v else ""
            if tailtxt and not re.search(r"미기재|추정|환산", tailtxt):
                print(f"   (참고) {collect[e]['file']}\tSORT {r['sort']}\t꼬리에 「미기재」 없음: {tailtxt[:60]}")
    print(f"  끝맺음 의심 {bad}")
    # 화면 문장 생성기(generator/format.py benefit_desc — 실제 import · 호출처는 NOTE · 서술 둘뿐: pages/company.py ·
    # pages/benefit.py · pages/guide_legal.py)가 바꾸는 칸: 서술어로 끝나는 칸만 완결문장이 된다
    from generator.format import benefit_desc
    ch = 0
    for e in collect:
        for r in final[e]:
            for fld in ("note", "qd"):
                v = r[fld]
                if not v:
                    continue
                src = derive_amt_source(r["amt"], r["qual"], r["note"]) if r["amt"] is not None else "none"
                out = benefit_desc(v, src)
                if out != v and out.replace("(추정)", "").strip() != v.replace("(추정)", "").strip():
                    ch += 1
                    print(f"   (문장 생성) {collect[e]['file']}\tSORT {r['sort']}\t{r['cd']}\t{fld}\t…{v[-50:]} ⇒ …{out[-60:]}")
    print(f"  benefit_desc 로 문장이 바뀌는 칸 {ch}")


def _merged_cfgs(overrides=None):
    cfgs = br.load_pages()
    merged = copy.deepcopy(cfgs)
    for code, ov in ((OVERRIDES + AUDIT_OVERRIDES) if overrides is None else overrides):
        merged[code].setdefault("overrides", []).append(ov)
    return cfgs, merged


@section("pages")
def sec_pages(collect, final, corpus):
    print("=" * 100)
    print("§pages 항목 페이지 — 모의 최종 문안 해시로 예외 대조 · validate_all · 분류")
    cfgs, merged = _merged_cfgs()
    errs = br.validate_all(merged)
    print(f"  validate_all(현행 + 예외 {len(OVERRIDES) + len(AUDIT_OVERRIDES)}건) 오류 {len(errs)} {errs[:5]}")
    per_code = collections.Counter(code for code, _ in OVERRIDES + AUDIT_OVERRIDES)
    print(f"  예외 파일별 개수 {dict(sorted(per_code.items()))}")
    for code, ov in OVERRIDES + AUDIT_OVERRIDES:
        r = next((x for x in final[ov["comp"]] if x["cd"] == code), None)
        h = br.text_hash(r["qd"], r["note"]) if r else None
        print(f"  {'OK ' if h == ov['h'] else '⚠  '}{code}\t{ov['comp']}\tSORT {r and r['sort']}\t기대 h {ov['h']}\t최종 문안 h {h}")
        old = [o for o in cfgs[code].get("overrides", []) if o.get("comp") == ov["comp"]]
        if old:
            print(f"     ⚠ 현행 설정에 같은 회사 예외 {old}")
    print("\n  최종 문안 분류(예외 적용 후 · 설정 있는 코드) — 예외 전후가 다른 행 표시")
    stale_all = []
    for e in collect:
        for r in final[e]:
            if r["cd"] not in merged:
                continue
            item = [{"comp": e, "desc": r["qd"], "note": r["note"], "unverified": False}]
            res = br.classify(merged[r["cd"]], item)
            res0 = br.classify(cfgs[r["cd"]], item)
            row = res["rows"][0] if res["rows"] else None
            row0 = res0["rows"][0] if res0["rows"] else None
            stale_all += [s for s in res["stale"] if e in str(s)]
            chg = "" if (row and row0 and row["mode"] == row0["mode"] and row["facets"] == row0["facets"]) else \
                f"  (예외 전 mode {row0 and row0['mode']} facets {sorted(row0['facets']) if row0 else None})"
            print(f"   {collect[e]['file']}\tSORT {r['sort']}\t{r['cd']}\th {br.text_hash(r['qd'], r['note'])}\t"
                  f"mode {row and row['mode']}\tfacets {sorted(row['facets']) if row else None}{chg}")
    print(f"  stale(이 18사) {stale_all or 0}")
    from generator.pages.benefit import MIN_COMPANIES
    marks = json.load(open(WT + "/generator/data/row_marks.json", encoding="utf-8"))["rows"]
    marked = {(m["comp_eng_nm"], m["benefit_cd"]) for m in marks}
    print(f"\n  row_marks.json 에 이번 18사 eng 등록 {sorted({m['comp_eng_nm'] for m in marks if m['comp_eng_nm'] in collect}) or 0}")
    print(f"\n  MIN_COMPANIES = {MIN_COMPANIES} — 설정 있는 코드 {len(cfgs)}개 회사 수(표시 행 · exclude 제외) 전 → 후")
    for code in sorted(cfgs):
        excl = {o["comp"] for o in cfgs[code].get("overrides", []) if o.get("exclude")}
        before = {e for e, c in corpus.items() if any(r["cd"] == code for r in c["rows"])
                  and (e, code) not in marked and e not in excl}
        after = before | {e for e in collect if any(r["cd"] == code for r in final[e])}
        cross = " ◀ 문턱을 넘는다" if len(before) < MIN_COMPANIES <= len(after) else ""
        if len(after) != len(before) or len(before) < MIN_COMPANIES + 5:
            print(f"   {code}: {len(before)} → {len(after)}{cross}")
    allcodes = {r["cd"] for c in corpus.values() for r in c["rows"]} | {r["cd"] for e in collect for r in final[e]}
    for code in sorted(allcodes - set(cfgs)):
        b = {e for e, c in corpus.items() if any(r["cd"] == code for r in c["rows"])}
        a = b | {e for e in collect if any(r["cd"] == code for r in final[e])}
        if len(a) >= MIN_COMPANIES or len(b) < MIN_COMPANIES <= len(a):
            print(f"   (설정 없음) {code}: {len(b)} → {len(a)}{' ◀ 20 을 넘지만 설정 파일이 없어 페이지 없음' if len(b) < MIN_COMPANIES else ''}")
    from generator.pages import find as fp
    print("\n  /find 대표 이름(base_label) 전 → 후 — 이번 웨이브가 쓰는 코드 중 LABEL_OVERRIDE 없는 것")
    for code in sorted({r["cd"] for e in collect for r in final[e]}):
        if code in fp.LABEL_OVERRIDE:
            continue
        cb = collections.Counter(r["nm"] for e, c in corpus.items() for r in c["rows"]
                                 if r["cd"] == code and (e, code) not in marked)
        ca = cb + collections.Counter(r["nm"] for e in collect for r in final[e] if r["cd"] == code)
        b, a = fp._most_common(cb), fp._most_common(ca)
        tag = "  ◀ 바뀜" if b != a else ""
        top = ca.most_common(3)
        tie = "  (최다 동률)" if len(top) > 1 and top[0][1] == top[1][1] else ""
        if b != a or sum(cb.values()) <= 4 or tie:
            print(f"   {code}: 「{b}」 → 「{a}」 (코퍼스 {sum(cb.values())}행 + 이번 {sum(ca.values()) - sum(cb.values())}행 · 이름 분포 {dict(ca.most_common(4))}){tag}{tie}")
    print(f"  LABEL_OVERRIDE 코드 {sorted(fp.LABEL_OVERRIDE)}")
    # 동률 표본(test_find_page.py · find.test.js 같은 쌍) — 합본 이름 빈도로 다시 잰다(픽스처는 리허설 DB 로 등록 단계가 다시 뽑는다)
    src = open(WT + "/generator/tests/test_find_page.py", encoding="utf-8").read()
    blk = src[src.index("def test_short_generic_name_wins_over_one_company_wording"):]
    blk = blk[blk.index("for code, expect in"):blk.index("names = cases")]
    pairs = re.findall(r'\("([a-z_]+)", "([^"]+)"\)', blk)
    jsrc = open(WT + "/web/assets/js/find.test.js", encoding="utf-8").read()
    jpairs = re.findall(r"\['([a-z_]+)', '([^']+)'\]", jsrc[jsrc.index("for (const [code, expect] of"):][:600])
    print(f"\n  동률 표본 파이썬 {pairs} · JS 같음 {pairs == jpairs}")
    after_names = collections.defaultdict(collections.Counter)
    before_names = collections.defaultdict(collections.Counter)
    for e, c in corpus.items():
        for r in c["rows"]:
            if (e, r["cd"]) not in marked:
                after_names[r["cd"]][r["nm"]] += 1
                before_names[r["cd"]][r["nm"]] += 1
    for e in collect:
        for r in final[e]:
            after_names[r["cd"]][r["nm"]] += 1
    for code, expect in pairs:
        cnt = after_names[code]
        top = max(cnt.values())
        tie = len([n for n, k in cnt.items() if k == top]) > 1
        got = fp._most_common(cnt)
        ok = tie and got == expect and expect in cnt and any(len(n) > len(expect) for n in cnt)
        print(f"   {'OK ' if ok else '⚠  '}{code}: 기대 「{expect}」 · 합본 대표 「{got}」 · 동률 {tie} · 이름 {dict(cnt.most_common(6))}")
    print("  지금(합본) 동률인 코드 — 교체 후보(대표 이름 · 최다 빈도 · 이름 수 · 이번 웨이브가 건드림):")
    wave_codes = {r["cd"] for e in collect for r in final[e]}
    for code in sorted(after_names):
        cnt = after_names[code]
        top = max(cnt.values())
        tied = [n for n, k in cnt.items() if k == top]
        if len(tied) > 1 and code not in dict(pairs):
            got = fp._most_common(cnt)
            longer = any(len(n) > len(got) for n in cnt)
            print(f"     {code}: 「{got}」 · 최다 {top} · 동률 이름 {len(tied)} · 이름 {len(cnt)} · 더 긴 후보 {longer} · 웨이브12 {'○' if code in wave_codes else '×'}"
                  f" · 웨이브 전 대표 「{fp._most_common(before_names[code])}」 · override {code in fp.LABEL_OVERRIDE}")


@section("chips")
def sec_chips(collect, final, corpus):
    print("=" * 100)
    print("§chips derive_work_style(모의본 텍스트) — remote · flex · refreshLeave · unlimitedPTO · cond")
    for e, c in collect.items():
        t = open(f"{SIM}/{c['file']}.sql", encoding="utf-8").read()
        ws = derive_work_style(t)
        rows = [(r["sort"], r["cd"], r["nm"], ws_conditions(r["nm"])) for r in final[e] if r["cd"] in _WS_CODE_KEY]
        ws0 = derive_work_style(c["text"])
        diff = "" if ws0 == ws else f"  (수집본 {ws0})"
        print(f"  {c['file']}\tremote={ws['remote']}\tflex={ws['flex']}\trefreshLeave={'켜짐' if ws['refreshLeave'] else '꺼짐'}"
              f"\tunlimitedPTO={ws['unlimitedPTO']}\tcond={ws.get('cond', {})}\t행 {rows}{diff}")


@section("final")
def sec_final(collect, final, corpus):
    print("=" * 100)
    print("§final 회사별 최종 행 수")
    tot_c = tot_f = 0
    for fn in FILES:
        eng = next(e for e, c in collect.items() if c["file"] == fn)
        nc, nf = len(collect[eng]["rows"]), len(final[eng])
        amt = [r for r in final[eng] if r["amt"] is not None]
        st = sum(1 for r in amt if derive_amt_source(r["amt"], r["qual"], r["note"]) == "stated")
        kinds = collections.Counter(a[0] for a in all_actions(eng))
        n_del = kinds.get("delete", 0)
        n_add = kinds.get("add", 0)
        print(f"  {fn}\t{nc} → {nf}\t(삭제 {n_del} · 추가 {n_add})\t조치 {len(all_actions(eng))} {dict(kinds)}\t금액 행 {len(amt)}(stated {st} · 추정 {len(amt) - st}) 합 {sum(r['amt'] for r in amt)}")
        tot_c += nc
        tot_f += nf
    nco = len(corpus)
    nro = sum(len(c["rows"]) for c in corpus.values())
    print(f"  합계 {tot_c} → {tot_f} · SD-3 {nco} + {len(FILES)} = {nco + len(FILES)} · SD-4 {nro} + {tot_f} = {nro + tot_f}")


@section("actions")
def sec_actions_md(collect, final, corpus):
    """§5 본문 — 조치 모델에서 글자 그대로 찍는다(보고서와 check-seed 가 같은 문자열을 본다)."""
    fk = {"cd": "BENEFIT_CD", "nm": "BENEFIT_NM", "amt": "BENEFIT_AMT", "ctgr": "BENEFIT_CTGR_CD", "note": "NOTE_CTNT",
          "qual": "QUAL_YN", "qd": "QUAL_DESC_CTNT", "sort": "SORT_ORDER_NO"}

    def _val(v):
        if v is None:
            return "NULL"
        if isinstance(v, bool):
            return "TRUE" if v else "FALSE"
        if isinstance(v, int):
            return str(v)
        return sv(v)
    for i, fn in enumerate(FILES, 1):
        eng = next(e for e, c in collect.items() if c["file"] == fn)
        c = collect[eng]
        acts = all_actions(eng)
        why = WHY.get(eng, [])
        print(f"\n### 5-{i}. {fn} (`{eng}`) — 수집 {len(c['rows'])} → 최종 {len(final[eng])}\n")
        by_sort = {r["sort"]: r for r in c["rows"]}
        if eng in URL_CHANGE:
            o, n = URL_CHANGE[eng]
            print(f"- **정본 URL 교체**(머리말 `-- URL:` · INSERT `CAREERS_BENEFIT_URL` · UPDATE 세 곳 같은 글자): `{o}` → `{n}`\n")
        if eng in META_CHANGE:
            o, n, _ = META_CHANGE[eng]
            print(f"- **등록 값 교체**(1번 문장 `INSERT IGNORE INTO TCOMPANY` 의 `INDUSTRY_NM` 한 곳 — 리드 판정 (136) ②): `{o}` → `{n}`(머리말 참고 블록 · 다른 문장은 그대로)\n")
        if acts:
            assert len(why) == len(acts), (eng, len(why), len(acts))
            print("| # | 대상(SORT · 코드) | 조치 | 근거 |")
            print("|---:|---|---|---|")
            for n, (a, w) in enumerate(zip(acts, why), 1):
                if a[0] == "set":
                    if "cd" in a[2]:
                        kind = "**재코딩(같은 SORT)**" + (" · 문안 교체" if ("qd" in a[2] or "note" in a[2]) else "")
                    elif "amt" in a[2]:
                        kind = "**금액 행으로**(AMT · QUAL_YN · 서술 → NOTE)"
                    else:
                        kind = "이름 · 문안 교체" if "nm" in a[2] and ("qd" in a[2] or "note" in a[2]) else ("이름 교체" if "nm" in a[2] else "문안 교체")
                    cur = by_sort[a[1]]['cd'] if a[1] in by_sort else next(x[1]['cd'] for x in all_actions(eng) if x[0] == 'add' and x[1]['sort'] == a[1])
                    print(f"| {n} | {a[1]} `{cur}` | {kind} | {w} |")
                elif a[0] == "replace":
                    print(f"| {n} | {a[1]} `{by_sort[a[1]]['cd']}` | 구절 교체({fk[a[2]]}) | {w} |")
                elif a[0] == "delete":
                    print(f"| {n} | {a[1]} `{by_sort[a[1]]['cd']}` | **삭제** | {w} |")
                elif a[0] == "move":
                    print(f"| {n} | {a[1]} `{by_sort[a[1]]['cd']}` → {a[2]['sort']} `{a[2]['cd']}` | **재코딩 · 섹션 이동** | {w} |")
                elif a[0] == "add":
                    print(f"| {n} | {a[1]['sort']} `{a[1]['cd']}` | **추가** | {w} |")
            print("\n집행(글자 그대로 — 백틱 안이 SQL 값이다):\n")
            for n, a in enumerate(acts, 1):
                if a[0] == "set":
                    cur = by_sort[a[1]]['cd'] if a[1] in by_sort else next(x[1]['cd'] for x in all_actions(eng) if x[0] == 'add' and x[1]['sort'] == a[1])
                    extra = " (위에서 추가한 행)" if a[1] not in by_sort else ""
                    print(f"- **#{n} SORT {a[1]} `{cur}`**{extra} — 적힌 필드만 바꾼다(나머지 필드 · 카테고리 · SORT 그대로)")
                    for k, v in a[2].items():
                        print(f"  - `{fk[k]}` = `{_val(v)}`")
                elif a[0] == "replace":
                    print(f"- **#{n} SORT {a[1]} `{by_sort[a[1]]['cd']}`** — `{fk[a[2]]}` 안의 구절 하나만 바꾼다(나머지 글자 그대로)")
                    print(f"  - 옛 구절: `{a[3]}`")
                    print(f"  - 새 구절: `{a[4]}`")
                elif a[0] == "delete":
                    last = a[1] == max(by_sort)
                    if last:
                        print(f"- **#{n} SORT {a[1]} `{by_sort[a[1]]['cd']}`** — VALUES 의 마지막 튜플이다: 튜플 두 줄을 지우고 바로 앞 튜플(SORT {max(s for s in by_sort if s < a[1])}) 끝의 `,` 도 지운다(그 튜플이 마지막이 되어 `)` 다음 줄이 `ON DUPLICATE KEY UPDATE`) · 빈 줄 남기지 않음")
                    else:
                        print(f"- **#{n} SORT {a[1]} `{by_sort[a[1]]['cd']}`** — 튜플을 통째로 지운다(뒤 쉼표 정리 · 빈 줄 남기지 않음 · 섹션 머리 주석은 남은 행 위에 그대로)")
                elif a[0] in ("move", "add"):
                    nr = a[2] if a[0] == "move" else a[1]
                    head = a[3] if a[0] == "move" else a[2]
                    rest = [r["sort"] for r in final[eng] if r["sort"] < nr["sort"]]
                    prev = max(rest)
                    if a[0] == "move":
                        print(f"- **#{n} SORT {a[1]} 이동** — {by_sort[a[1]]['ctgr']} 구역의 SORT {a[1]} 튜플을 지우고(뒤 쉼표 정리 · 빈 줄 남기지 않음), "
                              f"새 튜플을 {nr['ctgr']} 자리에 넣는다:")
                    is_last = nr["sort"] == max(r["sort"] for r in final[eng])
                    where = (f"VALUES 의 마지막 행이 된다: SORT {prev} 행 끝 `)` 뒤에 `,` 를 붙이고, 그 아래(`ON DUPLICATE KEY UPDATE` 바로 앞)에"
                             + (" 섹션 머리 주석 한 줄 · 이어서" if head else "") + " 쉼표 없이:") if is_last else \
                        (f"{nr['ctgr']} 구역, SORT {prev} 행 바로 뒤" + (" — 섹션 머리 주석 한 줄 · 이어서" if head else "") + "(이 튜플 끝에 쉼표):")
                    if a[0] == "add":
                        print(f"- **#{n} 추가 SORT {nr['sort']}** — {where}")
                    else:
                        print(f"  위치: {where}")
                    print("```sql\n" + ((head + "\n") if head else "") + render_tuple(nr) + ("" if is_last else ",") + "\n```")
        else:
            print("행 조치 없음(행 그대로).")
        for old_line, new_line in SECTION_EDIT.get(eng, []):
            print("\n섹션 머리 주석 한 줄 교체(주석 줄만 · 따옴표 없음 · 아래 옛 줄 전체를 새 줄로):\n```\n" + old_line + "\n```\n→\n```\n" + new_line + "\n```")
        print(f"\n헤더 한 줄(「참고」 블록 끝 · 닫는 ━━━ 줄 바로 위):\n```\n{HEADER_LINE[eng]}\n```")
        keeps = KEEP.get(eng, [])
        if keeps:
            print("\n바꾸지 않는 것(검증 권고 · 판단 요청 가운데 집행하지 않는 것):\n")
            print("| SORT | 코드 | 처리 | 이유 |")
            print("|---|---|---|---|")
            for s, cd, v, w in keeps:
                print(f"| {s} | `{cd}` | {v} | {w} |")


@section("combined")
def sec_combined(collect, final, corpus):
    """코퍼스 257 + 모의본 18 을 한 폴더(W9/audit/tmp/combined)에 모아 리포 함수로 다시 본다 —
    어휘표 재생성(_vocab_scan) · build_company_meta(SI-13c 조건 칩 · SI-13d 이름 꼴) · 회사 수."""
    import shutil
    print("=" * 100)
    print("§combined 코퍼스 257 + 모의본 18 — 어휘표 · company_meta 재현")
    d = W9 + "/audit/tmp/combined"
    shutil.rmtree(d, ignore_errors=True)
    os.makedirs(d)
    for f in glob.glob(CORPUS + "/*.sql"):
        shutil.copy(f, d)
    for fn in FILES:
        assert not os.path.exists(f"{d}/{fn}.sql"), fn
        shutil.copy(f"{SIM}/{fn}.sql", d)
    vs = _mod("vocab_scan", "/home/ubuntu/loupit-evidence/2026-10-14-wave6/_vocab_scan.py")
    vs.SEED = d
    rows, missed = vs.scan()
    by = collections.defaultdict(lambda: {"comps": set(), "names": collections.Counter(), "ctgr": collections.Counter()})
    for comp, code, name, amt, ctgr in rows:
        x = by[code]
        x["comps"].add(comp)
        x["names"][name] += 1
        x["ctgr"][ctgr] += 1
    split = {c: dict(x["ctgr"]) for c, x in by.items() if len(x["ctgr"]) > 1}
    print(f"  _vocab_scan: 회사 {len({r[0] for r in rows})} · 복지 {len(rows)}행 · 코드 {len(by)}종 · 놓친 줄 {len(missed)} · 카테고리 분열 {split or 0}")
    voc = vocab_table()
    print(f"  어휘표 n 이 바뀌는 코드 {sum(1 for c, x in by.items() if c in voc and len(x['comps']) != voc[c][0])}종 · 어휘표 밖 {sorted(c for c in by if c not in voc) or 0}")
    from db.seed import company_meta as cm
    old = cm.BENEFIT_SQL_DIR
    from pathlib import Path
    cm.BENEFIT_SQL_DIR = Path(d)
    try:
        meta = cm.build_company_meta()
        ws = {eng: v["work_style"] for eng, v in meta.items()}
        got = {eng: v["cond"] for eng, v in ws.items() if "cond" in v}
        print(f"  build_company_meta 회사 {len(meta)} · cond 회사 {len(got)}")
        for e in collect:
            if e in got:
                print(f"   SI-13c 추가 줄 후보: \"{e}\": {got[e]}")
        bad_inv = [(e, k) for e, v in ws.items() for k in v.get("cond", {}) if v.get(k)]
        print(f"  불변식 k ∈ cond ⇒ !ws[k] 위반 {bad_inv or 0}")
        looks = re.compile(r"육아|자녀|부문|필요\s*시")
        bad = []
        for f in sorted(Path(d).glob("*.sql")):
            text = f.read_text(encoding="utf-8")
            m = re.search(r"COMP_ENG_NM\s*=\s*'([A-Za-z0-9_]+)'", text)
            eng = m.group(1) if m else f.stem
            for chunk in cm._row_chunks(text):
                code, _q, _dd, _c, name = cm._row_info(chunk)
                if code in cm._WS_CODE_KEY and name and looks.search(name) and not cm.ws_conditions(name) and \
                        (eng, name) != ("hanwha", "정기휴가 (글로벌부문)·Refresh 휴가"):
                    bad.append((eng, code, name))
        print(f"  SI-13d(합본) 위반 {bad or 0}")
        aliases = {e: meta[e].get("aliases") for e in collect}
        # §8-2 WAVE10_ALIASES 초안 대조 — 다른 회사 표시명 · 별칭과 정확히 같은 것 0 이어야 한다 · 부분 일치는 참고
        owner = collections.defaultdict(set)
        for e2, v in meta.items():
            for al in v.get("aliases", []) + [v.get("comp_nm") or ""]:
                if al:
                    owner[al.lower()].add(e2)
        for e, extra in WAVE10_ALIASES.items():
            for al in extra:
                hit = owner.get(al.lower(), set()) - {e}
                part = sorted({e2 for e2, v in meta.items() if e2 != e and any(
                    (al in x or x in al) and len(x) >= 2 for x in v.get("aliases", []))})
                print(f"   별칭 {e} 「{al}」 정확 충돌 {sorted(hit) or 0} · 부분 일치 {part[:6] or 0}")
        print(f"  이번 18사 aliases(지금 코드 — WAVE12 별칭 넣기 전) {aliases}")
        print(f"  이번 18사 work_style {{eng: ws}}:")
        for e in collect:
            print(f"     {e}: {ws[e]}")
    finally:
        cm.BENEFIT_SQL_DIR = old


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

