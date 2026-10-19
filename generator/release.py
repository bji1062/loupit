"""generator/release.py — 릴리스 플로우: 해시·gzip·검증 게이트·원자적 스왑
(SP-GEN-10·11). 실패 시 이전 산출물 유지(무중단 지향, SP-ARCH-9).
"""
from __future__ import annotations

import gzip as gzip_module
import hashlib
import json
import os
import re
import shutil
from datetime import datetime, timezone

from generator.checks import run_generated_checks
from generator.context import Page

_COMPRESSIBLE_EXT = (".html", ".xml", ".txt")
_MANIFEST_NAME = ".manifest.json"


def _is_compressible(path: str) -> bool:
    return path.endswith(_COMPRESSIBLE_EXT)


def _ensure_parent(path: str) -> None:
    parent = os.path.dirname(path)
    if parent:
        os.makedirs(parent, exist_ok=True)


def _reset_dir(path: str) -> None:
    if os.path.exists(path):
        shutil.rmtree(path)
    os.makedirs(path, exist_ok=True)


def _write_bytes(path: str, data: bytes) -> None:
    _ensure_parent(path)
    with open(path, "wb") as f:
        f.write(data)


def _copy(src: str, dst: str) -> None:
    _ensure_parent(dst)
    shutil.copyfile(src, dst)


def _gzip_if_smaller(target: str, data: bytes) -> int | None:
    """`.gz` 사전압축(level 9). 원본보다 크면 생략(gzip_static, §8)."""
    compressed = gzip_module.compress(data, compresslevel=9)
    if len(compressed) >= len(data):
        return None
    with open(target + ".gz", "wb") as f:
        f.write(compressed)
    return len(compressed)


def _read_manifest(out_dir: str) -> dict:
    manifest_path = os.path.join(out_dir, _MANIFEST_NAME)
    if not os.path.exists(manifest_path):
        return {}
    with open(manifest_path, encoding="utf-8") as f:
        return json.load(f)


def _load_manifest(out_dir: str) -> dict:
    return _read_manifest(out_dir).get("files", {})


def _sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


# lastmod 지문 방식 버전 — 지문을 계산하는 방법이 바뀌면 올린다(`lastmod_index` 의 이관 규칙 참고).
#   1(표시 없음) = 페이지 HTML 전체의 sha256 · 2 = `_content_fingerprint`(main 안, skip 구간 제외)
LASTMOD_SCHEME = 2

_MAIN_RE = re.compile(r"<main\b.*?</main>", re.DOTALL)
_SKIP_RE = re.compile(r"<!--lm:skip-->.*?<!--/lm:skip-->", re.DOTALL)


def _content_fingerprint(html: str) -> str:
    """페이지의 **자기 내용** 지문 — sitemap lastmod · IndexNow 의 「바뀜」 판정용(2026-10-19).

    왜 HTML 전체가 아닌가 — 회사 페이지에는 **다른 회사에 따라 바뀌는 값**(전체 회사 평균 · 순위 ·
    「등록 N개사」 · 복지별 「이 복지가 있는 회사 N곳」 · 관련 회사 목록)이 박혀 있다. 전체를 해시하면 회사가
    1곳만 늘어도 275개 페이지 전부가 「바뀜」이 되어 lastmod 가 전부 같은 날이 되고(실측 2026-10-18),
    구글은 그런 lastmod 를 믿지 않는다. IndexNow 도 매번 275개를 통보한다.

    규칙: `<main>`…`</main>` 안에서(없으면 HTML 전체) `<!--lm:skip-->`…`<!--/lm:skip-->` 구간을 지운
    나머지의 sha256. head(자산 버전 해시 · 메타) · 헤더 · 푸터는 main 밖이라 빠진다.

    ⚠ skip 표시 계약 — **다른 회사 데이터로 바뀌는 값은 전부 skip 안에, 그 회사 자기 데이터는 skip 밖에
      최소 한 번**. 표시를 지우면 매 공개마다 전 회사 lastmod 가 바뀌고, 자기 값을 skip 에 넣으면 진짜로
      바뀐 날을 놓친다. 표시는 템플릿에 있다(`_stat_card.html` · `_benefit_table.html` · `company.html`).
    """
    m = _MAIN_RE.search(html)
    body = m.group(0) if m else html
    return _sha256(_SKIP_RE.sub("", body).encode("utf-8"))


def lastmod_index(out_dir: str, pages: list[Page], extra_sources: dict[str, str | None],
                  today: str) -> dict[str, dict]:
    """sitemap 에 실을 URL 마다 **내용이 실제로 바뀐 날**을 정한다(2026-08-29, 크롤 예산 대응).

    반환: `{url: {"sha256", "lastmod", "changed"}}`.

    왜 필요한가 — 이전 빌드는 매번 113개 URL 전부에 **오늘** 날짜를 찍었다. 실제로는 회사 페이지
    102개만 바뀌고 처리방침은 몇 주째 그대로인데도. 구글은 lastmod 가 내용과 무관하게 계속 바뀌는
    사이트맵을 몇 번 보면 그 날짜를 **무시한다**(공식 문서). 그러면 진짜로 바뀐 날에도 안 믿는다.
    Search Console 실측(2026-08-29): 사이트맵 111 URL 발견 · "발견됨-미색인" 다수 · 28일 노출 5.

    규칙은 지문(sha256) 하나다: 이전 매니페스트(`urls`)에 같은 지문이 있으면 **그때의 날짜를 그대로**,
    지문이 다르거나 처음 보는 URL 이면 `today`. 빌드가 결정적이어야 성립한다 — 같은 데이터로 두 번
    빌드해 115/115 해시가 같은 것을 확인했다(HTML 에 빌드 시각을 박지 않는다).

    `extra_sources` 는 생성기가 만들지 않는 URL(대문·커뮤니티 허브 = SPA 셸)의 원본 파일 경로다.
    파일이 있으면 그 바이트를 지문으로 쓰고, 없으면(테스트·다른 out_dir) 지문 없이 `today` 다 —
    있지도 않은 파일의 날짜를 지어내지 않는다.

    ⚠ 이 함수는 **스왑 전**에 부른다(sitemap 을 그리려면 날짜가 먼저 있어야 한다). 그래서 이전
      매니페스트는 아직 `out_dir` 에 있는 **직전 빌드의 것**이다.
    ⚠ 첫 실행(이전 매니페스트에 `urls` 없음)은 전부 `today` 가 된다 — 한 번은 피할 수 없다.

    페이지 지문은 HTML 전체가 아니라 `_content_fingerprint`(자기 내용만)다. `extra_sources`(SPA 셸 원본)는
    기존대로 바이트 그대로다.

    ⚠ 방식 전환 이관(1회) — 직전 매니페스트의 `lastmod_scheme` 이 지금(`LASTMOD_SCHEME`)과 다르면(없음
      포함) 지문을 비교하지 않고 **직전 lastmod 를 그대로 두고 새 지문만 받아들인다**(`changed=False`).
      옛 방식은 「더 자주 바뀜」으로만 틀렸으므로 직전 날짜는 실제 마지막 변경일보다 늦거나 같다 — 미래를
      지어내지 않는다. 직전에 없던 URL 은 기존대로 `today`. 그래서 이 방식을 싣는 배포는 **데이터 변경
      없이 단독으로** 해야 한다(같이 실으면 그 변경이 이관에 먹혀 lastmod 에 안 드러난다).
    """
    prev_manifest = _read_manifest(out_dir)
    prev = prev_manifest.get("urls", {})
    migrating = prev_manifest.get("lastmod_scheme") != LASTMOD_SCHEME
    out: dict[str, dict] = {}

    def _entry(url: str, digest: str | None) -> dict:
        before = prev.get(url) or {}
        if migrating and digest and before.get("lastmod"):
            return {"sha256": digest, "lastmod": before["lastmod"], "changed": False}
        if digest and before.get("sha256") == digest and before.get("lastmod"):
            return {"sha256": digest, "lastmod": before["lastmod"], "changed": False}
        return {"sha256": digest, "lastmod": today, "changed": True}

    for pg in pages:
        if pg.in_sitemap:
            out[pg.url] = _entry(pg.url, _content_fingerprint(pg.html))
    for url, src in extra_sources.items():
        digest = None
        if src and os.path.isfile(src):
            with open(src, "rb") as f:
                digest = _sha256(f.read())
        out[url] = _entry(url, digest)
    return out


def _atomic_swap(out_dir: str, next_dir: str) -> None:
    """`os.replace` 2단 디렉토리 rename — prev 백업 → next 승격(SP-ARCH-9)."""
    prev_dir = out_dir + ".prev"
    if os.path.exists(out_dir):
        if os.path.exists(prev_dir):
            shutil.rmtree(prev_dir)
        os.replace(out_dir, prev_dir)
    os.replace(next_dir, out_dir)


def stage_and_swap(out_dir: str, pages: list[Page], *, incremental: bool = False, gzip: bool = True) -> dict:
    """스테이징 → gzip → 해시 매니페스트 → 검증 게이트 → 원자적 스왑 (SP-GEN-11.1).

    검증(`run_generated_checks`) 실패 시 예외가 전파되고 `{out_dir}`는
    변경되지 않는다(스왑 미실행, GC-25).
    """
    nxt = out_dir + ".next"
    _reset_dir(nxt)
    prev_manifest = _load_manifest(out_dir) if incremental else {}
    manifest: dict[str, dict] = {}

    for p in pages:
        target = os.path.join(nxt, p.path)
        data = p.html.encode("utf-8")
        digest = hashlib.sha256(data).hexdigest()
        prev_entry = prev_manifest.get(p.path, {})
        prev_file = os.path.join(out_dir, p.path)
        if incremental and prev_entry.get("sha256") == digest and os.path.exists(prev_file):
            _copy(prev_file, target)  # 변경 없음 → 이전본 복사
        else:
            _write_bytes(target, data)
        gz_size = _gzip_if_smaller(target, data) if gzip and _is_compressible(p.path) else None
        manifest[p.path] = {"sha256": digest, "bytes": len(data), "gz": gz_size}

    run_generated_checks(nxt, pages)  # SP-GEN-12 게이트 — 실패 시 예외 전파, 스왑 중단
    _atomic_swap(out_dir, nxt)
    return manifest


def write_manifest(out_dir: str, manifest: dict, urls: dict | None = None) -> None:
    """`.manifest.json` 기록 — 증분·릴리스 검증용(gitignore 대상).

    `urls` 는 `lastmod_index` 의 결과다. 다음 빌드가 "무엇이 바뀌었는지"를 알려면 **이번 빌드의
    지문과 날짜**가 여기 남아 있어야 한다 — 안 남기면 매번 첫 실행처럼 전부 오늘이 된다.
    """
    payload = {
        "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "files": manifest,
        "lastmod_scheme": LASTMOD_SCHEME,
        "urls": {u: {"sha256": v.get("sha256"), "lastmod": v["lastmod"]} for u, v in (urls or {}).items()},
    }
    _ensure_parent(os.path.join(out_dir, _MANIFEST_NAME))
    with open(os.path.join(out_dir, _MANIFEST_NAME), "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)
