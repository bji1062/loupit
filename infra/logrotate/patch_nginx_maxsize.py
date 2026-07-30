#!/usr/bin/env python3
"""`/etc/logrotate.d/nginx` 에 크기 상한 한 줄을 **멱등** 삽입한다 (P3-④).

왜 통째로 배포하지 않고 패치인가
--------------------------------
이 파일은 `nginx-common` 패키지의 conffile 이다. 리포의 사본으로 덮어쓰면 상류가
회전 정책을 고쳐도 우리 사본에 얼어붙어 영영 못 받는다. 우리가 원하는 변경은
**한 줄**뿐이므로, 나머지는 패키지에 맡기고 그 한 줄만 끼운다.

왜 크기 상한이 필요한가
-----------------------
`daily` 만 있으면 회전 판정이 **시각**으로만 이뤄진다. 트래픽 급증이나 스캐너
공격이 하루 안에 로그를 수 기가로 불려도 자정까지 아무도 막지 않는다. `maxsize`
는 "일 주기가 안 됐어도 이 크기를 넘으면 회전한다"를 추가한다.

⚠ logrotate 실행 주기(기본 daily timer)에 걸리므로 **실시간 상한이 아니다.**
   1회 실행 사이에 200M 을 크게 초과할 수 있다. 상한이 아니라 완충이다.

⚠ 백업 사본을 `/etc/logrotate.d/` **안에** 두지 마라
   logrotate 는 그 디렉터리의 모든 파일을 읽고, 기본 taboo 확장자는 `.bak` 등
   고정 목록이라 `nginx.bak-20260730` 같은 이름은 걸러지지 않는다. 같은 글롭이
   두 번 등록돼 `duplicate log entry` 로 **전체 파싱이 깨진다**(2026-07-30 실발현).
   그래서 백업은 `/var/backups/loupit-config/` 로 뺀다.
"""

from __future__ import annotations

import re
import shutil
import sys
from pathlib import Path

TARGET = Path("/etc/logrotate.d/nginx")
BACKUP_DIR = Path("/var/backups/loupit-config")

MAXSIZE = "200M"

# 배포본과 리포가 어긋나지 않도록 삽입 블록을 여기 한 곳에서만 정의한다.
BLOCK = (
    "\t# P3-④(2026-07-30): daily 만으론 트래픽 급증·공격 시 하루치가 디스크를 채운다.\n"
    "\t# 200M 을 넘으면 일 주기를 기다리지 않고 회전한다(logrotate 실행 주기에 한해).\n"
    f"\tmaxsize {MAXSIZE}\n"
)

ANCHOR = "\tdaily\n"


def patch(text: str) -> str:
    """`daily` 바로 뒤에 블록을 끼운 문자열을 돌려준다. 이미 있으면 그대로."""
    if re.search(r"^\s*maxsize\s", text, re.MULTILINE):
        return text
    if ANCHOR not in text:
        raise SystemExit(
            f"중단: {TARGET} 에서 '{ANCHOR.strip()}' 앵커를 찾지 못했다. "
            "패키지가 구조를 바꿨을 수 있으니 수동 확인하라."
        )
    return text.replace(ANCHOR, ANCHOR + BLOCK, 1)


def main() -> int:
    if not TARGET.exists():
        print(f"  건너뜀: {TARGET} 없음(nginx 미설치?)")
        return 0

    original = TARGET.read_text()
    patched = patch(original)
    if patched == original:
        print(f"  이미 적용됨: {TARGET} (maxsize 존재)")
        return 0

    BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    backup = BACKUP_DIR / "logrotate.d-nginx.orig"
    if not backup.exists():  # 최초 원본만 보존한다(재실행이 원본을 덮어쓰면 안 된다)
        shutil.copy2(TARGET, backup)
    TARGET.write_text(patched)
    print(f"  적용: {TARGET} 에 maxsize {MAXSIZE} 삽입 (원본 → {backup})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
