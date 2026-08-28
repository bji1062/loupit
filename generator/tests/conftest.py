"""generator/tests/conftest.py — fake 번들 픽스처 노출 (T-07.11.1, SP-GEN-12.1).

전 GC-1~26 스위트가 여기 정의된 fixture로 무 DB 렌더 경로를 구동한다.
"""
from __future__ import annotations

import copy
import json
from datetime import datetime

import pytest

from generator.tests.fixtures import (
    FAKE_BUNDLE,
    FAKE_BUNDLE_XSS,
    FAKE_COMBINATIONS_RAW,
    FAKE_EMPLOY,
    FAKE_FINANCE,
)

# 배지 3파생(GC-13)을 결정적으로 재현하는 고정 빌드 시각. FAKE_BUNDLE의
# expires_dtm은 이 시각을 기준으로 미래(2099)/과거(2020)로 설계되어 있으므로
# 실제 값은 임의 시각이어도 무방하지만, 테스트 결정성을 위해 고정한다.
FAKE_NOW = datetime(2026, 7, 11)


@pytest.fixture
def fake_bundle() -> dict:
    """오염 방지를 위한 깊은 복사본(테스트 간 상호 격리)."""
    return copy.deepcopy(FAKE_BUNDLE)


@pytest.fixture
def fake_bundle_xss() -> dict:
    return copy.deepcopy(FAKE_BUNDLE_XSS)


@pytest.fixture
def fake_now() -> datetime:
    return FAKE_NOW


@pytest.fixture
def fake_finance() -> dict:
    """재무 픽스처(SP-FIN) 깊은 복사본 — `build_context(bundle, finance=…)` 에 주입한다.
    기존 스위트는 이걸 쓰지 않으므로 재무 없는 렌더 경로가 그대로 남는다(무회귀 계약)."""
    return copy.deepcopy(FAKE_FINANCE)


@pytest.fixture
def fake_employ() -> dict:
    """직원 현황 픽스처(SP-MET-8) 깊은 복사본 — `build_context(bundle, employ=…)` 에 주입한다.

    재무와 **따로** 받는 이유는 둘의 경계가 실제로 다르기 때문이다: 재무만 실린 빌드(수집 순서상
    실제로 존재했다)와 둘 다 실린 빌드가 서로 다른 화면을 내야 하고, 그 차이를 테스트가 갈라 볼 수
    있어야 한다. 기존 스위트는 이 픽스처를 쓰지 않으므로 직원 없는 렌더 경로가 그대로 남는다.
    """
    return copy.deepcopy(FAKE_EMPLOY)


@pytest.fixture
def fake_combinations_path(tmp_path, monkeypatch):
    """`generator.pages.combo.COMBINATIONS_PATH`를 fake 조합 목록으로 교체.

    회사 3개(FAKE_BUNDLE)로 유효 조합 2 + 무효 조합 1(kakao 미등록, GC-23)을
    구동하기 위해 프로덕션 `generator/data/combinations.json` 대신 임시
    파일을 가리키도록 monkeypatch한다.
    """
    from generator.pages import combo as combo_module

    path = tmp_path / "combinations.json"
    path.write_text(json.dumps(FAKE_COMBINATIONS_RAW, ensure_ascii=False), encoding="utf-8")
    monkeypatch.setattr(combo_module, "COMBINATIONS_PATH", path)
    return path
