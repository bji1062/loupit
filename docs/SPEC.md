# SPEC — loupit

> 이 문서는 **얇은 인덱스**다. 요약과 참조 파일 목록, 구현영역 마스터표(SP-대역), 데이터 계약 일치 요약, TDD 커버리지 요약, 상위(FR/NFR)→SPEC 추적 요약만 담는다. 각 SP-*의 상세 계약(DDL·시그니처·수식·라우팅·문안·토큰값·테스트 케이스)은 개별 `SPEC/xx.md` 파일에 있으며 여기서는 서술하지 않는다(개별 SP 상세 금지).

## 1. 목적

loupit SPEC은 FRD가 정의한 각 기능요구(FR-*)를 **개발자가 추측 없이 그대로 만들 수 있는 구현 계약**으로 확정하는 문서군이다. 13개 문서가 아키텍처·데이터·API·엔진·프론트·생성기·광고·정책·디자인·인프라·테스트·**참여(로그인·재직인증)**를 **안정 ID 대역(SP-ARCH·SP-DB·…·SP-AUTH) 1:1**로 나눠 소유하며, 각 항목은 자신이 구현하는 `FR-*`/`FR-D*`/`NFR*`/`INV*`/`UC-*`를 인용해 **SPEC → FRD → USECASE → PRD → 브리프** 추적성을 유지한다. 전역 방침: 디자인은 **옵션1(디자인 토큰만 확정, hi-fi 시안 없음·polish는 개발 후 반복)**, 품질은 **TDD(red-green-refactor, 구현+테스트 통과 둘 다여야 TASK 완료)**이며, 비밀번호·OAuth·소셜 로그인·프로파일러·익명 경로 서버 쓰기는 영구 제외(SC10·SC9, INV-1·INV-4)이나, 복지 등록·수정 기여(SC14)의 무비밀번호 이메일 코드 로그인·재직 인증·복지 편집은 **SP-AUTH(문서 13)**가 소유한다(익명 열람·비교는 로그인 불필요).

## 2. 참조 파일 목록

| 파일 | ID 대역 | 설명 |
| --- | :---: | --- |
| [SPEC/01-개요와-아키텍처.md](SPEC/01-개요와-아키텍처.md) | **SP-ARCH** | 컴포넌트 5종·배포 토폴로지·빌드타임/런타임 데이터 흐름·번들 단일 소스(SP-ARCH-4)·모노레포 디렉토리·버전 pin·SPEC 인덱스·아키텍처 불변식(INV-1~9)·릴리스 파이프라인 |
| [SPEC/02-데이터베이스-스키마.md](SPEC/02-데이터베이스-스키마.md) | SP-DB | MySQL 참조 테이블 5종 DDL·감사컬럼·`AMT_SOURCE_CD`(DEC-2 신규)·9카테고리·배지·제거 테이블(16)/컬럼·백필 마이그레이션 |
| [SPEC/03-데이터-시드-백필.md](SPEC/03-데이터-시드-백필.md) | SP-SEED | 96개 복지 SQL 재이식(→95 등록)·200시드 메타 조인·등록 예외(엔씨·CJ올리브·모비스)·프리셋 28·DEC-2 백필 오케스트레이션·멱등성 |
| [SPEC/04-백엔드-API.md](SPEC/04-백엔드-API.md) | SP-API | 슬림 읽기전용 FastAPI(GET 4종)·`build_reference_bundle`(단일 소스)·Pydantic 모델·aiomysql·인메모리 TTL 캐시·CORS/캐시 헤더·무인증/무쓰기 |
| [SPEC/05-비교-계산엔진.md](SPEC/05-비교-계산엔진.md) | **SP-ENGINE**(≡SP-CALC) | `calc.js` 순수 ES모듈(부수효과 0)·실효연봉·주간근무·야근수당·시간가치·워라밸·불확실성 밴드(DEC-2)·vdCard 판정·희생비용·프로파일러 벡터 제거 |
| [SPEC/06-프론트엔드-구조.md](SPEC/06-프론트엔드-구조.md) | SP-FE | 무빌드 바닐라 JS SPA 셸·해시/History 라우팅·전역 상태(프로파일러 키 없음)·REF 부팅·검색/입력·`normalizeCompany`·엔진 어댑터·리포트 렌더(SP-RPT 흡수)·XSS 이스케이프·"최근 비교" localStorage |
| [SPEC/07-정적-생성기.md](SPEC/07-정적-생성기.md) | SP-GEN | 빌드타임 파이썬 생성기·회사 상세(~95)/인기 조합/정책 4종/404 HTML·slug·Jinja2(autoescape)·SEO(title·OG·JSON-LD·canonical)·sitemap/robots·비-JS 본문·광고 슬롯 자리 |
| [SPEC/08-광고-제휴-통합.md](SPEC/08-광고-제휴-통합.md) | SP-ADS | `adsConfig`(client id 플레이스홀더 단일 주입)·`adPolicy` page_type 게이팅·자동/수동 슬롯(CLS 예약)·`affiliate.json`·"광고" 표기·`rel="sponsored nofollow"`·개인화 동의/비개인화 폴백 |
| [SPEC/09-정책-페이지.md](SPEC/09-정책-페이지.md) | SP-POL | 정책 4종 문안(개인정보/약관/면책/광고고지)·필수 항목·정정요청 임시 창구(서버 무쓰기)·동의↔정책 단일 진실·전역 푸터 링크(404 금지)·밴드 문안 정합 |
| [SPEC/10-디자인-토큰.md](SPEC/10-디자인-토큰.md) | **SP-DS**(≡SP-DSN) | `styles.css` `:root` 디자인 토큰(다크 기본)·색 팔레트·타입 스케일(Pretendard)·간격·반경·모션·배지/밴드/광고 라벨 색·대비 AA 계약(옵션1: 토큰만) |
| [SPEC/11-인프라-배포.md](SPEC/11-인프라-배포.md) | SP-INFRA | OCI Ampere A1 단일 인스턴스·Nginx(정적+`/api/v1` 프록시·TLS·gzip_static·HSTS)·systemd 유닛·MySQL 튜닝(loopback·최소권한)·방화벽·`release.sh` 파이프라인·백업·스모크 |
| [SPEC/12-테스트-전략.md](SPEC/12-테스트-전략.md) | SP-TEST(횡단) | 전역 TDD 원칙·TASK 완료 기준(DoD)·계층/러너 매트릭스·디렉토리·집계 러너(`run_tests.sh`)·스위트 종합 매핑·커버리지 목표(Tier 0/1/2)·로컬 릴리스 게이트·FR/INV 역추적 |
| [SPEC/13-참여-로그인.md](SPEC/13-참여-로그인.md) | **SP-AUTH** | 무비밀번호 이메일 코드 로그인·세션(불투명 토큰·SHA-256·라우트 의존성)·회사 도메인 재직 인증(HMAC·원문 파기·수동 폴백)·복지 등록/수정(배지 강제·낙관적 동시성 `base_dtm`·원자 트랜잭션)·편집 이력 공개·CSRF(`X-Loupit-Client`)·메일러(Console/SMTP)·발송/시도 리밋·운영자 CLI(SC14, 참여 7테이블 DDL은 SP-DB 소유) |

> 대역 별칭·계획 매핑(SP-ARCH-8·SP-TEST-6.2 정합): **SP-CALC ≡ SP-ENGINE**(`calc.js`), **SP-DSN ≡ SP-DS**(디자인 토큰), 구 **SP-RPT는 별도 파일 없이 SP-ENGINE(값)+SP-FE(렌더·저장)로 흡수**. 상호 인용은 파일 번호가 아니라 **안정 ID 대역**으로 해석한다.

## 3. 구현영역 마스터표

각 SP-대역이 소유하는 구현 영역·핵심 산출물·구현하는 상위 FR을 모은다. 상세 항목(SP-N)은 각 담당 문서 참조.

| SP-대역 | 구현 영역 | 핵심 산출물 | 관련 FR / NFR |
| --- | --- | --- | --- |
| **SP-ARCH** | 시스템 아키텍처·경계 | 컴포넌트 5종·토폴로지·데이터 흐름·디렉토리·버전 pin·INV-1~9·릴리스 순서 | FR-01·FR-90·FR-96, NFR1·20·22·23·28 |
| **SP-DB** | 참조 DB 스키마(DDL) | `TCOMPANY_TYPE`·`TCOMPANY`·`TCOMPANY_ALIAS`·`TCOMPANY_BENEFIT`·`TBENEFIT_PRESET` DDL·제약·`AMT_SOURCE_CD`·백필 SQL | FR-D1~D11, NFR29 |
| **SP-SEED** | 데이터 재이식·백필 | 95개 복지 SQL 사본·`company_meta`·프리셋 시드·`load.py`·`backfill_dec2` | FR-D3, D2·D3·D4 |
| **SP-API** | 읽기전용 HTTP 서버 | `main`/`config`/`database`/`cache`/`routers`(GET 4종)/`services.reference`(번들 빌더)/Pydantic 모델 | FR-90~96, FR-D1~D11 |
| **SP-ENGINE** | 클라이언트 계산 엔진 | `calc.js` 순수 함수(연봉·복지·실효연봉·근무시간·야근·시간가치·자율성·통근·밴드·vdCard·희생·`compare`/`calc`) | FR-30~39, FR-42 |
| **SP-FE** | SPA 구조·오케스트레이션 | 셸·라우팅·상태·`boot`/REF·`api`/`apiFetch`·검색·`normalizeCompany`/프리셋·`dom`(escape)·`assembleCompareState`·`report`·`store`(최근 비교) | FR-02·03·07, FR-10~17, FR-20~25, FR-40~45, FR-D4·D6·D7·D8, FR-E1~E3 |
| **SP-GEN** | 빌드타임 정적 생성 | 회사 상세/조합/정책/404 HTML·`slug`·Jinja2 템플릿·SEO head·JSON-LD·`sitemap.xml`·`robots.txt`·릴리스 산출물 | FR-50~65, FR-80(렌더), FR-E5·E6 |
| **SP-ADS** | 광고·제휴 통합 | `adsConfig`·`adPolicy`/`mountAds`·자동/수동 슬롯·`affiliate.json`·동의 배너·"광고" 표기·통합 DOM 계약 | FR-70~79 |
| **SP-POL** | 정책·고지 콘텐츠 | `content/policy.py`(4종 문안)·필수 섹션표·정정 경로·동의↔정책 단일 진실·`POLICY_FOOTER_LINKS` | FR-80~87 |
| **SP-DS** | 디자인 토큰·CSS 시스템 | `styles.css` `:root` 토큰(색·타이포·간격·반경·모션·배지/광고 라벨 색)·`@font-face`·대비 AA 계약 | NFR2·5·13·15·19 |
| **SP-INFRA** | 인프라·배포·운영 | `nginx/loupit.conf`·`systemd/loupit-api.service`·`mysql/loupit.cnf`·`release.sh`·`smoke.sh`·방화벽·TLS·백업 | AS1·AS2, NFR22·23·27·28 |
| **SP-TEST** | 테스트 전략·게이트(횡단) | TDD 규약·러너 매트릭스·`run_tests.sh`·스위트 매핑·Tier 0/1/2·FR/INV 역추적·메타 검증(MT) | 전 FR·NFR(횡단) |
| **SP-AUTH** | 참여·로그인·재직인증(SC14) | `member`/`employment`/`benefit_edit` 라우터·`session`/`auth_code`/`employment`/`benefit_edit` 서비스·`require_member`/`require_employment` 의존성·`mailer`(Console/SMTP)·`ops` CLI·config 확장(금지 substring 재명세) | FR-100~115, NFR16·17·20·21·30·31 |

## 4. 데이터 계약 일치 요약

`reference/all` 번들의 스키마 필드가 **DB → API → 엔진 → 프론트/생성기** 전 계층에서 어떻게 소비되는지 한 줄로 고정한다. 계층 간 필드명·의미가 어긋나지 않아야 한다(단일 소스 `build_reference_bundle`, SP-ARCH-4).

| 필드(계약) | DB(SP-DB) | API(SP-API) | 엔진(SP-ENGINE) | 프론트/생성기(SP-FE/SP-GEN) |
| --- | --- | --- | --- | --- |
| `benefit_amt`(만원) | `BENEFIT_AMT INT`\|NULL | `benefit_amt` int\|null | `benTotal`/`effSalary` 순복지 합산(정성 제외) | 리포트 총보상·회사표 `krw_manwon` 표시 |
| `amt_source`(stated/estimated/none) | `AMT_SOURCE_CD`(별칭→`amt_source`) | `AMT_SOURCE_CD AS amt_source` | **밴드 기준**(`bandCoeff`/`sumBand`, ±5/±20) | 밴드 표기·면책 D-4 문안 정합 |
| `badge_cd`(official/est) | `BADGE_CD` | `badge_cd` | **미사용**(밴드와 디커플링, INV-5) | 배지 표시(`badge_state` 공식/추정/만료) |
| `benefit_ctgr_cd`(9종) | `BENEFIT_CTGR_CD` | `benefit_ctgr_cd` | `benByCat`/카테고리 델타(미상→perks) | 카테고리 그룹 복지표·정성 대비 |
| `qual_yn` | `QUAL_YN BOOLEAN` | `bool` 강제 | 정성=금액/카테고리/밴드 제외 | 금액 생략·`qual_desc` 서술 표시 |
| `expires_dtm` | `EXPIRES_DTM` | ISO8601\|null | 만료 시 밴드 **+0.15 가산**(`now` 주입) | "만료·재확인 필요" 배지 |
| `work_style_val`(JSON) | `WORK_STYLE_VAL JSON` | `json.loads`→dict | `autonomyScore`(unlimitedPTO)·`initWsState` 제안 | 근무형태 5축 표시(true만) |
| `comp_tp_cd` + `company_types[]` | `COMP_TP_ID`→조인 파생(`TCOMPANY_TYPE` = 식별 3 + 감사 4) | `comp_tp_cd`·`comp_tp_nm`(원소 3필드) | 미참조(`companyTypes` 미주입, SP-ENGINE-13b 폐기) | 유형명 표시·프리셋 그룹 키 |
| `aliases[]` | `TCOMPANY_ALIAS` | 인라인 `aliases[]` | — | 검색 매칭·정규화·JSON-LD `alternateName` |
| `value_source`(real/preset/user) | **DB 컬럼 없음** | **API 필드 없음** | 미참조 | 클라이언트 런타임 파생(`fillBenefits`, SP-FE 전용) |

- 최상위 키는 정확히 3종(`company_types`·`benefit_presets`·`companies`)이며 프로파일러 키(`profiles`/`job_groups`/`questions`)는 스키마에 소스 테이블이 없어 구조적으로 부재(INV-2, SP-DB-14). 프리셋은 **직접 입력 모드 템플릿**이며 회사페이지 폴백이 아니다(INV-6).

## 5. TDD 커버리지 요약

브리프 §10 TDD 원칙. 영역별 테스트 유형·러너·케이스 대역을 종합한다(케이스 정의 정본은 각 SP-* 문서, 종합·게이트는 SP-TEST). 자동 ≈227 + 수동 체크리스트 32. SC14 참여(SP-AUTH)는 Tier-0 게이트 AU-1~7 + 기능 테스트 AL·AS·AM·AE·AB·AH·AC·AX·AO를 추가한다.

| SP-대역 | 테스트 유형·계층 | 러너·도구 | 케이스 대역(수) |
| --- | --- | --- | --- |
| SP-ARCH | 통합·횡단 불변식 | pytest·node·bash·curl | T1~T8(고유 4 + 위임 4) |
| SP-DB | DB 스키마·제약·데이터 계약 | pytest + pymysql + MySQL 8 | SC·CN·DC(33) |
| SP-SEED | 시드·이관·배지·멱등 | pytest + pymysql + MySQL 8 | SD·SI·SB·SM(29) |
| SP-API | API 계약(라우트·응답·헤더·오류) | pytest + httpx ASGITransport(무 DB) | TS·TH·TR·TSE·TC·TM·TN·TCORS·TE(26) |
| SP-ENGINE | 순수 계산모듈(경계·0나눗셈·밴드·순수성) | node:test(동일 ES모듈 import) | T-ENGINE(44 — 1~48 중 28·29·30·36 폐기) |
| SP-FE | 프론트 순수로직 + 수동 브라우저 | node:test + in-memory 스텁 / 브라우저 | UT-*(19) + MB(14) |
| SP-GEN | 정적 생성물(개수·SEO·slug·비-JS·이스케이프) | pytest + fake 번들(무 DB) | GC(26) |
| SP-ADS | 순수 게이팅/필터 + 데이터 + 수동 | node:test / `affiliate.json` / 브라우저 | UT-ADS(15) + MB-ADS(12) |
| SP-POL | 정책 콘텐츠 + 생성물 + 푸터 일치 | pytest(fake 번들·수기 셸 파싱) | PC(13) |
| SP-DS | 정적 CSS 파싱·대비 린트 + 수동 | node:test + WCAG 대비 유틸 / axe·육안 | UT-TOKEN/CONTRAST/…(14) + MD(6) |
| SP-INFRA | 설정 정적검증 + 라이브 스모크 | `nginx -t`·`systemd-analyze`·`smoke.sh` | CFG-1~6 · SM-1~14 |
| SP-TEST | 메타(집계 러너·파일 존재·게이트·export 커버리지) | node:test(`harness.test.js`) | MT-1~4 |
| SP-AUTH | 참여 API 계약(세션·로그인·재직·편집)·Tier-0 게이트·CLI | pytest + httpx ASGITransport + pymysql · node | AU-1~7 · AL·AS·AM·AE·AB·AH·AC·AX·AO |

- **Tier 0 회귀 게이트(깨지면 배포 차단)**: T-ENGINE-26(official×estimated=±20%, INV-5)·T-ENGINE-45(순수성 INV-4)·T-ENGINE-41(무크래시), TS-1·2(GET 4종·무쓰기·무인증), TR-1~3·5(번들 계약·프로파일러 키 부재·캐시), SD-3/DC-2(회사 ≈95≠200), SB-1/DC-13(official 승격)·DC-12/SB-6(DEC-2 디커플링), GC-2·10·21(개수·비-JS·XSS), UT-ESC/PC-13(이스케이프), UT-ADS-GATE-1(input 무광고). CI 없음 — `infra/deploy/release.sh` 4·7단계가 로컬 게이트로 강제한다.

## 6. 상위(FR/NFR)→SPEC 추적 요약

FRD 113개 FR과 SP-ARCH 9개 불변식(INV-1~9)이 각각 ≥1 SP-* 대역으로 구현됨을 보증한다(상세 역추적은 SP-TEST-9).

| 상위 대역 | 요지 | 주 소유 SP-* | 지지·연동 SP-* |
| --- | --- | --- | --- |
| FR-01~08(전역 규칙) | 아키텍처 불변식·상태 모델·규약 | SP-ARCH(INV-1~9) | 전 SP-* |
| FR-D1~D11(데이터 계약) | 번들·응답·클라 모델·디커플링 | SP-DB(스키마)·SP-API(직렬화) | SP-FE(`normalizeCompany`)·SP-ENGINE(소비) |
| FR-10~17(검색·회사 선택) | 검색·자동완성·슬롯·직접입력 | SP-FE | SP-API(`companies/search`) |
| FR-20~25(비교 입력) | 연봉·복지·근무형태·통근·우선순위 | SP-FE | SP-ENGINE(입력 파생) |
| FR-30~39·42(계산 엔진) | 실효연봉·시간가치·밴드·vdCard·재계산 | SP-ENGINE | SP-FE(어댑터·재렌더) |
| FR-40~45(리포트·로컬저장) | 판정카드·델타·배지/밴드·XSS·최근 비교 | SP-FE(렌더·저장) | SP-ENGINE(값) |
| FR-50~59(회사 상세 정적) | 빌드타임 ~95·SEO·CTA·sitemap | SP-GEN | SP-DB·SP-SEED·SP-ADS |
| FR-60~65(인기 조합 정적) | `/vs/{a}-{b}` 사전생성·요약·프리필·광고 | SP-GEN | SP-ADS·SP-FE(프리필 소비) |
| FR-70~79(광고·제휴) | AdSense 게이팅·CLS·affiliate·동의 | SP-ADS | SP-GEN/SP-FE(DOM 계약)·SP-POL(동의 링크) |
| FR-80~87(정책·고지) | 정책 4종·정정·단일 진실·푸터 | SP-POL(문안) | SP-GEN(렌더·SEO·sitemap) |
| FR-90~96(읽기전용 API) | GET 4종 전송 계약·캐시·CORS | SP-API | SP-ARCH·SP-INFRA(프록시) |
| FR-E1~E7(오류·엣지 횡단) | 번들 실패·검색 폴백·localStorage·404·비-JS | SP-FE·SP-API·SP-GEN | SP-ARCH |
| FR-100~115(참여·기여, SC14) | 로그인·세션·재직 인증·복지 편집·이력·CSRF·리밋·CLI | SP-AUTH | SP-DB(7테이블)·SP-INFRA(메일·리밋)·SP-POL(약관 T5)·SP-ENGINE(밴드 불변) |
| NFR2·5·13·15·19(성능·접근성·라벨) | LCP/INP/CLS·폰트·WCAG AA·"광고" | SP-DS | SP-ADS·SP-INFRA·SP-GEN |
| AS1·NFR22·23·27·28(인프라·보안) | 단일 인스턴스·TLS·외부차단·자원 | SP-INFRA | SP-ARCH·SP-API |

> 본 인덱스(SPEC.md)는 요약·인덱스·추적만 소유하고, 상세 구현 계약은 각 SP-* 문서가 소유한다(대역-문서 1:1, 대역 충돌·재사용 없음). 비밀번호·OAuth·소셜 로그인·프로파일러·익명 경로 서버 쓰기는 어떤 SP-*에도 없다(SC10·SC9, INV-1·INV-4). 복지 기여(SC14)의 무비밀번호 로그인·재직 인증·복지 편집은 **SP-AUTH(문서 13)**가 소유하며 익명 열람·비교와 분리된다.
