"""SC14: `release.sh` M9 활성화 가드 구조 검증 (적대리뷰 2026-07-25 major).

`db/schema.sql` 은 SC14 참여 7테이블을 포함하고 `server/main.py` 는 member·employment·
benefit_edit 라우터를 무조건 등록한다. 그래서 릴리스를 한 번 돌리면 **[2] schema 단계가
부재 테이블을 생성 → M9 API 가 즉시 공개**된다. M9 활성화는 AdSense 심사 뒤 체크리스트를
동반한 명시적 결정이므로, 릴리스 스크립트가 `M9_ACTIVATE=1` 없이는 그 경로로 못 가게 막아야
한다. 이 테스트는 그 가드가 **테스트 게이트[1]보다 앞**에 배선돼 있는지를 스크립트 텍스트로
검증한다 — 라이브 DB·서비스 무접촉(뮤테이션 테스트 금지, 2026-07-20 사고).
test_runner_backup.py 와 같은 구조 가드 계열이다.
"""
from __future__ import annotations

import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
RELEASE = os.path.join(ROOT, "infra", "deploy", "release.sh")

PARTICIPATION_TABLES = [
    "TMEMBER", "TSESSION", "TAUTH_CODE", "TCOMPANY_EMAIL_DOMAIN",
    "TEMPLOY_VERIFICATION", "TEMPLOY_VRF_REQUEST", "TBENEFIT_EDIT_LOG",
]


def _script() -> str:
    with open(RELEASE, encoding="utf-8") as f:
        return f.read()


def test_release_has_m9_activation_guard():
    """`M9_ACTIVATE` 환경변수 없이는 참여 테이블 생성 경로로 진입하지 못한다."""
    s = _script()
    assert "M9_ACTIVATE" in s, "M9 활성화 가드가 release.sh 에 없다"
    assert "information_schema.TABLES" in s, "참여 테이블 존재 여부를 실제로 조회해야 한다"
    assert "trap - ERR; exit 1" in s, "가드 미충족 시 중단 경로가 있어야 한다"


def test_guard_checks_all_seven_participation_tables():
    """존재 검사 대상이 SP-DB-17 참여 7테이블 전부다(부분 검사로 빠져나갈 수 없게)."""
    s = _script()
    guard = s.split("M9 활성화 가드", 1)[1].split("[1/7]", 1)[0]
    for t in PARTICIPATION_TABLES:
        assert f"'{t}'" in guard, f"가드 존재 검사에 {t} 누락"
    assert "-eq 7" in guard, "7/7 존재일 때만 '이미 활성'으로 통과해야 한다"


def test_guard_runs_before_test_gate_and_schema_steps():
    """가드는 서빙 상태를 건드리는 모든 단계보다 **앞**이어야 한다.

    [1] 테스트 게이트도 서빙 스키마를 DROP/CREATE 하며 참여 테이블 백업/재주입 장치를 태우므로,
    가드가 [2] schema 직전에만 있으면 이미 늦다."""
    s = _script()
    guard_at = s.index("M9 활성화 가드")
    gate_at = s.index("[1/7] test gate")
    schema_at = s.index("[2/7] schema")
    assert guard_at < gate_at < schema_at


def test_guard_message_points_at_activation_checklist():
    """중단 메시지가 다음 사람에게 '무엇을 하면 되는지'를 알려준다(AdSense 게이트 맥락 포함)."""
    s = _script()
    guard = s.split("M9 활성화 가드", 1)[1].split("[1/7]", 1)[0]
    assert "AdSense" in guard
    assert "M9_ACTIVATE=1" in guard and "RELEASE_CONFIRM=1" in guard
