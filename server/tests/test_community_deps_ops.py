"""SC15 — `deps.optional_member`(T-14.2.4) · `ops digest` 신고 대기 건수(T-14.5.3) · 설정(T-14.2.3).

무DB. `optional_member` 는 익명 열람 경로에서 세션을 **선택적으로** 읽는 별개 심볼이다 —
`require_member` 와 달리 어떤 경우에도 401 을 내지 않는다(SP-COMM-4). 요약 메일은 건수·ID 만
싣는다는 기존 판단(test_ops_digest OD-4)을 신고 큐에도 그대로 적용한다.
"""
from __future__ import annotations

import pytest

from server import deps, ops
from server.services import session as session_svc
from server.tests.test_ops_digest import _FakeConn


# ── optional_member ─────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_OM1_no_cookie_is_none_not_401():
    assert await deps.optional_member(loupit_sid=None) is None
    assert await deps.optional_member(loupit_sid="") is None


@pytest.mark.asyncio
async def test_OM2_invalid_session_is_none_not_401(monkeypatch):
    async def _resolve(raw):
        return None
    monkeypatch.setattr(session_svc, "resolve_session", _resolve)
    assert await deps.optional_member(loupit_sid="forged-or-expired") is None


@pytest.mark.asyncio
async def test_OM3_valid_session_returns_member(monkeypatch):
    async def _resolve(raw):
        return {"MBR_ID": 7} if raw == "good" else None
    monkeypatch.setattr(session_svc, "resolve_session", _resolve)
    assert await deps.optional_member(loupit_sid="good") == {"MBR_ID": 7}


def test_OM4_optional_is_a_distinct_symbol_from_require():
    """AU-2 계약은 `require_member` 의 **부재**로 잰다 — optional 이 그 이름을 감싸거나 재사용하면 안 된다."""
    assert deps.optional_member is not deps.require_member
    assert deps.optional_member.__name__ == "optional_member"


# ── 설정(SP-COMM-2) ─────────────────────────────────────────────────────────

def test_CFG1_community_limits_defaults():
    from server.config import Settings

    s = Settings(_env_file=None)
    assert (s.daily_post_limit, s.daily_comment_limit, s.daily_report_limit) == (10, 50, 20)
    assert s.post_list_max_limit == 50
    for name in ("daily_post_limit", "daily_comment_limit", "daily_report_limit", "post_list_max_limit"):
        for bad in ("jwt", "oauth", "password_reset", "social"):  # T10 금지 substring
            assert bad not in name


# ── ops digest ──────────────────────────────────────────────────────────────

def test_OD_R1_digest_counts_pending_reports():
    conn = _FakeConn({"pending": [], "company": [], "suppressed": [], "reports": [4, 9]})
    d = ops.collect_digest(conn)
    assert d["reports"] == [4, 9]
    subject = ops.digest_subject(d)
    assert "2건" in subject and ops.DIGEST_MARK in subject
    body = ops.digest_body(d)
    assert "신고" in body and "#4" in body and "#9" in body
    assert "list-reports" in body, "다음에 칠 명령을 알려줘야 한다 — 그리고 그 명령이 실제로 있어야 한다"
    assert "@" not in body and "://" not in body


def test_OD_R2_reports_query_reads_only_pending_ids():
    """수집 SQL 은 pending 의 ID 만 읽는다 — 내용(제목·상세)은 메일에 실릴 수가 없다(OD-4 규약)."""
    sql = next(q for k, _l, _c, q in ops._DIGEST_QUERIES if k == "reports")
    assert "TPOST_REPORT" in sql and "STATUS_CD='pending'" in sql
    assert "REPORT_ID AS id" in sql
    for col in ("DETAIL_CTNT", "TITLE_NM", "BODY_CTNT", "NICKNAME_NM"):
        assert col not in sql


def test_OD_R3_list_reports_command_exists():
    """digest 본문이 안내하는 `list-reports` 가 CLI 에 실제로 있다(없는 명령을 안내하면 막다른 길이다)."""
    parser = ops.build_parser()
    sub = next(a for a in parser._actions if getattr(a, "choices", None) and "digest" in a.choices)
    assert "list-reports" in sub.choices
