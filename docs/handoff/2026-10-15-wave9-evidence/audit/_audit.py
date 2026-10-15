#!/usr/bin/env python3
"""웨이브 9 코퍼스 횡단 감사 — 재현 스크립트 (2026-10-15).

출발점: /home/ubuntu/loupit-evidence/2026-10-15-wave8/audit/_audit.py (웨이브 8 감사 — 조치 모델 · simulate · check-seed)
바꾼 것: 경로(W9 · 코퍼스 = 웨이브 8 worktree 시드 218파일 · 리포 모듈도 그 worktree 에서 import) · 대상 22파일 ·
        조치 문자열은 _extract.json(검증 보고서 절 7 백틱 · 절 4 완성 튜플 · JSON 기계 추출)에서 읽는다 ·
        등록 값 교체(META_CHANGE — 호텔신라 업종) · 새 섹션 머리 주석(호텔신라 compensation · 롯데에너지머티리얼즈 time_off) ·
        형제 · 경계 축 · 업종 정규식을 웨이브 9 에 맞춤. 어휘표(wave-lite 91종) · 행 점검기(wave-lite/_row_check.py)는 그대로.

리포 모듈을 **실제로 import** 해서 돌린다(추측 금지 — 리포는 읽기만 · 바이트코드도 쓰지 않는다):
  db.seed.load._split_sql_statements            분할기(5문장 · 셋째 = UPDATE TCOMPANY SET CAREERS_BENEFIT_URL)
  db.seed.company_meta.parse_header_insert       등록 문장 파서 · ws_conditions · derive_work_style(근무형태 칩)
  generator.slug.slug_of                         slug
  db.seed.backfill_dec2._DATE_RE · _URL_RE · derive_amt_source   확인일 · 출처 URL · 금액 출처
  generator.benefit_rules load_pages · classify · text_hash · validate_all   항목 페이지(웨이브 8 예외까지 든 worktree 설정)
  generator.pages.find _most_common · LABEL_OVERRIDE                           /find 대표 이름
  wave-lite/_row_check.py check()                SI-9 · SI-11 · SI-12 · SI-13d · SI-B2 사전 점검(게이트와 같은 함수)
  /home/ubuntu/loupit-evidence/2026-10-02-recollect-3-7/_len_check.py  필드 길이 · 행 파서(parse_values)

사용:
  python3 -I _audit.py [섹션 ...]          섹션 없으면 all(actions 제외)
    fmt codes consist amt reg legal pages chips final combined actions simulate
  python3 -I _audit.py check-seed <폴더>   그 폴더의 22파일을 최종본 모델과 행 단위 · 전 필드 대조 → 「형식 문제 n · 불일치 n」
  python3 -I _audit.py search <정규식>     코퍼스 218파일 행(이름 · NOTE · 서술)에서 정규식 검색(주석 제외)
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

WT = "/home/ubuntu/loupit/.claude/worktrees/wave8"   # 웨이브 8 worktree(fb08b03 · 읽기만) — 웨이브 9 는 이 위에 쌓는다
W9 = "/home/ubuntu/loupit-evidence/2026-10-15-wave9"
LITE = "/home/ubuntu/loupit-evidence/wave-lite"
COLLECT = W9 + "/collect"
SIM = W9 + "/audit/sim"
CORPUS = WT + "/db/seed/benefit/sql"                  # 리드 칸: 이것 하나만 센다(218파일)
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

# 리드 칸 대상 22파일(리드 칸 순서 — 1차 10 · 2차 12)
FILES = ["롯데쇼핑", "호텔신라", "HS효성첨단소재", "태광산업", "팬오션", "영원무역", "대한조선", "영풍", "IPARK현대산업개발",
         "DN오토모티브", "대신증권", "SK네트웍스", "롯데에너지머티리얼즈", "와이지엔터테인먼트", "넥슨게임즈", "차바이오텍",
         "삼표시멘트", "로보스타", "LS마린솔루션", "SNT에너지", "SNT다이내믹스", "롯데관광개발"]
MAXLEN = {"nm": 100, "note": 200, "qd": 500}  # db/schema.sql — BENEFIT_NM · NOTE_CTNT · QUAL_DESC_CTNT
META_MAX = {"eng": 30, "nm": 100, "ind": 50, "logo": 10, "url": 500}  # db/schema.sql TCOMPANY
CTGR = {"compensation", "health", "family", "leisure", "perks", "growth", "time_off", "flexibility", "work_env"}
HDR_INSERT = rc.HDR_INSERT
UPD = rc.UPD
TUPLE = re.compile(  # 원문 텍스트 안 튜플 위치(모의본 쓰기용) — 행 파서는 lc.parse_values 가 정본
    r"\(\s*@comp_id\s*,\s*'((?:[^']|'')*)'\s*,\s*'((?:[^']|'')*)'\s*,\s*(NULL|-?[\d.]+)\s*,\s*'([a-z_]+)'\s*,"
    r"\s*'([a-z_]+)'\s*,\s*(NULL|'(?:[^']|'')*')\s*,\s*(TRUE|FALSE)\s*,\s*(NULL|'(?:[^']|'')*')\s*,\s*(\d+)\s*\)",
    re.S)
ROSTER_NM = {  # eng(slug) → W9/dart/check-2026-10-15.json 의 키(리드 명단 이름 = 표시명 22/22)
    "lotte_shopping": "롯데쇼핑", "hotel_shilla": "호텔신라", "hs_hyosung_advanced": "HS효성첨단소재", "taekwang_ind": "태광산업",
    "pan_ocean": "팬오션", "youngone": "영원무역", "daehan_shipbuilding": "대한조선", "youngpoong": "영풍",
    "ipark_hdc": "IPARK현대산업개발", "dn_automotive": "DN오토모티브", "daishin_securities": "대신증권",
    "sk_networks": "SK네트웍스", "lotte_energy_materials": "롯데에너지머티리얼즈", "yg_entertainment": "와이지엔터테인먼트",
    "nexon_games": "넥슨게임즈", "cha_biotech": "차바이오텍", "sampyo_cement": "삼표시멘트", "robostar": "로보스타",
    "ls_marine_solution": "LS마린솔루션", "snt_energy": "SNT에너지", "snt_dynamics": "SNT다이내믹스", "lotte_tour": "롯데관광개발"}
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
DATE = "2026-10-15"
_LS = "롯데쇼핑"
ACTIONS: dict[str, list] = {
    "lotte_shopping": [
        ("delete", 64),
        ("set", 62, dict(nm=X(_LS, 3), qd=X(_LS, 2))),
        ("set", 63, dict(nm=X(_LS, 6), qd=X(_LS, 5))),
        ("set", 71, dict(qd=X(_LS, 8))),
        ("set", 32, dict(nm=X(_LS, 12), qd=X(_LS, 11))),
        ("set", 10, dict(nm=X(_LS, 15))),
        ("set", 12, dict(nm=X(_LS, 17))),
        ("set", 15, dict(nm=X(_LS, 19))),
        ("set", 18, dict(nm=X(_LS, 21))),
        ("set", 30, dict(nm=X(_LS, 23))),
        ("set", 31, dict(nm=X(_LS, 25))),
        ("set", 50, dict(nm=X(_LS, 27))),
        ("set", 61, dict(nm=X(_LS, 29))),
        ("set", 70, dict(nm=X(_LS, 31))),
        ("set", 72, dict(nm=X(_LS, 33))),
        ("set", 73, dict(nm=X(_LS, 35))),
        ("set", 74, dict(nm=X(_LS, 37))),
    ],
    "hotel_shilla": [
        ("add", T("호텔신라", 2), None),
        ("add", T("호텔신라", 0), SEC(X("호텔신라", 3))),
        ("add", T("호텔신라", 1), None),
        ("set", 41, dict(qd=X("호텔신라", 6))),
        ("set", 42, dict(qd=X("호텔신라", 8))),
        ("set", 40, dict(nm=X("호텔신라", 10), qd=X("호텔신라", 11))),
    ],
    "hs_hyosung_advanced": [
        ("set", 40, dict(qd=X("HS효성첨단소재", 2))),
        ("add", T("HS효성첨단소재", 4), None),
        ("set", 50, dict(nm=X("HS효성첨단소재", 6), qd=X("HS효성첨단소재", 7))),
        ("add", T("HS효성첨단소재", 8), None),
        ("add", T("HS효성첨단소재", 0), None),
    ],
    "taekwang_ind": [],
    "pan_ocean": [
        ("set", 21, dict(nm=X("팬오션", 2))),
        ("set", 33, dict(nm=X("팬오션", 4))),
        ("add", T("팬오션", 5), None),
    ],
    "youngone": [],
    "daehan_shipbuilding": [
        ("set", 80, dict(nm=X("대한조선", 1), qd=X("대한조선", 3))),
    ],
    "youngpoong": [],
    "ipark_hdc": [
        ("set", 10, dict(nm=X("IPARK현대산업개발", 1))),
    ],
    "dn_automotive": [],
    "daishin_securities": [
        ("set", 31, dict(cd=T("대신증권", 5)["cd"], nm=T("대신증권", 5)["nm"], qd=T("대신증권", 5)["qd"])),
        ("set", 80, dict(nm=X("대신증권", 7), qd=X("대신증권", 8))),
        ("add", T("대신증권", 9), None),
        ("add", T("대신증권", 10), None),
    ],
    "sk_networks": [
        ("set", 60, dict(qd=X("SK네트웍스", 2))),
    ],
    "lotte_energy_materials": [
        ("set", 21, dict(nm=X("롯데에너지머티리얼즈", 2))),
        ("add", T("롯데에너지머티리얼즈", 3), SEC("-- ── 휴가 (time_off) — 2025 지속가능경영보고서 13쪽 ──")),
    ],
    "yg_entertainment": [
        ("set", 22, dict(qd=X("와이지엔터테인먼트", 1))),
        ("set", 81, dict(qd=X("와이지엔터테인먼트", 3))),
    ],
    "nexon_games": [
        ("set", 31, dict(nm=X("넥슨게임즈", 1))),
        ("set", 93, dict(qd=X("넥슨게임즈", 3))),
    ],
    "cha_biotech": [
        ("set", 31, dict(qd=XQ("차바이오텍", 2))),
        ("set", 61, dict(nm=XQ("차바이오텍", 5), qd=XQ("차바이오텍", 7))),
    ],
    "sampyo_cement": [
        ("set", 53, dict(qd=X("삼표시멘트", 1))),
    ],
    "robostar": [],
    "ls_marine_solution": [],
    "snt_energy": [],
    "snt_dynamics": [],
    "lotte_tour": [
        ("set", 30, dict(nm=XQ("롯데관광개발", 2))),
    ],
}

# 감사가 새로 더한 시드 조치(검증 보고서에 없는 것 — 근거는 보고서 §1 · §2 · §13). 문자열은 이 감사가 정한 글자다.
#   §1-2 신규 코드 financial_planning 흡수 → mental: 코퍼스가 전문가 재무 상담(재무 설계 · 재무코칭 · 재무 및 재테크 관리)을
#   전부 mental(EAP · 상담 서비스) 행에 싣는다(현대백화점 30 · 제일기획 63 · GS리테일 10 · 효성중공업 82) — 계약 3-4
#   「코퍼스에 대응 어휘가 있으면 신규가 아니다」. 회사당 한 코드 한 행이라 SORT 26 에 병합하고 53 을 지운다.
#   병합 구절은 수집본 SORT 53 서술(검증 CONFIRMED 원문 인용)을 기계로 옮긴다 — 꼬리 미기재만 둘을 합친다.
_SKN = parse_file(f"{COLLECT}/SK네트웍스.sql")
_SKN26 = next(r for r in _SKN["rows"] if r["sort"] == 26)
_SKN53 = next(r for r in _SKN["rows"] if r["sort"] == 53)
assert _SKN26["cd"] == "mental" and _SKN53["cd"] == "financial_planning"
assert _SKN26["qd"].count(" — ") == 1 and _SKN53["qd"].count(" — ") == 1
SKN_MENTAL_NM = "사내 상담실·SOKSOK 상담실·재무설계 지원"
SKN_MENTAL_QD = (_SKN26["qd"].split(" — ")[0] + ", " + _SKN53["qd"].split(" — ")[0]
                 + " — 상담 횟수·재무설계 이용 횟수·비용 부담 미기재")
#   §2-7 리드 판정 (137) 잣대를 IPARK현대산업개발에도: 반기보고서 유연근무 표 「원격근무제(재택근무 포함) 사용자 수 0 · 0 · 8」
#   (제9기 반기 · 제8기 · 제7기 — 사업보고서 표는 0 · 8 · 185) = 표의 제도 이름은 그 자체로 행(계약 3-12) · 0 · 「-」는 빼는 근거가
#   아니다((120)) · 대신증권 81(「- · - · 6」 → 추가)과 같은 꼴. 검증 레인 N2 는 (137) 전에 끝나 「웨이브 7 규칙대로 행 없음」으로 남겼다.
#   같은 표의 「유연근무제 활용 여부 일부활용(본사)」 → flex_work 10 과 같은 칩 꼴 「(조건부)」(검증 N2 조치 1 잣대).
IPARK_REMOTE = ("(@comp_id, 'remote_work', '원격근무제(재택근무 포함) (조건부)', NULL, 'flexibility', 'est', NULL, TRUE, "
                "'유연근무제 활용 여부 일부활용(본사) · 원격근무제(재택근무 포함) 사용자 2024년 8명 · 2025년 0명 · 2026년 상반기 0명 "
                "(2026 반기보고서 유연근무제도 사용 현황 표 항목) — 대상 직무·사용 조건 미기재', 11)")
AUDIT_ACTIONS: dict[str, list] = {
    "sk_networks": [("set", 26, dict(nm=SKN_MENTAL_NM, qd=SKN_MENTAL_QD)), ("delete", 53)],
    "ipark_hdc": [("add", TA(IPARK_REMOTE), None)],
}

# 정본 URL 교체(머리말 · INSERT · UPDATE 세 곳) — 이번 웨이브 없음(호텔신라 E50 유지 — 리드 판정 (136) ②)
URL_CHANGE: dict = {}
# 등록 값 교체(INSERT 한 곳의 글자 — 옛 글자, 새 글자, 기대 등록 필드) — 리드 판정 (136) ② 호텔신라 업종 = 기존 값 「유통」
META_CHANGE: dict = {
    "hotel_shilla": ("'호텔/면세', 'H',", "'유통', 'H',", dict(ind="유통")),
}
HEADER_EDIT: dict = {}  # 참고 블록의 옛 문장은 고치지 않는다(계약 B · A 5) — 헤더 한 줄이 뒤집힘을 적는다

# 항목 페이지 동반 조치(리드 집행 — generator/data/benefit_pages/<code>.json overrides)
#   검증 보고서의 JSON 을 기계로 뽑았다. h 는 모의 최종 문안으로 다시 계산해 대조한다(sec_pages).
OVERRIDES: list[tuple[str, dict]] = [
    ("parenting", J(_LS, 13)),
    ("mental", J("호텔신라", 18)),
    ("fitness", J("호텔신라", 19)),
    ("incentive", J("호텔신라", 20)),
    ("clinic", J("팬오션", 6)),
    ("meal", J("팬오션", 7)),
    ("fitness", J("영원무역", 0)),
    ("child_edu", J("영원무역", 1)),
    ("parenting", J("영원무역", 2)),
    ("transport", J("영원무역", 3)),
    ("holiday_gift", J("영풍", 0)),
    ("mental", J("영풍", 1)),
    ("housing_loan", J("IPARK현대산업개발", 2)),
    ("health_check", J("DN오토모티브", 0)),
    ("incentive", J("대신증권", 12)),
    ("flex_work", J("SK네트웍스", 5)),
    ("mental", J("와이지엔터테인먼트", 5)),
    ("incentive", J("와이지엔터테인먼트", 7)),
    ("holiday_gift", J("넥슨게임즈", 5)),
    ("mba", J("차바이오텍", 8)),
    ("holiday_gift", J("삼표시멘트", 4)),
    ("fitness", J("삼표시멘트", 7)),
    ("housing_loan", J("로보스타", 2)),
    ("parenting", J("로보스타", 5)),
    ("meal", J("LS마린솔루션", 2)),
    ("holiday_gift", J("SNT에너지", 7)),
    ("holiday_gift", J("SNT다이내믹스", 2)),
    ("dormitory", J("SNT다이내믹스", 5)),
    ("transport", J("롯데관광개발", 3)),
]
AUDIT_OVERRIDES: list[tuple[str, dict]] = []   # 감사가 더하는 예외(§10 — sec_pages 결과로 채운다)

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
        for old_line, new_line in HEADER_EDIT.get(eng, []):
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
            print(f"  ⚠ {fn}: 등록 eng {eng} 가 대상 22사가 아니다")
            bad += 1
            continue
        probs = fmt_problems(got, expected_meta(eng, collect), HEADER_LINE[eng])
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




_H = "-- 검증 · 감사 판정 반영(2026-10-15): "
HEADER_TEXT: dict[str, str] = {  # 회사별 헤더 한 줄 — 따옴표 없음 · 최종 행 수는 모델에서 센다({N})
    "lotte_shopping": _H + "롯데마트 교육제도 페이지(2022 이전 판)에만 기댄 사외 MBA 행 삭제 · 어학 · 교육 행에서 그 페이지 구절 걷기 · 단체보험 행에서 4대 보험 칸 구절 걷기 · 임신 출산 육아 행 문안 교체와 16쪽 일맘 CLUB 워크숍 병합 · 두 사업부 이상 같은 제도 12행 이름에서 부문 떼기(참고 블록 보조 줄의 롯데마트 교육제도는 이 판정으로 뒤집힘) · 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 {N}행",
    "hotel_shilla": _H + "자기 도메인 인사제도 · 복리후생 · 인재육성 3쪽 반영 — 의료실비 medical · 인센티브제도 incentive · 장기근속 포상 long_service_bonus 추가 · 어학 · 온라인 교육 · 지역전문가 행 병합 · 업종 유통(리드 판정 136) · 참고 블록의 자기 도메인 복리후생 페이지 없음 문장은 이 판정으로 뒤집힘 · 항목 페이지 예외 3(통합 밖 리드 집행) — 최종 {N}행",
    "hs_hyosung_advanced": _H + "제휴 할인 행에서 복지몰을 welfare_point 로 분리 · 하기 휴가 및 휴가비를 summer_leave · summer_vacation_subsidy 두 행으로 분리 · 45쪽 유급 출산 휴가 최대 6개월 parenting 추가(참고 블록 제외 줄의 출산은 이 판정으로 상회분만 뒤집힘) — 최종 {N}행",
    "taekwang_ind": _H + "행 조치 없음 · 경영성과급 행 유지(리드 판정 136) — 최종 {N}행",
    "pan_ocean": _H + "가족 동승 · 방선제도와 문화 오락비 행 이름에 해상 직원 한정 · 재고용 외국인 해상 직원 본인 가족 실손의료보험 medical 추가(통합 보고 각주) · 신규 코드 family_onboard 유지 · 항목 페이지 예외 2(통합 밖 리드 집행) — 최종 {N}행",
    "youngone": _H + "행 조치 없음 · 항목 페이지 예외 4(통합 밖 리드 집행) — 최종 {N}행",
    "daehan_shipbuilding": _H + "패밀리데이 이름 · 서술에 17시 퇴근과 정규 근무시간(리드 판정 135) — 최종 {N}행",
    "youngpoong": _H + "행 조치 없음 · 항목 페이지 예외 2(통합 밖 리드 집행) — 최종 {N}행",
    "ipark_hdc": _H + "유연근무제 이름을 조건부로(공시 일부활용 본사) · 공시 원격근무제 2024년 8명 remote_work 조건부 추가(리드 판정 137 잣대 — 참고 블록 제외 줄의 공시 원격근무는 이 판정으로 뒤집힘) · 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 {N}행",
    "dn_automotive": _H + "행 조치 없음 · Refresh 휴가 권장은 싣지 않음 유지(리드 판정 135) · 항목 페이지 예외 1 · 점검기 중간 인증서(통합 밖 리드 · 등록 집행) — 최종 {N}행",
    "daishin_securities": _H + "체력단련휴가를 refresh_leave 에서 leave_general 로 재코딩 · 탄력적 근무시간제 행에 공시 시차출퇴근제 · 선택근무제 병합 · 공시 원격근무제 remote_work 추가(리드 판정 137) · 81쪽 복리후생비 단체보험 insurance 추가 · 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 {N}행",
    "sk_networks": _H + "선택적 근로시간제 서술에 공시 시차출퇴근제 · 신규 코드 financial_planning 재무설계 지원 행을 mental 상담 행에 병합(신규 코드 0) · 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 {N}행",
    "lotte_energy_materials": _H + "재무제표 주석 근속 행 이름을 장기근속 급부로 · 13쪽 워라밸 데이 leave_general 추가(참고 블록 제외 줄의 워라밸 데이는 이 판정으로 뒤집힘) — 최종 {N}행",
    "yg_entertainment": _H + "주택 전세 자금 행 꼬리에서 원문 밖 대출 낱말 걷기 · 성과급 행에 반기보고서 전사 구성원 특별 상여금 구절 병합 · 항목 페이지 예외 2(통합 밖 리드 집행) — 최종 {N}행",
    "nexon_games": _H + "재무제표 주석 근속 행 이름을 장기근속 급부로 · 가족 돌봄 행은 지원금 몫만 · 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 {N}행",
    "cha_biotech": _H + "장기근속 포상 행에 2025년 12월 뉴스룸 기사 출처 · 학위 행에 차바이오 MBA 병합(참고 블록 보조 기사 5편은 이 판정으로 7편) · 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 {N}행",
    "sampyo_cement": _H + "2시간 단위 휴가 서술에서 반차 몫 4시간 구절 걷기 · 항목 페이지 예외 2(통합 밖 리드 집행) — 최종 {N}행",
    "robostar": _H + "행 조치 없음 · 항목 페이지 예외 2(통합 밖 리드 집행) — 최종 {N}행",
    "ls_marine_solution": _H + "행 조치 없음 · 공고 근거 12행 등록(리드 판정 138 — 한시적 출처) · 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 {N}행",
    "snt_energy": _H + "행 조치 없음 · 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 {N}행",
    "snt_dynamics": _H + "행 조치 없음 · 신규 코드 barber_shop 유지 · 항목 페이지 예외 2(통합 밖 리드 집행) — 최종 {N}행",
    "lotte_tour": _H + "탄력적 근로시간제 이름을 조건부로 · 선택적 근로시간제는 싣지 않음 유지(리드 판정 139) · 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 {N}행",
}
assert set(HEADER_TEXT) == set(ROSTER_NM)

WHY.update({
    "lotte_shopping": [
        "검증 REFUTED · 조치 1 — 롯데마트 교육제도 페이지(PbcmRecruit0010)만 근거 · 같은 페이지 「VIC마켓 영등포점」(2022 롯데마트 맥스로 바뀐 옛 브랜드) · 점장양성 9주(2025 보고서 약 4개월과 다름) = 옛 판(계약 3-1 옛 출처) · 리드 판정 (136) ①",
        "검증 SUSPECT · 조치 2 — 롯데마트 쪽 어학 구절은 옛 판 0010 에만 · 보고서 44쪽 구절만 남김 · 한 사업부 행이라 「(백화점부문)」, 이름 · 문안 교체 그대로",
        "검증 SUSPECT · 조치 3 — 이러닝(LEP제도) 구절은 0010 옛 판에만 · 보고서 44쪽 · 정본 e-Learning 구절만, 이름 · 문안 교체 그대로",
        "검증 SUSPECT · 조치 4 — 롯데마트 0009 「단체 보험 및 건강검진」 칸 본문이 「4대 보험 및 매년 1회 건강검진」(4대 보험 = 법정 · 단체보험 상품 문장 아님) → 46쪽 단체보험 구절만, 문안 교체 그대로(이름 유지)",
        "검증 SUSPECT · 조치 5 — leave_len 면을 켜던 「남성 자동 육아휴직(3개월)」 어순 정리 · 16쪽 일맘 CLUB 워크숍 병합(423자), 이름 · 문안 교체 그대로",
        "검증 조치 7 · 리드 메모 ② — 두 사업부 이상 같은 제도는 이름에서 「(…부문)」을 뗀다(출처 괄호가 사업부를 밝힘), 이름 교체 그대로",
        "검증 조치 7 · 리드 메모 ② — 같은 이유, 이름 교체 그대로",
        "검증 조치 7 · 리드 메모 ② — 같은 이유, 이름 교체 그대로",
        "검증 조치 7 · 리드 메모 ② — 같은 이유, 이름 교체 그대로",
        "검증 조치 7 · 리드 메모 ② — 같은 이유, 이름 교체 그대로",
        "검증 조치 7 · 리드 메모 ② — 같은 이유, 이름 교체 그대로",
        "검증 조치 7 · 리드 메모 ② — 같은 이유, 이름 교체 그대로",
        "검증 조치 7 · 리드 메모 ② — 같은 이유, 이름 교체 그대로",
        "검증 조치 7 · 리드 메모 ② — 같은 이유, 이름 교체 그대로",
        "검증 조치 7 · 리드 메모 ② — 같은 이유, 이름 교체 그대로",
        "검증 조치 7 · 리드 메모 ② — 같은 이유, 이름 교체 그대로",
        "검증 조치 7 · 리드 메모 ② — 같은 이유, 이름 교체 그대로",
    ],
    "hotel_shilla": [
        "검증 MISSED · 조치 1 — 자기 도메인 복리후생 이미지 「의료실비/단체보험」(판독) + E50 칸 이름 「건강검진 및 의료비 지원」 · 실손(실비) = medical(어휘 경계) · 단체보험은 11 insurance 그대로, 완성 튜플 그대로",
        "검증 MISSED · 조치 1 — 자기 도메인 인사제도 「경영성과에 따른 별도의 인센티브제도 · TAI · OPI · 업적성과급」(비율 = NULL) · 새 compensation 섹션 머리 주석(검증 조치 1 글자 — 섹션 첫 행 80 위), 완성 튜플 그대로",
        "검증 MISSED · 조치 1 · 리드 메모 — 자기 도메인 복리후생 이미지 「장기근속 포상」 + 반기보고서 주석 장기근속보상(SNT모티브 잣대), 완성 튜플 그대로",
        "검증 병합 · 조치 2 — 자기 도메인 인재육성 글로벌교육 SGPL · 스픽 · 디지털 외국어 생활관, 최종 문안 그대로",
        "검증 병합 · 조치 3 — 자기 도메인 인재육성 온라인교육 CiC · 클래스 101, 최종 문안 그대로",
        "검증 병합 · 조치 4 — 자기 도메인 인재육성 글로벌교육 「삼성 그룹 지역전문가 · SGBP」(같은 파견형 — career), 이름 · 문안 교체 그대로",
    ],
    "hs_hyosung_advanced": [
        "검증 SUSPECT · 조치 1 — 「제휴 복지몰」은 어휘 경계상 welfare_point(discount 「아님: 복지몰」) → 이 행은 세빛섬 몫만, 문안 교체 그대로(이름 유지)",
        "검증 조치 2 — 복지몰 몫을 perks SORT 44 welfare_point 새 행으로(그룹 공통 문구 각주 ②), 완성 튜플 그대로",
        "검증 SUSPECT · 조치 3 — 「하기 휴가 및 휴가비 지급」 = 휴가와 돈 한 줄 → 이 행은 휴가비 몫만, 이름 · 문안 교체 그대로",
        "검증 조치 4 — 휴가 몫을 time_off SORT 91 summer_leave 새 행으로(VALUES 마지막 행), 완성 튜플 그대로",
        "검증 MISSED · 조치 5 — 45쪽 생애주기 표 「유급 출산 휴가 최소 3개월~최대 6개월」 = 원문이 법정(3개월)과 상한(6개월)을 스스로 가른 상회분(계약 3-2 「육아휴직 최대 2년」 꼴), 완성 튜플 그대로",
    ],
    "pan_ocean": [
        "검증 SUSPECT · 조치 1 — 해상 직원만 쓰는 제도 · 직군 한정은 이름에(계약 3-5), 이름 교체 그대로 · 신규 코드 유지(§1-1)",
        "검증 SUSPECT · 조치 2 — 선박 단위 지급 · 해상 직원 한정을 이름에, 이름 교체 그대로",
        "검증 MISSED · 조치 3 — 47쪽 재고용 외국인 사관 · 부원 본인 · 가족 실손의료보험(가족 몫은 MLC 의무 밖) · 실손만 = medical · 공동 주어 → 통합 보고 각주(63~65 와 같은 잣대), 완성 튜플 그대로",
    ],
    "daehan_shipbuilding": [
        "검증 SUSPECT · 조치 1 · 2 · 리드 판정 (135) ① — 「17시 퇴근」 = 정규 퇴근 시각(평일 08~17시) · 행은 남기고 이름 · 서술에 근무시간을 나란히(조기 퇴근으로 읽히지 않게), 이름 · 문안 교체 그대로",
    ],
    "ipark_hdc": [
        "검증 SUSPECT · 조치 1 · 리드 메모 — 2026 반기보고서 유연근무 표 「일부활용(본사)」 = 사유 한정 → 칩 꼴 「(조건부)」(계약 3-10), 이름 교체 그대로",
        "감사 §2-7 · 리드 판정 (137) 잣대 — 반기 유연근무 표 「원격근무제(재택근무 포함) 사용자 수 0 · 0 · 8」(`W/ipark_hdc/raw/dart_20260818000088/20260818000088.txt:67316`) = 표의 제도 이름은 그 자체로 행 · 0 · 「-」는 빼는 근거가 아니다 — 대신증권 81 과 같은 꼴(검증 N2 는 (137) 전에 끝남) · 같은 표 「일부활용(본사)」 → 10 과 같은 칩 꼴 「(조건부)」, 감사 튜플(flexibility SORT 11 · SORT 10 바로 뒤)",
    ],
    "daishin_securities": [
        "검증 SUSPECT · 조치 1 — 61쪽 도표 이름뿐 · 연차 외 낱말 없음 → 어휘 경계 「리프레시가 아닌 이름뿐인 휴가 = leave_general」(카테고리 time_off 그대로 · 칩 리프레시를 켤 근거 없음), 완성 튜플의 코드 · 이름 · 서술 그대로",
        "검증 MISSED(병합) · 조치 2 — 반기보고서 「바. 유연근무제도 사용 현황」 시차출퇴근제 97 · 132 · 114 · 선택근무제 5 · 4 · 3, 이름 · 문안 교체 그대로",
        "검증 MISSED · 조치 3 · 리드 판정 (137) — 공시 표 「원격근무제(재택근무 포함) 사용자 수 - · - · 6」 = 표 제도 이름은 그 자체로 행(계약 3-12 · (120)), 완성 튜플 그대로",
        "검증 MISSED · 조치 4 — 81쪽 ESG Data 복리후생비 단체보험 0.3억 원 × 3년(0 아닌 지출 = 지표 이름 칸 제외 대상 아님) · 금액은 통계 총액이라 NULL, 완성 튜플 그대로",
    ],
    "sk_networks": [
        "검증 SUSPECT · 조치 1 — 「시작 시간으로부터 8시간 · 30분 단위 신청」 + 공시 선택근무제 「-」 · 시차출퇴근제 250 · 319 · 305 → 공시 문장 보강(197자), 문안 교체 그대로",
        "감사 §1-2 — 신규 코드 financial_planning 흡수: 코퍼스가 전문가 재무 상담을 전부 mental(EAP · 상담 서비스) 행에 싣는다(현대백화점 30 「EAP 종합 컨설팅 — 재무 설계」 · 제일기획 63 「EAP 를 통한 재무 및 재테크 관리」 · GS리테일 10 「재무코칭」 · 효성중공업 82 「세무 분야 상담」) — 계약 3-4 「코퍼스에 대응 어휘가 있으면 신규가 아니다」 · 회사당 한 코드 한 행 → SORT 53 서술을 26 에 병합(검증 §8 대안 이름)",
        "감사 §1-2 — 위 병합의 짝: SORT 53 financial_planning 삭제(서술은 26 에 옮김)",
    ],
    "lotte_energy_materials": [
        "검증 SUSPECT · 조치 1 — 재무제표 주석 근거 근속 행 이름을 「장기근속 급부」로(웨이브 8 감사 2-11 · 세방전지 · 코미코 · SNT모티브 · 에스에프에이 같은 근거 행), 이름 교체 그대로",
        "검증 MISSED · 조치 2 — 13쪽 이해관계자 표 임직원 대응 활동 「워라밸 데이 진행」(두 판 연속) · 어휘 「○○데이 = leave_general」 · 새 time_off 섹션 머리 주석(감사 글자 — 파일의 섹션 머리 꼴), 완성 튜플 그대로",
    ],
    "yg_entertainment": [
        "검증 SUSPECT · 조치 1 — 원문 「주택 전/월세 자금 지원」에 대출 낱말 없음(어휘 경계 「원문에 없는 대출 낱말을 더하지 않는다」) → 꼬리만, 문안 교체 그대로",
        "검증 병합 · 조치 2 — 반기보고서 임원 보수 칸 「전사 구성원 특별 상여금 지급」 = 칸 문장이 직원 적용을 스스로 밝힌 경우(계약 3-5 예외) · 같은 코드 병합, 문안 교체 그대로",
    ],
    "nexon_games": [
        "검증 SUSPECT · 조치 1 — 재무제표 주석 근거 근속 행 이름을 「장기근속 급부」로(웨이브 8 감사 2-11 같은 근거 행 꼴), 이름 교체 그대로",
        "검증 SUSPECT · 조치 2 — 「가족돌봄휴직과 지원금」 중 법정 휴직을 회사 제도처럼 싣지 않게 지원금 몫만(코드 parent_care 유지), 문안 교체 그대로",
    ],
    "cha_biotech": [
        "검증 · 조치 1 — 2025-12 뉴스룸 기사(창립기념일 15년 장기근속 포상)로 현행성 보강, 문안 교체 그대로",
        "검증 MISSED(병합) · 조치 2 — 그룹 뉴스룸 「차바이오 MBA(경영석사과정)」 선임급 이상 신청 · 교육비 50% 기업 부담(판정 (132) 학위 = mba · 그룹 주어 ② 각주), 이름 · 문안 교체 그대로",
    ],
    "sampyo_cement": [
        "검증 SUSPECT · 조치 1 — 원문 「반차(4H)/반반차(2H)」의 4시간 몫은 법정 반차(기준선 연차유급휴가 「반차」) · 회사분은 반반차(2시간)만(계약 3-2 「다른 행 서술 안에도 쓰지 않는다」) · 각주 ① 유지, 문안 교체 그대로",
    ],
    "lotte_tour": [
        "검증 SUSPECT · 조치 1 — 원문 「직무 특성에 따른 탄력적 근로시간제」 + 반기 「유연근무제 활용 여부 미도입」 → 전 직원 제도가 아님 · 칩 꼴 「(조건부)」(계약 3-10), 이름 교체 그대로",
    ],
})

_HDR_KEEP = ("—", "(머리말 참고 블록)", "고치지 않음",
             "계약 A 5 · B 7 — 참고 블록의 옛 문장은 고치지 않고 헤더 한 줄이 뒤집힘을 적는다(검증의 머리말 · 근거표 정정 권고 전부 — 근거표는 §14)")
KEEP.update({
    "lotte_shopping": [_HDR_KEEP,
                       ("19 · 90 · 92", "—", "롯데마트 0009 · 0008 근거 유지", "리드 판정 (136) ① — 지금 헤더 메뉴에서 링크되는 현행 페이지 · 보고서와 어긋남 없음(옛 판은 교육제도 0010 만)"),
                       ("40 · 41 · 62 · 63 · 71", "—", "「(○○부문)」 유지", "리드 메모 ② · 검증 — 한 사업부 행(40 칩 조건 「백화점부문」) · 41 은 두 사업부의 다른 휴가를 한 코드에"),
                       (32, "parenting", "남성 자동 육아휴직(3개월) 유지", "웨이브 7 규칙 · 판정 (123) 꼴 — 회사가 자동 · 의무 사용으로 정한 것")],
    "hotel_shilla": [_HDR_KEEP,
                     ("머리말 · INSERT · UPDATE", "(정본 URL)", "E50 유지", "리드 판정 (136) ② — 자기 도메인 복리후생 페이지는 항목이 이미지라 점검기가 변화를 못 본다 · 보조 출처로만"),
                     (40, "career", "지역전문가 유지", "검증 판단 요청 1"),
                     (12, "mental", "명상 병합 유지", "검증 판단 요청 2")],
    "hs_hyosung_advanced": [_HDR_KEEP,
                            ("12 · 40 · 41 · 50 · 44 · 91", "—", "「, HS효성그룹 공통 문구」 각주 유지", "리드 메모 · 검증 — 자기 도메인 그룹 주어 페이지(단서 없음) 각주 ②"),
                            (20, "flex_work", "시차출퇴근만", "리드 메모 ③ · 검증 — 더 새 공시(선택근무제 미시행)를 따름")],
    "taekwang_ind": [(51, "profit_sharing", "경영성과급 유지", "리드 판정 (136) ③ — 그 페이지 자체에 옛 판 증거 없음 · 남기는 쪽"),
                     (24, "retirement_support", "재취업 지원 유지", "검증 — 직원 826명(1,000인 미만 노력의무)"),
                     (91, "flex_work", "「(조건부)」 유지", "검증 — 대상 사유 한정")],
    "pan_ocean": [_HDR_KEEP,
                  ("63 · 64 · 65", "—", "「(팬오션 · 포스에스엠 통합 보고 기준)」 각주 유지", "검증 — 47 · 81쪽 공동 주어 · 표가 법인을 가르지 않음(계약 3-5 ③)"),
                  ("—", "(최고경영자과정 MBA)", "싣지 않음", "검증 — 83쪽 비즈니스 리더(실장 · 본부장) 열 = 임원 열 · 판정 (132) 갈래 아님"),
                  ("—", "(건강검진 당일 반차 · 심장 CT)", "싣지 않음", "검증 판단 요청 4 · 5")],
    "youngone": [(33, "company_event", "「, 영원무역그룹 공통 문구」 각주 유지", "검증 — 그룹 주어 보도자료 1행 각주 ②"),
                 (41, "parenting", "240 · 추정 유지", "검증 — 대상 집단 상시 월 지원(계약 3-3 ①)"),
                 (70, "flex_work", "「(자녀를 둔 임직원)」 유지", "검증 — 공시 사용자 수가 학부모 시차 출근제를 센 것")],
    "daehan_shipbuilding": [("71 · 90 · 91", "—", "공고 근거 3행 유지", "검증 — 공고 모집기간 「채용 시까지」 지금 게시 중 · 연봉 칸 「(성과급, 연차수당, 귀향비, 휴가비 제외)」")],
    "youngpoong": [(40, "welfare_point", "임직원몰 유지", "검증 판단 요청 1 — 어휘 경계 「복지몰 = welfare_point」"),
                   (72, "welcome_kit", "수습해지자 선물 유지", "검증 판단 요청 2"),
                   (90, "flex_work", "맨 칩 유지", "검증 판단 요청 3 — 사업장 · 직군 한정 꼴이 계약 3-10 에 없고 공시 선택근무 64명")],
    "ipark_hdc": [(20, "dormitory", "숙소 = dormitory 유지", "검증 판단 요청 2"),
                  (50, "leave_general", "휴테크 제도 이름만 유지", "검증 판단 요청 3")],
    "dn_automotive": [("—", "(Refresh 휴가제도 — 하계 1주 · 동계 1주 휴가 권장)", "싣지 않음", "리드 판정 (135) ② — 권장 휴가(회사가 더 주는 날 없음)"),
                      (20, "resort", "여가 복지몰 = resort 유지", "검증 판단 요청 1 — 원문이 몰 내용을 콘도 · 숙박으로 밝힘"),
                      ("머리말 · INSERT · UPDATE", "(정본 URL)", "자기 도메인 유지", "리드 칸 결론 5 — 점검기 중간 인증서는 등록 단계(§5-0 동반 조치 · §6)")],
    "daishin_securities": [_HDR_KEEP,
                           ("—", "(고객응대 상담 · 재취업 지원 · 외부 전문가 과정 · 사우회)", "싣지 않음", "검증 판단 요청 2 · 3 · 4 — 산안법 41조 · 1,000인 이상 법정 · 업무 교육 · 내용 없음")],
    "sk_networks": [_HDR_KEEP,
                    (90, "work_tools", "모바일 그룹웨어 유지", "검증 — 회사 복지 목록 「기타」 항목(PDF · 보고서 45쪽 표)"),
                    ("58 · 59 · 81 · 91", "—", "2024-01 복지 안내 PDF 단독 행 유지", "검증 · 리드 판정 (136) ① 잣대 — 정본이 지금 링크하는 자료 · 보고서와 어긋남 없음")],
    "lotte_energy_materials": [_HDR_KEEP,
                               ("—", "(롯데 MBA)", "싣지 않음", "검증 · 웨이브 8 롯데웰푸드 감사 — 사외 MBA · 학위 문장 0 · 그룹 사내 과정")],
    "yg_entertainment": [(26, "welfare_point", "자기계발비 지원 = welfare_point 유지", "검증 — 칸 설명이 복지포인트(용도 자유) · 「최대 130만원」 한도 NULL"),
                         ("22 · 23", "housing_loan · housing_support", "두 행 유지", "웨이브 7 주택 규칙")],
    "nexon_games": [(11, "remote_work", "맨 칩 유지", "검증 판단 요청 1 — 공시 사용자 11 · 대상 · 사유 한정 문장 없음"),
                    (91, "parenting", "출산전후 휴가 급여 100% 상회분 유지", "검증 판단 요청 4")],
    "cha_biotech": [_HDR_KEEP,
                    ("30 · 31", "leave_general · long_service_leave", "두 행 유지", "검증 판단 요청 1"),
                    ("80 · 81", "—", "「(그룹 통합 채용 기준)」 각주 유지", "검증 — 그룹 채용 페이지 「다소 차이」 단서 · 장소로 적용 확인한 2행만")],
    "sampyo_cement": [("53 · 54 · 63", "—", "「(그룹 통합 채용 기준)」 각주 유지", "검증 판단 요청 1 · 2"),
                      (63, "summer_vacation_subsidy", "NULL 유지", "검증 판단 요청 3 — 「연 · 매년」 표지 없음"),
                      (42, "telecom", "통신비만", "검증 — 더 새 보고서가 업무보조비를 통신비로 적음(계약 3-1)")],
    "robostar": [(71, "welfare_point", "110 · 추정 유지", "검증 판단 요청 3 — 배정형 포인트 · 「지급 주기 미기재」 꼬리"),
                 ("—", "(영문판 기념일 지원 · Early Home Day)", "싣지 않음", "검증 판단 요청 2 — 국문 2026-05 판이 더 새 판")],
    "ls_marine_solution": [("10 · 20~25 · 30 · 40 · 41 · 50 · 51", "—", "공고 근거 12행 유지", "리드 판정 (138) — 자기 도메인 게시판에 지금도 공개된 가장 새 회사 원문 · 한시적 출처(§14)"),
                           ("—", "(사내근로복지기금 이사회 안건)", "싣지 않음", "검증 판단 요청 2 — 안건 제목뿐")],
    "snt_energy": [(70, "conference", "「, SNT그룹 공통 문구」 각주 유지", "검증 — 형제 SNT다이내믹스와 같은 글자 · 머리 「SNT는」"),
                   (51, "incentive", "각주 없음 유지", "검증 판단 요청 1 — 임금제도 칸 주어 「당사는」 · 형제와 문장 다름")],
    "snt_dynamics": [("21 · 70", "—", "「, SNT그룹 공통 문구」 각주 유지", "검증 — SNT모티브 같은 글자 · 머리 「SNT는」"),
                     ("—", "(기타장기종업원급여)", "싣지 않음", "검증 판단 요청 3 — 주석에 「장기근속」 낱말 없음")],
    "lotte_tour": [("23 · 24 · 42 · 50 · 52 · 53 · 60 · 70 · 71 · 80 · 81", "—", "「(롯데관광개발 · 엘티엔터테인먼트 통합 채용 기준)」 각주 유지", "검증 판단 요청 3 · 4 — 두 법인 공용 채용 페이지 · 「그룹」 낱말을 쓰면 롯데그룹으로 읽힌다"),
                   ("—", "(선택적 근로시간제)", "싣지 않음", "리드 판정 (139)")],
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
    print("§codes 신규 코드 — 어휘표 91종 · 코퍼스 실사용 대비")
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




SIBLINGS = {  # 이번 회사 eng → 기등록 형제 · 같은 업종 회사 표시명(정규식) — 코퍼스(웨이브 6 · 7 · 8 포함 218) + 이번 웨이브 안
    "lotte_shopping": r"롯데",
    "hotel_shilla": r"^삼성|신라",
    "hs_hyosung_advanced": r"효성",
    "taekwang_ind": r"태광|흥국|대한화섬",
    "pan_ocean": r"팬오션|하림|HMM|해운",
    "youngone": r"영원",
    "daehan_shipbuilding": r"대한조선|조선|중공업|오션",
    "youngpoong": r"영풍|고려아연",
    "ipark_hdc": r"HDC|아이파크|IPARK|현대산업",
    "dn_automotive": r"^DN|디엔",
    "daishin_securities": r"대신",
    "sk_networks": r"^SK",
    "lotte_energy_materials": r"롯데",
    "yg_entertainment": r"와이지|YG|JYP|하이브|에스엠",
    "nexon_games": r"넥슨|NEXON",
    "cha_biotech": r"차바이오|차병원|CMG",
    "sampyo_cement": r"삼표|시멘트",
    "robostar": r"^LG|로보",
    "ls_marine_solution": r"^LS|가온",
    "snt_energy": r"SNT|에스앤티",
    "snt_dynamics": r"SNT|에스앤티",
    "lotte_tour": r"롯데|파라다이스",
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




FOOTNOTE = re.compile(r"\(그룹 통합 채용 기준\)|그룹 공통 문구|통합 보고 기준\)|통합 채용 기준\)")




@section("consist")
def sec_consist(collect, final, corpus):
    print("=" * 100)
    print("§consist ① 각주 세 꼴 — ① 그룹 통합 채용(삼표 · 차바이오 · 롯데관광개발 두 법인 꼴) · ② 그룹 공통 문구(HS효성 · SNT · 영원 · 차바이오) · ③ 통합 보고(팬오션)")
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

    print("\n§consist ③ 형제 이중 등록 · 문장 겹침(10자 이상 조각 · 출처 괄호 · 꼬리 제외) — 코퍼스 218 + 웨이브 안 22")
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
        print(f"   {collect[e]['file']}: 형제 {len(sibs)}({', '.join(('웨이브9 ' if k.startswith('W9:') else '') + c['meta']['nm'] for k, c in sibs.items()) or '없음'}) · 겹친 조각 {len(hits)}")
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

    print("\n§consist ⑥ 웨이브 9 경계 축 — 이름 · 서술 정규식 또는 코드 묶음")
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
        ("가족 동승 · 이용원 · 재무설계(신규 후보)", r"동승|방선|이용원|재무설계", ("family_onboard", "barber_shop", "financial_planning")),
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


@section("reg")
def sec_reg(collect, final, corpus):
    print("=" * 100)
    print("§reg 등록 값 · 업종 · corp_code")
    dart = json.load(open(W9 + "/dart/check-2026-10-15.json", encoding="utf-8"))
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
              f"slug={slug_of(eng)}\tDART {dk['corp_code']} '{dk['dart_name']}' 종목 {dk['stock']}\t재무 {' '.join(dk['fin'])}\t직원 {' '.join(dk['emp'])}\t"
              f"csv corp 충돌 {have_codes.get(dk['corp_code'], 0)} · 이름 충돌 {m['nm'] in have_names} · 정식명=표시명 {dk['dart_name'] == m['nm']}\t{m['url']}")
    print(f"  이번 corp_code 중복 {len(codes_here) - len(set(codes_here))} · 기존 csv 와 겹침 "
          f"{sum(1 for x in codes_here if x in have_codes)} · csv 최대 comp_id {max(int(r['comp_id']) for r in cmap if r['comp_id'])} · csv 행 {len(cmap)} · "
          f"매핑(UNMAPPED 아님) {sum(1 for r in cmap if r['status'] != 'UNMAPPED')} · 법인 {len({r['corp_code'] for r in cmap if r['status'] != 'UNMAPPED'})}")
    new_inds = sorted(m for m in {expected_meta(e, collect)['ind'] for e in collect} if m not in inds)
    print(f"  INDUSTRY_NM 새 값 {new_inds or 0} · 바이트: " +
          ", ".join(f"{i}={i.encode().hex()}" for i in sorted({expected_meta(e, collect)['ind'] for e in collect})))
    print(f"  코퍼스 업종 값 {len(inds)}종 · 관련 값 {sorted(i for i in inds if i and re.search('유통|호텔|면세|카지노|화학|해운|조선|패션|섬유|비철|금속|건설|자동차|증권|금융|상사|배터리|소재|엔터|게임|바이오|제약|시멘트|로봇|전선|전력|에너지|발전|방산|기계', i))}")
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
    print(f"  stale(이 22사) {stale_all or 0}")
    from generator.pages.benefit import MIN_COMPANIES
    marks = json.load(open(WT + "/generator/data/row_marks.json", encoding="utf-8"))["rows"]
    marked = {(m["comp_eng_nm"], m["benefit_cd"]) for m in marks}
    print(f"\n  row_marks.json 에 이번 22사 eng 등록 {sorted({m['comp_eng_nm'] for m in marks if m['comp_eng_nm'] in collect}) or 0}")
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
    """코퍼스 218 + 모의본 22 를 한 폴더(W9/audit/tmp/combined)에 모아 리포 함수로 다시 본다 —
    어휘표 재생성(_vocab_scan) · build_company_meta(SI-13c 조건 칩 · SI-13d 이름 꼴) · 회사 수."""
    import shutil
    print("=" * 100)
    print("§combined 코퍼스 218 + 모의본 22 — 어휘표 · company_meta 재현")
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
        print(f"  이번 22사 aliases(지금 코드 — WAVE9 별칭 넣기 전) {aliases}")
        print(f"  이번 22사 work_style {{eng: ws}}:")
        for e in collect:
            print(f"     {e}: {ws[e]}")
    finally:
        cm.BENEFIT_SQL_DIR = old


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

