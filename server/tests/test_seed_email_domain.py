"""SP-AUTH-7 / DG-5 — 회사↔이메일 도메인 화이트리스트 시드 가드 (SED-1~SED-5).

이 시드는 **재직 인증(자동)의 유일한 근거**다. 한 줄이 틀리면 엉뚱한 회사 재직자가
인증되어 남의 회사 복지 정보를 편집한다. 그래서 데이터가 아니라 **불변식**을 검사한다.

가드는 전부 **파생형**이다 — 시드 SQL 을 파싱해서 스스로 기대값을 만든다(함정 ㉗:
하드코딩 사본 가드는 원본과 함께 틀린다). 도메인 목록을 여기 복제하지 마라.

특히 SED-1 이 중요하다: `INSERT ... SELECT ... WHERE COMP_ENG_NM = 'slug'` 구조는
slug 오타 시 **에러 없이 0행 삽입**으로 조용히 사라진다. 릴리스는 초록인데 그 회사만
수동 승인 경로로 남는다 — 발견되지 않는 결함이다.
"""

from __future__ import annotations

import re
from pathlib import Path

import pytest

SEED_SQL = Path(__file__).resolve().parents[2] / "db" / "seed" / "company_email_domain.sql"

# 무료·공용 메일 서비스. 누구나 주소를 만들 수 있으므로 재직의 근거가 될 수 없다.
FREEMAIL_DOMAINS = frozenset({
    "gmail.com", "googlemail.com", "naver.com", "daum.net", "hanmail.net",
    "nate.com", "kakao.com", "outlook.com", "hotmail.com", "live.com",
    "yahoo.com", "yahoo.co.kr", "icloud.com", "me.com", "protonmail.com",
    "proton.me", "korea.com", "empas.com", "paran.com", "chol.com",
    "dreamwiz.com", "hanmir.com", "qq.com", "163.com", "126.com",
    "aol.com", "zoho.com", "yandex.com", "mail.com", "gmx.com",
})

# DNS 라벨 규칙 — 소문자·숫자·하이픈, 라벨 시작/끝은 영숫자, TLD 는 2자 이상 알파벳.
_DOMAIN_RE = re.compile(r"^(?=.{4,253}$)([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,}$")

# `SELECT COMP_ID, '<도메인>', TRUE FROM TCOMPANY` 에서 도메인을 집는다.
_DOMAIN_IN_SELECT = re.compile(r"SELECT\s+COMP_ID\s*,\s*'([^']+)'", re.I)
# 단일 회사 매핑: `WHERE COMP_ENG_NM = 'slug'`
_SLUG_EQ = re.compile(r"COMP_ENG_NM\s*=\s*'([^']+)'", re.I)
# 그룹 공용 매핑: `WHERE COMP_ENG_NM IN ('a','b',...)`
_SLUG_IN = re.compile(r"COMP_ENG_NM\s+IN\s*\(([^)]*)\)", re.I | re.S)


def _statements() -> list[str]:
    """세미콜론 분리 후 이 테이블을 건드리는 INSERT 문만 남긴다."""
    text = SEED_SQL.read_text(encoding="utf-8")
    # 줄 주석(`-- …`)에 도메인 예시가 들어 있어도 파싱에 섞이지 않게 먼저 제거한다.
    text = "\n".join(re.sub(r"--.*$", "", line) for line in text.splitlines())
    return [s.strip() for s in text.split(";") if "TCOMPANY_EMAIL_DOMAIN" in s.upper()]


def _parse() -> list[tuple[str, str, str]]:
    """시드를 (slug, domain, shape) 튜플로 펼친다. shape ∈ {'single','group'}."""
    pairs: list[tuple[str, str, str]] = []
    for stmt in _statements():
        dom_m = _DOMAIN_IN_SELECT.search(stmt)
        assert dom_m, f"도메인 리터럴을 찾지 못한 INSERT 문:\n{stmt}"
        domain = dom_m.group(1)

        in_m = _SLUG_IN.search(stmt)
        if in_m:
            slugs = re.findall(r"'([^']+)'", in_m.group(1))
            assert slugs, f"IN 목록이 비었다:\n{stmt}"
            pairs.extend((s, domain, "group") for s in slugs)
            continue

        eq_m = _SLUG_EQ.search(stmt)
        assert eq_m, f"회사 지목(= 또는 IN)이 없는 INSERT 문:\n{stmt}"
        pairs.append((eq_m.group(1), domain, "single"))
    assert pairs, "시드에서 (회사, 도메인) 쌍을 하나도 파싱하지 못했다 — 파서가 형식과 어긋났다"
    return pairs


# ── SED-1: slug 오타로 인한 조용한 no-op 금지 ─────────────────────────────
def test_SED1_every_slug_exists_in_company_table(seeded_db):
    """시드가 지목한 모든 COMP_ENG_NM 이 실제 TCOMPANY 에 있어야 한다.

    `INSERT ... SELECT ... WHERE COMP_ENG_NM='오타'` 는 0행을 넣고 성공한다.
    이 가드가 없으면 오타난 회사는 영원히 수동 승인 경로에 남고 아무도 모른다.
    """
    with seeded_db.cursor() as cur:
        cur.execute("SELECT COMP_ENG_NM FROM TCOMPANY")
        known = {r[0] for r in cur.fetchall()}
    missing = sorted({slug for slug, _, _ in _parse()} - known)
    assert not missing, (
        f"시드가 지목한 회사 slug 가 TCOMPANY 에 없다 — 삽입이 조용히 0행이 된다: {missing}"
    )


# ── SED-2: 파일이 선언한 쌍 = DB 에 실제로 들어간 행 ────────────────────────
def test_SED2_seed_pairs_match_db_rows(seeded_db):
    """선언과 적재가 1:1 이어야 한다 — 유실(오타)도 초과(중복 선언)도 잡는다."""
    declared = {(slug, dom) for slug, dom, _ in _parse()}
    with seeded_db.cursor() as cur:
        cur.execute(
            """
            SELECT c.COMP_ENG_NM, d.EMAIL_DOMAIN_NM
              FROM TCOMPANY_EMAIL_DOMAIN d
              JOIN TCOMPANY c ON c.COMP_ID = d.COMP_ID
            """
        )
        loaded = {(r[0], r[1]) for r in cur.fetchall()}
    assert declared == loaded, (
        f"선언에만 있음(미적재): {sorted(declared - loaded)} / "
        f"DB 에만 있음(출처불명): {sorted(loaded - declared)}"
    )


# ── SED-3: 무료·공용 메일 도메인 금지 ──────────────────────────────────────
def test_SED3_no_freemail_domains():
    """gmail·naver 같은 공용 도메인은 누구나 만들 수 있어 재직 근거가 못 된다."""
    offenders = sorted({d for _, d, _ in _parse() if d.lower() in FREEMAIL_DOMAINS})
    assert not offenders, f"무료/공용 메일 도메인이 화이트리스트에 있다: {offenders}"


# ── SED-4: 도메인 형식 정규화 ─────────────────────────────────────────────
@pytest.mark.parametrize("shape", ["single", "group"])
def test_SED4_domain_format_is_normalized(shape):
    """소문자·유효 DNS 형식만 허용. 대문자/공백/`@` 혼입은 매칭을 조용히 실패시킨다."""
    bad = sorted({
        d for _, d, sh in _parse()
        if sh == shape and (d != d.lower() or not _DOMAIN_RE.match(d))
    })
    assert not bad, f"도메인 형식 위반({shape}): {bad}"


# ── SED-5: 단일 매핑 도메인은 파일 전체에서 유일 ───────────────────────────
def test_SED5_single_company_domain_is_not_reused():
    """`= 'slug'` 로 쓴 도메인이 다른 곳에 또 나오면 안 된다.

    그룹 공용 도메인(삼성 samsung.com · SK sk.com)은 **`IN (...)` 한 문장**으로만
    표현한다 — 그래야 "이건 그룹 단위 인증이다"라는 의도가 코드에 남는다.
    같은 도메인이 단일 문장으로 흩어져 있으면 그건 의도가 아니라 실수다.
    """
    pairs = _parse()
    by_domain: dict[str, set[str]] = {}
    for slug, dom, _ in pairs:
        by_domain.setdefault(dom, set()).add(slug)
    single_domains = {dom for _, dom, sh in pairs if sh == "single"}
    leaked = sorted(
        f"{dom} → {sorted(by_domain[dom])}"
        for dom in single_domains
        if len(by_domain[dom]) > 1
    )
    assert not leaked, (
        "단일 회사로 선언한 도메인이 여러 회사에 매핑됐다. 그룹 공용이 의도라면 "
        f"IN (...) 한 문장으로 합쳐라: {leaked}"
    )


# ═══════════════════════════════════════════════════════════════════════
# SED-6 — 가드 자기검증(뮤테이션)
#
# 위 가드들은 전부 "위반이 없다"만 주장한다. 그런 테스트는 파서가 조용히
# 아무것도 못 읽어도 초록이다(빈 집합은 언제나 무해하다). 그래서 결함을
# 일부러 심어 **가드가 실제로 빨개지는지** 확인한다 — 함정 ㉒·㉔.
# ═══════════════════════════════════════════════════════════════════════


def _mutated_seed(tmp_path, old: str, new: str) -> Path:
    """시드 사본에 결함을 심는다. 원본은 건드리지 않는다."""
    text = SEED_SQL.read_text(encoding="utf-8")
    assert old in text, f"뮤테이션 대상 문자열이 시드에 없다(시드 구조가 바뀌었나): {old}"
    p = tmp_path / "mutated.sql"
    p.write_text(text.replace(old, new, 1), encoding="utf-8")
    return p


def test_SED6_typo_slug_mutation_is_caught(monkeypatch, tmp_path, seeded_db):
    """slug 오타를 심으면 SED-1·SED-2 가 반드시 실패해야 한다."""
    import server.tests.test_seed_email_domain as mod

    monkeypatch.setattr(
        mod, "SEED_SQL", _mutated_seed(tmp_path, "COMP_ENG_NM = 'kt'", "COMP_ENG_NM = 'ktt'")
    )
    with pytest.raises(AssertionError, match="조용히 0행"):
        mod.test_SED1_every_slug_exists_in_company_table(seeded_db)
    with pytest.raises(AssertionError, match="미적재"):
        mod.test_SED2_seed_pairs_match_db_rows(seeded_db)


def test_SED6_freemail_mutation_is_caught(monkeypatch, tmp_path):
    import server.tests.test_seed_email_domain as mod

    monkeypatch.setattr(mod, "SEED_SQL", _mutated_seed(tmp_path, "'kt.com'", "'naver.com'"))
    with pytest.raises(AssertionError, match="무료/공용"):
        mod.test_SED3_no_freemail_domains()


def test_SED6_bad_format_mutation_is_caught(monkeypatch, tmp_path):
    import server.tests.test_seed_email_domain as mod

    monkeypatch.setattr(mod, "SEED_SQL", _mutated_seed(tmp_path, "'kt.com'", "'KT.com'"))
    with pytest.raises(AssertionError, match="형식 위반"):
        mod.test_SED4_domain_format_is_normalized("single")


def test_SED6_reused_domain_mutation_is_caught(monkeypatch, tmp_path):
    """대한항공에 kia.com 을 붙이면 — 정확히 우리가 두려워하는 오매핑이다."""
    import server.tests.test_seed_email_domain as mod

    monkeypatch.setattr(mod, "SEED_SQL", _mutated_seed(tmp_path, "'koreanair.com'", "'kia.com'"))
    with pytest.raises(AssertionError, match="여러 회사에 매핑"):
        mod.test_SED5_single_company_domain_is_not_reused()


def test_SED6_parser_reads_both_statement_shapes():
    """파서가 단일·그룹 두 형식을 다 읽는지 — 빈 파싱으로 인한 거짓 초록 차단."""
    shapes = {sh for _, _, sh in _parse()}
    assert shapes == {"single", "group"}, f"파서가 두 형식을 다 보지 못했다: {shapes}"
