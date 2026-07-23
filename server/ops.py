"""SP-AUTH-8 / FR-115 운영자 CLI — 수동 재직 승인·인증 취소 (`python -m server.ops`).

런타임 API와 분리된 **동기 프로세스**(pymysql). 웹 관리자 페이지는 두지 않는다 — 서버 셸
접근 권한을 가진 운영자(A5)만 이 CLI로 처리한다(공격면·관리자 인증 시스템 회피). 승인·거부·
취소는 감사 흔적(`DECIDED_BY_ID`·`DECIDED_DTM`)을 남긴다. 사용자 대면 DELETE 라우트는 없다.

명령:
  list-pending                         수동 승인 대기 큐 조회
  approve <req_id> [--by N] [--note S] 승인 → manual 재직 인증 생성(+employ_vrf_ttl_days)
  reject  <req_id> [--by N] [--note S] 거부(사유 기록)
  revoke-verification <mbr_id> <comp_id> [--by N]  재직 인증 폐기(REVOKED_DTM)

`delete-benefit`(복지 반달리즘 삭제)은 복지 편집(T-13.10)의 편집 이력(append-only)·CASCADE
설계와 함께 추가한다 — TBENEFIT_EDIT_LOG.BENEFIT_ID 가 ON DELETE CASCADE 라 하드 삭제 시 이력이
함께 지워지므로, 편집 이력 인프라와 동시에 설계해야 이력·롤백 재료를 보존할 수 있다.
"""
from __future__ import annotations

import argparse
import hashlib
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
