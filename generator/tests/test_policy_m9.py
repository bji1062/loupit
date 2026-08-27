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

import os
import subprocess
import sys
from pathlib import Path

import pytest

from generator.config import GenConfig
from generator.content.policy import build_policy_docs, required_items

# generator/tests/test_policy_m9.py → parents[2] = 리포 루트(하위 프로세스 cwd 용, PM-10)
ROOT = Path(__file__).resolve().parents[2]

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
    # SC15 커뮤니티(2026-08-27)도 M9 게이트 안이다 — OFF 배포가 없는 게시판을 고지하면 안 된다.
    assert "P10" not in _ids(_doc(PRE_M9, "privacy"))
    assert "T6" not in _ids(_doc(PRE_M9, "terms"))


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
        # P8·P9 는 2026-07-29 신설 — 회원 제도와 **함께** 발생하는 고지 의무다(위탁·국외이전 /
        # 보유기간·권리·보호책임자). 이 정확일치 계약이 "새 항목을 조용히 추가"를 막는다.
        # P10·T6 은 2026-08-27 SC15 커뮤니티 — 게시물 정보·게시물 책임/임시조치. 같은 스위치(SP-COMM-10).
        (POST_M9, "privacy", {"P1", "P2", "P3", "P4", "P5", "P6", "P7", "P8", "P9", "P10"}),
        (POST_M9, "terms", {"T1", "T2", "T3", "T4", "T5", "T6"}),
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


def test_PM10_gen_default_is_off_without_env():
    """기본값 = OFF. `M9_ENABLED` 가 **환경에 없으면** GenConfig 는 로그인 전 문안을 낸다.

    ⚠ **`monkeypatch.delenv` 로는 검증할 수 없다**(2026-07-29 릴리스가 이걸로 깨졌다).
    `GenConfig` 의 필드 기본값은 `os.environ.get(...)` 을 **모듈 임포트 시점에** 평가해
    클래스에 박아 넣는다 — 테스트가 나중에 환경변수를 지워도 이미 늦다. 구 판본은
    "프로덕션 .env 에 키가 없으므로"라는 전제 위에서만 우연히 통과하고 있었고, M9 를 켜서
    `release.sh` 가 그 키를 export 하는 순간 거짓 실패를 냈다.

    그래서 **깨끗한 환경의 하위 프로세스**에서 새로 임포트해 확인한다. 모듈 리로드
    (`importlib.reload`)로도 되지만, 이미 임포트한 다른 테스트에 전역 부작용을 남긴다."""
    env = {k: v for k, v in os.environ.items() if k != "M9_ENABLED"}
    out = subprocess.run(
        [sys.executable, "-c",
         "from generator.config import GenConfig; print(GenConfig().m9_enabled)"],
        cwd=str(ROOT), env=env, capture_output=True, text=True,
    )
    assert out.returncode == 0, f"하위 프로세스 실패: {out.stderr}"
    assert out.stdout.strip() == "False", (
        f"M9_ENABLED 부재인데 생성기 기본이 OFF 가 아니다: {out.stdout.strip()!r}"
    )


def test_PM10b_gen_follows_env_when_present():
    """반대 방향 — 환경에 `M9_ENABLED=1` 이 있으면 임포트 시점에 ON 으로 바인딩된다.

    PM-10 과 짝이다: 둘 다 있어야 "환경이 문안을 지배한다"가 양방향으로 고정된다."""
    env = {**os.environ, "M9_ENABLED": "1"}
    out = subprocess.run(
        [sys.executable, "-c",
         "from generator.config import GenConfig; print(GenConfig().m9_enabled)"],
        cwd=str(ROOT), env=env, capture_output=True, text=True,
    )
    assert out.returncode == 0, f"하위 프로세스 실패: {out.stderr}"
    assert out.stdout.strip() == "True"


# ══════════════════════════════════════════════════════════════════════════════
# P8·P9 — 회원 제도가 생기면서 **새로 발생하는** 고지 의무 (2026-07-29 신설)
#
# P7·T5 는 "회원 제도가 있다"는 사실을 고지해 **허위 기재**를 해소한다. 그러나 그것만으로는
# 처리방침이 완성되지 않는다 — 회원 제도가 생기는 순간 아래가 함께 발생한다:
#   · 로그인 코드를 **Resend(국외)** 로 보내므로 **처리위탁·국외이전**이 실재한다(§26·§28-8)
#   · 코드 5분·세션 30일·재직인증 365일 등 **보유기간**이 실재한다(§30①3)
#   · 열람·정정·삭제·처리정지를 요구할 **정보주체**가 실재한다(§30①5·§35~37)
#   · **개인정보 보호책임자** 지정·공개 의무가 발생한다(§31②·§30①6)
# 익명 배포에는 이 중 어느 것도 해당하지 않으므로, P7·T5 와 **같은 스위치**로 함께 켜야 한다.
#
# ⚠ 이 테스트들은 문안의 *법적 충분성*을 판정하지 않는다(그건 사람이 할 일이다). 판정하는 것은
#   **"코드가 실제로 하는 일이 문안에 나타나는가"** 하나다 — 값이 바뀌면(예: 세션 TTL) 문안도
#   같이 바뀌게 강제하는 것이 목적이다.
# ══════════════════════════════════════════════════════════════════════════════

def test_PM12_p8_discloses_consignment_and_cross_border():
    """P8: 메일 발송 위탁(Resend)과 국외이전을 고지한다.

    구 문안의 제3자 절(P4)은 **Google 광고 쿠키만** 다뤄서 메일 발송 위탁을 덮지 못했다.
    로그인 코드는 우리 서버가 아니라 외부 사업자를 통해 나가므로 별도 항목이 필요하다."""
    text = _text(_doc(POST_M9, "privacy"))
    assert "Resend" in text, "수탁자명이 없다 — 누구에게 위탁하는지 알 수 없다"
    for token in ("위탁", "국외"):
        assert token in text, f"P8 에 '{token}' 고지가 없다"
    # 무엇이 넘어가는지·왜 넘어가는지·거부하면 어떻게 되는지가 함께 있어야 고지가 성립한다.
    assert "이메일 주소" in text
    assert "미국" in text, "이전 국가 미기재"


def test_PM13_p9_discloses_retention_rights_and_officer():
    """P9: 보유기간·정보주체 권리·보호책임자.

    보유기간은 **코드의 실제 설정값**과 일치해야 한다 — 아래 PM-14 가 그 결합을 강제한다."""
    text = _text(_doc(POST_M9, "privacy"))
    for token in ("보유", "파기"):
        assert token in text, f"P9 에 '{token}' 고지가 없다"
    for right in ("열람", "정정", "삭제", "처리정지"):
        assert right in text, f"정보주체 권리 '{right}' 안내가 없다"
    assert "개인정보 보호책임자" in text, "보호책임자 지정·공개(§31②) 표기가 없다"


def test_PM14_retention_periods_match_server_config():
    """**문안의 보유기간이 서버 설정값과 일치**한다 — 드리프트 방지의 핵심 가드.

    처리방침이 "세션 30일"이라고 적었는데 코드가 90일로 바뀌면 그 순간 허위 기재가 된다.
    사람이 두 파일을 대조하는 규율에 맡기지 않고 테스트가 강제한다."""
    from server.config import Settings

    s = Settings(_env_file=None)
    text = _text(_doc(POST_M9, "privacy"))
    assert f"{s.login_code_ttl_min}분" in text, f"인증 코드 보유기간({s.login_code_ttl_min}분) 불일치"
    assert f"{s.session_ttl_days}일" in text, f"세션 보유기간({s.session_ttl_days}일) 불일치"
    assert f"{s.employ_vrf_ttl_days}일" in text, f"재직 인증 보유기간({s.employ_vrf_ttl_days}일) 불일치"


def test_PM15_p8_p9_absent_when_m9_off():
    """OFF 배포에는 P8·P9 가 **없어야** 한다 — 위탁도 회원도 없는데 고지하면 그것도 거짓이다."""
    ids = {s.req_id for s in _doc(PRE_M9, "privacy").sections}
    assert "P8" not in ids and "P9" not in ids
    text = _text(_doc(PRE_M9, "privacy"))
    assert "Resend" not in text and "개인정보 보호책임자" not in text


def test_PM16_p8_p9_are_required_items_only_when_m9_on():
    """필수 항목 계약(PC-2)에 P8·P9 가 M9 조건부로 편입됐는가."""
    assert required_items(POST_M9)["privacy"] >= {"P7", "P8", "P9"}
    assert required_items(PRE_M9)["privacy"].isdisjoint({"P7", "P8", "P9"})


def test_PM17_contact_is_config_driven_not_hardcoded():
    """연락처는 `policy_contact` 단일 설정값에서 온다 — 전용 주소로 바꿀 때 코드 수정 0.

    ⚠ 도메인 전용 주소(contact@jobcho.wiki)를 쓰려면 **먼저 그 주소가 메일을 받을 수 있어야**
    한다(2026-07-29 현재 jobcho.wiki 에는 MX 가 없어 반송된다). 도달 불가능한 연락처를 처리방침에
    싣는 것은 권리 행사 경로를 막는 것이라 없는 것보다 나쁘다."""
    custom = GenConfig(m9_enabled=True, policy_contact="privacy@example.test")
    assert "privacy@example.test" in _text(_doc(custom, "privacy"))


# ── SC15 커뮤니티 게시물 고지 (2026-08-27, SP-COMM-10 · FR-133) ──────────────────────
# 게시판을 열면서 문안을 안 바꾸면 처리방침이 즉시 허위가 된다(함정 (61) 계열): 글·댓글·신고 사유는
# 새로 처리하는 항목이고, 임시조치는 정보통신망법 §44-2 의 운영자 의무다.


def test_PM16_on_p10_discloses_post_processing_and_deletion():
    """ON: P10 이 게시물 항목·공개 범위·조회수 미수집·삭제·탈퇴 후 존치(+요청 삭제)·신고 보관을 말한다."""
    p10 = next(s for s in _doc(POST_M9, "privacy").sections if s.req_id == "P10")
    body = " ".join(p10.paragraphs)
    for must in ("글·댓글", "닉네임", "신고 사유", "조회수", "삭제", "탈퇴", "숨김"):
        assert must in body, f"P10 에 '{must}' 고지가 없다"
    assert p10.cross_route == "/terms"


def test_PM17_on_t6_states_liability_and_takedown():
    """ON: T6 이 작성자 책임·금지행위·공지=운영자·신고·임시조치(§44-2)·이용허락을 말하고 /privacy 로 위임."""
    t6 = next(s for s in _doc(POST_M9, "terms").sections if s.req_id == "T6")
    body = " ".join(t6.paragraphs)
    for must in ("책임", "명예", "개인정보", "공지", "신고", "44조의2", "임시조치", "허락"):
        assert must in body, f"T6 에 '{must}' 가 없다"
    assert t6.cross_route == "/privacy"


def test_PM18_on_t2_mentions_community_login_but_still_no_feed():
    """ON: T2 가 커뮤니티 쓰기=로그인을 말하되 소셜 피드(팔로우·타임라인) 부재는 유지한다(SC10 정의 확정)."""
    t2 = next(s for s in _doc(POST_M9, "terms").sections if s.req_id == "T2")
    body = " ".join(t2.paragraphs)
    assert "커뮤니티" in body and "소셜 피드" in body
