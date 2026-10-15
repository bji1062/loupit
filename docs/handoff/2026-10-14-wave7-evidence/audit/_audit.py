#!/usr/bin/env python3
"""웨이브 7 코퍼스 횡단 감사 — 재현 스크립트 (2026-10-14).

출발점: /home/ubuntu/loupit-evidence/2026-10-14-wave6/audit/_audit.py (웨이브 6 감사 — 조치 모델 · simulate · check-seed)
바꾼 것: 경로(W7 · 코퍼스 = 웨이브 7 worktree 시드 173파일 · 리포 모듈도 그 worktree 에서 import) · 어휘표(wave-lite 91종) ·
        행 점검기(wave-lite/_row_check.py) · 대상 22파일 · 조치 문자열은 _extract.json(검증 보고서 백틱 · JSON 기계 추출)에서 읽는다.
        조치 종류에 replace(필드 안 구절 교체) · 섹션 머리 주석 · 마지막 튜플 삭제를 더했다.

리포 모듈을 **실제로 import** 해서 돌린다(추측 금지 — 리포는 읽기만 · 바이트코드도 쓰지 않는다):
  db.seed.load._split_sql_statements            분할기(5문장 · 셋째 = UPDATE TCOMPANY SET CAREERS_BENEFIT_URL)
  db.seed.company_meta.parse_header_insert       등록 문장 파서 · ws_conditions · derive_work_style(근무형태 칩)
  generator.slug.slug_of                         slug
  db.seed.backfill_dec2._DATE_RE · _URL_RE · derive_amt_source   확인일 · 출처 URL · 금액 출처
  generator.benefit_rules load_pages · classify · text_hash · validate_all   항목 페이지(웨이브 6 예외까지 든 worktree 설정)
  generator.pages.find _most_common · LABEL_OVERRIDE                           /find 대표 이름
  wave-lite/_row_check.py check()                SI-9 · SI-11 · SI-12 · SI-13d · SI-B2 사전 점검(게이트와 같은 함수)
  /home/ubuntu/loupit-evidence/2026-10-02-recollect-3-7/_len_check.py  필드 길이 · 행 파서(parse_values)

사용:
  python3 -I _audit.py [섹션 ...]          섹션 없으면 all(actions 제외)
    fmt codes consist amt reg legal pages chips final combined actions simulate
  python3 -I _audit.py check-seed <폴더>   그 폴더의 22파일을 최종본 모델과 행 단위 · 전 필드 대조 → 「형식 문제 n · 불일치 n」
  python3 -I _audit.py search <정규식>     코퍼스 173파일 행(이름 · NOTE · 서술)에서 정규식 검색(주석 제외)
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

WT = "/home/ubuntu/loupit/.claude/worktrees/wave7"   # 웨이브 6 위에 쌓은 웨이브 7 worktree(읽기만)
W7 = "/home/ubuntu/loupit-evidence/2026-10-14-wave7"
LITE = "/home/ubuntu/loupit-evidence/wave-lite"
COLLECT = W7 + "/collect"
SIM = W7 + "/audit/sim"
CORPUS = WT + "/db/seed/benefit/sql"                  # 리드 칸: 이것 하나만 센다(173파일)
VOCAB = LITE + "/_VOCAB.md"
LEN_CHECK = "/home/ubuntu/loupit-evidence/2026-10-02-recollect-3-7/_len_check.py"
LEGAL_SCAN = WT + "/docs/handoff/2026-09-19-evidence/_legal_scan.py"
ROW_CHECK = LITE + "/_row_check.py"
EXTRACT = W7 + "/audit/_extract.json"

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

# 리드 칸 대상 22파일(1차 11 · 2차 11 — 리드 칸 순서)
FILES = ["보령", "HK이노엔", "SK바이오사이언스", "케이씨텍", "롯데정밀화학", "이노션", "현대엘리베이터", "교보증권", "F&F",
         "경동나비엔", "안랩",
         "두산테스나", "제일기획", "하나머티리얼즈", "코스메카코리아", "한샘", "롯데칠성음료", "롯데렌탈", "코리안리",
         "LX인터내셔널", "금호타이어", "코미코"]
MAXLEN = {"nm": 100, "note": 200, "qd": 500}  # db/schema.sql — BENEFIT_NM · NOTE_CTNT · QUAL_DESC_CTNT
META_MAX = {"eng": 30, "nm": 100, "ind": 50, "logo": 10, "url": 500}  # db/schema.sql TCOMPANY
CTGR = {"compensation", "health", "family", "leisure", "perks", "growth", "time_off", "flexibility", "work_env"}
HDR_INSERT = rc.HDR_INSERT
UPD = rc.UPD
TUPLE = re.compile(  # 원문 텍스트 안 튜플 위치(모의본 쓰기용) — 행 파서는 lc.parse_values 가 정본
    r"\(\s*@comp_id\s*,\s*'((?:[^']|'')*)'\s*,\s*'((?:[^']|'')*)'\s*,\s*(NULL|-?[\d.]+)\s*,\s*'([a-z_]+)'\s*,"
    r"\s*'([a-z_]+)'\s*,\s*(NULL|'(?:[^']|'')*')\s*,\s*(TRUE|FALSE)\s*,\s*(NULL|'(?:[^']|'')*')\s*,\s*(\d+)\s*\)",
    re.S)
ROSTER_NM = {  # eng(slug) → W7/dart/check-2026-10-14.json 의 키(리드 명단 이름 — 롯데칠성만 짧은 이름)
    "boryung": "보령", "hk_inno_n": "HK이노엔", "sk_bioscience": "SK바이오사이언스", "kctech": "케이씨텍",
    "lotte_fine_chem": "롯데정밀화학", "innocean": "이노션", "hyundai_elevator": "현대엘리베이터",
    "kyobo_securities": "교보증권", "fnf": "F&F", "kyungdong_navien": "경동나비엔", "ahnlab": "안랩",
    "doosan_tesna": "두산테스나", "cheil_worldwide": "제일기획", "hana_materials": "하나머티리얼즈",
    "cosmecca_korea": "코스메카코리아", "hanssem": "한샘", "lotte_chilsung": "롯데칠성", "lotte_rental": "롯데렌탈",
    "korean_re": "코리안리", "lx_international": "LX인터내셔널", "kumho_tire": "금호타이어", "komico": "코미코"}
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


# ── §5 조치 모델 (보고서 §5 와 1:1 — 통합 결과는 check-seed 로 이 모델과 대조한다) ─────────────────
# 종류: ("set", SORT, {필드: 값}) · ("replace", SORT, 필드, 옛 구절, 새 구절) · ("delete", SORT)
#       ("add", 행 dict, 섹션 머리 주석|None) · ("move", 옛 SORT, 새 행 dict, 섹션 머리 주석|None)
DATE = "2026-10-14"
ACTIONS: dict[str, list] = {
    "boryung": [],
    "hk_inno_n": [
        ("delete", 54),
        ("add", T("HK이노엔", 2), None),
        ("set", 24, dict(qd=X("HK이노엔", 4))),
        ("add", T("HK이노엔", 5), None),
        ("add", T("HK이노엔", 6), None),
    ],
    "sk_bioscience": [],
    "kctech": [
        ("add", T("케이씨텍", 0), None),
    ],
    "lotte_fine_chem": [
        ("set", 22, dict(qd=X("롯데정밀화학", 1))),
        ("set", 23, dict(qd=X("롯데정밀화학", 3))),
        ("set", 31, dict(qd=X("롯데정밀화학", 5))),
        ("add", T("롯데정밀화학", 6), SEC(X("롯데정밀화학", 7))),
    ],
    "innocean": [
        ("delete", 32),
        ("add", T("이노션", 3), SEC(X("이노션", 4))),
        ("set", 24, dict(nm=X("이노션", 7), qd=X("이노션", 8))),
    ],
    "hyundai_elevator": [
        ("set", 20, dict(nm=X("현대엘리베이터", 5), qd=X("현대엘리베이터", 7))),
    ],
    "kyobo_securities": [
        ("set", 70, dict(nm=X("교보증권", 2), qd=X("교보증권", 4))),
    ],
    "fnf": [
        ("add", T("F&F", 0), None),
        ("add", T("F&F", 1), None),
        ("set", 80, dict(note=X("F&F", 3))),
    ],
    "kyungdong_navien": [
        ("set", 20, dict(qd=X("경동나비엔", 1))),
        # 감사 §2-2(리드 판정 (119) 의 화면 이름을 22사에 맞춘다) — 아래 AUDIT_ACTIONS 에서 더한다
    ],
    "ahnlab": [
        ("delete", 12),
        ("set", 11, dict(nm=X("안랩", 3), qd=X("안랩", 4))),
        ("set", 90, dict(qd=X("안랩", 6))),
    ],
    "doosan_tesna": [],
    "cheil_worldwide": [
        ("set", 43, dict(qd=X("제일기획", 1))),
        ("set", 61, dict(qd=X("제일기획", 3))),
        ("set", 55, dict(qd=X("제일기획", 5))),
        ("add", T("제일기획", 6), None),
    ],
    "hana_materials": [
        ("set", 52, dict(qd=X("하나머티리얼즈", 3))),
        ("add", T("하나머티리얼즈", 4), None),
        ("add", T("하나머티리얼즈", 5), None),
    ],
    "cosmecca_korea": [
        ("move", 41, T("코스메카코리아", 5), SEC(X("코스메카코리아", 4))),
    ],
    "hanssem": [
        ("set", 10, dict(nm=X("한샘", 3))),
        ("replace", 10, "note", X("한샘", 6), X("한샘", 7)),
    ],
    "lotte_chilsung": [
        ("set", 11, dict(qd=X("롯데칠성음료", 1))),
        ("add", T("롯데칠성음료", 3), None),
    ],
    "lotte_rental": [
        ("delete", 82),
    ],
    "korean_re": [
        ("set", 11, dict(qd=X("코리안리", 3))),
        ("add", T("코리안리", 4), None),
        ("set", 13, dict(qd=X("코리안리", 6))),
        ("set", 70, dict(qd=X("코리안리", 8))),
        ("set", 71, dict(qd=X("코리안리", 10))),
    ],
    "lx_international": [
        ("delete", 13),
        ("replace", 11, "qd", X("LX인터내셔널", 4), X("LX인터내셔널", 5)),
        ("replace", 33, "qd", X("LX인터내셔널", 8), X("LX인터내셔널", 9)),
        ("add", T("LX인터내셔널", 11), None),
        ("add", T("LX인터내셔널", 12), None),
    ],
    "kumho_tire": [
        ("delete", 13),
        ("set", 60, dict(qd=X("금호타이어", 4))),
        ("add", T("금호타이어", 6), None),
        ("add", T("금호타이어", 7), None),
    ],
    "komico": [],
}

# 감사가 새로 더한 시드 조치(검증 보고서에 없는 것 — 근거는 보고서 §2 · §9). 문자열은 이 감사가 쓴 글자다.
AUDIT_ACTIONS: dict[str, list] = {}

# 정본 URL 교체(머리말 · INSERT · UPDATE 세 곳) — 검증 권고 · 리드 판정 (119)
URL_CHANGE: dict = {
    "hyundai_elevator": ("https://www.hyundaielevator.co.kr/ko/esg/storage/report", X("현대엘리베이터", 2)),
}
HEADER_EDIT: dict = {}  # 참고 블록의 옛 문장은 고치지 않는다(계약 B · A 5) — 헤더 한 줄이 뒤집힘을 적는다

# 항목 페이지 동반 조치(리드 집행 — generator/data/benefit_pages/<code>.json overrides)
#   검증 보고서의 JSON 을 기계로 뽑았다. h 는 모의 최종 문안으로 다시 계산해 대조한다(sec_pages).
OVERRIDES: list[tuple[str, dict]] = [
    ("event", J("보령", 2)),
    ("incentive", J("HK이노엔", 7)),
    ("lang", J("SK바이오사이언스", 3)),
    ("health_check", J("SK바이오사이언스", 4)),
    ("leave_general", J("SK바이오사이언스", 5)),
    ("housing_loan", J("케이씨텍", 2)),
    ("edu_support", J("롯데정밀화학", 12)),
    ("child_edu", J("이노션", 9)),
    ("mental", J("이노션", 10)),
    ("mental", J("현대엘리베이터", 10)),
    ("child_edu", J("현대엘리베이터", 13)),
    ("edu_support", J("현대엘리베이터", 16)),
    ("edu_support", J("교보증권", 8)),
    ("lang", J("F&F", 7)),
    ("edu_support", J("F&F", 8)),
    ("holiday_gift", J("경동나비엔", 2)),
    ("health_check", J("안랩", 8)),
    ("remote_work", J("두산테스나", 0)),
    ("fitness", J("하나머티리얼즈", 0)),
    ("remote_work", J("하나머티리얼즈", 1)),
    ("child_edu", J("한샘", 12)),
    ("edu_support", J("한샘", 13)),
    ("mental", J("롯데칠성음료", 7)),
    ("holiday_gift", J("롯데칠성음료", 9)),
    ("parenting", J("롯데칠성음료", 11)),
    ("remote_work", J("롯데렌탈", 3)),
    ("parenting", J("롯데렌탈", 5)),
    ("transport", J("롯데렌탈", 7)),
    ("long_service_leave", J("코리안리", 0)),
    ("edu_support", J("코리안리", 1)),
    ("parenting", J("금호타이어", 8)),
    ("discount", J("금호타이어", 9)),
]

HEADER_LINE: dict[str, str] = {}   # 아래 _header_lines() 가 채운다(최종 행 수를 모델에서 센다)
# §5 표의 「근거」 열 — ACTIONS + AUDIT_ACTIONS 순서(검증 보고서 조치 번호 · 리드 판정)
WHY: dict[str, list[str]] = {
    "hk_inno_n": [
        "검증 REFUTED · 조치 1 — 150쪽 「직무별 교육」 칸 직무 전문가 양성용 외부 교육 · 세미나와 R&D 직군 「권장」뿐(업무 교육 §3-9) · 회사 사외 교육비는 SORT 50 이 이미 받친다",
        "검증 MISSED M1 · 조치 2 — 152쪽 사내 공모 제도(사원이 스스로 지원하는 사내 이동 = 어휘 `career`), 완성 튜플 그대로",
        "검증 MISSED M2 · 조치 3 — 160쪽 「임신위험기 단축근로제의 기간을 법정 기간보다 확대」(원문이 법정분 · 회사분을 스스로 가름 — 상회분만 서술에), 교체 문안 그대로",
        "검증 MISSED M3 · 조치 4 — 160쪽 이 법인 주어 문장의 콜마 패밀리 데이 · 피크닉 참여 독려(행사 주최가 그룹이라는 사실은 서술에), 완성 튜플 그대로",
        "검증 MISSED M4 · 조치 5 — 151쪽 생산 직무 직무전문가 시상금(회사 포상 · 직군 한정은 이름에), 완성 튜플 그대로",
    ],
    "kctech": [
        "리드 판정 (117) · 검증 MISSED · 조치 1 — 기업문화 「가정의 날, 휴가의 날」 같은 문장의 이름 있는 단체 휴무(권장 근거는 HTML 주석뿐 — 공개 원문 아님), 완성 튜플 그대로(끝 쉼표는 집행 규약대로)",
    ],
    "lotte_fine_chem": [
        "검증 SUSPECT · 조치 1 — EZ러닝의 전화 · 화상 외국어 과정은 SORT 21 `lang` 몫과 되풀이(학습 플랫폼 어학 몫 = `lang`)",
        "검증 SUSPECT · 조치 2 — 73쪽 「주재원 양성PG 예비/귀임」은 글로벌 교육 줄의 교육 과정(업무 교육) — 사내 MBA · 핵심인재 학위과정만 남김",
        "검증 SUSPECT · 조치 3 — 원문이 용도(주택 관련)를 밝혔는데 꼬리가 「대출 용도 미기재」였다",
        "검증 MISSED M1 · 조치 4 — 43쪽 환경경영 절 임직원 제안 시스템 시상(어휘 `excellence_award` 「회사 포상 안의 … 제안 포상」), 완성 튜플 · 섹션 머리 주석 그대로",
    ],
    "innocean": [
        "검증 REFUTED · 조치 0 — 54쪽 Skill Track 「광고제 참관 프로그램」 = 업무 교육 · 55쪽 참관 결과 보고서 전사 공유(업무 출장)",
        "검증 MISSED M1 · 조치 1 — 57쪽 표 Culture Experience(해외 출장과 개인 휴가 연계 = 어휘 `leave_general` 「휴가 사용 방식」), 완성 튜플 · 섹션 머리 주석 그대로",
        "검증 MISSED M2 · 조치 2 — 57쪽 같은 문장의 힐링캠프(동호회 · 상담은 이미 행 — 같은 기준 §3-12) · 파트너사 내용은 옮기지 않음",
    ],
    "hyundai_elevator": [
        "검증 MISSED(병합) · 조치 2 — 111쪽 임직원 교육 현황 표 각주 「사내 공개 — 자율 입과」(자율 수강 과정 §3-9), 이름 · 문안 교체 그대로",
    ],
    "kyobo_securities": [
        "리드 판정 (119) · 검증 SUSPECT · 조치 1 — 반반차의 화면 이름은 사용자 결정 「2시간 단위 휴가」(항목 페이지 `hourly` 면이 켜진다)",
    ],
    "fnf": [
        "리드 판정 (118) · 검증 MISSED M1 · 조치 1 — 자기 도메인 「우리의 문화」 복지 연재(지금 메뉴 안 게시) 자사 브랜드 · 관계사 할인, 완성 튜플 그대로",
        "리드 판정 (118) · 검증 MISSED M2 · 조치 2 — 같은 연재 「모든 임직원에게 허먼밀러 의자 제공」, 완성 튜플 그대로",
        "리드 판정 (118) · 검증 MISSED M3 · 조치 3 — FLUNCH DAY 를 식대 행 서술에(맞는 코드 없음 — 점심시간 선례) · 출처 괄호에 「항목」 · 금액 288 · 식대 꼬리 유지(197자)",
    ],
    "kyungdong_navien": [
        "검증 SUSPECT · 조치 1 — 보조 인용 72쪽 「임직원 건강진단」은 산업안전보건법 용어 그대로(법정 검진과 가를 수 없음 §3-2) — 정본 구절만",
    ],
    "ahnlab": [
        "검증 SUSPECT · 조치 1 — 「주택 관련 자금 및 생활안정자금 대출」 한 문장 · 한 라벨 = 어휘 경계 「주택 대출과 한 라벨이면 `housing_loan`」 → SORT 12 를 지운다",
        "검증 조치 1 — SORT 12 를 받는 행의 이름 · 문안 교체 그대로",
        "검증 SUSPECT · 조치 2 — 공시 각주상 834 · 142 는 자율출퇴근제 · 탄력근무제 **대상 인원**(사용자 수 아님)",
    ],
    "cheil_worldwide": [
        "검증 SUSPECT · 조치 1 — 78쪽 스카이박스 대관은 GWP · 고객 Hospitality · CSR 를 묶은 문장이라 임직원 몫이 아니다 — 걷는다",
        "검증 SUSPECT · 조치 2 — 77쪽 한 칸의 질병/상해보험(단체보험 상품)은 `insurance` 로 가른다(실손만 `medical` — 어휘 경계)",
        "검증 MISSED M2 · 조치 3 — 69쪽 표가 법정 기간 줄과 12~32주 줄을 스스로 나눔(법정 밖 기간 확대분), HK이노엔 M2 와 같은 결",
        "검증 MISSED M1 · 조치 4 — 77쪽 「질병/상해보험」 → `insurance` 새 행, 완성 튜플 그대로",
    ],
    "hana_materials": [
        "검증 SUSPECT · 조치 1 — 「지급할 수 있음」을 단언(「지급」)으로 바꾼 문안 — 「지급 가능」으로",
        "검증 MISSED · 조치 2 — 61쪽 「지역 상권 연계 사내 복지포인트 사용처 확대」 = 포인트 존재를 전제하는 문장(계획 표라는 이유로 축을 비우지 않는다), 완성 튜플 그대로",
        "리드 판정 (124) · 검증 MISSED · 조치 3 — 회사가 여는 어학 강좌 = 복지(사용자 기준) · 선발 조건은 이름 · 서술에, 완성 튜플 그대로",
    ],
    "cosmecca_korea": [
        "리드 판정 (122) · 검증 SUSPECT · 조치 1 — 「상급학교」 = 직원 본인 진학 학비(코퍼스 「상급학교」 행 = 한미약품 2행 모두 본인) · 원문에 없는 「자녀」를 붙이지 않는다 → growth 새 섹션 SORT 90, 튜플 · 섹션 머리 주석 그대로",
    ],
    "hanssem": [
        "검증 SUSPECT · 조치 1 — 이름의 맨 「육아휴직」은 법정 제도 이름 — 원문이 법정 상회라 밝힌 「최장 2년」을 이름에",
        "검증 SUSPECT · 조치 2 — 85쪽 「임신 전 과정에서 급여 삭감 없는 단축 근무」 = 법정 창(12주 이내 · 32주 이후) 밖 기간 확대(상회분) · NOTE 183자 · 금액 120 · 환산 꼬리 유지",
    ],
    "lotte_chilsung": [
        "리드 판정 (123) · 검증 조치 1 — 95쪽 출산 열 「배우자 출산 휴가 의무화」를 같은 행에 「의무」만 병합(법정 일수 없음)",
        "검증 MISSED · 조치 2 — 38쪽 Scope3 「임직원 통근 통근버스 운행 일지」 = 회사가 통근버스를 운행한다는 공개 원문(HK이노엔 SORT 15 와 같은 근거 꼴), 완성 튜플 그대로",
    ],
    "lotte_rental": [
        "검증 REFUTED · 조치 1 — 47쪽 표 이름만 「업무상 병가 의료비 지원」 = 근로기준법 78조 요양보상 · 산재(법정이 이름만 규칙보다 앞선다) · VALUES 마지막 튜플이라 앞 튜플 쉼표도 지운다",
    ],
    "korean_re": [
        "검증 SUSPECT · 조치 1 — 정본 블록의 근로복지기금 출연은 경조금과 다른 제도(어휘 `welfare_fund`) → 경조금 행에서 걷는다",
        "검증 조치 1 — 걷은 근로복지기금을 perks SORT 23 새 행으로, 완성 튜플 그대로",
        "검증 SUSPECT · 조치 2 — 자기 도메인 ESG 사회 출산장려정책(헤더 메뉴 안 · 지금 게시)의 연 500만원 한도 · 난자 냉동 70% 구절(한도라 금액 NULL 유지)",
        "검증 SUSPECT · 조치 3 — 최신 반기보고서(기재정정) 시차출퇴근 417 · 선택근무 5 — 「제도 유형 미기재」 꼬리가 거짓이 됐다",
        "검증 조치 4 — 같은 공시 원격근무제 사용자 27명 보강",
    ],
    "lx_international": [
        "검증 REFUTED · 조치 1 — 72쪽 기타직무교육 행의 「직무별 사외 교육 / 국내외 세미나」(직무 교육 체계의 한 칸 §3-9)",
        "검증 SUSPECT · 조치 2 — 꼬리 「수강료 본인 부담」은 원문에 없는 사실 단언 → 「수강료 지원 범위」",
        "검증 병합 · 조치 3 — 73쪽 조직문화 프로그램 운영의 팀 단위 워크숍 지원(조직문화 절 행사는 걷지 않는다)",
        "검증 MISSED · 조치 4 — 89쪽 안전보건 절 금연 클리닉(어휘 `smoking_cessation`), 완성 튜플 그대로",
        "검증 MISSED · 조치 5 — 89쪽 본사 건강관리실(법정 열거 밖 — 「산안법 성격」으로 거르지 않는다 · 자회사 의무실은 뺌), 완성 튜플 그대로",
    ],
    "kumho_tire": [
        "검증 REFUTED · 조치 1 — 74쪽 교육 표 전문 열의 「개인사외교육」(직무 전문 교육 체계의 한 칸 §3-9)",
        "리드 메모 기본안 · 검증 SUSPECT · 조치 2 — 융자 쪽만 남긴다(이름 「주택구입·임차 자금 융자」 그대로)",
        "리드 메모 기본안 · 검증 조치 2 — 지점근무 임차금 지원(대출 낱말 없음 · 직군 한정) = `housing_support` 새 행, 완성 튜플 그대로",
        "검증 MISSED · 조치 3 — 71쪽 동등급여 표 주석 「연봉총액은 기본급과 인센티브를 합하여 산출」(지표 정의 성과급 원천 §3-7), 완성 튜플 그대로",
    ],
}

# §5 「바꾸지 않는 것」 — 검증 권고 · 판단 요청 가운데 집행하지 않거나 그대로 두는 것(시드 밖 조치는 §10 · §14)
_HDR_KEEP = ("—", "(머리말 참고 블록)", "고치지 않음",
             "계약 A 5 · B 7 — 참고 블록의 옛 문장은 고치지 않고 헤더 한 줄이 뒤집힘을 적는다(검증의 머리말 정정 권고 전부)")
KEEP: dict[str, list[tuple]] = {
    "boryung": [(72, "leave_general", "유지(연말 Shut down · 질병휴직)", "검증 판단 요청 1 확정")],
    "hk_inno_n": [_HDR_KEEP, (61, "club", "금액 36(추정) 유지", "리드 메모 · 검증 — 누구나 드는 제도라 조건부 아님 · 월액 × 12"),
                  (81, "remote_work", "「(조건부)」 유지", "장애인 대상 꼴이 정해진 꼴에 없어 맨 칩 누수를 막는 유일한 꼴")],
    "sk_bioscience": [(80, "stock_option", "유지", "검증 판단 요청 1 — 주석 문장(담보 제공)이 조합 지원 사실")],
    "kctech": [_HDR_KEEP, (91, "family_day", "유지", "검증 판단 요청 2 · 리드 판정 (117) 같은 문장 같은 기준")],
    "lotte_fine_chem": [_HDR_KEEP, (51, "parenting", "남성 의무 육아휴직 유지", "리드 판정 (123) 과 같은 결")],
    "innocean": [_HDR_KEEP, ("—", "(임신 안정화 휴직)", "싣지 않음", "검증 — 남녀고용평등법 19조 임신 중 육아휴직과 목적 같음 · 상회분 없음")],
    "hyundai_elevator": [(12, "welfare_fund", "유지", "검증 판단 요청 1 — 생활안정자금 쪽은 원문에 대출 낱말 없음")],
    "kyobo_securities": [(22, "remote_work", "「(조건부)」 유지", "공시 주석 「재택근무 부분적 허용」"),
                         (81, "birthday_gift", "금액 5(stated) 유지", "원문 「5만 원 … 포인트」 · 연 1회")],
    "fnf": [_HDR_KEEP],
    "kyungdong_navien": [(11, "leave_general", "이름 「시간 단위 휴가」 유지", "감사 §2-2 — 원문이 「시간 단위 휴가」로 적었다(리드 판정 (119) 의 「회사가 밝힌 단위」 꼴) · 항목 페이지 `hourly` 켜짐 · 코퍼스 같은 이름 5사")],
    "ahnlab": [(40, "insurance", "유지", "감사 §2-3 — 상품 이름이 단체 상해 보험 · 코퍼스 효성중공업 같은 꼴")],
    "cheil_worldwide": [(25, "retirement_support", "유지", "직원 1,538 이지만 행 문장은 퇴직 후 · 재직 중 상시 · 유급 휴가뿐(법정 밖)"),
                        ("—", "(원격근무)", "싣지 않음", "리드 판정 (120)")],
    "hana_materials": [_HDR_KEEP, (50, "excellence_award", "이름 「자랑스러운 하나인 상」 유지", "검증 판단 요청 1 확정")],
    "cosmecca_korea": [_HDR_KEEP],
    "hanssem": [_HDR_KEEP, ("—", "(전직지원 프로그램 retirement_support)", "**추가하지 않음**", "리드 판정 (125) — 검증 보고서의 기각(집행 금지) 튜플")],
    "lotte_chilsung": [_HDR_KEEP, (91, "remote_work", "유지", "리드 판정 (120)")],
    "lotte_rental": [_HDR_KEEP, (30, "parenting", "남성 육아휴직 의무화 유지", "리드 판정 (123) — 검증 문안 교체 권고 철회")],
    "korean_re": [_HDR_KEEP],
    "lx_international": [_HDR_KEEP, (71, "remote_work", "유지", "리드 판정 (120)")],
    "kumho_tire": [_HDR_KEEP, (40, "medical", "생계비 병합 유지", "검증 판단 요청 3 확정")],
}


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
            if sort in want and sort in orig and want[sort]["cd"] == orig[sort]["cd"]:
                if want[sort] != orig[sort]:
                    t = t[:s] + render_tuple(want[sort]).lstrip() + t[e:]
            else:  # 삭제(또는 같은 SORT 에 다른 코드가 들어오는 이동 — 이번 웨이브엔 없음)
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


_H = "-- 검증 · 감사 판정 반영(2026-10-14): "
HEADER_TEXT: dict[str, str] = {  # 회사별 헤더 한 줄 — 따옴표 없음 · 최종 행 수는 모델에서 센다({N})
    "boryung": _H + "행 조치 없음 · 경조사 행 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 {N}행",
    "hk_inno_n": _H + "직무별 외부 교육 · 세미나 conference 삭제(업무 교육) · 사내 공모 제도 career · 콜마 패밀리 데이 company_event · 직무전문가 시상 excellence_award 추가 · 160쪽 임신위험기 단축 확대분을 parenting 서술에 병합(참고 블록 법정 제외 줄의 임신 위험기간 단축근로제는 법정 기간분만 남는다) — 최종 {N}행",
    "sk_bioscience": _H + "행 조치 없음 · 항목 페이지 예외 3(통합 밖 리드 집행) — 최종 {N}행",
    "kctech": _H + "기업문화 페이지 휴가의 날 leave_general 추가(리드 판정 117 — 참고 블록의 휴가의 날 판단 요청 줄은 이 판정으로 뒤집힘 · 복지 블록 수는 14) — 최종 {N}행",
    "lotte_fine_chem": _H + "EZ러닝 행에서 외국어 과정 구절 걷기(lang 행과 중복) · MBA 행에서 주재원 양성 프로그램 걷기(업무 교육) · 주택 관련 대출 꼬리 정정 · 43쪽 임직원 제안 시상 excellence_award 추가(compensation SORT 90) — 최종 {N}행",
    "innocean": _H + "광고제 참관 conference 삭제(업무 교육 Skill Track) · Culture Experience 해외 출장 연계 휴가 leave_general 추가(time_off SORT 80) · 힐링캠프를 company_event 행에 병합(참고 블록 제외 줄의 Culture Experience · 힐링캠프는 이 판정으로 뒤집힘) — 최종 {N}행",
    "hyundai_elevator": _H + "정본 URL 을 2025-26 ESG 보고서 PDF 직접 주소로 교체(리드 판정 119) · 111쪽 사내 공개 교육 과정을 직무 CoP 행에 병합 — 최종 {N}행",
    "kyobo_securities": _H + "반반차 행 이름 · 서술을 2시간 단위 휴가로(리드 판정 119) — 최종 {N}행",
    "fnf": _H + "자기 도메인 우리의 문화 복지 연재를 보조 출처로(리드 판정 118) 자사 브랜드 · 관계사 할인 discount · 허먼밀러 의자 office_furniture 추가 · FLUNCH DAY 를 식대 행 서술에 보탬 — 최종 {N}행",
    "kyungdong_navien": _H + "건강검진 행에서 법정 건강진단 구절 걷기 — 최종 {N}행",
    "ahnlab": _H + "생활안정자금 대출 welfare_fund_loan 행을 주택 관련 자금 대출 housing_loan 행에 병합(한 라벨) · 유연근무 행 공시 수치를 대상 인원으로 정정 — 최종 {N}행",
    "doosan_tesna": _H + "행 조치 없음 · 원격근무 행 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 {N}행",
    "cheil_worldwide": _H + "77쪽 질병 · 상해보험을 insurance 로 갈라 추가(medical 은 실손만) · 69쪽 임신 12주~32주 확대분을 parenting 서술에 병합 · 스포츠 구단 행에서 스카이박스 대관 걷기 — 최종 {N}행",
    "hana_materials": _H + "성과급 서술 단언 정정 · 지역 상권 연계 사내 복지포인트 welfare_point · 선별교육 외국어 강좌 lang 추가(리드 판정 124 — 참고 블록 제외 줄의 두 구절은 이 판정으로 뒤집힘) — 최종 {N}행",
    "cosmecca_korea": _H + "상급학교 학비 지원을 child_edu 에서 self_development 로 재코딩(리드 판정 122 · growth SORT 90) — 최종 {N}행",
    "hanssem": _H + "육아 행 이름에 육아휴직 최장 2년 · NOTE 에 보고서의 임신 전 과정 단축 근무 병합(참고 블록 법정 제외 줄의 임산부 단축근무는 정본 구절만 남는다) · 전직지원 프로그램은 법정 재취업지원이라 행 없음 유지(리드 판정 125) — 최종 {N}행",
    "lotte_chilsung": _H + "육아 행 서술에 배우자 출산 휴가 의무화 병합(리드 판정 123 — 참고 블록 법정 제외 줄의 같은 구절은 이 판정으로 뒤집힘) · 38쪽 Scope3 통근버스 운행 commute_subsidy 추가 — 최종 {N}행",
    "lotte_rental": _H + "업무상 병가 의료비 medical 삭제(법정 요양보상 · 산재) · 남성 육아휴직 의무화는 유지(리드 판정 123) — 최종 {N}행",
    "korean_re": _H + "경조금 행에서 근로복지기금 출연을 welfare_fund 로 갈라 추가 · 난임 지원 행에 자기 도메인 출산장려정책의 한도 구절 보탬 · 유연근무 · 원격근무 행에 반기보고서 사용자 수 보탬 — 최종 {N}행",
    "lx_international": _H + "직무별 사외 교육 · 세미나 conference 삭제(업무 교육) · 어학 행 꼬리 정정 · 팀 단위 워크숍을 행사 행에 병합(참고 블록 제외 줄의 팀 단위 워크숍은 이 판정으로 뒤집힘) · 89쪽 금연 클리닉 smoking_cessation · 본사 건강관리실 clinic 추가 — 최종 {N}행",
    "kumho_tire": _H + "개인사외교육 conference 삭제(업무 교육) · 국내영업 지점근무 주택 임차금 지원을 housing_support 로 갈라 추가 · 71쪽 동등급여 표 주석의 인센티브 incentive 추가 — 최종 {N}행",
    "komico": _H + "행 조치 없음 — 최종 {N}행",
}
assert set(HEADER_TEXT) == set(ROSTER_NM)

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


SIBLINGS = {  # 이번 회사 eng → 기등록 형제 회사 표시명(정규식) — 코퍼스(웨이브 6 포함 173) + 이번 웨이브 안
    "boryung": r"보령",
    "hk_inno_n": r"콜마|HK",
    "sk_bioscience": r"^SK",
    "kctech": r"케이씨|^KC(?!C)",
    "lotte_fine_chem": r"롯데",
    "innocean": r"^(현대자동차|기아|현대모비스|현대글로비스|현대건설|현대제철|현대로템|현대오토에버|현대위아)$",
    "hyundai_elevator": r"현대무벡스|현대엘리베이터",
    "kyobo_securities": r"교보",
    "fnf": r"F&F|에프앤에프",
    "kyungdong_navien": r"경동",
    "ahnlab": r"안랩",
    "doosan_tesna": r"두산",
    "cheil_worldwide": r"^삼성|에스원",
    "hana_materials": r"하나",
    "cosmecca_korea": r"코스메카",
    "hanssem": r"한샘",
    "lotte_chilsung": r"롯데",
    "lotte_rental": r"롯데",
    "korean_re": r"코리안리",
    "lx_international": r"^LX",
    "kumho_tire": r"금호",
    "komico": r"미코",
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
    print("§consist ① 각주 세 꼴 — 근거표 위험 표시상 그룹 통합 채용 근거 행이 있는 회사는 경동나비엔 3행(12 · 13 · 81)뿐")
    for e in collect:
        for r in final[e]:
            t = r["qd"] or r["note"] or ""
            if FOOTNOTE.search(t) or "kdfamily" in t or "그룹 채용" in t or "통합 채용" in t:
                tail = rc.dash_tail_breaks(t)
                ends = t.rstrip().endswith("(그룹 통합 채용 기준)")
                print(f"   {collect[e]['file']}\tSORT {r['sort']}\t{r['cd']}\t각주={bool(FOOTNOTE.search(t))}\t맨끝={ends}\tSI-11깨짐={tail}\t…{t[-90:]}")
    n_other = sum(1 for e in collect if e != "kyungdong_navien" for r in final[e] if FOOTNOTE.search(r["qd"] or r["note"] or ""))
    print(f"   경동나비엔 밖 각주 낱말 행 {n_other}")

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

    print("\n§consist ③ 형제 이중 등록 · 문장 겹침(10자 이상 조각 · 출처 괄호 · 꼬리 제외) — 코퍼스 173 + 웨이브 안 22")
    wave = {e: dict(meta=collect[e]["meta"], rows=final[e], file=collect[e]["file"]) for e in collect}
    pool = dict(corpus)
    for e, v in wave.items():
        pool["W7:" + e] = v
    for e in collect:
        pat_s = re.compile(SIBLINGS[e])
        sibs = {x: c for x, c in pool.items() if x != "W7:" + e and pat_s.search(c["meta"]["nm"])}
        sib_text = " ".join(rtext(r) for c in sibs.values() for r in c["rows"])
        hits = []
        for r in final[e]:
            for f in _fragments(r["qd"] or r["note"]):
                if f in sib_text:
                    hits.append((r["sort"], r["cd"], f))
        print(f"   {collect[e]['file']}: 형제 {len(sibs)}({', '.join(('웨이브7 ' if k.startswith('W7:') else '') + c['meta']['nm'] for k, c in sibs.items()) or '없음'}) · 겹친 조각 {len(hits)}")
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

    print("\n§consist ⑥ 웨이브 7 경계 축 — 시간 단위 휴가 이름 · 의무화 · conference · 원격 · 보험/의료비 · 재취업 · 대출/기금 · 임신기 단축")
    probes = [
        ("반반차·시간 단위 휴가", r"시간 단위|반일의 절반|반반차"),
        ("육아휴직·배우자 출산휴가 의무화", r"의무화|의무 육아|의무 사용"),
        ("conference 행", None),
        ("remote_work 행", None),
        ("insurance · medical 행", None),
        ("retirement_support 행", None),
        ("welfare_fund · welfare_fund_loan · housing_loan · housing_support 행", None),
        ("임신기 단축 상회분", r"임신.{0,12}(단축|휴게)|예비맘"),
        ("Scope3 · 통근버스 근거", r"Scope ?3|통근 버스|통근버스"),
    ]
    for label, rx in probes:
        print(f"   [{label}]")
        for e in collect:
            for r in final[e]:
                t = rtext(r)
                hit = False
                if rx and re.search(rx, t):
                    hit = True
                if label.startswith("conference") and r["cd"] == "conference":
                    hit = True
                if label.startswith("remote_work") and r["cd"] in ("remote_work", "telecommute", "wfh"):
                    hit = True
                if label.startswith("insurance") and r["cd"] in ("insurance", "medical"):
                    hit = True
                if label.startswith("retirement") and r["cd"] == "retirement_support":
                    hit = True
                if label.startswith("welfare_fund") and r["cd"] in ("welfare_fund", "welfare_fund_loan", "housing_loan", "housing_support"):
                    hit = True
                if hit:
                    print(f"      {collect[e]['file']}\tSORT {r['sort']}\t{r['cd']}\t「{r['nm']}」\t…{(r['qd'] or r['note'])[:150]}")


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
    dart = json.load(open(W7 + "/dart/check-2026-10-14.json", encoding="utf-8"))
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
    print(f"  코퍼스 업종 값 {len(inds)}종 · 관련 값 {sorted(i for i in inds if i and re.search('광고|마케팅|미디어|패션|의류|섬유|가구|인테리어|생활|렌탈|자동차|리스|유통', i))}")
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
            open(W7 + "/audit/tmp/legal_scan_sim.txt", "w", encoding="utf-8").write(out)
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
    fk = {"nm": "BENEFIT_NM", "amt": "BENEFIT_AMT", "ctgr": "BENEFIT_CTGR_CD", "note": "NOTE_CTNT",
          "qual": "QUAL_YN", "qd": "QUAL_DESC_CTNT", "sort": "SORT_ORDER_NO"}
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
                    kind = "이름 · 문안 교체" if "nm" in a[2] and ("qd" in a[2] or "note" in a[2]) else ("이름 교체" if "nm" in a[2] else "문안 교체")
                    print(f"| {n} | {a[1]} `{by_sort[a[1]]['cd']}` | {kind} | {w} |")
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
                    print(f"- **#{n} SORT {a[1]} `{by_sort[a[1]]['cd']}`** — 적힌 필드만 바꾼다")
                    for k, v in a[2].items():
                        print(f"  - `{fk[k]}` = `{sv(v) if isinstance(v, str) else v}`")
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
    """코퍼스 173 + 모의본 22 를 한 폴더(W7/audit/tmp/combined)에 모아 리포 함수로 다시 본다 —
    어휘표 재생성(_vocab_scan) · build_company_meta(SI-13c 조건 칩 · SI-13d 이름 꼴) · 회사 수."""
    import shutil
    print("=" * 100)
    print("§combined 코퍼스 173 + 모의본 22 — 어휘표 · company_meta 재현")
    d = W7 + "/audit/tmp/combined"
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
        print(f"  이번 22사 aliases(지금 코드 — WAVE7 별칭 넣기 전) {aliases}")
        print(f"  이번 22사 work_style {{eng: ws}}:")
        for e in collect:
            print(f"     {e}: {ws[e]}")
    finally:
        cm.BENEFIT_SQL_DIR = old


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
