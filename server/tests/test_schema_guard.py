"""C-1 안전장치 회귀 테스트 — 복원 래퍼 없이 서빙 스키마를 비우는 사고를 막는 가드.

배경(2026-07-11 종합검증 C-1): 테스트 하네스가 서빙 스키마 LOUPIT 의 테이블을 DROP 하므로,
복원(재시드) 없이 `pytest` 를 직접 돌리면 서빙 데이터가 사라진다(실제 발생).

정책(2026-07-12 확정): 이 서버는 LOUPIT 을 테스트에도 재사용한다. 단 **서빙 스키마 대상
테스트는 `run_tests.sh` 경유로만 허용**한다 — run_tests.sh 는 테스트 후 load.py 로 서빙
데이터를 자동 복원(trap)하기 때문이다. 맨 `pytest` 직접 실행(복원 보장 없음)은 차단한다.
run_tests.sh 는 이 허용을 `LOUPIT_ALLOW_SERVING_SCHEMA=1` 로 신호한다.
"""

from __future__ import annotations

import pytest

from server.tests.schema_guard import ServingSchemaError, assert_test_target


class TestServingSchemaGuard:
    def test_serving_schema_rejected_without_allow(self):
        # 맨 pytest 직접 실행(플래그 없음) → 서빙 스키마면 차단.
        with pytest.raises(ServingSchemaError):
            assert_test_target("LOUPIT", allow_serving=False)
        with pytest.raises(ServingSchemaError):
            assert_test_target("loupit", allow_serving=False)

    def test_serving_schema_allowed_with_flag(self):
        # run_tests.sh 경유(복원 보장) → 서빙 스키마 허용.
        assert assert_test_target("LOUPIT", allow_serving=True) == "LOUPIT"

    def test_empty_or_missing_is_rejected(self):
        with pytest.raises(ServingSchemaError):
            assert_test_target("", allow_serving=True)
        with pytest.raises(ServingSchemaError):
            assert_test_target(None, allow_serving=False)

    def test_non_serving_schema_is_allowed_without_flag(self):
        # 미래에 별도 테스트 스키마를 쓰더라도 서빙이 아니면 플래그 없이 허용.
        assert assert_test_target("LOUPIT_TEST", allow_serving=False) == "LOUPIT_TEST"

    def test_whitespace_is_trimmed(self):
        assert assert_test_target("  LOUPIT  ", allow_serving=True) == "LOUPIT"
