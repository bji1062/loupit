"""회사 등록 요청 — 검색에 없는 회사의 출구 (SP-AUTH-17, 2026-07-29 신설).

**해결하는 공백**: 재직 인증 화면에서 회사를 검색했는데 0건이면 화면이 아무 반응도 하지
않았고, 수동 승인 요청조차 `comp_id` 가 필수라 **폴백 경로에 진입조차 못 했다**. 등록 회사는
95개뿐이라 대부분의 사용자가 여기서 막힌다.

**계약: 요청은 회사를 만들지 않는다.** 등록 여부는 전적으로 운영자 판단이다(사용자 결정).
자동 생성하면 복지 데이터가 0인 빈 회사가 비교 서비스에 쌓여 데이터 품질이 무너지고,
"이 회사는 복지 정보가 없습니다"만 나오는 페이지가 검색엔진에 노출된다.

**입력 신뢰 경계**: 회사명·URL 은 **로그인 사용자가 자유롭게 쓰는 값**이다. 저장 전에
정규화·검증하고, 저장 후에는 어디서도 원문을 신뢰하지 않는다(운영 CLI 출력·향후 운영 화면).
"""
from __future__ import annotations

import logging
import re
import unicodedata

from server import database

logger = logging.getLogger(__name__)

# 한 회원이 동시에 걸어둘 수 있는 pending 요청 수. 요청은 **사람이 읽어야 하는** 항목이라
# 큐가 부풀면 운영자 검토가 마비된다 — 로그인만 하면 누구나 넣을 수 있으므로 상한이 필요하다.
MAX_PENDING_PER_MEMBER = 5

_NAME_MAX = 100
_URL_MAX = 500
# 스킴 화이트리스트. **차단 목록이 아니라 허용 목록**이어야 한다 — `javascript:`·`data:`·
# `vbscript:` 를 하나씩 막는 방식은 새 스킴이나 대소문자·공백 변형에 계속 뚫린다.
_ALLOWED_SCHEMES = ("http://", "https://")

_SQL_FIND_PENDING = """
  SELECT COMP_REQUEST_ID FROM TCOMPANY_REQUEST
   WHERE MBR_ID=%s AND REQ_COMP_NM=%s AND STATUS_CD='pending' LIMIT 1"""

_SQL_COUNT_PENDING = """
  SELECT COUNT(*) AS n FROM TCOMPANY_REQUEST WHERE MBR_ID=%s AND STATUS_CD='pending'"""

_SQL_INSERT = """
  INSERT INTO TCOMPANY_REQUEST (MBR_ID, REQ_COMP_NM, REF_URL_CTNT, STATUS_CD, INS_ID)
  VALUES (%s, %s, %s, 'pending', %s)"""


def normalize_name(raw: str | None) -> str:
    """회사명 정규화 — 공백 축약 + 제어문자 제거 + 길이 상한.

    제어문자를 지우는 이유: 이 값은 운영자 터미널에 출력된다. ANSI 이스케이프나 개행이 섞이면
    출력이 깨지거나 다른 줄을 위조할 수 있다(로그 인젝션). 표시 계층을 믿지 않고 입력에서 막는다.
    """
    if raw is None:
        raise ValueError("회사명이 비어 있다")
    # 제어문자(Cc)·서식문자(Cf)를 공백으로 바꾼 뒤 공백을 하나로 축약한다.
    cleaned = "".join(" " if unicodedata.category(ch) in ("Cc", "Cf") else ch for ch in raw)
    cleaned = re.sub(r"\s+", " ", cleaned).strip()
    if not cleaned:
        raise ValueError("회사명이 비어 있다")
    if len(cleaned) > _NAME_MAX:
        raise ValueError(f"회사명이 너무 길다(최대 {_NAME_MAX}자)")
    return cleaned


def normalize_url(raw: str | None) -> str | None:
    """참고 URL 정규화 — **선택 항목**이라 비면 `None`, 있으면 http/https 만 허용.

    ⚠ 이 값은 저장됐다가 운영자에게 보여지고, 운영 화면이 생기면 링크가 될 수 있다.
    `javascript:`·`data:` 를 통과시키면 그 시점에 저장형 XSS 가 된다. "지금은 링크가 아니니
    괜찮다"는 판단은 나중에 화면을 만드는 사람에게 **안전하다는 잘못된 신호**를 준다.
    """
    if raw is None:
        return None
    # 제어문자 제거 후 트림 — `  javascript:…` 나 `java\tscript:` 류 우회를 먼저 무력화한다.
    cleaned = "".join("" if unicodedata.category(ch) in ("Cc", "Cf") else ch for ch in raw).strip()
    if not cleaned:
        return None
    if len(cleaned) > _URL_MAX:
        raise ValueError(f"URL 이 너무 길다(최대 {_URL_MAX}자)")
    if not cleaned.lower().startswith(_ALLOWED_SCHEMES):
        raise ValueError("http:// 또는 https:// 로 시작하는 주소만 넣을 수 있다")
    return cleaned


async def submit(mbr_id: int, comp_nm: str, ref_url: str | None) -> str:
    """요청 1건 접수 → `"ok"` · `"dup"`(같은 회사 pending 중복) · `"too_many"`(상한 초과).

    ⚠ **`TCOMPANY` 를 절대 건드리지 않는다.** 이 함수가 하는 일은 큐에 한 줄 넣는 것뿐이고,
    회사 생성은 운영자가 별도로 판단·수행한다(test_CR7 이 이 성질을 적극 검증한다).
    """
    name = normalize_name(comp_nm)
    url = normalize_url(ref_url)

    if await database.fetch_one(_SQL_FIND_PENDING, (mbr_id, name)):
        return "dup"

    row = await database.fetch_one(_SQL_COUNT_PENDING, (mbr_id,))
    if row and int(row.get("n", 0)) >= MAX_PENDING_PER_MEMBER:
        return "too_many"

    await database.execute(_SQL_INSERT, (mbr_id, name, url, mbr_id))
    # 회사명은 사용자 입력이지만 PII 가 아니고 운영 판단에 필요하다. URL 은 로그에 남기지
    # 않는다(길고, 추적 파라미터가 붙어 있을 수 있다).
    logger.info("회사 등록 요청 접수: mbr=%s name=%r url=%s", mbr_id, name, "있음" if url else "없음")
    return "ok"
