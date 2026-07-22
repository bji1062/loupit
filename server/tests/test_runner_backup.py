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

# SP-DB-17 참여 7테이블 — FK 부모→자식 생성순서(= 재주입 안전순서). conftest.TABLE_CREATE_ORDER(③)·
# SPEC/02 SP-DB-17 생성순서와 동일해야 한다.
PARTICIPATION_FK_ORDER = [
    "TMEMBER",
    "TCOMPANY_EMAIL_DOMAIN",
    "TSESSION",
    "TAUTH_CODE",
    "TEMPLOY_VERIFICATION",
    "TEMPLOY_VRF_REQUEST",
    "TBENEFIT_EDIT_LOG",
]


def _script() -> str:
    with open(RUN_TESTS, encoding="utf-8") as f:
        return f.read()


def test_run_tests_sh_exists():
    assert os.path.isfile(RUN_TESTS), f"릴리스 게이트 스크립트 부재: {RUN_TESTS}"


def test_part_tables_lists_all_seven_in_fk_order():
    """PART_TABLES 가 참여 7테이블을 FK 부모→자식 순으로 정확히 나열(재주입 순서 안전)."""
    m = re.search(r'PART_TABLES="([^"]*)"', _script())
    assert m, "PART_TABLES 정의 부재"
    listed = m.group(1).split()
    assert listed == PARTICIPATION_FK_ORDER, (
        f"PART_TABLES 순서/집합이 SP-DB-17 FK 생성순서와 불일치: {listed}"
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
