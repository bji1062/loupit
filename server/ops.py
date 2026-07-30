"""SP-AUTH-8 / FR-115 운영자 CLI — 수동 재직 승인·인증 취소 (`python -m server.ops`).

런타임 API와 분리된 **동기 프로세스**(pymysql). 웹 관리자 페이지는 두지 않는다 — 서버 셸
접근 권한을 가진 운영자(A5)만 이 CLI로 처리한다(공격면·관리자 인증 시스템 회피). 승인·거부·
취소는 감사 흔적(`DECIDED_BY_ID`·`DECIDED_DTM`)을 남긴다. 사용자 대면 DELETE 라우트는 없다.

⚠ **CLI 만으로는 부족하다는 것이 2026-07-29 에 실측됐다** — 회사 등록 요청 #1 이 약 1시간 40분
방치됐고 아무도 몰랐다. **알림 없는 큐는 큐가 아니다.** 그래서 `digest` 를 두고
`loupit-ops-digest.timer` 가 일 1회 밀어준다(SP-AUTH-8.1). 위 "웹 관리자 페이지 없음" 결정은
유지되며, 알림은 그 결정을 바꾸지 않고 공백만 메운다.

명령:
  digest [--send]                      큐 3종 요약 출력(기본) / 발송. 타이머가 일 1회 --send
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
from server.mailer import SERVICE_NAME, get_mailer


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



def cmd_list_company_requests(conn, args) -> int:
    """회사 등록 요청 큐 조회(SP-AUTH-17).

    ⚠ 회사명·URL 은 **사용자 입력 원문**이다. 서비스 계층이 제어문자를 제거하고 URL 스킴을
    http/https 로 제한하지만, 여기서도 값을 신뢰해 자동으로 무언가 하지 않는다 — 출력해서
    사람이 읽고 판단하는 것이 이 명령의 전부다."""
    with conn.cursor(pymysql.cursors.DictCursor) as cur:
        cur.execute(
            "SELECT r.COMP_REQUEST_ID, r.MBR_ID, m.NICKNAME_NM, r.REQ_COMP_NM, r.REF_URL_CTNT, "
            "       r.STATUS_CD, r.INS_DTM "
            "  FROM TCOMPANY_REQUEST r LEFT JOIN TMEMBER m ON m.MBR_ID = r.MBR_ID "
            + ("" if args.all else "WHERE r.STATUS_CD='pending' ")
            + "ORDER BY r.INS_DTM LIMIT %s",
            (args.limit,),
        )
        rows = cur.fetchall()
    if not rows:
        print("회사 등록 요청 없음.")
        return 0
    print(f"회사 등록 요청 {len(rows)}건:")
    for r in rows:
        who = r["NICKNAME_NM"] or f"(탈퇴 회원 {r['MBR_ID']})"
        print(f"  #{r['COMP_REQUEST_ID']}  [{r['STATUS_CD']}]  {r['REQ_COMP_NM']}  — {who}  {r['INS_DTM']}")
        print(f"      참고 URL: {r['REF_URL_CTNT'] or '(없음 — 직접 조사 필요)'}")
    return 0


def cmd_decide_company_request(conn, args) -> int:
    """회사 등록 요청 승인/거부 표시(SP-AUTH-17).

    🚨 **이 명령은 회사를 만들지 않는다.** 상태만 바꾼다. 실제 등록은 `db/seed` 에 회사·복지
    데이터를 넣는 별도 작업이며, 그 판단(등록할 가치가 있는 회사인가·데이터를 확보할 수
    있는가)이 이 기능의 핵심이다. 승인 표시는 '검토했고 등록하기로 했다'는 기록일 뿐이다."""
    status = "approved" if args.approve else "rejected"
    with conn.cursor() as cur:
        cur.execute(
            "UPDATE TCOMPANY_REQUEST SET STATUS_CD=%s, DECIDED_BY_ID=%s, "
            "       DECIDED_DTM=UTC_TIMESTAMP(), DECIDE_NOTE_CTNT=%s, MOD_ID=%s "
            " WHERE COMP_REQUEST_ID=%s AND STATUS_CD='pending'",
            (status, args.by, args.note, args.by, args.req_id),
        )
        n = cur.rowcount
    conn.commit()
    print(f"회사 등록 요청 #{args.req_id} → {status} ({n}건).")
    if n == 0:
        print("  (pending 상태가 아니다 — 이미 처리됐거나 없는 ID)")
    elif status == "approved":
        print("  ⚠ 상태만 바뀌었다. 실제 회사 등록은 db/seed 작업으로 별도 수행하라.")
    return 0


# delete-benefit 편집 이력 before 스냅샷 필드(benefit_edit._snapshot 와 동일 형식·소문자 키).
_SNAP_MAP = {
    "benefit_cd": "BENEFIT_CD", "benefit_nm": "BENEFIT_NM", "benefit_ctgr_cd": "BENEFIT_CTGR_CD",
    "benefit_amt": "BENEFIT_AMT", "qual_yn": "QUAL_YN", "note_ctnt": "NOTE_CTNT",
    "badge_cd": "BADGE_CD", "amt_source": "AMT_SOURCE_CD",
}


# ── 운영자 큐 일일 요약 (2026-07-29 신설) ─────────────────────────────────
# 배경: 회사 등록 요청 #1 이 약 1시간 40분 방치됐고, 운영자가 `list-*` 를 직접 치기 전까지
# 아무도 몰랐다. 알림 배선이 전무했다(코드에 notify 흔적 0건·타이머는 백업 하나·크론 없음).
#
# 설계 판단 둘:
#   ① **건수와 ID 만 보낸다.** 증빙 원문에는 재직증명서 링크 같은 사용자 제출물이 들어오고
#      닉네임·회사명도 사용자 입력이다. 메일에 실으면 위탁 발송자(Resend)와 외부 수신함을
#      거치는 **새 개인정보 흐름**이 생긴다. "가서 봐야 한다"를 알리는 게 목적이니 건수로 충분하다.
#   ② **큐가 비어도 보낸다.** 대기가 있을 때만 보내면 침묵이 "대기 없음"과 "타이머 고장"의
#      두 뜻이 된다. 침묵을 성공으로 읽는 알림은 없는 것보다 나쁘다 — 있다고 믿게 만든다.
#      대신 제목에 건수와 마커를 실어 열지 않고도 판단하게 한다.
DIGEST_MARK = "🔴"

_DIGEST_QUERIES = (
    ("pending", "재직 수동 승인", "list-pending",
     "SELECT VRF_REQUEST_ID AS id FROM TEMPLOY_VRF_REQUEST WHERE STATUS_CD='pending' ORDER BY INS_DTM"),
    ("company", "회사 등록 요청", "list-company-requests",
     "SELECT COMP_REQUEST_ID AS id FROM TCOMPANY_REQUEST WHERE STATUS_CD='pending' ORDER BY INS_DTM"),
    ("suppressed", "메일 발송 억제", "list-suppressed",
     "SELECT MAIL_SUPP_ID AS id FROM TMAIL_SUPPRESSION WHERE RELEASED_DTM IS NULL ORDER BY INS_DTM DESC"),
)


def collect_digest(conn) -> dict[str, list[int]]:
    """세 큐의 **대기 중 ID 목록**만 모은다(내용은 읽지 않는다 — 위 판단 ①)."""
    out: dict[str, list[int]] = {}
    for key, _label, _cmd, sql in _DIGEST_QUERIES:
        with conn.cursor(pymysql.cursors.DictCursor) as cur:
            cur.execute(sql)
            out[key] = [r["id"] for r in cur.fetchall()]
    return out


# ── 복원 훈련 상태 (2026-07-30 신설) ──────────────────────────────────────
# 주간 복원 훈련(`infra/deploy/restore-drill.sh`)이 남긴 상태를 요약에 함께 싣는다.
#
# **왜 별도 알림 경로를 만들지 않았나**: 훈련이 실패해도 아무도 안 보면 훈련이 아니다. 그런데
# 새 발송 경로를 하나 더 만들면 그 경로도 언젠가 조용히 죽고, 그 죽음을 감시할 것이 또 필요해진다.
# 일일 요약은 **웹훅으로 배달까지 실증된** 채널이므로 여기에 얹는 것이 가장 안전하다.
#
# **경과일을 함께 본다**: 훈련이 "실패"한 것과 "아예 돌지 않은 것"은 다른 사건인데, 실패만
# 보면 둘째를 영영 놓친다. 타이머가 죽으면 상태 파일은 그냥 낡아 갈 뿐 아무 소리도 내지 않는다.
DRILL_STATE_PATH = "/var/backups/loupit/restore-drill.json"
DRILL_STALE_DAYS = 10  # 주기(7일) + 여유 3일. 이 이상 낡으면 타이머 고장을 의심한다.


def collect_drill_status(path: str | None = None) -> dict:
    """복원 훈련 상태를 읽는다. 읽을 수 없으면 **그 사실 자체를 상태로** 돌려준다.

    파일이 없다/깨졌다를 예외로 흘리면 요약 메일 전체가 안 나가고, 그러면 큐 알림까지 함께
    잃는다. 부수 기능이 본 기능을 죽이면 안 된다."""
    from datetime import datetime, timezone
    from pathlib import Path

    p = Path(path or DRILL_STATE_PATH)
    try:
        raw = json.loads(p.read_text())
        at = datetime.strptime(raw["at"], "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc)
    except FileNotFoundError:
        return {"known": False, "reason": "상태 파일 없음(훈련이 한 번도 안 돌았거나 경로가 다르다)"}
    except Exception as exc:  # noqa: BLE001 — 형식 파손·권한 등 원인 무관
        return {"known": False, "reason": f"상태 파일을 읽을 수 없다({type(exc).__name__})"}

    age_days = (datetime.now(timezone.utc) - at).total_seconds() / 86400
    return {
        "known": True,
        "ok": bool(raw.get("ok")),
        "at": raw["at"],
        "age_days": age_days,
        "stale": age_days > DRILL_STALE_DAYS,
        "source": raw.get("source", ""),
        "detail": raw.get("detail", ""),
    }


def drill_is_alarming(drill: dict) -> bool:
    """제목에 🔴 를 띄울 사건인가 — 실패 / 낡음 / 알 수 없음 셋 다 알람이다.

    "알 수 없음"을 알람에서 빼면, 경로가 틀린 채 배포된 순간부터 영원히 조용해진다."""
    return (not drill.get("known")) or (not drill.get("ok")) or bool(drill.get("stale"))


def drill_line(drill: dict) -> str:
    if not drill.get("known"):
        return f"{DIGEST_MARK} 복원 훈련        알 수 없음 — {drill.get('reason', '')}"
    mark = DIGEST_MARK if drill_is_alarming(drill) else "  "
    verdict = "성공" if drill.get("ok") else "실패"
    age = int(drill.get("age_days", 0))
    stale = " ⚠주기 초과" if drill.get("stale") else ""
    return (f"{mark} 복원 훈련        {verdict} ({age}일 전{stale})"
            f"  {drill.get('source', '')}  {drill.get('detail', '')}")


def digest_subject(digest: dict[str, list[int]], drill: dict | None = None) -> str:
    """제목만 보고 판단할 수 있어야 한다 — 매일 오는 메일 중에서 골라내야 하므로.

    큐가 비어도 **복원 훈련이 문제면 제목에 마커를 띄운다.** 본문에만 두면 "큐 0건" 제목을
    보고 열지 않는 날이 반복되고, 그러면 그 줄은 없는 것과 같다."""
    total = sum(len(v) for v in digest.values())
    parts = " · ".join(f"{label} {len(digest[key])}" for key, label, _c, _s in _DIGEST_QUERIES)
    alarm = bool(total) or (drill is not None and drill_is_alarming(drill))
    mark = f"{DIGEST_MARK} " if alarm else ""
    suffix = " · 복원훈련 확인필요" if drill is not None and drill_is_alarming(drill) else ""
    return f"[{SERVICE_NAME}] {mark}운영 큐 {total}건 — {parts}{suffix}"


def digest_body(digest: dict[str, list[int]], drill: dict | None = None) -> str:
    lines = ["운영 큐 요약", ""]
    for key, label, cmd, _sql in _DIGEST_QUERIES:
        ids = digest[key]
        marker = DIGEST_MARK if ids else "  "
        detail = "  " + " ".join(f"#{i}" for i in ids) if ids else ""
        lines.append(f"{marker} {label:<14} {len(ids)}건{detail}")
    if drill is not None:
        lines += ["", "백업 건강", "", drill_line(drill)]
    lines += [
        "",
        "내용(증빙·회사명·주소)은 이 메일에 담지 않는다 — 서버에서 확인하라:",
    ]
    lines += [f"  python3 -m server.ops {cmd}" for _k, _l, cmd, _s in _DIGEST_QUERIES]
    if drill is not None:
        lines.append("  journalctl -u loupit-restore-drill -n 30   # 복원 훈련 로그")
    return "\n".join(lines)


def cmd_digest(conn, args) -> int:
    """큐 요약 출력(기본) 또는 발송(`--send`).

    기본이 발송 없음인 이유: 사람이 확인차 실행할 때마다 메일이 나가면 안 된다.
    타이머만 `--send` 를 붙인다."""
    digest = collect_digest(conn)
    drill = collect_drill_status(getattr(args, "drill_state", None))
    subject = digest_subject(digest, drill)
    body = digest_body(digest, drill)
    total = sum(len(v) for v in digest.values())

    if not args.send:
        print(subject)
        print()
        print(body)
        return 0

    # ⚠ `--only-if-pending` 는 큐 건수만 본다. 복원 훈련이 실패해도 큐가 비면 침묵한다 —
    #   그래서 훈련 알람이 있으면 이 생략을 무시한다. 안 그러면 "조용한 백업 고장"이 된다.
    if getattr(args, "only_if_pending", False) and total == 0 and not drill_is_alarming(drill):
        print("대기 0건 + --only-if-pending → 발송 생략 (⚠ 침묵이 고장과 구분되지 않는다)")
        return 0

    to = args.to or get_settings().ops_digest_to
    if not to:
        print("발송 실패: 수신 주소 없음 — server/.env 의 OPS_DIGEST_TO 를 설정하라.")
        return 2

    try:
        get_mailer().send_notice(to, subject, body)
    except Exception as e:  # noqa: BLE001 — 원인 종류와 무관하게 비0으로 알려야 한다
        print(f"발송 실패: {type(e).__name__}: {e}")
        return 1
    print(f"요약 발송 완료 → {to} ({total}건)")
    return 0


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

    dg = sub.add_parser("digest", help="큐 3종 요약 출력(기본) / --send 로 운영자에게 발송")
    dg.add_argument("--send", action="store_true", help="메일 발송(없으면 화면 출력만)")
    dg.add_argument("--to", default="", help="수신 주소(생략 시 OPS_DIGEST_TO)")
    dg.add_argument("--only-if-pending", action="store_true",
                    help="대기 0건이면 발송 생략. ⚠ 침묵이 '고장'과 구분되지 않는다 — 기본값 아님. "
                         "복원 훈련 알람이 있으면 이 생략은 무시된다")
    dg.add_argument("--drill-state", default=None,
                    help=f"복원 훈련 상태 파일 경로(기본 {DRILL_STATE_PATH})")
    dg.set_defaults(func=cmd_digest)

    cq = sub.add_parser("list-company-requests", help="회사 등록 요청 큐(검색에 없는 회사)")
    cq.add_argument("--all", action="store_true", help="처리분까지 포함")
    cq.add_argument("--limit", type=int, default=50)
    cq.set_defaults(func=cmd_list_company_requests)

    dq = sub.add_parser("decide-company-request", help="회사 등록 요청 승인/거부 표시(회사 생성 아님)")
    dq.add_argument("req_id", type=int)
    g = dq.add_mutually_exclusive_group(required=True)
    g.add_argument("--approve", action="store_true")
    g.add_argument("--reject", action="store_true")
    dq.add_argument("--by", type=int, default=None, help="결정 운영자 ID(감사)")
    dq.add_argument("--note", default=None, help="결정 사유")
    dq.set_defaults(func=cmd_decide_company_request)

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
