"""메일 배달 결과 — 웹훅 이벤트 기록·발송 억제 (SP-AUTH-16, P1-4 · 2026-07-29).

**해결하는 공백**: Resend 키가 발송 전용이라 배달 결과를 **조회할 수 없다**. 그래서 게이트웨이가
거부·격리해도 앱은 영영 모르고, 화면엔 "코드를 보냈습니다"가 뜨는데 사용자는 로그인을 아예 못
한다. 웹훅은 읽기 권한 없이 제공자가 결과를 밀어주는 유일한 경로다.

**수신자는 언제나 해시로만 다룬다.** 페이로드에는 평문 주소가 오지만, 저장·조회 모두
`auth_code._hash_target`(= SHA-256(배달주소 정규화))을 거친다. 같은 규칙을 쓰는 덕에
`TAUTH_CODE` 의 발송 기록과 원문 없이 상관관계가 잡히고, `+태그`·구글 도트 변형으로
**억제를 우회할 수 없다**(`_delivery_address` 가 접어준다).
"""
from __future__ import annotations

import logging

from server import database
from server.services.auth_code import _hash_target

logger = logging.getLogger(__name__)

# 억제 사유 코드(TMAIL_SUPPRESSION.REASON_CD 값집합)
REASON_HARD_BOUNCE = "hard_bounce"
REASON_COMPLAINT = "complaint"
REASON_SUPPRESSED = "suppressed"

# 제공자가 "영구 실패"로 분류한 값. Transient(일시)·Undetermined(미상)는 **의도적으로 제외**한다.
_PERMANENT = "permanent"

_SQL_INSERT_EVENT = """
  INSERT IGNORE INTO TMAIL_EVENT
    (SVIX_MSG_ID, EVENT_TYPE_CD, TARGET_HASH_VAL, PROVIDER_MSG_ID,
     BOUNCE_TYPE_CD, BOUNCE_SUBTYPE_CD, EVENT_DTM)
  VALUES (%s, %s, %s, %s, %s, %s, %s)"""

# 억제는 주소당 1행. 재바운스·해제 후 재바운스는 UPDATE 로 되살린다(RELEASED_DTM=NULL).
_SQL_UPSERT_SUPPRESSION = """
  INSERT INTO TMAIL_SUPPRESSION (TARGET_HASH_VAL, REASON_CD, SRC_SVIX_MSG_ID)
  VALUES (%s, %s, %s)
  ON DUPLICATE KEY UPDATE REASON_CD=VALUES(REASON_CD),
                          SRC_SVIX_MSG_ID=VALUES(SRC_SVIX_MSG_ID),
                          RELEASED_DTM=NULL"""

_SQL_IS_SUPPRESSED = """
  SELECT MAIL_SUPP_ID AS id FROM TMAIL_SUPPRESSION
   WHERE TARGET_HASH_VAL=%s AND RELEASED_DTM IS NULL LIMIT 1"""


def suppression_reason(event_type: str, bounce: dict | None) -> str | None:
    """이 이벤트가 **발송 억제**를 유발하는가. 유발하지 않으면 None.

    억제는 사용자를 로그인에서 밀어내는 결정이라 **되돌리기 어렵다**. 그래서 판정은 보수적이다:

    - 영구 바운스(`Permanent`)·스팸 신고·제공자 자체 억제 → 억제
    - 일시 바운스(`Transient`: 메일함 가득참 등)·지연·일반 실패 → **억제하지 않음**
    - 바운스 정보가 없거나 종류가 `Undetermined` → **억제하지 않음**

    마지막 규칙이 중요하다: 애매한 페이로드를 "영구"로 읽으면 멀쩡한 사용자가 잠긴다.
    정보가 없으면 재발송을 택한다 — 원장에는 남으므로 운영자가 나중에 판단할 수 있다.
    """
    if event_type == "email.complained":
        return REASON_COMPLAINT
    if event_type == "email.suppressed":
        return REASON_SUPPRESSED
    if event_type == "email.bounced":
        kind = (bounce or {}).get("type") or ""
        if kind.strip().lower() == _PERMANENT:
            return REASON_HARD_BOUNCE
    return None


async def record_event(
    *,
    svix_id: str,
    event_type: str,
    recipient: str,
    provider_msg_id: str | None,
    bounce: dict | None,
    event_dtm: str | None,
) -> None:
    """이벤트 1건을 원장에 남기고, 필요하면 억제 목록에 올린다.

    `INSERT IGNORE` + 복합 UNIQUE 로 멱등이다 — Svix 는 at-least-once 라 같은 이벤트가 두 번
    올 수 있고, 재전송은 **동시에** 도착할 수도 있다. `SELECT` 후 `INSERT` 하는 검사-후-행동은
    그 레이스에서 둘 다 통과하므로 쓰지 않는다(제약이 판정을 소유한다).
    """
    target_hash = _hash_target(recipient)
    bounce = bounce if isinstance(bounce, dict) else None
    await database.execute(
        _SQL_INSERT_EVENT,
        (
            svix_id,
            event_type,
            target_hash,
            provider_msg_id,
            (bounce or {}).get("type"),
            (bounce or {}).get("subType"),
            _as_datetime(event_dtm),
        ),
    )

    reason = suppression_reason(event_type, bounce)
    if reason:
        await database.execute(_SQL_UPSERT_SUPPRESSION, (target_hash, reason, svix_id))
        # 수신자 원문은 로그에도 남기지 않는다(journald 평문 적재 전례 — NFR31).
        logger.warning("메일 발송 억제 등록: reason=%s target=%s…", reason, target_hash[:12])


async def is_suppressed(email: str) -> bool:
    """이 주소로 메일을 보내면 안 되는가(하드 바운스·스팸신고 이력).

    **DB 오류는 False 로 흡수한다** — 억제 조회가 실패했다고 로그인 메일을 막으면, 조회 장애가
    곧 전면 로그인 장애가 된다. 억제는 평판 보호 장치지 인증 경로의 필수 의존이 아니다.
    """
    try:
        row = await database.fetch_one(_SQL_IS_SUPPRESSED, (_hash_target(email),))
    except Exception:  # DB 장애·테이블 부재(구 스키마) — 발송을 막지 않는다
        logger.exception("억제 목록 조회 실패 — 발송을 계속한다")
        return False
    return row is not None


def _as_datetime(raw: str | None) -> str | None:
    """제공자의 ISO8601(`2026-07-29T01:02:03.000Z`)을 MySQL DATETIME 문자열로.

    파싱 실패는 None 이다 — 이벤트 기록이 시각 형식 하나 때문에 통째로 실패하면 안 된다
    (그 순간 제공자는 재시도 루프에 들어가고, 우리는 배달 결과를 계속 잃는다).
    """
    if not raw or not isinstance(raw, str):
        return None
    text = raw.strip().replace("Z", "+00:00")
    try:
        from datetime import datetime

        return datetime.fromisoformat(text).strftime("%Y-%m-%d %H:%M:%S")
    except ValueError:
        return None
