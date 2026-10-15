"""SP-SEED-6 — 회사 메타 보강 레지스트리 (별칭 · WORK_STYLE_VAL 파생).

200-seed(4개 KOSPI/KOSDAQ 파일)와 재이식된 95개 복지 SQL(db/seed/benefit/sql/)을
`COMP_NM`(정식명) 기준으로 조인해 별칭을 승계하고, 복지행 스캔으로 근무형태를
보수적으로 파생한다(SP-SEED-6.1·6.2). 예외 3건(CJ·엔씨소프트·현대모비스)은
DG-3 확정에 따라 수동 override 한다.

/home/ubuntu/job_change 는 읽기 전용 소스 — 이 모듈은 읽기만 한다.
"""

from __future__ import annotations

import importlib.util
import logging
import re
from pathlib import Path

log = logging.getLogger(__name__)

SEED_DIR = Path(__file__).resolve().parent
BENEFIT_SQL_DIR = SEED_DIR / "benefit" / "sql"

SEED200_FILES = [
    "companies_kospi_1.py", "companies_kospi_2.py",
    "companies_kosdaq_1.py", "companies_kosdaq_2.py",
]


def _resolve_seed200_dir() -> Path:
    """200-seed 디렉터리 해석 — 리포 동봉본 우선, 레거시 절대경로는 폴백.

    구 판본은 `/home/ubuntu/job_change/server/seed` 하드코딩뿐이었다 — 시드
    파이프라인의 **입력 데이터가 배포 호스트에만 존재**해, fresh clone·CI 에서
    seeded_db 픽스처가 FileNotFoundError 로 전멸했다(함정 74 와 같은 '서버 유령'
    부류: sitemap 템플릿에 이어 두 번째 실증, 2026-08-26 CI 첫 실행에서 검출).

    해석 순서:
      1. env `LOUPIT_SEED200_DIR` (명시 지정)
      2. 리포 동봉 `db/seed/legacy200/` — `seed200.py` 단일본(서빙 DB 도출,
         legacy200/export_from_db.py 생성) **또는** 원본 4파일이 모두 있을 때
      3. 레거시 `/home/ubuntu/job_change/server/seed` (은퇴한 리포 폴백 —
         동봉본이 커밋되면 도달하지 않는 경로다)
    """
    import os

    env = os.environ.get("LOUPIT_SEED200_DIR")
    if env:
        return Path(env)
    vendored = SEED_DIR / "legacy200"
    if (vendored / "seed200.py").is_file() or all(
        (vendored / f).is_file() for f in SEED200_FILES
    ):
        return vendored
    return Path("/home/ubuntu/job_change/server/seed")


LEGACY_SEED_DIR = _resolve_seed200_dir()
SEED200_VARS = {
    "companies_kospi_1.py": "KOSPI_1", "companies_kospi_2.py": "KOSPI_2",
    "companies_kosdaq_1.py": "KOSDAQ_1", "companies_kosdaq_2.py": "KOSDAQ_2",
}

# ── 등록 예외 메타 override (DG-3 확정: 엔씨소프트 재이식 + 회사 메타 수동구성) ──
CJ_OLIVE_ALIASES = ["CJ올리브네트웍스", "올리브네트웍스", "CJ OliveNetworks", "cj_olive_networks"]

# CJ 계열 7개사(2026-07-30 신설) — 200-seed 목록에 없어 자기명 별칭만 붙는다(fallback 경고).
# 사용자가 실제로 검색하는 이름은 법인명이 아니라 **브랜드**다(예: CJ ENM 커머스부문 → "CJ온스타일").
# 별칭이 없으면 검색 0건 → SP-AUTH-17 회사 등록 요청으로 되돌아온다. 그게 이 목록의 존재 이유다.
# ⚠ uq_comp_alias 는 (COMP_ID, ALIAS_NM) 복합이라 같은 별칭을 여러 회사에 붙일 수 있다 —
#    "CJ ENM" 은 두 부문 모두에 붙여 어느 쪽을 찾든 결과가 나오게 한다.
CJ_AFFILIATE_ALIASES: dict[str, list[str]] = {
    "cj_enm_ent": ["CJ ENM 엔터테인먼트부문", "CJ ENM", "CJENM", "씨제이이엔엠", "CJ이엔엠",
                   "ENM", "CJ ENM 엔터", "엔터테인먼트부문"],
    "cj_enm_com": ["CJ ENM 커머스부문", "CJ ENM", "CJENM", "CJ온스타일", "온스타일", "CJ ONSTYLE",
                   "CJ오쇼핑", "오쇼핑", "커머스부문"],
    "cj_freshway": ["CJ프레시웨이", "프레시웨이", "CJ Freshway"],
    "cj_oliveyoung": ["CJ올리브영", "올리브영", "올영", "Olive Young"],
    "cj_logistics": ["CJ대한통운", "대한통운", "CJ Logistics"],
    "cj_cheiljedang": ["CJ제일제당", "제일제당", "CJ CheilJedang"],
    "cj_cgv": ["CJ CGV", "CGV", "씨지브이", "CJCGV"],
}
# 확장 웨이브 1(2026-09-01, 11개사 신규 등록) — 전부 200-seed 에 없어 override 가 필수다
# (없으면 자기명 하나로 폴백 → 브랜드·구명·영문 검색이 전부 죽는다). 구명 LS산전은 유입 자산.
# ⚠ '한국앤컴퍼니'(별도 지주 법인)·'국민은행'(자회사 법인)은 넣지 않는다 — 타 법인 오귀속.
WAVE1_ALIASES: dict[str, list[str]] = {
    "korea_zinc": ["고려아연", "Korea Zinc", "코리아징크"],
    "hyundai_enc": ["현대건설", "Hyundai E&C"],
    "ls_electric": ["LS ELECTRIC", "LS일렉트릭", "엘에스일렉트릭", "LS산전", "LS Electric"],
    "wonik_ips": ["원익IPS", "원익아이피에스", "WONIK IPS"],
    "lg_cns": ["LG CNS", "LG씨엔에스", "엘지씨엔에스", "LGCNS"],
    "landf": ["엘앤에프", "L&F"],
    "hana_micron": ["하나마이크론", "Hana Micron"],
    # 심텍: 지주 '심텍홀딩스'는 별도 법인 — 별칭에 넣지 않는다
    "simmtech": ["심텍", "SIMMTECH"],
    "hankook_tire": ["한국타이어앤테크놀로지", "한국타이어", "한타", "Hankook Tire"],
    "kbfg": ["KB금융", "KB금융지주", "KB Financial Group", "KB금융그룹"],
    "hd_hyundai": ["HD현대", "에이치디현대", "HD Hyundai", "현대중공업지주"],
}
# 확장 웨이브 2(2026-09-05, 13개사 신규 등록) — 웨이브 1 과 같은 이유로 override 필수.
# ⚠ 타 법인 이름은 넣지 않는다: ㈜대덕(지주)·셀트리온(모회사)·삼양사/삼양홀딩스/삼양라운드스퀘어·
#    넷마블 개발 자회사(넷마블네오 등)·한화생명금융서비스(FP 법인). 구명(삼성엔지니어링·대한생명·
#    넷마블게임즈)은 유입 자산이라 남긴다.
WAVE2_ALIASES: dict[str, list[str]] = {
    "samsung_heavy": ["삼성중공업", "삼중", "Samsung Heavy Industries", "SHI"],
    "lg_innotek": ["LG이노텍", "엘지이노텍", "LG Innotek"],
    "daeduck": ["대덕전자", "Daeduck Electronics"],
    "samsung_fire": ["삼성화재", "삼성화재해상보험", "Samsung Fire"],
    "samsung_sds": ["삼성SDS", "삼성에스디에스", "Samsung SDS"],
    "samsung_ena": ["삼성E&A", "삼성이앤에이", "삼성엔지니어링", "Samsung E&A"],
    "isu_petasys": ["이수페타시스", "페타시스", "ISU Petasys"],
    "celltrion_pharm": ["셀트리온제약", "Celltrion Pharm"],
    "netmarble": ["넷마블", "Netmarble", "넷마블게임즈"],
    "dongjin_semichem": ["동진쎄미켐", "동진세미켐", "Dongjin Semichem"],
    "hanwha_life": ["한화생명", "한화생명보험", "Hanwha Life", "대한생명"],
    "samyang_foods": ["삼양식품", "Samyang Foods"],
    "kai": ["한국항공우주산업", "한국항공우주", "KAI", "카이", "Korea Aerospace Industries"],
}

# 확장 웨이브 3(2026-09-14) — 구명(대우인터내셔널·포스코케미칼)·DART 음차명(에스케이바이오팜)·영문. 그룹명(키움·더존)은 타 법인과 겹쳐 뺐다.
WAVE3_ALIASES: dict[str, list[str]] = {
    "posco_intl": ["포스코인터내셔널", "포스코인터", "POSCO INTERNATIONAL", "대우인터내셔널"],
    "posco_futurem": ["포스코퓨처엠", "POSCO FUTURE M", "포스코케미칼"],
    "kiwoom": ["키움증권", "Kiwoom Securities"],
    "samsung_sec": ["삼성증권", "Samsung Securities"],
    "sk_biopharm": ["SK바이오팜", "에스케이바이오팜", "SK Biopharm"],
    "taihan": ["대한전선", "Taihan Cable", "TAIHAN"],
    "stpharm": ["에스티팜", "ST Pharm"],
    "robotis": ["로보티즈", "ROBOTIS"],
    "lunit": ["루닛", "Lunit"],
    "seegene": ["씨젠", "Seegene"],
    "douzone": ["더존비즈온", "Douzone Bizon"],
    "gaon_cable": ["가온전선", "Gaon Cable"],
}
# 확장 웨이브 4(2026-09-20 서빙 반영) — 구명·영문·약칭만. 지주·형제 법인 이름은 절대 금지.
WAVE4_ALIASES: dict[str, list[str]] = {
    "gc_biopharma": ["녹십자", "GC Biopharma", "지씨녹십자"],  # DART 정식명이 녹십자 — 빠지면 검색 0건
    "hl_mando": ["만도", "Mando", "HL Mando"],
    "jyp": ["JYP", "JYP엔터테인먼트", "제이와이피"],
    "nongshim": ["Nongshim"],
    "dongkook_pharm": ["Dongkook Pharmaceutical"],
    "emart": ["Emart", "E-Mart"],
    "jeju_semi": ["Jeju Semiconductor", "EMLSI"],
    "tse": ["TSE"],
    "fadu": ["FADU"],
    "poongsan": ["Poongsan"],
    "psk": ["PSK", "PSK Inc"],
    "hyundai_dept": ["The Hyundai", "현대百"],
}

# 확장 웨이브 5(2026-10-10 서빙 반영) — 구명·영문·약칭만. 지주·형제 법인 이름은 절대 금지.
WAVE5_ALIASES: dict[str, list[str]] = {
    "ottogi": ["OTOKI", "Ottogi"],
    "kcc": ["케이씨씨", "KCC Corporation"],  # DART 정식명이 케이씨씨 — 빠지면 그 이름 검색 0건
    "hansol_chemical": ["Hansol Chemical"],
    "orion": ["ORION"],
    "gs_enc": ["GS E&C", "지에스건설"],
    "hyundai_marine": ["현대해상화재보험", "Hyundai Marine & Fire Insurance"],
    "hanon_systems": ["Hanon Systems"],
    "sl_corp": ["SL Corporation"],
    "kolon_industries": ["코오롱인더", "Kolon Industries"],  # DART 정식명이 코오롱인더(W5-19 ①) — 필수
    "sanil_electric": ["Sanil Electric"],
    "isc": ["아이에스시"],  # 법인 국문 상호 (주)아이에스시
    "kolmar_korea": ["Kolmar Korea"],
    "cosmax": ["COSMAX"],
}

# 확장 웨이브 6(2026-10-16 서빙 반영) — 구명·영문·약칭만. 지주·형제 법인 이름은 절대 금지.
WAVE6_ALIASES: dict[str, list[str]] = {
    "hyundai_wia": ["Hyundai WIA", "위아"],  # 위아(주) 2001~2009 구명 — 같은 법인
    "daewoong_pharm": ["Daewoong Pharmaceutical"],  # ㈜대웅(지주)과 섞이지 않게 「대웅」 단독은 쓰지 않는다
    "binggrae": ["Binggrae"],
    "isu_specialty_chemical": ["ISU Specialty Chemical", "이수스페셜티"],  # 이수화학(별개 법인) 이름 금지
    "hj_heavy": ["HJ Shipbuilding & Construction", "HJSC", "한진중공업"],  # 2021 사명 변경 전 구명 — 같은 법인(corp 00633835)
    "sfa_semicon": ["SFA Semicon", "에스에프에이반도체"],  # 모회사 SFA 이름 금지
    "bgf_retail": ["BGF Retail", "비지에프리테일"],  # 법인 국문 상호
    "s1": ["S-1", "S1 Corporation"],
    "sebang_battery": ["Sebang Global Battery"],
    "sk_chemicals": ["SK chemicals", "에스케이케미칼"],
    "paradise": ["PARADISE", "Paradise Co."],  # 파라다이스시티 · 파라다이스세가사미(다른 법인) 이름 금지
    "kumho_petrochemical": ["Kumho Petrochemical", "금호석화"],
    "gs_retail": ["GS Retail", "지에스리테일"],
}

# 확장 웨이브 7(2026-10-16 서빙 반영) — 구명·영문·약칭·법인 국문 상호만. 지주·형제 법인 이름은 절대 금지.
WAVE7_ALIASES: dict[str, list[str]] = {
    "boryung": ["Boryung", "보령제약"],  # 2022-03 사명 변경 전 구명(보령제약 → 보령) — 같은 법인 · 보령홀딩스(지주) 이름 금지
    "hk_inno_n": ["HK inno.N", "에이치케이이노엔", "CJ헬스케어"],  # 법인 국문 상호 · 2020-02 사명 변경 전 구명(씨제이헬스케어 → 에이치케이이노엔) — 한국콜마 · 콜마홀딩스 이름 금지
    "sk_bioscience": ["SK bioscience", "에스케이바이오사이언스"],  # 법인 국문 상호 — SK케미칼(최대주주) 이름 금지
    "kctech": ["KCTECH"],  # 분할 존속 법인 ㈜케이씨 · KC 그룹 이름 금지
    "lotte_fine_chem": ["LOTTE Fine Chemical"],
    "innocean": ["INNOCEAN"],
    "hyundai_elevator": ["Hyundai Elevator"],
    "kyobo_securities": ["Kyobo Securities"],  # 교보생명 등과 섞이지 않게 「교보」 단독은 쓰지 않는다
    "fnf": ["에프앤에프"],  # 법인 국문 상호 — F&F홀딩스(지주) · F&F엔터테인먼트 이름 금지
    "kyungdong_navien": ["KD Navien", "Kyungdong Navien"],  # 경동원 · 경동인베스트 이름 금지
    "ahnlab": ["AhnLab"],
    "doosan_tesna": ["Doosan Tesna", "TESNA"],  # 2022-04 두산 편입 전 법인명 테스나 — 같은 법인 · ㈜두산 이름 금지
    "cheil_worldwide": ["Cheil Worldwide"],  # 「제일」 단독은 쓰지 않는다
    "hana_materials": ["HANA Materials"],  # 하나마이크론 이름 금지
    "cosmecca_korea": ["COSMECCA KOREA"],
    "hanssem": ["HANSSEM"],
    "lotte_chilsung": ["LOTTE CHILSUNG BEVERAGE"],
    "lotte_rental": ["LOTTE RENTAL", "KT렌탈"],  # 2015 사명 변경 전 구명(케이티렌탈 → 롯데렌탈) — 같은 법인 · 최대주주 매각 진행 중이라 그룹 낱말은 넣지 않는다
    "korean_re": ["Korean Re", "코리안리재보험"],  # 법인 국문 상호
    "lx_international": ["LX International", "LG상사"],  # 2021 사명 변경 전 구명 — 같은 법인 · LX홀딩스 이름 금지
    "kumho_tire": ["KUMHO TIRE"],  # 「금호」 단독 금지(금호석유화학 등 다른 그룹)
    "komico": ["KoMiCo"],  # 미코 · 미코세라믹스 이름 금지
}

# 확장 웨이브 8(2026-10-16 서빙 반영) — 구명·영문·약칭·법인 국문 상호만. 지주·형제 법인 이름은 절대 금지.
WAVE8_ALIASES: dict[str, list[str]] = {
    "hanil_cement": ["HANIL CEMENT"],  # 2018-07 인적분할 신설 법인 — 존속 지주 한일홀딩스 · 형제 한일현대시멘트 이름 금지
    "daou_tech": ["Daou Technology"],  # 「다우」 단독 금지(다우데이타 · 다우키움 그룹 · 키움증권)
    "doosan_fuelcell": ["Doosan Fuel Cell"],  # ㈜두산 · 두산에너빌리티 이름 금지
    "sk_gas": ["SK Gas"],  # SK디스커버리(최대주주) 이름 금지
    "stx_engine": ["STX Engine"],  # 2004 분할 전 쌍용중공업 · STX 는 다른 법인 계보라 넣지 않는다
    "posco_dx": ["POSCO DX", "포스코디엑스", "포스코ICT", "포스코아이씨티"],  # 법인 국문 상호 · 2023-03 사명 변경 전 구명(포스코아이씨티 → 포스코디엑스) — POSCO홀딩스 · 포스코퓨처엠 이름 금지
    "snt_motiv": ["SNT MOTIV", "에스앤티모티브", "S&T모티브"],  # 법인 국문 상호 · 사명 변경 전 구명(S&T모티브) — SNT홀딩스 · SNT다이내믹스 이름 금지
    "lotte_wellfood": ["LOTTE WELLFOOD", "롯데제과"],  # 2023-04 사명 변경 전 구명(롯데제과 → 롯데웰푸드) — 같은 법인 · 롯데지주 이름 금지
    "hankuk_carbon": ["HANKUK CARBON"],
    "inbody": ["InBody", "바이오스페이스"],  # 2014-09 사명 변경 전 구명(바이오스페이스 → 인바디) — 같은 법인
    "haesung_ds": ["HAESUNG DS"],  # 해성그룹 · 형제 이름 금지
    "sd_biosensor": ["SD Biosensor", "SD바이오센서"],  # 영문 · 약칭 — 바이오노트(최대주주) 이름 금지
    "shift_up": ["SHIFT UP"],
    "shinyoung_sec": ["Shinyoung Securities"],  # 「신영」 단독 금지
    "mirae_asset_life": ["MIRAE ASSET Life", "미래에셋생명보험", "SK생명"],  # 법인 국문 상호 · 1997~2005 구명(SK생명보험 → 미래에셋생명보험) — 같은 법인 · 미래에셋증권 등 형제 이름 금지
    "iljin_electric": ["ILJIN Electric"],  # 일진홀딩스 · 일진다이아 이름 금지
    "hanwha_inv_sec": ["Hanwha Investment & Securities", "한화증권"],  # 2012-09 사명 변경 전 구명(한화증권 → 한화투자증권) — 같은 법인 · ㈜한화 이름 금지
    "sfa": ["SFA", "SFA Engineering"],  # DART corp_name 「SFA」(표시명과 다름 — 필수) · 자회사 SFA반도체 이름 금지
    "samwha_capacitor": ["SAMWHA CAPACITOR"],  # 삼화전기 · 삼화전자 이름 금지
    "dl_enc": ["DL E&C", "디엘이앤씨"],  # 법인 국문 상호 — 2021-01 인적분할 신설(구명 대림산업은 지주 DL㈜ 의 옛 이름이라 금지)
    "nice_info": ["NICE Information Service", "나이스평가정보"],  # 법인 국문 상호 — NICE홀딩스 · NICE신용평가 이름 금지
    "foosung": ["FOOSUNG"],  # 후성그룹 · 퍼스텍 · 한국내화 이름 금지
}

# 확장 웨이브 9(2026-10-16 서빙 반영) — 구명·영문·약칭·법인 국문 상호만. 지주·형제 법인 이름은 절대 금지.
WAVE9_ALIASES: dict[str, list[str]] = {
    "lotte_shopping": ["LOTTE SHOPPING"],  # 롯데지주 · 롯데 계열사 이름 금지
    "hotel_shilla": ["HOTEL SHILLA"],  # 신라호텔 · 신라면세점 · 신라스테이는 사업장 · 상표 이름이라 넣지 않는다 · 삼성 형제 이름 금지
    "hs_hyosung_advanced": ["HS Hyosung Advanced Materials", "에이치에스효성첨단소재", "효성첨단소재"],  # 법인 국문 상호 · 2024-09 사명 변경 전 구명(효성첨단소재) — 지주 HS효성 · ㈜효성 · 효성중공업 이름 금지
    "taekwang_ind": ["Taekwang Industrial"],  # 태광그룹 · 흥국 계열 이름 금지
    "pan_ocean": ["Pan Ocean"],  # 하림지주 이름 금지
    "youngone": ["Youngone Corporation"],  # 2009-07 인적분할 신설 — 존속 지주 영원무역홀딩스(구 영원무역) 이름 금지
    "daehan_shipbuilding": ["DAEHAN SHIPBUILDING"],  # 최대주주 케이에이치아이 이름 금지
    "youngpoong": ["Young Poong"],  # 고려아연 · 영풍 계열 이름 금지
    "ipark_hdc": ["IPARK HYUNDAI DEVELOPMENT", "아이파크현대산업개발", "HDC현대산업개발", "에이치디씨현대산업개발"],  # 법인 국문 상호 · 2026 사명 변경 전 구명 · 약칭(HDC현대산업개발) — 지주 HDC(구 현대산업개발) 이름 금지
    "dn_automotive": ["DN AUTOMOTIVE", "디엔오토모티브", "디티알오토모티브", "동아타이어공업"],  # 법인 국문 상호 · 구명(2017-11 동아타이어공업 → 디티알오토모티브 · 2022-06 → 디엔오토모티브) — DN그룹 다른 계열 이름 금지
    "daishin_securities": ["DAISHIN SECURITIES"],  # 대신파이낸셜그룹 계열 이름 금지
    "sk_networks": ["SK Networks", "에스케이네트웍스"],  # 법인 국문 상호 — SK㈜ · SK인텔릭스(구 SK매직) 등 자회사 이름 금지
    "lotte_energy_materials": ["LOTTE ENERGY MATERIALS", "일진머티리얼즈"],  # 2023-03 사명 변경 전 구명 — 같은 법인 · 일진 그룹 다른 계열 · 롯데케미칼 이름 금지
    "yg_entertainment": ["YG Entertainment", "YG엔터테인먼트"],  # 영문 · 약칭 — YG PLUS 등 계열 이름 금지
    "nexon_games": ["NEXON Games", "넷게임즈"],  # 2022-03 사명 변경 전 구명(넷게임즈 — 존속 법인) — 흡수된 넥슨지티 · 넥슨코리아 이름 금지
    "cha_biotech": ["Chabiotech"],  # 차병원 · 차바이오그룹 계열 이름 금지
    "sampyo_cement": ["SAMPYO Cement", "동양시멘트"],  # 2017-03 사명 변경 전 구명(동양시멘트 — 2010 흡수합병 뒤 같은 법인) — 삼표 · 삼표산업 이름 금지
    "robostar": ["Robostar"],  # LG 계열 이름 금지
    "ls_marine_solution": ["LS Marine Solution", "엘에스마린솔루션", "KT서브마린", "케이티서브마린"],  # 법인 국문 상호 · 2023-08 사명 변경 전 구명(케이티서브마린) — LS전선 · KT 이름 금지
    "snt_energy": ["SNT Energy"],  # 구명 S&TC 는 2008 분할 전 지주(현 SNT홀딩스)도 쓰던 이름이라 넣지 않는다 — SNT홀딩스 · SNT모티브 이름 금지
    "snt_dynamics": ["SNT DYNAMICS", "에스앤티다이내믹스", "S&T중공업", "SNT중공업"],  # 법인 국문 상호 · 구명(2005 S&T중공업 · 2021 SNT중공업 → 2023 SNT다이내믹스) — SNT홀딩스 · SNT모티브 이름 금지
}

# 확장 웨이브 10(2026-10-16 서빙 반영) — 구명·영문·약칭·법인 국문 상호만. 지주·형제 법인 이름은 절대 금지.
WAVE10_ALIASES: dict[str, list[str]] = {
    "dongwon_industries": ["DONGWON INDUSTRIES"],  # 2022-11 합병 전 지주 동원엔터프라이즈 · 동원F&B · 동원시스템즈 이름 금지
    "sgc_energy": ["SGC Energy", "에스지씨에너지"],  # 법인 국문 상호 — 구명 삼광글라스는 유리사업을 물적분할한 형제 SGC솔루션의 사업 이름이라 넣지 않는다 · 흡수된 군장에너지는 다른 법인
    "wonik_qnc": ["WONIK QnC", "원익큐엔씨", "원익쿼츠"],  # 법인 국문 상호 · 구명(원익쿼츠 → 원익큐엔씨) — ㈜원익 · 원익IPS · 원익홀딩스 이름 금지
    "hyosung_tnc": ["Hyosung TNC"],  # 2018-06 분할 신설 · 상호 변경 없음 — ㈜효성 · 효성중공업 · HS효성 이름 금지
    "ecopro_materials": ["에코프로머티", "ECOPRO MATERIALS", "에코프로지이엠"],  # DART 정식명(필수) · 영문 · 구명(2022-03 전 에코프로지이엠) — 에코프로 · 에코프로비엠 이름 금지
    "cosmo_amt": ["COSMO ADVANCED MATERIALS & TECHNOLOGY", "새한미디어"],  # 영문 · 구명(1980 새한미디어 → 2011 코스모신소재) — 코스모화학 · 코스모앤컴퍼니 이름 금지
    "skc": ["에스케이씨"],  # 법인 국문 상호 — SK㈜ · SK넥실리스 · ISC 등 SKC Family 이름 금지
    "daejoo_electronic": ["Daejoo Electronic Materials", "대주교역"],  # 영문 · 구명(1981 대주교역 → 2003 대주전자재료)
    "hanall_biopharma": ["HANALL BIOPHARMA", "한올제약"],  # 영문 · 구명(1987 한올제약 → 2010 한올바이오파마) — 1973 선경제약은 SK 옛 그룹명과 섞여 넣지 않는다 · 대웅 · 대웅제약 이름 금지
    "gst": ["Global Standard Technology", "글로벌스탠다드테크놀로지"],  # 영문 · 법인 국문 상호
    "cs_wind": ["CS Wind", "중산풍력"],  # 영문 · 구명(2006 중산풍력 → 2007 씨에스윈드) — CS베어링 등 계열 이름 금지
    "ls_materials": ["LS Materials", "엘에스머트리얼즈"],  # 영문 · 법인 국문 상호 — 분할 전 LS엠트론 · LS ELECTRIC · LS 이름 금지
}

NCSOFT_ALIASES = ["엔씨소프트", "NCSOFT", "NC", "엔씨", "리니지"]
NCSOFT_INDUSTRY = "게임/IT"  # DG-3 확정값(소스 SQL의 '게임'을 정밀화)

# ── 사명 변경 2건(2026-08-21) ────────────────────────────────────────────────
# LIG넥스원 → LIG디펜스앤에어로스페이스(2026-03-31 주총, DART 개황 2026-04-15 갱신 —
# 정식명 `엘아이지디펜스앤에어로스페이스(주)`), 엔씨소프트 → (주)엔씨(DART 2026-05-04).
# 표시명은 병기형으로 바꿨다(`LIG디펜스앤에어로스페이스(구 LIG넥스원)` · `엔씨소프트(NC)`).
#
# 🚨 **override 가 없으면 표시명 변경이 별칭을 지운다.** build_company_meta 는 200-seed 를
# `by_name.get(comp_nm)` 으로 조인해 별칭을 승계하는데, COMP_NM 을 바꾸는 순간 그 조인이
# 미매칭으로 떨어져 `aliases = [comp_nm]` fallback 이 된다 — 옛 이름 검색이 통째로 죽는다.
# 엔씨소프트는 NCSOFT_ALIASES 가 이미 막고 있었고, LIG 는 막는 것이 없어 여기 추가한다.
# 옛 이름을 남기는 이유: 사람들은 여전히 옛 이름으로 검색하고, 별칭은 사이트 내 검색과
# JSON-LD `alternateName`(검색엔진이 동일 대상임을 아는 근거) 양쪽으로 나간다.
LIG_ALIASES = [
    "LIG디펜스앤에어로스페이스", "LIG디펜스", "LIG D&A", "LIG DnA",
    "LIG넥스원", "LIG Nex1", "LIG",   # ← 옛 이름. 유입 자산이라 절대 빼지 않는다
]

_HEADER_INSERT_RE = re.compile(
    r"VALUES\s*\(\s*'([^']+)',\s*'([^']+)',\s*"
    r"\(SELECT\s+COMP_TP_ID\s+FROM\s+TCOMPANY_TYPE\s+WHERE\s+COMP_TP_CD\s*=\s*'([^']+)'\)",
)


def parse_header_insert(sql_text: str) -> tuple[str, str, str]:
    """복지 SQL의 자기등록 INSERT에서 (eng_nm, comp_nm, comp_type) 추출."""
    m = _HEADER_INSERT_RE.search(sql_text)
    if not m:
        raise ValueError("TCOMPANY 자기등록 INSERT 패턴을 찾지 못함")
    return m.group(1), m.group(2), m.group(3)


def _load_module(path: Path):
    spec = importlib.util.spec_from_file_location(path.stem, path)
    mod = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(mod)
    return mod


def _load_seed200() -> list[dict]:
    """200-seed 로드 — 별칭 승계 소스(D2.3, 회사 등록 소스 아님).

    `seed200.py` 단일본(SEED200 변수 — 서빙 DB 도출 동봉본)이 있으면 그것을,
    없으면 원본 4파일(KOSPI/KOSDAQ ×2)을 읽는다. 파이프라인이 소비하는 필드는
    두 형식 모두 name·aliases 뿐이다(build_company_meta)."""
    single = LEGACY_SEED_DIR / "seed200.py"
    if single.is_file():
        return list(getattr(_load_module(single), "SEED200"))
    records: list[dict] = []
    for fname in SEED200_FILES:
        path = LEGACY_SEED_DIR / fname
        mod = _load_module(path)
        records.extend(getattr(mod, SEED200_VARS[fname]))
    return records


def _dedup(items: list[str]) -> list[str]:
    seen: set[str] = set()
    out: list[str] = []
    for it in items:
        if it not in seen:
            seen.add(it)
            out.append(it)
    return out


def _row_chunks(sql_text: str) -> list[str]:
    """TCOMPANY_BENEFIT INSERT VALUES 블록을 행 단위 청크로 분리(베스트-에포트).

    각 청크는 `(@comp_id, 'CODE', ...` 로 시작 — 노트/설명 텍스트 내부의 콤마·괄호는
    다음 행 시작 앵커(`(@comp_id,`)가 아니므로 안전하게 보존된다.
    """
    idx = sql_text.find("INSERT INTO TCOMPANY_BENEFIT")
    if idx == -1:
        return []
    section = sql_text[idx:]
    end_idx = section.find("ON DUPLICATE KEY UPDATE")
    if end_idx != -1:
        section = section[:end_idx]
    chunks = re.split(r"(?=\(@comp_id,)", section)
    return [c for c in chunks if c.strip().startswith("(@comp_id,")]


def _row_info(chunk: str) -> tuple[str | None, bool, str | None, str | None, str | None]:
    """청크 → (BENEFIT_CD, QUAL_YN 여부, 설명텍스트[NOTE 또는 QUAL_DESC], BENEFIT_CTGR_CD, BENEFIT_NM)."""
    code_m = re.match(r"\(@comp_id,\s*'([a-zA-Z0-9_]+)'", chunk)
    code = code_m.group(1) if code_m else None
    is_qual = bool(re.search(r",\s*TRUE\s*,", chunk))
    # SQL 문자열 안의 홑따옴표 이스케이프(두 개 연속)를 한 칸으로 읽는다 — 안 그러면 이름 칸에 이스케이프가
    # 있는 행(CJ ENM 커머스부문 쉴랜다 리프레시 휴가)처럼 칸이 밀려 카테고리 자리에 이름 조각이 온다(2026-09-28).
    quoted = [q.replace("''", "'") for q in re.findall(r"'((?:[^']|'')*)'", chunk)]
    # quoted[0..3] = CODE,NAME,CATEGORY,BADGE. 그 뒤 NOTE 또는 QUAL_DESC 중 존재하는
    # 쪽만 콤마당 1개 추가되므로, 마지막 원소가 그 설명 텍스트다(존재 시).
    desc = quoted[-1] if len(quoted) > 4 else None
    ctgr = quoted[2] if len(quoted) > 2 else None
    name = quoted[1] if len(quoted) > 1 else None
    return code, is_qual, desc, ctgr, name


# ── 근무형태 칩의 조건(SP-SEED-6.2, 사용자 결정 6c 2026-10-04) — **이름만** 읽는다 ─────────────────────────
# 서술에는 「대상 · 부문 · 필요시 · 일부」가 걸리는 행이 50행을 넘고 대부분 오탐이다(수집 메모 「적용 대상 미기재」 ·
# 삼성바이오 · 휴젤 「필요시」 신청형 · ㈜한화 flex 서술의 두 부문 공통). 그래서 수집 계약이 정한 이름 꼴만 본다 —
# 계약 문안: 「근무형태 칩 이름 규칙」(`_COLLECT-CONTRACT.md`). 이 꼴 밖의 괄호(「(주 1회)」 · 「(WFA)」 · 「(재택근무 포함)」)는
# 한정으로 읽지 않는다.
_COND_TARGET_HEAD = re.compile(r"^(육아기|자녀돌봄|부서별)\s")        # 대상 — 앞 「육아기 」·「자녀돌봄 」·「부서별 」
_COND_TARGET_TAIL = re.compile(r"\((자녀를\s*둔[^()]*)\)\s*$")       # 대상 — 끝 「(자녀를 둔 …)」
_COND_REASON = re.compile(r"\(\s*필요\s*시\s*\)\s*$")              # 사유 — 끝 「(필요 시)」 → 「필요 시」
_COND_CONDITIONAL = re.compile(r"\(\s*조건부\s*\)\s*$")             # 사유 — 끝 「(조건부)」 → 「조건부」
_COND_SECTOR = re.compile(r"\(([^()]*부문)\)\s*$")                  # 부문 — 끝 「(○○부문)」
_COND_TOPIC = re.compile(r"^.*[은는]\s+")                            # 「휴가는 건설부문」 → 「건설부문」

# 파생 대상 코드 → 칩 키
_WS_CODE_KEY = {
    "remote_work": "remote", "telecommute": "remote", "wfh": "remote",
    "flex_work": "flex",
    "refresh_leave": "refreshLeave", "long_service_leave": "refreshLeave",
}


def ws_conditions(name: str | None) -> list[str]:
    """근무형태 행 이름 → 조건 라벨 목록(없으면 `[]` = 조건 없는 행).

    앞 대상 · 끝 대상 · 끝 사유 · 끝 부문을 각각 보고, 해당하는 것을 이 순서로 모은다.
    """
    nm = (name or "").strip()
    out: list[str] = []
    m = _COND_TARGET_HEAD.match(nm)
    if m:
        out.append(m.group(1))
    m = _COND_TARGET_TAIL.search(nm)
    if m:
        out.append(re.sub(r"\s+", " ", m.group(1).strip()))
    elif _COND_REASON.search(nm):
        out.append("필요 시")
    elif _COND_CONDITIONAL.search(nm):
        out.append("조건부")
    else:
        m = _COND_SECTOR.search(nm)
        if m:
            inner = _COND_TOPIC.sub("", m.group(1).strip())
            out.append(inner)
    return out


def derive_work_style(sql_text: str) -> dict:
    """복지 코드 존재 스캔으로 근무형태 파생(SP-SEED-6.2, 보수적 기본값).

    칩은 **조건 없는 단정**만이다(6c): 같은 키에 조건 없는 행이 하나라도 있으면 맨 칩(`remote: true`), 조건 있는 행뿐이면
    그 키는 false 로 두고 `cond` 맵에 조건 라벨을 쓴다(불변식 `k ∈ cond ⇒ !ws[k]`). 조건이 하나도 없으면 `cond` 키를
    쓰지 않는다(137사 JSON 바이트 그대로). `unlimitedPTO` 는 조건 사례가 없어 대상 밖이다.
    """
    codes: set[str] = set()
    unlimited_hit = False
    plain: dict[str, bool] = {}               # 키 → 조건 없는 행이 있는가
    cond: dict[str, list[str]] = {}           # 키 → 조건 라벨(행 순서, 중복 제거)
    refresh_desc: str | None = None           # 조건 없는 행 가운데 파일상 마지막 행 서술 [:60]
    for chunk in _row_chunks(sql_text):
        code, is_qual, desc, ctgr, name = _row_info(chunk)
        if code:
            codes.add(code)
        # 휴가 카테고리 행만 본다(2026-09-28) — 「음료 무제한」(에이피알) · 「도서 구매 무제한」(카카오페이)이
        # 「무제한 휴가」 칩으로 화면과 이직 계산기에 나가고 있었고, 재수집한 NH투자증권의 「본인 의료비 무제한」도
        # 걸릴 참이었다.
        if is_qual and desc and ctgr == "time_off" and ("무제한" in desc or "자율 휴가" in desc):
            unlimited_hit = True
        key = _WS_CODE_KEY.get(code)
        if key:
            conds = ws_conditions(name)
            if conds:
                for lb in conds:
                    if lb not in cond.setdefault(key, []):
                        cond[key].append(lb)
            else:
                plain[key] = True
                if key == "refreshLeave" and desc:
                    refresh_desc = desc[:60]
    ws = {
        "remote": bool(plain.get("remote")),
        "flex": bool(plain.get("flex")),
        "unlimitedPTO": ("unlimited_pto" in codes) or unlimited_hit,
        "refreshLeave": refresh_desc if plain.get("refreshLeave") else None,
        "overtime": None,
    }
    # 조건 있는 행뿐인 키만 cond 에 싣는다 — 맨 행이 하나라도 있으면 맨 칩이 이기고 조건은 적지 않는다.
    cond_only = {k: v for k, v in cond.items() if not plain.get(k)}
    if cond_only:
        ws["cond"] = cond_only
    return ws


def build_company_meta() -> dict:
    """eng_nm → {comp_nm, aliases[], work_style{}} 딕셔너리 생성(SP-SEED-6.1)."""
    seed200 = _load_seed200()
    by_name = {rec["name"]: rec for rec in seed200}

    meta: dict[str, dict] = {}
    for f in sorted(BENEFIT_SQL_DIR.glob("*.sql")):
        text = f.read_text(encoding="utf-8")
        eng, comp_nm, _comp_type = parse_header_insert(text)
        rec = by_name.get(comp_nm)
        if rec:
            aliases = list(rec.get("aliases", []))
        else:
            aliases = [comp_nm]
            log.warning("meta fallback: comp_nm=%s eng=%s 200-seed 미매칭 — 자기명 별칭만 시드", comp_nm, eng)
        meta[eng] = {
            "comp_nm": comp_nm,
            "aliases": _dedup(aliases + [comp_nm]),
            "work_style": derive_work_style(text),
        }

    # ── 예외 override(DG-3, SP-SEED-7) ──
    if "cj" in meta:
        meta["cj"]["comp_nm"] = "CJ올리브네트웍스"
        meta["cj"]["aliases"] = _dedup(CJ_OLIVE_ALIASES)
    if "ncsoft" in meta:
        meta["ncsoft"]["aliases"] = _dedup(NCSOFT_ALIASES)
        meta["ncsoft"]["industry_override"] = NCSOFT_INDUSTRY
    if "lig_nex1" in meta:
        # 사명 변경(2026-08-21). eng_nm 은 `lig_nex1` 그대로 둔다 — URL slug 이라
        # 바꾸면 /company/lig-nex1 색인과 외부 링크가 통째로 깨진다.
        meta["lig_nex1"]["aliases"] = _dedup(LIG_ALIASES)
    if "hyundai_mobis" in meta:
        meta["hyundai_mobis"]["aliases"] = _dedup(meta["hyundai_mobis"]["aliases"] + ["모비스"])
    for eng, extra_aliases in CJ_AFFILIATE_ALIASES.items():
        if eng in meta:
            meta[eng]["aliases"] = _dedup(meta[eng]["aliases"] + extra_aliases)
    for eng, extra_aliases in WAVE1_ALIASES.items():
        if eng in meta:
            meta[eng]["aliases"] = _dedup(meta[eng]["aliases"] + extra_aliases)
    for eng, extra_aliases in WAVE2_ALIASES.items():
        if eng in meta:
            meta[eng]["aliases"] = _dedup(meta[eng]["aliases"] + extra_aliases)
    for eng, extra_aliases in WAVE3_ALIASES.items():
        if eng in meta:
            meta[eng]["aliases"] = _dedup(meta[eng]["aliases"] + extra_aliases)

    for eng, extra_aliases in WAVE4_ALIASES.items():
        if eng in meta:
            meta[eng]["aliases"] = _dedup(meta[eng]["aliases"] + extra_aliases)

    for eng, extra_aliases in WAVE5_ALIASES.items():
        if eng in meta:
            meta[eng]["aliases"] = _dedup(meta[eng]["aliases"] + extra_aliases)

    for eng, extra_aliases in WAVE6_ALIASES.items():
        if eng in meta:
            meta[eng]["aliases"] = _dedup(meta[eng]["aliases"] + extra_aliases)

    for eng, extra_aliases in WAVE7_ALIASES.items():
        if eng in meta:
            meta[eng]["aliases"] = _dedup(meta[eng]["aliases"] + extra_aliases)

    for eng, extra_aliases in WAVE8_ALIASES.items():
        if eng in meta:
            meta[eng]["aliases"] = _dedup(meta[eng]["aliases"] + extra_aliases)

    for eng, extra_aliases in WAVE9_ALIASES.items():
        if eng in meta:
            meta[eng]["aliases"] = _dedup(meta[eng]["aliases"] + extra_aliases)

    for eng, extra_aliases in WAVE10_ALIASES.items():
        if eng in meta:
            meta[eng]["aliases"] = _dedup(meta[eng]["aliases"] + extra_aliases)

    return meta
