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

LEGACY_SEED_DIR = Path("/home/ubuntu/job_change/server/seed")
SEED200_FILES = [
    "companies_kospi_1.py", "companies_kospi_2.py",
    "companies_kosdaq_1.py", "companies_kosdaq_2.py",
]
SEED200_VARS = {
    "companies_kospi_1.py": "KOSPI_1", "companies_kospi_2.py": "KOSPI_2",
    "companies_kosdaq_1.py": "KOSDAQ_1", "companies_kosdaq_2.py": "KOSDAQ_2",
}

# ── 등록 예외 메타 override (DG-3 확정: 엔씨소프트 재이식 + 회사 메타 수동구성) ──
CJ_OLIVE_ALIASES = ["CJ올리브네트웍스", "올리브네트웍스", "CJ OliveNetworks", "cj_olive_networks"]
NCSOFT_ALIASES = ["엔씨소프트", "NCSOFT", "NC", "엔씨", "리니지"]
NCSOFT_INDUSTRY = "게임/IT"  # DG-3 확정값(소스 SQL의 '게임'을 정밀화)

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
    """200-seed(KOSPI/KOSDAQ ×2) 로드 — 별칭 승계 소스(D2.3, 회사 등록 소스 아님)."""
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
    if "hyundai_mobis" in meta:
        meta["hyundai_mobis"]["aliases"] = _dedup(meta["hyundai_mobis"]["aliases"] + ["모비스"])

    return meta
