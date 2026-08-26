"""릴리스 게이트(`run_tests.sh`) 서빙 무접촉 계약 — 구조 가드.

역사: 이 모듈은 원래 T-13.2.1(참여 테이블 백업/재주입 장치)을 못박는 가드였다.
게이트가 서빙 스키마(LOUPIT)를 테스트에 재사용하던 시절, DROP/CREATE 로부터
시드로 재현 불가한 데이터를 지키는 장치가 필수였기 때문이다(실소실 전례:
2026-07-29 TCOMPANY_EMAIL_DOMAIN 이중 복원 사고).

2026-08-26 격리 전환으로 전제가 사라졌다: 게이트는 이제 `loupit_test` 만 쓰고
서빙을 아예 만지지 않는다 → 백업/재주입/복원 trap 장치가 통째로 제거됐다.
그래서 이 가드가 지키는 불변식도 뒤집힌다 — **"보호 장치가 있는가"가 아니라
"서빙을 만질 수 있는 경로가 없는가"** 를 스크립트 텍스트로 검증한다.
(test_surface·test_package 와 동일한 구조 가드 계열, 라이브 DB 무접촉.)

⚠ 이 가드가 빨개지는 날 = 누군가 게이트에 서빙 접촉 경로를 되살린 날이다.
그때는 이 파일을 고치지 말고 그 경로를 지워라. 서빙 대상 실행이 정말 필요하면
run_tests.sh 가 아니라 별도 스크립트로, C-1 가드(LOUPIT_ALLOW_SERVING_SCHEMA)의
복원 책임 계약과 함께 만들어야 한다.
"""
from __future__ import annotations

import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
RUN_TESTS = os.path.join(ROOT, "infra", "deploy", "run_tests.sh")


def _script() -> str:
    with open(RUN_TESTS, encoding="utf-8") as f:
        return f.read()


def _code_lines() -> list[str]:
    """주석·빈 줄을 뺀 실행 코드 줄만 — 격리 전환 배경 설명 주석이 금지어를 포함해도 무해."""
    out = []
    for line in _script().splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        out.append(line.split("#", 1)[0])  # 행끝 주석 제거
    return out


def test_run_tests_sh_exists():
    assert os.path.isfile(RUN_TESTS)


def test_gate_targets_isolated_schema():
    """백엔드 pytest 는 격리 스키마 기본값(loupit_test)으로 돈다 — 코드 줄에 export 존재."""
    code = "\n".join(_code_lines())
    assert re.search(r'export\s+DB_NAME="\$\{DB_NAME:-loupit_test\}"', code), (
        "게이트의 DB_NAME 격리 기본값(export DB_NAME=${DB_NAME:-loupit_test}) 부재"
    )


def test_gate_never_signals_serving_allowance():
    """LOUPIT_ALLOW_SERVING_SCHEMA 를 export 하지 않는다 — 그 신호는 '서빙을 만지되 복원을
    책임지는 래퍼'의 계약(C-1)이고, 격리 게이트는 그 래퍼가 아니다."""
    code = "\n".join(_code_lines())
    assert "LOUPIT_ALLOW_SERVING_SCHEMA" not in code, (
        "게이트가 서빙 허용 신호를 보낸다 — 격리 전환(2026-08-26) 위반. "
        "서빙 대상 실행이 필요하면 별도 스크립트로(모듈 머리말 참조)."
    )


def test_gate_has_no_serving_mutation_machinery():
    """구 백업/재주입/복원 장치의 어떤 잔재도 코드에 없다 — 반쯤 되살아난 장치는
    (격리 스키마를 대상으로 오작동하며) 이중 복원 사고(2026-07-29)의 재연 경로다."""
    code = "\n".join(_code_lines())
    forbidden = [
        "mysqldump",
        "backup_compare_log",
        "backup_participation",
        "reinject_compare_log",
        "reinject_participation",
        "restore_serving",
        "trap _on_exit",
        "PART_TABLES",
    ]
    present = [w for w in forbidden if w in code]
    assert not present, f"서빙 접촉/복원 장치 잔재: {present} — 게이트는 서빙 무접촉이어야 한다"


def test_gate_runs_four_sub_suites():
    """Tier-0 #24: 게이트가 4개 서브스위트(백엔드·생성기·node·nginx)를 전부 호출한다."""
    s = _script()
    assert "pytest server/tests/" in s, "백엔드 스위트 호출 부재"
    assert "pytest generator/tests/" in s, "생성기 스위트 호출 부재"
    assert re.search(r"node --test", s), "node:test 스위트 호출 부재"
    assert "nginx -t" in s, "nginx 문법 검사 부재"


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
