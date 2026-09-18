"""generator/benefit_rules.py — 복지 항목 페이지(SP-BEN)의 원문 분류 규칙 (순수 함수).

항목 페이지는 「이 복지가 있는 회사들이 **원문에 무엇을 적었나**」를 센다. 세는 규칙은 항목마다
`generator/data/benefit_pages/{code}.json` 에 있고, 이 모듈이 그 규칙을 원문에 적용한다.

🚨 **숫자는 사람이 적지 않는다.** 규칙(정규식)만 사람이 쓰고, 개수는 빌드가 원문에서 센다.
   회사가 늘거나 재직자가 원문을 고치면 다음 빌드에서 개수가 저절로 바뀐다 — 그래서 페이지의
   사람 글(해설·질문)에는 숫자를 금지한다(`check_no_digits`). 숫자가 든 사람 글은 데이터가
   바뀌는 날 거짓이 된다.

🚨 **예외(override)는 원문 해시에 묶는다.** 규칙이 틀리게 분류한 행은 JSON 의 `overrides` 에
   회사 + 원문 해시(`text_hash`)로 적는다. 원문이 바뀌면 해시가 달라져 예외가 **저절로 꺼지고**
   빌드 경고(`stale`)가 난다 — 예전 원문을 보고 내린 판정이 새 원문에 조용히 붙는 일을 막는다.

⚠ **수집자 메모를 걷어 내고 센다**(`core_text`). 원문 칸에는 「(공식 채용 페이지 … — 대출 한도·
   이율 미기재)」 같은 수집자의 출처 메모가 섞여 있고, 그 안의 「대출」「이자」 같은 낱말이
   규칙에 걸린다(실측: 가온전선 「대출·이자 지원 등 지원 방식 … 미기재」가 이자 지원으로 잡혔다).
   걷어 내는 것은 **매칭용 사본**뿐이다 — 화면의 원문은 회사 페이지와 같은 `benefit_desc` 를 쓴다.
"""
from __future__ import annotations

import glob
import hashlib
import json
import os
import re
from collections import Counter

_DIR = os.path.join(os.path.dirname(__file__), "data", "benefit_pages")

# 괄호 안이 수집자 메모인지 가르는 낱말. 회사가 쓴 괄호(예: 「(유·무이자)」「(최대 2억원)」)는 남긴다.
_META = re.compile(r"공식|페이지|미기재|미표기|미공개|채용|항목|추정|사이트|출처")
# 「 — 」 뒤 꼬리가 수집자 메모인지 가르는 낱말. 꼬리가 회사 내용일 수도 있어 낱말이 있을 때만 걷는다.
_META_TAIL = re.compile(r"미기재|미표기|미공개|다름|정본|공식|페이지|항목")
_PAREN = re.compile(r"\s*\(([^()]*)\)")
# 남기기로 한 괄호를 잠시 가리는 표식. 가리지 않으면 바깥 괄호가 `[^()]` 에 막혀 영영 안 걸린다 —
# 「(공식 페이지 (유·무이자) 항목 미기재)」의 메모가 통째로 남는다.
_KEEP_OPEN, _KEEP_CLOSE = "\x02", "\x03"
_TAIL = re.compile(r"\s+[—–]\s+(.*)$")
_DIGIT = re.compile(r"[0-9０-９]")


def text_hash(desc: str | None, note: str | None) -> str:
    """원문 해시 — 예외(override)가 **어떤 원문을 보고** 내린 판정인지 묶는 열쇠."""
    return hashlib.sha1(((desc or "") + "\x1f" + (note or "")).encode("utf-8")).hexdigest()[:10]


def _drop_or_keep(m: re.Match) -> str:
    if _META.search(m.group(1)):
        return ""
    return m.group(0).replace("(", _KEEP_OPEN).replace(")", _KEEP_CLOSE)


def core_text(text: str | None) -> str:
    """매칭용 사본: 수집자 메모(괄호·꼬리)를 걷어 낸 원문.

    괄호는 **안쪽부터** 본다(`[^()]*` = 가장 안쪽 괄호). 메모면 걷고, 회사가 쓴 괄호면 표식으로 가려
    두고 다시 돈다 — 바뀌지 않을 때까지. 그래서 「(공식 페이지 (채용) 항목 — 한도 미기재)」는 안쪽을
    걷은 뒤 바깥이 통째로 걷히고, 메모 안에 회사 괄호가 끼어 있어도(「(공식 … (유·무이자) … 미기재)」)
    바깥 메모가 걷힌다. 메모 낱말이 없는 겹괄호(「(최대 2억원(연 1회))」)는 그대로 남는다.
    """
    s = text or ""
    while True:
        t = _PAREN.sub(_drop_or_keep, s)
        if t == s:
            break
        s = t
    s = s.replace(_KEEP_OPEN, "(").replace(_KEEP_CLOSE, ")")
    m = _TAIL.search(s)
    if m and _META_TAIL.search(m.group(1)):
        s = s[: m.start()]
    return s.strip()


def match_text(desc: str | None, note: str | None) -> str:
    return " ".join(t for t in (core_text(desc), core_text(note)) if t)


def load_pages(path: str = _DIR) -> dict[str, dict]:
    """항목 설정 전부 `{code: cfg}`. 파일 이름과 `code` 가 다르면 예외 — 조용히 엉뚱한 항목에 붙지 않게."""
    out: dict[str, dict] = {}
    for fp in sorted(glob.glob(os.path.join(path, "*.json"))):
        with open(fp, encoding="utf-8") as f:
            cfg = json.load(f)
        code = os.path.splitext(os.path.basename(fp))[0]
        if cfg.get("code") != code:
            raise ValueError(f"{fp}: code={cfg.get('code')!r} 가 파일 이름과 다르다")
        out[code] = cfg
    return out


def human_texts(cfg: dict) -> list[tuple[str, str]]:
    """사람이 쓴 문장 전부 `(자리, 문장)` — 숫자 금지 검사의 대상."""
    out = [(f"intro[{i}]", p) for i, p in enumerate(cfg.get("intro", []))]
    out += [(f"questions[{i}]", q["text"]) for i, q in enumerate(cfg.get("questions", []))]
    out += [(f"notes.{k}", v) for k, v in (cfg.get("notes") or {}).items()]
    return out


def check_no_digits(cfg: dict) -> list[str]:
    """사람 글에 숫자가 있으면 그 자리를 돌려준다(빈 목록 = 통과)."""
    return [f"{cfg['code']}.{where}: {text}" for where, text in human_texts(cfg) if _DIGIT.search(text)]


# 수량어 — 숫자와 같은 이유로 사람 글에서 금지한다. 「대부분의 회사가」는 숫자를 안 썼을 뿐 개수에
# 대한 주장이고, 회사가 늘어 비율이 뒤집히는 날 **아무 경고 없이** 거짓이 된다. 개수는 빌드가 붙인다.
# ⚠ 「적은」은 「원문에 적은」(적다=쓰다)에도 걸린다 — 그 뜻이면 「원문에 쓴」으로 바꿔 쓴다.
QUANTIFIERS = ("대부분", "대다수", "많은", "적은", "보통", "일반적으로", "흔히", "절반", "일부 회사")


def check_quantifiers(cfg: dict) -> list[str]:
    """사람 글에 수량어가 있으면 그 자리를 돌려준다(빈 목록 = 통과)."""
    return [f"{cfg['code']}.{where}: 「{w}」 — {text}"
            for where, text in human_texts(cfg) for w in QUANTIFIERS if w in text]


# notes 가 놓일 수 있는 자리 — 항목 페이지 템플릿이 아는 칸 이름이다. 모르는 키는 **화면에 안 나오고
# 에러도 없다**(템플릿이 그 키를 찾지 않는다). 그래서 목록 밖 키는 설정 오류로 막는다.
NOTE_SLOTS = ("modes", "facets", "money", "questions", "companies")
# 방식 색은 규칙 순서로 붙는다(styles.css `.bn-m1`~`.bn-m4`). 규칙이 더 많으면 색 없는 막대가 나온다.
MAX_MODE_RULES = 4
_SLUG = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
_REQUIRED = ("code", "slug", "title", "intro", "facets", "questions")


def _regex_error(where: str, pattern) -> list[str]:
    try:
        re.compile(pattern)
    except (re.error, TypeError) as exc:
        return [f"{where}: 정규식 오류 {exc}"]
    return []


def validate(cfg: dict) -> list[str]:
    """설정 **구조** 검사 — 오류 목록(빈 목록 = 통과).

    여기서 잡는 것은 전부 「틀려도 화면이 조용히 나오는」 종류다. `answered_by` 가 없는 facet 을
    가리키면 `answered()` 는 늘 False 라 질문 칸에 「원문에 밝힌 회사 없음」이 **거짓으로** 찍히고,
    `display` 에 없는 방식 키는 막대에서 빠진다. 그래서 빌드(`pages/benefit.py`)가 이 검사를 통과한
    설정만 그린다. 사람 글 규칙(숫자·수량어)은 여기가 아니라 `check_no_digits`·`check_quantifiers`.
    """
    code = cfg.get("code", "?")
    errs = [f"{code}: 필수 키 {k} 없음" for k in _REQUIRED if not cfg.get(k)]
    if errs:
        return errs
    if not _SLUG.match(str(cfg["slug"])):
        errs.append(f"{code}: slug {cfg['slug']!r} 형식 오류(소문자·숫자·하이픈)")
    if not all(isinstance(p, str) and p.strip() for p in cfg["intro"]):
        errs.append(f"{code}: intro 는 비지 않은 문단 목록")

    facet_keys = [f.get("key") for f in cfg["facets"]]
    if len(set(facet_keys)) != len(facet_keys):
        errs.append(f"{code}: facet 키 중복 {facet_keys}")
    for f in cfg["facets"]:
        if not f.get("key") or not f.get("label"):
            errs.append(f"{code}: facet 에 key·label 필수 — {f}")
        errs += _regex_error(f"{code}.facets.{f.get('key')}", f.get("pattern"))

    modes = cfg.get("modes")
    mode_keys: list[str] = []
    if modes:
        rules, extra, fb = modes.get("rules") or [], modes.get("extra") or [], modes.get("fallback")
        if not rules or not fb or not fb.get("key") or not fb.get("label"):
            errs.append(f"{code}: modes 는 rules 와 fallback(key·label)이 필요하다")
            return errs
        if len(rules) > MAX_MODE_RULES:
            errs.append(f"{code}: modes.rules {len(rules)}개 — 색이 {MAX_MODE_RULES}개뿐이다")
        for r in rules:
            errs += _regex_error(f"{code}.modes.{r.get('key')}", r.get("pattern"))
        mode_keys = [x.get("key") for x in (*rules, *extra, fb)]
        if len(set(mode_keys)) != len(mode_keys) or not all(x.get("label") for x in (*rules, *extra)):
            errs.append(f"{code}: 방식 키 중복이거나 label 없음 {mode_keys}")
        display = modes.get("display") or []
        if len(set(display)) != len(display) or not set(display) <= set(mode_keys):
            errs.append(f"{code}: modes.display {display} 가 정의된 키 {mode_keys} 의 부분집합이 아니다")

    valid_answers = {f"facet:{k}" for k in facet_keys} | ({"mode:known"} if modes else set())
    for i, q in enumerate(cfg["questions"]):
        if not q.get("text") or not q.get("answered_by"):
            errs.append(f"{code}.questions[{i}]: text·answered_by 필수")
            continue
        bad = [a for a in q["answered_by"] if a not in valid_answers]
        if bad:
            errs.append(f"{code}.questions[{i}]: answered_by {bad} 가 없는 facet/방식을 가리킨다")

    mf = cfg.get("money_facet")
    if mf is not None and mf not in facet_keys:
        errs.append(f"{code}: money_facet {mf!r} 가 facet 에 없다")
    bad_notes = [k for k in (cfg.get("notes") or {}) if k not in NOTE_SLOTS]
    if bad_notes:
        errs.append(f"{code}: notes 키 {bad_notes} 는 놓일 자리가 없다(가능: {NOTE_SLOTS})")

    for o in cfg.get("overrides", []):
        if not (o.get("comp") and o.get("h") and o.get("why")):
            errs.append(f"{code}: override 에 comp·h·why 필수 — {o}")
        if "exclude" in o:
            # 빼는 예외는 `true` 하나뿐이다. 방식·facet 을 함께 적으면 무엇이 이기는지 읽는 사람이 헷갈린다.
            if o["exclude"] is not True:
                errs.append(f"{code}: override {o.get('comp')} exclude 는 true 만 쓴다")
            if any(k in o for k in ("mode", "facets_add", "facets_remove")):
                errs.append(f"{code}: override {o.get('comp')} exclude 는 mode·facets 와 함께 쓸 수 없다")
        if "mode" in o and o["mode"] not in mode_keys:
            errs.append(f"{code}: override {o.get('comp')} mode {o['mode']!r} 가 정의되지 않았다")
        for k in (*o.get("facets_add", []), *o.get("facets_remove", [])):
            if k not in facet_keys:
                errs.append(f"{code}: override {o.get('comp')} facet {k!r} 가 정의되지 않았다")
    return errs


# 문장 끝 = 종결 「다.」「요.」「?」 뒤 공백. 마침표 아무 데서나 자르지 않는다 — 「무급. 유급으로 …」·
# 「… 등.」 같은 조각이 따로 떨어져 나오면 짧은 조각끼리 우연히 겹쳐 반복 검사가 헛발질한다.
_SENT_END = re.compile(r"(?:(?<=다\.)|(?<=요\.)|(?<=\?))\s+")


def sentences(text: str) -> list[str]:
    """사람 글 한 칸 → 문장 목록(공백 정규화). 반복 검사의 단위다."""
    return [" ".join(x.split()) for x in _SENT_END.split(text or "") if x.strip()]


def repeated_sentences(cfgs: dict[str, dict]) -> list[str]:
    """**서로 다른** 설정에 똑같이 실린 사람 글 문장 — 오류 목록(빈 목록 = 통과).

    여러 페이지에 똑같이 반복되는 완결문장이 곧 필러다(애드센스 거절 사유 원문 §5, SP-BEN-7).
    템플릿 쪽은 렌더 테스트가 막지만, 사람 글은 항목마다 다른 사람이 써서 템플릿 검사로는 안 보인다
    (첫 배치 실측: `medical`·`long_service_leave` 의 notes.money 가 한 문장 겹쳤다). 한 설정 **안**의
    반복은 한 페이지 안의 일이라 여기서 보지 않는다.
    """
    where: dict[str, set[str]] = {}
    for code, cfg in cfgs.items():
        for _, text in human_texts(cfg):
            for sent in sentences(text):
                where.setdefault(sent, set()).add(code)
    return [f"사람 글 문장이 설정 {sorted(codes)} 에 겹친다(필러): 「{sent}」"
            for sent, codes in sorted(where.items()) if len(codes) > 1]


def validate_all(cfgs: dict[str, dict]) -> list[str]:
    """설정 전부 — 각자의 `validate` + slug 중복(URL 이 겹치면 한 페이지가 다른 페이지를 덮는다)
    + 설정 사이의 같은 사람 글 문장(`repeated_sentences`)."""
    errs = [e for cfg in cfgs.values() for e in validate(cfg)]
    slugs = Counter(cfg.get("slug") for cfg in cfgs.values())
    errs += [f"slug {s!r} 가 {n}개 설정에 겹친다" for s, n in slugs.items() if n > 1]
    errs += repeated_sentences(cfgs)
    return errs


def classify(cfg: dict, rows: list[dict]) -> dict:
    """원문 행들에 규칙을 적용한다.

    rows: `{comp, desc, note, ...}` 목록(회사당 한 행).
    반환: `{"rows": [{..., mode, facets}], "modes": {key: n}, "facets": {key: n}, "stale": [...],
    "excluded": [{..., why}]}`

    `"exclude": true` 예외는 그 행을 **통째로 뺀다** — `rows`·개수 어디에도 없고 `excluded` 에만 남는다.
    이 항목 코드로 잘못 분류된 행(예: 어린이집 코드인데 어린이집 없이 수당만 주는 회사)을 데이터
    재코딩 전까지 항목 페이지에서만 걷는 용도다. 다른 예외처럼 해시가 다르면 꺼지고(`stale`) 행이
    다시 나타난다 — 원문이 바뀌었으면 잘못 분류됐다는 판정도 다시 봐야 한다.
    """
    modes_cfg = cfg.get("modes")
    facets_cfg = cfg.get("facets", [])
    ov = {(o["comp"]): o for o in cfg.get("overrides", [])}
    stale, used, changed = [], set(), set()
    out_rows, excluded = [], []
    for r in rows:
        t = match_text(r.get("desc"), r.get("note"))
        mode = None
        if modes_cfg:
            mode = modes_cfg["fallback"]["key"]
            for rule in modes_cfg["rules"]:
                if re.search(rule["pattern"], t):
                    mode = rule["key"]
                    break
        facets = {f["key"] for f in facets_cfg if re.search(f["pattern"], t)}
        o = ov.get(r["comp"])
        if o is not None:
            if o["h"] == text_hash(r.get("desc"), r.get("note")):
                used.add(r["comp"])
                if o.get("exclude"):
                    excluded.append({**r, "why": o.get("why", "")})
                    continue
                if "mode" in o:
                    mode = o["mode"]
                facets |= set(o.get("facets_add", []))
                facets -= set(o.get("facets_remove", []))
            else:
                changed.add(r["comp"])
                stale.append(f"{cfg['code']}: {r['comp']} 원문이 바뀌어 예외를 끈다({o.get('why', '')})")
        out_rows.append({**r, "mode": mode, "facets": facets})
    for comp in ov:
        if comp not in used and comp not in changed:
            stale.append(f"{cfg['code']}: {comp} 행이 없어 예외가 쓰이지 않는다")
    modes = {}
    if modes_cfg:
        keys = [x["key"] for x in modes_cfg["rules"]] + [x["key"] for x in modes_cfg.get("extra", [])] \
            + [modes_cfg["fallback"]["key"]]
        modes = {k: sum(1 for r in out_rows if r["mode"] == k) for k in keys}
    facets = {f["key"]: sum(1 for r in out_rows if f["key"] in r["facets"]) for f in facets_cfg}
    return {"rows": out_rows, "modes": modes, "facets": facets, "stale": stale, "excluded": excluded}


def answered(q: dict, row: dict, fallback_mode: str | None) -> bool:
    """질문 하나에 이 행의 원문이 답하는가. `answered_by` = `["facet:키", …]`(하나라도) 또는 `["mode:known"]`."""
    for a in q["answered_by"]:
        kind, _, key = a.partition(":")
        if kind == "facet" and key in row["facets"]:
            return True
        if kind == "mode" and key == "known" and row["mode"] not in (None, fallback_mode):
            return True
    return False
