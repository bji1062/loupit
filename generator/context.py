"""generator/context.py — Page 모델·컨텍스트 인덱스 (SP-GEN-2).

모든 렌더 함수(company/combo/policy/sitemap)는 `Page`를 반환한다. 릴리스
(SP-GEN-11)·sitemap(SP-GEN-9)·검증(SP-GEN-12)이 공통 소비하는 단일 산출 타입.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime

from generator.employ import is_loaded as employ_is_loaded
from generator.employ import normalize as employ_normalize
from generator.finance import is_loaded
from generator.slug import validate_slugs


@dataclass(frozen=True)
class Page:
    """생성기의 단일 산출 단위 (SP-GEN-2.2)."""

    path: str  # dist 상대 경로 (예: "company/samsung-elec.html")
    url: str  # 절대 canonical URL (예: "https://jobcho.wiki/company/samsung-elec")
    html: str  # 완성 HTML(또는 sitemap/robots는 xml/txt) 문자열
    title: str  # <title> 텍스트(중복 검증용, FR-59)
    description: str  # meta description(중복 검증용)
    in_sitemap: bool = True  # 404 등은 False
    content_type: str = "text/html; charset=utf-8"


@dataclass
class Ctx:
    """빌드 컨텍스트 — 번들 인덱스·slug 매핑·빌드 시각 (SP-GEN-2.3)."""

    companies: list[dict]
    by_eng: dict[str, dict]
    by_id: dict
    types_by_cd: dict[str, dict]
    slugs: dict[str, str]
    build_now: datetime = field(default_factory=datetime.utcnow)
    # 회사별 재무(SP-FIN-4, 2026-08-27) — `{comp_id: FinanceView}`. 번들 dict **밖**에서 온다:
    # 번들은 런타임 API(`reference/all`)와 단일 소스라 키를 더하면 600KB 응답·Pydantic 화이트리스트
    # ·클라이언트 정규화가 같이 움직인다(함정 (55)). 소비처가 정적 페이지뿐이라 여기 붙인다.
    finance: dict = field(default_factory=dict)
    # 회사별 직원 현황(SP-MET-8, 2026-08-28) — `{comp_id: {year: {salary, tenure, head}}}`.
    # 재무와 **같은 이유로** 번들 밖에서 온다(함정 (55)). 재무와 나란히 두는 것은 화면이 둘을 카드
    # 6장으로 합치기 때문이고, 합치는 규칙은 `generator/employ.py::company_metrics` 하나뿐이다.
    employ: dict = field(default_factory=dict)

    @property
    def finance_loaded(self) -> bool:
        """수치가 한 건이라도 있어야 '재무가 실렸다'. 매핑만 있고 수치 0건(수집 전)은 미적재다 —
        그 상태에서 '공시 데이터 없음'을 102개사 전부에 찍으면 그게 거짓이다."""
        return is_loaded(self.finance)

    @property
    def employ_loaded(self) -> bool:
        """직원 현황도 같은 경계다 — 수집 전 릴리스가 전 회사에 "값 없음"을 찍지 않게 한다."""
        return employ_is_loaded(self.employ)


def build_context(bundle: dict, now: datetime | None = None, finance: dict | None = None,
                  employ: dict | None = None) -> Ctx:
    """번들 dict → 인덱스·slug 검증 완료된 `Ctx` (SP-GEN-2.3).

    slug 충돌은 `validate_slugs`가 `BuildError`로 표면화한다(SP-GEN-3).
    `finance`·`employ` 는 선택(SP-FIN-4·SP-MET-8) — None 이면 그 섹션 없는 기존 렌더 경로 그대로다.
    키는 int 로 정규화한다(JSON 덤프를 거치면 문자열로 떨어진다). 직원 현황은 두 겹이라 연도까지
    되돌려야 한다 — `employ.normalize` 가 그 규칙의 유일한 자리다.
    """
    companies = bundle["companies"]
    by_eng = {c["comp_eng_nm"]: c for c in companies}
    by_id = {c["comp_id"]: c for c in companies}
    types_by_cd = {t["comp_tp_cd"]: t for t in bundle["company_types"]}
    slugs = validate_slugs(companies)
    return Ctx(
        companies=companies,
        by_eng=by_eng,
        by_id=by_id,
        types_by_cd=types_by_cd,
        slugs=slugs,
        build_now=now or datetime.utcnow(),
        finance={int(k): v for k, v in (finance or {}).items()},
        employ=employ_normalize(employ),
    )
