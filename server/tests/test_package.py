"""T-04.1.1 패키지 스캐폴드 스모크 + T-04.1.2 conftest 픽스처 스모크.

레거시 델타(auth/oauth/profiler/comparisons/admin/landing 라우터·모듈 부재)
회귀. SP-API-1 · SP-ARCH-6 · INV-1 · FR-90.
"""
from __future__ import annotations

import importlib
import os

import pytest

SERVER_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROUTERS_DIR = os.path.join(SERVER_DIR, "routers")

FORBIDDEN_MODULE_NAMES = ["auth", "oauth", "profiler", "comparisons", "admin", "landing"]


def test_T04_1_1_package_import_smoke():
    """server·server.routers·server.services·server.models import 스모크."""
    for name in ("server", "server.routers", "server.services", "server.models"):
        importlib.import_module(name)  # ImportError 시 실패


def test_T04_1_1_forbidden_legacy_modules_absent():
    """auth/oauth/profiler/comparisons/admin/landing 라우터·모듈 파일 부재 (레거시 델타)."""
    for base_dir in (SERVER_DIR, ROUTERS_DIR):
        for fname in os.listdir(base_dir):
            stem = fname[:-3] if fname.endswith(".py") else fname
            assert stem not in FORBIDDEN_MODULE_NAMES, f"금지 모듈 발견: {os.path.join(base_dir, fname)}"


def test_T04_1_1_routers_package_file_allowlist():
    """routers/ 파일 허용목록 — health·reference·companies + trending(INV-1 개정
    2026-07-14 익명 비교 트렌딩; 레거시 'comparisons' 모듈명은 사용자 저장 비교
    부활 방지를 위해 계속 금지) (+ __init__.py)."""
    py_files = {f for f in os.listdir(ROUTERS_DIR) if f.endswith(".py")}
    assert py_files == {"__init__.py", "health.py", "reference.py", "companies.py", "trending.py"}


@pytest.mark.asyncio
async def test_T04_1_2_client_fixture_boots(client):
    """conftest `client` 픽스처가 정상 부트되어 요청을 처리한다."""
    resp = await client.get("/api/v1/health")
    assert resp.status_code == 200


@pytest.mark.asyncio
async def test_T04_1_2_fake_data_monkeypatch_applied(client, fake_data):
    """`fake_data` 픽스처가 database.fetch_one/fetch_all을 실제로 대체했는지 확인.

    companies/1(캔드 존재)·companies/999999(캔드 부재)로 monkeypatch가 라우터
    호출 경로까지 실제로 반영됐음을 왕복 검증한다.
    """
    ok = await client.get("/api/v1/companies/1")
    missing = await client.get("/api/v1/companies/999999")
    assert ok.status_code == 200
    assert missing.status_code == 404
