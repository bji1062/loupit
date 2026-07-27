"""T-13.2.2 테스트 스키마 격리 계약 — `db/schema.sql` 의 모든 테이블이 격리 사이클 안에 있는가.

**막으려는 회귀(2026-07-27 발견)**: `schema_db` 픽스처는 `_drop_all_tables()`(=
`TABLE_DROP_ORDER + REMOVED_TABLES`) 로 지운 뒤 `apply_sql(schema.sql)` 로 재생성한다.
그런데 SC14 참여 7테이블은 **schema.sql 에는 있고 두 목록 어디에도 없었다** — 즉 생성만 되고
영원히 안 지워졌다. 결과:

  1. 세션 간 행 잔존 — 한 실행이 쓴 회원·세션·편집이력이 다음 실행에 그대로 남는다.
  2. **고아 FK(#15 동형)** — `TCOMPANY` 는 DROP/CREATE 되어 `COMP_ID` AUTO_INCREMENT 가 1부터
     재배정되는데, 살아남은 `TBENEFIT_EDIT_LOG`·`TEMPLOY_VERIFICATION` 행은 옛 `COMP_ID` 를
     들고 있어 **무결성 오류 없이 다른 회사로 재해석**된다. `TCOMPARE_LOG` 가 정확히 이 이유로
     `_truncate_compare_log()` 를 얻었다(load.py) — 참여 테이블은 그 처방을 못 받았다.

그래서 계약을 "참여 테이블도 목록에 넣었나"가 아니라 **"schema.sql 의 모든 테이블이 격리
사이클에 있나"** 로 일반화한다 — 앞으로 테이블을 추가할 때 같은 실수를 자동으로 잡는다.

무 DB 테스트 — schema.sql 텍스트와 conftest 상수만 본다. 세션 스코프 픽스처(seeded_db)를
건드리지 않으려고 의도적으로 DDL 을 실행하지 않는다.
"""
from __future__ import annotations

import re

from server.tests.conftest import (
    PARTICIPATION_CREATE_ORDER,
    REMOVED_TABLES,
    SCHEMA_SQL,
    TABLE_CREATE_ORDER,
    TABLE_DROP_ORDER,
)

_CREATE_RE = re.compile(r"CREATE\s+TABLE\s+IF\s+NOT\s+EXISTS\s+(T[A-Z0-9_]+)", re.IGNORECASE)
_FK_RE = re.compile(r"REFERENCES\s+(T[A-Z0-9_]+)", re.IGNORECASE)


def _schema_tables() -> list[str]:
    """schema.sql 이 실제로 만드는 테이블(정의 순서)."""
    return _CREATE_RE.findall(SCHEMA_SQL.read_text(encoding="utf-8"))


def _fk_parents() -> dict[str, set[str]]:
    """테이블 → FK 부모 집합(자기참조 제외)."""
    text = SCHEMA_SQL.read_text(encoding="utf-8")
    blocks = re.split(r"(?=CREATE\s+TABLE\s+IF\s+NOT\s+EXISTS\s+T)", text, flags=re.IGNORECASE)
    parents: dict[str, set[str]] = {}
    for b in blocks:
        m = _CREATE_RE.match(b)
        if not m:
            continue
        name = m.group(1).upper()
        parents[name] = {p.upper() for p in _FK_RE.findall(b)} - {name}
    return parents


def test_SI1_every_schema_table_is_in_isolation_cycle():
    """schema.sql 이 만드는 모든 테이블은 DROP 목록에 있어야 한다(격리 사이클 완결).

    빠진 테이블은 '생성만 되고 안 지워지는' 상태가 되어 세션 간 행이 잔존한다."""
    covered = set(TABLE_DROP_ORDER) | set(REMOVED_TABLES)
    missing = [t for t in _schema_tables() if t.upper() not in {c.upper() for c in covered}]
    assert not missing, (
        f"schema.sql 이 만들지만 격리 DROP 대상이 아닌 테이블: {missing} — "
        "TABLE_CREATE_ORDER 에 추가하라(세션 간 행 잔존·고아 FK 위험)"
    )


def test_SI2_participation_tables_are_in_create_order():
    """SC14 참여 7테이블이 활성 생성순서에 편입되어 있다(T-13.2.2).

    구 판본은 `PARTICIPATION_CREATE_ORDER` 를 inert 상수로만 뒀다 — 그때는 schema.sql 에
    DDL 이 없어 정당했으나, DDL 이 들어온 뒤(SP-DB-17) 이 목록이 죽은 채로 남아 간극이 됐다."""
    missing = [t for t in PARTICIPATION_CREATE_ORDER if t not in TABLE_CREATE_ORDER]
    assert not missing, f"참여 테이블이 TABLE_CREATE_ORDER 에 미편입: {missing}"


def test_SI3_participation_tables_not_in_removed():
    """참여 테이블은 '제거 테이블'이 아니다 — SP-DB-17 이 신규 소유(SC-6 FK→REMOVED 0건)."""
    overlap = sorted(set(PARTICIPATION_CREATE_ORDER) & set(REMOVED_TABLES))
    assert not overlap, f"참여 테이블이 REMOVED_TABLES 에 잔존: {overlap}"


def test_SI4_create_order_respects_fk_parents():
    """생성순서가 FK 부모→자식이다 — 부모가 자식보다 먼저 나와야 CREATE 가 성공한다."""
    parents = _fk_parents()
    position = {t.upper(): i for i, t in enumerate(TABLE_CREATE_ORDER)}
    violations = []
    for child, ps in parents.items():
        if child not in position:
            continue
        for parent in ps:
            if parent in position and position[parent] > position[child]:
                violations.append(f"{child}(#{position[child]}) → 부모 {parent}(#{position[parent]})")
    assert not violations, f"FK 부모가 자식보다 뒤에 생성됨: {violations}"


def test_SI5_drop_order_is_exact_reverse():
    """DROP 순서 = CREATE 역순(자식→부모). FOREIGN_KEY_CHECKS=0 와 무관하게 계약으로 고정."""
    assert TABLE_DROP_ORDER == list(reversed(TABLE_CREATE_ORDER))


def test_SI6_no_duplicates_in_create_order():
    """중복 등록 금지 — 병합 시 실수로 두 번 넣으면 DROP/CREATE 가 두 번 돈다."""
    assert len(TABLE_CREATE_ORDER) == len(set(TABLE_CREATE_ORDER)), (
        f"TABLE_CREATE_ORDER 중복: {TABLE_CREATE_ORDER}"
    )
