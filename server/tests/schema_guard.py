"""C-1 안전장치 — 복원 래퍼 없이 서빙 스키마를 비우는 사고를 막는 순수 가드.

정책(2026-07-12): 이 서버는 LOUPIT 스키마를 테스트에도 재사용한다. 테스트는 5개 참조
테이블을 DROP/CREATE 하므로, **서빙 스키마(LOUPIT) 대상 테스트는 run_tests.sh 경유로만
허용**한다 — run_tests.sh 는 테스트 종료 후 load.py 로 서빙 데이터를 자동 복원(trap)한다.
맨 `pytest` 직접 실행(복원 보장 없음)은 차단해, 2026-07-11 C-1(run_tests.sh가 서빙을 비운
채 복원 안 함) 같은 사고를 막는다.

conftest 의 pytest_configure 가 세션 시작 시 `assert_test_target(DB_NAME, allow_serving)`
를 호출한다. 순수 함수라 DB 없이 단위테스트 가능(test_schema_guard.py).
"""

from __future__ import annotations

# 서빙(운영/베타)에서 실제로 사용되는 스키마명 — 복원 보장 없이 비워선 안 되는 대상.
SERVING_SCHEMAS = frozenset({"LOUPIT", "loupit"})


class ServingSchemaError(RuntimeError):
    """복원 래퍼 없이 서빙 스키마를 대상으로 테스트를 실행하려 할 때."""


def assert_test_target(db_name: str | None, allow_serving: bool = False) -> str:
    """테스트 대상 DB_NAME 을 검증하고 그 이름을 반환한다.

    거부 조건(fail-closed):
      - 비어있음/미설정 → 오설정.
      - 서빙 스키마(LOUPIT/loupit)인데 allow_serving=False → 복원 보장 없는 직접 실행 차단.
        (run_tests.sh 는 테스트 후 재시드를 보장하므로 allow_serving=True 로 신호한다.)
    서빙이 아닌 스키마는 플래그 없이도 허용(별도 테스트 스키마 사용 여지).
    """
    name = (db_name or "").strip()
    if not name:
        raise ServingSchemaError(
            "DB_NAME 미설정 — server/.env 의 DB_NAME 을 확인하세요."
        )
    if name in SERVING_SCHEMAS and not allow_serving:
        raise ServingSchemaError(
            f"거부: '{name}'는 서빙(운영/베타) 스키마입니다. 테스트 하네스가 이 스키마의 "
            "테이블을 DROP 하므로, 복원을 보장하는 `bash infra/deploy/run_tests.sh` 로만 "
            "실행하세요(테스트 후 load.py 로 서빙 데이터 자동 복원). 맨 `pytest` 직접 실행은 "
            "서빙을 비운 채 복원하지 않으므로 차단합니다. (C-1 안전장치)"
        )
    return name
