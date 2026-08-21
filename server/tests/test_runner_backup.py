"""T-13.2.1 (SC14): `run_tests.sh` 참여 7테이블 백업/재주입 장치 구조 가드.

인프라 데이터 보호 계약을 회귀로 못박는다. 릴리스 게이트(`infra/deploy/run_tests.sh`)는
서빙 스키마(LOUPIT)를 테스트에도 재사용하고 conftest 가 격리를 위해 테이블을 DROP/CREATE
하므로, ③(conftest) 후 참여 테이블이 편입되면 회원·세션·인증·재직·편집이력 등 **시드로
재현 불가한** 데이터가 게이트 실행마다 소실될 수 있다(TCOMPARE_LOG 와 동일 위험, #1). 그래서
게이트는 pytest 이전 mysqldump 백업 → 재시드 이후 재주입 장치를 갖춘다(SP-INFRA-6.2a·§C
T-13.2.1). 이 테스트는 그 장치가 배선돼 있는지를 **스크립트 텍스트로** 검증한다 — 라이브 DB
무접촉(mutation 테스트 금지, 2026-07-20 사고). test_surface·test_package 와 동일한 구조 가드
계열이며, 참여 테이블이 아직 없어도(현 익명 배포) 항상 그린이다(장치는 존재검사로 no-op).
"""
from __future__ import annotations

import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
RUN_TESTS = os.path.join(ROOT, "infra", "deploy", "run_tests.sh")

# ⚠ **하드코딩 사본을 없앴다(2026-07-29)**. 구 판본은 참여 7테이블 목록을 여기 한 벌 더 적어
# 두고 그것과만 대조했다 — 그래서 `TMAIL_EVENT`·`TMAIL_SUPPRESSION`(SP-AUTH-16) 이 격리
# 사이클에 편입됐을 때 **이 가드가 통과했다**(실측). 즉 게이트가 매 릴리스 그 두 테이블을
# DROP/CREATE 하는데 백업 목록엔 없는 상태 = 프로덕션 억제 목록 소실을, 가드가 못 본 것이다.
# 이제 conftest(단일 출처)에서 파생시켜 **새 테이블이 추가되면 자동으로 빨개진다**.
from server.tests.conftest import (  # noqa: E402  (ROOT 계산 뒤 임포트 — 무 DB 상수만 읽는다)
    CORP_FINANCE_CREATE_ORDER,
    MAIL_OPS_CREATE_ORDER,
    PARTICIPATION_CREATE_ORDER,
    TABLE_CREATE_ORDER,
    _REFERENCE_CREATE_ORDER,
)

# 게이트가 지워버리는 **시드로 재현 불가한** 테이블 = 백업/재주입 대상. 재주입 순서는 FK
# 부모→자식이라 참여 테이블이 먼저고, 메일 2테이블은 FK 가 없어 뒤에 붙는다.
#
# ⚠ `TCOMPANY_EMAIL_DOMAIN` 은 **제외**한다 — FK 위상으로는 참여 테이블이지만 **내용은 시드**다
#   (`db/seed/company_email_domain.sql`). 백업 목록에 두면 재시드가 넣은 행 위에 백업분을 또
#   넣어 **PK 충돌**이 난다(2026-07-29 실제 릴리스에서 발생: `Duplicate entry '1'`).
#   더 나빴던 건 2차 피해다: 덤프에서 이 테이블이 앞쪽이라 **뒤따르던 메일 2테이블이 통째로
#   복원되지 않았다**(mysql 클라이언트가 첫 오류에서 중단). 아래 SEED_RESTORABLE 파생 검사가
#   이 조합을 원천 차단한다.
# 2026-08-21: 회사 재무 3테이블(CORP_FINANCE_CREATE_ORDER)을 파생 소스에 편입한다. 시드가 아니라
#   런타임 수집으로만 채워지므로 백업/재주입이 유일한 생존 수단이다 — 특히 `TCOMPANY_CORP` 에는
#   102개 매칭 중 사람이 판정한 6건의 근거(MATCH_NOTE_CTNT)가 들어 있다.
#   ⚠ 이 셋을 `db/seed/` 로 옮기는 순간 `_seed_sql_tables()` 가 SEED_RESTORABLE 로 잡아
#     아래 파생 검사가 "백업 목록에서 빼라"고 요구한다 — TCOMPANY_EMAIL_DOMAIN 과 같은 처리다.
BACKUP_EXPECTED_ORDER = (
    [t for t in PARTICIPATION_CREATE_ORDER if t != "TCOMPANY_EMAIL_DOMAIN"]
    + list(MAIL_OPS_CREATE_ORDER)
    + list(CORP_FINANCE_CREATE_ORDER)
)


def _seed_sql_tables() -> set[str]:
    """`db/seed/*.sql` 이 INSERT/REPLACE 하는 테이블 — **파일에서 파생**한다.

    하드코딩 사본을 두지 않는 이유는 이 파일 머리말과 같다. 시드 파일이 새로 생기거나 대상
    테이블이 바뀌면 아래 불변식이 자동으로 따라간다."""
    seed_dir = os.path.join(ROOT, "db", "seed")
    found: set[str] = set()
    for name in os.listdir(seed_dir):
        if not name.endswith(".sql"):
            continue
        with open(os.path.join(seed_dir, name), encoding="utf-8") as f:
            text = f.read()
        found |= {
            m.upper()
            for m in re.findall(r"(?:INSERT|REPLACE)\s+(?:IGNORE\s+)?INTO\s+`?([A-Za-z_]+)`?", text)
        }
    return found


# 시드 경로가 되살리는 테이블 = 백업 대상이 **아니다**. 참조 6종은 `load.py --fresh` 가,
# 나머지는 `db/seed/*.sql` 이 복원한다(TCOMPARE_LOG 는 전용 backup_compare_log 경로).
SEED_RESTORABLE = set(_REFERENCE_CREATE_ORDER) | _seed_sql_tables()


def _script() -> str:
    with open(RUN_TESTS, encoding="utf-8") as f:
        return f.read()


def _part_tables() -> list[str]:
    m = re.search(r'PART_TABLES="([^"]*)"', _script())
    assert m, "PART_TABLES 정의 부재"
    return m.group(1).split()


def test_run_tests_sh_exists():
    assert os.path.isfile(RUN_TESTS), f"릴리스 게이트 스크립트 부재: {RUN_TESTS}"


def test_part_tables_matches_conftest_source_of_truth():
    """PART_TABLES = 참여 7 + 메일 2, FK 부모→자식 순(재주입 순서 안전).

    목록을 conftest 에서 **파생**시킨다 — 사본을 두면 갈라지고, 갈라진 쪽이 조용히 데이터를
    잃는다(구 판본이 정확히 그랬다: 파일 머리말 참조)."""
    listed = _part_tables()
    assert listed == BACKUP_EXPECTED_ORDER, (
        f"PART_TABLES 순서/집합이 conftest 와 불일치\n  실제: {listed}\n  기대: {BACKUP_EXPECTED_ORDER}"
    )


def test_every_non_seed_table_is_backed_up():
    """**핵심 불변식**: 격리 사이클 안에서 시드로 복원되지 않는 테이블은 전부 백업 대상이다.

    게이트는 서빙 스키마의 `TABLE_CREATE_ORDER` 를 DROP/CREATE 한다. 참조 테이블은
    `load.py --fresh` 가 되살리고 TCOMPARE_LOG 는 전용 경로가 있지만, 그 외 테이블은
    **백업/재주입이 유일한 생존 수단**이다. 새 테이블을 conftest 에만 넣고 여기를 잊으면
    릴리스마다 조용히 소실된다 — 이 테스트가 그 조합을 원천 차단한다.
    """
    listed = set(_part_tables())
    must_backup = set(TABLE_CREATE_ORDER) - SEED_RESTORABLE
    missing = sorted(must_backup - listed)
    assert not missing, (
        f"격리 사이클에 있는데 백업 목록에 없는 테이블: {missing} — "
        f"run_tests.sh 의 PART_TABLES 에 추가하라(릴리스마다 데이터 소실)"
    )
    stale = sorted(listed - set(TABLE_CREATE_ORDER))
    assert not stale, f"PART_TABLES 에 격리 사이클 밖 테이블: {stale} (오타·삭제 잔재)"


def test_no_double_restore_collision():
    """**시드가 되살리는 테이블은 백업 대상이 아니다** — 이중 복원은 PK 충돌을 낸다.

    2026-07-29 실제 릴리스가 여기서 깨졌다: `TCOMPANY_EMAIL_DOMAIN` 은 FK 위상상 참여
    테이블이라 PART_TABLES 에 있었는데 내용은 시드(`db/seed/company_email_domain.sql`)다.
    재시드가 31행을 넣은 뒤 백업분을 또 넣으려다 `Duplicate entry '1'` 로 실패했고,
    **덤프에서 뒤따르던 메일 2테이블이 통째로 복원되지 않았다**(mysql 이 첫 오류에서 중단).

    즉 이 충돌은 자기 자신만 깨는 게 아니라 **뒤에 있는 모든 테이블의 데이터를 날린다**.
    그래서 "충돌 나면 고친다"가 아니라 배포 전에 조합 자체를 금지한다."""
    collide = sorted(set(_part_tables()) & SEED_RESTORABLE)
    assert not collide, (
        f"시드가 복원하는 테이블이 백업 목록에도 있다: {collide} — 재주입 시 PK 충돌로 "
        f"그 테이블은 물론 **덤프에서 뒤따르는 테이블까지 복원되지 않는다**. "
        f"PART_TABLES 에서 빼라(시드 경로가 이미 되살린다)."
    )


def test_backup_runs_before_trap_and_gate():
    """backup_participation 호출이 (1) 트랩 무장 전, (2) 백엔드 pytest 전에 온다
    — DROP(격리) 전에 백업해야 데이터가 보호된다."""
    s = _script()
    m_call = re.search(r"^backup_participation +#", s, re.M)  # 호출부(주석 딸림); 정의는 '(){'
    assert m_call, "backup_participation 호출부 부재"
    i_backup = m_call.start()
    i_trap = s.find("trap _on_exit EXIT")
    i_pytest = s.find("pytest server/tests/")
    assert i_trap != -1 and i_pytest != -1, "트랩/게이트 앵커 부재"
    assert i_backup < i_trap < i_pytest, "백업은 트랩·백엔드 pytest 앞에 실행돼야 함"


def test_backup_is_existence_aware():
    """참여 테이블 존재를 information_schema 로 조회한 뒤에만 덤프 — 부재 시 no-op(현 익명 배포)."""
    s = _script()
    assert "information_schema.TABLES" in s, "존재검사(information_schema) 부재"
    assert ("no-op" in s) or ("백업 생략" in s), "부재 시 생략 경로 부재"


def test_backup_halts_on_failure():
    """백업/존재조회 실패 시 게이트를 중단(exit 비0)한다 — 무엇을 보호할지 모르면 파괴 경로 진입 금지."""
    fn = re.search(r"backup_participation\(\)\s*\{(.*?)\n\}", _script(), re.S)
    assert fn, "backup_participation 함수 부재"
    assert re.search(r"\bexit\s+[1-9]", fn.group(1)), "백업 실패 시 exit(데이터 보호) 부재"


def test_reinject_wired_in_trap_and_main_flow():
    """reinject_participation 이 (1) EXIT 트랩과 (2) 본류(restore_serving 이후)에 배선."""
    s = _script()
    trap = re.search(r"_on_exit\(\)\s*\{([^}]*)\}", s)
    assert trap and "reinject_participation" in trap.group(1), "EXIT 트랩에 reinject_participation 부재"
    body = s[s.find("pytest server/tests/"):]
    i_restore = body.find("restore_serving")
    i_reinject = body.find("reinject_participation")
    assert i_restore != -1 and i_reinject != -1, "본류 앵커 부재"
    assert i_restore < i_reinject, "재주입은 재시드(restore_serving) 이후여야 함"


def test_reinject_fk_on_and_data_only():
    """재주입은 FK 검사를 켠 채(reinject_compare_log 동일 fail-safe: 로스터 드리프트 시 전량 거부·
    덤프 보존) + 데이터만(--no-create-info, 스키마 무변경)."""
    s = _script()
    assert "--no-create-info" in s, "데이터-only 덤프(--no-create-info) 부재 — 스키마 덮어쓰기 위험"
    fn = re.search(r"reinject_participation\(\)\s*\{(.*?)\n\}", s, re.S)
    assert fn, "reinject_participation 함수 부재"
    assert "FOREIGN_KEY_CHECKS=0" not in fn.group(1), (
        "참여 재주입이 FK 검사를 끔 — proven 경로(reinject_compare_log)의 fail-safe(드리프트 거부)와 불일치"
    )


def test_compare_log_path_preserved():
    """기존 TCOMPARE_LOG 보존 경로(프로벤)는 그대로 — 참여 확장이 그것을 대체·훼손하지 않는다."""
    s = _script()
    assert "backup_compare_log" in s and "reinject_compare_log" in s, "TCOMPARE_LOG 보존 경로 훼손"


def test_base_gate_excludes_sc14_marker():
    """③ RED 스테이징: 베이스 백엔드 게이트가 `-m "not sc14"` 로 미구현 SC14 스펙을 제외해
    RED 스펙이 배포를 막지 않는다(SC14 마커 등록: conftest.pytest_configure)."""
    s = _script()
    assert re.search(r"""pytest\s+server/tests/[^\n]*-m\s+["']not sc14["']""", s), (
        "run_tests.sh 백엔드 게이트에 -m 'not sc14' 제외 부재 — RED SC14 스펙이 베이스 배포를 막을 수 있음"
    )


if __name__ == "__main__":  # conftest/DB 없이 자체 검증용(python server/tests/test_runner_backup.py)
    _fns = [v for k, v in sorted(globals().items()) if k.startswith("test_") and callable(v)]
    for _f in _fns:
        _f()
        print(f"  ok  {_f.__name__}")
    print(f"ALL {len(_fns)} STRUCTURAL CHECKS PASS")
