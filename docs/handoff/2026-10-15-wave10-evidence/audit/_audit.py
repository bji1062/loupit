#!/usr/bin/env python3
"""웨이브 10 코퍼스 횡단 감사 — 재현 스크립트 (2026-10-15).

출발점: /home/ubuntu/loupit-evidence/2026-10-15-wave9/audit/_audit.py (웨이브 9 감사 — 조치 모델 · simulate · check-seed)
바꾼 것: 경로(W10 · 코퍼스 = 웨이브 9 worktree 시드 240파일 · 리포 모듈도 그 worktree 에서 import) · 대상 12파일 ·
        조치 문자열은 _extract.json(검증 보고서 절 7 백틱 · 절 4 완성 튜플 · JSON 기계 추출)에서 읽는다 ·
        항목 페이지 예외의 코드는 JSON 의 h 를 모의 최종 문안 해시와 맞춰 기계로 찾는다(손으로 코드를 적지 않음) ·
        형제 · 경계 축 · 업종 정규식을 웨이브 10 에 맞춤. 어휘표(wave-lite 93종) · 행 점검기(wave-lite/_row_check.py)는 그대로.

리포 모듈을 **실제로 import** 해서 돌린다(추측 금지 — 리포는 읽기만 · 바이트코드도 쓰지 않는다):
  db.seed.load._split_sql_statements            분할기(5문장 · 셋째 = UPDATE TCOMPANY SET CAREERS_BENEFIT_URL)
  db.seed.company_meta.parse_header_insert       등록 문장 파서 · ws_conditions · derive_work_style(근무형태 칩)
  generator.slug.slug_of                         slug
  db.seed.backfill_dec2._DATE_RE · _URL_RE · derive_amt_source   확인일 · 출처 URL · 금액 출처
  generator.benefit_rules load_pages · classify · text_hash · validate_all   항목 페이지(웨이브 9 예외까지 든 worktree 설정)
  generator.pages.find _most_common · LABEL_OVERRIDE                           /find 대표 이름
  wave-lite/_row_check.py check()                SI-9 · SI-11 · SI-12 · SI-13d · SI-B2 사전 점검(게이트와 같은 함수)
  /home/ubuntu/loupit-evidence/2026-10-02-recollect-3-7/_len_check.py  필드 길이 · 행 파서(parse_values)

사용:
  python3 -I _audit.py [섹션 ...]          섹션 없으면 all(actions 제외)
    fmt codes consist amt reg legal pages chips final combined actions simulate
  python3 -I _audit.py check-seed <폴더>   그 폴더의 12파일을 최종본 모델과 행 단위 · 전 필드 대조 → 「형식 문제 n · 불일치 n」
  python3 -I _audit.py search <정규식>     코퍼스 240파일 행(이름 · NOTE · 서술)에서 정규식 검색(주석 제외)
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

WT = "/home/ubuntu/loupit/.claude/worktrees/wave9"   # 웨이브 9 worktree(3278570 · 읽기만) — 웨이브 10 은 이 위에 쌓는다
W9 = "/home/ubuntu/loupit-evidence/2026-10-15-wave10"   # (변수 이름은 웨이브 9 판 그대로 — 값은 웨이브 10 폴더)
LITE = "/home/ubuntu/loupit-evidence/wave-lite"
COLLECT = W9 + "/collect"
SIM = W9 + "/audit/sim"
CORPUS = WT + "/db/seed/benefit/sql"                  # 리드 칸: 이것 하나만 센다(240파일)
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

# 리드 칸 대상 12파일(리드 칸 순서)
FILES = ["동원산업", "SGC에너지", "원익QnC", "효성티앤씨", "에코프로머티리얼즈", "코스모신소재", "SKC", "대주전자재료",
         "한올바이오파마", "GST", "씨에스윈드", "LS머트리얼즈"]
MAXLEN = {"nm": 100, "note": 200, "qd": 500}  # db/schema.sql — BENEFIT_NM · NOTE_CTNT · QUAL_DESC_CTNT
META_MAX = {"eng": 30, "nm": 100, "ind": 50, "logo": 10, "url": 500}  # db/schema.sql TCOMPANY
CTGR = {"compensation", "health", "family", "leisure", "perks", "growth", "time_off", "flexibility", "work_env"}
HDR_INSERT = rc.HDR_INSERT
UPD = rc.UPD
TUPLE = re.compile(  # 원문 텍스트 안 튜플 위치(모의본 쓰기용) — 행 파서는 lc.parse_values 가 정본
    r"\(\s*@comp_id\s*,\s*'((?:[^']|'')*)'\s*,\s*'((?:[^']|'')*)'\s*,\s*(NULL|-?[\d.]+)\s*,\s*'([a-z_]+)'\s*,"
    r"\s*'([a-z_]+)'\s*,\s*(NULL|'(?:[^']|'')*')\s*,\s*(TRUE|FALSE)\s*,\s*(NULL|'(?:[^']|'')*')\s*,\s*(\d+)\s*\)",
    re.S)
ROSTER_NM = {  # eng(slug) → W/dart/check-2026-10-15.json 의 키(리드 명단 이름 — 에코프로머티리얼즈만 DART 이름 「에코프로머티」)
    "dongwon_industries": "동원산업", "sgc_energy": "SGC에너지", "wonik_qnc": "원익QnC", "hyosung_tnc": "효성티앤씨",
    "ecopro_materials": "에코프로머티", "cosmo_amt": "코스모신소재", "skc": "SKC", "daejoo_electronic": "대주전자재료",
    "hanall_biopharma": "한올바이오파마", "gst": "GST", "cs_wind": "씨에스윈드", "ls_materials": "LS머트리얼즈"}
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
    "dongwon_industries": [
        ("add", T("동원산업", 2), None),
        ("add", T("동원산업", 3), None),
    ],
    "sgc_energy": [
        ("delete", 43),
        ("set", 90, dict(nm=X("SGC에너지", 3), qd=X("SGC에너지", 4))),
        ("add", T("SGC에너지", 5), None),
    ],
    "wonik_qnc": [
        ("add", T("원익QnC", 2), None),
        ("set", 70, dict(nm=X("원익QnC", 4), qd=X("원익QnC", 5))),
    ],
    "hyosung_tnc": [
        ("set", 21, dict(qd=X("효성티앤씨", 1))),
        ("set", 60, dict(nm=X("효성티앤씨", 3), qd=X("효성티앤씨", 4))),
        ("set", 80, dict(qd=X("효성티앤씨", 6))),
    ],
    "ecopro_materials": [],
    "cosmo_amt": [
        ("delete", 81),
    ],
    "skc": [
        ("set", 51, dict(qd=X("SKC", 1))),
        ("set", 62, dict(qd=X("SKC", 3))),
    ],
    "daejoo_electronic": [
        ("set", 80, dict(qd=X("대주전자재료", 2))),
        ("add", T("대주전자재료", 5), SEC(X("대주전자재료", 4))),
    ],
    "hanall_biopharma": [
        ("delete", 11),
    ],
    "gst": [],
    "cs_wind": [],
    "ls_materials": [
        ("add", T("LS머트리얼즈", 2), None),
    ],
}

# 감사가 새로 더한 시드 조치(검증 보고서에 없는 것 — 근거는 보고서 §2-11). 문자열은 이 감사가 정한 글자다.
#   §2-11 재무제표 주석만이 근거인 근속 행의 이름 — 코퍼스 정본 꼴 「장기근속 급부」(웨이브 8 감사 2-11 · 웨이브 9 검증 조치:
#   세방전지 14 · 코미코 14 · SNT모티브 42 · 롯데에너지머티리얼즈 21 · 넥슨게임즈 31 · 에스에프에이 63). 코퍼스에 「장기종업원급여」를
#   이름에 쓴 행 0 — 회계 계정 낱말이 화면 이름이 되지 않게(서술 · 출처 괄호의 원문 구절은 그대로).
LSB_NAME = "장기근속 급부"
AUDIT_ACTIONS: dict[str, list] = {
    "hyosung_tnc": [("set", 13, dict(nm=LSB_NAME))],
    "cosmo_amt": [("set", 82, dict(nm=LSB_NAME))],
}

# 정본 URL 교체(머리말 · INSERT · UPDATE 세 곳) — 이번 웨이브 없음
URL_CHANGE: dict = {}
# 등록 값 교체(INSERT 한 곳의 글자 — 옛 글자, 새 글자, 기대 등록 필드) — 이번 웨이브 없음(업종 12사 수집본 값 유지 — §4-2)
META_CHANGE: dict = {}
HEADER_EDIT: dict = {}  # 참고 블록의 옛 문장은 고치지 않는다(계약 B · A 5) — 헤더 한 줄이 뒤집힘을 적는다

# 항목 페이지 동반 조치(리드 집행 — generator/data/benefit_pages/<code>.json overrides)
#   검증 보고서의 JSON 을 기계로 뽑았다. 코드는 JSON 의 h 를 모의 최종 문안 해시와 맞춰 찾는다(resolve_overrides).
OVERRIDE_JSON: list[dict] = [
    J("동원산업", 4), J("동원산업", 5), J("동원산업", 6),
    J("SGC에너지", 6),
    J("효성티앤씨", 7), J("효성티앤씨", 8),
    J("에코프로머티리얼즈", 0),
    J("코스모신소재", 1),
    J("SKC", 5), J("SKC", 7), J("SKC", 9), J("SKC", 11),
    J("한올바이오파마", 0), J("한올바이오파마", 1),
    J("GST", 0),
    J("씨에스윈드", 0),
]
OVERRIDES: list[tuple[str, dict]] = []         # resolve_overrides() 가 (코드, JSON) 으로 채운다
AUDIT_OVERRIDES: list[tuple[str, dict]] = []   # 감사가 더하는 예외(§10 — sec_pages 결과로 채운다)


def resolve_overrides(final: dict) -> None:
    """JSON 의 h 를 그 회사 최종본 행의 text_hash 와 맞춰 코드를 정한다 — 한 행에만 맞아야 한다."""
    OVERRIDES.clear()
    for ov in OVERRIDE_JSON:
        hits = [r for r in final[ov["comp"]] if br.text_hash(r["qd"], r["note"]) == ov["h"]]
        assert len(hits) == 1, (ov["comp"], ov["h"], len(hits))
        OVERRIDES.append((hits[0]["cd"], ov))


# §8-2 db/seed/company_meta.py WAVE10_ALIASES 초안(보고서와 같은 글자 — combined 섹션이 충돌을 잰다)
WAVE10_ALIASES: dict[str, list[str]] = {
    "dongwon_industries": ["DONGWON INDUSTRIES"],
    "sgc_energy": ["SGC Energy", "에스지씨에너지"],
    "wonik_qnc": ["WONIK QnC", "원익큐엔씨", "원익쿼츠"],
    "hyosung_tnc": ["Hyosung TNC"],
    "ecopro_materials": ["에코프로머티", "ECOPRO MATERIALS", "에코프로지이엠"],
    "cosmo_amt": ["COSMO ADVANCED MATERIALS & TECHNOLOGY", "새한미디어"],
    "skc": ["에스케이씨"],
    "daejoo_electronic": ["Daejoo Electronic Materials", "대주교역"],
    "hanall_biopharma": ["HANALL BIOPHARMA", "한올제약"],
    "gst": ["Global Standard Technology", "글로벌스탠다드테크놀로지"],
    "cs_wind": ["CS Wind", "중산풍력"],
    "ls_materials": ["LS Materials", "엘에스머트리얼즈"],
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
            print(f"  ⚠ {fn}: 등록 eng {eng} 가 대상 12사가 아니다")
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




_H = "-- 검증 · 감사 판정 반영(2026-10-15): "
HEADER_TEXT: dict[str, str] = {  # 회사별 헤더 한 줄 — 따옴표 없음 · 최종 행 수는 모델에서 센다({N})
    "dongwon_industries": _H + "헤더 메뉴 영문판 기업 문화 교육제도 Future Leaders, Global Experts 칸의 어학 교육 프로그램 lang · Dongwon MBA와 글로벌 지역전문가 mba 2행 추가(동원그룹 공통 문구 각주) · 참고 블록의 공고 근거 0행 / 전체 17행은 전체 19행 · 항목 페이지 예외 3(통합 밖 리드 집행) — 최종 {N}행",
    "sgc_energy": _H + "그룹 채용 사이트 교통비 또는 식비 택일 라벨의 식비 meal 행 삭제(교통비 행 서술에 원문 그대로) · 자격증 행에서 업무 관련 자격 유지 교육비 구절을 걷고 자격증 취득 축하금만 · 2025 보고서 7쪽 CEO 메시지의 가족 단체 스포츠 관람 sports_ticket 추가(참고 블록 보조 출처 줄에 7쪽을 더해 읽는다) · 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 {N}행",
    "wonik_qnc": _H + "2023년 7월 뉴스센터 기사의 사내 복지차원 세차 직무와 2026 보고서 78쪽 사내 세차 car_wash 추가 · 인재육성체계 공통 교육 Work Smart OA 과정을 자기개발지원 edu_support 행에 병합(참고 블록의 인재육성체계 탭 행 없음 문장은 이 판정으로 뒤집힘 · 원익은 = 회사 약칭) · 참고 블록의 공고 근거 0행 / 전체 28행은 전체 29행 — 최종 {N}행",
    "hyosung_tnc": _H + "어린이집 행에서 형제 효성중공업과 같은 틀 블록의 위탁 운영 문장을 걷고 보고서 사업장 라벨만 · 퇴직자 지원 행은 퇴직 위로금만(사외 교육비는 1,000인 이상 법정 재취업지원 교육 범위 · 참고 블록 제외 줄과 같은 잣대) · 건강검진 행에 보고서 97쪽 주석의 검진 주기 · 재무제표 주석 근거 근속 행 이름을 장기근속 급부로(웨이브 8 · 9 꼴) · 항목 페이지 예외 2(통합 밖 리드 집행) — 최종 {N}행",
    "ecopro_materials": _H + "행 조치 없음 · 플러스 휴가 서술의 본인 휴가는 원문 개인연차를 낱말 규칙대로 바꾼 것(뜻 같음 · 회사가 더 주는 3일) · 그룹 채용 사이트 근거 4행의 그룹 통합 채용 기준 각주 유지 · 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 {N}행",
    "cosmo_amt": _H + "장기근속자 퇴직금 severance_plus 행 삭제(누진 · 가산 원문 없음 · 리드 판정 144) · 재무제표 주석 근거 근속 행 이름을 장기근속 급부로(웨이브 8 · 9 꼴) · 참고 블록의 공고 근거 0행 / 전체 23행은 전체 22행 · 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 {N}행",
    "skc": _H + "원격근무 서술에 원문 낱말 자율적으로를 되살림 · 인싸Learn · mySUNI 서술에 라이프 페이지 mySUNI 수강 문장을 되살림(SKC Family 공통 문구 각주) · 분류는 항목 페이지 예외 4(통합 밖 리드 집행)로 맞춤 — 최종 {N}행",
    "daejoo_electronic": _H + "외국어 교육 서술에 보고서 교육 대상별 교육 내용 표 이미지의 영어 · 일본어 · 중국어(꼬리의 교육 언어 미기재는 이 판정으로 뒤집힘) · 게시 중 채용공고 복리후생 휴일/휴가 칸의 정기 휴가 leave_general 추가(새 time_off 섹션) · 참고 블록의 공고 근거 9행 / 전체 26행은 10행 / 전체 27행 — 최종 {N}행",
    "hanall_biopharma": _H + "스톡그랜트 stock_grant 행 삭제(개인 연봉계약 · 이사회 결의 재량 부여 · 공시 개인별 부여는 등기임원 · 대표이사 몫) · 참고 블록의 공고 근거 0행 / 전체 11행은 전체 10행 · 항목 페이지 예외 2(통합 밖 리드 집행) — 최종 {N}행",
    "gst": _H + "행 조치 없음 · 효도 지원금 parent_care · 효도휴가 leave_general 두 행 유지 · 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 {N}행",
    "cs_wind": _H + "행 조치 없음 · 관리비 지원 housing_support · 정직원 순금 배지 welcome_kit · 질병 진료 보장 medical · 교육비와 컨퍼런스비 conference 유지 · 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 {N}행",
    "ls_materials": _H + "복리후생 목록 자기계발 지원의 사내교육 몫과 인재 육성 교육 표 사이버연수원(사내)을 edu_support 1행으로 추가(참고 블록 제외 줄의 사이버연수원은 이 판정으로 뒤집힘) · 참고 블록의 공고 근거 0행 / 전체 21행은 전체 22행 — 최종 {N}행",
}
assert set(HEADER_TEXT) == set(ROSTER_NM)

WHY.update({
    "dongwon_industries": [
        "검증 MISSED · 조치 1 — 헤더 메뉴 영문판 교육제도 「Future Leaders, Global Experts」 칸 「training programs that enhance … language proficiency」(국문판 칸과 다름) · 웨이브 7 규칙 「회사가 여는 어학 강좌는 선별 칸에 있어도 싣는다」 · 그룹 주어 페이지라 각주 ②, 완성 튜플 그대로",
        "검증 MISSED · 조치 2 — 같은 칸 「Dongwon MBA」 + 「Global Regional Expert Program」(현지 1년) · 판정 (132) 학위 = mba · career 행 없음 → 지역전문가는 mba 서술에 흡수(계약 3-9), 완성 튜플 그대로",
    ],
    "sgc_energy": [
        "검증 SUSPECT · 조치 1 — 그룹 채용 SGC에너지 전용 페이지 「매월 교통비 또는 식비 보조금」 = 택일 한 급부 · 정본은 교통비만 → 두 코드로 나누면 한 급부가 두 축을 켠다(코퍼스 「사택 또는 정착지원금」 한 행 꼴) · 식비 구절은 40 서술에 원문 그대로",
        "검증 SUSPECT · 조치 2 — 「업무 관련 자격 유지를 위한 교육비」 = 직무 필수 자격 보수교육(업무 교육 · 계약 3-9) · 축하금 몫만(코퍼스 BGF리테일 · 에코프로비엠 · 포스코퓨처엠 자격증 취득 축하금 = self_development), 이름 · 문안 교체 그대로",
        "검증 MISSED · 조치 3 — 2025 보고서 7쪽 CEO 메시지 「SGC에너지는 … 가족 단체 스포츠 관람 등」(법인 주어 · 복지 혜택으로 적음) · 코퍼스 sports_ticket, 완성 튜플 그대로",
    ],
    "wonik_qnc": [
        "검증 MISSED · 조치 1 — 뉴스센터 2023-07 「기업문화 활성화 및 사내 복지차원에서 시작된 세차 직무」 + 2026 보고서 78쪽 「사내 세차 직무를 신설」(최신 판에 지금도 있음) · 어휘 car_wash, 완성 튜플 그대로(perks SORT 35 뒤)",
        "검증 MISSED(병합) · 조치 2 — 인재육성체계 「공통 교육 / Work Smart (OA …)」 · 어휘 edu_support 「일반 사무 기술 과정(OA)」 이름까지 적힘 · 「원익은」은 회사 약칭(원익아카데미가 이 법인 보고서 당사 절 제도), 이름 · 문안 교체 그대로",
    ],
    "hyosung_tnc": [
        "검증 SUSPECT · 조치 1 — 페이지 어린이집 블록(「마포, 창원」 + 위탁 문장)이 형제 효성중공업 블록과 글자까지 같고 창원은 이 법인 사업장이 아님 · 더 새 보고서 49쪽 「본사, 구미공장, 울산공장」 라벨만, 문안 교체 그대로",
        "검증 SUSPECT · 조치 2 — 49쪽 「퇴직자 지원 제도 (재취업 지원, 진로 설계 교육, 퇴직 위로금, 사외 교육비 지원)」 · 직원 1,266명(≥1,000) → 재취업 · 진로 · 교육비 몫은 법정 재취업지원서비스 범위 · 퇴직 위로금만 법정 밖(코퍼스 정년퇴직 격려금 · 포상금 = retirement_support), 이름 · 문안 교체 그대로",
        "검증 SUSPECT · 조치 3 — 97쪽 주석 「40세 이상은 매년, 39세 이하는 격년」이 꼬리 「검진 주기 미기재」를 거짓으로 만든다, 문안 교체 그대로",
        "감사 §2-11 — 재무제표 주석만이 근거인 근속 행의 이름 = 코퍼스 정본 꼴 「장기근속 급부」(웨이브 8 감사 2-11 · 웨이브 9 검증 조치 — 세방전지 · 코미코 · SNT모티브 · 롯데에너지머티리얼즈 · 넥슨게임즈) · 이름에 「장기종업원급여」를 쓴 코퍼스 행 0, 이름 교체(서술 그대로)",
    ],
    "cosmo_amt": [
        "검증 REFUTED · 조치 1 · 리드 판정 (144) — 「ㆍ장기근속자 퇴직금」 라벨뿐 · 누진 · 가산 · 추가 지급 낱말 0(공시도 확정급여제도만) · 퇴직급여는 법정 기준선이고 severance_plus 는 법정 초과를 단언하는 코드",
        "감사 §2-11 — 같은 잣대(효성티앤씨 13 과 같음) · 2025 사업보고서 주석 「장기 근속 임직원에게 장기종업원급여」만 근거, 이름 교체(서술 그대로) · 70 장기근속자 포상/휴가(정본 라벨)와 다른 행 유지(판단 요청 2 · 검증)",
    ],
    "skc": [
        "검증 SUSPECT(문안) · 조치 1 — 40쪽 「각 조직이 자율적으로 Ground Rule을 수립·운영」의 원문 낱말을 항목 페이지 분류 때문에 뺐다 · 원문 보존이 먼저 · 분류는 예외(choose 빼고 team) — 리드 칸 결론 9, 문안 교체 그대로",
        "검증 SUSPECT(문안) · 조치 2 — 라이프 페이지 「SK그룹 mySUNI 수강 등 자기개발을 위한 다양한 Event」를 「수강」 낱말 때문에 뺐다 · 이 행이 왜 자기개발(복지)인지가 사라짐 · 문장 되살림(라이프 몫 각주 ②) · 분류는 예외(external 뺌), 문안 교체 그대로",
    ],
    "daejoo_electronic": [
        "검증 SUSPECT(문안) · 조치 1 — 정본 페이지 교육 표 이미지 「전체 인원 | 외국어 교육(영어, 일본어, 중국어)」(검증이 새로 받은 이미지 3장 중 1 · 「직원 역량강화 프로그램」 문단 바로 아래)가 꼬리 「교육 언어 미기재」와 어긋남, 문안 교체 그대로",
        "검증 MISSED · 조치 2 — 게시 중 공고(작성 2023-07-14 · 「채용중」) 복리후생 「휴일/휴가 : 주 5일 근무, 연차, 정기 휴가」 · 연차와 따로 적힌 이름 있는 휴가 = 계약 3-6 꼬리 「연차 사용일인지·일수·유급 여부 미기재」 · 새 time_off 섹션 머리 주석(검증 조치 2 글자) · VALUES 마지막 행, 완성 튜플 그대로",
    ],
    "hanall_biopharma": [
        "검증 REFUTED · 조치 1 — 41쪽 「연봉계약서 및 이사회 결의를 거쳐 … 18명(중복제외 시 14명)」 = 개인별 재량 부여(계약 3-7 · 어휘 「재량으로 고르는 부여는 복지가 아니다」) · 서술의 「2025년 6월 … 1,499주 처분」은 공시 부여 현황 표의 등기임원(대표이사) 몫(계약 3-5 임원 전용)",
    ],
    "ls_materials": [
        "검증 MISSED · 조치 1 — 복리후생 목록 「자기계발 지원 / 사내교육, 외국어 학원 등 지원」의 사내교육 몫 + 인재 육성 표 「사이버연수원(사내)」(학습 플랫폼 · 계약 3-9 「통째로 빼지 말 것」 · 코퍼스 오리온 · 차바이오텍 · 영원무역 · 이수페타시스 edu_support) · 판단 요청 1 · 3 기본안 뒤집음, 완성 튜플 그대로(growth SORT 10 뒤)",
    ],
})
_HDR_KEEP = ("—", "(머리말 참고 블록)", "고치지 않음",
             "계약 A 5 · B 7 — 참고 블록의 옛 문장은 고치지 않고 헤더 한 줄이 뒤집힘을 적는다(검증의 머리말 · 근거표 정정 권고 전부 — 근거표는 §14)")
KEEP.update({
    "dongwon_industries": [_HDR_KEEP,
                           ("10 · 20~23 · 30 · 31 · 40 · 50 · 60~63 · 70 · 71", "—", "「, 동원그룹 공통 문구」 각주 유지(추가 2행도 같은 각주)", "검증 판단 요청 4 · 계약 1-6 「자기 도메인 페이지 주어가 OO그룹 — 단서 없으면 가능(그룹 각주)」"),
                           ("10", "edu_support", "목요세미나 유지 · 독서교육 제외", "검증 판단 요청 1 — 초빙강의 = 특강 몫 · 독서교육은 필수 소양"),
                           ("—", "(INDUSTRY_NM)", "「식품」 유지", "검증 판단 요청 3 · 리드 칸 결론 1 — 별도 매출 수산 · 식품 본업 · 「지주회사」는 HD현대 1사와만 묶임")],
    "sgc_energy": [_HDR_KEEP,
                   (30, "child_edu", "유치원입학축하금을 학자금 서술에 유지", "검증 판단 요청 2 — 원문이 「자녀 학자금 지원」 항목 구성으로 적음"),
                   (70, "refresh_leave", "샌드위치데이 리프레쉬 유급휴가 맨 칩 유지", "검증 판단 요청 4 — 원문 「유급휴가 제공」 · 연차 낱말 없음"),
                   (80, "flex_work", "유지", "검증 판단 요청 5 — 공시 시차 사용자 3명 세 기간"),
                   (31, "parenting", "120 · 추정 유지", "검증 — 5~7세 자녀 월 10만원 보육수당 = 대상 집단 상시 월 지원(계약 3-3 ①) · 코퍼스 CJ 120")],
    "wonik_qnc": [_HDR_KEEP,
                  (41, "travel_support", "Refresh 해외배낭여행 한 행", "검증 판단 요청 1 — 코퍼스 배낭여행 3사 모두 travel_support · refresh_leave 맨 칩을 따로 세우면 전 직원 휴가로 읽힘"),
                  (55, "smoking_cessation", "금연클리닉 유지", "검증 판단 요청 3 — 최신 2026 보고서 56쪽이 운영 사실을 밝힘"),
                  (12, "excellence_award", "모범사원 특별상 유지", "검증 — 안전환경 부문은 기존 상에 덧붙인 것(㉙ 아님)")],
    "hyosung_tnc": [_HDR_KEEP,
                    (61, "mba", "국내외 학술연수자 학위과정 지원 유지", "검증 — 자기 도메인 현행 페이지 문장 · 반대 원문 없음(계약 3-5)"),
                    ("30 · 53 · 82 · 86", "—", "유지", "검증 판단 요청 1 · 4 · 6 · 7"),
                    ("—", "(지정 휴무일 · 리프레시 5일 연속 사용 권장)", "싣지 않음", "검증 판단 요청 8 — 본인 연차 사용 · 권장")],
    "ecopro_materials": [(70, "refresh_leave", "「본인 휴가」 문안 · 맨 칩 유지", "리드 칸 결론 9 — 원문 「개인연차」는 계약 3-11 「연차」 낱말 금지(허용 꼴 아님)라 바꾼 것 · 항목 페이지 분류 때문이 아님 · 뜻 같음(검증)"),
                         ("24 · 32 · 42 · 43", "—", "「(그룹 통합 채용 기준)」 맨 끝 유지", "검증 판단 요청 4 · 5 — 계약 3-5 ① 꼴(형제 에코프로비엠의 옛 꼴 「— 그룹 공통)」은 따르지 않음)"),
                         ("—", "(에코프로 주어 뉴스 2050 · 그룹 「건강증진 프로그램」 라벨)", "싣지 않음", "검증 판단 요청 1 · 2")],
    "cosmo_amt": [_HDR_KEEP,
                  ("12 · 13", "mba · conference", "Cyber MBA · 사외위탁교육 유지", "검증 판단 요청 3 · 4 — 판정 (132) · 코퍼스 사외 위탁 교육 = conference"),
                  (83, "stock_option", "우리사주 담보 제공 유지", "검증 — 주석이 「직원 우리사주조합」 담보를 밝힌 제도 문장(SK바이오사이언스 선례)")],
    "skc": [_HDR_KEEP,
            (21, "parenting", "어순 손질 유지(「3개월 유급화된 육아휴직」)", "검증 — 낱말이 빠지지 않고 뜻 같음 · 분류는 예외 leave_pay"),
            ("11 · 12 · 20 · 30 · 40 · 50 · 60 · 61 · 62", "—", "「, SKC Family 공통 문구」 각주 유지", "검증 판단 요청 4 · 계약 3-5 ② 꼴의 이름 자리에 페이지 자기 이름(「각 사별로」는 한 문장에만)"),
                (31, "club", "「(SKC · SK넥실리스 · SK피아이씨글로벌 · ISC 통합 보고 기준)」 유지", "검증 판단 요청 5 · 계약 3-5 ③")],
    "daejoo_electronic": [_HDR_KEEP,
                          ("34 · 52 · 90", "—", "공고만이 근거인 3행 유지", "검증 — 게시 중 공고(웨이브 9 (138) 마감 공고보다 강함) · 한시적 출처(§14-8)"),
                          ("22 · 32", "medical · snack_bar", "유지", "검증 판단 요청 3 · 4"),
                          ("40", "parenting", "꼬리 없음 유지", "검증 — 원문이 대상 · 금액을 다 밝혀 미기재 사항 없음(꼬리 0 은 게이트 위반 아님)")],
    "hanall_biopharma": [_HDR_KEEP,
                         ("30 · 31", "flex_work · remote_work", "「(조건부)」 유지", "검증 판단 요청 5 — 공시 주석 「특별 사유로 활용」"),
                         (60, "health_check", "2024 EHS 보고서 근거 유지", "검증 판단 요청 4 — ESG 메뉴에 지금 걸린 최신 EHS 판 · 같은 제도를 다르게 적은 더 새 문장 없음"),
                         ("—", "(resort 예외 후보 b86b5db850)", "넣지 않음", "검증 — 「그룹사콘도 도입」이 확보 방식을 밝히지 않음")],
    "gst": [(72, "parent_care", "효도 지원금 유지", "검증 판단 요청 1 — 원문 낱말 「효도」 · 대안 코드에 원문 낱말 0(§1-1)"),
            (71, "child_edu", "「자녀 학자금」 이름 유지", "검증 판단 요청 2"),
            ("—", "(선택근무제 · 기타장기종업원급여)", "싣지 않음", "검증 판단 요청 3 · 5")],
    "cs_wind": [(22, "housing_support", "관리비 지원 유지", "검증 판단 요청 1 — 생활 안정 지원 블록 · 코퍼스 관리비 2행 모두 주거"),
                (90, "welcome_kit", "정직원 순금 배지 유지", "검증 판단 요청 2"),
                ("33 · 71", "medical · conference", "유지", "검증 판단 요청 3 · 4")],
    "ls_materials": [_HDR_KEEP,
                     (50, "summer_leave", "하계휴가 (유급 5일) 유지", "검증 판단 요청 2"),
                     ("22 · 51", "long_service_bonus · long_service_leave", "두 행 유지", "검증 — 채용 사이트가 휴가 줄 · 포상 줄로 나눔(어휘 경계)")],
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




SIBLINGS = {  # 이번 회사 eng → 기등록 형제 · 같은 그룹 · 같은 업종 회사 표시명(정규식) — 코퍼스 240 + 이번 웨이브 안
    "dongwon_industries": r"동원|스타키스트",
    "sgc_energy": r"SGC|OCI|삼광|이테크",
    "wonik_qnc": r"원익|^WONIK",
    "hyosung_tnc": r"효성",
    "ecopro_materials": r"에코프로",
    "cosmo_amt": r"코스모|^GS",
    "skc": r"^SK|ISC|넥실리스",
    "daejoo_electronic": r"대주",
    "hanall_biopharma": r"대웅|한올",
    "gst": r"GST|글로벌스탠다드",
    "cs_wind": r"씨에스|CS ?WIND|CS베어링|씨에스베어링",
    "ls_materials": r"^LS|가온|엘에스",
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

    print("\n§consist ③ 형제 이중 등록 · 문장 겹침(10자 이상 조각 · 출처 괄호 · 꼬리 제외) — 코퍼스 240 + 웨이브 안 12")
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
        print(f"   {collect[e]['file']}: 형제 {len(sibs)}({', '.join(('웨이브10 ' if k.startswith('W9:') else '') + c['meta']['nm'] for k, c in sibs.items()) or '없음'}) · 겹친 조각 {len(hits)}")
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
    print(f"  코퍼스 업종 값 {len(inds)}종 · 관련 값 {sorted(i for i in inds if i and re.search('식품|지주|수산|화학|소재|배터리|전자|부품|반도체|제약|바이오|에너지|발전|기계|금속|전선|전력|장비', i))}")
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
    print(f"  stale(이 12사) {stale_all or 0}")
    from generator.pages.benefit import MIN_COMPANIES
    marks = json.load(open(WT + "/generator/data/row_marks.json", encoding="utf-8"))["rows"]
    marked = {(m["comp_eng_nm"], m["benefit_cd"]) for m in marks}
    print(f"\n  row_marks.json 에 이번 12사 eng 등록 {sorted({m['comp_eng_nm'] for m in marks if m['comp_eng_nm'] in collect}) or 0}")
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
            print(f"     {code}: 「{got}」 · 최다 {top} · 동률 이름 {len(tied)} · 이름 {len(cnt)} · 더 긴 후보 {longer} · 웨이브10 {'○' if code in wave_codes else '×'}"
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
    """코퍼스 240 + 모의본 12 를 한 폴더(W9/audit/tmp/combined)에 모아 리포 함수로 다시 본다 —
    어휘표 재생성(_vocab_scan) · build_company_meta(SI-13c 조건 칩 · SI-13d 이름 꼴) · 회사 수."""
    import shutil
    print("=" * 100)
    print("§combined 코퍼스 240 + 모의본 12 — 어휘표 · company_meta 재현")
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
        print(f"  이번 12사 aliases(지금 코드 — WAVE10 별칭 넣기 전) {aliases}")
        print(f"  이번 12사 work_style {{eng: ws}}:")
        for e in collect:
            print(f"     {e}: {ws[e]}")
    finally:
        cm.BENEFIT_SQL_DIR = old


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

