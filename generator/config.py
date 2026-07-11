"""generator/config.py — 빌드타임 설정 상수 소스.

SP-GEN(07 정적 생성기, M5) 소유 파일. M4 시점에는 SP-POL(09 정책 페이지)이
`build_policy_docs(cfg)` 호출에 필요한 정책 설정 3키만 담고 있었다. M5(SP-GEN)
착수로 사이트 상수(오리진·OG·AdSense placeholder·경로) 전체를 추가한다
(SP-GEN-1.3, SP-ARCH-6 `generator/` 하위 파일 추가 허용).

시크릿 부재(NFR22): DB 자격·PAT·실 AdSense client id를 포함하지 않는다.
`policy_contact`·`adsense_client_id` 실값은 운영자가 배포 시 환경변수로
주입하며 저장소에 커밋하지 않는다.
"""
from __future__ import annotations

import os
from dataclasses import dataclass, field


@dataclass(frozen=True)
class GenConfig:
    """운영자가 배포 시 주입하는 빌드타임 상수 소스.

    필드 기본값은 모듈 임포트 시점의 환경변수를 읽어 고정된다(운영 배포는
    프로세스 시작 전 env가 확정돼 있으므로 실사용에는 영향 없음). 테스트는
    `GenConfig(legal_reviewed=True)`처럼 필드를 직접 override해 env 오염 없이
    시나리오를 검증한다.
    """

    # SP-POL-2.2 정책 설정 키 (SP-POL 요구, FR-85 · NFR22)
    policy_contact: str = os.environ.get(
        "POLICY_CONTACT", "{운영자 정정·문의 연락처}"
    )
    policy_last_modified: str = os.environ.get(
        "POLICY_LAST_MODIFIED", "{게시 시 운영자 확정}"
    )
    legal_reviewed: bool = os.environ.get("POLICY_LEGAL_REVIEWED", "false") == "true"

    # SP-GEN-1.3 사이트 상수 (FR-50, NFR22, SP-ARCH-6)
    site_origin: str = os.environ.get("SITE_ORIGIN", "https://loupit.co")
    out_dir: str = os.environ.get("GEN_OUT_DIR", "web/dist")
    default_og_image: str = "/assets/og-default.png"  # 사이트 기본 공유 이미지(회사별 없음, FR-55)
    adsense_client_id: str = os.environ.get(
        "ADSENSE_CLIENT_ID", "ca-pub-XXXXXXXXXXXXXXXX"
    )  # placeholder(NFR22)
    compare_path: str = "/compare"  # CTA 진입 경로(SP-FE 셸)
    site_name: str = "loupit"
    lang: str = "ko"
    desc_max: int = 155  # meta description 절단 상한
    # sitemap에 포함되는 비-생성 정적 URL(랜딩 등). /compare(툴 셸)는 색인 대상 제외.
    extra_sitemap_paths: tuple = ("/",)
    # 정책 페이지 4종 (문안 소유 = SP-POL, 렌더·SEO = 본 생성기)
    policy_pages: tuple = field(
        default=(
            ("privacy", "개인정보처리방침"),
            ("terms", "이용약관"),
            ("disclaimer", "데이터 정확성 면책"),
            ("ads", "광고·제휴 고지"),
        )
    )


CFG = GenConfig()
