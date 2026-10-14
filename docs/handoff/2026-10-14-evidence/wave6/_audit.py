#!/usr/bin/env python3
"""웨이브 6 코퍼스 횡단 감사 — 재현 스크립트 (2026-10-14).

출발점: /home/ubuntu/loupit-evidence/2026-10-10-wave5/audit/_audit.py (웨이브 5 감사 — 조치 모델 · simulate · check-seed)
        /home/ubuntu/loupit/docs/handoff/2026-09-19-evidence/wave4/_audit.py · _precheck.py

리포 모듈을 **실제로 import** 해서 돌린다(추측 금지 — 리포는 읽기만 · 바이트코드도 쓰지 않는다):
  db.seed.load._split_sql_statements            분할기(5문장 · 셋째 = UPDATE TCOMPANY SET CAREERS_BENEFIT_URL)
  db.seed.company_meta.parse_header_insert       등록 문장 파서 · ws_conditions · derive_work_style(근무형태 칩)
  generator.slug.slug_of                         slug
  db.seed.backfill_dec2._DATE_RE · _URL_RE · derive_amt_source   확인일 · 출처 URL · 금액 출처
  generator.benefit_rules load_pages · classify · text_hash · validate_all   항목 페이지
  generator.pages.find _most_common · LABEL_OVERRIDE                           /find 대표 이름
  W6/_row_check.py check()                       SI-9 · SI-11 · SI-12 · SI-13d · SI-B2 사전 점검(게이트와 같은 함수)
  /home/ubuntu/loupit-evidence/2026-10-02-recollect-3-7/_len_check.py  필드 길이 · 행 파서(parse_values)

사용:
  python3 _audit.py [섹션 ...]          섹션 없으면 all(actions 제외)
    fmt      수집본 · 모의본 형식(분할기 · 머리말 · 등록 · slug · 표시명 · 길이 · 따옴표)
    codes    신규 코드(어휘표 89종 · 코퍼스 실사용 대비) · 신규 2종 코퍼스 전문 grep
    consist  그룹 · 통합 각주 세 꼴 표 · 성과급 꼴 · 형제 문장 겹침 · 난임 11-27 목록 · 보상휴가 · 기타장기종업원급여
    amt      금액 전수(예측 금액 출처) · 회사별 합
    reg      등록 값 표 · 업종 합류 · corp_code 대조
    legal    _legal_scan.py 를 수집본 · 모의본에 돌린 결과
    pages    항목 페이지 예외(모의 최종 문안 해시) · validate_all · MIN_COMPANIES 문턱 · /find 대표 이름
    chips    derive_work_style 회사별 결과
    actions  §5 본문(집행형) — 조치 모델에서 글자 그대로 찍는다
    final    최종 행 수 · 핀
    simulate 조치 모델을 수집본 텍스트에 적용해 W6/audit/sim/<파일명>.sql 를 쓰고 check-seed 로 자가 시험
  python3 _audit.py check-seed <폴더>   그 폴더의 13파일을 최종본 모델과 행 단위 · 전 필드 대조 → 「형식 문제 n · 불일치 n」
  python3 _audit.py search <정규식>     코퍼스 160파일 행(이름 · NOTE · 서술)에서 정규식 검색(주석 제외)
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

REPO = "/home/ubuntu/loupit"
W6 = "/home/ubuntu/loupit-evidence/2026-10-14-wave6"
COLLECT = W6 + "/collect"
SIM = W6 + "/audit/sim"
CORPUS = REPO + "/db/seed/benefit/sql"
VOCAB = W6 + "/_VOCAB.md"
LEN_CHECK = "/home/ubuntu/loupit-evidence/2026-10-02-recollect-3-7/_len_check.py"
LEGAL_SCAN = REPO + "/docs/handoff/2026-09-19-evidence/_legal_scan.py"
ROW_CHECK = W6 + "/_row_check.py"

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

# 계약 「웨이브 6 전용」 대상 13파일(계약 순서)
FILES = ["현대위아", "대웅제약", "빙그레", "이수스페셜티케미컬", "HJ중공업", "SFA반도체", "BGF리테일",
         "에스원", "세방전지", "SK케미칼", "파라다이스", "금호석유화학", "GS리테일"]
MAXLEN = {"nm": 100, "note": 200, "qd": 500}  # db/schema.sql — BENEFIT_NM · NOTE_CTNT · QUAL_DESC_CTNT
META_MAX = {"eng": 30, "nm": 100, "ind": 50, "logo": 10, "url": 500}  # db/schema.sql:36-43
CTGR = {"compensation", "health", "family", "leisure", "perks", "growth", "time_off", "flexibility", "work_env"}
HDR_INSERT = rc.HDR_INSERT
UPD = rc.UPD
TUPLE = re.compile(  # 원문 텍스트 안 튜플 위치(모의본 쓰기용) — 행 파서는 lc.parse_values 가 정본
    r"\(\s*@comp_id\s*,\s*'((?:[^']|'')*)'\s*,\s*'((?:[^']|'')*)'\s*,\s*(NULL|-?[\d.]+)\s*,\s*'([a-z_]+)'\s*,"
    r"\s*'([a-z_]+)'\s*,\s*(NULL|'(?:[^']|'')*')\s*,\s*(TRUE|FALSE)\s*,\s*(NULL|'(?:[^']|'')*')\s*,\s*(\d+)\s*\)",
    re.S)
ROSTER_NM = {  # eng(slug) → 리드 명단 · DART check 의 회사 이름
    "hyundai_wia": "현대위아", "daewoong_pharm": "대웅제약", "binggrae": "빙그레",
    "isu_specialty_chemical": "이수스페셜티케미컬", "hj_heavy": "HJ중공업", "sfa_semicon": "SFA반도체",
    "bgf_retail": "BGF리테일", "s1": "에스원", "sebang_battery": "세방전지", "sk_chemicals": "SK케미칼",
    "paradise": "파라다이스", "kumho_petrochemical": "금호석유화학", "gs_retail": "GS리테일"}


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


def rtext(r: dict) -> str:
    return " ".join(x for x in (r["nm"], r["note"] or "", r["qd"] or ""))


def search(pattern: str, corpus: dict, show: int = 160) -> list:
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


# ── §5 조치 모델 (보고서 §5 와 1:1 — 통합 결과는 check-seed 로 이 모델과 대조한다) ─────────────────
# 종류: set(SORT, 필드=값) · recode(SORT, 새 코드, 필드=값) · delete(SORT) · add(행 dict)
#       move(옛 SORT, 새 행 dict) — 옛 튜플을 지우고 새 SORT 자리(다른 카테고리 구역)에 새 튜플을 넣는다(재코딩 + 섹션 이동)
# 문자열은 검증 보고서의 백틱 글자를 기계로 뽑아 넣었다(`_extract.json` · 손 옮김 0). GS리테일 SORT 50 만 리드 판정 (110) ② 의
# 「아이 사랑 휴직 (인재경영 지표 Life 항목), 」 삽입(검증 보고서 §8 ② 의 위치 · 글자 그대로)을 더했다.
def _row(cd, nm, amt, ctgr, note, qual, qd, sort):
    return dict(cd=cd, nm=nm, amt=amt, ctgr=ctgr, badge="est", note=note, qual=qual, qd=qd, sort=sort)


DATE = "2026-10-14"
ACTIONS: dict[str, list] = {
    "hyundai_wia": [
        ("move", 41, _row('welfare_point', '주간 연속 2교대 포인트', None, 'perks', None, True, '주간 연속 2교대 포인트: 자기개발을 위한 40만원/반기 포인트 지급 (2026 지속가능성보고서 54쪽 복리후생 제도 문화·여가 지원 항목) — 지급 대상 범위·포인트 사용처 미기재', 64)),
        ("add", _row('self_development', '자격증 취득 지원', None, 'growth', None, True, '자격증 취득 지원 (2026 지속가능성보고서 51쪽 자기주도적 직무 역량 강화 항목) — 지원 대상 자격증·지원 비용·지원 방식 미기재', 41)),
        ("add", _row('remote_work', '원격근무제(재택근무 포함)', None, 'flexibility', None, True, '원격근무제(재택근무 포함) 활용, 사용자 2026년 상반기 57명 · 2025년 70명 (2026 반기보고서 직원 등 현황 유연근무제도 사용현황 항목) — 대상 직무·사용 조건 미기재', 11)),
    ],
    "daewoong_pharm": [
        ("set", 20, dict(qd='자율적으로 성과를 창출할 수 있는 임직원을 대상으로 유연근무제 운영, 출퇴근 시간을 자율적으로 선택 (2026 지속가능경영보고서 68쪽 자율적 업무 몰입환경 조성 항목), 시차출퇴근제·선택근무제를 직무 특성, 질환, 주거 여건, 임신 및 출산 등 내부 기준에 따른 특별 사유로 활용 (2025 사업보고서 직원 등 현황 유연근무제도 항목) — 코어타임·신청 절차 미기재')),
        ("add", _row('remote_work', '원격근무제 (조건부)', None, 'flexibility', None, True, '근무 장소를 자율적으로 선택할 수 있도록 지원 (2026 지속가능경영보고서 68쪽 자율적 업무 몰입환경 조성 항목), 원격근무제를 직무 특성, 질환, 주거 여건, 임신 및 출산 등 내부 기준에 따른 특별 사유로 활용 (2026 반기보고서 직원 등 현황 유연근무제도 항목) — 원격근무 장소·횟수·신청 절차 미기재', 22)),
        ("add", _row('childcare', '사내 어린이집', None, 'family', None, True, '사내 어린이집 (2026 지속가능경영보고서 130쪽 목표 추진 주요 활동 항목) — 설치 사업장·정원·이용 대상 미기재', 72)),
    ],
    "binggrae": [
        ("set", 11, dict(nm='명절조 지급', qd='명절조 지급 (공식 채용 페이지 복리후생 Pay 항목, 2026 지속가능경영보고서 67쪽 복리후생 제도 표) — 지급 내용·금액 미기재')),
        ("add", _row("birthday_gift", "기념일 선물", None, "perks", None, True, '각종 기념일 선물 지급 (공식 채용 페이지 복리후생 Environments 항목, 2026 지속가능경영보고서 67쪽 복리후생 제도 표), 임직원 기념일 기프트 카드 지급 (2024년 12월 보도자료) — 기념일 종류·선물 금액 미기재', 25)),
        ("set", 40, dict(qd='전국 주요콘도 이용 (공식 채용 페이지 복리후생 Benefits 항목, 2026 지속가능경영보고서 67쪽 복리후생 제도 표), 하계휴양소 운영 (2024년 12월 보도자료) — 이용 일수·본인 부담 미기재')),
        ("set", 41, dict(nm='사내 동우회', qd='사내 동우회 (공식 채용 페이지 복리후생 Benefits 항목, 2026 지속가능경영보고서 67쪽 복리후생 제도 표), 동우회를 통해 임직원 간 소통과 취미 활동 지원 (같은 보고서 67쪽 노사관리 및 소통), 직원 동우회 활동 (2024년 12월 가족친화인증 재획득 보도자료) — 동우회 지원 금액·동우회 종류 미기재')),
        ("set", 93, dict(nm='스마트러닝·학습조직 (Study Group)·자기주도·동료학습·Culture Class', qd='스마트러닝, 학습조직 (Study Group), 자기주도·동료학습 (공식 채용 페이지 복리후생 Learning & Development 항목), Smart Learning(역량개발 도서학습), 자율적 학습조직(Study Group) (2026 지속가능경영보고서 63쪽 자기주도·동료학습), 필요한 교육과 학습자원을 자유롭게 활용하고 동료와 함께 배우는 자기주도·동료학습 (같은 보고서 64쪽), Culture Class를 통한 임직원 취미 활동 지원 (같은 보고서 67쪽 노사관리 및 소통), 다양한 문화 강좌 운영 (2024년 12월 가족친화인증 재획득 보도자료) — 학습조직 지원 금액·학습 플랫폼·강좌 종류 미기재')),
        ("set", 51, dict(qd='정기 건강검진, 배우자 종합검진 (공식 채용 페이지 복리후생 Benefits 항목), 종합 건강검진 실시, 일정 연령 이상 임직원의 배우자 대상 건강검진(격년) (2026 지속가능경영보고서 75쪽 보건 관리), 본인 및 배우자 종합검진 (2024년 12월 가족친화인증 재획득 보도자료) — 종합검진 대상 범위·검진 항목·배우자 대상 연령 미기재')),
        ("add", _row("career", "이동희망 신청 (연중 상시)", None, "growth", None, True, '연중 상시로 이동희망 신청 접수 (2026 지속가능경영보고서 61쪽 공정한 채용과 기회 제공) — 이동 가능 부서·선발 기준 미기재', 95)),
    ],
    "isu_specialty_chemical": [
        ("set", 40, dict(qd='콘도 및 하계 휴양소 운영 (공식 채용 페이지 복리후생 여가활용, 가족지원 항목), 복지용 휴양소를 매입하여 임직원 복지로 활용 (2026 반기보고서 신규사업 부동산 매매 및 임대업 항목) — 이용 조건·지원 범위 미기재')),
        ("set", 62, dict(nm='OA 과정 (Excel·Power Point·Word)', qd='역량개발교육체계 자기개발 과정의 OA(Excel · Power Point · Word / 한글) 과정 (공식 채용 페이지 교육제도 항목) — 운영 방식·수강 대상·비용 부담 미기재')),
    ],
    "hj_heavy": [
        ("set", 90, dict(qd='유연근무제 운영 (2025 지속가능경영보고서 57쪽 가족친화 인증기업 선정 본문) — 제도 유형·대상 미기재')),
    ],
    "sfa_semicon": [
        ("add", _row('discount', '제휴업체 할인', None, 'perks', None, True, '제휴업체 할인 (공식 채용 페이지 복리후생 기타 제휴업체 할인 항목) — 제휴처·할인율 미기재', 22)),
        ("add", _row('incentive', '개인성과급', None, 'compensation', None, True, '「직원과 함께 개인성과급 산정」 (2026 반기보고서 이사·감사의 보수지급기준 등기이사 성과급 항목) — 직원 지급 기준·지급률 미기재', 73)),
    ],
    "bgf_retail": [
        ("set", 10, dict(qd='매년 임직원 가족 초청 행사 진행, 2025년 5월 임직원 자녀 대상 스마트 오피스 투어와 10월 부모님도 함께 초대한 BGF 진천 CDC 물류센터 투어 (2025-2026 지속가능경영보고서 70쪽 임직원 가족 초청 행사), 임직원 간 소통 및 화합 컨셉 시너지데이(문화·체육·봉사활동 및 힐링 프로그램 등 연 1회 지원) (66쪽 소통 활성화 프로그램 항목), BGF만의 차별화 된 온택트 프로그램 운영 (71쪽 복리후생 제도 개인&회사 성장 PLUS 항목), 조직활성화 프로그램 좋은 친구 온(溫)택트의 지역부원들과 함께하는 원데이 클래스 찾아가는 문화다방 (66쪽) — 행사 비용 지원 범위·참가 대상 미기재')),
        ("set", 80, dict(qd='자기개발 지원(자격증) (2025-2026 지속가능경영보고서 71쪽 복리후생 제도 개인&회사 성장 PLUS 항목), 자격증 취득 지원 제도로 업무 관련 자격증을 취득한 임직원에게 난이도별 축하금 차등 지급, 2025년 97명 (69쪽 자기개발 지원 제도 자격증/어학 취득 지원 항목) — 난이도별 축하금 금액 미기재')),
        ("set", 81, dict(qd='자격증·어학 취득 지원 제도로 어학 취득 임직원에게 난이도별 축하금 차등 지급, 2025년 131명 (2025-2026 지속가능경영보고서 69쪽 자기개발 지원 제도 자격증/어학 취득 지원 항목), 온라인 교육 플랫폼 BSA(BGF Smart Academy)로 어학/OA 교육 콘텐츠 제공 (67쪽 인재육성 항목) — 대상 어학시험·축하금 금액 미기재')),
        ("set", 82, dict(qd='BGF 문화다방 월 2회 온라인 클래스로 취미생활 및 자기개발 지원(가족 및 지인과 함께 참여 가능, 26년부터 팀 단위 참여 확대) (2025-2026 지속가능경영보고서 71쪽 임직원 리프레시 지원 프로그램 표), 자기개발 지원(학습조직(CoP)) (71쪽 복리후생 제도 개인&회사 성장 PLUS 항목), 문제해결형 학습조직(CoP) 학습 비용 외 필요 비용 지원 및 우수동아리 연 1회 포상 (69쪽 자기개발 지원 제도 학습조직(CoP) 지원 항목), 온라인 교육 플랫폼 BSA(BGF Smart Academy)로 인사이트·튜터링 등 교육 콘텐츠 제공, AI 활용 개인 맞춤형 과정 추천 (67쪽 인재육성 항목) — 클래스 주제·지원 금액 미기재')),
        ("delete", 40),
        ("set", 22, dict(nm='임신기 단축근무 전 기간·출산 경조금·자녀 선물·입학 축하금·자녀 등교·졸업 휴가', qd='임신 여직원 1일 2시간 근로시간 단축을 법정 기간(12주 이내 또는 32주 이후) 포함 임신 기간 전체에 대하여 신청자 희망 시 사용 가능, 임직원 자녀출산 경조금 지급, 임직원 자녀 초등학교 입학 축하 선물 지급, 임직원 자녀 어린이날 선물 지급, 임직원 자녀 중/고 입학 축하금 지급, 우리아이 첫 등교 응원 휴가 1일, 임직원 자녀 초/중/고 졸업 휴가 1일 (2025-2026 지속가능경영보고서 70쪽 맞춤형 지원 제도 모성 및 여직원 보호제도·가족친화제도 항목), 임직원 자녀 격려 선물 지급 (71쪽 복리후생 제도 일&삶 균형 PLUS 항목) — 경조금·축하금 금액·선물 품목·휴가 유급 여부 미기재')),
        ("add", _row('lounge', '여성직원 휴게실 (수유실 겸용)', None, 'work_env', None, True, '여성직원 휴게실을 겸하여 수유실 용도의 공간 운영 (2025-2026 지속가능경영보고서 70쪽 맞춤형 지원 제도 모성 및 여직원 보호제도 항목 주석) — 운영 사업장·휴게 설비 미기재', 31)),
    ],
    "s1": [],
    "sebang_battery": [
        ("set", 11, dict(qd='우수한 성과를 인정하는 다양한 포상제도 운영 (공식 채용정보 페이지 인사제도 보상제도 항목), 모범적인 협업 사례와 긍정적 행동을 발굴·포상하는 착한동료상 상·하반기 연 2회 운영 (2025 지속가능경영보고서 46쪽 조직문화 확산 캠페인 항목) — 포상 금액·포상 내용 미기재')),
        ("add", _row('welfare_fund_loan', '사내 대출제도', None, 'perks', None, True, '사내 대출제도, 신청 및 상환 과정의 자발성·투명성 강화 (2025 지속가능경영보고서 44쪽 인권실사 인권 리스크 식별 및 개선 활동 항목) — 대출 용도·한도·이율 미기재', 23)),
        ("add", _row('company_event', '체육대회·원팀데이·에너지충전소', None, 'leisure', None, True, '노사 간 화합과 상호 이해 증진을 위해 매년 체육대회 등 화합 프로그램 개최 (2025 지속가능경영보고서 45쪽 노사 화합 프로그램 항목), 협업 미션 · 소통 프로그램 · 취미·문화 공유 프로그램으로 구성된 분기별 전사 원팀데이 · 임직원 사기 진작을 위한 에너지충전소 오프라인 이벤트 (2025 지속가능경영보고서 46쪽 전사 참여 프로그램 항목) — 참가 대상·비용 지원 범위 미기재', 41)),
        ("add", _row('long_service_bonus', '장기근속 급부', None, 'compensation', None, True, '장기 근속 임직원에게 기타장기종업원급여 제공 (2025 사업보고서 재무제표 주석 종업원급여 항목) — 근속 기준·급부 형태·금액 미기재', 14)),
    ],
    "sk_chemicals": [
        ("set", 73, dict(qd='심리상담 프로그램 「토닥토닥」 운영 (공식 ESG 사이트 일과 삶의 균형 보장 페이지 복리후생 제도 건강 관리 항목), 2021년부터 근무자 지원 프로그램(EAP) 업체를 활용한 심리상담 프로그램, 사내에서 대면 및 비대면으로 제공되는 심리상담 프로그램 「토닥토닥」 (2025 지속가능경영보고서 97쪽 건강 관리 항목), 구성원과 가족의 정신건강을 위해 전문상담사와 함께하는 1:1 맞춤형 심리상담 「토닥토닥」 (같은 보고서 106쪽 구성원 건강관리 프로그램 항목) — 상담 횟수·비용 부담 미기재')),
        ("add", _row('company_event', '가족 초청 행사·행복충전 프로그램', None, 'leisure', None, True, '구성원 가족을 초청하여 기업과 업무의 의미에 대한 이해도를 제고하고 가족간의 유대감을 강화 (2025 지속가능경영보고서 96쪽 일과 삶의 균형 지원 제도 운영 현황 표 가족 친화 항목), 2025년 SK케미칼·SK플라즈마·SK바이오사이언스 3사 공동 구성원 가족 초청 행사와 봉사활동 등 참여형 프로그램 (같은 보고서 96쪽 가족 초청 행사 항목), 판교 ECO Lab 본사 구성원의 정서적 안정과 활력증진을 위한 음악회 감상·게임 등 참여형 행복충전 프로그램 (같은 보고서 106쪽 구성원 건강관리 프로그램 항목) — 개최 주기·참가 범위 미기재', 62)),
        ("recode", 54, "grocery_support", {}),
    ],
    "paradise": [
        ("set", 81, dict(nm='온라인 학습 플랫폼 파라人SIGHT·독서 소모임 파라북클럽', qd='전 임직원이 시간과 장소의 제약 없이 학습할 수 있는 자기주도형 상시학습 온라인 플랫폼 파라人SIGHT 운영, 사내 콘텐츠 약 320편 제공 (2025 지속가능경영보고서 48쪽 인재 육성 프로그램), 구성원 간 독서 기반 소통 강화 및 토론 역량 향상을 위한 독서 소모임 파라북클럽 운영, 2025년 132명·23개 소모임 (48쪽 독서경영 프로그램 표) — 활동비 지원 여부·참여 조건 미기재 (파라다이스 · 파라다이스시티 · 호텔 부산 통합 보고 기준)')),
        ("set", 90, dict(qd='직원 연봉에 기본급과 함께 성과급 포함 (2025 지속가능경영보고서 99쪽 남성 대비 여성 연봉(기본급+성과급) 비율 표·104쪽 직원 급여(기본급+성과급) 중간값 표), 보상 수준은 경영계획에 기반한 목표 달성도 등을 기준으로 결정, 특히 연초에 설정한 영업이익 목표 대비 달성 성과를 핵심 기준으로 적용, 평가 기반 차등 보상 (49쪽 성과 보상 제도) — 지급률·지급 시기 미기재 (파라다이스 · 파라다이스시티 · 호텔 부산 통합 보고 기준)')),
    ],
    "kumho_petrochemical": [
        ("add", _row('clinic', '보건관리실 (본사·울산·여수)', None, 'health', None, True, '본사, 울산사업장, 여수사업장에 보건관리실을 구축하고 전담인력(간호사)을 채용하여 현장 중심의 건강관리 체계 운영 (2025 지속가능경영보고서 89쪽 임직원 건강 관리 지원 항목) — 진료 범위·운영 시간 미기재', 54)),
    ],
    "gs_retail": [
        ("set", 50, dict(qd='출산 축하금 및 선물 지원 (2025 지속가능경영보고서 59쪽 축하 선물 지급 항목), 출산 축하 선물 및 다자녀 출산 경조금 (공식 홈페이지 인재경영 지표 Engagement 축하 선물 지급 항목), 자녀 양육 지원 보육비 지급과 다자녀 출산 지원금, 법정 기준을 초과한 육아휴직 제도 운영 (같은 보고서 58쪽 가족친화제도), 아이 사랑 휴직 (인재경영 지표 Life 항목), 임직원 자녀 입학 선물 (인재경영 지표 Life 항목) — 축하금·보육비 금액, 지원 연령, 육아휴직 초과 기간·휴직 중 급여 미기재')),
        ("set", 51, dict(nm='자녀 학자금 (고교·대학 입학금·등록금)·유치원 보조비', qd='근속 년수에 따라 국·내외 고등학생, 대학생 자녀가 있는 임직원에게 입학금과 등록금 지원 (2025 지속가능경영보고서 59쪽 자녀 교육비 지원 항목), 유치원 보조비 지급 (같은 보고서 58쪽 가족친화제도 자녀 양육 지원 항목), 유치원 보조비, 자녀 학자금 지원 (공식 홈페이지 인재경영 지표 Life 항목) — 근속 연수 기준·지원 한도·유치원 보조비 금액·자녀 수 제한 미기재')),
        ("set", 73, dict(qd='내일On (이러닝 플랫폼), 전사 인사이트 특강, 자기주도학습/사외과정 지원제도 (2025 지속가능경영보고서 56쪽 자기주도 학습 · 공식 홈페이지 인재육성체계 자기주도 학습 항목), 홈쇼핑BU에서는 구성원이 원하는 사외교육을 자율적으로 선택해 학습할 수 있도록 연간 교육비 한도 내에서 지원 (같은 보고서 56쪽) — 교육비 한도 금액 미기재')),
        ("add", _row('leave_buyout', '미사용 휴가 1.5배 보상', None, 'compensation', None, True, '휴가촉진제 실시 후 25% 범위 내 미사용분에 대해 1.5배 보상 (2025 지속가능경영보고서 59쪽 휴가 보상 항목), 미사용 분에 대해 일부 1.5배 보상 (공식 홈페이지 인재경영 지표 Leisure 휴가 보상 항목) — 보상 기준 금액 미기재', 42)),
    ],
}


# 항목 페이지 동반 조치(리드 집행 — generator/data/benefit_pages/<code>.json overrides)
#   검증 보고서의 JSON 을 기계로 뽑았다. h 는 모의 최종 문안으로 다시 계산해 대조한다(sec_pages).
OVERRIDES: list[tuple[str, dict]] = [
    ('incentive', {"comp": "hyundai_wia", "h": "e2549caaf9", "mode": "individual", "why": "52쪽 「일반직의 경우 평가 결과를 기반으로 성과급을 산정·지급」 — 인사평가 결과에 따른 성과급"}),
    ('self_development', {"comp": "daewoong_pharm", "h": "43680e2603", "mode": "allowance", "why": "원문 「리프레시 기간 동안 자기계발 교육이 필요한 경우 최대 100만 원까지 교육비를 지원」 — 자기계발 교육비를 돈으로 대 준다"}),
    ('edu_support', {"comp": "daewoong_pharm", "h": "7b6dc4e6ea", "facets_add": ["external"], "why": "원문 「사내/외 교육」 — 사외 교육을 지원 범위에 적었는데 규칙 정규식은 「사내외」만 본다"}),
    ('books', {"comp": "daewoong_pharm", "h": "2f5a0d6adc", "facets_remove": ["limit"], "why": "「무제한」은 사내/외 교육·사이버연수원·도서지원·사내북카페를 묶은 학습 환경 전체에 붙은 말이고 책값 한도를 밝힌 문장이 아니다"}),
    ('incentive', {"comp": "binggrae", "h": "9cf9add7b4", "mode": "both", "why": "인사제도 페이지 Performance Incentive 「회사 전체 성과에 따라 지급 여부 및 지급률을 결정하고 개인 성과에 따라 차등 지급」 — 회사 실적과 개인 성과 둘 다"}),
    ('resort', {"comp": "hj_heavy", "h": "5bdeb8b542", "facets_add": ["paid"], "why": "채용 페이지 휴양소 지원 「제휴 휴양소 무료 이용」 — 이용료를 회사가 부담"}),
    ('leave_general', {"comp": "hj_heavy", "h": "eb2351fde2", "facets_add": ["reason"], "why": "채용 페이지 「건강검진·결혼기념일 휴가」 · 보고서 57쪽 「결혼기념일 휴가」 — 결혼기념일이라는 사유를 정해 주는 휴가"}),
    ('mental', {"comp": "bgf_retail", "h": "fc655d0e15", "mode": "external", "why": "원문은 EAP 프로그램(빅데이터 기반 상담센터 추천 · EAP 모바일 플랫폼)으로 사내 상담실이 아니다 — 「상담센터」 낱말이 사내 규칙에 걸렸다"}),
    ('health_check', {"comp": "bgf_retail", "h": "32725588d0", "facets_remove": ["family"], "why": "「배우자」는 독감 예방 접종 대상이다 — 가족 건강검진은 원문에 없다"}),
    ('mental', {"comp": "s1", "h": "daa4c2f7b5", "facets_remove": ["family"], "why": "「커플사랑더하기 · 자녀양육 프로그램」은 상담 프로그램 이름이다 — 가족도 이용하는지는 원문에 없다"}),
    ('fitness', {"comp": "s1", "h": "cf65aea160", "mode": "inhouse", "why": "「레포츠센터 운영」 — 회사가 운영하는 운동 시설이다(복리후생 건강 증진 항목)"}),
    ('mental', {"comp": "sk_chemicals", "h": "ec50bb27bc", "mode": "both", "why": "근무자 지원 프로그램(EAP) 업체를 활용한 상담과 사내 대면·비대면 「토닥토닥」을 함께 운영한다 — 「사내」에 먼저 걸려 회사 밖 기관 몫이 빠졌다"}),
    ('lang', {"comp": "sk_chemicals", "h": "1c0b7599ba", "mode": "both", "why": "어학 교육 과정 제공과 「어학지원금」 지원을 함께 적었다 — 「지원금」 낱말이 학습비 규칙에 없어 수업 쪽으로만 잡혔다"}),
    ('incentive', {"comp": "sk_chemicals", "h": "3dfb2265fc", "mode": "both", "why": "「업적평가」(개인 평가)와 「사업 성과」(회사 실적)에 따른 인센티브 보너스를 한 문장에 적었다"}),
    ('flex_work', {"comp": "paradise", "h": "b5af0e0780", "mode": "start", "why": "원문 「2주 단위~3개월 단위 탄력적 근로시간제」는 회사가 근로시간을 단위 기간 안에서 배분하는 제도이고 직원이 근무 시간 길이를 고르는 제도가 아니다 — 직원이 고르는 것은 시차출퇴근제의 출퇴근 시간"}),
    ('fitness', {"comp": "paradise", "h": "d719a7a50a", "mode": "inhouse", "facets_add": ["hours"], "why": "원문 항목명이 「사내 피트니스」이고 내용이 「무인 피트니스 시설 24시 운영」 — 회사 안 시설 · 24시간 이용"}),
    ('mental', {"comp": "paradise", "h": "c95ed5857b", "facets_add": ["remote"], "why": "원문 「온 · 오프라인 심리 상담 서비스」 — 온라인 상담을 밝혔는데 규칙 정규식은 「온오프라인」만 본다"}),
    ('parenting', {"comp": "paradise", "h": "e27eb41636", "facets_add": ["cash"], "why": "원문 「직장어린이집 위수탁계약을 맺은 기관을 통한 50% 보육료 지원」 — 보육료를 돈으로 대 준다"}),
    ('discount', {"comp": "paradise", "h": "a68f8ee55f", "facets_add": ["group"], "why": "원문 「임직원 대상 내부시설(객실, F&B, 원더박스, 씨메르 등) 할인」 — 자기 회사 · 계열 시설 할인"}),
    ('edu_support', {"comp": "paradise", "h": "213106fc58", "facets_add": ["study"], "why": "원문 「파라북클럽 — 구성원 간 독서 기반 소통 강화 및 토론 역량 향상, 132명, 23개 소모임」 — 회사 독서경영 프로그램이 여는 학습 소모임"}),
    ('incentive', {"comp": "kumho_petrochemical", "h": "22569ce1e4", "mode": "both", "why": "인사제도 페이지 「회사 및 개인의 성과에 따라 보장되는 인센티브 제도」 — 회사 성과와 개인 성과를 함께 반영"}),
    ('edu_support', {"comp": "kumho_petrochemical", "h": "3966958fbd", "facets_remove": ["external"], "why": "「수강」은 사내 교육 플랫폼 Wink-A 수강이고 교양특강은 명사를 사내로 초청한 것 — 회사 밖 교육 지원이 아니다"}),
    ('incentive', {"comp": "gs_retail", "h": "eda69ede11", "mode": "both", "why": "원문 「회사/BU/개인 성과를 가시화하여 공유하고 맞춤형 성과급을 제공」 — 회사 실적과 개인 성과를 함께 적었다, 「회사 성과」 낱말이 회사 실적 규칙에 없다"}),
]

# 조치마다 근거 한 줄(§5 표의 「근거」 열) — ACTIONS 와 같은 순서
WHY: dict[str, list[str]] = {
    "hyundai_wia": [
        "검증 레인 1 조치 1 — 원문 지급 형태가 「포인트」(어휘 함정: 포인트 = `welfare_point` · 자기계발**비** = `self_development`), 2025 판 「복지포인트」 줄이 2026 판에서 이 줄로 합쳐졌다. 금액 NULL 은 리드 판정 (107) ①(2교대 근무자 한정 — 규칙 4-3 · 4-7)",
        "검증 MISSED — 51쪽 「자격증 취득 지원」(규칙 8 업무 교육 열거 밖 · 「섞이면 복지 쪽만」), 완성 튜플 그대로 · 재코딩으로 비게 된 SORT 41",
        "리드 판정 (107) ③ — 2026 반기보고서 유연근무제도 사용현황 「원격근무제(재택근무 포함)」 57명, 검증 A-6 튜플 그대로. 「(재택근무 포함)」은 규칙 13 한정 꼴이 아니라 맨 칩(DB손해보험 · 현대글로비스 선례와 같음)",
    ],
    "daewoong_pharm": [
        "리드 판정 (109) ② — 원격근무 몫을 SORT 22 로 떼고 이 행은 시차출퇴근 · 선택근무만(검증 7절 ③ 문안 그대로 · 205자)",
        "리드 판정 (109) ② — 공시 표 「원격근무제」 + 주석 「특별 사유로 활용」 = 사유 한정 → 이름 「(조건부)」(규칙 13), 검증 튜플 그대로",
        "리드 판정 (109) ① — 2026 보고서 130쪽 「주요 활동」 칸 「사내 어린이집」(최신 판 · (98)) · 2025 판 리틀베어 운영 문장이 받침, 검증 튜플 그대로",
    ],
    "binggrae": [
        "리드 판정 (106) ① — 명절조만 `holiday_gift` 에 남긴다(검증 §7 ① 문안)",
        "리드 판정 (106) ① — 「각종 기념일 선물」 · 「임직원 기념일 기프트 카드」 = 개인 기념일 급부 → `birthday_gift`(어휘표 대표 명칭 「기념일 선물」), 검증 §7 ② 튜플 그대로",
        "검증 §7 ③ — 출처 괄호 「가족친화인증 재획득 보도자료」의 「가족」이 항목 페이지 resort 「가족도 이용」 면을 켠다(원문에 가족 이용 없음) → 출처 괄호를 「2024년 12월 보도자료」로",
        "검증 §7 ④ — Culture Class · 문화 강좌는 코퍼스 · 어휘표상 `edu_support` 몫이라 동우회 행에서 걷는다(SORT 93 으로)",
        "검증 §7 ⑤ — SORT 41 에서 걷은 Culture Class · 문화 강좌를 받는다",
        "검증 §7 ⑥ — 원문 「전 직원을 대상으로 일반 및 종합 건강검진」에서 법정 「일반」만 걷으며 「전 직원 … 종합」 단언이 생겼다(규칙 2 · 3-4) → 수식어를 걷고 꼬리에 「종합검진 대상 범위」",
        "검증 MISSED — 61쪽 「연중 상시로 이동희망 신청을 접수」(사원이 스스로 지원하는 사내 이동 — 어휘표 career 정의), 완성 튜플 그대로",
    ],
    "isu_specialty_chemical": [
        "검증 조치 1 — 가장 새 공시 2026 반기보고서 신규사업 절 「복지용 휴양소를 매입하여 임직원 복지로 활용」 보강",
        "리드 판정 (105) — 「자기관리」 칸은 리더십과 한 묶음(업무 교육)이라 걷고 OA 과정만 남긴다(검증 조치 2 문안)",
    ],
    "hj_heavy": [
        "검증 §7 ① — 출처 괄호 안 「… 제도 중 하나로 기재」는 원문 서술 방식 메모(규칙 8-3 금지 꼴 「○○로 표기」류) → 걷는다",
    ],
    "sfa_semicon": [
        "검증 MISSED 1 — 복리후생 목록의 항목 라벨 「제휴업체 할인」(규칙 9 · ⚖ C-5. C-16 이 빼는 것은 혜택 없는 제휴카드), 에코프로 2사 같은 꼴 선례 · 완성 튜플 그대로",
        "리드 판정 (104) — 반기보고서(정정) 이사 보수지급기준 「직원과 함께 개인성과급 산정」 = 직원 적용을 스스로 밝힌 문장(규칙 11-1 예외), 검증 튜플 그대로 · 임원 산정 기준은 옮기지 않음",
    ],
    "bgf_retail": [
        "검증 M-3 — 71쪽 복리후생 표 라벨 「BGF만의 차별화 된 온택트 프로그램 운영」 + 66쪽 원데이 클래스를 받는다(규칙 9 · ⚖ C-5)",
        "검증 §6-3 — 「자격증·어학 취득」의 「어학」이 항목 페이지 self_development 「쓸 수 있는 곳」 면을 켠다 → 이 행은 「자격증 취득」 몫만",
        "검증 M-2 — 67쪽 BSA 학습 플랫폼의 어학/OA 콘텐츠를 받는다(규칙 8 학습 플랫폼 · 회사가 여는 어학 과정)",
        "검증 M-2 — 67쪽 BSA 학습 플랫폼의 인사이트 · 튜터링 · AI 과정 추천을 받는다(직무 · 리더십 몫은 뺀다)",
        "검증 SORT 40 SUSPECT — 자녀 첫 등교 · 졸업 휴가는 코퍼스 7사 전부 `parenting`(항목 페이지 parenting 「자녀 입학 때 쓰는 휴가·휴직」 칸) → SORT 22 로 병합하고 이 행을 지운다",
        "검증 조치 5 — SORT 40 의 원문 두 구절을 받는다(이름 · 서술 교체)",
        "검증 M-1 — 70쪽 주석 3 「여성직원 휴게실을 겸하여 수유실 용도의 공간」 = 성별 휴게실 + 수유 시설 → 시설별 두 행(§0-1 5), 완성 튜플 그대로",
    ],
    "s1": [],
    "sebang_battery": [
        "검증 A1 — 꼬리 「포상 종류 … 미기재」가 46쪽 착한동료상(상 · 하반기 연 2회)과 어긋난다 → 원문 구절을 보탠다(「동료 간 추천」은 항목 페이지 referral 오분류라 뺀 검증 문안)",
        "검증 M1 — 44쪽 「사내 대출제도」(규칙 12 — 용도 미기재 사내 대출 = `welfare_fund_loan`), 완성 튜플 그대로",
        "검증 M2 — 45쪽 매년 체육대회 · 46쪽 분기별 원팀데이 · 에너지충전소(코퍼스 체육대회 6사 `company_event`), 완성 튜플 그대로",
        "리드 판정 (103) — 재무제표 주석 「장기 근속 임직원에게 기타장기종업원급여를 제공」, 검증 A4 튜플 그대로",
    ],
    "sk_chemicals": [
        "검증 §7 1 — 106쪽 「구성원과 가족의 정신건강을 위해 … 토닥토닥」이 꼬리 「가족 이용 여부 미기재」와 어긋난다 → 원문 구절을 보태고 꼬리에서 가족 이용을 뺀다",
        "리드 판정 (108) — 기본안(96쪽 제도 표 「가족 초청 행사」 + 106쪽 행복충전 프로그램 한 행), 검증 튜플 그대로",
        "감사 §1-1 — 신규 코드는 세우되 이름을 제도 영역으로(「유기농」은 그 제도의 속성 — 웨이브 4 `smoking_cessation` 명명 선례). 이름 · 서술 · 카테고리 perks · SORT 그대로",
    ],
    "paradise": [
        "검증 MISSED-1 — 48쪽 전 임직원 자기주도형 상시학습 온라인 플랫폼 파라人SIGHT(규칙 8 학습 플랫폼)를 같은 코드 행에 합친다(UNIQUE) · 각주 (99) 유지",
        "리드 판정 (109) — 연봉 인상률 반영(급여 조정)을 성과급으로 옮기지 않는 검증 교체 문안 채택 · 각주 (99) 유지",
    ],
    "kumho_petrochemical": [
        "검증 MISSED — 89쪽 보건관리실(본사 · 울산 · 여수 · 간호사) · 27쪽 본사 신설. 법정 열거 · legal_baseline 밖이라 걸러 내면 거짓 부재, 완성 튜플 그대로",
    ],
    "gs_retail": [
        "검증 §7 1 + 리드 판정 (110) ② — 유치원 보조비를 SORT 51 로 옮기고, 「아이 사랑 휴직」을 58쪽 「법정 기준을 초과한 육아휴직 제도」의 회사 이름으로 이 서술에 흡수(검증 §8 ② 의 위치 · 글자)",
        "검증 §7 2 — 유치원 보조비 = 어휘표 `child_edu` 「유아교육비」(코퍼스 유치원 35:5)",
        "검증 §7 3 — 복합 라벨 「자기주도학습/어학/자격증/사외과정」에서 SORT 70 · 72 몫(어학 · 자격증)을 걷는다(규칙 8-3 각 행 자기 몫)",
        "리드 판정 (110) ① — 59쪽 · 웹 Leisure 「미사용분 1.5배 보상」 = 법(통상임금 1배) 위 급부. 신규 코드 `leave_buyout`(감사 §1-2 확정 · compensation), 검증 튜플 그대로",
    ],
}

# 정본 URL 교체 · 머리말 줄 교체 — 이번 웨이브 없음(13사 전부 점검기 ok)
URL_CHANGE: dict = {}
HEADER_EDIT: dict = {}
HEADER_LINE = {
    "hyundai_wia": "-- 검증 · 감사 판정 반영(2026-10-14): 주간 연속 2교대 포인트를 self_development 에서 welfare_point 로 재코딩(perks SORT 64 · 금액 NULL) · 자격증 취득 지원 self_development 추가 · 반기보고서 원격근무제(재택근무 포함) remote_work 추가 — 최종 35행",
    "daewoong_pharm": "-- 검증 · 감사 판정 반영(2026-10-14): 원격근무제 (조건부) remote_work 를 유연근무 행에서 떼어 추가 · 130쪽 사내 어린이집 childcare 추가(참고 블록 제외 목록의 어린이집 낱말 줄은 이 판정으로 뒤집힘) · 학자금 child_edu 유지 — 최종 18행",
    "binggrae": "-- 검증 · 감사 판정 반영(2026-10-14): 기념일 선물을 holiday_gift 에서 갈라 birthday_gift 추가 · Culture Class 를 동우회 행에서 edu_support 행으로 · 건강검진 전 직원 단언 걷기 · 휴양소 출처 괄호 정리 · 이동희망 신청 career 추가 · Mobile Office work_tools 유지 — 최종 29행",
    "isu_specialty_chemical": "-- 검증 · 감사 판정 반영(2026-10-14): 휴양소 행에 2026 반기보고서 복지용 휴양소 구절 보탬 · 자기개발 과정 행을 OA 과정만 남김(리더십 묶음 걷기) — 최종 19행",
    "hj_heavy": "-- 검증 · 감사 판정 반영(2026-10-14): 유연근무제 서술의 출처 메모 걷기 — 최종 25행",
    "sfa_semicon": "-- 검증 · 감사 판정 반영(2026-10-14): 제휴업체 할인 discount 추가(참고 블록 제외 목록의 제휴업체 할인 줄은 이 판정으로 뒤집힘) · 반기보고서의 직원과 함께 산정하는 개인성과급 incentive 추가 — 최종 17행",
    "bgf_retail": "-- 검증 · 감사 판정 반영(2026-10-14): 자녀 등교 · 졸업 휴가 leave_general 을 parenting 으로 병합 · 여성직원 휴게실 lounge 추가 · BSA 학습 플랫폼 어학 · 인사이트 몫과 온택트 프로그램 라벨을 기존 행 서술에 보탬 · 자격증 행 문안 정리 — 최종 26행",
    "s1": "-- 검증 · 감사 판정 반영(2026-10-14): 조치 없음 — 최종 25행",
    "sebang_battery": "-- 검증 · 감사 판정 반영(2026-10-14): 포상제도 행에 착한동료상 보탬 · 사내 대출제도 welfare_fund_loan · 체육대회와 원팀데이 company_event · 기타장기종업원급여 long_service_bonus 추가(참고 블록 제외 목록의 해당 줄은 이 판정으로 뒤집힘) — 최종 25행",
    "sk_chemicals": "-- 검증 · 감사 판정 반영(2026-10-14): 신규 코드를 grocery_support 로 확정(이름 · 서술 · perks 그대로) · 심리상담 행에 가족 이용 구절 보탬 · 가족 초청 행사와 행복충전 프로그램 company_event 추가(참고 블록의 가족 초청 행사 제외 줄은 이 판정으로 뒤집힘) — 최종 32행",
    "paradise": "-- 검증 · 감사 판정 반영(2026-10-14): 온라인 학습 플랫폼 파라人SIGHT 를 독서 소모임 행에 합침(참고 블록 제외 목록의 온라인 학습 플랫폼 줄은 이 판정으로 뒤집힘) · 성과급 서술 교체 — 최종 15행",
    "kumho_petrochemical": "-- 검증 · 감사 판정 반영(2026-10-14): 보건관리실 clinic 추가 · 재활수당 금액 NULL 유지 — 최종 29행",
    "gs_retail": "-- 검증 · 감사 판정 반영(2026-10-14): 신규 코드 leave_buyout 미사용 휴가 1.5배 보상 추가(참고 블록 제외 목록의 해당 줄은 이 판정으로 뒤집힘) · 유치원 보조비를 child_edu 로 · 아이 사랑 휴직을 육아 행 서술에 흡수 · 자기주도 학습 행을 자기 몫만 — 최종 26행",
}

# 검증 권고 · 판단 요청 가운데 감사가 집행하지 않는 것(리드 판정 · 감사 판정) — §5 「바꾸지 않는 것」 표
KEEP: dict[str, list[tuple]] = {
    "hyundai_wia": [(70, "holiday_gift", "코드 · 금액 50(stated) 유지", "리드 판정 (107) ② — 원문 「50만원/년 지급」 · 서술에 명절 낱말을 더하지 않는다"),
                    (64, "welfare_point", "금액 NULL 유지", "리드 판정 (107) ①")],
    "daewoong_pharm": [(71, "child_edu", "유지 · 서술에 「자녀」 더하지 않음", "리드 판정 (109) ③")],
    "binggrae": [(70, "work_tools", "유지", "리드 판정 (106) ②"), ("—", "(국제 심포지엄)", "싣지 않음", "리드 판정 (106) ③")],
    "isu_specialty_chemical": [(30, "child_edu", "유지", "검증 판단 요청 ① — 고등학교 학자금은 본인 대상으로 읽을 수 없음"),
                               ("—", "(대표이사 보수 칸 복지 금액)", "싣지 않음", "리드 판정 (100)")],
    "hj_heavy": [(44, "smoking_cessation", "유지(독립 행)", "검증 판단 요청 4 · 감사 §2-4 — 코드 이름이 제도 영역이라 프로그램형도 담는다"),
                 (40, "health_check", "유지(근거표 선례 인용만 정정)", "검증 §7 ③ — 시드 영향 없음")],
    "sfa_semicon": [(40, "edu_support", "유지(사내대학 라벨)", "검증 판단 요청 ①")],
    "bgf_retail": [("—", "(72쪽 육아휴직 추가 부여)", "싣지 않음", "검증 — 숫자 없음 · 70쪽 「법정육아휴직 자녀 1명당 1년」")],
    "s1": [(40, "child_edu", "유지(발달장애 자녀 실비 포함)", "리드 판정 (71) · 어휘표 child_edu 정의 · 감사 §2-3"),
           ("—", "(경력컨설팅센터)", "제외 유지", "규칙 3-3 · 직원 7,044명")],
    "sebang_battery": [(21, "housing_loan", "유지", "감사 §2-5 — 같은 문구 「전세자금 및 주택구입자금 지원」 코퍼스 3사가 `housing_loan` · 정리는 §14")],
    "sk_chemicals": [(30, "leave_general", "유지(휴가사용 자가승인)", "검증 판단 요청 ② · SK하이닉스 · 에이피알 선례"),
                     (31, "summer_leave", "유지", "검증 판단 요청 ③")],
    "paradise": [(30, "parenting", "유지(위탁보육)", "검증 — legal_baseline 밖 · 코퍼스 위탁보육 5:1 parenting"),
                 (51, "housing_support", "금액 NULL 유지", "월 최대 30만원 = 한도 + 거주 조건(규칙 4-3 · 4-7)")],
    "kumho_petrochemical": [(73, "disability_family_support", "금액 NULL 유지(600 권고 기각)", "리드 판정 (107)"),
                            (63, "housing_loan", "금액 NULL 유지", "대출 원금 한도(규칙 4-3)")],
    "gs_retail": [(32, "housing_support", "유지(원거리 지원금)", "검증 판단 요청 ④ — 웹 「주거비 일부」")],
}


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
            else:  # 삭제 — 튜플 줄 전체와 뒤 쉼표를 지운다
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
        # 3) 정본 URL · 머리말 줄(이번 웨이브 없음)
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
SECTIONS: dict = {}


def section(name):
    def deco(fn):
        SECTIONS[name] = fn
        return fn
    return deco


def main(argv):
    collect = load_collect()
    final = apply_actions(collect)
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
        print(f"  {c['file']:<10} eng={eng:<24} slug={sl:<24} 행 {len(c['rows']):>2} → 최종 {len(final[eng]):>2} · "
              f"수집본 형식 {p or 0} · 모의본 형식 {ps or 0} · 모의본 문장 {st} · 충돌 {coll or 0}")


NEW_CODES = ("grocery_support", "leave_buyout")


@section("codes")
def sec_codes(collect, final, corpus):
    print("=" * 100)
    print("§codes 신규 코드 — 어휘표 89종 · 코퍼스 실사용 대비")
    voc = vocab_table()
    used = collections.defaultdict(set)
    for eng, c in corpus.items():
        for r in c["rows"]:
            used[r["cd"]].add(eng)
    print(f"  어휘표 코드 {len(voc)} · 코퍼스 실사용 코드 {len(used)} · 어휘표 ≠ 실사용 {sorted(set(voc) ^ set(used)) or 0}")
    for label, rows_of in (("수집본", lambda e: collect[e]["rows"]), ("최종본", lambda e: final[e])):
        codes = collections.Counter(r["cd"] for e in collect for r in rows_of(e))
        new_v = sorted(c for c in codes if c not in voc)
        new_c = sorted(c for c in codes if c not in used)
        ctg = [(e, r["sort"], r["cd"], r["ctgr"], voc[r["cd"]][1]) for e in collect for r in rows_of(e)
               if r["cd"] in voc and voc[r["cd"]][1] != r["ctgr"]]
        new_rows = [(collect[e]["file"], r["sort"], r["cd"], r["ctgr"], r["nm"]) for e in collect for r in rows_of(e) if r["cd"] not in voc]
        print(f"  {label}: 행 {sum(codes.values())} · 코드 {len(codes)}종 · 어휘표 밖 {new_v or 0} · 코퍼스 미사용 {new_c or 0} · "
              f"카테고리 ≠ 어휘표 {ctg or 0}")
        for x in new_rows:
            print(f"     신규 행 {x}")
    allc = set(used)
    for e in collect:
        allc |= {r["cd"] for r in final[e]}
    print(f"  최종 반영 뒤 쓰이는 코드 수 {len(allc)} (지금 {len(used)})")
    print("\n  신규 2종 코퍼스 전문 grep(행의 이름 · NOTE · 서술 — 주석 제외)")
    for pat in (r"유기농|친환경|농산물|식품|먹거리|식료품|과일|쌀\b|건강기능|영양제|반찬|밀키트|식재료|꾸러미|생수",
                r"미사용|잔여|1\.5배|연차\s*수당|휴가\s*보상|보상\s*휴가|매수|매입|이월|buy"):
        hits = search(pat, corpus)
        print(f"   /{pat}/ → {len(hits)}행 · {len({h[0] for h in hits})}사")
        for h in hits:
            print(f"      {h[0]}\tSORT {h[1]}\t{h[2]}\t{h[3]}\t…{h[4]}…")


SIBLINGS = {  # 이번 회사 eng → 기등록 형제 회사 표시명(정규식) — 계약 「웨이브 6 전용」 7
    "hyundai_wia": r"^(현대자동차|기아|현대모비스|현대글로비스|현대건설|현대제철|현대로템|현대오토에버)$",
    "s1": r"^삼성",
    "sk_chemicals": r"^SK",
    "gs_retail": r"^GS",
    "isu_specialty_chemical": r"^이수",
    "daewoong_pharm": r"대웅|한올",
    "paradise": r"파라다이스",
    "sfa_semicon": r"^SFA|에스에프에이",
    "bgf_retail": r"^BGF|비지에프",
    "binggrae": r"빙그레|해태",
    "hj_heavy": r"HJ|한진",
    "sebang_battery": r"세방",
    "kumho_petrochemical": r"금호",
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


@section("consist")
def sec_consist(collect, final, corpus):
    print("=" * 100)
    print("§consist ① 그룹 · 통합 각주 세 꼴(대웅제약 「(그룹 통합 채용 기준)」 · 파라다이스 (99) · 나머지 11곳 각주 없음)")
    para = "(파라다이스 · 파라다이스시티 · 호텔 부산 통합 보고 기준)"
    for e in collect:
        for r in final[e]:
            t = r["qd"] or r["note"] or ""
            g = "(그룹 통합 채용 기준)" in t
            s = "그룹 공통 문구" in t
            pa = para in t
            src_group = "대웅그룹 채용 사이트" in t
            dashes = len(re.findall(r"\s[—–]\s", t))
            tail = rc.dash_tail_breaks(t)
            flag = ""
            if e == "daewoong_pharm" and src_group != g:
                flag = " ◀ 그룹 채용 근거 ↔ 각주 불일치"
            if e == "paradise" and not pa:
                flag = " ◀ (99) 꼬리 없음"
            if e not in ("daewoong_pharm", "paradise") and (g or s or pa):
                flag = " ◀ 각주 없어야 할 회사"
            if e in ("daewoong_pharm", "paradise") or flag:
                print(f"   {collect[e]['file']}\tSORT {r['sort']}\t{r['cd']}\t그룹채용근거={src_group}\t그룹통합각주={g}\t통합보고각주={pa}\t"
                      f"「—」{dashes}\tSI-11깨짐={tail}\t길이 {len(t)}{flag}")
    n_other = sum(1 for e in collect if e not in ("daewoong_pharm", "paradise")
                  for r in final[e] if any(x in (r["qd"] or r["note"] or "") for x in ("그룹 통합 채용 기준", "그룹 공통 문구", "통합 보고 기준")))
    print(f"   나머지 11곳 각주 낱말 행 {n_other}")

    print("\n§consist ② 성과급 꼴 — incentive / profit_sharing(이번 웨이브 최종본)")
    pat = re.compile(r"경영\s*실적|경영\s*성과|회사\s*실적|영업이익|Profit Sharing|이익|전사 목표|회사의 성과|회사 및 개인|회사 전체 성과|사업 성과|조직의 성과|회사/BU/개인")
    other = re.compile(r"개인|조직|팀|부서|평가|차등|등급|KPI|PI\b|업적")
    for e in collect:
        for r in final[e]:
            if r["cd"] in ("incentive", "profit_sharing"):
                t = rtext(r)
                only_company = bool(pat.search(t)) and not other.search(t)
                flag = "  ◀ 회사 실적만인데 incentive" if only_company and r["cd"] == "incentive" else ""
                flag += "  ◀ 평가 차등이 있는데 profit_sharing" if r["cd"] == "profit_sharing" and other.search(t) and not re.search(r"외에도|평가 기반 급여 외", t) else ""
                print(f"   {collect[e]['file']}\tSORT {r['sort']}\t{r['cd']}\t회사실적={bool(pat.search(t))}\t평가·개인={bool(other.search(t))}\t{r['nm']}{flag}")

    print("\n§consist ③ 형제 이중 등록 · 문장 겹침(10자 이상 조각 · 출처 괄호 · 꼬리 제외)")
    for e in collect:
        pat_s = re.compile(SIBLINGS[e])
        sibs = {x: c for x, c in corpus.items() if pat_s.search(c["meta"]["nm"])}
        sib_text = " ".join(rtext(r) for c in sibs.values() for r in c["rows"])
        hits = []
        for r in final[e]:
            for f in _fragments(r["qd"] or r["note"]):
                if f in sib_text:
                    hits.append((r["sort"], r["cd"], f))
        print(f"   {collect[e]['file']}: 기등록 형제 {len(sibs)}({', '.join(c['meta']['nm'] for c in sibs.values()) or '없음'}) · 겹친 조각 {len(hits)}")
        for h in hits:
            print(f"      SORT {h[0]} {h[1]}: 「{h[2]}」")

    print("\n§consist ④ 난임 · 11-27(이번 웨이브 최종본 행 · 수집 근거표 언급)")
    for e in collect:
        for r in final[e]:
            if "난임" in rtext(r):
                print(f"   행 {collect[e]['file']}\tSORT {r['sort']}\t{r['cd']}\t{r['nm']}\t…{(r['qd'] or r['note'])[:160]}")
        ev = open(f"{COLLECT}/{collect[e]['file']}.evidence.md", encoding="utf-8").read()
        lines = [ln.strip()[:150] for ln in ev.splitlines() if "난임" in ln]
        print(f"   근거표 {collect[e]['file']}: 「난임」 줄 {len(lines)} · 「11-27」 줄 {sum(1 for ln in ev.splitlines() if '11-27' in ln)}")

    print("\n§consist ⑤ 카테고리 · 코드 일관성 — 같은 이름이 다른 코드(코퍼스 + 이번 웨이브)")
    by_name = collections.defaultdict(collections.Counter)
    for c in corpus.values():
        for r in c["rows"]:
            by_name[r["nm"]][r["cd"]] += 1
    for e in collect:
        for r in final[e]:
            cs = by_name.get(r["nm"])
            if cs and r["cd"] not in cs:
                print(f"   {collect[e]['file']}\tSORT {r['sort']}\t{r['cd']}\t「{r['nm']}」 코퍼스에서는 {dict(cs)}")


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
    print("\n  원 · 만원 숫자가 서술에 있는데 금액 칸이 빈 행(최종본) — 4-3 판정 대상 목록")
    won = re.compile(r"\d[\d,.]*\s*(만\s*원|원|만원)|\d+\s*천만|\d+\s*억")
    for e in collect:
        for r in final[e]:
            if r["amt"] is None and won.search(r["qd"] or ""):
                ms = sorted({m.group(0) for m in won.finditer(r["qd"])})
                print(f"   {collect[e]['file']}\tSORT {r['sort']}\t{r['cd']}\t{r['nm']}\t숫자 {ms}")
    print("\n  코퍼스 holiday_gift · meal 금액 축 최댓값(⚖ C-2 · 이번 금액과 비교)")
    for cd in ("holiday_gift", "meal"):
        vals = sorted((r["amt"], c["file"]) for c in corpus.values() for r in c["rows"] if r["cd"] == cd and r["amt"])
        print(f"   {cd}: 금액 행 {len(vals)} · 최댓값 {vals[-1] if vals else None} · 중간값 {vals[len(vals)//2] if vals else None}")


@section("reg")
def sec_reg(collect, final, corpus):
    print("=" * 100)
    print("§reg 등록 값 · 업종 · corp_code")
    dart = json.load(open(W6 + "/dart/check-2026-10-14.json", encoding="utf-8"))
    inds = collections.Counter(c["meta"]["ind"] for c in corpus.values())
    import csv
    cmap = list(csv.DictReader(open(REPO + "/db/seed/corp_code_map.csv", encoding="utf-8")))
    have_codes = collections.Counter(r["corp_code"] for r in cmap if r["corp_code"])
    have_names = {r["comp_nm"] for r in cmap}
    codes_here = []
    for eng, c in collect.items():
        m = expected_meta(eng, collect)
        dk = dart[ROSTER_NM[eng]]
        codes_here.append(dk["corp_code"])
        same = len([x for x in collect.values() if x["meta"]["ind"] == m["ind"]])
        print(f"  {c['file']}\t{eng}\t{m['nm']}\t{m['tp']}\t{m['ind']}(코퍼스 {inds.get(m['ind'], 0)} + 이번 {same})\t{m['logo']}\t"
              f"slug={slug_of(eng)}\tDART {dk['corp_code']} '{dk['dart_name']}' 종목 {dk['stock']}\t재무 {dk['fin']}\t직원 {dk['emp']}\t"
              f"기존 csv corp 충돌 {have_codes.get(dk['corp_code'], 0)} · 이름 충돌 {m['nm'] in have_names}\t{m['url']}")
    print(f"  이번 corp_code 중복 {len(codes_here) - len(set(codes_here))} · 기존 csv 와 겹침 "
          f"{sum(1 for x in codes_here if x in have_codes)} · csv 최대 comp_id {max(int(r['comp_id']) for r in cmap)} · csv 행 {len(cmap)} · "
          f"매핑(UNMAPPED 아님) {sum(1 for r in cmap if r['status'] != 'UNMAPPED')} · 법인 {len({r['corp_code'] for r in cmap if r['status'] != 'UNMAPPED'})}")
    new_inds = sorted(m for m in {expected_meta(e, collect)['ind'] for e in collect} if m not in inds)
    print(f"  INDUSTRY_NM 새 값 {new_inds or 0} · 바이트: " +
          ", ".join(f"{i}={i.encode().hex()}" for i in sorted({expected_meta(e, collect)['ind'] for e in collect})))
    print(f"  코퍼스 업종 값 {len(inds)}종 · 「보안」 「카지노」 「호텔」 「레저」 「관광」 「서비스」 포함 값 "
          f"{sorted(i for i in inds if i and re.search('보안|카지노|호텔|레저|관광|서비스|리조트|엔터', i))}")
    print(f"  유형 large {sum(1 for c in corpus.values() if c['meta']['tp'] == 'large')} · mid {sum(1 for c in corpus.values() if c['meta']['tp'] == 'mid')} "
          f"→ 이번 large {sum(1 for c in collect.values() if c['meta']['tp'] == 'large')} · mid {sum(1 for c in collect.values() if c['meta']['tp'] == 'mid')}")


_INTERNAL = re.compile(r"코퍼스|선례|어휘표|규칙\s*\d|수집기|수집|검증|감사|병합|미수록|회피|흡수|판독|정본|시드|⚠|구본|승계|앵커|틀 값|"
                       r"항목명 그대로|로 표기|로 기재|영문 표기|카드에는 별도|하나로 기재")
_TRAIL = re.compile(r"(에서|까지|부터|으로|에게|을|를|이|가|은|는|에|와|과|도|며|고|서|하여|해)$")


@section("legal")
def sec_legal(collect, final, corpus):
    print("=" * 100)
    print("§legal _legal_scan.py — 수집본 · 모의본 + 편집 낱말 · 끝맺음 · 「 — 」 꼬리")
    for label, d in (("수집본", COLLECT), ("모의본", SIM)):
        paths = [f"{d}/{fn}.sql" for fn in FILES]
        out = subprocess.run([sys.executable, "-I", LEGAL_SCAN, *paths], capture_output=True, text=True).stdout
        tail = [ln for ln in out.splitlines() if ln.strip()][-1:]
        print(f"  [{label}] " + " / ".join(tail))
    print("\n  편집 · 내부 낱말(계약 §9 목록 — 이름 · NOTE · 서술, 최종본)")
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
    print("\n  끝맺음(서술 마지막 괄호 · 꼬리 앞 본문의 끝 낱말이 조사 · 연결 어미인 것)")
    bad = 0
    for e in collect:
        for r in final[e]:
            v = (r["qd"] or r["note"] or "")
            body = v.split(" — ")[0]
            body = re.sub(r"\s*\([^()]*\)\s*$", "", body).strip()
            body = re.sub(r"\s*\([^()]*\)\s*$", "", body).strip()
            last = re.split(r"[\s,]", body)[-1] if body else ""
            if _TRAIL.search(last):
                bad += 1
                print(f"   {collect[e]['file']}\tSORT {r['sort']}\t{r['cd']}\t끝 「{last}」")
            tailtxt = v.split(" — ", 1)[1] if " — " in v else ""
            if tailtxt and not re.search(r"미기재", tailtxt):
                print(f"   (참고) {collect[e]['file']}\tSORT {r['sort']}\t꼬리에 「미기재」 없음: {tailtxt[:60]}")
    print(f"  끝맺음 의심 {bad}")


def _merged_cfgs():
    cfgs = br.load_pages()
    merged = copy.deepcopy(cfgs)
    for code, ov in OVERRIDES:
        merged[code].setdefault("overrides", []).append(ov)
    return cfgs, merged


@section("pages")
def sec_pages(collect, final, corpus):
    print("=" * 100)
    print("§pages 항목 페이지 — 모의 최종 문안 해시로 예외 대조 · validate_all · 분류")
    cfgs, merged = _merged_cfgs()
    errs = br.validate_all(merged)
    print(f"  validate_all(현행 + 예외 {len(OVERRIDES)}건) 오류 {len(errs)} {errs[:3]}")
    per_code = collections.Counter(code for code, _ in OVERRIDES)
    print(f"  예외 파일별 개수 {dict(per_code)}")
    for code, ov in OVERRIDES:
        r = next((x for x in final[ov["comp"]] if x["cd"] == code), None)
        h = br.text_hash(r["qd"], r["note"]) if r else None
        print(f"  {'OK ' if h == ov['h'] else '⚠  '}{code}\t{ov['comp']}\tSORT {r and r['sort']}\t기대 h {ov['h']}\t최종 문안 h {h}")
        # 같은 (code, comp) 예외가 현행 설정에 이미 있으면 겹침
        old = [o for o in cfgs[code].get("overrides", []) if o.get("comp") == ov["comp"]]
        if old:
            print(f"     ⚠ 현행 설정에 같은 회사 예외 {old}")
    print("\n  최종 문안 분류(예외 적용 후 · 설정 있는 코드) — 예외 전후가 다른 행 · 예외 없는 행 전부")
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
    print(f"  stale(이 13사) {stale_all or 0}")
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
        if b != a or sum(cb.values()) <= 4:
            print(f"   {code}: 「{b}」 → 「{a}」 (코퍼스 {sum(cb.values())}행 + 이번 {sum(ca.values()) - sum(cb.values())}행 · 이름 분포 {dict(ca.most_common(4))}){tag}")


@section("chips")
def sec_chips(collect, final, corpus):
    print("=" * 100)
    print("§chips derive_work_style(모의본 텍스트) — remote · flex · refreshLeave · unlimitedPTO · cond")
    for e, c in collect.items():
        t = open(f"{SIM}/{c['file']}.sql", encoding="utf-8").read()
        ws = derive_work_style(t)
        rows = [(r["sort"], r["cd"], r["nm"], ws_conditions(r["nm"])) for r in final[e] if r["cd"] in _WS_CODE_KEY]
        t0 = open(f"{COLLECT}/{c['file']}.sql", encoding="utf-8").read()
        ws0 = derive_work_style(t0)
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
        kinds = collections.Counter(a[0] for a in ACTIONS[eng])
        print(f"  {fn}\t{nc} → {nf}\t조치 {len(ACTIONS[eng])} {dict(kinds)}\t금액 행 {len(amt)}(stated {st} · 추정 {len(amt) - st}) 합 {sum(r['amt'] for r in amt)}")
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
        acts = ACTIONS.get(eng, [])
        print(f"\n### 5-{i}. {fn} (`{eng}`) — 수집 {len(c['rows'])} → 최종 {len(final[eng])}\n")
        by_sort = {r["sort"]: r for r in c["rows"]}
        if acts:
            print("| # | 대상(SORT · 코드) | 조치 | 근거 |")
            print("|---:|---|---|---|")
            for n, (a, why) in enumerate(zip(acts, WHY[eng]), 1):
                if a[0] == "set":
                    kind = "이름 · 문안 교체" if "nm" in a[2] and "qd" in a[2] else ("이름 교체" if "nm" in a[2] else "문안 교체")
                    print(f"| {n} | {a[1]} `{by_sort[a[1]]['cd']}` | {kind} | {why} |")
                elif a[0] == "recode":
                    print(f"| {n} | {a[1]} `{by_sort[a[1]]['cd']}` | **재코딩 → `{a[2]}`** | {why} |")
                elif a[0] == "delete":
                    print(f"| {n} | {a[1]} `{by_sort[a[1]]['cd']}` | **삭제** | {why} |")
                elif a[0] == "move":
                    print(f"| {n} | {a[1]} `{by_sort[a[1]]['cd']}` → {a[2]['sort']} `{a[2]['cd']}` | **재코딩 · 섹션 이동** | {why} |")
                elif a[0] == "add":
                    print(f"| {n} | {a[1]['sort']} `{a[1]['cd']}` | **추가** | {why} |")
            print("\n집행(글자 그대로 — 백틱 안이 SQL 값이다):\n")
            for n, a in enumerate(acts, 1):
                if a[0] == "set":
                    print(f"- **#{n} SORT {a[1]} `{by_sort[a[1]]['cd']}`** — 적힌 필드만 바꾼다")
                    for k, v in a[2].items():
                        print(f"  - `{fk[k]}` = `{sv(v) if isinstance(v, str) else v}`")
                elif a[0] == "recode":
                    print(f"- **#{n} SORT {a[1]}** `BENEFIT_CD` `'{by_sort[a[1]]['cd']}'` → `'{a[2]}'` "
                          f"(카테고리 `{by_sort[a[1]]['ctgr']}` · SORT {a[1]} · 이름 · 서술 그대로)")
                elif a[0] == "delete":
                    print(f"- **#{n} SORT {a[1]} `{by_sort[a[1]]['cd']}`** — 튜플을 통째로 지운다(뒤 쉼표 정리 · 빈 줄 남기지 않음 · 섹션 머리 주석은 남은 행 위에 그대로)")
                elif a[0] == "move":
                    nr = a[2]
                    prev = max(s for s in by_sort if s < nr["sort"] and s != a[1])
                    print(f"- **#{n} SORT {a[1]} 이동** — growth 구역의 SORT {a[1]} 튜플을 지우고(그 자리에는 다음 조치의 새 SORT {a[1]} 이 들어간다), "
                          f"{nr['ctgr']} 구역 SORT {prev} 행 바로 뒤에(이 튜플 끝에 쉼표):")
                    print("```sql\n" + render_tuple(nr) + ",\n```")
                elif a[0] == "add":
                    nr = a[1]
                    prev = max(s for s in [r["sort"] for r in final[eng]] if s < nr["sort"])
                    if nr["sort"] > max(by_sort):
                        print(f"- **#{n} 추가 SORT {nr['sort']}** — VALUES 의 마지막 행이 된다: SORT {prev} 행 끝 `)` 뒤에 `,` 를 붙이고, "
                              f"그 아래(`ON DUPLICATE KEY UPDATE` 바로 앞)에 쉼표 없이:")
                        print("```sql\n" + render_tuple(nr) + "\n```")
                    else:
                        print(f"- **#{n} 추가 SORT {nr['sort']}** — {nr['ctgr']} 구역, SORT {prev} 행 바로 뒤(이 튜플 끝에 쉼표):")
                        print("```sql\n" + render_tuple(nr) + ",\n```")
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



@section("combined")
def sec_combined(collect, final, corpus):
    """코퍼스 160 + 모의본 13 을 한 폴더(W6/audit/tmp/combined)에 모아 리포 함수로 다시 본다 —
    어휘표 재생성(_vocab_scan) · build_company_meta(SI-13c 조건 칩 · SI-13d 이름 꼴) · 회사 수."""
    import shutil
    print("=" * 100)
    print("§combined 코퍼스 160 + 모의본 13 — 어휘표 · company_meta 재현")
    d = W6 + "/audit/tmp/combined"
    shutil.rmtree(d, ignore_errors=True)
    os.makedirs(d)
    for f in glob.glob(CORPUS + "/*.sql"):
        shutil.copy(f, d)
    for fn in FILES:
        assert not os.path.exists(f"{d}/{fn}.sql"), fn
        shutil.copy(f"{SIM}/{fn}.sql", d)
    vs = _mod("vocab_scan", W6 + "/_vocab_scan.py")
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
    for c, x in sorted(by.items(), key=lambda kv: (-len(kv[1]["comps"]), kv[0])):
        n0 = voc.get(c, (0, None))[0]
        if c not in voc or len(x["comps"]) != n0:
            top = [n for n, _ in sorted(x["names"].items(), key=lambda kv: (-kv[1], kv[0]))[:3]]
            if c not in voc:
                print(f"   신규 | `{c}` | {len(x['comps'])} | {x['ctgr'].most_common(1)[0][0]} | {' · '.join(top)} |")
    print(f"  어휘표 n 이 바뀌는 코드 {sum(1 for c, x in by.items() if c in voc and len(x['comps']) != voc[c][0])}종")
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
        for eng in ("db_insurance", "hyundai_glovis", "hyundai_wia"):
            print(f"   {eng}: remote={ws[eng]['remote']} cond={'cond' in ws[eng]}")
        aliases = {e: meta[e].get("aliases") for e in collect}
        print(f"  이번 13사 aliases(지금 코드 — WAVE6 별칭 넣기 전) {aliases}")
    finally:
        cm.BENEFIT_SQL_DIR = old


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
