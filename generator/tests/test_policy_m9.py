"""M9 정책 문안 전환 계약 — 로그인 배포와 처리방침 문안의 원자성(SP-POL-3·4, SC14).

**왜 스위치인가**: 라이브 `/privacy` 는 지금 "회원가입·로그인·계정 기능이 **없습니다** … 이용자를
식별하는 개인정보(이름·**이메일**·전화번호 등)를 서버에 수집하거나 저장하지 **않습니다**" 라고
선언한다. 로그인이 켜지는 순간 이 문장은 사실과 어긋난다 — 서비스가 로그인 이메일을 실제로
저장하기 때문이다. 개인정보처리방침은 실제 처리와 일치해야 하므로(개인정보보호법 §30) 문안 전환은
**로그인 배포보다 늦어도, 이르어도 안 된다**.

그래서 `server/config.Settings.m9_enabled` 와 **같은 환경변수(`M9_ENABLED`)**가 생성기의
`GenConfig.m9_enabled` 도 지배한다. `release.sh` 가 `server/.env` 를 `set -a` 로 source 하므로
정적 재생성([4/7])과 API 재시작([5/7])이 한 릴리스 안에서 같은 값을 본다.

두 방향 모두 **적극 검증**한다 — 한쪽만 보면 "문안이 늘 최신"이라는 착각으로 OFF 배포에 로그인
문안이 나가는 반대 사고를 못 잡는다.
"""
from __future__ import annotations

import pytest

from generator.config import GenConfig
from generator.content.policy import build_policy_docs, required_items

PRE_M9 = GenConfig(m9_enabled=False)
POST_M9 = GenConfig(m9_enabled=True)


def _doc(cfg, key: str):
    return next(d for d in build_policy_docs(cfg) if d.key == key)


def _text(doc) -> str:
    """문서 전체 문안(메타 + 모든 문단)을 한 문자열로."""
    parts = [doc.meta_description]
    for s in doc.sections:
        parts.append(s.heading)
        parts.append(s.toc_label)
        parts.extend(s.paragraphs)
    return "\n".join(parts)


def _ids(doc) -> set[str]:
    return {s.req_id for s in doc.sections}


# ── OFF(현 익명 배포): 로그인 없음이 사실 ────────────────────────────────────────────
def test_PM1_off_has_no_member_sections():
    """OFF: P7·T5 미노출 — 존재하지 않는 회원 제도를 고지하지 않는다."""
    assert "P7" not in _ids(_doc(PRE_M9, "privacy"))
    assert "T5" not in _ids(_doc(PRE_M9, "terms"))


def test_PM2_off_states_no_login():
    """OFF: '로그인·계정 없음'을 그대로 선언한다(현 서비스의 정확한 기술)."""
    privacy = _text(_doc(PRE_M9, "privacy"))
    terms = _text(_doc(PRE_M9, "terms"))
    assert "회원가입·로그인·계정 기능이 없습니다" in privacy
    assert "로그인·회원가입 없이 제공" in terms


# ── ON(SC14 기여 배포): 로그인 있음이 사실 ──────────────────────────────────────────
def test_PM3_on_adds_member_sections():
    """ON: P7(회원 정보 처리)·T5(가입·탈퇴·기여 이력) 신설 — SPEC/09 SP-POL-3·4."""
    privacy_doc = _doc(POST_M9, "privacy")
    terms_doc = _doc(POST_M9, "terms")
    assert "P7" in _ids(privacy_doc)
    assert "T5" in _ids(terms_doc)
    # 앵커 계약(PC-2와 동일 규칙)
    assert {s.anchor for s in privacy_doc.sections} >= {"p7"}
    assert {s.anchor for s in terms_doc.sections} >= {"t5"}


def test_PM4_on_retracts_the_no_login_claim():
    """ON: '로그인·계정 없음'류 절대 주장이 **사라진다**.

    이 테스트가 핵심이다 — P7 을 추가하면서 P1 의 구 문장을 그대로 두면 같은 문서가
    "로그인 없음"과 "로그인 시 이메일 보관"을 동시에 말하는 자기모순 고지가 된다."""
    privacy = _text(_doc(POST_M9, "privacy"))
    terms = _text(_doc(POST_M9, "terms"))
    for claim in ("회원가입·로그인·계정 기능이 없습니다", "로그인·회원이 없어"):
        assert claim not in privacy, f"ON 인데 '로그인 없음' 주장 잔존: {claim}"
    for claim in ("로그인·회원가입 없이 제공", "로그인·회원 없음"):
        assert claim not in terms, f"ON 인데 '로그인 없음' 주장 잔존: {claim}"


def test_PM5_on_p7_states_pii_contract():
    """ON: P7 이 SP-AUTH 회원 PII 계약과 정합(평문 2종·해시 at-rest·탈퇴 파기·이력 존치)."""
    p7 = next(s for s in _doc(POST_M9, "privacy").sections if s.req_id == "P7")
    body = "\n".join(p7.paragraphs)
    assert "로그인 이메일" in body and "닉네임" in body      # 평문 보관 2종(INV-8)
    assert "해시" in body                                     # 코드·세션·회사이메일 원문 무저장(NFR30)
    assert "탈퇴" in body and "파기" in body                  # 탈퇴 시 파기
    assert "편집 이력" in body                                # 닉네임·이력 존치 고지(약관 T5)
    assert p7.cross_route == "/terms"                         # 단일 진실 위임


def test_PM6_on_t5_states_membership_lifecycle():
    """ON: T5 가 가입·탈퇴·공개 이력을 고지하고 상세는 /privacy 로 위임(단일 진실)."""
    t5 = next(s for s in _doc(POST_M9, "terms").sections if s.req_id == "T5")
    body = "\n".join(t5.paragraphs)
    assert "탈퇴" in body
    assert "편집 이력" in body
    assert t5.cross_route == "/privacy"


def test_PM7_on_p1_distinguishes_anonymous_from_contribution():
    """ON: P1 이 '익명 열람 무수집'과 '기여 로그인'을 구분한다 — P7 과 모순되지 않게."""
    p1 = next(s for s in _doc(POST_M9, "privacy").sections if s.req_id == "P1")
    body = "\n".join(p1.paragraphs)
    assert "로그인 없이" in body          # 익명 열람은 여전히 무로그인
    assert "기여" in body                  # 기여 시에만 로그인
    # PC-2 인접 계약 유지(test_policy_content 의 P1 어서션)
    assert "서버" in body and ("수집" in body or "저장" in body)


# ── REQUIRED_ITEMS 가 모드를 따라간다 ───────────────────────────────────────────────
@pytest.mark.parametrize(
    "cfg,key,expected",
    [
        (PRE_M9, "privacy", {"P1", "P2", "P3", "P4", "P5", "P6"}),
        (PRE_M9, "terms", {"T1", "T2", "T3", "T4"}),
        (POST_M9, "privacy", {"P1", "P2", "P3", "P4", "P5", "P6", "P7"}),
        (POST_M9, "terms", {"T1", "T2", "T3", "T4", "T5"}),
    ],
)
def test_PM8_required_items_track_mode(cfg, key, expected):
    """PC-2 의 필수 항목 계약이 모드별로 정확하다(SPEC/09 §SP-POL-2)."""
    assert required_items(cfg)[key] == expected


@pytest.mark.parametrize("cfg", [PRE_M9, POST_M9])
def test_PM9_sections_cover_required_items_in_both_modes(cfg):
    """두 모드 모두 실제 섹션이 필수 항목을 덮는다(PC-2 의 모드 일반화)."""
    req = required_items(cfg)
    for doc in build_policy_docs(cfg):
        assert _ids(doc) >= req[doc.key], (
            f"[m9_enabled={cfg.m9_enabled}] {doc.key} 필수 항목 누락: {req[doc.key] - _ids(doc)}"
        )


@pytest.mark.parametrize("raw", ["1", "0", "true", "false", "TRUE", "False", "yes", "no", "on", "off"])
def test_PM11_server_and_generator_agree_on_every_env_value(monkeypatch, raw):
    """**원자성의 실체**: 같은 `M9_ENABLED` 값에 서버와 생성기가 반드시 같은 판정을 내린다.

    두 모듈이 각자 문자열을 파싱하면 조용히 갈라진다 — 실제로 초판은 서버가 pydantic 의 넓은
    truthy 집합(`true·yes·on`…)을 받고 생성기는 `== "1"` 만 받아, `M9_ENABLED=true` 로 배포하면
    **로그인은 켜지고 정책 문안은 '로그인 없음'으로 남는** 정확히 그 사고가 났다. 한쪽만 보는
    테스트로는 절대 안 잡히므로 교차 검증한다."""
    from server.config import Settings

    # GenConfig 필드 기본값은 임포트 시점 1회 평가되므로, 재평가 가능한 파서를 직접 부른다.
    from generator.config import env_flag

    monkeypatch.setenv("M9_ENABLED", raw)
    server_val = Settings(_env_file=None).m9_enabled
    gen_val = env_flag("M9_ENABLED")
    assert server_val == gen_val, (
        f"M9_ENABLED={raw!r} 에 대해 server={server_val} vs generator={gen_val} — "
        "라우터와 정책 문안이 어긋난 배포가 만들어진다"
    )


def test_PM10_gen_default_is_off_without_env(monkeypatch):
    """기본값 = OFF. `M9_ENABLED` 없이 만든 GenConfig 는 로그인 전 문안을 낸다.

    프로덕션 `server/.env` 에 키가 없으므로 재빌드해도 문안이 조용히 바뀌지 않는다."""
    monkeypatch.delenv("M9_ENABLED", raising=False)
    assert GenConfig().m9_enabled is False
