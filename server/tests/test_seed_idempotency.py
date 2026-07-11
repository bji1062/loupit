"""SP-SEED-11.4 멱등성 테스트 (SM-1~SM-4).

근거: SPEC/03 SP-SEED-10·SP-SEED-11.4 · TASK/03 T-03.6.1~T-03.6.4.
est↔official 순환 불변식: 파이프라인 단위(단계3+5)로만 멱등 — 단계5(백필)
미실행 시 est 잔존은 최종상태가 아니다(SM-4는 이 사실 자체를 가드로 검증).

주의: 이 스위트는 `seeded_db`(session-scoped, load.main(fresh=True))와
별개로 **자체 fresh 재시드를 반복 실행**해 재실행 안정성을 검증하므로
함수 스코프에서 직접 `load.main`을 호출한다(다른 테스트의 session 픽스처
상태를 건드리지 않도록 마지막에 다시 fresh=True로 복원한다).
"""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SEED_DIR = ROOT / "db" / "seed"
if str(SEED_DIR) not in sys.path:
    sys.path.insert(0, str(SEED_DIR))

import load as seed_load  # noqa: E402  # db/seed/load.py


def _scalar(conn, sql, params=()):
    with conn.cursor() as cur:
        cur.execute(sql, params)
        return cur.fetchone()[0]


def _snapshot(conn) -> dict:
    return {
        "TCOMPANY": _scalar(conn, "SELECT COUNT(*) FROM TCOMPANY"),
        "TCOMPANY_TYPE": _scalar(conn, "SELECT COUNT(*) FROM TCOMPANY_TYPE"),
        "TBENEFIT_PRESET": _scalar(conn, "SELECT COUNT(*) FROM TBENEFIT_PRESET"),
        "TCOMPANY_BENEFIT": _scalar(conn, "SELECT COUNT(*) FROM TCOMPANY_BENEFIT"),
        "badge_official": _scalar(conn, "SELECT COUNT(*) FROM TCOMPANY_BENEFIT WHERE BADGE_CD='official'"),
        "badge_est": _scalar(conn, "SELECT COUNT(*) FROM TCOMPANY_BENEFIT WHERE BADGE_CD='est'"),
        "amt_stated": _scalar(conn, "SELECT COUNT(*) FROM TCOMPANY_BENEFIT WHERE AMT_SOURCE_CD='stated'"),
        "amt_estimated": _scalar(conn, "SELECT COUNT(*) FROM TCOMPANY_BENEFIT WHERE AMT_SOURCE_CD='estimated'"),
        "amt_none": _scalar(conn, "SELECT COUNT(*) FROM TCOMPANY_BENEFIT WHERE AMT_SOURCE_CD='none'"),
    }


# ── SM-1: 재실행 안정 — load.main() 2회 연속 실행 후 카운트·분포 동일 ──
def test_SM1_repeated_full_run_is_stable(seeded_db):
    snap1 = _snapshot(seeded_db)
    seed_load.main(fresh=True)
    snap2 = _snapshot(seeded_db)
    assert snap1 == snap2, f"재실행 전후 분포 불일치: {snap1} != {snap2}"
    assert snap2["TCOMPANY"] == 95
    assert snap2["badge_est"] == 0


# ── SM-2: 프리셋 무중복 — 2회 실행 후 28, 중복 증식 없음 ──
def test_SM2_preset_full_refresh_no_duplication(seeded_db):
    seed_load.main(fresh=True)
    count = _scalar(seeded_db, "SELECT COUNT(*) FROM TBENEFIT_PRESET")
    assert count == 28


# ── SM-3: official 보존 — 시드→백필 후 단계3 재적용→단계5 재실행 시 다시 official ──
def test_SM3_official_survives_reapply_cycle(seeded_db):
    # 1) 현재 전량 official 확인(직전 fresh 시드 기준)
    est_before = _scalar(seeded_db, "SELECT COUNT(*) FROM TCOMPANY_BENEFIT WHERE BADGE_CD='est'")
    assert est_before == 0

    conn = seed_load.connect()
    try:
        with conn.cursor() as cur:
            cur.execute("SET NAMES utf8mb4")
            # 단계3 재적용 — 복지 SQL이 est로 재삽입(DELETE est는 no-op, INSERT는
            # ON DUP KEY UPDATE로 기존 official 행의 BADGE_CD를 다시 est로 되돌림)
            for f in sorted(seed_load.BENEFIT_SQL_DIR.glob("*.sql")):
                seed_load.run_sql_file(cur, f)
            mid_est = _scalar(conn, "SELECT COUNT(*) FROM TCOMPANY_BENEFIT WHERE BADGE_CD='est'")
            assert mid_est > 0, "단계3 재적용 후 est 중간상태가 재현되지 않음(전제 실패)"

            # 단계5 재실행 — 다시 전량 official로 승격
            from backfill_dec2 import backfill

            backfill(cur)
        conn.commit()
    finally:
        conn.close()

    est_after = _scalar(seeded_db, "SELECT COUNT(*) FROM TCOMPANY_BENEFIT WHERE BADGE_CD='est'")
    assert est_after == 0, "단계5 재실행 후에도 est 잔존 — official 보존 실패"

    # 다음 테스트를 위해 session 픽스처 상태를 정본 fresh 시드로 복원
    seed_load.main(fresh=True)


# ── SM-4: 부분실행 감지 — 단계5(백필) 미실행 시 est 잔존은 최종상태 아님 ──
def test_SM4_partial_run_without_backfill_is_not_final_state(seeded_db):
    conn = seed_load.connect()
    try:
        with conn.cursor() as cur:
            cur.execute("SET NAMES utf8mb4")
            for f in sorted(seed_load.BENEFIT_SQL_DIR.glob("*.sql")):
                seed_load.run_sql_file(cur, f)
        conn.commit()

        with conn.cursor() as cur:
            cur.execute("SELECT COUNT(*) FROM TCOMPANY_BENEFIT WHERE BADGE_CD='est'")
            est_count = cur.fetchone()[0]
    finally:
        conn.close()

    # 단계5(백필) 미실행 상태 — est 잔존 확인(최종상태 아님을 나타내는 가드 신호)
    assert est_count > 0, "백필 미실행인데 est=0 — 부분실행 감지 전제 실패"

    # 세션 픽스처 상태 복원(다른 테스트에 영향 없도록)
    seed_load.main(fresh=True)
