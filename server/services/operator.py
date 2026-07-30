"""SP-AUTH-19 운영자 권한 — 이 코드베이스에 처음 생기는 "회원 위" 계층.

지금까지 권한 계층은 `require_member` 하나뿐이었다("회원이냐 아니냐"). 그 위를 여는 일이라
**작게, 그리고 되돌릴 수 있게** 만든다: DB 스키마 변경 0, 상태 0, 순수 함수 두 개.

식별자는 `server/.env` 의 `OPERATOR_EMAILS`(쉼표 구분)다. 바꾸려면 서버 접근이 필요하다는
사실 자체가 방어다 — 그리고 권한이 DB 밖에 있으므로 **가입 경로의 어떤 실수도 권한 상승이
되지 않는다**(`TMEMBER` 에 권한 컬럼을 넣었다면 그 둘이 한 테이블을 공유했을 것이다).
"""

from __future__ import annotations

import hashlib

from server import database
from server.config import get_settings


def operator_emails() -> frozenset[str]:
    """화이트리스트를 정규화해 돌려준다(소문자·공백 제거·빈 항목 제외).

    정규화가 계약이다: `.env` 를 손으로 고치는 사람이 `A@b.com, c@d.com ` 처럼 쓸 것이고,
    대소문자·여백 하나 때문에 **운영자가 조용히 권한을 잃으면** 원인을 찾기 어렵다.
    비교 대상인 `TMEMBER.LOGIN_EMAIL_NM` 도 `auth_code._normalize_email`(strip+lower)을
    거쳐 저장되므로 같은 규칙을 쓴다.

    ⚠ `_delivery_address`(`+태그`·구글도트 접기)는 **쓰지 않는다.** 그건 "같은 수신함인가"를
    묻는 폭탄 방지용 키다. 여기서 접으면 `admin+test@` 로 만든 별개 계정이 운영자 권한을
    물려받는다 — 권한은 **계정 동일성**으로 판정해야 한다.
    """
    raw = get_settings().operator_emails or ""
    return frozenset(part.strip().lower() for part in raw.split(",") if part.strip())


def is_operator(email: str | None) -> bool:
    """이 로그인 이메일이 운영자인가. 화이트리스트가 비면 **아무도 아니다**(fail-closed).

    빈 화이트리스트를 "제한 없음"으로 읽는 구현이 세상에 흔한데, 그건 설정을 지운 순간
    전원에게 권한을 주는 것이다. 여기서는 빈 집합이 곧 권한 0이다."""
    if not email:
        return False
    return email.strip().lower() in operator_emails()


# ── 결정 SQL — CLI(`server/ops.py`, 동기 pymysql)와 콘솔(비동기)이 **함께 쓴다** ──────
#
# 같은 규칙을 두 번 구현하면 반드시 어긋난다. 흐름(동기/비동기)은 나뉘어도 **무엇을 바꾸는가**는
# 한 곳에 있어야 한다. 특히 `AND STATUS_CD='pending'` 가드가 그렇다 — 이게 빠진 사본이 하나라도
# 생기면 이미 처리된 요청을 두 번 결정할 수 있고, 그때 `DECIDED_DTM` 은 마지막 것만 남는다.

SQL_FETCH_PENDING_VRF_REQUEST = (
    "SELECT MBR_ID, COMP_ID FROM TEMPLOY_VRF_REQUEST "
    "WHERE VRF_REQUEST_ID=%s AND STATUS_CD='pending'"
)
SQL_ACTIVE_VERIFICATION_EXISTS = (
    "SELECT 1 FROM TEMPLOY_VERIFICATION WHERE MBR_ID=%s AND COMP_ID=%s AND REVOKED_DTM IS NULL "
    "AND (EXPIRES_DTM IS NULL OR EXPIRES_DTM > UTC_TIMESTAMP())"
)
SQL_INSERT_MANUAL_VERIFICATION = (
    "INSERT INTO TEMPLOY_VERIFICATION "
    "(MBR_ID, COMP_ID, VRF_METHOD_CD, COMP_EMAIL_HASH_VAL, EXPIRES_DTM, INS_ID) "
    "VALUES (%s, %s, 'manual', %s, UTC_TIMESTAMP() + INTERVAL %s DAY, %s)"
)
SQL_MARK_VRF_REQUEST_APPROVED = (
    "UPDATE TEMPLOY_VRF_REQUEST SET STATUS_CD='approved', DECIDED_BY_ID=%s, "
    "DECIDED_DTM=UTC_TIMESTAMP(), DECIDE_NOTE_CTNT=%s WHERE VRF_REQUEST_ID=%s"
)
SQL_MARK_VRF_REQUEST_REJECTED = (
    "UPDATE TEMPLOY_VRF_REQUEST SET STATUS_CD='rejected', DECIDED_BY_ID=%s, "
    "DECIDED_DTM=UTC_TIMESTAMP(), DECIDE_NOTE_CTNT=%s WHERE VRF_REQUEST_ID=%s AND STATUS_CD='pending'"
)
SQL_DECIDE_COMPANY_REQUEST = (
    "UPDATE TCOMPANY_REQUEST SET STATUS_CD=%s, DECIDED_BY_ID=%s, "
    "       DECIDED_DTM=UTC_TIMESTAMP(), DECIDE_NOTE_CTNT=%s, MOD_ID=%s "
    " WHERE COMP_REQUEST_ID=%s AND STATUS_CD='pending'"
)
SQL_RELEASE_SUPPRESSION = (
    "UPDATE TMAIL_SUPPRESSION SET RELEASED_DTM=UTC_TIMESTAMP(), MOD_ID=%s "
    "WHERE TARGET_HASH_VAL=%s AND RELEASED_DTM IS NULL"
)

SQL_LIST_PENDING_VRF = (
    "SELECT r.VRF_REQUEST_ID, r.MBR_ID, m.NICKNAME_NM, r.COMP_ID, c.COMP_NM, "
    "       r.EVIDENCE_CTNT, r.INS_DTM "
    "FROM TEMPLOY_VRF_REQUEST r "
    "JOIN TMEMBER m ON m.MBR_ID = r.MBR_ID "
    "JOIN TCOMPANY c ON c.COMP_ID = r.COMP_ID "
    "WHERE r.STATUS_CD='pending' ORDER BY r.INS_DTM"
)
SQL_LIST_PENDING_COMPANY_REQ = (
    "SELECT r.COMP_REQUEST_ID, r.MBR_ID, m.NICKNAME_NM, r.REQ_COMP_NM, r.REF_URL_CTNT, "
    "       r.STATUS_CD, r.INS_DTM "
    "  FROM TCOMPANY_REQUEST r LEFT JOIN TMEMBER m ON m.MBR_ID = r.MBR_ID "
    " WHERE r.STATUS_CD='pending' ORDER BY r.INS_DTM LIMIT %s"
)
SQL_LIST_SUPPRESSED = (
    "SELECT MAIL_SUPP_ID, TARGET_HASH_VAL, REASON_CD, INS_DTM "
    "  FROM TMAIL_SUPPRESSION WHERE RELEASED_DTM IS NULL ORDER BY INS_DTM DESC LIMIT %s"
)


def manual_hash(mbr_id: int, comp_id: int, req_id: int) -> str:
    """수동 인증용 `COMP_EMAIL_HASH_VAL` 대체값.

    NOT NULL UNIQUE 를 충족하면서 도메인 HMAC 과 충돌하지 않는다(원문 이메일이 없는 경로라
    실제 해시를 만들 수 없다). CLI 와 콘솔이 **같은 값**을 만들어야 같은 요청을 두 경로로
    처리해도 UNIQUE 가 일관되게 걸린다."""
    return hashlib.sha256(f"manual:{mbr_id}:{comp_id}:{req_id}".encode()).hexdigest()


# ── 콘솔(비동기) 실행부 ─────────────────────────────────────────────────────────────
#
# ⚠ 모든 함수가 `decided_by` 를 **필수 인자**로 받는다. 기본값을 두지 않는 것이 의도다 —
#   기본값이 있으면 호출부가 빠뜨려도 조용히 NULL 이 들어가고, 그러면 감사가 다시 자율신고가
#   된다. 콘솔은 이 값을 **세션에서** 넣는다(요청 본문에서 받지 않는다).


async def list_pending_verifications() -> list[dict]:
    return await database.fetch_all(SQL_LIST_PENDING_VRF)


async def list_pending_company_requests(limit: int = 50) -> list[dict]:
    return await database.fetch_all(SQL_LIST_PENDING_COMPANY_REQ, (limit,))


async def list_suppressed(limit: int = 50) -> list[dict]:
    return await database.fetch_all(SQL_LIST_SUPPRESSED, (limit,))


async def approve_verification(req_id: int, decided_by: int, note: str | None) -> str:
    """수동 재직 승인 → `manual` 인증 생성 + 요청 approved. 반환=결과 코드.

    CLI `cmd_approve` 와 **같은 SQL·같은 순서**다. 인증 생성과 요청 상태 변경을 한 트랜잭션에
    묶는다 — 둘이 갈라지면 "승인됐다고 표시됐는데 인증은 없는" 상태가 남고, 사용자는 승인
    통보를 보고도 편집을 못 한다."""
    async with database.transaction() as conn:
        async with conn.cursor() as cur:
            await cur.execute(SQL_FETCH_PENDING_VRF_REQUEST, (req_id,))
            req = await cur.fetchone()
            if not req:
                return "not_pending"
            mbr, comp = req["MBR_ID"], req["COMP_ID"]
            await cur.execute(SQL_ACTIVE_VERIFICATION_EXISTS, (mbr, comp))
            already = await cur.fetchone()
            if not already:
                await cur.execute(
                    SQL_INSERT_MANUAL_VERIFICATION,
                    (mbr, comp, manual_hash(mbr, comp, req_id),
                     get_settings().employ_vrf_ttl_days, decided_by),
                )
            await cur.execute(SQL_MARK_VRF_REQUEST_APPROVED, (decided_by, note, req_id))
    return "approved_existing" if already else "approved"


async def reject_verification(req_id: int, decided_by: int, note: str | None) -> bool:
    return bool(await database.execute(SQL_MARK_VRF_REQUEST_REJECTED, (decided_by, note, req_id)))


async def decide_company_request(req_id: int, approve: bool, decided_by: int, note: str | None) -> bool:
    """🚨 **회사를 만들지 않는다.** 상태만 바꾼다 — CLI 와 동일한 계약(SP-AUTH-17).

    실제 등록은 `db/seed` 작업이고, 그 판단(등록할 가치가 있는가·데이터를 확보할 수 있는가)이
    이 기능의 핵심이다. 승인 표시는 '검토했고 등록하기로 했다'는 기록일 뿐이다."""
    status = "approved" if approve else "rejected"
    return bool(await database.execute(
        SQL_DECIDE_COMPANY_REQUEST, (status, decided_by, note, decided_by, req_id)))


async def release_suppression(target_hash: str, decided_by: int) -> bool:
    """억제 해제 — **해시로** 받는다(원문 이메일을 받지 않는다).

    CLI 는 원문을 받아 해시한다(사람이 아는 것은 주소니까). 콘솔은 목록에서 고르는 UI 라
    해시를 그대로 넘길 수 있다 — 그러면 **주소 원문이 브라우저·요청 로그·히스토리에 남지
    않는다**. 같은 기능이라도 입구가 다르면 안전한 표현이 다르다."""
    return bool(await database.execute(SQL_RELEASE_SUPPRESSION, (decided_by, target_hash)))
