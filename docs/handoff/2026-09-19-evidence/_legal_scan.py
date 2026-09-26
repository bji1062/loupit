#!/usr/bin/env python3
"""시드 SQL 의 사용자 노출 필드를 법정 제도 문구·편집 주석 검출어로 전수 스캔한다.

왜: 웨이브 3 에서 회사별 적대 검증이 전부 통과시킨 뒤, 횡단 감사의 기계 스윕이
「본인/배우자 태아 검진 휴가」(근로기준법 74조의2) 1행을 잡아냈다(BLOCK B-3).
사람이 행을 읽는 것과 검출어로 훑는 것은 다른 일이다 — 검증자도 이걸 돌린다.

사용법:  python3 docs/handoff/2026-09-19-evidence/_legal_scan.py <파일.sql> [...]
출력:    파일 · SORT · 코드 · 필드 · 검출어 · 문장
판정은 사람이 한다. 원문이 법정분과 회사 상회분을 스스로 나눠 밝힌 경우만 예외다.
⚠ 「반차」·「반반차」·시간 단위 연차 검출은 단서일 뿐 법정이 아니다 — 법정 연차를 쓰더라도
   그렇게 쪼개 쓰게 해주는 회사가 소수라 제도 자체가 복지다(사용자 결정 2026-09-20).
"""
import re
import sys

LEGAL_TERMS = [
    "법정", "시차 출근", "시차출근", "시차출퇴근", "시차 출퇴근",
    "난임 휴가", "난임휴가", "난임치료휴가",
    # 법정 문구 정리(2026-09-20)가 찾아낸 구멍 — 「연차」라는 낱말 없이 연차를 쪼개 쓰는 표기
    "반차", "반반차", "보건휴가", "연차촉진",
    "근로자의 날", "근로자의날", "노동절",
    # 웨이브 4 검증이 찾아낸 구멍 — 붙여쓴 표기와 다른 법률의 사업주 의무
    "보호구", "산업안전보건", "산업재해", "보상휴가", "직무발명",
    # 재수집 R-1 감사가 찾아낸 구멍(2026-09-26) — 고령자고용법 제21조의3: 피보험자 1,000명 이상 사업주는
    #   50세 이상 비자발적 이직예정자에게 재취업지원서비스(진로설계·취업 알선·재취업·창업 교육)를 줘야 한다.
    #   수집기마다 갈렸다(LIG 넣음·롯데 뺌). 남기는 것은 법 위에 얹은 부분뿐 — 대상 확대(재직 중 상시·
    #   50세 미만)·유급 휴가·퇴직 후 혜택·기념품·행사. 「재취업」은 그런 상회분 문장에도 나오므로 판정은 사람이 한다.
    "재취업", "전직 지원", "전직지원", "전직 프로그램", "전직 컨설팅", "전직 교육",
    #   법령이 서비스를 부르는 이름(법 21조의3 ① · 시행령 14조의4 ①)도 잡는다. 「전직」 한 낱말은 「전직원」에 걸리고
    #   「창업」은 사내 벤처 · 휴직 창업(복지)에 걸려 넣지 않는다. 지금 허용된 검출 행 = 현대자동차 SORT 82(재직 중 상시
    #   + 퇴직 후 1년) · 효성중공업 SORT 61(만 50세 이상 재직자 전체 — 대상 확대)
    "진로설계", "진로 설계", "생애설계", "생애 설계", "노후설계", "노후 설계", "취업알선", "취업 알선", "아웃플레이스먼트",
    "출산휴가", "출산 휴가", "출산전후", "출산 전후", "산전후", "배우자 출산", "육아휴직", "육아 휴직",
    "육아기", "임신기", "가족돌봄", "가족 돌봄", "4대", "사회보험", "퇴직연금", "퇴직금", "연차",
    "주5일", "주 5일", "태아 검진", "태아검진", "유산", "사산", "수유", "모성보호", "근로기준법",
]
# 검출어가 걸려도 **이 표기면 법정이 아니다.** 법은 시간·휴가를 시키지 시설을 시키지 않는다.
#   「수유」는 근로기준법 75조(육아 시간)를 잡으려고 넣은 낱말인데, 「수유실」은 회사가 만든 방이라
#   복지다. 문안을 「모유수유 공간」으로 바꿔도 「수유」가 그대로 들어 있어 소용이 없다(2026-09-21 실측)
#   — 고쳐야 하는 건 글이 아니라 이 검사기다.
#   면제는 **숨기지 않는다**: 아래 main() 이 「면제 n건」으로 따로 세어 보여주므로 사람이 확인할 수 있다.
EXEMPT = {
    "수유": ("수유실", "수유 공간", "수유룸", "모유수유 공간", "수유시설", "수유 시설"),  # 시설 표기(2026-09-26 SKT·SK하이닉스)
}

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
    hits, exempted, rows = [], [], 0
    for m in ROW.finditer(sql):
        rows += 1
        cd, nm, _amt, note, qual, sort = m.groups()
        for field, text in (("NM", nm.replace("''", "'")), ("NOTE", unq(note)), ("QUAL", unq(qual))):
            for kind, terms in (("법정", LEGAL_TERMS), ("편집", EDIT_TERMS)):
                for t in terms:
                    if t not in text:
                        continue
                    if any(e in text for e in EXEMPT.get(t, ())):
                        exempted.append((sort, cd, field, t, text))
                        continue
                    hits.append((sort, cd, field, kind, t, text))
    return rows, hits, exempted


def main(paths):
    total = bad = skipped = 0
    for p in paths:
        rows, hits, exempted = scan(p)
        total += rows
        bad += len(hits)
        skipped += len(exempted)
        print(f"\n=== {p} — 행 {rows} · 검출 {len(hits)}"
              + (f" · 면제 {len(exempted)}" if exempted else ""))
        for sort, cd, field, kind, term, text in sorted(hits, key=lambda h: int(h[0])):
            print(f"  [{kind}] SORT {sort:>3} {cd:<22} {field:<4} 「{term}」  {text[:100]}")
        # 면제는 숨기지 않는다 — 표를 잘못 넓히면 진짜 법정 문구가 조용히 빠진다.
        for sort, cd, field, term, text in sorted(exempted, key=lambda h: int(h[0])):
            print(f"  [면제] SORT {sort:>3} {cd:<22} {field:<4} 「{term}」  {text[:100]}")
    print(f"\n총 행 {total} · 검출 {bad}" + (f" · 면제 {skipped}" if skipped else ""))
    return 1 if bad else 0


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(2)
    sys.exit(main(sys.argv[1:]))
