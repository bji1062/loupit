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
        elif sql.strip().startswith("SELECT") and "FROM TCOMPANY_BENEFIT WHERE BENEFIT_ID" in sql:  # delete-benefit 조회
            for b in self.store.get("benefits", []):
                if b["BENEFIT_ID"] == params[0]:
                    self._result = [dict(b)]
        elif "INSERT INTO TBENEFIT_EDIT_LOG" in sql:  # (bid, comp, before_json, note)
            self.store.setdefault("edit_logs", []).append(
                {"BENEFIT_ID": params[0], "COMP_ID": params[1], "ACTOR_MBR_ID": None,
                 "EDIT_TYPE_CD": "delete", "BEFORE_VAL": params[2], "AFTER_VAL": None, "EDIT_NOTE_CTNT": params[3]})
            self.rowcount = 1
        elif "DELETE FROM TCOMPANY_BENEFIT WHERE BENEFIT_ID" in sql:  # 하드 삭제 → 이력 BENEFIT_ID SET NULL
            bid = params[0]
            self.store["benefits"] = [b for b in self.store.get("benefits", []) if b["BENEFIT_ID"] != bid]
            for l in self.store.get("edit_logs", []):
                if l["BENEFIT_ID"] == bid:
                    l["BENEFIT_ID"] = None  # ON DELETE SET NULL 시뮬레이션(이력 존치)
            self.rowcount = 1
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


def test_AO2_delete_benefit_records_delete_log_and_preserves_it():
    """AO-2: 복지 하드 삭제 + delete 이력 기록. BENEFIT_ID ON DELETE SET NULL 이라 이력 존치(CASCADE 아님)."""
    import json

    store = {"requests": [], "verifications": [], "edit_logs": [],
             "benefits": [{"BENEFIT_ID": 3, "COMP_ID": 10, "BENEFIT_CD": "meal", "BENEFIT_NM": "식대",
                           "BENEFIT_CTGR_CD": "compensation", "BENEFIT_AMT": 220, "QUAL_YN": 0,
                           "NOTE_CTNT": None, "BADGE_CD": "verified", "AMT_SOURCE_CD": "estimated"}]}
    conn = _FakeConn(store)
    assert ops.cmd_delete_benefit(conn, _args(benefit_id=3, note="반달 정정")) == 0
    assert store["benefits"] == []                                # 복지 하드 삭제
    assert len(store["edit_logs"]) == 1                           # delete 이력 기록
    log = store["edit_logs"][0]
    assert log["EDIT_TYPE_CD"] == "delete" and log["AFTER_VAL"] is None
    assert log["BENEFIT_ID"] is None and log["COMP_ID"] == 10     # SET NULL 로 존치(COMP_ID로 조회 가능)
    before = json.loads(log["BEFORE_VAL"])
    assert before["benefit_cd"] == "meal" and before["benefit_nm"] == "식대"  # before 스냅샷
    assert log["EDIT_NOTE_CTNT"] == "반달 정정"
    assert conn.commits == 1


def test_AO2_delete_benefit_missing_is_noop():
    store = {"requests": [], "verifications": [], "edit_logs": [], "benefits": []}
    conn = _FakeConn(store)
    assert ops.cmd_delete_benefit(conn, _args(benefit_id=999, note=None)) == 1
    assert store["edit_logs"] == []                               # 미존재 → 이력·삭제 없음


def test_AO3_no_user_facing_benefit_delete_route():
    """AO-3: 복지 삭제는 CLI 전용 — 사용자 대면 benefit DELETE 라우트 부재(계정 탈퇴 DELETE만)."""
    from fastapi.routing import APIRoute

    from server.main import create_app

    app = create_app()
    deletes = {(r.path, m) for r in app.routes if isinstance(r, APIRoute) for m in r.methods if m == "DELETE"}
    # SC15(2026-08-27): 커뮤니티 글·댓글 DELETE 는 **본인 소프트 삭제**(STATUS_CD=deleted, 마스킹)이며
    # 하드 삭제가 아니다(FR-126·128). 복지 DELETE 는 여전히 없다 — 아래 어서션이 그 계약을 지킨다.
    assert deletes == {
        ("/api/v1/members/me", "DELETE"),
        ("/api/v1/posts/{post_id}", "DELETE"),
        ("/api/v1/posts/{post_id}/comments/{comment_id}", "DELETE"),
    }
    assert not any("benefit" in p.lower() for p, _ in deletes)


def test_AO_parser_dispatch():
    p = ops.build_parser()
    a = p.parse_args(["approve", "5", "--by", "9", "--note", "ok"])
    assert a.func is ops.cmd_approve and a.req_id == 5 and a.by == 9 and a.note == "ok"
    b = p.parse_args(["revoke-verification", "1", "10"])
    assert b.func is ops.cmd_revoke_verification and b.mbr_id == 1 and b.comp_id == 10
    d = p.parse_args(["delete-benefit", "3", "--note", "반달"])
    assert d.func is ops.cmd_delete_benefit and d.benefit_id == 3 and d.note == "반달"
    with pytest.raises(SystemExit):  # 서브명령 필수
        p.parse_args([])


# ── SP-AUTH-16: 메일 발송 억제 운영 명령 ──────────────────────────────────────
class _SuppCursor(_FakeCursor):
    """억제 테이블 전용 스텁 — UPDATE 조건(해시·미해제)만 재현한다."""

    def execute(self, sql, params=()):
        self._result, self.rowcount = [], 0
        if "SET NAMES" in sql:
            return
        if "FROM TMAIL_SUPPRESSION" in sql:
            rows = self.store["suppressions"]
            if "RELEASED_DTM IS NULL" in sql:
                rows = [r for r in rows if r["RELEASED_DTM"] is None]
            self._result = [dict(r) for r in rows]
        elif "UPDATE TMAIL_SUPPRESSION" in sql:
            mod_id, target_hash = params
            for r in self.store["suppressions"]:
                if r["TARGET_HASH_VAL"] == target_hash and r["RELEASED_DTM"] is None:
                    r["RELEASED_DTM"], r["MOD_ID"] = "2026-07-29 00:00:00", mod_id
                    self.rowcount += 1

    def fetchall(self):
        # 실제 pymysql 과 동일: DictCursor 를 요구하지 않았으면 **튜플**을 준다.
        if getattr(self, "_as_dict", False):
            return self._result
        return [tuple(r.values()) for r in self._result]


class _SuppConn(_FakeConn):
    """⚠ **커서 종류를 실제 pymysql 처럼 모사한다**(2026-07-29 프로덕션에서 실결함으로 배움).

    구 스텁은 인자를 무시하고 **항상 dict 행**을 돌려줬다. 그래서 `conn.cursor()`(기본 커서)로
    조회하고 `r["RELEASED_DTM"]` 로 읽는 코드가 **테스트에서는 통과**했는데, 실제로는 기본
    커서가 **튜플**을 주므로 `TypeError: tuple indices must be integers` 로 죽었다 — 라이브에서
    `list-suppressed` 를 처음 돌렸을 때 그대로 터졌다(거짓 초록).

    이제 `DictCursor` 를 명시하지 않으면 튜플을 돌려준다 — 규약을 어기면 테스트가 먼저 죽는다."""

    def cursor(self, cursorclass=None):
        import pymysql

        cur = _SuppCursor(self.store)
        cur._as_dict = cursorclass is pymysql.cursors.DictCursor
        return cur


def _supp_store(target_hash: str, released=None):
    return {
        "suppressions": [{
            "MAIL_SUPP_ID": 1, "TARGET_HASH_VAL": target_hash, "REASON_CD": "hard_bounce",
            "SRC_SVIX_MSG_ID": "msg_1", "INS_DTM": "2026-07-29 00:00:00",
            "RELEASED_DTM": released, "MOD_ID": None,
        }]
    }


def test_AO4_release_suppression_reverses_lockout():
    """**억제 해제는 기능의 필수 짝이다** — 없으면 오탐·위조 바운스 한 건이 영구 잠금이 된다.

    행을 지우지 않고 RELEASED_DTM 을 채워 "언제 누가 풀었는가"를 남긴다(반복 오탐 추적)."""
    from server.services.auth_code import _hash_target

    email = "user@example.com"
    store = _supp_store(_hash_target(email))
    conn = _SuppConn(store)
    args = argparse.Namespace(email=email, by=7)

    assert ops.cmd_release_suppression(conn, args) == 0
    row = store["suppressions"][0]
    assert row["RELEASED_DTM"] is not None, "해제되지 않았다"
    assert row["MOD_ID"] == 7, "해제 운영자가 감사에 안 남았다"


def test_AO4b_release_matches_by_delivery_address_hash():
    """`+태그`·도트 변형으로 신고해도 같은 수신함이면 해제된다(억제 등록과 같은 키)."""
    from server.services.auth_code import _hash_target

    store = _supp_store(_hash_target("ab@gmail.com"))
    conn = _SuppConn(store)
    ops.cmd_release_suppression(conn, argparse.Namespace(email="a.b+tag@gmail.com", by=None))
    assert store["suppressions"][0]["RELEASED_DTM"] is not None


def test_AO4c_release_never_prints_plaintext_address(capsys):
    """출력에 원문 주소가 없어야 한다 — 터미널·운영 로그에 남는다(NFR31 과 같은 이유)."""
    from server.services.auth_code import _hash_target

    email = "secret.person@corp.example.com"
    conn = _SuppConn(_supp_store(_hash_target(email)))
    ops.cmd_release_suppression(conn, argparse.Namespace(email=email, by=None))
    out = capsys.readouterr().out
    assert email not in out and "corp.example.com" not in out


def test_AO4d_release_of_unsuppressed_is_noop_and_reports():
    """억제 중이 아니면 0건 — 조용히 성공한 척하지 않고 그 사실을 알린다."""
    from server.services.auth_code import _hash_target

    store = _supp_store(_hash_target("other@example.com"), released="2026-07-01 00:00:00")
    conn = _SuppConn(store)
    assert ops.cmd_release_suppression(conn, argparse.Namespace(email="other@example.com", by=None)) == 0


def test_AO4e_list_suppressed_runs(capsys):
    from server.services.auth_code import _hash_target

    conn = _SuppConn(_supp_store(_hash_target("x@example.com")))
    ops.cmd_list_suppressed(conn, argparse.Namespace(all=False, limit=50))
    assert "hard_bounce" in capsys.readouterr().out


def test_AO4f_parser_dispatch_for_suppression():
    p = ops.build_parser()
    a = p.parse_args(["release-suppression", "a@b.com", "--by", "3"])
    assert a.func is ops.cmd_release_suppression and a.email == "a@b.com" and a.by == 3
    b = p.parse_args(["list-suppressed", "--all"])
    assert b.func is ops.cmd_list_suppressed and b.all is True
