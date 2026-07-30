"""SP-AUTH-19 SSH 터널 전용 운영 콘솔 (FR-107·115).

라우터명이 `admin` 이 **아닌** 이유: 그 이름은 레거시 델타로 영구 제외돼 있다
(`server/routers/__init__.py`). 이름을 되살리면 "제거했다"는 기록과 어긋난다.

## 두 겹의 관문 — 바깥이 본체다

라우터 레벨 `dependencies=[Depends(require_loopback)]` 가 **먼저** 돈다(FastAPI 는 라우터
의존성을 경로 의존성보다 앞서 해결한다). 그래서 인터넷에서 온 요청은 세션을 보기도 전에
404 로 끊긴다 — 순서가 뒤바뀌면 비로그인 요청에 401 이 나가 **여기에 무언가 있다**를 알려 준다.

## 왜 콘솔이 CLI 보다 나은가 — 편의가 아니라 감사다

`DECIDED_BY_ID` 를 **세션에서 자동 주입**한다. CLI 는 `--by N` 을 사람이 손으로 넣고 FK 도
검증도 없어 현재 감사 기록은 자율신고다. 요청 본문으로 받지 않는 것이 핵심이다.

## 되돌릴 수 없는 것은 여기 없다

복지 하드 삭제·재직 인증 폐기는 CLI 에만 있다(SP-AUTH-19.4). 브라우저 클릭 한 번 뒤에
비가역 조작을 두지 않는다.
"""
from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Response
from fastapi.responses import HTMLResponse
from pydantic import BaseModel, Field

from server.deps import require_csrf, require_loopback, require_operator
from server.services import operator

# 라우터 레벨 의존성 = 경로 의존성보다 먼저 평가된다. 노출 범위 판정이 **항상 첫 관문**이어야
# 하므로 여기에 둔다(각 라우트에 붙이면 하나를 빠뜨리는 날 그 라우트만 공개된다).
router = APIRouter(prefix="/console", tags=["console"], dependencies=[Depends(require_loopback)])


class DecisionIn(BaseModel):
    """결정 입력 — **`decided_by` 가 없다.** 그 값은 세션에서만 온다(SP-AUTH-19.5 ③).

    본문으로 받으면 운영자가 남의 ID 를 적을 수 있고, 그러면 감사는 여전히 자율신고다.
    모델에 필드를 두지 않는 것이 가장 강한 방어다 — 실수로 쓸 수가 없다."""

    note: str | None = Field(default=None, max_length=500)


class CompanyDecisionIn(DecisionIn):
    approve: bool


@router.get("/queues")
async def queues(op: dict = Depends(require_operator)) -> dict:
    """대기 큐 3종을 **구조화된 JSON** 으로 돌려준다.

    ⚠ 여기 담기는 `EVIDENCE_CTNT`·`REQ_COMP_NM`·`REF_URL_CTNT`·`NICKNAME_NM` 은 전부
    **사용자 입력 원문**이다. 서버는 값을 그대로 싣고, 그리는 쪽(`console.html`)이 노드
    조립으로만 표시한다 — 서버가 HTML 을 만들어 보내면 그 순간 XSS 경로가 생긴다.

    억제 목록은 **해시만** 싣는다(원문 주소는 애초에 저장되지 않는다, T9).
    """
    pending = await operator.list_pending_verifications()
    companies = await operator.list_pending_company_requests()
    suppressed = await operator.list_suppressed()
    return {
        "operator": op["LOGIN_EMAIL_NM"],
        "verifications": [
            {
                "id": r["VRF_REQUEST_ID"], "member_id": r["MBR_ID"], "nickname": r["NICKNAME_NM"],
                "company_id": r["COMP_ID"], "company": r["COMP_NM"],
                "evidence": r["EVIDENCE_CTNT"], "at": str(r["INS_DTM"]),
            } for r in pending
        ],
        "company_requests": [
            {
                "id": r["COMP_REQUEST_ID"], "member_id": r["MBR_ID"], "nickname": r["NICKNAME_NM"],
                "name": r["REQ_COMP_NM"], "ref_url": r["REF_URL_CTNT"], "at": str(r["INS_DTM"]),
            } for r in companies
        ],
        "suppressed": [
            {
                "id": r["MAIL_SUPP_ID"], "target_hash": r["TARGET_HASH_VAL"],
                "reason": r["REASON_CD"], "at": str(r["INS_DTM"]),
            } for r in suppressed
        ],
    }


@router.post("/verifications/{req_id}/approve", status_code=200)
async def approve_verification(
    req_id: int, body: DecisionIn,
    _csrf: None = Depends(require_csrf), op: dict = Depends(require_operator),
) -> dict:
    """수동 재직 승인 — `DECIDED_BY_ID` 는 `op["MBR_ID"]`(세션)에서 온다."""
    result = await operator.approve_verification(req_id, op["MBR_ID"], body.note)
    if result == "not_pending":
        raise HTTPException(status_code=409, detail="not_pending")
    return {"result": result}


@router.post("/verifications/{req_id}/reject", status_code=200)
async def reject_verification(
    req_id: int, body: DecisionIn,
    _csrf: None = Depends(require_csrf), op: dict = Depends(require_operator),
) -> dict:
    if not await operator.reject_verification(req_id, op["MBR_ID"], body.note):
        raise HTTPException(status_code=409, detail="not_pending")
    return {"result": "rejected"}


@router.post("/company-requests/{req_id}/decide", status_code=200)
async def decide_company_request(
    req_id: int, body: CompanyDecisionIn,
    _csrf: None = Depends(require_csrf), op: dict = Depends(require_operator),
) -> dict:
    """🚨 **회사를 만들지 않는다** — 상태만 바꾼다(SP-AUTH-17 과 동일 계약).

    실제 등록은 `db/seed` 작업이고, 회사를 추가하면 **정적 사이트 재생성이 필수**다.
    응답에 그 안내를 실어 승인 직후에 잊지 않게 한다."""
    if not await operator.decide_company_request(req_id, body.approve, op["MBR_ID"], body.note):
        raise HTTPException(status_code=409, detail="not_pending")
    return {
        "result": "approved" if body.approve else "rejected",
        "next": ("상태만 바뀌었다. 실제 등록은 db/seed 작업 + 정적 사이트 재생성(generator.build)."
                 if body.approve else None),
    }


@router.post("/suppressions/{target_hash}/release", status_code=200)
async def release_suppression(
    target_hash: str, body: DecisionIn,
    _csrf: None = Depends(require_csrf), op: dict = Depends(require_operator),
) -> dict:
    """억제 해제 — **해시로** 받는다(원문 주소는 브라우저·요청 로그에 남기지 않는다).

    억제는 위조·오탐 바운스 한 건으로 사용자가 로그인을 영영 못 하게 만들 수 있어서,
    되돌리는 수단이 반드시 있어야 한다(SP-AUTH-16). 행은 지우지 않고 `RELEASED_DTM` 만
    채운다 — 반복 오탐을 추적하려면 누가 언제 풀었는지가 남아야 한다."""
    if len(target_hash) != 64 or not all(c in "0123456789abcdef" for c in target_hash.lower()):
        raise HTTPException(status_code=422, detail="invalid_target_hash")
    if not await operator.release_suppression(target_hash.lower(), op["MBR_ID"]):
        raise HTTPException(status_code=409, detail="not_suppressed")
    return {"result": "released"}


@router.get("", response_class=HTMLResponse, include_in_schema=False)
async def console_page() -> Response:
    """콘솔 화면. **`web/dist` 가 아니라 여기서 낸다.**

    `web/dist` 는 공개 문서 루트라 거기 두는 순간 인터넷에 노출된다(그 디렉터리에 쓰는 것은
    곧 프로덕션 반영이다). 라우터에서 내면 이 파일도 `require_loopback` 관문 뒤에 있다.

    ⚠ 이 응답은 **운영자 세션을 요구하지 않는다** — 껍데기 HTML 에는 데이터가 없고, 실제
    내용은 `/console/queues`(운영자 필수)가 준다. 터널을 뚫은 사람에게 로그인 폼을 보여
    주려면 화면 자체는 열려 있어야 한다.
    """
    return HTMLResponse(_PAGE, headers={"Cache-Control": "no-store"})


# ⚠ 이 페이지의 규칙 두 가지(SP-AUTH-19.5) — 어기면 관리자가 표적이 된다.
#   ① `innerHTML` 금지. 증빙·회사명·닉네임은 사용자 입력 원문이다 → `textContent` 로만 넣는다.
#   ② 자동 하이퍼링크 금지. 증빙·참고 URL 은 사용자가 넣은 외부 주소다. `<a href>` 로 만들면
#      관리자가 무심코 눌러 IP 노출·피싱을 당한다 → 텍스트로 보여주고 **복사**하게 한다.
_PAGE = """<!doctype html>
<html lang="ko"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex, nofollow">
<title>운영 콘솔 — jobcho.wiki</title>
<style>
  :root { color-scheme: light dark; --bd:#8884; --mut:#7a7a7a; }
  body { font: 15px/1.6 system-ui, -apple-system, "Apple SD Gothic Neo", sans-serif;
         margin: 0 auto; max-width: 62rem; padding: 1.5rem; }
  h1 { font-size: 1.15rem; margin: 0 0 .25rem; }
  h2 { font-size: 1rem; margin: 2rem 0 .5rem; border-bottom: 1px solid var(--bd); padding-bottom: .3rem; }
  .who { color: var(--mut); font-size: .85rem; margin-bottom: 1rem; }
  .item { border: 1px solid var(--bd); border-radius: 8px; padding: .75rem .9rem; margin: .5rem 0; }
  .head { display: flex; gap: .5rem; align-items: baseline; flex-wrap: wrap; }
  .id { font-weight: 600; }
  .meta { color: var(--mut); font-size: .85rem; }
  .raw { background: #8881; border-radius: 6px; padding: .45rem .6rem; margin: .5rem 0;
         white-space: pre-wrap; word-break: break-all; font-family: ui-monospace, monospace;
         font-size: .85rem; }
  .rowbtns { display: flex; gap: .4rem; flex-wrap: wrap; margin-top: .5rem; }
  button { font: inherit; padding: .3rem .7rem; border: 1px solid var(--bd);
           border-radius: 6px; background: transparent; cursor: pointer; }
  button:hover { background: #8882; }
  input[type=text] { font: inherit; padding: .3rem .5rem; border: 1px solid var(--bd);
                     border-radius: 6px; background: transparent; flex: 1; min-width: 12rem; }
  .empty { color: var(--mut); font-style: italic; }
  .warn { border-left: 3px solid #c60; padding-left: .7rem; color: var(--mut); font-size: .85rem; }
  #msg { position: sticky; top: 0; padding: .5rem 0; background: Canvas; }
</style></head><body>
<h1>운영 콘솔</h1>
<div class="who" id="who"></div>
<div id="msg"></div>
<div class="warn">
  증빙·회사명·참고 URL 은 <b>사용자가 입력한 원문</b>이다. 링크로 만들지 않는다 —
  누르면 IP 가 노출되고 피싱일 수 있다. 확인이 필요하면 복사해서 안전한 곳에서 열어라.
</div>
<div id="root"></div>
<script>
// ── 이 파일의 유일한 규칙: DOM 은 노드 조립으로만 만든다. innerHTML 은 쓰지 않는다. ──
const $ = (t, cls, text) => { const e = document.createElement(t);
  if (cls) e.className = cls; if (text !== undefined) e.textContent = text; return e; };
const root = document.getElementById('root');
const msgEl = document.getElementById('msg');
const say = (t) => { msgEl.textContent = t; };

async function api(path, opts = {}) {
  const res = await fetch('/api/v1/console' + path, {
    credentials: 'include',
    headers: { 'X-Loupit-Client': 'console', 'Content-Type': 'application/json' },
    ...opts,
  });
  if (res.status === 404) throw new Error('운영자 세션이 아니거나 터널 밖 접근이다 (404)');
  if (res.status === 401) throw new Error('로그인이 필요하다 — 이 주소에서 먼저 로그인하라');
  if (!res.ok) throw new Error(await res.text());
  return res.json();
}

/** 사용자 입력 원문 한 덩어리 — 텍스트로 보여주고 복사 버튼만 준다(링크 만들지 않음). */
function rawBlock(label, value) {
  const wrap = $('div');
  wrap.appendChild($('div', 'meta', label));
  const box = $('div', 'raw', value || '(없음)');
  wrap.appendChild(box);
  if (value) {
    const b = $('button', null, '복사');
    b.onclick = () => navigator.clipboard.writeText(value).then(() => say('복사했다.'));
    wrap.appendChild(b);
  }
  return wrap;
}

function section(title, items, render) {
  root.appendChild($('h2', null, title + ' (' + items.length + ')'));
  if (!items.length) { root.appendChild($('div', 'empty', '대기 없음.')); return; }
  items.forEach((it) => root.appendChild(render(it)));
}

function actionButton(label, fn) {
  const b = $('button', null, label);
  b.onclick = async () => {
    b.disabled = true;
    try { const r = await fn(); say(JSON.stringify(r)); await load(); }
    catch (e) { say('실패: ' + e.message); b.disabled = false; }
  };
  return b;
}

async function load() {
  root.replaceChildren();
  say('불러오는 중…');
  let data;
  try { data = await api('/queues'); } catch (e) { say(e.message); return; }
  say('');
  document.getElementById('who').textContent = '운영자: ' + data.operator;

  section('재직 수동 승인', data.verifications, (v) => {
    const el = $('div', 'item');
    const h = $('div', 'head');
    h.appendChild($('span', 'id', '#' + v.id));
    h.appendChild($('span', null, v.company));
    h.appendChild($('span', 'meta', v.nickname + ' (MBR ' + v.member_id + ') · ' + v.at));
    el.appendChild(h);
    el.appendChild(rawBlock('증빙(사용자 입력 원문)', v.evidence));
    const btns = $('div', 'rowbtns');
    const note = $('input'); note.type = 'text'; note.placeholder = '메모(선택)';
    btns.appendChild(note);
    btns.appendChild(actionButton('승인', () => api('/verifications/' + v.id + '/approve',
      { method: 'POST', body: JSON.stringify({ note: note.value || null }) })));
    btns.appendChild(actionButton('거부', () => api('/verifications/' + v.id + '/reject',
      { method: 'POST', body: JSON.stringify({ note: note.value || null }) })));
    el.appendChild(btns);
    return el;
  });

  section('회사 등록 요청', data.company_requests, (c) => {
    const el = $('div', 'item');
    const h = $('div', 'head');
    h.appendChild($('span', 'id', '#' + c.id));
    h.appendChild($('span', 'meta', (c.nickname || '(탈퇴 회원 ' + c.member_id + ')') + ' · ' + c.at));
    el.appendChild(h);
    el.appendChild(rawBlock('요청 회사명(사용자 입력 원문)', c.name));
    el.appendChild(rawBlock('참고 URL(사용자 입력 원문 — 누르지 마라)', c.ref_url));
    el.appendChild($('div', 'meta',
      '승인해도 회사는 생기지 않는다. db/seed 작업 + 정적 사이트 재생성이 따로 필요하다.'));
    const btns = $('div', 'rowbtns');
    const note = $('input'); note.type = 'text'; note.placeholder = '메모(선택)';
    btns.appendChild(note);
    btns.appendChild(actionButton('승인 표시', () => api('/company-requests/' + c.id + '/decide',
      { method: 'POST', body: JSON.stringify({ approve: true, note: note.value || null }) })));
    btns.appendChild(actionButton('거부', () => api('/company-requests/' + c.id + '/decide',
      { method: 'POST', body: JSON.stringify({ approve: false, note: note.value || null }) })));
    el.appendChild(btns);
    return el;
  });

  section('메일 발송 억제', data.suppressed, (s) => {
    const el = $('div', 'item');
    const h = $('div', 'head');
    h.appendChild($('span', 'id', '#' + s.id));
    h.appendChild($('span', null, s.reason));
    h.appendChild($('span', 'meta', s.at));
    el.appendChild(h);
    // 주소 원문은 애초에 저장되지 않는다(T9) — 해시만 보여준다.
    el.appendChild($('div', 'raw', s.target_hash));
    const btns = $('div', 'rowbtns');
    btns.appendChild(actionButton('억제 해제', () => api('/suppressions/' + s.target_hash + '/release',
      { method: 'POST', body: JSON.stringify({ note: null }) })));
    el.appendChild(btns);
    return el;
  });
}
load();
</script></body></html>
"""
