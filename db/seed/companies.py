"""SP-SEED-6.3 — 회사 메타(별칭·근무형태) 적용.

`company_meta.build_company_meta()`가 만든 레지스트리를 실제 DB 행에 적용한다.
복지 SQL(단계3)이 먼저 회사를 자기등록한 뒤 실행되어야 `eng_nm` 조회가 성립한다.
"""

from __future__ import annotations

import json
import logging

log = logging.getLogger(__name__)


def apply_company_meta(cur, meta: dict) -> dict:
    """meta(dict) 를 TCOMPANY_ALIAS INSERT + TCOMPANY.WORK_STYLE_VAL UPDATE로 반영.

    멱등: 별칭은 `uq_comp_alias`로 INSERT IGNORE, WORK_STYLE_VAL은 값 고정 UPDATE.
    반환: {"aliases_applied": n, "skipped": [eng,...]} — 로그/테스트용 통계.
    """
    cur.execute("SELECT COMP_ID, COMP_ENG_NM FROM TCOMPANY")
    id_of = {eng: cid for cid, eng in cur.fetchall()}

    alias_count = 0
    skipped: list[str] = []
    for eng, m in meta.items():
        cid = id_of.get(eng)
        if not cid:
            skipped.append(eng)
            log.warning("meta skip: eng=%s not registered (복지 SQL 미로드/eng 불일치)", eng)
            continue
        for alias in m["aliases"]:
            cur.execute(
                "INSERT IGNORE INTO TCOMPANY_ALIAS (COMP_ID, ALIAS_NM) VALUES (%s,%s)",
                (cid, alias),
            )
            alias_count += 1
        cur.execute(
            "UPDATE TCOMPANY SET WORK_STYLE_VAL=%s WHERE COMP_ID=%s",
            (json.dumps(m["work_style"], ensure_ascii=False), cid),
        )
        industry_override = m.get("industry_override")
        if industry_override:
            cur.execute(
                "UPDATE TCOMPANY SET INDUSTRY_NM=%s WHERE COMP_ID=%s",
                (industry_override, cid),
            )

    return {"aliases_applied": alias_count, "skipped": skipped}
