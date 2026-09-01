"""SP-SEED-11.1 카운트 테스트 (SD-1~SD-7).

근거: SPEC/03 SP-SEED-11.1 · TASK/03 T-03.2.1·T-03.2.2·T-03.3.4·T-03.3.5·T-03.4.1.
`seeded_db`(conftest, load.main(fresh=True))가 스키마→시드→백필 전체를 적용한 뒤
검증한다.
"""

from __future__ import annotations

import pytest

TYPE_CODES_5_NONFREELANCE = {"large", "mid", "public", "startup", "foreign"}


def _scalar(conn, sql, params=()):
    with conn.cursor() as cur:
        cur.execute(sql, params)
        return cur.fetchone()[0]


# ── SD-1: 기업유형 6종 ──
def test_SD1_company_type_count(seeded_db):
    assert _scalar(seeded_db, "SELECT COUNT(*) FROM TCOMPANY_TYPE") == 6


# ── SD-2: 프리셋 28행 ──
def test_SD2_benefit_preset_total_count(seeded_db):
    assert _scalar(seeded_db, "SELECT COUNT(*) FROM TBENEFIT_PRESET") == 28


# ── SD-3: 회사 102 (Tier-0) — 95 + CJ 계열 7개사(2026-07-30) ──
def test_SD3_company_count_is_102(seeded_db):
    """정확 카운트 핀. 회사 추가는 **의도적으로만** 가능해야 한다(시드 유실·중복 조기 발견).
    회사를 늘리거나 줄일 땐 이 값과 SI-8·멱등성 스냅샷을 함께 갱신하라."""
    assert _scalar(seeded_db, "SELECT COUNT(*) FROM TCOMPANY") == 113


# ── SD-4: 복지 총행 1553(=1330-모비스13+CJ계열148+파일럿22+배치1 66), 하한 1200 방어 ──
def test_SD4_benefit_total_row_count(seeded_db):
    """정확 카운트 핀 — 시드 유실·중복 적재를 조기에 잡는다.

    내역: 원본 1330 − 모비스 중복 13 = 1317 (2026-07 재이식분)
          + CJ 계열 7개사 148행(2026-07-30) = 1465
          엔터 22 · 커머스 24 · 프레시웨이 21 · 올리브영 22 · 대한통운 19 · 제일제당 20 · CGV 20
          ⚠ 주식보상(RSU)은 일회성 부여 공시라 상시 제도가 아니어서 제외했다(-2행, 사용자 결정).
          + 에이전트 재수집 파일럿 +22행(2026-08-31) = 1487
          셀트리온 22→20(근거 없는 8행 제외·신규 6행) · 아이센스 5→29(구본=자회사 오염 전면 교체)
          — handoff/2026-08-31-복지-에이전트수집-파일럿.md
          + 에이전트 재수집 배치 1 +66행(2026-08-31) = 1553
          알테오젠 3→12 · 유진테크 4→12 · 엠씨넥스 5→14 · 엔켐 6→16 · 삼성카드 7→23(구본=에코비트
          오염) · 실리콘투 6→20 · 삼천당제약 7→7 — 리메드·오스코텍·리노공업은 공식 소스 부재로
          무변경. handoff/2026-08-31-복지-배치1.md
          + 확장 웨이브 1 신규 11개사 +202행(2026-09-01) = 1755
          원익IPS 24 · LG CNS 27 · 한국타이어 22 · KB금융 21 · 엘앤에프 20 · HD현대 19 ·
          심텍 17 · 하나마이크론 14 · 현대건설 14 · LS ELECTRIC 12 · 고려아연 12
          — handoff/2026-09-01-회사확장-웨이브1.md
    """
    count = _scalar(seeded_db, "SELECT COUNT(*) FROM TCOMPANY_BENEFIT")
    assert count == 1755, f"복지 총행 불일치: {count} (기대 1755 = 1553 + 웨이브1 202)"
    assert count >= 1200


# ── SD-5: 회사별 복지 ≥1 (복지 0개 회사 수 = 0) ──
def test_SD5_every_company_has_benefit(seeded_db):
    bad = _scalar(
        seeded_db,
        """
        SELECT COUNT(*) FROM TCOMPANY c
        LEFT JOIN TCOMPANY_BENEFIT b ON b.COMP_ID = c.COMP_ID
        WHERE b.BENEFIT_ID IS NULL
        """,
    )
    assert bad == 0


# ── SD-6: 회사별 별칭 ≥1 (별칭 0개 회사 수 = 0) ──
def test_SD6_every_company_has_alias(seeded_db):
    bad = _scalar(
        seeded_db,
        """
        SELECT COUNT(*) FROM TCOMPANY c
        LEFT JOIN TCOMPANY_ALIAS a ON a.COMP_ID = c.COMP_ID
        WHERE a.ALIAS_ID IS NULL
        """,
    )
    assert bad == 0


# ── SD-7: 프리셋 유형 커버 (freelance 제외 5유형 ≥1행, freelance=0행) ──
@pytest.mark.parametrize("type_cd", sorted(TYPE_CODES_5_NONFREELANCE))
def test_SD7_preset_covers_non_freelance_types(seeded_db, type_cd):
    count = _scalar(
        seeded_db,
        """
        SELECT COUNT(*) FROM TBENEFIT_PRESET p
        JOIN TCOMPANY_TYPE t ON t.COMP_TP_ID = p.COMP_TP_ID
        WHERE t.COMP_TP_CD = %s
        """,
        (type_cd,),
    )
    assert count >= 1, f"{type_cd} 유형 프리셋 0행"


def test_SD7_freelance_has_zero_presets(seeded_db):
    count = _scalar(
        seeded_db,
        """
        SELECT COUNT(*) FROM TBENEFIT_PRESET p
        JOIN TCOMPANY_TYPE t ON t.COMP_TP_ID = p.COMP_TP_ID
        WHERE t.COMP_TP_CD = 'freelance'
        """,
    )
    assert count == 0
