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


def _row_info(chunk: str) -> tuple[str | None, bool, str | None]:
    """청크 → (BENEFIT_CD, QUAL_YN 여부, 설명텍스트[NOTE 또는 QUAL_DESC])."""
    code_m = re.match(r"\(@comp_id,\s*'([a-zA-Z0-9_]+)'", chunk)
    code = code_m.group(1) if code_m else None
    is_qual = bool(re.search(r",\s*TRUE\s*,", chunk))
    quoted = re.findall(r"'([^']*)'", chunk)
    # quoted[0..3] = CODE,NAME,CATEGORY,BADGE. 그 뒤 NOTE 또는 QUAL_DESC 중 존재하는
    # 쪽만 콤마당 1개 추가되므로, 마지막 원소가 그 설명 텍스트다(존재 시).
    desc = quoted[-1] if len(quoted) > 4 else None
    return code, is_qual, desc


def derive_work_style(sql_text: str) -> dict:
    """복지 코드 존재 스캔으로 근무형태 파생(SP-SEED-6.2, 보수적 기본값)."""
    codes: set[str] = set()
    unlimited_hit = False
    refresh_desc: str | None = None
    for chunk in _row_chunks(sql_text):
        code, is_qual, desc = _row_info(chunk)
        if code:
            codes.add(code)
        if is_qual and desc and ("무제한" in desc or "자율 휴가" in desc):
            unlimited_hit = True
        if code in ("refresh_leave", "long_service_leave") and desc:
            refresh_desc = desc[:60]
    return {
        "remote": bool(codes & {"remote_work", "telecommute", "wfh"}),
        "flex": "flex_work" in codes,
        "unlimitedPTO": ("unlimited_pto" in codes) or unlimited_hit,
        "refreshLeave": refresh_desc,
        "overtime": None,
    }


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

    return meta
