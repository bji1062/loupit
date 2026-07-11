"""generator/slug.py — 회사 slug 규칙·조합 경로 규칙·충돌 검증 (SP-GEN-3).

FR-51(회사 slug)·FR-60 R2·R3(조합 경로)·FR-59(충돌=빌드 실패)·NFR11.
"""
from __future__ import annotations

import re


class BuildError(Exception):
    """빌드타임 검증 실패 — 렌더 산출물을 스왑하지 않고 예외로 표면화한다."""


_SLUG_RE = re.compile(r"[a-z0-9]+(-[a-z0-9]+)*")
_NON_ALNUM_RE = re.compile(r"[^a-z0-9]+")
_DASH_RUN_RE = re.compile(r"-{2,}")


def slug_of(comp_eng_nm: str) -> str:
    """`COMP_ENG_NM` → 안정 URL slug (FR-51).

    소스는 `COMP_ENG_NM`(unique, D1.2)이며 한글 정식명은 URL에 넣지 않는다.
    재빌드 간 동일 입력 → 동일 slug(안정 URL, 색인 유지).
    """
    s = comp_eng_nm.strip().lower()
    s = _NON_ALNUM_RE.sub("-", s)  # 비영숫자(공백·_·기호) → 하이픈
    s = _DASH_RUN_RE.sub("-", s)  # 연속 하이픈 축약
    s = s.strip("-")  # 양끝 하이픈 제거
    if not s:
        raise BuildError(f"empty slug for COMP_ENG_NM={comp_eng_nm!r}")
    if not _SLUG_RE.fullmatch(s):
        raise BuildError(f"invalid slug {s!r}")
    return s


def validate_slugs(companies: list[dict]) -> dict[str, str]:
    """전 회사 slug 유일성 검증 — 충돌 시 빌드 실패 (FR-59).

    반환 `{comp_eng_nm: slug}`.
    """
    slugs: dict[str, str] = {}
    seen: dict[str, str] = {}
    for c in companies:
        s = slug_of(c["comp_eng_nm"])
        if s in seen and seen[s] != c["comp_eng_nm"]:
            raise BuildError(f"slug collision {s!r}: {seen[s]} vs {c['comp_eng_nm']}")
        seen[s] = c["comp_eng_nm"]
        slugs[c["comp_eng_nm"]] = s
    assert len({slugs[c["comp_eng_nm"]] for c in companies}) == len(companies)
    return slugs


def combo_slug(eng_a: str, eng_b: str, slugs: dict[str, str]) -> tuple[str, str, str]:
    """두 회사 slug → 사전식 정규화 canonical 경로 (FR-60 R2).

    역순 쌍(B vs A)은 동일 canonical로 귀속(별도 파일 없음, NFR11).
    반환 `(path, first, second)`.
    """
    sa, sb = slugs[eng_a], slugs[eng_b]
    first, second = sorted([sa, sb])
    return f"{first}-{second}", first, second


def validate_combo_paths(
    pairs: list[tuple[str, str]], slugs: dict[str, str]
) -> dict[str, tuple[str, str]]:
    """전 조합 경로 유일성 빌드타임 강제 (FR-60 R3).

    동일 `first-second` 문자열을 만드는 서로 다른 쌍(세그먼트 모호성) →
    BuildError. 반환 `{combo_path: (eng_a, eng_b)}`.
    """
    out: dict[str, tuple[str, str]] = {}
    for a, b in pairs:
        path, _, _ = combo_slug(a, b, slugs)
        if path in out and set(out[path]) != {a, b}:
            raise BuildError(f"combo path collision {path!r}: {out[path]} vs {(a, b)}")
        out[path] = (a, b)
    return out
