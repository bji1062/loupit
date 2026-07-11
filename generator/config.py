"""generator/config.py — 빌드타임 설정 상수 소스.

SP-GEN(07 정적 생성기, M5)이 소유하는 파일이다. SP-GEN이 아직 착수되지
않은 시점(M4)에 SP-POL(09 정책 페이지)이 `build_policy_docs(cfg)` 호출에
필요한 설정 키를 요구하므로(SP-POL-2.2), 본 파일은 그 3개 정책 키만 담아
최소로 신설한다. SP-GEN 착수 시 템플릿/출력 경로 등 추가 설정으로 확장된다
(SP-ARCH-6 `generator/` 하위 파일 추가 허용).

시크릿 부재(NFR22): DB 자격·PAT·실 AdSense client id를 포함하지 않는다.
`policy_contact` 실값은 운영자가 배포 시 환경변수로 주입하며 저장소에
커밋하지 않는다.
"""
from __future__ import annotations

import os
from dataclasses import dataclass


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


CFG = GenConfig()
