"""운영자 큐 일일 요약 (OD-1~OD-8).

**왜 필요한가**(2026-07-29 실측): 회사 등록 요청 #1 이 약 1시간 40분 방치됐고, 운영자가
`ops list-*` 를 직접 치기 전까지 아무도 몰랐다. 알림 배선은 전무했다 — 코드에 notify 흔적 0건,
타이머는 백업 하나, 크론 없음. 사용자는 "확인 후 등록해 드릴게요" 안내를 받고 기다리는 중이었다.

## 두 가지 설계 판단을 테스트가 고정한다

**① 요약은 건수와 ID 만 담고 내용은 담지 않는다**(OD-3·OD-4). 증빙 원문에는 재직증명서 링크
같은 사용자 제출물이 들어오고, 닉네임·회사명도 사용자 입력이다. 그걸 메일에 실으면 **위탁
발송자(Resend)와 외부 수신함(Gmail)을 거치는 새 개인정보 흐름**이 생긴다. 알림의 목적은
"가서 봐야 한다"를 알리는 것이므로 건수만으로 충분하다 — 내용은 서버에서 본다.

**② 큐가 비어도 보낸다**(OD-5). 대기가 있을 때만 보내면 **침묵이 두 뜻**이 된다 — "대기 없음"과
"타이머가 죽었음"을 구분할 수 없다. 침묵을 성공으로 읽는 순간 알림은 없는 것보다 나쁘다
(있다고 믿게 만든다). 대신 **제목에 건수를 실어** 열지 않고도 판단할 수 있게 한다.
"""

from __future__ import annotations

import pytest

from server import ops


class _FakeCursor:
    """ops 의 SELECT COUNT/ID 질의에만 답하는 최소 스텁.

    ⚠ 스텁이라 실 SQL 문법은 검증하지 못한다(함정 ㉒) — 실행 확인은 실 DB 로 따로 한다.
    여기서 검증하는 것은 **요약 문안과 발송 판단**이다.
    """

    def __init__(self, counts: dict[str, list[int]]):
        self._counts = counts
        self._rows: list = []

    def execute(self, sql, params=()):
        s = " ".join(sql.split())
        if "TEMPLOY_VRF_REQUEST" in s:
            key = "pending"
        elif "TCOMPANY_REQUEST" in s:
            key = "company"
        elif "TMAIL_SUPPRESSION" in s:
            key = "suppressed"
        else:
            raise AssertionError(f"예상 못 한 질의: {s}")
        self._rows = [{"id": i} for i in self._counts[key]]

    def fetchall(self):
        return self._rows

    def __enter__(self):
        return self

    def __exit__(self, *a):
        return False


class _FakeConn:
    def __init__(self, counts):
        self._counts = counts

    def cursor(self, *a, **kw):
        return _FakeCursor(self._counts)


class _FakeMailer:
    def __init__(self):
        self.sent: list[tuple[str, str, str]] = []

    def send_notice(self, to, subject, body):
        self.sent.append((to, subject, body))


@pytest.fixture
def empty_conn():
    return _FakeConn({"pending": [], "company": [], "suppressed": []})


@pytest.fixture
def busy_conn():
    return _FakeConn({"pending": [3, 7], "company": [1], "suppressed": []})


# ── OD-1: 건수 수집 ────────────────────────────────────────────────────────
def test_OD1_collects_all_three_queues(busy_conn):
    d = ops.collect_digest(busy_conn)
    assert d["pending"] == [3, 7]
    assert d["company"] == [1]
    assert d["suppressed"] == []


# ── OD-2: 제목만 보고 판단할 수 있어야 한다 ────────────────────────────────
def test_OD2_subject_carries_counts(busy_conn, empty_conn):
    busy = ops.digest_subject(ops.collect_digest(busy_conn))
    empty = ops.digest_subject(ops.collect_digest(empty_conn))
    assert "3건" in busy, f"총 건수가 제목에 없다: {busy!r}"
    assert "jobcho.wiki" in busy, "어느 서비스인지 제목에 있어야 한다"
    assert busy != empty
    assert "0건" in empty
    # 대기가 있을 때만 눈에 띄는 마커 — 매일 오는 메일 중에서 골라내야 한다
    assert ops.DIGEST_MARK in busy and ops.DIGEST_MARK not in empty


# ── OD-3: 본문은 건수·ID·확인 방법만 ──────────────────────────────────────
def test_OD3_body_has_counts_and_next_action(busy_conn):
    body = ops.digest_body(ops.collect_digest(busy_conn))
    assert "재직 수동 승인" in body and "회사 등록 요청" in body and "발송 억제" in body
    assert "#3" in body and "#7" in body and "#1" in body, "어느 건인지 알려줘야 바로 처리한다"
    assert "list-company-requests" in body, "다음에 칠 명령을 알려줘야 한다"


# ── OD-4: 개인정보·사용자 입력은 절대 실리지 않는다 ────────────────────────
def test_OD4_body_carries_no_user_content(busy_conn):
    """증빙·닉네임·회사명·URL 을 메일에 실으면 위탁 발송자와 외부 수신함을 거치는
    **새 개인정보 흐름**이 생긴다. 알림은 "가서 봐라"만 하면 된다.

    ⚠ 초판은 본문에서 "증빙" 같은 **키워드를 금지**하는 식으로 짰는데, 그 단어가 안내 문구
    ("내용(증빙·회사명·주소)은 담지 않는다")에 정당하게 등장해 거짓 실패를 냈다. 키워드 대조는
    "무엇이 새는가"를 재지 못한다 → **자료형으로 증명**한다: 수집 단계가 정수 ID 만 반환하므로
    사용자 입력은 본문에 **실릴 수가 없다**. 그게 진짜 불변식이다.
    """
    digest = ops.collect_digest(busy_conn)
    for key, ids in digest.items():
        assert isinstance(ids, list), key
        assert all(isinstance(i, int) and not isinstance(i, bool) for i in ids), (
            f"{key} 에 정수 아닌 값이 있다 — 수집 단계가 행 내용을 읽고 있다: {ids!r}"
        )

    body = ops.digest_body(digest)
    assert "@" not in body, "이메일 주소가 새어 나갔다"
    assert "://" not in body, "사용자 제출 URL 이 새어 나갔다"
    # 컬럼명이 보이면 행을 그대로 덤프한 것이다.
    for col in ("EVIDENCE_CTNT", "NICKNAME_NM", "REQ_COMP_NM", "REF_URL_CTNT", "TARGET_HASH_VAL"):
        assert col not in body, f"행 내용을 그대로 실었다: {col}"


# ── OD-5: 큐가 비어도 보낸다(침묵 = 고장으로 읽히게) ───────────────────────
def test_OD5_sends_even_when_empty(empty_conn, monkeypatch):
    m = _FakeMailer()
    monkeypatch.setattr(ops, "get_mailer", lambda: m)
    rc = ops.cmd_digest(empty_conn, _Args(send=True, to="ops@example.com"))
    assert rc == 0
    assert len(m.sent) == 1, "빈 큐에 안 보내면 침묵이 '대기 없음'과 '타이머 고장'을 못 가른다"


def test_OD5b_only_if_pending_suppresses_empty(empty_conn, busy_conn, monkeypatch):
    """조용히 쓰고 싶으면 명시적으로 골라야 한다 — 기본값이 아니다(하트비트를 잃으므로)."""
    m = _FakeMailer()
    monkeypatch.setattr(ops, "get_mailer", lambda: m)
    ops.cmd_digest(empty_conn, _Args(send=True, to="ops@example.com", only_if_pending=True))
    assert m.sent == []
    ops.cmd_digest(busy_conn, _Args(send=True, to="ops@example.com", only_if_pending=True))
    assert len(m.sent) == 1


# ── OD-6: 수신 주소 미설정은 조용히 넘어가지 않는다 ────────────────────────
def test_OD6_missing_recipient_fails_loudly(busy_conn, monkeypatch, capsys):
    m = _FakeMailer()
    monkeypatch.setattr(ops, "get_mailer", lambda: m)
    rc = ops.cmd_digest(busy_conn, _Args(send=True, to=""))
    assert rc != 0, "수신 주소가 없는데 성공으로 보고하면 '알림이 있다'고 믿게 된다"
    assert m.sent == []
    assert "OPS_DIGEST_TO" in capsys.readouterr().out


# ── OD-7: 기본은 발송 없음(사고 방지) ─────────────────────────────────────
def test_OD7_dry_run_by_default(busy_conn, monkeypatch, capsys):
    m = _FakeMailer()
    monkeypatch.setattr(ops, "get_mailer", lambda: m)
    rc = ops.cmd_digest(busy_conn, _Args(send=False, to="ops@example.com"))
    assert rc == 0
    assert m.sent == [], "--send 없이 발송하면 사람이 시험할 때마다 메일이 나간다"
    assert "회사 등록 요청" in capsys.readouterr().out


# ── OD-8: 발송 실패는 비0 종료(타이머가 실패로 표시하게) ───────────────────
def test_OD8_send_failure_is_reported(busy_conn, monkeypatch, capsys):
    class _Boom:
        def send_notice(self, *a):
            raise OSError("smtp down")

    monkeypatch.setattr(ops, "get_mailer", lambda: _Boom())
    rc = ops.cmd_digest(busy_conn, _Args(send=True, to="ops@example.com"))
    assert rc != 0, "조용한 발송 실패는 알림이 없는 것보다 나쁘다(있다고 믿게 만든다)"
    assert "실패" in capsys.readouterr().out


class _Args:
    def __init__(self, send=False, to="", only_if_pending=False):
        self.send = send
        self.to = to
        self.only_if_pending = only_if_pending
