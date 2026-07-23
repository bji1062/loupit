"""SP-AUTH-8 운영자 CLI — 승인·거부·인증취소·대기조회 (AO-*, T-13.9.2).

무 DB — pymysql 커넥션을 인메모리 스텁으로 대체해 명령 함수 로직·감사 기록·상태전이를 검증한다.
AO-3(사용자 대면 benefit DELETE 라우트 부재)은 앱 표면으로 확인.
"""
from __future__ import annotations

import argparse

import pytest

from server import ops


class _FakeCursor:
    def __init__(self, store):
        self.store = store
        self.rowcount = 0
        self._result = []

    def __enter__(self):
        return self

    def __exit__(self, *a):
        return False

    def execute(self, sql, params=()):
        self._result, self.rowcount = [], 0
        if "SET NAMES" in sql:
            return
        if "FROM TEMPLOY_VRF_REQUEST r" in sql:  # list-pending
            self._result = [dict(r) for r in self.store["requests"] if r["STATUS_CD"] == "pending"]
        elif "SELECT MBR_ID, COMP_ID FROM TEMPLOY_VRF_REQUEST" in sql:  # approve fetch(pending)
            for r in self.store["requests"]:
                if r["VRF_REQUEST_ID"] == params[0] and r["STATUS_CD"] == "pending":
                    self._result = [{"MBR_ID": r["MBR_ID"], "COMP_ID": r["COMP_ID"]}]
        elif "SELECT 1 FROM TEMPLOY_VERIFICATION" in sql:  # 활성 인증 존재?
            mbr, comp = params[0], params[1]
            if any(v["MBR_ID"] == mbr and v["COMP_ID"] == comp and not v["revoked"] for v in self.store["verifications"]):
                self._result = [{"1": 1}]
        elif "INSERT INTO TEMPLOY_VERIFICATION" in sql:  # (mbr, comp, hash, ttl, by)
            self.store["verifications"].append({"MBR_ID": params[0], "COMP_ID": params[1],
                                                "VRF_METHOD_CD": "manual", "COMP_EMAIL_HASH_VAL": params[2], "revoked": False})
            self.rowcount = 1
        elif "SET STATUS_CD='approved'" in sql:  # (by, note, rid)
            for r in self.store["requests"]:
                if r["VRF_REQUEST_ID"] == params[2]:
                    r.update(STATUS_CD="approved", DECIDED_BY_ID=params[0], DECIDE_NOTE_CTNT=params[1])
                    self.rowcount = 1
        elif "SET STATUS_CD='rejected'" in sql:  # (by, note, rid) WHERE pending
            for r in self.store["requests"]:
                if r["VRF_REQUEST_ID"] == params[2] and r["STATUS_CD"] == "pending":
                    r.update(STATUS_CD="rejected", DECIDED_BY_ID=params[0], DECIDE_NOTE_CTNT=params[1])
                    self.rowcount = 1
        elif "SET REVOKED_DTM" in sql:  # (by, mbr, comp) WHERE not revoked
            mbr, comp = params[1], params[2]
            for v in self.store["verifications"]:
                if v["MBR_ID"] == mbr and v["COMP_ID"] == comp and not v["revoked"]:
                    v["revoked"] = True
                    self.rowcount += 1
        else:
            raise AssertionError(f"ops fake: unmatched SQL: {sql!r}")

    def fetchone(self):
        return self._result[0] if self._result else None

    def fetchall(self):
        return list(self._result)


class _FakeConn:
    def __init__(self, store):
        self.store = store
        self.commits = 0

    def cursor(self, cursorclass=None):
        return _FakeCursor(self.store)

    def commit(self):
        self.commits += 1

    def close(self):
        pass


def _args(**kw):
    return argparse.Namespace(**kw)


def _pending_req(**kw):
    base = {"VRF_REQUEST_ID": 5, "MBR_ID": 1, "COMP_ID": 10, "STATUS_CD": "pending",
            "EVIDENCE_CTNT": "명함 사진 링크", "NICKNAME_NM": "직장인-000001", "COMP_NM": "삼성전자",
            "INS_DTM": "2026-07-23 00:00:00", "DECIDED_BY_ID": None, "DECIDE_NOTE_CTNT": None}
    base.update(kw)
    return base


def test_AO1_approve_creates_manual_verification_and_audits():
    store = {"requests": [_pending_req()], "verifications": []}
    conn = _FakeConn(store)
    assert ops.cmd_approve(conn, _args(req_id=5, by=99, note="증빙 확인")) == 0
    assert len(store["verifications"]) == 1
    v = store["verifications"][0]
    assert v["MBR_ID"] == 1 and v["COMP_ID"] == 10 and v["VRF_METHOD_CD"] == "manual"
    assert len(v["COMP_EMAIL_HASH_VAL"]) == 64  # 대체 해시(회사 이메일 원문 없음)
    r = store["requests"][0]
    assert r["STATUS_CD"] == "approved" and r["DECIDED_BY_ID"] == 99 and r["DECIDE_NOTE_CTNT"] == "증빙 확인"
    assert conn.commits == 1


def test_AO_approve_nonpending_is_noop():
    store = {"requests": [_pending_req(STATUS_CD="approved")], "verifications": []}
    conn = _FakeConn(store)
    assert ops.cmd_approve(conn, _args(req_id=5, by=1, note=None)) == 1
    assert store["verifications"] == []


def test_AO_approve_already_verified_skips_insert():
    store = {"requests": [_pending_req()],
             "verifications": [{"MBR_ID": 1, "COMP_ID": 10, "VRF_METHOD_CD": "domain",
                                "COMP_EMAIL_HASH_VAL": "x" * 64, "revoked": False}]}
    conn = _FakeConn(store)
    assert ops.cmd_approve(conn, _args(req_id=5, by=1, note=None)) == 0
    assert len(store["verifications"]) == 1                 # 중복 인증 생성 안 함
    assert store["requests"][0]["STATUS_CD"] == "approved"  # 요청은 처리


def test_AO_reject_records_reason():
    store = {"requests": [_pending_req()], "verifications": []}
    conn = _FakeConn(store)
    assert ops.cmd_reject(conn, _args(req_id=5, by=2, note="증빙 불충분")) == 0
    assert store["requests"][0]["STATUS_CD"] == "rejected"
    assert store["requests"][0]["DECIDE_NOTE_CTNT"] == "증빙 불충분"


def test_AO_revoke_verification():
    store = {"requests": [], "verifications": [{"MBR_ID": 1, "COMP_ID": 10, "revoked": False}]}
    conn = _FakeConn(store)
    assert ops.cmd_revoke_verification(conn, _args(mbr_id=1, comp_id=10, by=3)) == 0
    assert store["verifications"][0]["revoked"] is True


def test_AO_list_pending_runs(capsys):
    store = {"requests": [_pending_req()], "verifications": []}
    conn = _FakeConn(store)
    assert ops.cmd_list_pending(conn, _args()) == 0
    out = capsys.readouterr().out
    assert "삼성전자" in out and "#5" in out


def test_AO3_no_user_facing_benefit_delete_route():
    """AO-3: 복지 삭제는 CLI 전용 — 사용자 대면 benefit DELETE 라우트 부재(계정 탈퇴 DELETE만)."""
    from fastapi.routing import APIRoute

    from server.main import create_app

    app = create_app()
    deletes = [(r.path, m) for r in app.routes if isinstance(r, APIRoute) for m in r.methods if m == "DELETE"]
    assert deletes == [("/api/v1/members/me", "DELETE")]
    assert not any("benefit" in p.lower() for p, _ in deletes)


def test_AO_parser_dispatch():
    p = ops.build_parser()
    a = p.parse_args(["approve", "5", "--by", "9", "--note", "ok"])
    assert a.func is ops.cmd_approve and a.req_id == 5 and a.by == 9 and a.note == "ok"
    b = p.parse_args(["revoke-verification", "1", "10"])
    assert b.func is ops.cmd_revoke_verification and b.mbr_id == 1 and b.comp_id == 10
    with pytest.raises(SystemExit):  # 서브명령 필수
        p.parse_args([])
