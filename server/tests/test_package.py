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
    """AU-6(SC14 재명세): routers/ 파일 허용목록 = 익명 5(health·reference·companies·
    trending·__init__) + 참여 3(member·employment·benefit_edit, SP-AUTH-1).

    trending 보존(INV-1 개정 2026-07-14 익명 비교 트렌딩), 라우터명 'auth' 는 FORBIDDEN
    유지(→ member.py, T10), 레거시 'comparisons' 모듈명도 사용자 저장 비교 부활 방지를
    위해 계속 금지. §C item4 — M9 표면 세그먼트에서 구 5파일 게이트를 이 확장 집합으로
    갱신·통합했다(구 @pytest.mark.sc14 test_AU6 를 본 베이스 게이트로 흡수).

    2026-07-29(SP-AUTH-16): `mail_webhook.py` 추가. 참여 3종과 달리 **M9 게이트 밖**이고
    `RESEND_WEBHOOK_SECRET` 이 있을 때만 등록되는 조건부 라우터다(main.create_app) — 파일이
    존재하는 것과 표면에 노출되는 것이 다르며, 표면 계약은 test_m9_gate·test_surface 가 본다.

    2026-07-30(SP-AUTH-19): `console.py` 추가 — SSH 터널 전용 운영 콘솔. **`admin.py` 가
    아니다**: 그 이름은 레거시 델타로 영구 금지이며 아래 어서션이 계속 지킨다. 웹훅과 같은
    조건부 라우터로, `M9_ENABLED` + `OPERATOR_EMAILS` 가 **둘 다** 있어야 등록된다.
    노출 범위는 등록 조건이 아니라 `deps.require_loopback` 가 지킨다(test_console_gate CO-7)."""
    py_files = {f for f in os.listdir(ROUTERS_DIR) if f.endswith(".py")}
    expected = {
        "__init__.py", "health.py", "reference.py", "companies.py", "trending.py",
        "member.py", "employment.py", "benefit_edit.py",
        "mail_webhook.py",
        "console.py",
    }
    assert py_files == expected, f"라우터 허용목록 불일치(대칭차): {py_files ^ expected}"
    assert "auth" in FORBIDDEN_MODULE_NAMES, "라우터명 'auth' 금지 유지(→ member.py, T10)"
    assert "admin" in FORBIDDEN_MODULE_NAMES, "라우터명 'admin' 금지 유지(→ console.py, SP-AUTH-19)"
    assert "trending.py" in py_files, "trending.py 보존(§C item4)"


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
