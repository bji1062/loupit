"""SP-SEED-5 — job_change 96개 복지 SQL → loupit 95개로 재이식.

규칙(SP-SEED-1·5, SPEC/03):
- `모비스.sql` 은 재이식 제외(현대모비스와 동일 실체, 중복 제거).
- `CJ.sql` 은 등록명 리터럴만 교정(`CJ그룹`→`CJ올리브네트웍스`), `eng_nm='cj'`는 유지.
- 그 외 94개는 바이트 무변경 복사(헤더 출처/URL은 백필 프로버넌스 소스이므로 보존).

/home/ubuntu/job_change 는 읽기 전용 소스(원본 편집 금지) — 이 스크립트는 읽기만 한다.
"""

from __future__ import annotations

import re
from pathlib import Path

SRC = Path("/home/ubuntu/job_change/server/seed/benefit/sql")
DST = Path(__file__).resolve().parent / "benefit" / "sql"

SKIP_FILES = {"모비스.sql"}  # SP-SEED-1.2 중복 제거(현대모비스로 흡수)
CJ_FILE = "CJ.sql"


def replace_company_nm(text: str, old: str = "CJ그룹", new: str = "CJ올리브네트웍스") -> str:
    """자기등록 튜플의 두 번째 리터럴(정식명)만 교정한다.

    앵커: `VALUES ('cj', 'CJ그룹',` — eng_nm='cj' 리터럴은 그대로 두고
    바로 뒤따르는 정식명 리터럴만 치환한다(SP-SEED-5.1).
    """
    pattern = re.compile(r"(VALUES \('cj', ')" + re.escape(old) + r"(',)")
    new_text, n = pattern.subn(r"\g<1>" + new + r"\g<2>", text)
    if n == 0:
        raise ValueError(f"CJ 등록명 교정 앵커를 찾지 못함(예상 리터럴 불일치): old={old!r}")
    return new_text


def reingest() -> int:
    """SRC/*.sql(96개) → DST/*.sql(95개) 재이식. 반환값 = 생성된 파일 수."""
    DST.mkdir(parents=True, exist_ok=True)
    # 이전 실행 잔존분 정리(재실행 멱등 — 소스 삭제/이름변경 반영)
    for f in DST.glob("*.sql"):
        f.unlink()

    src_files = sorted(SRC.glob("*.sql"))
    written = 0
    for f in src_files:
        if f.name in SKIP_FILES:
            continue
        text = f.read_text(encoding="utf-8")
        if f.name == CJ_FILE:
            text = replace_company_nm(text)
        (DST / f.name).write_text(text, encoding="utf-8")
        written += 1

    assert written == 95, f"재이식 결과 파일 수 불일치: {written} (기대 95)"
    return written


if __name__ == "__main__":
    n = reingest()
    print(f"reingest done: {n} files -> {DST}")
