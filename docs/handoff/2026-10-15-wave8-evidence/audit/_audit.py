#!/usr/bin/env python3
"""웨이브 8 코퍼스 횡단 감사 — 재현 스크립트 (2026-10-15).

출발점: /home/ubuntu/loupit-evidence/2026-10-14-wave7/audit/_audit.py (웨이브 7 감사 — 조치 모델 · simulate · check-seed)
바꾼 것: 경로(W8 · 코퍼스 = 웨이브 8 worktree 시드 195파일 · 리포 모듈도 그 worktree 에서 import) · 대상 23파일 ·
        조치 문자열은 _extract.json(검증 보고서 백틱 · 펜스 JSON 기계 추출)에서 읽는다 · 같은 SORT 재코딩(set cd)을
        simulate 가 제자리 다시 쓰기로 처리 · 형제 · 경계 축 · 업종 정규식을 웨이브 8 에 맞춤. 어휘표(wave-lite 91종) ·
        행 점검기(wave-lite/_row_check.py)는 그대로.

리포 모듈을 **실제로 import** 해서 돌린다(추측 금지 — 리포는 읽기만 · 바이트코드도 쓰지 않는다):
  db.seed.load._split_sql_statements            분할기(5문장 · 셋째 = UPDATE TCOMPANY SET CAREERS_BENEFIT_URL)
  db.seed.company_meta.parse_header_insert       등록 문장 파서 · ws_conditions · derive_work_style(근무형태 칩)
  generator.slug.slug_of                         slug
  db.seed.backfill_dec2._DATE_RE · _URL_RE · derive_amt_source   확인일 · 출처 URL · 금액 출처
  generator.benefit_rules load_pages · classify · text_hash · validate_all   항목 페이지(웨이브 7 예외까지 든 worktree 설정)
  generator.pages.find _most_common · LABEL_OVERRIDE                           /find 대표 이름
  wave-lite/_row_check.py check()                SI-9 · SI-11 · SI-12 · SI-13d · SI-B2 사전 점검(게이트와 같은 함수)
  /home/ubuntu/loupit-evidence/2026-10-02-recollect-3-7/_len_check.py  필드 길이 · 행 파서(parse_values)

사용:
  python3 -I _audit.py [섹션 ...]          섹션 없으면 all(actions 제외)
    fmt codes consist amt reg legal pages chips final combined actions simulate
  python3 -I _audit.py check-seed <폴더>   그 폴더의 23파일을 최종본 모델과 행 단위 · 전 필드 대조 → 「형식 문제 n · 불일치 n」
  python3 -I _audit.py search <정규식>     코퍼스 195파일 행(이름 · NOTE · 서술)에서 정규식 검색(주석 제외)
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

WT = "/home/ubuntu/loupit/.claude/worktrees/wave8"   # 웨이브 7 위에 쌓은 웨이브 8 worktree(읽기만)
W8 = "/home/ubuntu/loupit-evidence/2026-10-15-wave8"
LITE = "/home/ubuntu/loupit-evidence/wave-lite"
COLLECT = W8 + "/collect"
SIM = W8 + "/audit/sim"
CORPUS = WT + "/db/seed/benefit/sql"                  # 리드 칸: 이것 하나만 센다(195파일)
VOCAB = LITE + "/_VOCAB.md"
LEN_CHECK = "/home/ubuntu/loupit-evidence/2026-10-02-recollect-3-7/_len_check.py"
LEGAL_SCAN = WT + "/docs/handoff/2026-09-19-evidence/_legal_scan.py"
ROW_CHECK = LITE + "/_row_check.py"
EXTRACT = W8 + "/audit/_extract.json"

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

# 리드 칸 대상 23파일(리드 칸 순서)
FILES = ["한일시멘트", "다우기술", "두산퓨얼셀", "SK가스", "STX엔진", "달바글로벌", "포스코DX", "SNT모티브", "롯데웰푸드",
         "한국카본", "인바디", "해성디에스", "에스디바이오센서", "시프트업", "신영증권", "미래에셋생명", "일진전기",
         "한화투자증권", "에스에프에이", "삼화콘덴서공업", "DL이앤씨", "NICE평가정보", "후성"]
MAXLEN = {"nm": 100, "note": 200, "qd": 500}  # db/schema.sql — BENEFIT_NM · NOTE_CTNT · QUAL_DESC_CTNT
META_MAX = {"eng": 30, "nm": 100, "ind": 50, "logo": 10, "url": 500}  # db/schema.sql TCOMPANY
CTGR = {"compensation", "health", "family", "leisure", "perks", "growth", "time_off", "flexibility", "work_env"}
HDR_INSERT = rc.HDR_INSERT
UPD = rc.UPD
TUPLE = re.compile(  # 원문 텍스트 안 튜플 위치(모의본 쓰기용) — 행 파서는 lc.parse_values 가 정본
    r"\(\s*@comp_id\s*,\s*'((?:[^']|'')*)'\s*,\s*'((?:[^']|'')*)'\s*,\s*(NULL|-?[\d.]+)\s*,\s*'([a-z_]+)'\s*,"
    r"\s*'([a-z_]+)'\s*,\s*(NULL|'(?:[^']|'')*')\s*,\s*(TRUE|FALSE)\s*,\s*(NULL|'(?:[^']|'')*')\s*,\s*(\d+)\s*\)",
    re.S)
ROSTER_NM = {  # eng(slug) → W8/dart/check-2026-10-15.json 의 키(리드 명단 이름 — 삼화콘덴서만 짧은 이름)
    "hanil_cement": "한일시멘트", "daou_tech": "다우기술", "doosan_fuelcell": "두산퓨얼셀", "sk_gas": "SK가스",
    "stx_engine": "STX엔진", "dalba_global": "달바글로벌", "posco_dx": "포스코DX", "snt_motiv": "SNT모티브",
    "lotte_wellfood": "롯데웰푸드", "hankuk_carbon": "한국카본", "inbody": "인바디", "haesung_ds": "해성디에스",
    "sd_biosensor": "에스디바이오센서", "shift_up": "시프트업", "shinyoung_sec": "신영증권",
    "mirae_asset_life": "미래에셋생명", "iljin_electric": "일진전기", "hanwha_inv_sec": "한화투자증권", "sfa": "에스에프에이",
    "samwha_capacitor": "삼화콘덴서", "dl_enc": "DL이앤씨", "nice_info": "NICE평가정보", "foosung": "후성"}
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
ACTIONS: dict[str, list] = {
    "hanil_cement": [
        ("set", 15, dict(qd=X("한일시멘트", 1))),
        ("set", 65, dict(qd=X("한일시멘트", 3))),
        ("set", 80, dict(qd=X("한일시멘트", 6))),
        ("add", T("한일시멘트", 7), None),
        ("add", T("한일시멘트", 8), None),
        ("add", T("한일시멘트", 9), None),
    ],
    "daou_tech": [
        ("set", 43, dict(nm=X("다우기술", 1), qd=X("다우기술", 2))),
    ],
    "doosan_fuelcell": [
        ("add", T("두산퓨얼셀", 0), None),
    ],
    "sk_gas": [
        ("set", 24, dict(cd=X("SK가스", 1))),
        ("set", 80, dict(qd=X("SK가스", 3))),
        ("set", 14, dict(qd=X("SK가스", 5))),
        ("add", T("SK가스", 6), None),
    ],
    "stx_engine": [
        ("add", T("STX엔진", 0), None),
    ],
    "dalba_global": [
        ("delete", 34),
        ("set", 33, dict(nm=X("달바글로벌", 2), qd=X("달바글로벌", 3))),
        ("add", T("달바글로벌", 4), None),
        ("set", 63, dict(qd=X("달바글로벌", 6))),
    ],
    "posco_dx": [
        ("set", 17, dict(nm=X("포스코DX", 1), qd=X("포스코DX", 2))),
        ("add", T("포스코DX", 3), None),
        ("delete", 53),
        ("add", T("포스코DX", 5), None),
    ],
    "snt_motiv": [
        ("add", T("SNT모티브", 0), None),
    ],
    "lotte_wellfood": [
        ("set", 80, dict(qd=X("롯데웰푸드", 1))),
        ("set", 41, dict(qd=X("롯데웰푸드", 3))),
        ("add", T("롯데웰푸드", 5), None),
        ("add", T("롯데웰푸드", 6), None),
        ("add", T("롯데웰푸드", 7), None),
    ],
    "hankuk_carbon": [],
    "inbody": [
        ("add", T("인바디", 0), None),
    ],
    "haesung_ds": [],
    "sd_biosensor": [],
    "shift_up": [],
    "shinyoung_sec": [
        ("set", 70, dict(cd=XQ("신영증권", 1), qd=XQ("신영증권", 5))),
        ("set", 12, dict(nm=XQ("신영증권", 7), qd=XQ("신영증권", 9))),
        ("add", T("신영증권", 10), None),
    ],
    "mirae_asset_life": [],
    "iljin_electric": [],
    "hanwha_inv_sec": [
        ("set", 41, dict(nm=X("한화투자증권", 1), qd=X("한화투자증권", 2))),
        ("add", T("한화투자증권", 3), None),
    ],
    "sfa": [],
    "samwha_capacitor": [],
    "dl_enc": [
        ("add", T("DL이앤씨", 0), None),
        ("delete", 22),
    ],
    "nice_info": [
        ("set", 11, dict(qd=X("NICE평가정보", 1))),
        ("set", 33, dict(nm=X("NICE평가정보", 3))),
        ("delete", 75),
    ],
    "foosung": [
        ("set", 80, dict(qd=X("후성", 1))),
        ("add", T("후성", 2), None),
    ],
}

# 감사가 새로 더한 시드 조치(검증 보고서에 없는 것 — 근거는 보고서 §2 · §13). 문자열은 이 감사가 쓴 글자다.
#   리드 판정 (132) 「선발형 학위 · MBA · 유학 = mba — 23사 전체에 맞춘다」: 검증 레인 M1 이 (132) 전에 끝나
#   「웨이브 7 규칙대로 제외」로 남긴 두 회사(롯데웰푸드 · SK가스)의 선발형 학위 · MBA 를 원문 그대로 싣는다.
MBA_LOTTE = ("(@comp_id, 'mba', '사외 MBA·대학원 과정', NULL, 'growth', 'est', NULL, TRUE, "
             "'핵심인재(Hi-Po) 대상 사외MBA/대학원 (2025 지속가능경영보고서 98쪽 교육체계도 핵심인재 항목), "
             "최신 트렌드와 산업 지식을 반영한 사외 MBA 등 맞춤형 교육 운영 (같은 쪽 임직원 육성 및 복지 항목) "
             "— 선발 기준·학비 지원 범위 미기재', 72)")
MBA_SKGAS = ("(@comp_id, 'mba', '국내외 학위 지원', NULL, 'growth', 'est', NULL, TRUE, "
             "'국내외 학위 지원, 핵심인재 육성을 목적으로 구성원 역량 및 성장 가능성 등을 고려한 대상자 선발을 통해 전문 교육 기회 제공 "
             "(2025 지속가능경영보고서 68쪽 주요 인재 육성 프로그램 항목) — 지원 학위 과정·학비 지원 범위·선발 인원 미기재', 93)")
#   §2-11 코퍼스 일관성: 재무제표 주석 근거 근속 행의 이름을 코퍼스 같은 근거 행(세방전지 14 · 코미코 14 「장기근속 급부」)과 같게 —
#   「종업원급여」(회계 용어) · 「임직원 급여」(봉급으로 읽힘)는 화면 이름으로 쓰지 않는다.
AUDIT_ACTIONS: dict[str, list] = {
    "lotte_wellfood": [("add", TA(MBA_LOTTE), None)],
    "sk_gas": [("add", TA(MBA_SKGAS), None)],
    "snt_motiv": [("set", 42, dict(nm="장기근속 급부"))],
    #   §3-2 금액 갈래 ①(계약 3-3 「대상 집단이 정해진 상시 지원 — 보육지원금 · 장애 자녀 치료비」) · 코퍼스 두산에너빌리티 35(장애 자녀
    #   치료비 월 20만 → 240) 와 같게: 원문 「1인당 연 200만원 지급」은 사건 조건부(재활수당)가 아니라 상시 정액 → 금액 행 · stated.
    "posco_dx": [("set", 65, dict(amt=200, qual=False, qd=None,
                                  note="직원 본인 및 배우자, 자녀 중 심한 장애를 가진 경우 1인당 연 200만원 지급 (공식 복지제도 페이지 가족친화 장애인가족지원 항목)"))],
    "sfa": [("set", 63, dict(nm="장기근속 급부 (5·10·20·30년 근속)"))],
}

# 정본 URL 교체(머리말 · INSERT · UPDATE 세 곳) — 이번 웨이브 없음(두산퓨얼셀 · 일진전기 · NICE평가정보 · 후성 · 미래에셋생명 목록 페이지 유지)
URL_CHANGE: dict = {}
HEADER_EDIT: dict = {}  # 참고 블록의 옛 문장은 고치지 않는다(계약 B · A 5) — 헤더 한 줄이 뒤집힘을 적는다

# 항목 페이지 동반 조치(리드 집행 — generator/data/benefit_pages/<code>.json overrides)
#   검증 보고서의 JSON 을 기계로 뽑았다. h 는 모의 최종 문안으로 다시 계산해 대조한다(sec_pages).
OVERRIDES: list[tuple[str, dict]] = [
    ("event", J("STX엔진", 1)),
    ("meal", J("한국카본", 0)),
    ("refresh_leave", J("신영증권", 11)),
    ("fitness", J("삼화콘덴서공업", 0)),
    ("holiday_gift", J("삼화콘덴서공업", 1)),
    ("long_service_bonus", J("롯데웰푸드", 4)),
    ("flex_work", J("한화투자증권", 4)),
    ("fitness", J("한화투자증권", 5)),
    ("mental", J("포스코DX", 6)),
    ("fitness", J("포스코DX", 7)),
    ("long_service_leave", J("포스코DX", 8)),
    ("clinic", J("포스코DX", 9)),
    ("lang", J("포스코DX", 10)),
    ("mba", J("포스코DX", 11)),
    ("leave_general", J("NICE평가정보", 5)),
    ("long_service_leave", J("NICE평가정보", 6)),
    ("lang", J("NICE평가정보", 7)),
    ("books", J("후성", 3)),
    ("self_development", J("후성", 5)),
    ("holiday_gift", J("SNT모티브", 2)),
    ("fitness", J("에스에프에이", 1)),
    ("meal", J("에스디바이오센서", 1)),
    ("mental", J("에스디바이오센서", 3)),
    ("mental", J("다우기술", 3)),
    ("books", J("다우기술", 4)),
    ("self_development", J("다우기술", 5)),
    ("edu_support", J("다우기술", 6)),
    ("housing_loan", J("다우기술", 7)),
    ("holiday_gift", J("다우기술", 8)),
    ("meal", J("인바디", 1)),
    ("dormitory", J("인바디", 2)),
    ("resort", J("인바디", 3)),
    ("mental", J("해성디에스", 0)),
    ("edu_support", J("해성디에스", 1)),
    ("holiday_gift", J("달바글로벌", 7)),
    ("discount", J("달바글로벌", 8)),
    ("parenting", J("미래에셋생명", 0)),
]
AUDIT_OVERRIDES: list[tuple[str, dict]] = []   # 감사가 더하는 예외(§10 — sec_pages 결과로 채운다)

HEADER_LINE: dict[str, str] = {}   # 아래 _header_lines() 가 채운다(최종 행 수를 모델에서 센다)
WHY: dict[str, list[str]] = {}     # §5 표의 「근거」 열 — 아래 _why.py 블록
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
            print(f"  ⚠ {fn}: 등록 eng {eng} 가 대상 23사가 아니다")
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
    "hanil_cement": _H + "이사 지원비 행에서 직원 숙소 구절 걷기 · 근속 가산 휴가 서술에 법정 가산 상회 구조 · 76쪽 품질분임조 포상을 우수 사원 포상 행에 병합 · 89쪽 Job Posting career · 90쪽 자격취득·학위과정 self_development · 92쪽 블레저 workation 추가(참고 블록 제외 줄의 블레저는 이 판정으로 뒤집힘) — 최종 {N}행",
    "daou_tech": _H + "팀/부서별 워크숍 비용 지원을 팀 커뮤니케이션 제도 행에 병합(참고 블록 제외 줄의 워크숍은 이 판정으로 뒤집힘) · 항목 페이지 예외 6(통합 밖 리드 집행) — 최종 {N}행",
    "doosan_fuelcell": _H + "80쪽 노사협의회 혹서기 쿨론소재 티셔츠 uniform 추가(참고 블록 제외 줄의 쿨론 티셔츠는 이 판정으로 뒤집힘) · 정본 목록 페이지 유지 — 최종 {N}행",
    "sk_gas": _H + "단신 부임 주거비를 housing_support 에서 relocation 으로 재코딩 · 질병 유급휴직 출처 괄호 정정 · 54쪽 건강 증진 프로그램을 피트니스 행에 병합 · 금연 캠페인 smoking_cessation 추가 · 68쪽 국내외 학위 지원 mba 추가(리드 판정 132 — 참고 블록 제외 줄의 학위 지원은 이 판정으로 뒤집힘) — 최종 {N}행",
    "stx_engine": _H + "인사제도 평가제도의 성과배분 incentive 추가(참고 블록 제외 줄의 평가 문장은 이 판정으로 뒤집힘) · 경조금 행 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 {N}행",
    "dalba_global": _H + "신규 코드 own_product 행을 discount 행에 병합(신규 코드 0) · 이사회 주택 전세 및 구입금 지원 housing_loan 추가 · 우리사주 취득자금 대출을 우리사주 행에 병합(참고 블록 제외 줄의 이사회 안건은 이 판정으로 뒤집힘) — 최종 {N}행",
    "posco_dx": _H + "대부금 행에서 생활안정자금 대부를 welfare_fund_loan 으로 분리 · 해외 세미나 컨퍼런스 conference 삭제(업무 교육 · 글로벌 칸) · 35쪽 유학과정 mba 추가(리드 판정 132 — 참고 블록 제외 줄의 유학과정은 이 판정으로 뒤집힘) · 장애인가족지원 연 200만원을 금액 행으로(상시 정액 · 참고 블록 금액 요약은 이 판정으로 뒤집힘) — 최종 {N}행",
    "snt_motiv": _H + "반기보고서 주석 장기근속원가 부채 long_service_bonus 장기근속 급부 추가(참고 블록 제외 줄의 장기근속원가 부채는 이 판정으로 뒤집힘) — 최종 {N}행",
    "lotte_wellfood": _H + "유연근무 행의 시차출근제를 원문 시차출퇴근제로 · 정본 목록 해외연수제도를 장기근속 포상 행에 병합 · 115쪽 전사 소통 행사 company_event · 116쪽 우수 상담사 포상 excellence_award · 112쪽 공장 간호사 clinic · 98쪽 사외 MBA 대학원 mba 추가(리드 판정 132 — 참고 블록 제외 줄의 해외연수제도 · 사외MBA는 이 판정으로 뒤집힘) — 최종 {N}행",
    "hankuk_carbon": _H + "행 조치 없음 · 식대 행 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 {N}행",
    "inbody": _H + "반기보고서 자기주식 임직원 보상 처분 stock_grant 추가(참고 블록 제외 줄의 자기주식 처분은 이 판정으로 뒤집힘) — 최종 {N}행",
    "haesung_ds": _H + "행 조치 없음 · 항목 페이지 예외 2(통합 밖 리드 집행) — 최종 {N}행",
    "sd_biosensor": _H + "행 조치 없음 · 항목 페이지 예외 2(통합 밖 리드 집행) — 최종 {N}행",
    "shift_up": _H + "행 조치 없음 — 최종 {N}행",
    "shinyoung_sec": _H + "정기휴가를 leave_general 에서 refresh_leave 로 재코딩 · 명절 행에서 가을행사 기념품을 company_event 로 분리 추가 — 최종 {N}행",
    "mirae_asset_life": _H + "행 조치 없음 · 위탁보육료 행 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 {N}행",
    "iljin_electric": _H + "행 조치 없음 · 정본 목록 페이지 유지 — 최종 {N}행",
    "hanwha_inv_sec": _H + "단체상해보험 및 실손보험 행에서 실손보험을 medical 로 분리 추가 — 최종 {N}행",
    "sfa": _H + "재무제표 주석 근속 행 이름을 장기근속 급부로(코퍼스 같은 근거 행과 같게) · 웰빙카드 행 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 {N}행",
    "samwha_capacitor": _H + "행 조치 없음 · 항목 페이지 예외 2(통합 밖 리드 집행) — 최종 {N}행",
    "dl_enc": _H + "정본 복리후생 장기근속자 해외여행 long_service_bonus 추가(참고 블록 제외 줄의 해외여행은 이 판정으로 뒤집힘) · 사외직무교육 conference 삭제(업무 교육 · 직무 교육 칸) — 최종 {N}행",
    "nice_info": _H + "체력단련 휴가 서술에 연차와 별도로 복원 · 원격근무제 이름을 조건부로 · 외부기관연수 conference 삭제(업무 교육 · 고도의 전문가 양성 칸) — 최종 {N}행",
    "foosung": _H + "장기근속자 선물 행에서 정년퇴직자 몫을 retirement_support 로 분리 추가 — 최종 {N}행",
}
assert set(HEADER_TEXT) == set(ROSTER_NM)

WHY.update({
    "hanil_cement": [
        "검증 SUSPECT · 조치 1 — 92쪽 한 문장의 앞 구절 「각 지역 공장에도 별도의 직원 숙소를 운영」은 `dormitory`(SORT 50) 몫 — 복합 문장을 쪼갠 행은 자기 몫만(계약 3-11), 교체 문안 그대로",
        "검증 SUSPECT · 조치 2 · 리드 메모 답 — 91쪽 「근로기준법 기준보다 상위」 · 근속 2년 후 매년 1일 · 상한 없음(법 60조④ = 2년마다 1일 · 25일 한도) → 행은 남기고 상회 구조를 괄호로, 교체 문안 그대로",
        "검증 병합 · 조치 3 — 76쪽 품질분임조 경진대회 수상 분임조 포상금 · 국내외 연수(문단 주어 「한일시멘트는」 — 각주 없음), 교체 문안 그대로",
        "검증 MISSED · 조치 4 — 89쪽 Job Posting 제도(사원이 스스로 지원하는 사내 이동 = 어휘 `career`) · 주어 「한일은」 → 통합 보고 각주, 완성 튜플 그대로",
        "검증 MISSED · 조치 5 — 90쪽 L&D 표 공통교육 「자격취득·학위과정」(계약 3-9 · 어휘 `self_development` 「직무 역량 개발 문단 안의 자격증」 · 「직무 외부교육·세미나」 몫은 싣지 않음), 완성 튜플 그대로",
        "검증 MISSED · 조치 6 — 92쪽 블레저 제도(회사가 이름 붙여 도입 · 출장 교통편 조정 · 체류 연장 허용 — 가장 가까운 코드 `workation`) · 주어 「한일은」 → 통합 보고 각주, 완성 튜플 그대로",
    ],
    "daou_tech": [
        "검증 MISSED(병합) · 조치 1 — 복지 페이지 「문화와 소통」 칸 「팀/부서별 워크숍」 반기마다 부서별 조직개발 워크숍 비용 지원(회사 복리후생 목록 항목 §3-12 — 「업무 활동」은 계약 제외 사유가 아니다), 이름 · 문안 교체 그대로",
    ],
    "doosan_fuelcell": [
        "검증 MISSED · 조치 1 — 80쪽 노사협의회 표 2025년 1분기 「항온 공정 이외 작업자 대상 혹서기 쿨론소재 티셔츠 지급」(부의/처리 4건/4건 = 시행 완료 · 같은 표의 교통비 · 간식 · 휴게실과 같은 기준 · 법정 보호구 열거 밖), 완성 튜플 그대로",
    ],
    "sk_gas": [
        "검증 SUSPECT · 조치 1 — 70쪽 「단신 부임 주거비 지원한도 상향」은 부임(발령) 사유 주거 지원 = 어휘 `relocation`(근거표 선례 「휴젤」은 인용 실재 실패 — 덕산네오룩스) · 카테고리 perks · 이름 · 서술 그대로",
        "검증 SUSPECT · 조치 2 — 54쪽 「유급휴가/휴직 지원」은 상자 소제목이 아니라 「의료비 지원」 상자 첫 줄 끝 구절(렌더 확인) — 출처 괄호의 칸 이름 정정, 교체 문안 그대로",
        "검증 MISSED(병합) · 조치 3 — 54쪽 사업장 건강 증진 프로그램(인바디 건강 증진 대회 · 집중 맞춤 건강 관리), 교체 문안 그대로",
        "검증 MISSED · 조치 4 — 54쪽 「대표적인 구성원 건강 증진 프로그램 … 금연 캠페인」 · 사진 캡션 [금연 프로그램](어휘 `smoking_cessation` = 금연 영역 전체), 완성 튜플 그대로",
        "리드 판정 (132) · 감사 §13-10 — 68쪽 「국내외 학위 지원 / 핵심인재 육성을 목적으로 … 대상자 선발을 통해 전문 교육 기회 제공」 = 선발형 학위 지원 → `mba`(검증 레인 M1 은 (132) 전에 끝나 웨이브 7 규칙 문면대로 뺐다), 감사 튜플(growth SORT 93 — VALUES 마지막 행)",
    ],
    "stx_engine": [
        "검증 MISSED · 조치 1 — 채용 사이트 인사제도 평가제도 「이를 통해 보상과 성과배분에 활용」(개인 · 조직 평가 연동 성과배분 = 어휘 `incentive`), 완성 튜플 그대로",
    ],
    "dalba_global": [
        "검증 SUSPECT · 조치 1 · 리드 칸 결론 2 — 신규 코드 `own_product` 흡수: 어휘 `discount` 가 「자사 제품 할인 판매」를, 항목 페이지 discount.json 이 무상 제공(facet `free_items`)을 이미 받는다 · 이름이 제도 영역이 아니라 대상 속성(§1)",
        "검증 조치 1 — 신제품 전사 제공 구절을 받는 `discount` 행 이름 · 문안 교체 그대로",
        "검증 MISSED · 조치 2 — 2025-05-07 이사회 「주택 전세 및 구입금 지원 대상 특별승인의 건」(임원 몫은 같은 날 투명경영위원회가 따로 승인 · 어휘 `housing_loan` 방식 미기재 주택구입 · 전세자금 지원), 완성 튜플 그대로",
        "검증 MISSED(병합) · 조치 3 — 같은 회차 「우리사주 취득자금 대출 지원 대상 특별승인 · 대여금 집행」을 우리사주 행 서술에, 교체 문안 그대로",
    ],
    "posco_dx": [
        "검증 SUSPECT · 조치 1 — 가계안정 「대부금」 칸 머리 아래 세 상품이 각자 이름 · 한도 · 이율로 따로 적힘 → 이 행은 주택 두 상품만, 이름 · 문안 교체 그대로",
        "검증 조치 1 — 생활안정자금 대부(주거 외 용도 대출 = 어휘 `welfare_fund_loan`)를 perks SORT 19 새 행으로, 완성 튜플 그대로",
        "검증 REFUTED · 조치 2 — 34쪽 인재 육성 Pipeline 「[Globality] 글로벌 & 공통」 칸 이름 「해외 세미나/컨퍼런스 지원」뿐(업무 교육 §3-9 · 웨이브 7 HK이노엔 · 이노션 선례)",
        "리드 판정 (132) · 검증 MISSED · 조치 3 — 35쪽 「유학과정 / 역량 우수직원 / 국내 산학 석사과정 … 입학금 및 등록금 … 경비 지원」(선발형 학위 = `mba`), 완성 튜플 그대로",
        "감사 §3-2 — 「1인당 연 200만원 지급」 = 대상 집단이 정해진 상시 정액(계약 3-3 ① 「장애 자녀 치료비」 · 코퍼스 두산에너빌리티 35 240) → 금액 200 · stated(원문 「연 200만원」 · 표지 없음), 서술을 NOTE 로 옮김(글자 그대로)",
    ],
    "snt_motiv": [
        "검증 MISSED · 조치 1 · 리드 메모 ③ — 2026 반기보고서 별도 재무제표 주석 「장기근속원가에 대한 부채」 · 기타장기종업원급여부채 전기 지급액 = 직원 근속 급부 공시 원문(계약 3-7), 완성 튜플 그대로(이름은 아래 #2)",
        "감사 §2-11 — 위 #1 로 넣은 행의 이름을 코퍼스 같은 근거 행(세방전지 · 코미코 「장기근속 급부」)과 같게(「종업원급여」는 회계 용어 · 원문에 없는 「포상」을 넣지 않는 것은 그대로)",
    ],
    "sfa": [
        "감사 §2-11 — 재무제표 주석 근거 근속 행 이름 「장기근속 임직원 급여」는 봉급으로 읽힌다 → 코퍼스 같은 근거 행(세방전지 · 코미코 「장기근속 급부」) 꼴 + 근속 연수 괄호 그대로(칩 코드 아님)",
    ],
    "lotte_wellfood": [
        "검증 SUSPECT · 조치 1 — 100쪽 렌더 「시차출퇴근제(유연근무제)」(텍스트 사본의 합자 깨짐을 「시차출근제」로 읽은 원문 밖 낱말), 교체 문안 그대로",
        "검증 MISSED(병합) · 조치 2 — 정본 목록 「해외연수제도」(이름만) ↔ 100쪽 「장기근속해외연수」 칸 짝(같은 목록 같은 기준 §3-12), 교체 문안 그대로",
        "검증 MISSED · 조치 4 — 115쪽 주니어 보드 전사 소통 행사 · 출근길 빼빼로 나눔(조직문화 절 행사 — 어휘 `company_event`), 완성 튜플 그대로",
        "검증 MISSED · 조치 5 — 116쪽 고객 응대 근로자 보호 「반기 단위로 우수 상담사를 선정·포상」(포상 제도 · 직군 한정은 이름에), 완성 튜플 그대로",
        "검증 MISSED · 조치 6 — 112쪽 인권고충처리 채널 「각 공장 간호사」(사내 간호사 = 법정 열거 밖 `clinic`), 완성 튜플 그대로",
        "리드 판정 (132) · 감사 §13-10 — 98쪽 교육체계도 핵심인재(Hi-Po) 칸 「사외MBA/대학원」 · 같은 쪽 본문 「사외 MBA 등 맞춤형 교육을 운영」 = 선발형 학위 · MBA → `mba`(검증 레인 M1 은 (132) 전에 끝나 웨이브 7 규칙 문면대로 뺐다 · 같은 칸 「롯데 MBA」는 그룹 사내 과정일 수 있어 옮기지 않음), 감사 튜플(growth SORT 72)",
    ],
    "inbody": [
        "검증 MISSED · 조치 1 — 2026 반기보고서 자기주식 처분 「임직원 보상제도 운영을 위해 … 5,100주(임직원 및 우리사주조합)」 · 목적 「주식보상」(웨이브 6 세방전지 같은 공시 절 선례), 완성 튜플 그대로",
    ],
    "shinyoung_sec": [
        "검증 SUSPECT · 조치 1 — 휴가제도 표가 「정기휴가: 유급휴가 연 5일」과 「법정휴가: 연차휴가」를 다른 항목으로 가름 = 어휘 `refresh_leave` 「법정 휴가 외 추가 휴가」(카테고리 time_off · 이름 그대로) · 출처 괄호의 메모 꼴 「법정」 걷기, 교체 문안 그대로",
        "검증 SUSPECT · 조치 2 — 「가을행사 기념품」은 날의 급부가 아니라 회사 행사의 급부 → 명절 몫만 남김, 이름 · 문안 교체 그대로",
        "검증 조치 3 — 가을행사 기념품을 leisure SORT 42 `company_event` 새 행으로, 완성 튜플 그대로",
    ],
    "hanwha_inv_sec": [
        "검증 SUSPECT · 조치 1 — 「단체상해보험 및 실손보험 가입」 = 상품 둘(어휘 경계: 실손만인 상품 = `medical`) → 이 행은 단체상해보험 몫만, 이름 · 문안 교체 그대로",
        "검증 조치 2 — 실손보험 몫을 health SORT 44 `medical` 새 행으로, 완성 튜플 그대로",
    ],
    "dl_enc": [
        "검증 MISSED · 조치 1 · 리드 메모 — 정본 복리후생 칸 「공로자, 장기근속자 해외여행」(보고서가 폐지 · 중단을 문장으로 밝히지 않음 · 지금 걸린 상시 페이지 · 포상금 · 휴가 행 70 과 다른 항목), 완성 튜플 그대로",
        "검증 REFUTED · 조치 2 — 정본 「직무 교육」 칸 안 사외직무교육 · 세미나 · 99쪽 직무교육 칸 「사외직무교육(컨퍼런스 등)」 = 업무 교육(§3-9 · 웨이브 7 HK이노엔 선례)",
    ],
    "nice_info": [
        "검증 SUSPECT · 조치 1 — 원문 「연차휴가와 별도로 체력 단련 휴가」의 「연차와 별도로」 꼴 복원(계약 3-11 허용 꼴 — refresh_leave 칩의 근거 구절), 교체 문안 그대로",
        "검증 SUSPECT · 조치 2 — 회사가 밝힌 쓰임은 24쪽 「감염병 대응 … 재택근무등 시행」 = 사유 한정 → 칩 꼴 「(조건부)」(계약 3-10), 이름 교체 그대로",
        "검증 REFUTED · 조치 3 — 16쪽 인재육성 표 「고도의 전문가 양성」 칸 외부기관연수(직무전문성 · 실무능력양성 = 업무 교육 §3-9)",
    ],
    "foosung": [
        "검증 SUSPECT · 조치 1 — 「장기근속자 선물 (10 년, 30 년, 정년퇴직자)」의 정년퇴직자 몫은 `retirement_support` 축 → 이 행은 근속 몫과 공시 주석만, 교체 문안 그대로",
        "검증 MISSED · 조치 2 — 정년퇴직자 선물을 growth SORT 24 새 행으로, 완성 튜플 그대로",
    ],
})

_HDR_KEEP = ("—", "(머리말 참고 블록)", "고치지 않음",
             "계약 A 5 · B 7 — 참고 블록의 옛 문장은 고치지 않고 헤더 한 줄이 뒤집힘을 적는다(검증의 머리말 · 근거표 정정 권고 전부 — 근거표는 §14)")
KEEP.update({
    "hanil_cement": [_HDR_KEEP,
                     ("32 · 33 · 42 · 70 · 71 · 72 · 90", "—", "각주 없음 유지", "검증 판단 요청 1 — 공동 주어 「한일홀딩스와 한일시멘트는」(이 법인이 이름으로 주어 — 계약 3-5 ③)"),
                     (11, "welfare_point", "여가활동비 유지", "검증 판단 요청 2 — 선택적 복리후생비 류(현대자동차 「여가생활 포인트」)"),
                     (74, "self_development", "학위과정을 mba 로 가르지 않음", "감사 §2 — 「자격취득·학위과정」 한 칸 복합 라벨 · 설명 · 선발 문장 없음 · 코퍼스 SK케미칼 「직무와 연관된 학위 및 자격증 취득 지원」 = self_development 와 같은 꼴(리드 판정 (132) 은 선발형 학위 · MBA 파견 과정 — 해당 없음)")],
    "daou_tech": [_HDR_KEEP,
                  (21, "insurance", "유지", "검증 판단 요청 1 — 회사 「생활 지원」 칸의 단체 가입 상해성 보험 · 한정은 이름에"),
                  (72, "remote_work", "유지", "리드 판정 (120) · 공시 사용자 2 > 0")],
    "doosan_fuelcell": [_HDR_KEEP,
                        ("머리말 · INSERT · UPDATE", "(정본 URL)", "목록 페이지 유지", "검증 실측 — SSR · 없는 경로 404(판정 (119) 의 PDF 전환 사유 없음) · 리드 칸 결론 5")],
    "sk_gas": [_HDR_KEEP,
               (61, "remote_work", "맨 칩 유지", "검증 판단 요청 8 — 공시 원격 355 / 직원 673 · 「자녀 돌봄 등」은 쓰임 예시"),
               (62, "satellite_office", "모바일 오피스 유지", "검증 판단 요청 4 — 운영 장소(서울 내)를 밝힘")],
    "stx_engine": [_HDR_KEEP,
                   (30, "birthday_gift", "「기념일 선물」 유지", "검증 판단 요청 1 — 날을 밝히지 않은 맨 라벨 · 코퍼스 6곳 같은 꼴")],
    "dalba_global": [_HDR_KEEP,
                     (53, "massage", "에스테틱 유지", "검증 판단 요청 3 — 미용 관리 서비스 선례(엔씨소프트 · SK텔레콤)"),
                     (62, "incentive", "상위 5명 표 직원 칸 인용 유지", "검증 판단 요청 7 — 직원 직위 칸 · 개인 이름 · 금액 없음")],
    "posco_dx": [_HDR_KEEP,
                 (16, "welfare_point", "150 · 추정 유지", "리드 메모 · 검증 — 발행일 있는 새 판 2025 보고서 「연 150만 포인트」 · 포인트 → 원 환산(계약 3-3 ②)"),
                 (41, "remote_work", "「육아기 재택근무」 유지", "검증 판단 요청 6 — 공시 낱말 · 칩 조건 꼴")],
    "snt_motiv": [(70, "conference", "유지", "검증 판단 요청 2 — 사외 기관 교육 지원(「직무」 낱말 없음 · 그룹 공통 문구 각주)"),
                  (20, "child_edu", "자녀 영어캠프 · 해외어학연수 병합 유지", "검증 판단 요청 1")],
    "lotte_wellfood": [_HDR_KEEP,
                       (31, "leave_general", "정기휴가 4일 유지", "검증 판단 요청 1 — 연차 외 원문 없음"),
                       (11, "parenting", "남성 육아휴직 의무 사용 유지", "리드 판정 (123)")],
    "hankuk_carbon": [(72, "leave_general", "「Bonus 휴가」 유지", "리드 메모 답 · 검증 — 근속 · 가산 낱말 없음 · 같은 칸에 연차가 따로 있음"),
                      (50, "flex_work", "「(조건부)」 유지", "검증 판단 요청 3 — 「일부 지역에 한함」")],
    "inbody": [(21, "meal", "864 유지", "리드 메모 · 검증 — 식대 절 「사업장별 상이는 적힌 끼니로」(한온시스템 · 한국타이어 · 더존비즈온 선례)"),
               ("—", "(GBD Program)", "싣지 않음", "검증 판단 요청 3 — 해외 파견 과정(학위 아님 · career · mba 행 없음 — 계약 3-9 행 신설 금지)")],
    "haesung_ds": [("—", "(임신기 안정 휴직)", "싣지 않음", "검증 판단 요청 1 — 법정 임신 중 육아휴직과 원문이 가르지 않음")],
    "sd_biosensor": [("—", "(/recruit/hmr 복리후생 표)", "쓰지 않음", "리드 메모 답 · 검증 — 헤더 메뉴 링크가 전부 주석 · 옛 교육 체계 · 옛 용어(계약 1-5 · 3-1)")],
    "shift_up": [("—", "(업무 환경 · 원격 · 시차)", "싣지 않음", "검증 판단 요청 1 · 2 — 내용 없는 라벨 · 공시 3년 0명 + 자기 출처 문장 없음(리드 판정 (120))")],
    "shinyoung_sec": [(11, "long_service_bonus", "안식휴가비 유지", "검증 판단 요청 2 — 돈과 휴가를 원문이 다른 표로 나눔")],
    "mirae_asset_life": [("머리말 · INSERT · UPDATE", "(정본 URL)", "?year=2025 목록 유지", "리드 메모 — 2026 판이 오르면 갈아끼움(§4 배포 시 주의)")],
    "iljin_electric": [("머리말 · INSERT · UPDATE", "(정본 URL)", "목록 페이지 유지", "검증 실측 — 없는 경로 404 · 리드 칸 결론 5"),
                       (31, "lounge", "편의시설 유지", "검증 판단 요청 1")],
    "hanwha_inv_sec": [_HDR_KEEP,
                       ("14 · 81", "meal · holiday_gift", "공시 직원 칸 근거 유지", "리드 메모 · 검증 — 「취업규칙 및 보상규정에 의거」 직원 칸(임원 칸 아님 · 계약 3-5)"),
                       (51, "refresh_leave", "「(조건부)」 유지", "검증 판단 요청 4 — 안식월(승진자)")],
    "sfa": [(10, "fitness", "웰빙카드 유지", "리드 메모 · 검증 판단 요청 1")],
    "samwha_capacitor": [(40, "long_service_leave", "문안 유지", "리드 메모 답 · 검증 — 근속 연수 괄호는 같은 말")],
    "dl_enc": [_HDR_KEEP,
               (30, "housing_loan", "사내대출 한 행 유지", "검증 — 102쪽 한 칸 한 이름(주택 · 생활 · 결혼 용도) = 「주택 대출과 한 라벨」")],
    "nice_info": [_HDR_KEEP,
                  (73, "mba", "선발형 학위 지원 유지", "리드 판정 (132)")],
    "foosung": [("11 · 23 · 62 · 73 · 81 · 82", "—", "「(그룹 통합 채용 기준)」 각주 유지", "리드 메모 · 검증 — 경동나비엔 선례와 같은 꼴")],
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


SIBLINGS = {  # 이번 회사 eng → 기등록 형제 회사 표시명(정규식) — 코퍼스(웨이브 6 · 7 포함 195) + 이번 웨이브 안
    "hanil_cement": r"한일",
    "daou_tech": r"다우|키움",
    "doosan_fuelcell": r"두산",
    "sk_gas": r"^SK",
    "stx_engine": r"STX",
    "dalba_global": r"달바",
    "posco_dx": r"포스코|POSCO",
    "snt_motiv": r"SNT|에스앤티",
    "lotte_wellfood": r"롯데",
    "hankuk_carbon": r"한국카본|한국화이바",
    "inbody": r"인바디",
    "haesung_ds": r"해성",
    "sd_biosensor": r"에스디|SD바이오|바이오노트",
    "shift_up": r"시프트업",
    "shinyoung_sec": r"신영",
    "mirae_asset_life": r"미래에셋",
    "iljin_electric": r"일진",
    "hanwha_inv_sec": r"한화",
    "sfa": r"SFA|에스에프에이",
    "samwha_capacitor": r"삼화",
    "dl_enc": r"^DL|대림",
    "nice_info": r"NICE|나이스",
    "foosung": r"후성",
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


FOOTNOTE = re.compile(r"\(그룹 통합 채용 기준\)|그룹 공통 문구|통합 보고 기준\)")


@section("consist")
def sec_consist(collect, final, corpus):
    print("=" * 100)
    print("§consist ① 각주 세 꼴 — 근거표 위험 표시: 그룹 통합 채용 = 후성 6행 · 그룹 공통 문구 = SNT모티브 2행 · 통합 보고 = 한일시멘트")
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

    print("\n§consist ③ 형제 이중 등록 · 문장 겹침(10자 이상 조각 · 출처 괄호 · 꼬리 제외) — 코퍼스 195 + 웨이브 안 23")
    wave = {e: dict(meta=collect[e]["meta"], rows=final[e], file=collect[e]["file"]) for e in collect}
    pool = dict(corpus)
    for e, v in wave.items():
        pool["W8:" + e] = v
    for e in collect:
        pat_s = re.compile(SIBLINGS[e])
        sibs = {x: c for x, c in pool.items() if x != "W8:" + e and pat_s.search(c["meta"]["nm"])}
        sib_text = " ".join(rtext(r) for c in sibs.values() for r in c["rows"])
        hits = []
        for r in final[e]:
            for f in _fragments(r["qd"] or r["note"]):
                if f in sib_text:
                    hits.append((r["sort"], r["cd"], f))
        print(f"   {collect[e]['file']}: 형제 {len(sibs)}({', '.join(('웨이브8 ' if k.startswith('W8:') else '') + c['meta']['nm'] for k, c in sibs.items()) or '없음'}) · 겹친 조각 {len(hits)}")
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

    print("\n§consist ⑥ 웨이브 8 경계 축 — 이름 · 서술 정규식 또는 코드 묶음")
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
    dart = json.load(open(W8 + "/dart/check-2026-10-15.json", encoding="utf-8"))
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
    print(f"  코퍼스 업종 값 {len(inds)}종 · 관련 값 {sorted(i for i in inds if i and re.search('시멘트|건설|건자재|소재|신용|금융|정보|IT|핀테크|보험|증권|에너지|가스|전선|전력|방산|기계', i))}")
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
            open(W8 + "/audit/tmp/legal_scan_sim.txt", "w", encoding="utf-8").write(out)
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
    for code, ov in (OVERRIDES if overrides is None else overrides):
        merged[code].setdefault("overrides", []).append(ov)
    return cfgs, merged


@section("pages")
def sec_pages(collect, final, corpus):
    print("=" * 100)
    print("§pages 항목 페이지 — 모의 최종 문안 해시로 예외 대조 · validate_all · 분류")
    cfgs, merged = _merged_cfgs()
    errs = br.validate_all(merged)
    print(f"  validate_all(현행 + 예외 {len(OVERRIDES)}건) 오류 {len(errs)} {errs[:5]}")
    per_code = collections.Counter(code for code, _ in OVERRIDES)
    print(f"  예외 파일별 개수 {dict(sorted(per_code.items()))}")
    for code, ov in OVERRIDES:
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
    print(f"  stale(이 23사) {stale_all or 0}")
    from generator.pages.benefit import MIN_COMPANIES
    marks = json.load(open(WT + "/generator/data/row_marks.json", encoding="utf-8"))["rows"]
    marked = {(m["comp_eng_nm"], m["benefit_cd"]) for m in marks}
    print(f"\n  row_marks.json 에 이번 23사 eng 등록 {sorted({m['comp_eng_nm'] for m in marks if m['comp_eng_nm'] in collect}) or 0}")
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
    """코퍼스 195 + 모의본 23 를 한 폴더(W8/audit/tmp/combined)에 모아 리포 함수로 다시 본다 —
    어휘표 재생성(_vocab_scan) · build_company_meta(SI-13c 조건 칩 · SI-13d 이름 꼴) · 회사 수."""
    import shutil
    print("=" * 100)
    print("§combined 코퍼스 195 + 모의본 23 — 어휘표 · company_meta 재현")
    d = W8 + "/audit/tmp/combined"
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
        print(f"  이번 23사 aliases(지금 코드 — WAVE8 별칭 넣기 전) {aliases}")
        print(f"  이번 23사 work_style {{eng: ws}}:")
        for e in collect:
            print(f"     {e}: {ws[e]}")
    finally:
        cm.BENEFIT_SQL_DIR = old


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
