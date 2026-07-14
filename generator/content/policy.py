"""generator/content/policy.py — 정책·고지 문안 단일 소스 (SP-POL 소유).

SP-GEN `generator/pages/policy.py::render_all`(M5)가 `build_policy_docs(cfg)`를
import·호출해 4개 `PolicyDoc`을 얻고 `templates/policy.html`로 감싸 렌더한다
(SP-POL-1). 본 모듈은 문안·필수 섹션·상수만 소유하며, 렌더 마크업(HTML)은
소유하지 않는다(SP-GEN 위임, SP-POL 범위 경계).

법률 검토 필요 표기(SP-POL-2.3): `cfg.legal_reviewed`가 False인 동안 4종
전부 `draft=True`로 초안 배너를 노출한다. 문안은 창작 없이 사실만 담고
미확정 값(연락처·최종 수정일)은 `generator.config.GenConfig` 플레이스홀더로
남긴다.
"""
from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class PolicySection:
    """정책 문서 내 필수 항목 1개 단위 (SP-POL-2.1)."""

    req_id: str  # 상위 필수 항목 ID: "P1"/"T1"/"D-1"/"A-1" … (추적·검증 키)
    anchor: str  # 목차·본문 앵커 id (예: "p1") — 순수 <a href="#p1"> 이동(비-JS)
    toc_label: str  # 목차에 표시할 짧은 라벨
    heading: str  # 본문 <h2> 제목
    paragraphs: tuple[str, ...]  # 초안 한국어 문단(≥1). Jinja autoescape로 안전 삽입
    cross_route: str | None = None  # 본문 내 정책 상호 링크 대상 라우트(예: "/disclaimer")


@dataclass(frozen=True)
class PolicyDoc:
    """정책 문서 1종 (SP-POL-2.1). SP-GEN이 `templates/policy.html`로 감싼다."""

    key: str  # "privacy" | "terms" | "disclaimer" | "ads"
    route: str  # "/privacy" …            (canonical, SP-POL-1)
    filename: str  # "privacy.html" …        (dist 파일)
    title: str  # <h1> 및 <title> 기반 정책명(SP-GEN이 " | loupit" 접미)
    meta_description: str  # meta description 초안(SP-GEN이 desc_max로 절단)
    sections: tuple[PolicySection, ...]
    related: tuple[tuple[str, str], ...]  # C3 상호 링크 [(라벨, route)]
    show_correction: bool = True  # C2 정정·문의 연락 경로 노출(SP-POL-7)
    ads_none: bool = True  # ▢ "광고 없음" 표식(SP-POL-9)
    draft: bool = True  # 초안 배너 노출(법률 검토 필요) — 확정 게시 시 False


def _S(
    req_id: str,
    anchor: str,
    toc_label: str,
    heading: str,
    paragraphs: tuple[str, ...],
    cross_route: str | None = None,
) -> PolicySection:
    """PolicySection 생성 헬퍼 (SP-POL-2.1)."""
    return PolicySection(
        req_id=req_id,
        anchor=anchor,
        toc_label=toc_label,
        heading=heading,
        paragraphs=paragraphs,
        cross_route=cross_route,
    )


# 상위 필수 항목 ID 집합(검증 PC-2): 문안 누락 방지의 계약
REQUIRED_ITEMS = {
    "privacy": {"P1", "P2", "P3", "P4", "P5", "P6"},
    "terms": {"T1", "T2", "T3", "T4"},
    "disclaimer": {"D-1", "D-2", "D-3", "D-4", "D-5", "D-6", "D-7"},
    "ads": {"A-1", "A-2", "A-3", "A-4", "A-5"},
}

POLICY_KEYS = ("privacy", "terms", "disclaimer", "ads")  # 순서·집합 정본(검증 PC-1)

# 초안 배너 문안 (SP-POL-2.3) — 창작 없이 사실만 담는다.
DRAFT_BANNER = (
    "본 문서는 초안입니다. 실제 게시 전 법률 자문 검토가 필요하며, "
    "구체 문구·연락처·최종 수정일은 운영자가 확정합니다."
)

# 전역 푸터 정책 4종 링크 정본 상수 (SP-POL-9.1). 소비처: SP-GEN
# `templates/partials/_footer.html`(생성 페이지 순회 렌더) · SP-FE 수기 셸
# `web/index.html`·`web/compare/index.html`(무빌드 정적 HTML이라 하드코딩,
# 본 상수를 정본으로 PC-5가 양측 일치를 강제).
POLICY_FOOTER_LINKS = (
    ("개인정보처리방침", "/privacy"),
    ("이용약관", "/terms"),
    ("데이터 정확성 면책조항", "/disclaimer"),
    ("광고·제휴 고지", "/ads"),
)


def _privacy(cfg) -> PolicyDoc:
    """개인정보처리방침 문안 (P1~P6, SP-POL-3, FR-81)."""
    return PolicyDoc(
        key="privacy",
        route="/privacy",
        filename="privacy.html",
        title="개인정보처리방침",
        meta_description=(
            "loupit은 로그인·회원이 없어 개인정보를 서버에 저장하지 않습니다. "
            "브라우저 저장 항목·광고 쿠키·제3자 처리·개인화 동의를 안내합니다."
        ),
        sections=(
            _S(
                "P1", "p1", "수집·저장 안 함", "수집·저장하지 않는 정보",
                (
                    "loupit은 회원가입·로그인·계정 기능이 없습니다. 이용자를 식별하는 "
                    "개인정보(이름·이메일·전화번호 등)를 서버에 수집하거나 저장하지 "
                    "않습니다.",
                ),
            ),
            _S(
                "P2", "p2", "localStorage 한정", "브라우저에만 저장되는 항목",
                (
                    "비교 입력값(연봉·통근시간·복지 선택 등)과 '최근 비교' 기록은 "
                    "이용자의 브라우저 localStorage에만 저장되며, loupit 서버로 "
                    "전송·저장되지 않습니다. 다른 기기와 동기화되지 않고, 브라우저 "
                    "데이터를 지우면 함께 삭제됩니다.",
                    "예외로, '실시간 비교 TOP 10' 집계를 위해 비교 실행 시 선택한 "
                    "두 회사의 식별번호 쌍만 익명으로 서버에 전송·집계됩니다. 이 "
                    "전송에는 이용자 식별 정보나 연봉 등 입력값이 포함되지 않으며, "
                    "누가 비교했는지는 저장되지 않습니다.",
                ),
            ),
            _S(
                "P3", "p3", "광고 쿠키", "광고 쿠키(Google AdSense)",
                (
                    "loupit은 Google AdSense 광고를 게재하며, 광고 제공을 위해 Google이 "
                    "쿠키 및 유사 기술을 사용할 수 있습니다.",
                ),
            ),
            _S(
                "P4", "p4", "제3자·동의", "제3자 처리·개인화 동의/거부",
                (
                    "Google 등 제3자가 쿠키를 통해 광고·분석 목적의 정보를 처리할 수 "
                    "있습니다. 이용자는 사이트의 광고·쿠키 동의 안내에서 개인화 광고에 "
                    "대한 동의 또는 거부를 선택할 수 있습니다.",
                ),
                cross_route="/ads",
            ),
            _S(
                "P5", "p5", "거부해도 이용", "거부해도 이용 가능",
                (
                    "개인화 광고를 거부하더라도 사이트 이용에는 제한이 없으며, "
                    "비개인화 광고가 표시되거나 광고가 표시되지 않을 수 있습니다.",
                ),
            ),
            _S(
                "P6", "p6", "식별정보 미수집", "재직자 식별정보 미수집",
                (
                    "복지·근무조건 정보는 회사가 공개한 제도·사실만을 대상으로 하며, "
                    "특정 재직자의 실명이나 식별 가능한 개인정보는 수집하지 않습니다.",
                ),
            ),
        ),
        related=(("이용약관", "/terms"), ("광고·제휴 고지", "/ads")),
        draft=not cfg.legal_reviewed,
    )


def _terms(cfg) -> PolicyDoc:
    """이용약관 문안 (T1~T4, SP-POL-4, FR-82)."""
    return PolicyDoc(
        key="terms",
        route="/terms",
        filename="terms.html",
        title="이용약관",
        meta_description=(
            "loupit 이용약관 — 복지·연봉·근무조건 비교 정보 도구(비-채용 플랫폼), "
            "로그인·회원 없음, 참고용 정보 제공과 일반 이용 조건을 안내합니다."
        ),
        sections=(
            _S(
                "T1", "t1", "서비스 성격", "서비스 성격",
                (
                    "loupit은 한국 회사의 복지·연봉·근무조건을 비교·열람하는 정보 "
                    "도구입니다. 채용 공고 탐색·지원을 제공하는 채용 플랫폼이 "
                    "아닙니다.",
                ),
            ),
            _S(
                "T2", "t2", "로그인·계정 없음", "로그인·계정 없음",
                (
                    "본 서비스는 로그인·회원가입 없이 제공되며, 이용자 계정·즐겨찾기·"
                    "소셜 기능을 제공하지 않습니다.",
                ),
            ),
            _S(
                "T3", "t3", "참고용·의사결정 책임", "참고용·의사결정 책임",
                (
                    "제공되는 정보는 참고용이며, 최종 확인과 의사결정 책임은 "
                    "이용자에게 있습니다. 데이터 정확성에 관한 상세는 데이터 정확성 "
                    "면책조항에서 확인해 주세요.",
                ),
                cross_route="/disclaimer",
            ),
            _S(
                "T4", "t4", "일반 이용 조건", "일반 이용 조건",
                (
                    "콘텐츠 이용 조건, 서비스의 변경·중단 가능성 등 일반 이용 조건은 "
                    "운영자가 확정하여 게시합니다.",
                ),
            ),
        ),
        related=(("개인정보처리방침", "/privacy"), ("데이터 정확성 면책조항", "/disclaimer")),
        draft=not cfg.legal_reviewed,
    )


def _disclaimer(cfg) -> PolicyDoc:
    """데이터 정확성 면책조항 문안 (D-1~D-7, SP-POL-5, FR-83·DEC-2).

    D-4 밴드 계수(±5% stated · ±20% estimated · +15% 만료 가산)는
    SP-CALC(`web/assets/js/calc.js` `BAND_BASE`·`BAND_EXPIRE`)와 문자열·의미
    모두 정확히 일치해야 한다(PC-6, INV-5). 출처 배지(`badge_cd`) 기준
    서술은 금지한다(DEC-2 디커플링).
    """
    return PolicyDoc(
        key="disclaimer",
        route="/disclaimer",
        filename="disclaimer.html",
        title="데이터 정확성 면책조항",
        meta_description=(
            "loupit 데이터 정확성 면책조항 — 복지·연봉 정보는 참고용이며, 출처 "
            "신뢰도 배지와 금액 신뢰도 기준 불확실성 밴드·정정 요청 경로를 "
            "안내합니다."
        ),
        sections=(
            _S(
                "D-1", "d1", "참고용", "참고용·실제와 다를 수 있음",
                (
                    "복지·연봉·근무조건 데이터는 참고용이며 실제와 다를 수 있습니다. "
                    "채용 등 중요한 의사결정 전에는 회사 공식 정보로 반드시 최종 "
                    "확인하시기 바랍니다.",
                ),
            ),
            _S(
                "D-2", "d2", "출처 신뢰도 배지", "출처 신뢰도 배지(공식/추정)",
                (
                    "각 복지 항목에는 출처 신뢰도 배지가 표시됩니다. 공식(official)은 "
                    "회사 공식 공개 정보에 근거한 항목, 추정(est)은 집계·프리셋 등 "
                    "추정에 근거한 항목입니다.",
                ),
            ),
            _S(
                "D-3", "d3", "출처≠금액 신뢰도", "출처 신뢰도 ≠ 금액 신뢰도",
                (
                    "출처가 공식이라도 금액은 추정치일 수 있습니다. 출처의 신뢰도와 "
                    "금액의 신뢰도는 별개로 표기되며, 추정 금액은 더 넓은 오차로 "
                    "표시됩니다.",
                ),
            ),
            _S(
                "D-4", "d4", "불확실성 밴드", "불확실성 밴드",
                (
                    "복지 금액에는 불확실성 밴드가 적용됩니다. 밴드는 출처 배지가 "
                    "아니라 금액 신뢰도를 기준으로 하며, 명시 금액은 ±5%, 추정 "
                    "금액은 ±20%, 만료된 항목은 +15%를 가산해 넓힙니다. 따라서 "
                    "출처가 공식이어도 금액이 추정치이면 ±20% 밴드가 유지됩니다.",
                ),
            ),
            _S(
                "D-5", "d5", "검증일·만료", "검증일·만료",
                (
                    "각 항목에는 검증일과 만료 시점이 있으며, 만료된 항목은 "
                    "'재확인 필요'로 표기되고 오차 범위가 넓어집니다.",
                ),
            ),
            _S(
                "D-6", "d6", "계산·우열 무단정", "브라우저 계산·우열 무단정",
                (
                    "비교 계산은 이용자의 브라우저에서 수행되며, loupit은 특정 "
                    "회사가 절대적으로 유리하다고 단정하지 않습니다.",
                ),
            ),
            _S(
                "D-7", "d7", "정정 요청 경로", "정정 요청 경로",
                (
                    "데이터 정정을 원하시면 아래 정정·문의 연락처로 요청해 주세요. "
                    "접수된 요청은 검토 후 다음 빌드에 반영됩니다.",
                ),
            ),
        ),
        related=(("개인정보처리방침", "/privacy"), ("이용약관", "/terms")),
        show_correction=True,
        draft=not cfg.legal_reviewed,
    )


def _ads(cfg) -> PolicyDoc:
    """광고·제휴 고지 문안 (A-1~A-5, SP-POL-6, FR-84)."""
    return PolicyDoc(
        key="ads",
        route="/ads",
        filename="ads.html",
        title="광고·제휴 고지",
        meta_description=(
            "loupit 광고·제휴 고지 — Google AdSense 광고와 제휴 링크로 운영되며, "
            "모든 광고·제휴 영역에 '광고' 라벨을 표기하고 제3자 쿠키·개인화 동의를 "
            "안내합니다."
        ),
        sections=(
            _S(
                "A-1", "a1", "수익 모델", "수익 모델",
                (
                    "loupit은 Google AdSense 광고와 제휴(affiliate) 링크로 운영 "
                    "비용을 충당합니다. 유료 구독이나 결제 기능은 없습니다.",
                ),
            ),
            _S(
                "A-2", "a2", "'광고' 표기", "'광고' 표기",
                (
                    "모든 광고 및 제휴 영역에는 '광고'(또는 '유료 광고') 라벨을 "
                    "이용자가 인지할 수 있게 표기하며, 이를 숨기지 않습니다.",
                ),
            ),
            _S(
                "A-3", "a3", "제휴 수수료 관계", "제휴 수수료 관계",
                (
                    "제휴 링크를 통해 이동·구매가 발생하면 제휴사로부터 수수료를 "
                    "받을 수 있습니다.",
                ),
            ),
            _S(
                "A-4", "a4", "제3자 광고 쿠키·동의", "제3자 광고 쿠키·개인화 동의",
                (
                    "광고 게재를 위해 Google 등 제3자가 쿠키를 사용할 수 있으며, "
                    "개인화 광고 동의/거부를 선택할 수 있습니다. 자세한 내용은 "
                    "개인정보처리방침과 사이트의 동의 안내를 확인해 주세요.",
                ),
                cross_route="/privacy",
            ),
            _S(
                "A-5", "a5", "공정위 표시·광고 규정", "공정위 표시·광고 규정 정합",
                (
                    "광고·제휴 표기는 공정거래위원회의 표시·광고 관련 규정(추천·"
                    "보증 등에 관한 표시·광고 심사지침의 취지)에 따릅니다.",
                ),
            ),
        ),
        related=(("개인정보처리방침", "/privacy"), ("데이터 정확성 면책조항", "/disclaimer")),
        draft=not cfg.legal_reviewed,
    )


def build_policy_docs(cfg) -> list[PolicyDoc]:
    """4종 PolicyDoc을 확정 순서(privacy, terms, disclaimer, ads)로 반환.

    cfg = generator.config.GenConfig 인스턴스(운영자 주입 상수 소스).
    """
    return [_privacy(cfg), _terms(cfg), _disclaimer(cfg), _ads(cfg)]
