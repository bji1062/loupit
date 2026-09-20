#!/usr/bin/env python3
"""시드 SQL 의 사용자 노출 필드를 법정 제도 문구·편집 주석 검출어로 전수 스캔한다.

왜: 웨이브 3 에서 회사별 적대 검증이 전부 통과시킨 뒤, 횡단 감사의 기계 스윕이
「본인/배우자 태아 검진 휴가」(근로기준법 74조의2) 1행을 잡아냈다(BLOCK B-3).
사람이 행을 읽는 것과 검출어로 훑는 것은 다른 일이다 — 검증자도 이걸 돌린다.

사용법:  python3 docs/handoff/2026-09-19-evidence/_legal_scan.py <파일.sql> [...]
출력:    파일 · SORT · 코드 · 필드 · 검출어 · 문장
판정은 사람이 한다. 원문이 법정분과 회사 상회분을 스스로 나눠 밝힌 경우만 예외다.
"""
import re
import sys

LEGAL_TERMS = [
    "법정", "시차 출근", "시차출근", "시차출퇴근", "난임 휴가", "난임휴가", "난임치료휴가",
    "근로자의 날", "근로자의날", "노동절",
    # 웨이브 4 검증이 찾아낸 구멍 — 붙여쓴 표기와 다른 법률의 사업주 의무
    "보호구", "산업안전보건", "산업재해", "보상휴가", "직무발명",
    "출산휴가", "출산 휴가", "출산전후", "출산 전후", "산전후", "배우자 출산", "육아휴직", "육아 휴직",
    "육아기", "임신기", "가족돌봄", "가족 돌봄", "4대", "사회보험", "퇴직연금", "퇴직금", "연차",
    "주5일", "주 5일", "태아 검진", "태아검진", "유산", "사산", "수유", "모성보호", "근로기준법",
]
EDIT_TERMS = [
    "코퍼스", "선례", "어휘", "규칙", "수집기", "수집", "검증", "병합", "미수록", "회피", "흡수",
    "정본", "판독", "시드", "SI-B2", "별도 행", "수록", "부연", "우리 판단", "⚠", "분할기",
    "UNIQUE", "행으로", "1행", "AMT", "앵커", "함정", "웨이브", "evidence", "SQL", "환산",
    "추정", "이미지", "교차 확인", "원문에 없", "한 행에", "같은 코드", "단정",
]
ROW = re.compile(
    r"\(\s*@comp_id\s*,\s*'([a-z0-9_]+)'\s*,\s*'((?:[^']|'')*)'\s*,\s*(NULL|[\d.]+)\s*,"
    r"\s*'[a-z_]+'\s*,\s*'[a-z]+'\s*,\s*(NULL|'(?:[^']|'')*')\s*,\s*(?:TRUE|FALSE)\s*,"
    r"\s*(NULL|'(?:[^']|'')*')\s*,\s*(\d+)\s*\)"
)


def unq(s):
    return "" if s == "NULL" else s[1:-1].replace("''", "'")


def scan(path):
    sql = open(path, encoding="utf-8").read()
    sql = re.sub(r"^\s*--.*$", "", sql, flags=re.M)      # 주석은 사용자에게 안 보인다
    hits, rows = [], 0
    for m in ROW.finditer(sql):
        rows += 1
        cd, nm, _amt, note, qual, sort = m.groups()
        for field, text in (("NM", nm.replace("''", "'")), ("NOTE", unq(note)), ("QUAL", unq(qual))):
            for kind, terms in (("법정", LEGAL_TERMS), ("편집", EDIT_TERMS)):
                for t in terms:
                    if t in text:
                        hits.append((sort, cd, field, kind, t, text))
    return rows, hits


def main(paths):
    total = bad = 0
    for p in paths:
        rows, hits = scan(p)
        total += rows
        bad += len(hits)
        print(f"\n=== {p} — 행 {rows} · 검출 {len(hits)}")
        for sort, cd, field, kind, term, text in sorted(hits, key=lambda h: int(h[0])):
            print(f"  [{kind}] SORT {sort:>3} {cd:<22} {field:<4} 「{term}」  {text[:100]}")
    print(f"\n총 행 {total} · 검출 {bad}")
    return 1 if bad else 0


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(2)
    sys.exit(main(sys.argv[1:]))
