"""SP-AUTH-8 / FR-115 운영자 CLI — 수동 재직 승인·인증 취소 (`python -m server.ops`).

런타임 API와 분리된 **동기 프로세스**(pymysql). 웹 관리자 페이지는 두지 않는다 — 서버 셸
접근 권한을 가진 운영자(A5)만 이 CLI로 처리한다(공격면·관리자 인증 시스템 회피). 승인·거부·
취소는 감사 흔적(`DECIDED_BY_ID`·`DECIDED_DTM`)을 남긴다. 사용자 대면 DELETE 라우트는 없다.

명령:
  list-pending                         수동 승인 대기 큐 조회
  approve <req_id> [--by N] [--note S] 승인 → manual 재직 인증 생성(+employ_vrf_ttl_days)
  reject  <req_id> [--by N] [--note S] 거부(사유 기록)
  revoke-verification <mbr_id> <comp_id> [--by N]  재직 인증 폐기(REVOKED_DTM)
  delete-benefit <benefit_id> [--note S]  복지 하드 삭제 + delete 편집 이력(반달리즘 정정)

`delete-benefit` 은 delete 이력을 **먼저** 기록한 뒤 복지를 삭제한다 —
`TBENEFIT_EDIT_LOG.BENEFIT_ID ON DELETE SET NULL`(구 CASCADE 에서 변경, DG)로 이력의 BENEFIT_ID 만
NULL 이 되고 이력(before 스냅샷·COMP_ID)은 공개 편집 이력에 존치된다. 사용자 대면 DELETE 라우트는 없다.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sys

import pymysql
from dotenv import load_dotenv

from server.config import get_settings


def _connect() -> pymysql.connections.Connection:
    """server/.env 기반 동기 커넥션(autocommit=False — 승인은 인증+요청 UPDATE 원자 커밋)."""
    from pathlib import Path

    load_dotenv(Path(__file__).resolve().parent / ".env")
    s = get_settings()
    conn = pymysql.connect(
        host=s.db_host, port=s.db_port, user=s.db_user, password=s.db_password,
        database=s.db_name, charset="utf8mb4", autocommit=False,
    )
    with conn.cursor() as cur:
        cur.execute("SET NAMES utf8mb4")
    return conn


def _manual_hash(mbr_id: int, comp_id: int, req_id: int) -> str:
    """수동 인증용 COMP_EMAIL_HASH_VAL 대체값 — NOT NULL UNIQUE 충족·도메인 HMAC과 비충돌(원문 없음)."""
    return hashlib.sha256(f"manual:{mbr_id}:{comp_id}:{req_id}".encode()).hexdigest()


def cmd_list_pending(conn, args) -> int:
    """수동 승인 대기 큐(STATUS=pending) 조회. 터미널 출력이라 표시 이스케이프 불요."""
    with conn.cursor(pymysql.cursors.DictCursor) as cur:
        cur.execute(
            "SELECT r.VRF_REQUEST_ID, r.MBR_ID, m.NICKNAME_NM, r.COMP_ID, c.COMP_NM, "
            "       r.EVIDENCE_CTNT, r.INS_DTM "
            "FROM TEMPLOY_VRF_REQUEST r "
            "JOIN TMEMBER m ON m.MBR_ID = r.MBR_ID "
            "JOIN TCOMPANY c ON c.COMP_ID = r.COMP_ID "
            "WHERE r.STATUS_CD='pending' ORDER BY r.INS_DTM"
        )
        rows = cur.fetchall()
    if not rows:
        print("수동 승인 대기 요청 없음.")
        return 0
    print(f"수동 승인 대기 {len(rows)}건:")
    for r in rows:
        print(f"  #{r['VRF_REQUEST_ID']}  [{r['COMP_NM']}]  {r['NICKNAME_NM']}(MBR {r['MBR_ID']})  {r['INS_DTM']}")
        print(f"      증빙: {r['EVIDENCE_CTNT']}")
    return 0


def cmd_approve(conn, args) -> int:
    """승인 → manual 재직 인증 생성 + 요청 approved(감사). 이미 활성 인증이면 인증 생성 스킵."""
    with conn.cursor(pymysql.cursors.DictCursor) as cur:
        cur.execute(
            "SELECT MBR_ID, COMP_ID FROM TEMPLOY_VRF_REQUEST WHERE VRF_REQUEST_ID=%s AND STATUS_CD='pending'",
            (args.req_id,),
        )
        req = cur.fetchone()
        if not req:
            print(f"요청 #{args.req_id}: pending 상태가 아님(미존재/이미 처리).")
            return 1
        mbr, comp = req["MBR_ID"], req["COMP_ID"]
        cur.execute(
            "SELECT 1 FROM TEMPLOY_VERIFICATION WHERE MBR_ID=%s AND COMP_ID=%s AND REVOKED_DTM IS NULL "
            "AND (EXPIRES_DTM IS NULL OR EXPIRES_DTM > UTC_TIMESTAMP())",
            (mbr, comp),
        )
        if cur.fetchone():
            print(f"요청 #{args.req_id}: 이미 활성 재직 인증 존재 — 요청만 approved 처리.")
        else:
            cur.execute(
                "INSERT INTO TEMPLOY_VERIFICATION "
                "(MBR_ID, COMP_ID, VRF_METHOD_CD, COMP_EMAIL_HASH_VAL, EXPIRES_DTM, INS_ID) "
                "VALUES (%s, %s, 'manual', %s, UTC_TIMESTAMP() + INTERVAL %s DAY, %s)",
                (mbr, comp, _manual_hash(mbr, comp, args.req_id), get_settings().employ_vrf_ttl_days, args.by),
            )
        cur.execute(
            "UPDATE TEMPLOY_VRF_REQUEST SET STATUS_CD='approved', DECIDED_BY_ID=%s, "
            "DECIDED_DTM=UTC_TIMESTAMP(), DECIDE_NOTE_CTNT=%s WHERE VRF_REQUEST_ID=%s",
            (args.by, args.note, args.req_id),
        )
    conn.commit()
    print(f"요청 #{args.req_id} 승인 완료 (MBR {mbr} → COMP {comp}, method=manual, by={args.by}).")
    return 0


def cmd_reject(conn, args) -> int:
    """거부 → 요청 rejected(사유 기록)."""
    with conn.cursor() as cur:
        cur.execute(
            "UPDATE TEMPLOY_VRF_REQUEST SET STATUS_CD='rejected', DECIDED_BY_ID=%s, "
            "DECIDED_DTM=UTC_TIMESTAMP(), DECIDE_NOTE_CTNT=%s WHERE VRF_REQUEST_ID=%s AND STATUS_CD='pending'",
            (args.by, args.note, args.req_id),
        )
        n = cur.rowcount
    conn.commit()
    print(f"요청 #{args.req_id} 거부 완료." if n else f"요청 #{args.req_id}: pending 아님(처리 안 됨).")
    return 0 if n else 1


def cmd_revoke_verification(conn, args) -> int:
    """재직 인증 폐기(REVOKED_DTM) — 오인증·퇴사 대응."""
    with conn.cursor() as cur:
        cur.execute(
            "UPDATE TEMPLOY_VERIFICATION SET REVOKED_DTM=UTC_TIMESTAMP(), MOD_ID=%s "
            "WHERE MBR_ID=%s AND COMP_ID=%s AND REVOKED_DTM IS NULL",
            (args.by, args.mbr_id, args.comp_id),
        )
        n = cur.rowcount
    conn.commit()
    print(f"재직 인증 폐기: MBR {args.mbr_id} / COMP {args.comp_id} — {n}건.")
    return 0


def cmd_list_suppressed(conn, args) -> int:
    """발송 억제 목록 조회(SP-AUTH-16).

    ⚠ **원문 주소는 어디에도 없다** — 저장된 것은 배달주소의 SHA-256 뿐이다(T9·NFR30). 그래서
    "누가 막혔는지"는 이 목록만으로 알 수 없고, 해제하려면 **사용자가 알려준 주소를 넣어**
    같은 해시를 다시 계산해야 한다(`release-suppression <이메일>`). 불편하지만 의도한 설계다:
    DB 가 유출돼도 반송된 수신함 목록이 통째로 새지 않는다.

    ⚠ `DictCursor` **필수**(cmd_list_pending 과 동일 규약). 기본 커서는 튜플을 주므로
    `r["RELEASED_DTM"]` 가 `TypeError` 로 죽는다 — 초판이 정확히 그랬고, 스텁이 항상 dict 를
    돌려주는 바람에 단위 테스트는 통과했다(거짓 초록. 지금은 스텁이 커서 종류를 모사한다)."""
    with conn.cursor(pymysql.cursors.DictCursor) as cur:
        cur.execute(
            "SELECT MAIL_SUPP_ID, TARGET_HASH_VAL, REASON_CD, SRC_SVIX_MSG_ID, INS_DTM, RELEASED_DTM "
            "FROM TMAIL_SUPPRESSION "
            + ("" if args.all else "WHERE RELEASED_DTM IS NULL ")
            + "ORDER BY INS_DTM DESC LIMIT %s",
            (args.limit,),
        )
        rows = cur.fetchall()
    if not rows:
        print("억제 중인 주소 없음.")
        return 0
    for r in rows:
        state = "해제됨" if r["RELEASED_DTM"] else "억제 중"
        print(
            f"[{r['MAIL_SUPP_ID']}] {state} · {r['REASON_CD']} · {r['INS_DTM']} · "
            f"hash={r['TARGET_HASH_VAL'][:16]}… · svix={r['SRC_SVIX_MSG_ID'] or '-'}"
        )
    print(f"— {len(rows)}건")
    return 0


def cmd_release_suppression(conn, args) -> int:
    """억제 해제 — 오탐·주소 복구 대응(SP-AUTH-16).

    **이 명령이 없으면 억제는 영구 잠금이다.** 위조·오탐 바운스 한 건으로 사용자가 로그인을
    영영 못 하게 되는 상황을 되돌리는 유일한 수단이라, 기능과 함께 반드시 존재해야 한다.

    행을 지우지 않고 `RELEASED_DTM` 을 채운다 — 언제 누가 풀었는지가 남아야 반복 오탐을
    추적할 수 있다. 같은 주소가 다시 하드 바운스하면 웹훅이 `RELEASED_DTM=NULL` 로 되살린다."""
    from server.services.auth_code import _hash_target

    target_hash = _hash_target(args.email)
    with conn.cursor() as cur:
        cur.execute(
            "UPDATE TMAIL_SUPPRESSION SET RELEASED_DTM=UTC_TIMESTAMP(), MOD_ID=%s "
            "WHERE TARGET_HASH_VAL=%s AND RELEASED_DTM IS NULL",
            (args.by, target_hash),
        )
        n = cur.rowcount
    conn.commit()
    # 주소 원문은 출력하지 않는다(운영 로그·터미널 기록에 남는다 — NFR31 과 같은 이유).
    print(f"억제 해제: hash={target_hash[:16]}… — {n}건.")
    if n == 0:
        print("  (해당 주소는 억제 중이 아니다 — 이미 해제됐거나 다른 주소일 수 있다)")
    return 0


# delete-benefit 편집 이력 before 스냅샷 필드(benefit_edit._snapshot 와 동일 형식·소문자 키).
_SNAP_MAP = {
    "benefit_cd": "BENEFIT_CD", "benefit_nm": "BENEFIT_NM", "benefit_ctgr_cd": "BENEFIT_CTGR_CD",
    "benefit_amt": "BENEFIT_AMT", "qual_yn": "QUAL_YN", "note_ctnt": "NOTE_CTNT",
    "badge_cd": "BADGE_CD", "amt_source": "AMT_SOURCE_CD",
}


def _benefit_snapshot(row: dict) -> str:
    """삭제 복지의 before 스냅샷 JSON — benefit_edit._snapshot 와 동일 형식(공개 이력 diff 정합)."""
    snap = {lo: row.get(up) for lo, up in _SNAP_MAP.items()}
    snap["qual_yn"] = bool(snap.get("qual_yn"))
    return json.dumps(snap, ensure_ascii=False)


def cmd_delete_benefit(conn, args) -> int:
    """복지 하드 삭제 + delete 편집 이력 기록(반달리즘 정정, FR-115).

    순서가 핵심: delete 이력을 **먼저** INSERT(BENEFIT_ID=대상)한 뒤 복지를 DELETE 하면,
    `TBENEFIT_EDIT_LOG.BENEFIT_ID ON DELETE SET NULL` 이 이력의 BENEFIT_ID 만 NULL 로 바꿔
    이력 자체(before 스냅샷·COMP_ID·기록시각)는 **존치**된다(CASCADE 였다면 이력도 소실).
    편집자(ACTOR_MBR_ID)는 운영자라 회원이 아니므로 NULL — 맥락은 EDIT_NOTE_CTNT 로 남긴다."""
    with conn.cursor(pymysql.cursors.DictCursor) as cur:
        cur.execute(
            "SELECT BENEFIT_ID, COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_CTGR_CD, BENEFIT_AMT, "
            "QUAL_YN, NOTE_CTNT, BADGE_CD, AMT_SOURCE_CD FROM TCOMPANY_BENEFIT WHERE BENEFIT_ID=%s",
            (args.benefit_id,),
        )
        row = cur.fetchone()
        if not row:
            print(f"복지 #{args.benefit_id}: 존재하지 않음(삭제 안 함).")
            return 1
        comp = row["COMP_ID"]
        cur.execute(
            "INSERT INTO TBENEFIT_EDIT_LOG "
            "(BENEFIT_ID, COMP_ID, ACTOR_MBR_ID, EDIT_TYPE_CD, BEFORE_VAL, AFTER_VAL, EDIT_NOTE_CTNT) "
            "VALUES (%s, %s, NULL, 'delete', %s, NULL, %s)",
            (args.benefit_id, comp, _benefit_snapshot(row), args.note or "운영자 삭제"),
        )
        cur.execute("DELETE FROM TCOMPANY_BENEFIT WHERE BENEFIT_ID=%s", (args.benefit_id,))
    conn.commit()
    print(f"복지 #{args.benefit_id} 삭제 완료 (COMP {comp}, delete 이력 기록·존치).")
    return 0


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(prog="python -m server.ops", description="loupit 운영자 CLI (SP-AUTH-8)")
    sub = p.add_subparsers(dest="command", required=True)

    sub.add_parser("list-pending", help="수동 승인 대기 큐 조회").set_defaults(func=cmd_list_pending)

    ap = sub.add_parser("approve", help="수동 승인 → manual 재직 인증 생성")
    ap.add_argument("req_id", type=int)
    ap.add_argument("--by", type=int, default=None, help="결정 운영자 ID(감사)")
    ap.add_argument("--note", default=None, help="결정 비고")
    ap.set_defaults(func=cmd_approve)

    rp = sub.add_parser("reject", help="수동 승인 거부")
    rp.add_argument("req_id", type=int)
    rp.add_argument("--by", type=int, default=None)
    rp.add_argument("--note", default=None)
    rp.set_defaults(func=cmd_reject)

    vp = sub.add_parser("revoke-verification", help="재직 인증 폐기")
    vp.add_argument("mbr_id", type=int)
    vp.add_argument("comp_id", type=int)
    vp.add_argument("--by", type=int, default=None)
    vp.set_defaults(func=cmd_revoke_verification)

    dp = sub.add_parser("delete-benefit", help="복지 하드 삭제 + delete 이력(반달리즘 정정)")
    dp.add_argument("benefit_id", type=int)
    dp.add_argument("--note", default=None, help="삭제 사유(편집 이력에 기록)")
    dp.set_defaults(func=cmd_delete_benefit)

    # ── 메일 발송 억제(SP-AUTH-16) ──
    sp = sub.add_parser("list-suppressed", help="발송 억제 목록(반송·스팸신고 주소)")
    sp.add_argument("--all", action="store_true", help="해제분까지 포함")
    sp.add_argument("--limit", type=int, default=50)
    sp.set_defaults(func=cmd_list_suppressed)

    rs = sub.add_parser("release-suppression", help="억제 해제(오탐·주소 복구) — 이메일 원문 필요")
    rs.add_argument("email", help="해제할 주소. 저장된 것은 해시뿐이라 원문으로 재계산한다")
    rs.add_argument("--by", type=int, default=None, help="결정 운영자 ID(감사)")
    rs.set_defaults(func=cmd_release_suppression)

    return p


def main(argv=None) -> int:
    args = build_parser().parse_args(argv)
    conn = _connect()
    try:
        return args.func(conn, args)
    finally:
        conn.close()


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
