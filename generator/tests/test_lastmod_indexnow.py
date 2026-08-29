"""sitemap lastmod 정직성 + IndexNow 통보 (2026-08-29, 크롤 예산 대응).

배경(Search Console·nginx 로그 실측): 사이트맵 111 URL 발견 · "발견됨-미색인" 다수 · 28일 노출 5 ·
진짜 Googlebot 15일간 18건(회사 페이지 1). 그리고 우리 사이트맵은 **매 빌드 113 URL 전부에 오늘**을
찍고 있었다 — 구글이 날짜를 무시하게 만드는 패턴이다.

여기서 못박는 계약:
  1. 내용이 안 바뀐 페이지는 직전 빌드의 lastmod 를 **그대로** 받는다. 바뀐 것만 오늘.
  2. 날짜가 없는 URL 은 조용히 빠지지 않고 **즉시 실패**한다.
  3. IndexNow 는 바뀐 URL 만 보내고, 실패해도 빌드를 죽이지 않으며, 항상 stderr 에 한 줄 남긴다.
  4. 통보는 **라이브 dist 로 빌드할 때만** 나간다 — 테스트·CI·스크래치는 아니다.
  5. 키 파일은 키가 있을 때만 생기고 sitemap 에는 없다.
"""
from __future__ import annotations

import io
import json
import os
import re
import urllib.error

import pytest

from generator import build as build_module
from generator import indexnow
from generator.config import CFG, GenConfig
from generator.context import Page
from generator.pages import sitemap
from generator.release import lastmod_index, write_manifest
from generator.render import make_env


def _page(path: str, html: str, in_sitemap: bool = True) -> Page:
    return Page(path=path, url=f"{CFG.site_origin}/{path.removesuffix('.html')}", html=html,
                title="t", description="d", in_sitemap=in_sitemap)


# ── 1. lastmod 는 지문이 바뀐 날 ────────────────────────────────────────────

def test_unchanged_page_keeps_its_previous_lastmod(tmp_path):
    out = str(tmp_path / "dist")
    a, b = _page("company/a.html", "<h1>A</h1>"), _page("company/b.html", "<h1>B</h1>")
    first = lastmod_index(out, [a, b], {}, "2026-08-01")
    assert {v["lastmod"] for v in first.values()} == {"2026-08-01"}
    assert all(v["changed"] for v in first.values()), "첫 실행은 전부 '바뀜'이다"
    os.makedirs(out)
    write_manifest(out, {}, urls=first)

    b2 = _page("company/b.html", "<h1>B 수정</h1>")
    second = lastmod_index(out, [a, b2], {}, "2026-08-29")
    assert second[a.url] == {"sha256": first[a.url]["sha256"], "lastmod": "2026-08-01", "changed": False}
    assert second[b2.url]["lastmod"] == "2026-08-29" and second[b2.url]["changed"]


def test_new_url_and_removed_url_are_handled(tmp_path):
    out = str(tmp_path / "dist"); os.makedirs(out)
    a = _page("company/a.html", "<h1>A</h1>")
    write_manifest(out, {}, urls=lastmod_index(out, [a], {}, "2026-08-01"))
    c = _page("company/c.html", "<h1>C</h1>")
    idx = lastmod_index(out, [c], {}, "2026-08-29")
    assert list(idx) == [c.url], "사라진 URL 은 색인에 남지 않는다(사이트맵에서도 빠진다)"
    assert idx[c.url]["changed"] and idx[c.url]["lastmod"] == "2026-08-29"


def test_pages_outside_the_sitemap_are_not_indexed(tmp_path):
    out = str(tmp_path / "dist")
    robots = _page("robots.txt", "User-agent: *", in_sitemap=False)
    idx = lastmod_index(out, [robots, _page("company/a.html", "<h1>A</h1>")], {}, "2026-08-29")
    assert robots.url not in idx


def test_extra_url_uses_its_source_file_fingerprint(tmp_path):
    """대문·커뮤니티 허브는 생성물이 아니라 SPA 셸 파일이 원본이다 — 그 파일의 지문을 쓴다."""
    out = str(tmp_path / "dist"); os.makedirs(out)
    shell = tmp_path / "index.html"; shell.write_text("<html>v1</html>", encoding="utf-8")
    url = CFG.site_origin + "/"
    first = lastmod_index(out, [], {url: str(shell)}, "2026-08-01")
    assert first[url]["sha256"] and first[url]["changed"]
    write_manifest(out, {}, urls=first)
    assert lastmod_index(out, [], {url: str(shell)}, "2026-08-29")[url]["lastmod"] == "2026-08-01"
    shell.write_text("<html>v2</html>", encoding="utf-8")
    assert lastmod_index(out, [], {url: str(shell)}, "2026-08-29")[url]["lastmod"] == "2026-08-29"


def test_extra_url_without_a_source_file_is_stamped_today_not_invented(tmp_path):
    """파일이 없으면(테스트·다른 out_dir) 지문 없이 오늘 — 있지도 않은 파일의 날짜를 지어내지 않는다."""
    out = str(tmp_path / "dist"); os.makedirs(out)
    url = CFG.site_origin + "/community/"
    first = lastmod_index(out, [], {url: None}, "2026-08-01")
    assert first[url]["sha256"] is None
    write_manifest(out, {}, urls=first)
    # 지문이 없으니 "같다"고 말할 근거도 없다 → 다음 빌드도 오늘이다(거짓 안정성보다 낫다)
    assert lastmod_index(out, [], {url: None}, "2026-08-29")[url]["lastmod"] == "2026-08-29"


# ── 2. 사이트맵 렌더 ────────────────────────────────────────────────────────

def test_sitemap_writes_a_date_per_url_and_refuses_a_missing_one():
    env = make_env()
    u1, u2 = f"{CFG.site_origin}/company/a", f"{CFG.site_origin}/company/b"
    idx = {u1: {"lastmod": "2026-08-01"}, u2: {"lastmod": "2026-08-29"}}
    xml = sitemap.render_sitemap(env, [u1, u2], idx, CFG).html
    got = dict(re.findall(r"<loc>([^<]+)</loc>\s*<lastmod>([^<]+)</lastmod>", xml))
    assert got == {u1: "2026-08-01", u2: "2026-08-29"}
    with pytest.raises(ValueError, match="lastmod 가 없는 URL"):
        sitemap.render_sitemap(env, [u1, u2, f"{CFG.site_origin}/company/c"], idx, CFG)


def test_sitemap_still_accepts_one_date_for_all(fake_bundle, fake_now):
    """하위 호환 — 문자열 하나면 전 URL 에 같은 날짜(기존 테스트·수동 빌드 경로)."""
    xml = sitemap.render_sitemap(make_env(), [f"{CFG.site_origin}/x", f"{CFG.site_origin}/y"], "2026-07-11", CFG).html
    assert xml.count("<lastmod>2026-07-11</lastmod>") == 2


# ── 3. IndexNow 전송 ────────────────────────────────────────────────────────

class _Resp:
    def __init__(self, status): self.status = status
    def getcode(self): return self.status
    def __enter__(self): return self
    def __exit__(self, *a): return False


def _opener(status=202, raise_exc=None, seen=None):
    def open_(req, timeout=None):
        if seen is not None:
            seen.append((req.full_url, req.get_method(), json.loads(req.data.decode("utf-8")), req.get_header("Content-type")))
        if raise_exc:
            raise raise_exc
        return _Resp(status)
    return open_


def test_submit_posts_the_indexnow_document():
    seen = []
    r = indexnow.submit(["https://jobcho.wiki/company/a", "https://jobcho.wiki/company/a", "https://jobcho.wiki/company/b"],
                        host="jobcho.wiki", key="k" * 32, key_location="https://jobcho.wiki/indexnow-key.txt",
                        opener=_opener(202, seen=seen))
    assert r == {"sent": 2, "status": 202, "ok": True, "error": None}, "중복은 한 번만 보낸다"
    url, method, body, ctype = seen[0]
    assert url == indexnow.ENDPOINT and method == "POST"
    assert ctype.startswith("application/json")
    assert body == {"host": "jobcho.wiki", "key": "k" * 32,
                    "keyLocation": "https://jobcho.wiki/indexnow-key.txt",
                    "urlList": ["https://jobcho.wiki/company/a", "https://jobcho.wiki/company/b"]}


def test_submit_never_raises():
    """검색엔진 API 가 죽었다고 배포를 되돌릴 이유가 없다 — 결과를 돌려주되 던지지 않는다."""
    http403 = urllib.error.HTTPError("u", 403, "Forbidden", {}, None)
    r = indexnow.submit(["https://jobcho.wiki/x"], host="jobcho.wiki", key="k", key_location="l", opener=_opener(raise_exc=http403))
    assert r["ok"] is False and r["status"] == 403 and "403" in r["error"]
    r = indexnow.submit(["https://jobcho.wiki/x"], host="jobcho.wiki", key="k", key_location="l", opener=_opener(raise_exc=TimeoutError("t")))
    assert r["ok"] is False and r["status"] is None and "TimeoutError" in r["error"]
    r = indexnow.submit(["https://jobcho.wiki/x"], host="jobcho.wiki", key="k", key_location="l", opener=_opener(500))
    assert r["ok"] is False and r["status"] == 500


def test_submit_with_nothing_to_send_makes_no_request():
    seen = []
    assert indexnow.submit([], host="h", key="k", key_location="l", opener=_opener(seen=seen)) == {"sent": 0, "status": None, "ok": True, "error": None}
    assert seen == []


def test_submit_refuses_to_silently_truncate_over_the_cap():
    r = indexnow.submit([f"https://jobcho.wiki/{i}" for i in range(indexnow.MAX_URLS + 1)],
                        host="h", key="k", key_location="l", opener=_opener())
    assert r["ok"] is False and "상한" in r["error"]


def test_notify_changed_sends_only_changed_urls_and_logs_one_line():
    seen, log = [], io.StringIO()
    idx = {"https://jobcho.wiki/a": {"changed": True}, "https://jobcho.wiki/b": {"changed": False},
           "https://jobcho.wiki/c": {"changed": True}}
    indexnow.notify_changed(idx, site_origin="https://jobcho.wiki", key="k", key_path="indexnow-key.txt",
                            opener=_opener(200, seen=seen), log=log)
    assert seen[0][2]["urlList"] == ["https://jobcho.wiki/a", "https://jobcho.wiki/c"]
    assert seen[0][2]["host"] == "jobcho.wiki"
    assert "2개 URL 통보, HTTP 200" in log.getvalue()
    log2 = io.StringIO()
    indexnow.notify_changed({"https://jobcho.wiki/a": {"changed": False}}, site_origin="https://jobcho.wiki",
                            key="k", key_path="indexnow-key.txt", opener=_opener(seen=[]), log=log2)
    assert "바뀐 URL 0개" in log2.getvalue()


# ── 4·5. 빌드 배선 — 게이트·키 파일 ───────────────────────────────────────────

def test_key_page_only_when_key_is_configured():
    assert sitemap.render_indexnow_key(GenConfig(indexnow_key="")) is None
    assert sitemap.render_indexnow_key(GenConfig(indexnow_key="  ")) is None
    pg = sitemap.render_indexnow_key(GenConfig(indexnow_key="abc123"))
    assert pg.path == "indexnow-key.txt" and pg.html == "abc123\n"
    assert pg.in_sitemap is False and pg.content_type == "text/plain; charset=utf-8"


def test_build_stamps_only_changed_pages_and_persists_the_index(tmp_path, fake_bundle, fake_combinations_path, monkeypatch):
    out = tmp_path / "dist"
    assert build_module.run(str(out), fake_bundle, lastmod="2026-08-01") == 0
    xml1 = (out / "sitemap.xml").read_text(encoding="utf-8")
    assert set(re.findall(r"<lastmod>([^<]+)</lastmod>", xml1)) == {"2026-08-01"}
    urls = json.loads((out / ".manifest.json").read_text(encoding="utf-8"))["urls"]
    assert urls and all(v["lastmod"] == "2026-08-01" for v in urls.values())

    # 같은 번들로 다시 — 생성 페이지는 전부 그대로, 대문·커뮤니티(원본 파일 없음)만 오늘이다.
    assert build_module.run(str(out), fake_bundle, lastmod="2026-08-29") == 0
    xml2 = (out / "sitemap.xml").read_text(encoding="utf-8")
    dates = dict(re.findall(r"<loc>([^<]+)</loc>\s*<lastmod>([^<]+)</lastmod>", xml2))
    generated = {u: d for u, d in dates.items() if "/company/" in u or "/vs/" in u or u.endswith(("/privacy", "/terms"))}
    assert generated and set(generated.values()) == {"2026-08-01"}, "안 바뀐 페이지에 오늘을 찍었다"

    # 회사 하나를 바꾸면 그 페이지만 오늘이다.
    fake_bundle["companies"][0]["industry_nm"] = "반도체·바뀜"
    assert build_module.run(str(out), fake_bundle, lastmod="2026-08-30") == 0
    dates3 = dict(re.findall(r"<loc>([^<]+)</loc>\s*<lastmod>([^<]+)</lastmod>", (out / "sitemap.xml").read_text(encoding="utf-8")))
    changed = {u for u, d in dates3.items() if d == "2026-08-30" and "/company/" in u}
    assert f"{CFG.site_origin}/company/samsung-elec" in changed
    assert f"{CFG.site_origin}/company/naver" not in changed


def test_build_does_not_notify_outside_the_serving_dist(tmp_path, fake_bundle, fake_combinations_path, monkeypatch):
    """③ 게이트 — 스크래치·테스트·CI 빌드는 라이브가 아니다. 키가 있어도 통보하지 않는다."""
    monkeypatch.setattr(build_module, "CFG", GenConfig(indexnow_key="k" * 32))
    seen = []
    assert build_module.run(str(tmp_path / "dist"), fake_bundle, lastmod="2026-08-29",
                            indexnow_opener=_opener(seen=seen)) == 0
    assert seen == [], "서빙 dist 가 아닌데 IndexNow 를 두드렸다"
    assert (tmp_path / "dist" / "indexnow-key.txt").read_text(encoding="utf-8") == "k" * 32 + "\n"


def test_build_notifies_changed_urls_when_targeting_the_serving_dist(tmp_path, fake_bundle, fake_combinations_path, monkeypatch, capsys):
    out = tmp_path / "dist"
    monkeypatch.setattr(build_module, "CFG", GenConfig(indexnow_key="k" * 32, out_dir=str(out)))
    seen = []
    assert build_module.run(str(out), fake_bundle, lastmod="2026-08-01", indexnow_opener=_opener(202, seen=seen)) == 0
    assert len(seen) == 1
    body = seen[0][2]
    assert body["key"] == "k" * 32 and body["keyLocation"] == f"{CFG.site_origin}/indexnow-key.txt"
    assert f"{CFG.site_origin}/company/samsung-elec" in body["urlList"]
    assert f"{CFG.site_origin}/indexnow-key.txt" not in body["urlList"], "키 파일 자체는 통보 대상이 아니다"
    assert "IndexNow" in capsys.readouterr().err

    # 두 번째 빌드: 생성 페이지는 안 바뀌었으니 대문·커뮤니티(원본 파일 없음 = 매번 오늘)만 간다.
    seen.clear()
    assert build_module.run(str(out), fake_bundle, lastmod="2026-08-29", indexnow_opener=_opener(202, seen=seen)) == 0
    assert all("/company/" not in u and "/vs/" not in u for u in seen[0][2]["urlList"])


def test_build_honours_no_indexnow_and_a_missing_key(tmp_path, fake_bundle, fake_combinations_path, monkeypatch):
    out = tmp_path / "dist"
    seen = []
    monkeypatch.setattr(build_module, "CFG", GenConfig(indexnow_key="k" * 32, out_dir=str(out)))
    assert build_module.run(str(out), fake_bundle, notify=False, indexnow_opener=_opener(seen=seen)) == 0
    assert seen == []
    monkeypatch.setattr(build_module, "CFG", GenConfig(indexnow_key="", out_dir=str(out)))
    assert build_module.run(str(out), fake_bundle, indexnow_opener=_opener(seen=seen)) == 0
    assert seen == [] and not (out / "indexnow-key.txt").exists()


def test_indexnow_failure_does_not_fail_the_build(tmp_path, fake_bundle, fake_combinations_path, monkeypatch, capsys):
    out = tmp_path / "dist"
    monkeypatch.setattr(build_module, "CFG", GenConfig(indexnow_key="k" * 32, out_dir=str(out)))
    http403 = urllib.error.HTTPError("u", 403, "Forbidden", {}, None)
    assert build_module.run(str(out), fake_bundle, indexnow_opener=_opener(raise_exc=http403)) == 0
    assert (out / "sitemap.xml").exists(), "스왑은 이미 끝났다 — 통보 실패가 라이브를 되돌리지 않는다"
    assert "IndexNow 실패" in capsys.readouterr().err
