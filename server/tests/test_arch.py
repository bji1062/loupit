"""SP-ARCH 아키텍처 회귀 테스트 (T1·T3).

근거: SPEC/01 §9.2(아키텍처 테스트 케이스), TASK/01 T-01.1.1·T-01.3.1.
- T1: 리포지토리 레이아웃(6 디렉토리) — 본 마일스톤(M0)에서 green.
- T3: build_reference_bundle 단일 소스 회귀 — 실구현은 M2(SP-API), 그때 skip 해제.
"""
import os

import pytest

# server/tests/test_arch.py → dirname ×3 = loupit/ (리포 루트)
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

REQUIRED_DIRS = ["web", "server", "db", "generator", "infra", "docs"]


def test_T1_repo_layout():
    """T1: 최상위 6종 디렉토리 존재 (SP-ARCH-6, INV-3 레이아웃)."""
    missing = [d for d in REQUIRED_DIRS if not os.path.isdir(os.path.join(ROOT, d))]
    assert not missing, f"누락 디렉토리: {missing}"


@pytest.mark.skip(reason="T-01.3.1: build_reference_bundle 단일 소스 회귀 — 실구현은 M2(SP-API). 그때 skip 해제.")
def test_T3_bundle_single_source():
    """T3: 런타임 라우터(FR-92)와 generator(C2)가 동일 build_reference_bundle 심볼 참조(SP-ARCH-4)."""
    from server.services.reference import build_reference_bundle  # noqa: F401

    raise NotImplementedError("M2에서 라우터·generator 참조 동일성 assert")
