"""generator/indexnow.py — 바뀐 URL 을 검색엔진에 **먼저** 알린다 (IndexNow, 2026-08-29).

왜 있는가. 검색엔진이 알아서 들를 때까지 기다리면 네이버 봇은 하루 3~9 페이지, 구글은 15일에
1 페이지를 본다(nginx 로그 실측 8/15~8/29). 페이지 하나를 고쳐도 검색엔진이 그걸 아는 데 몇 주가
걸린다. IndexNow 는 반대 방향이다 — 우리가 "이 주소들이 방금 바뀌었다"고 POST 하면 참여 엔진
(빙·네이버 서치어드바이저·얀덱스·Seznam)이 곧 가져간다. `api.indexnow.org` 한 곳에 보내면 참여
엔진 전부에 전달된다.

⚠ **구글은 IndexNow 를 받지 않는다.** 구글 쪽 크롤 예산은 외부 링크와 Search Console 색인
   요청이 움직인다. 이 모듈은 네이버·빙 몫이다.

무엇을 보내는가 — `release.lastmod_index` 가 `changed=True` 로 판정한 URL 만. "전부 바뀜"을 매번
보내면 사이트맵에 매번 오늘을 찍던 것과 같은 짓이다(신호가 소음이 된다). 한 요청에 10,000 URL
까지라 우리 규모(≈115)는 한 번이면 된다.

**실패해도 빌드는 실패하지 않는다.** 통보는 배포 뒤의 부가 동작이고, 검색엔진 API 가 죽었다고
라이브 반영을 되돌릴 이유가 없다. 대신 결과(상태 코드·건수·오류)를 **반드시 stderr 에 찍는다** —
조용히 실패하면 "왜 네이버가 안 오지"를 아무도 모른다.

키 검증: 엔진은 `keyLocation` 의 파일을 직접 읽어 내용이 `key` 와 같은지 본다. 그 파일은
`pages/sitemap.render_indexnow_key` 가 dist 에 만들고 nginx `location = /indexnow-key.txt` 가
서빙한다. 따라서 **키 파일이 라이브가 된 뒤(스왑 뒤)** 에 보내야 한다 — 먼저 보내면 엔진이 키를
못 찾아 403 을 주고, 그 실패는 재시도해도 같다.
"""
from __future__ import annotations

import json
import sys
import urllib.error
import urllib.parse
import urllib.request

ENDPOINT = "https://api.indexnow.org/indexnow"
MAX_URLS = 10_000  # 규격 상한(요청당)
USER_AGENT = "loupit-indexnow/1.0"


def submit(urls: list[str], *, host: str, key: str, key_location: str,
           opener=urllib.request.urlopen, timeout: float = 15.0, endpoint: str = ENDPOINT) -> dict:
    """바뀐 URL 목록을 IndexNow 로 통보하고 결과를 dict 로 돌려준다. **예외를 밖으로 내지 않는다.**

    반환 `{"sent": n, "status": int|None, "ok": bool, "error": str|None}`.
    `ok` = 200(처리) 또는 202(접수). 그 밖의 상태·전송 오류는 `ok=False` 에 사유를 담는다.
    빈 목록은 요청 없이 `sent=0, ok=True` — 보낼 것이 없는 것은 실패가 아니다.
    `opener` 는 테스트 주입점이다(실 엔진을 두드리는 테스트는 없어야 한다).
    """
    urls = list(dict.fromkeys(u for u in urls if u))  # 중복 제거, 순서 유지
    if not urls:
        return {"sent": 0, "status": None, "ok": True, "error": None}
    if len(urls) > MAX_URLS:
        # 규격 상한. 우리 규모에선 닿지 않지만, 닿는 날 조용히 잘리면 뒤쪽 URL 은 영영 통보되지 않는다.
        return {"sent": 0, "status": None, "ok": False,
                "error": f"URL {len(urls)}개 — 요청당 상한 {MAX_URLS} 초과(나눠 보내도록 고쳐라)"}
    if not host or not key:
        return {"sent": 0, "status": None, "ok": False, "error": "host 또는 key 가 비어 있다"}

    body = json.dumps({"host": host, "key": key, "keyLocation": key_location, "urlList": urls},
                      ensure_ascii=False).encode("utf-8")
    req = urllib.request.Request(endpoint, data=body, method="POST", headers={
        "Content-Type": "application/json; charset=utf-8",
        "User-Agent": USER_AGENT,
    })
    try:
        with opener(req, timeout=timeout) as resp:  # noqa: S310 — 고정 https 엔드포인트
            status = int(getattr(resp, "status", None) or resp.getcode())
    except urllib.error.HTTPError as exc:
        # 4xx 는 우리 쪽 문제다(키 불일치 403 · 형식 422 · 호스트 불일치 등). 상태를 그대로 올린다.
        return {"sent": len(urls), "status": exc.code, "ok": False, "error": f"HTTP {exc.code}: {exc.reason}"}
    except Exception as exc:  # noqa: BLE001 — 전송 계층 전부: 빌드를 죽이지 않는다
        return {"sent": len(urls), "status": None, "ok": False, "error": f"{type(exc).__name__}: {exc}"}
    return {"sent": len(urls), "status": status, "ok": status in (200, 202), "error": None}


def notify_changed(index: dict[str, dict], *, site_origin: str, key: str, key_path: str,
                   opener=urllib.request.urlopen, log=None) -> dict:
    """`lastmod_index` 결과에서 바뀐 URL 만 골라 보낸다. 항상 한 줄을 `log`(기본 stderr)에 남긴다.

    `log` 기본값을 시그니처에 `sys.stderr` 로 묶지 않는 이유: 그러면 임포트 시점의 stderr 객체가
    고정돼, pytest 의 capsys 처럼 stderr 를 바꿔 끼우는 도구가 이 출력을 못 본다.
    """
    log = log if log is not None else sys.stderr
    changed = [u for u, v in index.items() if v.get("changed")]
    host = urllib.parse.urlparse(site_origin).netloc
    key_location = f"{site_origin}/{key_path}"
    result = submit(changed, host=host, key=key, key_location=key_location, opener=opener)
    if result["sent"] == 0 and result["ok"]:
        print("generator build: IndexNow — 바뀐 URL 0개, 통보 생략", file=log)
    elif result["ok"]:
        print(f"generator build: IndexNow — {result['sent']}개 URL 통보, HTTP {result['status']}", file=log)
    else:
        print(f"generator build: IndexNow 실패 — {result['sent']}개 URL, {result['error']} "
              f"(빌드는 성공 — 통보만 안 됐다)", file=log)
    return result
