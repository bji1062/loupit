"""SP-SEED-8 — DEC-2 백필 오케스트레이션 (로더 프로버넌스 정밀 판본).

SP-DB-13(순수 SQL 판본, db/migrations/20260710_backfill_dec2.sql)과 동일 불변식
(DC-13/14 ≡ SB-1/SB-9)을 만족하되, 파일 헤더의 실측 수집일·URL을 반영해
BADGE_SRC_CD·VERIFIED_DTM을 정밀화한다.

DG-1 확정(TASK/00 §4, 2026-07-11): 만료 TTL = **균일 18개월**(카테고리 차등 폐기).
DG-2 확정: amt_source 판별 규칙 — 정성/금액없음→none, (추정·환산 표기 OR note
없음)→estimated, 명시금액+추정표기 없음→stated.

M-4 앵커 강등(2026-07-12 ~ 2026-09-28)은 **폐기했다**(사용자 결정 2026-09-28: 「당연히 겹칠 수도 있지」).
무관 회사 간 같은 (복지코드·금액)이 N개사 이상이면 stated→estimated 로 내리던 규칙이다. 공식 원문으로 다시
모은 회사가 늘면서, 원문에 적힌 금액(CJ 5사 복지포인트 100 · 카카오·카카오페이·엔씨소프트 명절 60 등)까지
「추정치」로 내리고 있었다. 금액출처는 이제 DG-2 판별 하나로만 정한다 — 추정이면 시드 NOTE 에 「추정」·「환산」을
적는 것이 정본이다(재수집 계약 R6). 되살리지 마라 — test_seed_integrity.py SI-M4 가 막는다.

🚨 SP-SEED-12(2026-09-24): **백필은 재직자 행(`BADGE_CD='verified'`)을 읽지도 쓰지도 않는다.**
재직자 행 = 편집 서비스(`server/services/benefit_edit.py`)가 등록·수정한 행이고, 그 금액출처·출처·
신선도는 서비스가 정한 값이 정본이다(금액 행은 늘 'estimated' — INV-5 밴드). 예전 판본은 2·2b·3
단계를 전 행에 돌려, 재직자가 적은 「1인당 월 5만원」을 'stated' 로 올리고 출처·신선도를 시드 파일
헤더 것으로 덮었으며, 재직자 값이 다른 회사 공식 행의 앵커 판정에까지 끼어들었다. 1단계(승격)는
원래 'est' 만 보므로 무관하다. 로더 쪽 보존 장치(스냅숏·복원·대조)는 load.py 머리말 참조.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

_THIS_DIR = Path(__file__).resolve().parent
if str(_THIS_DIR) not in sys.path:
    sys.path.insert(0, str(_THIS_DIR))

from company_meta import BENEFIT_SQL_DIR, parse_header_insert  # noqa: E402

TTL_MONTHS_UNIFORM = 18  # DG-1 확정: 카테고리 무관 균일 18개월
# SP-SEED-12: 재직자 행 표지. 편집 서비스(server/services/benefit_edit.py)만 이 값을 쓴다 —
# 시드는 'est', 백필은 'official' 만 쓴다. 두 값이 갈라지면 보존이 조용히 꺼진다(SK-8 이 대조한다).
MEMBER_BADGE_CD = "verified"

_DATE_RE = re.compile(r"^-- 출처: AI 파싱 \((\d{4}-\d{2}-\d{2})\)", re.MULTILINE)
_URL_RE = re.compile(r"^-- URL: (http\S+)", re.MULTILINE)


def derive_amt_source(benefit_amt, qual_yn, note_ctnt) -> str:
    """OI-6/DG-2 확정 규칙 — 금액 신뢰도 도출(SP-SEED-8.2)."""
    if qual_yn or benefit_amt is None:  # 정성/금액없음
        return "none"
    n = note_ctnt or ""
    if ("추정" in n) or ("환산" in n) or (n == ""):  # 추정·환산 표기 또는 근거(NOTE) 없음 → 보수적 넓은 밴드
        return "estimated"
    return "stated"  # note에 명시 금액 근거 있고 추정 표기 없음


def _parse_provenance(dst_dir: Path) -> dict:
    """{eng_nm: {"scraped_at": "YYYY-MM-DD", "url": str|None}} — 헤더 재파싱(SP-SEED-8.5)."""
    prov: dict[str, dict] = {}
    for f in sorted(dst_dir.glob("*.sql")):
        text = f.read_text(encoding="utf-8")
        eng, _comp_nm, _comp_type = parse_header_insert(text)
        date_m = _DATE_RE.search(text)
        scraped_at = date_m.group(1) if date_m else "2026-07-10"
        url_m = _URL_RE.search(text)
        prov[eng] = {"scraped_at": scraped_at, "url": url_m.group(1) if url_m else None}
    return prov


def backfill(cur) -> dict:
    """단계5 — 로드된 복지행에 DEC-2 백필 적용. 처리 카운트 반환(로그/테스트용).

    재직자 행(`BADGE_CD=MEMBER_BADGE_CD`)은 2·3 단계 모두에서 뺀다(모듈 머리말 SP-SEED-12).
    그래서 `amt_source` 합계는 "재직자 행을 뺀 전 행" 이다.
    """
    stats: dict = {}

    # 1) 출처 신뢰도 official 승격 — 'est'(시드가 막 넣은 행)만 본다. 재직자 행은 원래 대상이 아니다.
    cur.execute("UPDATE TCOMPANY_BENEFIT SET BADGE_CD='official' WHERE BADGE_CD='est'")
    stats["promoted"] = cur.rowcount

    # 2) 금액 신뢰도 amt_source 도출 — 재직자 행 제외(서비스가 금액 유무로 정한 값이 정본).
    cur.execute(
        "SELECT BENEFIT_ID, BENEFIT_AMT, QUAL_YN, NOTE_CTNT FROM TCOMPANY_BENEFIT WHERE BADGE_CD <> %s",
        (MEMBER_BADGE_CD,),
    )
    rows = cur.fetchall()
    amt_source_counts = {"stated": 0, "estimated": 0, "none": 0}
    for benefit_id, amt, qual_yn, note in rows:
        src = derive_amt_source(amt, bool(qual_yn), note)
        amt_source_counts[src] += 1
        cur.execute(
            "UPDATE TCOMPANY_BENEFIT SET AMT_SOURCE_CD=%s WHERE BENEFIT_ID=%s AND BADGE_CD <> %s",
            (src, benefit_id, MEMBER_BADGE_CD),
        )

    # (2b M-4 앵커 강등은 2026-09-28 폐기 — 모듈 머리말.)

    stats["amt_source"] = amt_source_counts

    # 3) 출처유형·URL + 4) 신선도·만료(균일 18개월, DG-1) — 회사 단위 프로버넌스 전파.
    #    재직자 행 제외 — 출처는 'user_report', 신선도는 편집 시각(+18개월)이 정본이다.
    prov = _parse_provenance(BENEFIT_SQL_DIR)
    cur.execute("SELECT COMP_ID, COMP_ENG_NM FROM TCOMPANY")
    verified_n = 0
    for comp_id, eng in cur.fetchall():
        p = prov.get(eng)
        if not p:
            continue
        if p["url"]:
            badge_src_cd, badge_src_url = "scrape_official", p["url"]
        else:
            badge_src_cd, badge_src_url = "ai_parse", None
        verified_dtm = f"{p['scraped_at']} 00:00:00"
        cur.execute(
            """
            UPDATE TCOMPANY_BENEFIT
               SET BADGE_SRC_CD=%s, BADGE_SRC_URL_CTNT=%s,
                   VERIFIED_DTM=%s, EXPIRES_DTM=DATE_ADD(%s, INTERVAL %s MONTH)
             WHERE COMP_ID=%s AND BADGE_CD <> %s
            """,
            (badge_src_cd, badge_src_url, verified_dtm, verified_dtm, TTL_MONTHS_UNIFORM, comp_id,
             MEMBER_BADGE_CD),
        )
        verified_n += cur.rowcount

    stats["verified"] = verified_n
    stats["expires"] = verified_n
    return stats
