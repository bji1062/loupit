"""SP-AUTH-19 운영 콘솔 관문 (CO-1~CO-12).

**이 파일이 지키는 것은 UI 가 아니라 노출 범위와 감사다.**

콘솔은 이 코드베이스에 처음 생기는 "회원 위" 권한이고, 잘못 열리면 인터넷에 관리 화면이
노출된다. 그래서 여기서 재는 축은 셋이다.

1. **허락된 입구 밖에서는 보이지도 않는가** — nginx 를 거친 요청은 404(403·401 이 아니다).
   예외는 비밀번호 뒤의 관리 호스트 하나(SP-AUTH-19.8) — 그 매트릭스는 `test_admin_host_gate.py` 가 소유한다.
2. **그 판정의 전제가 살아 있는가** — "프록시 헤더가 없으면 터널"이라는 규칙은
   `infra/nginx/*.conf`(본·베타·관리) 가 모든 `proxy_pass` 블록에 헤더를 붙인다는 사실에 기댄다.
   CO-11 이 그 사실을 직접 검사한다. **전제를 검사하지 않는 보안 판정은 가정이다.**
3. **감사가 자율신고를 벗어났는가** — `DECIDED_BY_ID` 를 요청 본문으로 받을 수 없어야 한다.
   CO-12 는 입력 모델에 그 필드가 **없다**는 것을 못박는다(있으면 언젠가 쓰인다).
"""

from __future__ import annotations

import re
from pathlib import Path

import pytest
from fastapi.routing import APIRoute

from server import deps
from server.services import operator

ROOT = Path(__file__).resolve().parents[2]
# 앱 포트(:8000·:8001)로 프록시하는 vhost **전부** — 하나라도 표식을 빠뜨리면 그 경로가 터널로 위장한다.
# 손으로 적은 목록은 새 vhost 를 놓친다(2026-09-18 적대 검토) → proxy_pass 가 있는 conf 를 모은다.
NGINX_CONFS = tuple(sorted(
    p for p in (ROOT / "infra" / "nginx").glob("*.conf")
    if re.search(r"^\s*proxy_pass\s", p.read_text(encoding="utf-8"), re.M)
))


# ── CO-1~4: 화이트리스트 (순수 함수) ──────────────────────────────────────────

def _settings(monkeypatch, value: str):
    from server.config import get_settings
    s = get_settings()
    monkeypatch.setattr(s, "operator_emails", value)


def test_CO1_화이트리스트가_비면_아무도_운영자가_아니다(monkeypatch):
    """빈 목록을 '제한 없음'으로 읽는 구현이 흔하다 — 그건 설정을 지운 순간 전원에게 권한을 준다."""
    _settings(monkeypatch, "")
    assert operator.operator_emails() == frozenset()
    assert operator.is_operator("anyone@example.com") is False
    assert operator.is_operator(None) is False


def test_CO2_대소문자와_여백은_흡수한다(monkeypatch):
    """`.env` 를 손으로 고치는 사람이 있다. 여백 하나로 운영자가 조용히 권한을 잃으면 안 된다."""
    _settings(monkeypatch, "  Ops@Example.COM , second@example.com ,, ")
    assert operator.operator_emails() == {"ops@example.com", "second@example.com"}
    assert operator.is_operator("OPS@example.com  ") is True
    assert operator.is_operator("second@example.com") is True


def test_CO3_플러스태그_변형은_운영자가_아니다(monkeypatch):
    """권한은 **계정 동일성**으로 판정한다.

    `_delivery_address`(`+태그`·구글도트 접기)를 여기 쓰면 `ops+test@` 로 만든 **별개 계정**이
    운영자 권한을 물려받는다. 그 접기는 "같은 수신함인가"를 묻는 폭탄 방지용 키지 신원이 아니다.
    """
    _settings(monkeypatch, "ops@gmail.com")
    assert operator.is_operator("ops+admin@gmail.com") is False
    assert operator.is_operator("o.p.s@gmail.com") is False


def test_CO4_비운영자는_그냥_아니다(monkeypatch):
    _settings(monkeypatch, "ops@example.com")
    assert operator.is_operator("someone@example.com") is False
    assert operator.is_operator("") is False


# ── CO-5~7: 노출 범위 판정 (순수 함수) ────────────────────────────────────────

@pytest.mark.parametrize("header", ["x-real-ip", "X-Forwarded-For", "X-Forwarded-Proto"])
def test_CO5_프록시_헤더가_하나라도_있으면_외부다(header):
    """nginx 는 세 헤더를 모두 붙인다. **하나라도** 있으면 프록시를 거친 것이다 —
    셋 다 요구하면 하나만 지운 요청이 터널로 위장한다."""
    assert deps.came_through_proxy({header.lower(): "1.2.3.4"}) is True


def test_CO6_헤더가_없으면_터널이다():
    assert deps.came_through_proxy({}) is False
    assert deps.came_through_proxy({"host": "127.0.0.1:8000", "cookie": "loupit_sid=x"}) is False


@pytest.mark.asyncio
async def test_CO7_프록시_요청은_404로_끊긴다():
    """403 이 아니라 **404** 다 — 관리 화면은 존재 자체가 정보다.

    403 은 "여기 뭔가 있는데 네가 못 본다"를 알려 준다. 봇이 경로를 수집하는 세상에서
    그 차이가 표적 여부를 가른다.
    """
    from fastapi import HTTPException

    class _Req:
        headers = {"x-real-ip": "203.0.113.9"}

    with pytest.raises(HTTPException) as exc:
        await deps.require_console_access(_Req())
    assert exc.value.status_code == 404

    class _Tunnel:
        headers = {"host": "127.0.0.1:8000"}

    assert await deps.require_console_access(_Tunnel()) is None  # 터널은 통과


# ── CO-8~10: 등록 조건 (fail-closed) ─────────────────────────────────────────

def _console_routes(app) -> set[tuple[str, str]]:
    out = set()
    for r in app.routes:
        if isinstance(r, APIRoute) and "/console" in r.path:
            for m in r.methods:
                out.add((r.path, m))
    return out


def _build(monkeypatch, *, m9: str, ops_emails: str):
    from server.config import get_settings
    from server.main import create_app

    monkeypatch.setenv("M9_ENABLED", m9)
    monkeypatch.setenv("OPERATOR_EMAILS", ops_emails)
    get_settings.cache_clear()
    try:
        return create_app()
    finally:
        get_settings.cache_clear()


def test_CO8_화이트리스트가_비면_라우터를_등록조차_하지_않는다(monkeypatch):
    """404 를 낼 라우터라도 **표면에 없는 것**이 낫다 — 표면 변화는 명시적 설정에만 따라온다(INV-1)."""
    assert _console_routes(_build(monkeypatch, m9="1", ops_emails="")) == set()
    assert _console_routes(_build(monkeypatch, m9="1", ops_emails="   ")) == set()


def test_CO9_M9가_꺼져_있으면_등록하지_않는다(monkeypatch):
    """콘솔이 다루는 큐 2종은 참여 테이블이다 — 없는 테이블에 대고 500 을 뿜을 수는 없다."""
    assert _console_routes(_build(monkeypatch, m9="0", ops_emails="ops@example.com")) == set()


def test_CO10_표면은_정확히_이_집합이다(monkeypatch):
    """새 라우트가 슬며시 끼는 것을 막는다(TS-1 과 같은 규약).

    ⚠ 되돌릴 수 없는 조작(복지 하드 삭제·재직 인증 폐기)이 **여기 없다**는 것도 함께 재는
    어서션이다. 그것들은 CLI 에만 남는다(SP-AUTH-19.4)."""
    routes = _console_routes(_build(monkeypatch, m9="1", ops_emails="ops@example.com"))
    assert routes == {
        ("/api/v1/console", "GET"),                                    # 콘솔 화면(껍데기)
        ("/api/v1/console/queues", "GET"),                             # 큐 3종
        ("/api/v1/console/verifications/{req_id}/approve", "POST"),
        ("/api/v1/console/verifications/{req_id}/reject", "POST"),
        ("/api/v1/console/company-requests/{req_id}/decide", "POST"),
        ("/api/v1/console/suppressions/{target_hash}/release", "POST"),
        # SC15(2026-08-27): 신고 처리 — hide(대상 hidden, 되돌릴 수 있다)/dismiss 뿐. 하드 삭제 없음.
        ("/api/v1/console/reports/{report_id}/decide", "POST"),
        # SP-AUTH-19.7(2026-09-18): 조회 화면 4종(전부 GET) + 게시판 숨김/복구 2. 복구는 hidden→active 만 —
        # 하드 삭제·되돌리기(복지 편집)는 여전히 없다.
        ("/api/v1/console/overview", "GET"),
        ("/api/v1/console/members", "GET"),
        ("/api/v1/console/posts", "GET"),
        ("/api/v1/console/comments", "GET"),
        ("/api/v1/console/benefit-edits", "GET"),
        ("/api/v1/console/posts/{post_id}/visibility", "POST"),
        ("/api/v1/console/comments/{comment_id}/visibility", "POST"),
    }


def test_CO10b_노출범위_관문이_라우터_레벨에_있다(monkeypatch):
    """경로마다 붙이면 **하나를 빠뜨리는 날 그 라우트만 공개된다.**

    라우터 레벨이어야 새 라우트가 자동으로 보호된다. 그리고 라우터 의존성은 경로 의존성보다
    **먼저** 평가되므로, 비로그인 외부 요청이 401(=존재 누설) 대신 404 를 받는다."""
    app = _build(monkeypatch, m9="1", ops_emails="ops@example.com")
    for r in app.routes:
        if isinstance(r, APIRoute) and "/console" in r.path:
            names = [d.call.__name__ for d in r.dependant.dependencies if d.call]
            assert "require_console_access" in names, f"{r.path} 에 노출범위 관문이 없다"
            assert names.index("require_console_access") == 0, (
                f"{r.path}: 노출범위 판정이 첫 관문이 아니다 — 세션 검사가 먼저 돌면 "
                "비로그인 외부 요청에 401 이 나가 존재가 새어 나간다"
            )


# ── CO-11: 판정의 **전제**를 검사한다 ─────────────────────────────────────────

def test_CO11_nginx의_모든_프록시_블록이_식별_헤더를_붙인다():
    """"프록시 헤더가 없으면 터널"이라는 판정은 이 사실 위에 서 있다.

    누군가 `proxy_pass` 블록을 추가하면서 `X-Real-IP` 를 빠뜨리면, **그 경로로 들어온 인터넷
    요청이 터널로 위장**해 콘솔이 공개된다. 전제를 검사하지 않는 보안 판정은 가정이다.

    2026-09-18: 본 사이트 하나만 보던 검사를 **베타·관리 vhost 까지** 넓혔다. 베타 API(:8001)에도
    콘솔이 있고, 관리 vhost 는 콘솔로 가는 바로 그 경로다 — 거기서 표식이 빠지면 비밀번호도 게이트
    비밀도 없이 통과 A(터널)로 열린다. 블록 단위 정밀 검사는 test_admin_host_gate AH-7·AH-9 가 한다.
    """
    assert {"loupit.conf", "loupit-beta.conf", "loupit-admin.conf"} <= {p.name for p in NGINX_CONFS}, (
        "알려진 vhost 가 목록에 없다 — glob 이 비어 이 검사가 공회전한다"
    )
    for path in NGINX_CONFS:
        conf = path.read_text()
        lines = conf.splitlines()
        # 각 proxy_pass 라인 뒤 12줄 안에 X-Real-IP 설정이 있어야 한다(현행 conf 는 3줄 뒤).
        idxs = [i for i, ln in enumerate(lines) if re.match(r"\s*proxy_pass\s+http://127\.0\.0\.1", ln)]
        assert idxs, f"{path.name} 에서 proxy_pass 를 찾지 못했다 — 이 검사가 무력화됐다"
        for i in idxs:
            window = "\n".join(lines[i:i + 12])
            assert "proxy_set_header X-Real-IP" in window, (
                f"{path.name}:{i + 1} 의 proxy_pass 블록이 X-Real-IP 를 설정하지 않는다 — "
                "이 경로로 온 인터넷 요청이 SSH 터널로 위장해 운영 콘솔이 공개된다"
            )


# ── CO-12: 감사 — 결정자는 세션에서만 온다 ────────────────────────────────────

def test_CO12_결정_입력에_결정자_필드가_없다():
    """`DECIDED_BY_ID` 를 본문으로 받으면 감사는 여전히 자율신고다.

    모델에 필드를 **두지 않는 것**이 가장 강한 방어다 — 실수로 쓸 수가 없다. 이 테스트는
    나중에 누군가 편의를 이유로 필드를 추가하는 것을 막는다."""
    from server.routers.console import CompanyDecisionIn, DecisionIn, ReportDecisionIn, VisibilityIn

    for model in (DecisionIn, CompanyDecisionIn, ReportDecisionIn, VisibilityIn):
        fields = set(model.model_fields)
        for banned in ("decided_by", "by", "decided_by_id", "operator_id", "mbr_id"):
            assert banned not in fields, f"{model.__name__} 이 결정자를 본문으로 받는다: {banned}"


def test_CO13_콘솔_페이지는_innerHTML_과_자동링크를_쓰지_않는다():
    """SP-AUTH-19.5 ①② — 증빙·회사명·URL 은 전부 사용자 입력 원문이다.

    `innerHTML` 이면 XSS 고, `<a href>` 면 관리자가 무심코 눌러 IP 노출·피싱이다.
    페이지는 노드 조립으로만 그리고 링크를 만들지 않는다."""
    from server.routers.console import _PAGE

    # ⚠ 주석까지 세면 "innerHTML 은 쓰지 않는다"라고 **적어 둔 주석**이 위반으로 잡힌다
    #   (2026-07-30 실발현 — 가드 문구가 의도보다 넓은 함정 ㊶ 의 축소판). 코드만 본다.
    code = "\n".join(ln for ln in _PAGE.splitlines() if not ln.lstrip().startswith("//"))

    for banned in ("innerHTML", "outerHTML", "insertAdjacentHTML", "document.write"):
        assert banned not in code, f"{banned} 사용 — 사용자 입력 원문이 HTML 로 해석된다"
    # 앵커를 만드는 모든 모양 — 이 페이지는 `$('a', …)` 헬퍼로도 요소를 만든다. `x.href = url`(공백 포함)·
    # `setAttribute('href', …)` 도 링크다(2026-09-18 적대 검토: 옛 검사는 이 셋을 못 봤다).
    link_makers = (
        r"createElement\(\s*['\"]a['\"]",   # document.createElement('a')
        r"\$\(\s*['\"]a['\"]",              # $('a', …) 헬퍼
        r"\.href\b",                          # el.href = …
        r"setAttribute\(\s*['\"]href['\"]",  # el.setAttribute('href', …)
        r"<a[\s>]",                           # 정적 마크업
        r"href\s*=",
    )
    for pat in link_makers:
        assert not re.search(pat, code), f"링크를 만든다({pat}) — 증빙 URL 이 클릭 가능해지면 관리자가 표적이 된다"
    assert "noindex" in _PAGE, "검색엔진 차단 메타가 없다"
    # 자기검증 — 위 어서션들이 실제로 무언가를 보고 있는지(빈 문자열이면 전부 통과한다).
    assert "textContent" in code and len(code) > 2000, "페이지 본문을 못 읽었다 — 어서션이 공회전한다"


def test_CO14_콘솔에_로그인_단계가_있다():
    """**막다른 길 금지**(2026-07-30 실발현 — 관문만 만들고 입구를 안 만들었다).

    세션 쿠키는 오리진별이라 `jobcho.wiki` 로그인이 `127.0.0.1` 로 오지 않는다. 그런데 정적
    `/login` 페이지는 nginx 가 `jobcho.wiki` 에서만 서빙하고 앱 포트는 `/api/v1` 만 낸다 →
    터널 안에는 **로그인할 화면이 아예 없었다.** 콘솔은 "로그인이 필요하다"고만 말하고 그
    방법을 주지 않았다.

    함정 ㉘ 과 같은 부류다 — 기능을 열기 전에 **그 기능의 실패 경로**가 갈 곳이 있는지 보라.
    """
    from server.routers.console import _PAGE

    code = "\n".join(ln for ln in _PAGE.splitlines() if not ln.lstrip().startswith("//"))
    for needed in ("renderLogin", "/members/login-code", "/members/login", "/members/logout"):
        assert needed in code, f"콘솔에 {needed} 가 없다 — 터널 안에서 로그인할 방법이 없다"
    # 401 을 **오류 문구**가 아니라 **다음 단계**로 다뤄야 한다.
    assert "NEEDS_LOGIN" in code and "renderLogin(" in code, (
        "401 을 문구로만 표시하고 있다 — 그건 막다른 길이다"
    )
    # 코드 발송 응답은 균일 204 다(계정 열거 방지). 억제 409 만 예외로 안내한다(SP-AUTH-16).
    assert "409" in code, "억제된 주소 안내가 없다 — 그 사용자는 영영 이유를 모른다"
    # 비운영자 세션도 막다른 길이다(2026-09-18 적대 검토) — 404 를 받으면 로그아웃·다시 로그인 단계로 보낸다.
    assert "notAllowed" in code and "renderLogin(" in code and "지금 세션 로그아웃" in code, (
        "비운영자 세션으로 들어오면 쿠키를 손으로 지워야만 빠져나갈 수 있다"
    )


# ── CO-15~17: SP-AUTH-19.7 화면 확장(2026-09-18) — 방어 심층 ───────────────────────

@pytest.mark.asyncio
async def test_CO15_콘솔_페이지는_인라인_블록_해시_CSP_를_싣는다():
    """규칙 ①(노드 조립)이 언젠가 한 군데서 깨지더라도 주입된 스크립트는 **돌지 않고**(해시 script-src),
    돌더라도 **밖으로 못 보낸다**(connect-src 'self', img-src 없음 = 이미지 비콘 차단).

    `'unsafe-inline'` 을 쓰면 이 방어가 통째로 사라진다 — 해시는 `_PAGE` 에서 계산하므로 페이지를 고쳐도
    따라오지만, 여기서 실제 블록과 대조해 "계산이 엉뚱한 곳을 가리키는" 경우까지 잡는다."""
    import base64
    import hashlib

    from server.routers import console

    csp = console._CSP
    for needed in ("default-src 'none'", "connect-src 'self'", "frame-ancestors 'none'",
                   "base-uri 'none'", "form-action 'none'"):
        assert needed in csp, f"CSP 에 {needed} 가 없다"
    assert "unsafe-inline" not in csp and "unsafe-eval" not in csp
    for tag in ("script", "style"):
        body = re.search(rf"<{tag}>(.*?)</{tag}>", console._PAGE, re.S).group(1)
        digest = base64.b64encode(hashlib.sha256(body.encode("utf-8")).digest()).decode()
        assert f"{tag}-src 'sha256-{digest}'" in csp, f"{tag} 해시가 실제 블록과 다르다 — 화면이 통째로 안 뜬다"
    assert "<script src" not in console._PAGE, "외부 스크립트 — CSP 가 막아 화면이 깨진다(그리고 공급망 위험)"

    resp = await console.console_page()
    assert resp.headers["content-security-policy"] == csp
    assert resp.headers["cache-control"] == "no-store"


def test_CO16_콘솔_JSON_응답은_전부_no_store_다(monkeypatch):
    """회원 탭은 로그인 이메일을 싣는다 — 브라우저·중간 캐시에 남으면 안 된다. 라우트마다 붙이면 새 라우트
    하나를 빠뜨리는 날 그 응답만 캐시되므로 **라우터 레벨** 의존성으로 건다(관문과 같은 이유)."""
    app = _build(monkeypatch, m9="1", ops_emails="ops@example.com")
    for r in app.routes:
        if isinstance(r, APIRoute) and "/console" in r.path and r.path != "/api/v1/console":
            names = [d.call.__name__ for d in r.dependant.dependencies if d.call]
            assert "_no_store" in names, f"{r.path} 응답에 no-store 가 걸리지 않는다"


def test_CO17_콘솔에_새_탭_4종이_있고_탭은_링크가_아니다():
    """현황·회원·게시판·복지 수정 이력 — 사용자 요청 화면(2026-09-18). 탭 전환은 버튼이다(`<a>` 0 — CO-13)."""
    from server.routers.console import _PAGE

    code = "\n".join(ln for ln in _PAGE.splitlines() if not ln.lstrip().startswith("//"))
    for fn, path in (("renderOverview", "/overview"), ("renderMembers", "/members"),
                     ("renderBoard", "/posts"), ("renderEdits", "/benefit-edits")):
        assert fn in code and f"'{path}" in code, f"{fn}({path}) 가 없다"
    assert "/visibility" in code, "게시판 숨김/복구 버튼이 없다"
    assert "overflow-x: auto" in code, "표가 자기 상자 안에서 가로 스크롤하지 않는다 — 폰에서 페이지 전체가 밀린다"
    assert 'name="viewport"' in _PAGE
