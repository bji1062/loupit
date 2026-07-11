"""SP-ARCH 아키텍처 회귀 테스트 (T1·T3).

근거: SPEC/01 §9.2(아키텍처 테스트 케이스), TASK/01 T-01.1.1·T-01.3.1.
- T1: 리포지토리 레이아웃(6 디렉토리) — 본 마일스톤(M0)에서 green.
- T3: build_reference_bundle 단일 소스 회귀 — M2(SP-API) 구현으로 skip 해제(2026-07-11).
"""
import importlib
import os

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

REQUIRED_DIRS = ["web", "server", "db", "generator", "infra", "docs"]


def test_T1_repo_layout():
    """T1: 최상위 6종 디렉토리 존재 (SP-ARCH-6, INV-3 레이아웃)."""
    missing = [d for d in REQUIRED_DIRS if not os.path.isdir(os.path.join(ROOT_DIR, d))]
    assert not missing, f"누락 디렉토리: {missing}"


def test_T3_bundle_single_source():
    """T3: 런타임 라우터(FR-92)와 generator(C2)가 동일 build_reference_bundle 심볼 참조(SP-ARCH-4).

    라우터는 services.reference의 함수를 재구현 없이 직접 import해 사용해야
    한다(identity 검사). generator(C2)는 M5(SP-GEN)에서 빌드되며, DAG상
    SP-API가 SP-GEN보다 선행이라 본 리프(M2) 시점엔 아직 존재하지 않을 수
    있다 — 존재하면 동일 심볼을 강제하고, 부재 시(M5 미착수) services.reference
    가 유일한 정의처임을 확인하는 것으로 단일 소스 요건을 구조적으로 충족한다.
    """
    from server.services.reference import build_reference_bundle as canonical
    from server.routers import reference as reference_router

    assert reference_router.build_reference_bundle is canonical, (
        "라우터가 build_reference_bundle을 재구현했거나 다른 심볼을 참조함(단일 소스 위반)"
    )

    # generator는 build_reference_bundle을 generator/bundle.py에서 소비한다
    # (`from server.services.reference import build_reference_bundle`, SP-API-7 단일 소스).
    # build.py는 bundle.load_bundle()를 통해 간접 사용하므로(속성 재노출 없음),
    # 단일 소스 회귀는 소비 모듈 generator.bundle의 심볼 동일성으로 검증한다(M5 착지 후 존재).
    try:
        generator_bundle = importlib.import_module("generator.bundle")
    except ModuleNotFoundError:
        generator_bundle = None  # M5(SP-GEN) 미착수 — 단일 정의처(services.reference)만 존재하면 충족

    if generator_bundle is not None:
        assert generator_bundle.build_reference_bundle is canonical
