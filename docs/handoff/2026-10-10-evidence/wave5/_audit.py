#!/usr/bin/env python3
"""웨이브 5 코퍼스 횡단 감사 — 재현 스크립트 (2026-10-10).

출발점: /home/ubuntu/loupit/docs/handoff/2026-09-19-evidence/wave4/_audit.py · _precheck.py
        /home/ubuntu/loupit-evidence/2026-09-26-recollect/audit/_audit.py (조치 모델 · simulate · check-seed)

리포 모듈을 **실제로 import** 해서 돌린다(추측 금지 — 리포는 읽기만):
  db.seed.load._split_sql_statements            분할기(5문장 · 셋째 = UPDATE TCOMPANY SET CAREERS_BENEFIT_URL)
  db.seed.company_meta.parse_header_insert       등록 문장 파서 · ws_conditions · derive_work_style(근무형태 칩)
  generator.slug.slug_of                         slug
  db.seed.backfill_dec2._DATE_RE · _URL_RE · derive_amt_source   확인일 · 출처 URL · 금액 출처
  generator.benefit_rules load_pages · classify · text_hash · validate_all   항목 페이지
  server.source_check.parse_robots              옛 robots 목록 줄(W5-17)
  W5/_row_check.py check()                       SI-9 · SI-11 · SI-12 · SI-13d · SI-B2 사전 점검(게이트와 같은 함수)
  /home/ubuntu/loupit-evidence/2026-10-02-recollect-3-7/_len_check.py  필드 길이 · 행 파서(parse_values)

사용:
  python3 _audit.py [섹션 ...]          섹션 없으면 all
    fmt      수집본 · 모의본 형식(분할기 · 머리말 · 등록 · slug · 표시명 · 길이 · 따옴표)
    codes    신규 코드(어휘표 89종 · 코퍼스 실사용 대비)
    consist  W5-10 성과급 꼴 표 · 그룹 각주 꼴 표 · 형제 등록 점검
    amt      금액 전수(예측 금액 출처) · 회사별 합
    reg      등록 값 표 · 업종 합류 · corp_code 대조
    robots   옛 robots 목록 줄(W5-17) — 12 정본 호스트 사본 · parse_robots
    legal    _legal_scan.py 를 모의본에 돌린 결과 요약
    pages    항목 페이지 예외(모의 최종 문안 해시) · validate_all · MIN_COMPANIES 문턱 · /find 대표 이름
    chips    derive_work_style 회사별 결과
    actions  §5 본문(집행형) — 조치 모델에서 글자 그대로 찍는다
    final    최종 행 수 · 핀
    simulate 조치 모델을 수집본 텍스트에 적용해 W5/audit/sim/<파일명>.sql 를 쓰고 check-seed 로 자가 시험
  python3 _audit.py check-seed <폴더>   그 폴더의 13파일을 최종본 모델과 행 단위 · 전 필드 대조 → 「형식 문제 n · 불일치 n」
"""
from __future__ import annotations

import collections
import copy
import glob
import hashlib
import importlib.util
import json
import os
import re
import subprocess
import sys

REPO = "/home/ubuntu/loupit"
W5 = "/home/ubuntu/loupit-evidence/2026-10-10-wave5"
COLLECT = W5 + "/collect"
SIM = W5 + "/audit/sim"
CORPUS = REPO + "/db/seed/benefit/sql"
VOCAB = W5 + "/_VOCAB.md"
LEN_CHECK = "/home/ubuntu/loupit-evidence/2026-10-02-recollect-3-7/_len_check.py"
LEGAL_SCAN = REPO + "/docs/handoff/2026-09-19-evidence/_legal_scan.py"
ROW_CHECK = W5 + "/_row_check.py"

sys.path.insert(0, REPO)
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

# 계약 「웨이브 5 전용」 대상 13파일(리드 프롬프트 순서)
FILES = ["오뚜기", "KCC", "한솔케미칼", "오리온", "GS건설", "현대해상", "한온시스템",
         "에스엘", "코오롱인더", "산일전기", "ISC", "한국콜마", "코스맥스"]
MAXLEN = {"nm": 100, "note": 200, "qd": 500}  # db/schema.sql — BENEFIT_NM · NOTE_CTNT · QUAL_DESC_CTNT
META_MAX = {"eng": 30, "nm": 100, "ind": 50, "logo": 10, "url": 500}  # db/schema.sql:36-43
CTGR = {"compensation", "health", "family", "leisure", "perks", "growth", "time_off", "flexibility", "work_env"}
HDR_INSERT = rc.HDR_INSERT
UPD = rc.UPD
TUPLE = re.compile(  # 원문 텍스트 안 튜플 위치(모의본 쓰기용) — 행 파서는 lc.parse_values 가 정본
    r"\(\s*@comp_id\s*,\s*'((?:[^']|'')*)'\s*,\s*'((?:[^']|'')*)'\s*,\s*(NULL|-?[\d.]+)\s*,\s*'([a-z_]+)'\s*,"
    r"\s*'([a-z_]+)'\s*,\s*(NULL|'(?:[^']|'')*')\s*,\s*(TRUE|FALSE)\s*,\s*(NULL|'(?:[^']|'')*')\s*,\s*(\d+)\s*\)",
    re.S)


# ── 파싱 ─────────────────────────────────────────────────────────────────────
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
            r = dict(zip(cols, tup))
            amt = r.get("BENEFIT_AMT")
            rows.append(dict(cd=r["BENEFIT_CD"], nm=r["BENEFIT_NM"],
                             amt=None if amt is None else int(float(amt)),
                             ctgr=r["BENEFIT_CTGR_CD"], badge=r["BADGE_CD"], note=r.get("NOTE_CTNT"),
                             qual=(r.get("QUAL_YN") == "TRUE"), qd=r.get("QUAL_DESC_CTNT"),
                             sort=int(r["SORT_ORDER_NO"])))
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


def load_corpus() -> dict:
    out = {}
    for f in sorted(glob.glob(CORPUS + "/*.sql")):
        t = open(f, encoding="utf-8").read()
        body = re.sub(r"^\s*--.*$", "", t, flags=re.M)
        m = re.search(r"VALUES\s*\(\s*'([^']+)',\s*'([^']+)',\s*\(SELECT[^)]*'([a-z]+)'\)\s*,\s*"
                      r"(NULL|'[^']*')\s*,\s*(NULL|'[^']*')\s*,\s*(NULL|'[^']*')", t)
        u = lambda x: None if x == "NULL" else x[1:-1]  # noqa: E731
        meta = dict(eng=m.group(1), nm=m.group(2), tp=m.group(3), ind=u(m.group(4)), logo=u(m.group(5)),
                    url=u(m.group(6)))
        rows = []
        for r in TUPLE.finditer(body):
            cd, nm, amt, ctgr, badge, note, qual, qd, sort = r.groups()
            rows.append(dict(cd=cd, nm=nm.replace("''", "'"), amt=None if amt == "NULL" else int(float(amt)),
                             ctgr=ctgr, badge=badge, note=u(note), qual=(qual == "TRUE"), qd=u(qd), sort=int(sort)))
        out[meta["eng"]] = dict(file=os.path.basename(f)[:-4], meta=meta, rows=rows, text=t)
    return out


def vocab_table() -> dict:
    out = {}
    for line in open(VOCAB, encoding="utf-8"):
        m = re.match(r"^\| `([a-z0-9_]+)` \| (\d+) \| ([a-z_]+)", line)
        if m:
            out[m.group(1)] = (int(m.group(2)), m.group(3))
    return out


# ── §5 조치 모델 (보고서 §5 와 1:1 — 통합 결과는 check-seed 로 이 모델과 대조한다) ─────────────────
# 종류: set(SORT, 필드=값) · recode(SORT, 새 코드, 필드=값) · delete(SORT) · add(행 dict)
def _row(cd, nm, amt, ctgr, note, qual, qd, sort):
    return dict(cd=cd, nm=nm, amt=amt, ctgr=ctgr, badge="est", note=note, qual=qual, qd=qd, sort=sort)


DATE = "2026-10-10"
ACTIONS: dict[str, list] = {
    "ottogi": [
        ("delete", 21),
        ("add", _row("housing_support", "지방사업장 근무자 주거 지원금", None, "perks", None, True,
                     "지방사업장 근무자 주거 지원금 규정, 지원 기준의 합리성 재검토 및 필요시 규정 개정 예정 (2026 지속가능경영보고서 63~64쪽 인권영향평가 개선조치 항목) — 지원 금액·지급 대상 기준 미기재", 15)),
    ],
    "kcc": [
        ("set", 80, dict(qd="근로시간 총량을 정해 근무 시작과 종료를 직원의 자율에 맡기는 선택적 근로시간제, 프로젝트성 업무 등 근무시간 초과가 예상되는 부서 및 직원 대상 탄력적 근로시간제, 출퇴근시간 조정 시스템 운영 (2026 지속가능성보고서 61쪽 근로시간 제도 개선 항목) — 적용 대상 직군·의무 근무시간대 미기재")),
        ("set", 41, dict(qd="비연고지에서 근무하는 직원에게 연고지 이동을 위한 교통비 지원 (공식 채용 페이지 복지제도 생활/문화 항목), 필요시 장거리 근무자의 주말 귀향비 지원 (2026 지속가능성보고서 61쪽 다양한 복리후생 항목), 유류비 지원 (같은 보고서 6쪽 이해관계자 참여 항목) — 지원 금액·지원 횟수·유류비 지원 대상 미기재")),
    ],
    "hansol_chemical": [
        ("delete", 12),
        ("delete", 44),
        ("set", 41, dict(qd="주택대출이자 지원 (공식 인재채용 인사제도 페이지 더욱 먼 미래를 함께 꿈꾸는 회사 항목), 주거비 지원 (2026 한솔그룹 지속가능경영보고서 94~95쪽 계열사별 여성 및 가족친화 제도 한솔케미칼 행) — 지원 대상·한도·이자 지원율·주거비 지원 방식 미기재")),
    ],
    "orion": [
        ("add", _row("mental", "마음돌봄서비스", None, "health", None, True,
                     "임직원이 행복한 일상을 향유할 수 있도록 통합 심리적 지원프로그램인 「마음돌봄서비스」 제공, 스트레스 등으로 인한 심리적 이슈 해결 지원, 2025년 이용 인원 40명·이용 횟수 120회 (2025 ESG 보고서 16쪽 인권 고충처리 채널 항목) — 상담 방식·비용 지원 범위 미기재", 42)),
    ],
    "gs_enc": [
        ("set", 10, dict(nm="시차출퇴근제",
                         qd="시차 출퇴근제 운영(07:30~10:00 / 10분 단위 자율 출퇴근), 육아·업무 등 개인 필요에 따른 출퇴근 시간 자율 조정 (2026 지속가능경영보고서 90쪽 임직원 복리후생 프로그램 표 유연 근무제 운영 항목) — 출퇴근 시간 선택 주기·신청 절차 미기재")),
        ("add", _row("leave_general", "안식휴가 (휴가 적립형)", None, "time_off", None, True,
                     "휴가 적립을 통한 안식휴가제도 운영 (2026 지속가능경영보고서 90쪽 임직원 복리후생 프로그램 표 휴가 제도 강화 항목, 일하기 좋은 여건 조성 본문) — 적립 재원·기간·유급 여부 미기재", 22)),
        ("set", 90, dict(nm="관리직 성과급",
                         qd="관리직 연 평균 급여 기본급 + 성과급 항목 (2026 지속가능경영보고서 124쪽 임직원 보수 표) — 성과급 지급 기준·지급률·비관리직 지급 여부 미기재")),
        ("add", _row("excellence_award", "조직 성과 포상", None, "compensation", None, True,
                     "조직 차원에서 우수한 성과를 달성한 경우 추가적인 포상 실시 (2026 지속가능경영보고서 89쪽 합리적 보상체계 운영) — 포상 기준·포상 내용·주기 미기재", 91)),
    ],
    "hyundai_marine": [
        ("delete", 42),
    ],
    "hanon_systems": [
        ("recode", 10, "profit_sharing", {}),
    ],
    "sl_corp": [
        ("set", 40, dict(qd="임산부 전용 주차구역, 출산 시 축하선물, 입학 축하금과 교복 구입비 등 양육 지원 제도 (2026 지속가능경영보고서 65쪽 가족친화문화 조성), 만 8세 이하 또는 초등학교 2학년 이하 자녀가 있는 임직원 대상 무급 육아휴직 최대 2년(법정 1년에 1년 추가) (같은 쪽 복리후생 제도 표 육아휴직 항목), 2025년 4분기 노사협의회 안건 입학축하금 및 교복구입비 인상 (같은 보고서 60쪽 노사협의회 운영 현황) — 선물 품목·축하금 금액 미기재")),
        ("set", 50, dict(qd="임직원 대상 연 1회 건강검진, 내원 또는 출장 검진 (2026 지속가능경영보고서 55쪽 근로자 건강검진), 종합 건강검진 지원 (같은 보고서 65쪽 복리후생 제도 표 건강검진 항목), 내시경 검사, 초음파 검사, 혈액 종양표지자 검사 등의 추가 검진 지원 (55쪽 근로자 건강검진) — 비용 지원 범위·가족 포함 여부 미기재")),
        ("set", 61, dict(nm="업무 통신비 지원")),
    ],
    "kolon_industries": [
        ("set", 10, dict(qd="모성 보호 제도로 임신 축하 선물, 출산 축하금 지원 (2025 지속가능경영보고서 79쪽 복리후생 제도 항목), 임신기 여성에게 법적 기준보다 4주 확대된 근로시간 단축 제도 적용, 임산부 전용 주차공간 마련, 자녀 입학 시 경조금 지급 (같은 쪽 자녀양육 지원 항목) — 출산 축하금·입학 경조금 금액과 선물 구성 미기재")),
        ("add", _row("overseas_safety", "해외출장자 Travel Medical Kit", None, "health", None, True,
                     "해외출장자를 대상으로 출장 중 발생할 수 있는 응급상황에 대비할 수 있는 kit 제공 (2025 지속가능경영보고서 79쪽 건강보건 지원 제도 Travel Medical Kit 제공 항목) — kit 구성·대상 국가 미기재", 53)),
        ("set", 62, dict(nm="전화외국어·어학 보조금",
                         qd="임직원의 자기주도 학습을 지원하기 위해 전화외국어 과정 매월 운영 (2025 지속가능경영보고서 75쪽 인재 육성 정책 항목), 교육 체계도의 어학 보조금 (같은 쪽 교육 체계도) — 대상 언어·보조금 금액·수강 대상 미기재")),
    ],
    "sanil_electric": [],
    "isc": [
        ("set", 10, dict(nm="경조휴가",
                         qd="경조휴가 (공식 채용 페이지 i-Gle LIFE 복리후생 「휴가는 눈치보지 말아요」 항목) — 경조 사유별 휴가 일수·유급 여부 미기재")),
    ],
    "kolmar_korea": [
        ("add", _row("excellence_award", "품질 분임조 포상", None, "compensation", None, True,
                     "매년 품질 분임조 대회를 개최하여 공정 개선 우수 사례 발굴, 성과에 따른 포상 제도 연계 (한국콜마 2025 지속가능경영보고서 106쪽 품질 분임조 활동) — 포상 기준·포상 내용 미기재", 92)),
    ],
    "cosmax": [
        ("set", 10, dict(qd="자녀 출산 시 출산장려금 첫째 1천만원, 둘째 2천만원, 셋째 이상 3천만원 지원 (코스맥스그룹 채용 사이트 복리후생 출산장려금 지원 항목), 배우자 출산휴가 희망 시 최대 무급 10일 사용 가능 (법정 20일에 무급 10일 추가) (출산휴가 제도 확대 항목), 어린이집 보육료 지원 (위탁보육료 지급 항목), 초등 2학년 이하 자녀 대상 법정 기본 연차 외에 별도의 휴가 부여 (유급 2일) (자녀돌봄 휴가 도입 항목) — 보육료 지원 금액·자녀돌봄 휴가 부여 주기 미기재 (그룹 통합 채용 기준)")),
    ],
}

# 조치마다 근거 한 줄(§5 표의 「근거」 열) — ACTIONS 와 같은 순서
WHY: dict[str, list[str]] = {
    "ottogi": [
        "리드 판정 W5-12 ① — 영업 직무 수단(`work_tools` = 업무용 IT 장비), 같은 칸 「영업 배상 책임보험」을 거른 잣대와 같게",
        "리드 판정 W5-12 ② — 검증 MISSED(보고서 63~64쪽 「지방사업장 근무자 주거 지원금 규정」) 완성 튜플 그대로",
    ],
    "kcc": [
        "리드 판정 W5-14 · 검증 §7 ① — 「법정 근무시간」의 「법정」 낱말 걷기(허용 조건 밖). 뜻(근무시간 초과 예상 부서)은 남는다",
        "리드 판정 W5-14 ① — 보고서 6쪽 「각종 복리후생 지원 (주택자금대부, 유류 및 통신비, …)」의 유류비를 이 행 서술에 보탬(검증 §8-1 문안)",
    ],
    "hansol_chemical": [
        "리드 판정 W5-15 ① — 근거가 영문판 「telecommuting」 하나뿐이고 국문(최신)은 같은 자리를 「근로시간 단축/조기퇴근」으로 바꿨다",
        "리드 판정 W5-15 ② — 그룹 보고서 「주거비 지원」은 정본 「주택대출이자 지원」과 같은 제도인지 못 가른다 → 별행 삭제",
        "리드 판정 W5-15 ② — 삭제한 SORT 44 의 원문 구절을 이 행 서술로 병합(검증 §7 ② 문안)",
    ],
    "orion": [
        "리드 판정 W5-13 ① — 검증 MISSED(보고서 16쪽 「마음돌봄서비스」) 완성 튜플 그대로",
    ],
    "gs_enc": [
        "리드 판정 W5-16 · 검증 §8 ① — 「휴가 적립을 통한 안식휴가제도」를 시차출퇴근 행에서 걷는다(원문에 초과근무 전환이 없어 `flex_work` 서술 근거 아님)",
        "리드 판정 W5-16 ① — 같은 구절을 `leave_general` 「안식휴가 (휴가 적립형)」으로 싣는다(꼬리 「적립 재원·기간·유급 여부 미기재」). GS건설에 `leave_general` 행이 없어 새 행",
        "리드 판정 W5-16 · 검증 §8 ② — 근거를 124쪽 보수 표로 좁히고 대상(관리직)을 이름에. 89쪽 일반 보상 문장 · 포상 문장은 걷는다",
        "리드 판정 W5-16 · 검증 MISSED — 89쪽 「조직 차원에서 우수한 성과를 달성한 경우에는 추가적인 포상」 완성 튜플 그대로",
    ],
    "hyundai_marine": [
        "리드 판정 W5-9 — 「Refresh를 위한 연속 휴가사용 장려」는 회사가 더 주는 날이 없는 연차 사용 캠페인(R-3 기준 31 · 계약 3-5)",
    ],
    "hanon_systems": [
        "리드 판정 W5-10 — 「경영실적에 따른 성과급 지급」(평가 차등 · PI 언급 없음) = 경영성과급 단독 제도(계약 11-1). 이름 · 서술 · 카테고리 · SORT 그대로",
    ],
    "sl_corp": [
        "리드 판정 W5-19 · 검증 §7 ① — 상회분 꼴 「(법정 1년에 1년 추가)」 · 노사협의회 안건임을 본문에(검증 문안 그대로)",
        "리드 판정 W5-19 · 검증 §7 ② — 같은 보고서 55쪽 「연 1회 건강검진」이 있는데 꼬리가 「검진 주기 미기재」라 원문과 반대 말",
        "리드 판정 W5-19 · 검증 §7 ③ — 원문 「업무 수행 통신비 지원」의 한정을 이름에",
    ],
    "kolon_industries": [
        "리드 판정 W5-19 · 검증 §7 ① — 「임산부 정기 건강검진 지원」은 근로기준법 74조의2 와 같은 말(회사분을 가르지 않음) → 그 구절만 걷기",
        "리드 판정 W5-19 · 검증 MISSED — 79쪽 건강보건 지원 제도 「Travel Medical Kit 제공」 완성 튜플 그대로(`overseas_safety` · 어휘표 n=2)",
        "리드 판정 W5-19 · 검증 §7 ② — 「1:1 외국어 코칭」은 75쪽 교육 체계도 임원 행(임원 전용) → 걷고 같은 쪽 「어학 보조금」으로",
    ],
    "sanil_electric": [],
    "isc": [
        "리드 판정 W5-20 ① — 「권장휴가」는 이름뿐이고 회사가 더 주는 날이 없다(W5-9 · R-3 기준 31 과 같은 유형) → 걷기(검증 A-1 문안)",
    ],
    "kolmar_korea": [
        "리드 판정 W5-18 — 검증 MISSED(보고서 106쪽 품질 분임조 「성과에 따른 포상 제도를 연계」) 완성 튜플 그대로. 보고서 전용이라 그룹 각주 없음(W5-8 ①)",
    ],
    "cosmax": [
        "리드 판정 W5-18 · 검증 §7-1 — 원문 항목명 「출산장려금」 · 「배우자 출산휴가」를 본문 구절에 둔다(항목 페이지가 출처 괄호 속 낱말을 메모로 걷는다). 나머지 글자 그대로",
    ],
}

# 정본 URL 교체(리드 판정 W5-8 ②) — 머리말 `-- URL:` · INSERT · UPDATE 세 곳
URL_CHANGE = {
    "kolmar_korea": ("https://kolmar.recruiter.co.kr/career/benefits",
                     "https://www.kolmar.co.kr/img/esg/2025_sustainability_report_kor_2.pdf"),
}
# 머리말 「참고」 줄 교체(정본이 바뀐 회사만 — 주석이라 적재 영향 없음)
HEADER_EDIT = {
    "kolmar_korea": [(
        "--   정본 = 콜마그룹 통합 채용사이트 복리후생 페이지(kolmar.recruiter.co.kr/career/benefits, 제목 복리후생 | 콜마그룹 채용).",
        "--   정본 = 한국콜마(주) 자기 도메인 2025 지속가능경영보고서 PDF(리드 판정 W5-8). 참고 = 콜마그룹 통합 채용사이트 복리후생 페이지(kolmar.recruiter.co.kr/career/benefits, 콜마홀딩스 운영, 제목 복리후생 | 콜마그룹 채용) — 그룹 각주 19행의 근거.",
    )],
}
HEADER_LINE = {
    "ottogi": "-- 검증 · 감사 판정 반영(2026-10-10): 영업용 차량 work_tools 삭제 · 지방사업장 근무자 주거 지원금 housing_support 추가 — 최종 30행",
    "kcc": "-- 검증 · 감사 판정 반영(2026-10-10): 선택근로 서술의 법정 낱말 제거 · 비연고지 교통비 행에 보고서 6쪽 유류비 구절 보탬 · 금연 프로그램은 싣지 않음 — 최종 30행",
    "hansol_chemical": "-- 검증 · 감사 판정 반영(2026-10-10): 영문판 단독 재택근무 remote_work 삭제 · 그룹 보고서 주거비 지원 housing_support 를 주택대출이자 행 서술로 병합 — 최종 22행",
    "orion": "-- 검증 · 감사 판정 반영(2026-10-10): 마음돌봄서비스 mental 추가 · 관리자 KPI 성과급 연계 문장은 싣지 않음 — 최종 21행",
    "gs_enc": "-- 검증 · 감사 판정 반영(2026-10-10): 시차출퇴근제 행에서 휴가 적립 안식휴가 구절을 걷어 leave_general 안식휴가 (휴가 적립형) 행으로 · 성과급을 124쪽 보수 표 관리직 성과급으로 좁힘 · 조직 성과 포상 excellence_award 추가 — 최종 23행",
    "hyundai_marine": "-- 검증 · 감사 판정 반영(2026-10-10): 休-9 연속 휴가사용 장려 leave_general 삭제(회사가 더 주는 날 없음) — 최종 16행",
    "hanon_systems": "-- 검증 · 감사 판정 반영(2026-10-10): 경영실적 성과급을 incentive 에서 profit_sharing 으로 재코딩 · 식대 576 유지 — 최종 19행",
    "sl_corp": "-- 검증 · 감사 판정 반영(2026-10-10): 육아휴직 상회분 표기와 노사협의회 안건 표기 정리 · 건강검진 연 1회 반영 · 통신비 행 이름을 업무 통신비 지원으로 — 최종 24행",
    "kolon_industries": "-- 검증 · 감사 판정 반영(2026-10-10): 임산부 정기 건강검진 구절(법정 겹침) 제거 · 임원 행 1:1 외국어 코칭을 어학 보조금으로 교체 · 해외출장자 Travel Medical Kit overseas_safety 추가 — 최종 31행",
    "sanil_electric": "-- 검증 · 감사 판정 반영(2026-10-10): 조치 없음 — 최종 15행",
    "isc": "-- 검증 · 감사 판정 반영(2026-10-10): 경조휴가 행에서 권장휴가(회사가 더 주는 날 없음) 걷기 — 최종 17행",
    "kolmar_korea": "-- 검증 · 감사 판정 반영(2026-10-10): 정본 URL 을 한국콜마 2025 지속가능경영보고서 PDF 로 교체(그룹 채용 페이지는 참고) · 품질 분임조 포상 excellence_award 추가 — 최종 28행",
    "cosmax": "-- 검증 · 감사 판정 반영(2026-10-10): 출산장려금 행 서술 앞 두 구절에 원문 항목명 출산장려금 · 배우자 출산휴가를 본문으로 — 최종 17행",
}

# 검증 권고 가운데 감사가 집행하지 않는 것(리드 판정 · 감사 판정) — §5 「바꾸지 않는 것」 표
KEEP: dict[str, list[tuple]] = {
    "ottogi": [("—", "(휴직제도)", "제외 유지", "W5-12 ③ — 내용 없음 · 계약 3-1")],
    "kcc": [(22, "books", "유지", "W5-14 ③"), (64, "leisure_ticket", "유지", "W5-14 ③"),
            ("—", "smoking_cessation", "싣지 않음", "W5-14 ② — 보건소 협업 프로그램, `smoking_cessation` 은 현금 급부 축")],
    "orion": [(30, "child_edu", "유지", "W5-13 ③ — 꼬리 「지원 대상(본인·자녀)」 유지"),
              ("—", "incentive(관리자 KPI)", "싣지 않음", "W5-13 ② — 지배구조 · ESG 보상 연계 설명(R-3 기준 17 과 같은 이유)"),
              ("—", "(대체휴무제)", "제외 유지", "W5-13 ④ — 영문판 compensatory time off = 보상휴가(법정)")],
    "gs_enc": [(90, "incentive", "유지(이름 · 문안만 교체)", "W5-16 ② — 리드 판정 ㊾ 유형")],
    "hanon_systems": [(40, "meal", "금액 576 유지", "W5-11 — 규칙 4-5 「사업장별 상이는 적힌 끼니로」 · 한국타이어 864 선례 · 항목 페이지 `site` 예외")],
    "kolon_industries": [(30, "housing_loan", "유지", "W5-19 ② — 같은 문구 코퍼스 2사(가온전선 · LG에너지솔루션)"),
                         ("—", "COMP_NM", "「코오롱인더스트리」 유지", "W5-19 ① — 별칭 「코오롱인더」 필수(§8)")],
    "kolmar_korea": [("—", "(열린협의회 의안 3건)", "싣지 않음", "W5-18 — 의안일 뿐 시행 문장 없음")],
    "hyundai_marine": [],
    "sl_corp": [],
    "sanil_electric": [("—", "(정기 건강검진)", "제외 유지", "회사가 스스로 「법정복리후생」 칸에 넣었다(검증 §3)")],
    "isc": [(20, "incentive", "유지", "회사 실적 및 개인 · 팀 성과 — W5-10 꼴(회사 실적만) 아님")],
    "cosmax": [],
    "hansol_chemical": [],
}

# 항목 페이지 동반 조치(리드 집행 — generator/data/benefit_pages/<code>.json overrides)
#   h 는 모의 최종 문안으로 다시 계산해 대조한다(sec_pages) — 아래 값은 기대값.
OVERRIDES: list[tuple[str, dict]] = [
    ("discount", {"comp": "hyundai_marine", "h": "be27d03040", "facets_remove": ["group"], "why": "현대해상은 현대차그룹·현대백화점그룹 계열이 아니다 — 원문 「임직원 제휴할인 : 현대/기아자동차, 현대백화점 할인」은 외부 제휴처 할인이다"}),
    ("meal", {"comp": "hanon_systems", "h": "ed091d455c", "facets_add": ["site"], "why": "원문이 사내식당을 「판교/대전/평택」 세 사업장으로 적었다 — 회사 국내 사업장 다섯 곳(대전·평택·판교·울산·경주) 가운데 셋이다"}),
    ("meal", {"comp": "ottogi", "h": "eb7c5dada9", "mode": "both", "why": "원문 「사내식당/중식비」 — 사내식당과 중식비를 한 항목에 함께 적었다"}),
    ("mental", {"comp": "ottogi", "h": "66ef43a16e", "mode": "unknown", "why": "「사내」는 명상 Class 를 꾸민 말이다 — 상담 방식(사내 상담실·외부 기관)은 원문에 없다"}),
    ("parenting", {"comp": "ottogi", "h": "4d6473313c", "facets_remove": ["amount"], "why": "「총 4,830만 원」은 2025년 자녀 69명 몫 지급 총액이다 — 1인 금액이 아니다"}),
    ("event", {"comp": "ottogi", "h": "aa6875bdfe", "facets_add": ["money"], "why": "원문 「경상조비」는 경조사비다 — 규칙 낱말 경조비 사이에 「상」이 끼어 못 잡는다"}),
    ("health_check", {"comp": "ottogi", "h": "27b385cc37", "facets_add": ["cycle"], "why": "원문 「2년 주기로」 종합검진 — 격년 주기인데 규칙 낱말에 「N년 주기」가 없다"}),
    ("long_service_bonus", {"comp": "ottogi", "h": "1eeab7180f", "mode": "goods", "why": "근속자에게 웰니스 시설 객실·식사·힐링 프로그램을 준다 — 돈이 아니라 숙박형 여행 급부다"}),
    ("meal", {"comp": "orion", "h": "064725641b", "mode": "both", "why": "원문이 「외식비 지원」(돈)과 「무료사내식당」(밥)을 함께 적었다"}),
    ("incentive", {"comp": "kcc", "h": "8a508eada5", "facets_remove": ["frequency"], "why": "원문 「연간 업무성과에 따른 성과급」의 연간은 평가 기간이다 — 지급 주기가 원문에 없다"}),
    ("resort", {"comp": "kcc", "h": "e1454777b6", "facets_add": ["secured", "paid"], "why": "원문 「무료 캠핑장을 운영하여 여가장소를 제공」 — 회사가 직접 운영하는 무료 숙영지다"}),
    ("leave_general", {"comp": "kolmar_korea", "h": "4eece12ac4", "facets_remove": ["sick"], "why": "「휴직자로 인한 업무 공백을 분담하는 직원」에게 주는 휴가다 — 병가·휴직 제도를 밝힌 문장이 아니다"}),
    ("parenting", {"comp": "kolmar_korea", "h": "f93779e17b", "facets_add": ["leave_pay"], "why": "「육아휴직 개시 시 육아휴직 생활지원금 지급」 — 휴직 중 회사가 주는 돈인데 「생활지원금」이 규칙 낱말 꼴에 맞지 않는다"}),
    ("parenting", {"comp": "cosmax", "h": "1a1af205a4", "facets_add": ["amount"], "why": "「첫째 1천만원, 둘째 2천만원, 셋째 이상 3천만원」 — 출산장려금 금액인데 「천만원」 꼴이 금액 규칙(숫자+만 원)에 맞지 않는다"}),
    ("resort", {"comp": "cosmax", "h": "e7b953b89e", "facets_add": ["secured", "paid"], "why": "「법인 근로복지시설 향약원 무료이용」 — 회사가 가진 시설을 무료로 쓰는데 규칙 낱말(법인 콘도·휴양소 운영·무료 숙박) 꼴이 아니다"}),
    ("excellence_award", {"comp": "sl_corp", "h": "52e44eb18f", "facets_remove": ["referral"], "why": "「조직장 추천 인원」은 GDS 포상 대상을 고르는 절차다 — 인재 추천 포상이 아니다"}),
    ("fitness", {"comp": "sl_corp", "h": "f1076e2d13", "mode": "inhouse", "why": "55쪽 「체력 증진을 위한 스트레칭룸을 조성」 — 회사가 만든 시설이다"}),
    ("mental", {"comp": "kolon_industries", "h": "21a7e497f7", "mode": "external", "why": "「전국 1,600여 개 전문 상담센터와 협력」 · 패션부문 「전문업체를 통한 … EAP」 — 회사 밖 전문기관이다(사내 상담실 아님)"}),
    ("incentive", {"comp": "kolon_industries", "h": "ad58a8e7eb", "facets_remove": ["frequency"], "why": "「연간」은 「회사의 연간 경영 목표 달성 여부」에서 걸렸다 — 지급 주기를 밝힌 것이 아니다"}),
    ("long_service_bonus", {"comp": "kolon_industries", "h": "3246b1ca0a", "facets_remove": ["years"], "why": "「2024년」 · 「2025년」은 노사 웰빙TF 연도다 — 몇 년 근속부터인지를 밝힌 것이 아니다"}),
    ("lang", {"comp": "kolon_industries", "h": "9ad94446d7", "mode": "both", "why": "75쪽 「전화외국어 … 매월 운영」(회사가 수업을 엶)과 교육 체계도 「어학 보조금」(학습비 지원)이 함께 있다 — 「보조금」 낱말이 비용 규칙에 없다"}),
    ("incentive", {"comp": "isc", "h": "3cb4d361fc", "mode": "both", "why": "보상체계 원문이 Incentive Bonus 를 회사 실적 및 개인·팀 성과를 반영한 보상으로 적어 회사 실적과 개인·팀 성과를 함께 밝힌다"}),
]


# ── 조치 적용 ─────────────────────────────────────────────────────────────────
def apply_actions(collect: dict) -> dict:
    final = {}
    for eng, c in collect.items():
        rows = copy.deepcopy(c["rows"])
        by_sort = {r["sort"]: r for r in rows}
        for act in ACTIONS.get(eng, []):
            kind = act[0]
            if kind == "set":
                by_sort[act[1]].update(act[2])
            elif kind == "recode":
                r = by_sort[act[1]]
                r["cd"] = act[2]
                r.update(act[3])
            elif kind == "delete":
                assert act[1] in by_sort, (eng, act)
                rows = [r for r in rows if r["sort"] != act[1]]
                by_sort.pop(act[1])
            elif kind == "add":
                nr = dict(act[1])
                assert nr["sort"] not in by_sort, (eng, nr["sort"])
                assert nr["cd"] not in {r["cd"] for r in rows}, (eng, nr["cd"])
                rows.append(nr)
                by_sort[nr["sort"]] = nr
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


def one_line_tuple(r: dict) -> str:
    amt = "NULL" if r["amt"] is None else str(r["amt"])
    return (f"(@comp_id, '{r['cd']}', '{r['nm']}', {amt}, '{r['ctgr']}', 'est', {sv(r['note'])}, "
            f"{'TRUE' if r['qual'] else 'FALSE'}, {sv(r['qd'])}, {r['sort']})")


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
        for s, e, sort in reversed(spans):
            if sort in want and sort in orig:
                if want[sort] != orig[sort]:
                    t = t[:s] + render_tuple(want[sort]).lstrip() + t[e:]
            else:  # 삭제 — 튜플 줄 전체와 뒤 쉼표를 지운다(마지막 행이면 앞 행 쉼표를 지운다)
                line_start = t.rfind("\n", 0, s) + 1
                rest = t[e:]
                if rest.startswith(","):
                    end = e + 1
                    nl = t.find("\n", end)
                    end = nl + 1 if nl != -1 and t[end:nl].strip() == "" else end
                    t = t[:line_start] + t[end:]
                else:  # 이번 조치에는 마지막 튜플 삭제가 없다 — 생기면 손으로 다시 본다
                    raise NotImplementedError(f"{eng} SORT {sort}: 마지막 튜플 삭제")
        # 2) 새 행 — SORT 순서 자리(바로 앞 SORT 의 튜플 뒤)
        for r in [x for x in final[eng] if x["sort"] not in orig]:
            spans2 = [(m.start(), m.end(), int(m.group(9))) for m in TUPLE.finditer(t)]
            prev = max((sp for sp in spans2 if sp[2] < r["sort"]), key=lambda sp: sp[2])
            e = prev[1]
            if t[e:e + 1] == ",":
                t = t[:e + 1] + "\n" + render_tuple(r) + "," + t[e + 1:]
            else:  # 마지막 튜플 뒤
                t = t[:e] + ",\n" + render_tuple(r) + t[e:]
        # 3) 정본 URL · 머리말 줄
        if eng in URL_CHANGE:
            old, new = URL_CHANGE[eng]
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
            print(f"  ⚠ {fn}: 등록 eng {eng} 가 대상 13사가 아니다")
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
def sec_fmt(collect, final, corpus):
    print("=" * 100)
    print("§fmt 수집본 형식 · 등록 · slug · 표시명 충돌")
    slugs = {slug_of(c["meta"]["eng"]): c["file"] for c in corpus.values()}
    names = {c["meta"]["nm"]: c["file"] for c in corpus.values()}
    wave_slugs = collections.Counter(slug_of(e) for e in collect)
    wave_names = collections.Counter(c["meta"]["nm"] for c in collect.values())
    for eng, c in collect.items():
        p = fmt_problems(c)
        sl = slug_of(eng)
        coll = []
        if sl in slugs:
            coll.append(f"slug 충돌 {slugs[sl]}")
        if c["meta"]["nm"] in names:
            coll.append(f"표시명 충돌 {names[c['meta']['nm']]}")
        if wave_slugs[sl] > 1 or wave_names[c["meta"]["nm"]] > 1:
            coll.append("웨이브 안 중복")
        print(f"  {c['file']:<8} eng={eng:<18} slug={sl:<18} 행 {len(c['rows']):>2} → 최종 {len(final[eng]):>2} · "
              f"형식 {p or '0'} · 충돌 {coll or '0'}")


def sec_codes(collect, final, corpus):
    print("=" * 100)
    print("§codes 신규 코드 — 어휘표 89종 · 코퍼스 실사용 대비")
    voc = vocab_table()
    used = collections.defaultdict(set)
    for eng, c in corpus.items():
        for r in c["rows"]:
            used[r["cd"]].add(eng)
    for label, rows_of in (("수집본", lambda e: collect[e]["rows"]), ("최종본", lambda e: final[e])):
        codes = collections.Counter(r["cd"] for e in collect for r in rows_of(e))
        new_v = sorted(c for c in codes if c not in voc)
        new_c = sorted(c for c in codes if c not in used)
        ctg = [(e, r["sort"], r["cd"], r["ctgr"], voc[r["cd"]][1]) for e in collect for r in rows_of(e)
               if r["cd"] in voc and voc[r["cd"]][1] != r["ctgr"]]
        print(f"  {label}: 코드 {len(codes)}종 · 어휘표 밖 {new_v or 0} · 코퍼스 미사용 {new_c or 0} · 카테고리 ≠ 어휘표 {ctg or 0}")
    allc = set(used)
    for e in collect:
        allc |= {r["cd"] for r in final[e]}
    print(f"  최종 반영 뒤 쓰이는 코드 수 {len(allc)} (지금 {len(used)})")


def sec_consist(collect, final, corpus):
    print("=" * 100)
    print("§consist ① W5-10 경영실적 성과급 꼴 — incentive / profit_sharing")
    pat = re.compile(r"경영\s*실적|경영\s*성과|회사\s*실적|영업이익|Profit Sharing|이익\s*배분|초과\s*이익")
    other = re.compile(r"개인|조직|팀|부서|평가|차등|등급|KPI|PI\b|PI\)|Productivity|기여|프로젝트|역량|목표달성 등급")
    for tag, src in (("코퍼스", {e: c["rows"] for e, c in corpus.items()}), ("웨이브5 최종", final)):
        for e, rows in src.items():
            for r in rows:
                if r["cd"] not in ("incentive", "profit_sharing"):
                    continue
                t = " ".join(x for x in (r["nm"], r["note"] or "", r["qd"] or ""))
                if not pat.search(t):
                    continue
                only_company = not other.search(t)
                fn = corpus[e]["file"] if e in corpus else collect[e]["file"]
                flag = ""
                if only_company and r["cd"] == "incentive":
                    flag = "  ◀ 회사 실적만인데 incentive"
                print(f"  {tag}\t{fn}\tSORT {r['sort']}\t{r['cd']}\t회사 실적만={only_company}\t{r['nm']}{flag}")
    print("\n§consist ② 그룹 각주 꼴(코스맥스 · 한국콜마)")
    for e in ("cosmax", "kolmar_korea"):
        for r in final[e]:
            t = r["qd"] or r["note"] or ""
            g = "(그룹 통합 채용 기준)" in t
            s = "그룹 공통 문구" in t
            src_recruit = "채용 사이트" in t or "채용사이트" in t
            dashes = len(re.findall(r"\s[—–]\s", t))
            flag = ""
            if src_recruit and not g:
                flag = " ◀ 채용 페이지 근거인데 각주 없음"
            if g and not src_recruit:
                flag = " ◀ 채용 페이지 근거 없는데 각주"
            tail = rc.dash_tail_breaks(t)
            print(f"  {collect[e]['file']}\tSORT {r['sort']}\t{r['cd']}\t채용페이지근거={src_recruit}\t"
                  f"그룹통합각주={g}\t그룹공통문구={s}\t「—」{dashes}\tSI-11깨짐={tail}\t길이 {len(t)}{flag}")


def sec_amt(collect, final, corpus):
    print("=" * 100)
    print("§amt 금액 행 전수(최종본) — 예측 금액 출처 derive_amt_source")
    tot = collections.Counter()
    for e in collect:
        for r in final[e]:
            if r["amt"] is not None:
                s = derive_amt_source(r["amt"], r["qual"], r["note"])
                fa = rc.formula_amount(r["note"])
                print(f"  {collect[e]['file']}\tSORT {r['sort']}\t{r['cd']}\t{r['amt']}\t{s}\t꼬리식={fa}\t{r['note']}")
                tot[(e, s)] += 1
    print("\n  코퍼스 meal 금액 분포(축 최댓값)")
    vals = sorted((r["amt"], c["file"]) for c in corpus.values() for r in c["rows"] if r["cd"] == "meal" and r["amt"])
    print(f"   meal 금액 행 {len(vals)} · 최댓값 {vals[-1] if vals else None} · 864 이상 {[v for v in vals if v[0] >= 864]}")


def sec_reg(collect, corpus):
    print("=" * 100)
    print("§reg 등록 값 · 업종 · corp_code")
    dart = json.load(open(W5 + "/dart/check-2026-10-10.json", encoding="utf-8"))
    inds = collections.Counter(c["meta"]["ind"] for c in corpus.values())
    import csv
    cmap = list(csv.DictReader(open(REPO + "/db/seed/corp_code_map.csv", encoding="utf-8")))
    have_codes = collections.Counter(r["corp_code"] for r in cmap if r["corp_code"])
    roster_key = {"ottogi": "오뚜기", "kcc": "KCC", "hansol_chemical": "한솔케미칼", "orion": "오리온", "gs_enc": "GS건설",
                  "hyundai_marine": "현대해상", "hanon_systems": "한온시스템", "sl_corp": "에스엘",
                  "kolon_industries": "코오롱인더", "sanil_electric": "산일전기", "isc": "ISC",
                  "kolmar_korea": "한국콜마", "cosmax": "코스맥스"}
    codes_here = []
    for eng, c in collect.items():
        m = expected_meta(eng, collect)
        dk = dart[roster_key[eng]]
        codes_here.append(dk["corp_code"])
        same = len([x for x in collect.values() if x["meta"]["ind"] == m["ind"]])
        print(f"  {c['file']}\t{eng}\t{m['nm']}\t{m['tp']}\t{m['ind']}(코퍼스 {inds.get(m['ind'], 0)} + 이번 {same})\t{m['logo']}\t"
              f"slug={slug_of(eng)}\tDART {dk['corp_code']} '{dk['dart_name']}' 종목 {dk['stock']}\t"
              f"기존 csv 충돌 {have_codes.get(dk['corp_code'], 0)}\t{m['url']}")
    print(f"  이번 corp_code 중복 {len(codes_here) - len(set(codes_here))} · 기존 csv 와 겹침 "
          f"{sum(1 for x in codes_here if x in have_codes)} · csv 최대 comp_id {max(int(r['comp_id']) for r in cmap)} · csv 행 {len(cmap)}")
    new_inds = [m for m in {expected_meta(e, collect)['ind'] for e in collect} if m not in inds]
    print(f"  INDUSTRY_NM 새 값 {new_inds or 0} · NFC/바이트: " +
          ", ".join(f"{i}={i.encode().hex()[:12]}" for i in sorted({expected_meta(e, collect)['ind'] for e in collect})))


def sec_robots():
    print("=" * 100)
    print("§robots 옛 robots 목록 줄(W5-17) — server.source_check.parse_robots 실제 import")
    from server import source_check as sc
    hosts = {
        "오뚜기 www.otoki.com": ("ottogi/robots_www.otoki.com.txt", "https://www.otoki.com/about/personnel-system"),
        "KCC www.kccworld.co.kr": ("probe/kcc/robots_www.txt", "https://www.kccworld.co.kr/jobs/hr-system.do"),
        "한솔케미칼 hansolchemical.com": ("hansol_chem/robots_apex.txt", "https://hansolchemical.com/hr/"),
        "오리온 www.orionworld.com": ("probe/orion/www_robots.txt", "https://www.orionworld.com/theme/102114/kr/assets/upload/x.pdf"),
        "GS건설 www.gsenc.com": ("probe/gs_enc/robots_www.txt", "https://www.gsenc.com/FileUpload/Bbs_New/x.pdf"),
        "한온시스템 hanonsystems.recruiter.co.kr": ("probe/hanon/robots_ats.txt", "https://hanonsystems.recruiter.co.kr/career/welfare"),
        "에스엘 www.slworld.com": ("probe/sl_corp/www_robots.txt", "https://www.slworld.com/include/esg_report_2026_ko.pdf"),
        "코오롱인더 www.kolonindustries.com": ("probe/kolon_ind/robots_www.txt", "https://www.kolonindustries.com/file/view?fileSeq=7255&fileOrd=2"),
        "산일전기 www.sanil.co.kr": ("sanil/robots_www_2026-10-10.txt", "https://www.sanil.co.kr/kr/sub/career/welfare.php"),
        "ISC www.isc21.kr": ("isc/robots_www.isc21.kr.txt", "https://www.isc21.kr/careers/i-gle-life"),
        "한국콜마 www.kolmar.co.kr": ("kolmar/_work/robots_www.txt", "https://www.kolmar.co.kr/img/esg/2025_sustainability_report_kor_2.pdf"),
        "코스맥스 cosmax.recruiter.co.kr": ("cosmax/_work/cosmax_robots.txt", "https://cosmax.recruiter.co.kr/career/welfare"),
    }
    for k, (p, u) in hosts.items():
        raw = open(f"{W5}/{p}", "rb").read()
        t = raw.decode("utf-8", "replace")
        uas = [ln.strip() for ln in t.splitlines() if ln.strip().lower().startswith("user-agent")]
        moz = [ln for ln in uas if "mozilla" in ln.lower()]
        slash = [ln for ln in uas if "/" in ln.split(":", 1)[1]]
        print(f"  {k}\t{len(raw)}B sha256 {hashlib.sha256(raw).hexdigest()[:12]}\tUA줄 {len(uas)}\t값에 / {len(slash)}\t"
              f"Mozilla 줄 {moz or 0}\t점검기 토큰({sc.ROBOTS_AGENT}) 허용={sc.parse_robots(t).allows(u)}\t"
              f"mozilla 토큰 허용={sc.parse_robots(t, 'mozilla').allows(u)}\tclaudebot 허용={sc.parse_robots(t, 'claudebot').allows(u)}")
    print("  (현대해상 hi.recruiter.co.kr robots 사본 없음 — 검증 점검기 실측 ok 200 으로 대신)")


def sec_legal(collect):
    print("=" * 100)
    print("§legal _legal_scan.py — 수집본 · 모의본")
    for label, d in (("수집본", COLLECT), ("모의본", SIM)):
        paths = [f"{d}/{fn}.sql" for fn in FILES]
        out = subprocess.run([sys.executable, LEGAL_SCAN, *paths], capture_output=True, text=True).stdout
        tail = [ln for ln in out.splitlines() if ln.strip()][-3:]
        print(f"  [{label}] " + " / ".join(tail))
        if label == "모의본":
            print(out)


def _merged_cfgs():
    cfgs = br.load_pages()
    merged = copy.deepcopy(cfgs)
    for code, ov in OVERRIDES:
        merged[code].setdefault("overrides", []).append(ov)
    return cfgs, merged


def sec_pages(collect, final, corpus):
    print("=" * 100)
    print("§pages 항목 페이지 — 모의 최종 문안 해시로 예외 대조 · validate_all · 분류")
    cfgs, merged = _merged_cfgs()
    errs = br.validate_all(merged)
    print(f"  validate_all(현행 + 예외 {len(OVERRIDES)}건) 오류 {len(errs)} {errs[:3]}")
    per_code = collections.Counter(code for code, _ in OVERRIDES)
    print(f"  예외 파일별 개수 {dict(per_code)}")
    want = {(code, ov["comp"]): ov for code, ov in OVERRIDES}
    # 해시 대조
    for (code, comp), ov in want.items():
        r = next((x for x in final[comp] if x["cd"] == code), None)
        h = br.text_hash(r["qd"], r["note"]) if r else None
        print(f"  {'OK ' if h == ov['h'] else '⚠  '}{code}\t{comp}\t기대 h {ov['h']}\t최종 문안 h {h}")
    # 최종 문안 분류(설정 있는 코드 전부) — 예외 적용 후
    print("\n  최종 문안 분류(예외 적용 후 · 설정 있는 코드)")
    stale_all = []
    for e in collect:
        for r in final[e]:
            if r["cd"] not in merged:
                continue
            res = br.classify(merged[r["cd"]], [{"comp": e, "desc": r["qd"], "note": r["note"], "unverified": False}])
            row = res["rows"][0] if res["rows"] else None
            stale_all += [s for s in res["stale"] if e in s]
            print(f"   {collect[e]['file']}\tSORT {r['sort']}\t{r['cd']}\th {br.text_hash(r['qd'], r['note'])}\t"
                  f"mode {row and row['mode']}\tfacets {sorted(row['facets']) if row else None}")
    print(f"  stale(이 13사) {stale_all or 0}")
    # MIN_COMPANIES 문턱 — 설정 있는 코드의 회사 수(표시 행 · exclude 예외 제외) 전후
    sys.path.insert(0, REPO)
    from generator.pages.benefit import MIN_COMPANIES
    marks = json.load(open(REPO + "/generator/data/row_marks.json", encoding="utf-8"))["rows"]
    marked = {(m["comp_eng_nm"], m["benefit_cd"]) for m in marks}
    print(f"\n  MIN_COMPANIES = {MIN_COMPANIES} — 설정 있는 코드 {len(cfgs)}개 회사 수(표시 행 · exclude 제외) 전 → 후")
    for code in sorted(cfgs):
        excl = {o["comp"] for o in cfgs[code].get("overrides", []) if o.get("exclude")}
        before = {e for e, c in corpus.items() if any(r["cd"] == code for r in c["rows"])
                  and (e, code) not in marked and e not in excl}
        after = before | {e for e in collect if any(r["cd"] == code for r in final[e])}
        cross = " ◀ 문턱을 넘는다" if len(before) < MIN_COMPANIES <= len(after) else ""
        if len(after) != len(before) or len(before) < MIN_COMPANIES + 5:
            print(f"   {code}: {len(before)} → {len(after)}{cross}")
    # 설정 없는 코드 가운데 이번에 20 을 넘는 것
    allcodes = {r["cd"] for c in corpus.values() for r in c["rows"]} | {r["cd"] for e in collect for r in final[e]}
    for code in sorted(allcodes - set(cfgs)):
        b = {e for e, c in corpus.items() if any(r["cd"] == code for r in c["rows"])}
        a = b | {e for e in collect if any(r["cd"] == code for r in final[e])}
        if len(a) >= MIN_COMPANIES:
            print(f"   (설정 없음) {code}: {len(b)} → {len(a)}{' ◀ 20 을 넘지만 설정 파일이 없어 페이지 없음' if len(b) < MIN_COMPANIES else ''}")
    # /find 대표 이름 — 빈도 → 길이 → 코드포인트(find._prefer_name) · LABEL_OVERRIDE 는 고정
    from generator.pages import find as fp
    print("\n  /find 대표 이름(base_label) 전 → 후 — 이번 웨이브가 쓰는 코드 중 LABEL_OVERRIDE 없는 것")
    for code in sorted({r["cd"] for e in collect for r in final[e]}):
        if code in fp.LABEL_OVERRIDE:
            continue
        cb = collections.Counter(r["nm"] for e, c in corpus.items() for r in c["rows"]
                                 if r["cd"] == code and (e, code) not in marked)
        ca = cb + collections.Counter(r["nm"] for e in collect for r in final[e] if r["cd"] == code)
        b, a = fp._most_common(cb), fp._most_common(ca)
        if b != a:
            print(f"   ◀ {code}: 「{b}」 → 「{a}」 (코퍼스 {sum(cb.values())}행 + 이번 {sum(ca.values()) - sum(cb.values())}행)")


def sec_chips(collect, final):
    print("=" * 100)
    print("§chips derive_work_style(모의본 텍스트) — remote · flex · refreshLeave · unlimitedPTO · cond")
    for e, c in collect.items():
        t = open(f"{SIM}/{c['file']}.sql", encoding="utf-8").read()
        ws = derive_work_style(t)
        rows = [(r["sort"], r["cd"], r["nm"], ws_conditions(r["nm"])) for r in final[e] if r["cd"] in _WS_CODE_KEY]
        print(f"  {c['file']}\tremote={ws['remote']}\tflex={ws['flex']}\trefreshLeave={'켜짐' if ws['refreshLeave'] else '꺼짐'}"
              f"\tunlimitedPTO={ws['unlimitedPTO']}\tcond={ws.get('cond', {})}\t행 {rows}")


def sec_actions_md(collect, final):
    """§5 본문 — 조치 모델에서 글자 그대로 찍는다(보고서와 check-seed 가 같은 문자열을 본다)."""
    fk = {"nm": "BENEFIT_NM", "amt": "BENEFIT_AMT", "ctgr": "BENEFIT_CTGR_CD", "note": "NOTE_CTNT",
          "qual": "QUAL_YN", "qd": "QUAL_DESC_CTNT", "sort": "SORT_ORDER_NO"}
    for i, fn in enumerate(FILES, 1):
        eng = next(e for e, c in collect.items() if c["file"] == fn)
        c = collect[eng]
        acts = ACTIONS.get(eng, [])
        print(f"\n### 5-{i}. {fn} (`{eng}`) — 수집 {len(c['rows'])} → 최종 {len(final[eng])}\n")
        by_sort = {r["sort"]: r for r in c["rows"]}
        if acts or eng in URL_CHANGE:
            print("| # | 대상(SORT · 코드) | 조치 | 근거 |")
            print("|---:|---|---|---|")
            n = 0
            for a, why in zip(acts, WHY[eng]):
                n += 1
                if a[0] == "set":
                    print(f"| {n} | {a[1]} `{by_sort[a[1]]['cd']}` | {'이름 · 문안 교체' if 'nm' in a[2] and 'qd' in a[2] else ('이름 교체' if 'nm' in a[2] else '문안 교체')} | {why} |")
                elif a[0] == "recode":
                    print(f"| {n} | {a[1]} `{by_sort[a[1]]['cd']}` | **재코딩 → `{a[2]}`** | {why} |")
                elif a[0] == "delete":
                    print(f"| {n} | {a[1]} `{by_sort[a[1]]['cd']}` | **삭제** | {why} |")
                elif a[0] == "add":
                    print(f"| {n} | {a[1]['sort']} `{a[1]['cd']}` | **추가** | {why} |")
            if eng in URL_CHANGE:
                n += 1
                print(f"| {n} | 등록 · 머리말 | **정본 URL 교체** | 리드 판정 W5-8 ② — 법인 자기 도메인 상시 자료(계약 1-4) · 점검기 `ok 206 application/pdf`(검증 실측). 그룹 채용 페이지는 머리말 「참고」로 |")
            print("\n집행(글자 그대로 — 백틱 안이 SQL 값이다):\n")
            n = 0
            for a in acts:
                n += 1
                if a[0] == "set":
                    print(f"- **#{n} SORT {a[1]} `{by_sort[a[1]]['cd']}`** — 적힌 필드만 바꾼다")
                    for k, v in a[2].items():
                        print(f"  - `{fk[k]}` = `{sv(v) if isinstance(v, str) else v}`")
                elif a[0] == "recode":
                    print(f"- **#{n} SORT {a[1]}** `BENEFIT_CD` `'{by_sort[a[1]]['cd']}'` → `'{a[2]}'` (카테고리 `compensation` · SORT {a[1]} · 이름 · 서술 그대로)")
                elif a[0] == "delete":
                    print(f"- **#{n} SORT {a[1]} `{by_sort[a[1]]['cd']}`** — 튜플을 통째로 지운다(앞뒤 쉼표 정리 · 빈 줄 남기지 않음)")
                elif a[0] == "add":
                    prev = max(s for s in by_sort if s < a[1]["sort"])
                    if a[1]["sort"] > max(by_sort):
                        print(f"- **#{n} 추가 SORT {a[1]['sort']}** — VALUES 의 마지막 행이 된다: SORT {prev} 행 끝 `)` 뒤에 `,` 를 붙이고, "
                              f"그 아래(`ON DUPLICATE KEY UPDATE` 바로 앞)에 쉼표 없이:")
                        print("```sql\n" + render_tuple(a[1]) + "\n```")
                    else:
                        print(f"- **#{n} 추가 SORT {a[1]['sort']}** — 같은 카테고리 구역, SORT {prev} 행 바로 뒤(이 튜플 끝에 쉼표):")
                        print("```sql\n" + render_tuple(a[1]) + ",\n```")
            if eng in URL_CHANGE:
                n += 1
                old, new = URL_CHANGE[eng]
                print(f"- **#{n} 정본 URL** — 세 곳(머리말 `-- URL:` 줄 · INSERT 의 CAREERS_BENEFIT_URL · UPDATE)의 `{old}` → `{new}`")
                for o, nw in HEADER_EDIT.get(eng, []):
                    print(f"  - 머리말 「참고」 줄 하나 교체(주석 · 따옴표 없음):\n    - 옛: `{o}`\n    - 새: `{nw}`")
        else:
            print("조치 없음(행 그대로).")
        print(f"\n헤더 한 줄(「참고」 블록 끝 · 닫는 ━━━ 줄 바로 위):\n```\n{HEADER_LINE[eng]}\n```")
        keeps = KEEP.get(eng, [])
        if keeps:
            print("\n바꾸지 않는 것(검증 권고 · 판단 요청 가운데 집행하지 않는 것):\n")
            print("| SORT | 코드 | 처리 | 이유 |")
            print("|---|---|---|---|")
            for s, cd, v, why in keeps:
                print(f"| {s} | `{cd}` | {v} | {why} |")


def sec_final(collect, final):
    print("=" * 100)
    print("§final 회사별 최종 행 수")
    tot_c = tot_f = 0
    for fn in FILES:
        eng = next(e for e, c in collect.items() if c["file"] == fn)
        nc, nf = len(collect[eng]["rows"]), len(final[eng])
        amt = [r for r in final[eng] if r["amt"] is not None]
        st = sum(1 for r in amt if derive_amt_source(r["amt"], r["qual"], r["note"]) == "stated")
        print(f"  {fn}\t{nc} → {nf}\t조치 {len(ACTIONS[eng]) + (1 if eng in URL_CHANGE else 0)}\t금액 행 {len(amt)}(stated {st} · 추정 {len(amt) - st}) 합 {sum(r['amt'] for r in amt)}")
        tot_c += nc
        tot_f += nf
    print(f"  합계 {tot_c} → {tot_f} · SD-3 147 + {len(FILES)} = {147 + len(FILES)} · SD-4 3179 + {tot_f} = {3179 + tot_f}")


def main(argv):
    collect = load_collect()
    final = apply_actions(collect)
    if argv and argv[0] == "check-seed":
        return check_seed(argv[1], collect, final)
    corpus = load_corpus()
    secs = argv or ["all"]
    want = lambda s: "all" in secs or s in secs  # noqa: E731
    if "simulate" in secs or "all" in secs:
        simulate(collect, final)
        rcd = check_seed(SIM, collect, final)
        if "simulate" in secs and len(secs) == 1:
            return rcd
    if want("fmt"):
        sec_fmt(collect, final, corpus)
    if want("codes"):
        sec_codes(collect, final, corpus)
    if want("consist"):
        sec_consist(collect, final, corpus)
    if want("amt"):
        sec_amt(collect, final, corpus)
    if want("reg"):
        sec_reg(collect, corpus)
    if want("robots"):
        sec_robots()
    if want("legal"):
        sec_legal(collect)
    if want("pages"):
        sec_pages(collect, final, corpus)
    if want("chips"):
        sec_chips(collect, final)
    if want("final"):
        sec_final(collect, final)
    if "actions" in secs:
        sec_actions_md(collect, final)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
