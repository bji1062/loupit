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

# pydantic-settings 가 bool 필드에 쓰는 truthy 문자열 집합(대소문자 무시).
# 서버 `Settings` 와 생성기 `GenConfig` 가 같은 환경변수를 **같은 규칙**으로 읽어야
# 런타임 동작과 정적 문안이 갈라지지 않는다(test_policy_m9 PM-11).
_TRUTHY = frozenset({"1", "true", "t", "yes", "y", "on"})


def env_flag(name: str) -> bool:
    """환경변수를 pydantic 과 동일 규칙으로 bool 파싱한다(미설정·미인식 = False).

    ⚠ 서버 쪽은 빈 문자열(`M9_ENABLED=`)을 ValidationError 로 거부해 **앱이 부팅하지 못한다** —
    여기서 False 로 관대하게 처리해도 배포는 API 재시작 단계에서 실패하므로, `.env` 에는 키를
    아예 두지 않거나 유효값을 넣어야 한다(빈값 금지)."""
    return os.environ.get(name, "").strip().lower() in _TRUTHY


@dataclass(frozen=True)
class GenConfig:
    """운영자가 배포 시 주입하는 빌드타임 상수 소스.

    필드 기본값은 모듈 임포트 시점의 환경변수를 읽어 고정된다(운영 배포는
    프로세스 시작 전 env가 확정돼 있으므로 실사용에는 영향 없음). 테스트는
    `GenConfig(legal_reviewed=True)`처럼 필드를 직접 override해 env 오염 없이
    시나리오를 검증한다.
    """

    # SP-POL-2.2 정책 설정 키 (SP-POL 요구, FR-85 · NFR22)
    # 실값 기본(발견 #8, 2026-07-18 사용자 결정): 플레이스홀더 중괄호가 라이브에 노출되던
    # 문제를 없앤다. env(POLICY_CONTACT/POLICY_LAST_MODIFIED)로 여전히 override 가능.
    policy_contact: str = os.environ.get("POLICY_CONTACT", "bji1062@gmail.com")
    policy_last_modified: str = os.environ.get("POLICY_LAST_MODIFIED", "2026-07-19")
    # 2026-07-19 사용자 결정: 개인 프로젝트 수준으로 확정 게시(초안 배너 해제). 정식 법률
    # 검토는 실수익 발생 시점으로 유예 — 문안이 스스로 '검토 안 된 초안'을 선언하는 상태가
    # 고지 효력·심사·신뢰 모두에 더 해롭다는 판단. env로 여전히 재점등 가능.
    legal_reviewed: bool = os.environ.get("POLICY_LEGAL_REVIEWED", "true") == "true"
    # M9(SC14 참여·로그인) 문안 스위치 — **기본 OFF**. `server/config.Settings.m9_enabled` 와
    # **같은 환경변수**를 읽어, 로그인 배포와 처리방침 문안이 어긋나지 않게 한다.
    #   OFF: "회원가입·로그인·계정 기능이 없습니다"(현 익명 배포의 정확한 기술)
    #   ON : 익명 열람 무수집(P1 개정) + 회원 정보 처리 P7 · 약관 T5 신설
    # 어느 방향이든 어긋나면 처리방침이 허위 기재가 된다 — 로그인은 있는데 "없다"고 하거나,
    # 로그인이 없는데 "기여하려면 로그인이 필요하다"고 하거나(SPEC/09 SP-POL-3·4, test_policy_m9).
    # release.sh 가 `server/.env` 를 `set -a` 로 source 하므로 정적 재생성([4/7])과 API
    # 재시작([5/7])이 한 릴리스 안에서 같은 값을 본다.
    #
    # 파싱은 `env_flag`(= pydantic 과 동일 규칙)로 통일한다. 초판은 `== "1"` 이었는데, 서버
    # Settings 는 pydantic 의 넓은 truthy 집합을 받으므로 `M9_ENABLED=true` 배포에서
    # **서버 ON · 생성기 OFF** 로 갈라졌다 — 로그인은 켜지고 처리방침은 "로그인 없음"으로 남는,
    # 이 스위치가 막으려던 바로 그 상태다(test_policy_m9 PM-11 이 교차 검증).
    m9_enabled: bool = env_flag("M9_ENABLED")

    # SP-GEN-1.3 사이트 상수 (FR-50, NFR22, SP-ARCH-6)
    site_origin: str = os.environ.get("SITE_ORIGIN", "https://jobcho.wiki")
    out_dir: str = os.environ.get("GEN_OUT_DIR", "web/dist")
    default_og_image: str = "/assets/v2/og-default.png"  # 사이트 기본 공유 이미지(회사별 없음, FR-55)
    adsense_client_id: str = os.environ.get(
        "ADSENSE_CLIENT_ID", "ca-pub-6009927622334159"
    )  # AdSense 게시자 ID(공개값). 용도: render_ads_txt의 pub-id 소스(2026-07-21 발급).
    #   ※ 런타임 광고 로더의 client id는 web/assets/js/adsConfig.js AD_CLIENT가 별도 소유
    #     (SPA·정적 공용, static-ads.js→ads.js 경로). 이 config는 정적 ads.txt 생성 전용.
    compare_path: str = "/compare"  # CTA 진입 경로(SP-FE 셸)
    site_name: str = "jobcho.wiki"
    lang: str = "ko"
    desc_max: int = 155  # meta description 절단 상한
    # 본문 임계(자) — 미달 페이지는 noindex + sitemap 제외 (SP-GEN-13).
    # 1,000 인 근거: §G-1 실측에서 회사 페이지 중앙이 1,279자였고 그 아래 23개가
    # 눈에 띄게 부실했다. 임계를 더 올리면 정상 페이지까지 잘려 색인 자산이 줄고,
    # 더 내리면 반려 사유였던 얇은 페이지가 그대로 남는다. 0 이면 판정 비활성.
    thin_page_min_chars: int = 1000
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
