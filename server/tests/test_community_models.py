"""SP-COMM-7 입력 신뢰 경계 — CM-5 422 케이스 표 (FR-132).

무DB. 모델이 거부해야 하는 것과 **통과시켜야 하는 것**을 함께 잰다 — 정직한 입력(줄바꿈·
링크 3개·100자 제목)이 거부되면 사용자가 글을 못 쓰고, 그건 스팸이 통과하는 것만큼 나쁘다.
서버는 HTML 을 만들지 않는다 — `<script>` 는 **통과**한다(이스케이프는 표시 계층, NFR21).
"""
from __future__ import annotations

import pytest

from server.models import post as m


# ── 글 작성 ────────────────────────────────────────────────────────────────

def test_CM5_M1_strip_and_control_chars_removed():
    p = m.PostCreateIn(category="free", title="  제목\x00\x1f  ", body="본문\x0b 첫 줄\n둘째 줄\t끝 ")
    assert p.title == "제목"
    assert p.body == "본문 첫 줄\n둘째 줄\t끝", "줄바꿈·탭은 남기고 나머지 제어문자만 지운다"


@pytest.mark.parametrize("title", ["", "   ", "\x00\x01"])
def test_CM5_M2_blank_title_rejected(title):
    with pytest.raises(ValueError):
        m.PostCreateIn(category="free", title=title, body="본문")


@pytest.mark.parametrize("body", ["", "  \n  "])
def test_CM5_M3_blank_body_rejected(body):
    with pytest.raises(ValueError):
        m.PostCreateIn(category="free", title="제목", body=body)


def test_CM5_M4_url_count_boundary():
    """링크 3개는 정직한 글이다 — 4개부터 스팸으로 본다(FR-132)."""
    three = " ".join(f"https://example.com/{i}" for i in range(3))
    assert m.PostCreateIn(category="free", title="t", body=three).body == three
    four = three + " HTTP://x.example"  # 대소문자 무관
    with pytest.raises(ValueError):
        m.PostCreateIn(category="free", title="t", body=four)


@pytest.mark.parametrize("cat", ["", "NOTICE", "news", "all"])
def test_CM5_M5_category_value_set(cat):
    """`all`(전체)은 카테고리가 아니라 목록 필터다(계획 D-4) — 글에 붙일 수 없다."""
    with pytest.raises(ValueError):
        m.PostCreateIn(category=cat, title="t", body="b")


@pytest.mark.parametrize("cat", sorted(m.CATEGORIES))
def test_CM5_M5b_all_four_categories_accepted(cat):
    assert m.PostCreateIn(category=cat, title="t", body="b").category == cat


def test_CM5_M6_comp_id_must_be_positive():
    with pytest.raises(ValueError):
        m.PostCreateIn(category="free", title="t", body="b", comp_id=0)
    assert m.PostCreateIn(category="free", title="t", body="b", comp_id=None).comp_id is None
    assert m.PostCreateIn(category="free", title="t", body="b", comp_id=7).comp_id == 7


def test_CM5_M7_length_after_clean():
    """100자 제목·5,000자 본문은 통과, 101·5,001 은 거부 — 경계는 strip **후** 길이다."""
    assert len(m.PostCreateIn(category="free", title="가" * 100 + "  ", body="b").title) == 100
    with pytest.raises(ValueError):
        m.PostCreateIn(category="free", title="가" * 101, body="b")
    assert len(m.PostCreateIn(category="free", title="t", body="나" * 5000).body) == 5000
    with pytest.raises(ValueError):
        m.PostCreateIn(category="free", title="t", body="나" * 5001)


def test_CM5_M8_html_passes_through_unescaped():
    """서버는 이스케이프하지 않는다 — 표시 계층(textContent)이 한다. 여기서 바꾸면 CLI·콘솔·API
    소비자마다 규칙이 갈려 결국 '어디선가는 안 했다'가 된다(test_console_flow_db CF-8 과 같은 규약)."""
    raw = "<script>alert(1)</script> & \"따옴표\""
    assert m.PostCreateIn(category="free", title=raw, body=raw).body == raw


def test_CM5_M9_update_has_no_category():
    """PUT 은 `category` 를 **받지 않는다** — 일반 글을 공지로 승격하는 경로를 모델에서 막는다."""
    assert "category" not in m.PostUpdateIn.model_fields
    p = m.PostUpdateIn(title=" 수정 ", body=" 본문 ", comp_id=3)
    assert (p.title, p.body, p.comp_id) == ("수정", "본문", 3)


# ── 댓글·신고 ──────────────────────────────────────────────────────────────

def test_CM5_M10_comment_rules():
    assert m.CommentIn(body=" 댓글\x00 ").body == "댓글"
    with pytest.raises(ValueError):
        m.CommentIn(body="   ")
    with pytest.raises(ValueError):
        m.CommentIn(body="가" * 1001)
    assert len(m.CommentIn(body="가" * 1000).body) == 1000
    with pytest.raises(ValueError):
        m.CommentIn(body=" ".join(["http://a.b"] * 4))


@pytest.mark.parametrize("kw", [
    {"target_type": "user"}, {"reason": "hate"}, {"target_id": 0}, {"detail": "x" * 301},
])
def test_CM5_M11_report_rejects(kw):
    base = {"target_type": "post", "target_id": 1, "reason": "spam", "detail": None}
    with pytest.raises(ValueError):
        m.ReportIn(**{**base, **kw})


def test_CM5_M12_report_detail_cleaned_and_optional():
    r = m.ReportIn(target_type="comment", target_id=5, reason="other", detail="  \x00  ")
    assert r.detail is None, "공백·제어문자만 있는 상세는 null 로 접는다"
    r2 = m.ReportIn(target_type="post", target_id=1, reason="privacy", detail=" 전화번호가 있다 ")
    assert r2.detail == "전화번호가 있다"


def test_CM5_M13_value_sets_match_spec():
    """SP-DB-18.5 값집합 — 이 상수가 곧 강제 지점이다(ENUM 금지)."""
    assert m.CATEGORIES == {"notice", "free", "career", "suggestion"}
    assert m.SORTS == {"latest", "comments", "likes"}
    assert m.REPORT_TARGET_TYPES == {"post", "comment"}
    assert m.REPORT_REASONS == {"spam", "abuse", "privacy", "other"}
    assert m.DECIDE_ACTIONS == {"hide", "dismiss"}
