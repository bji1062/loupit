# HD현대일렉트릭 (전력기기 / KOSPI 267260) — 복지 수집 가능성 실사 프로브

- 회사: HD현대일렉트릭(주) / HD Hyundai Electric Co., Ltd. — DART corp_code 01205851, 설립 2017-04-03
- 프로브 일시: 2026-09-14 · **판정만 수행. 수집·SQL 작성 없음.** 요청 26회(자사 도메인 14 · recruit.hd.com 12, openssl 핸드셰이크 포함)

**판정: 조건부(그룹 공통 복지 — 법인 전용 복지 페이지 없음 · 「복리후생은 계열사간 일부 상이할 수 있습니다」 면책 · 이미 라이브인 HD현대 19행과 같은 원문이라 채택하면 계열사 복제 전개가 된다)**

- 정본 URL(유일한 항목 출처): `https://recruit.hd.com/kr/mainLayout/benefit` — HD현대 그룹 통합 채용사이트. 자사 도메인 `www.hd-hyundaielectric.com` 에는 복지 페이지가 없다.
- 항목 수: **18개 / 3카테고리**(업무 몰입 8 · 생활 지원 7 · 건강 지원 3). 영문판 18개는 같은 목록의 번역이라 따로 세지 않는다.
- 렌더 방식: Vue SPA. HTML 셸 1,781B 에는 본문이 없다. 항목은 **정적 JS 청크 `/js/5869.08a09a96.js` 안에 하드코딩**(API 아님)돼 있다.

> 리드 메모의 핵심 질문 「이 법인 전용 복지 페이지가 따로 있고 그룹 공통과 항목이 다른가」에 대한 답: **없다.**
> 복지 페이지는 컴포넌트(`BenefitPage`) 하나뿐이고, 경로 파라미터·계열사 필터가 없다. 데이터 청크는 2026-09-01 HD현대·HD현대중공업 프로브 때와
> **파일명 해시(`08a09a96`)도 크기(61,050B)도 같다**. 세 회사가 본 원문이 바이트 단위로 같다는 뜻이다. 형제 법인 페이지와 대조할 법인 페이지가 애초에 없다.

---

## ① 공식 채용/복지 페이지 URL

### 자사 도메인 `www.hd-hyundaielectric.com` — 채용·복지 콘텐츠 없음(확인 완료)

DART hm_url 은 **살아 있고 오염되지 않았다**(실제 회사 사이트). 다만 채용 메뉴는 그룹 사이트로 넘기는 외부 링크 하나뿐이다.

| 확인 대상 | 결과 |
|---|---|
| `https://www.hd-hyundaielectric.com/` | 200 · 324B · EUC-KR. `<meta http-equiv="refresh" content="1;url=/elect/ko/index.jsp">` 한 줄짜리 스텁(차단 페이지 아님) |
| 국문 메인 `/elect/ko/index.jsp` | 200 · 62,018B · 0.14s · UTF-8 · SSR(JSP). 링크 전수(주석 제거 후) 중 채용 관련은 **GNB `채용` → `https://recruit.hd.com`(target=_blank)** 와 본문 `채용정보` → 같은 곳 두 개뿐. `복리·복지·welfare·benefit` 0건 |
| 영문 메인 `/elect/en/index.jsp` | 200 · 50,223B. GNB `Recruit` → `https://recruit.hd.com` / `https://recruit.hd.com/en` |
| ESG `esg1`(지속가능경영)·`esg3`(가치경영)·`esg5`(인권경영) | 전부 200. 「임직원」 절은 **안전보건(ISO 45001·비만·직업병 관리)** 서술이고 `복리후생·휴가·어린이집·학자금` 은 0건. 복지 항목 0 |
| `/elect/ko/company/workplace.jsp`(사업장 소개) | 200 · 45,720B. 사업장 목록(아래 ②-3 에 사용) |
| `/sitemap.xml` | **404**(진짜 404 상태 · 2,333B HTML). robots 에도 Sitemap 지시 없음 |
| `recruit.` · `careers.hd-hyundaielectric.com` | **NXDOMAIN** |
| `hd-hyundaielectric.recruiter.co.kr` · `hyundaielectric.recruiter.co.kr` | DNS 응답 없음(와일드카드도 아님 — 임의 이름도 무응답). 전용 ATS 없음 |
| 구 도메인 `www.hyundai-electric.com` | 200 · 758B · 2006년 작성 **로그인 리다이렉트 스텁**(JS 로 `/index_renew.jsp` 또는 `crm.ondemand.com` 으로 보냄). 회사 소개·채용 사이트 아님. 단 채용 담당 이메일 도메인으로는 아직 쓰인다(아래) |
| 푸터 `퇴직자 제증명 신청` | `ex-hihr.hhi.co.kr`(HD현대중공업 HR 시스템) — 복지 무관 |

### 그룹 채용사이트에서의 귀속 경로 — **채용 주체로는 식별되는데, 복지 페이지는 법인을 받지 않는다**

1. 자사 GNB `채용` → `recruit.hd.com`(위 표).
2. `recruit.hd.com` 채용공고·직무 필터의 회사 목록(청크 5869 의 계열사 배열)에 `HD현대일렉트릭` 이 에너지 부문으로 들어 있다. 회사소개 카드 문구는 「HD현대일렉트릭은 국내 최대 전기전자기기 및 솔루션 전문기업으로…」이고 homeUrl 은 `https://www.hd-hyundaielectric.com/elect/ko/index.jsp`.
3. 개인정보처리방침의 회사별 채용 담당자 표에 `HD현대일렉트릭 | 박형규 책임 | 052-202-8014 | …@hyundai-electric.com` 행이 있다(청크 2279).
4. **그러나 복지 라우트는 `{path:"benefit", name:"benefit-kr"}` 로 파라미터가 없다.** 컴포넌트 `BenefitPage` 의 메타 제목은 「HD현대 복리후생」, 설명은 「HD현대가 제공하는 최상의 복리후생 혜택으로…」. 컴포넌트 안의 `query` 6건은 전부 `document.querySelector` 이고 계열사 필터·선택 UI 는 없다. `계열사` 문자열은 각주 한 곳뿐이다.
5. 형제 대조: 법인별 복지 페이지가 존재하지 않으므로 samsungcareers(E21·C60·D80)식 라벨 대조는 성립하지 않는다. 대신 **데이터 청크가 09-01 두 프로브와 같은 파일**이라는 것이 템플릿(그룹 단일 목록)이라는 직접 증거다. 오늘 sha256 = `f2173c9f0a1f781be098fd64371975cd81e03fc6fe7ec661356a051b57b37e9b`.

## ② 복지 항목 명시 여부 — **명시됨 · 18개 / 3카테고리 · JS 번들 안 텍스트(`benefitTitle` + `text`)**

| 카테고리 | 수 | 항목명(원문) |
|---|---:|---|
| Work / 업무 몰입 | 8 | 선택근로제, 유연근로, 자율좌석제, 워케이션, 아침/점심/저녁 제공, 칸틴 운영, 편안한 근무 환경, 통근버스 운영 |
| Life / 생활 지원 | 7 | 생활안정, 기숙사, 우리 아이 지원, 자유로운 휴가 문화, 그룹사 패밀리 카드 운영, 유류비 지원 혜택, 범현대 계열사 할인 |
| Health / 건강 지원 | 3 | 종합검진, 직원 휴식 지원, 건강 케어 (GRC) |
| **계** | **18** | 09-01 HD현대·HD현대중공업 프로브 목록과 한 글자도 다르지 않다 |

**예시 2개(원문)**
- `워케이션` — 「선임 승진자를 대상으로 워케이션을 운영하고 있습니다. 4박 5일간 전국 원하는 근무지에서 근무 가능하며 최대 100만원의 비용을 지원하고 있습니다.」
- `우리 아이 지원` — 「0세부터 5세까지 구성된 학급으로 최고 시설의 교육환경을 갖춘 어린이집을 운영하고 있습니다. … 만 4세부터 6세의 자녀가 있는 직원에게는 매월 50만원의 교육비가 지원됩니다.」

**금액·정량 명시 6항목**: 워케이션 최대 100만원(선임 승진자·4박5일) · 우리 아이 지원 월 50만원(만 4~6세) · 자유로운 휴가 문화 하기휴가 최대 9일 · 그룹사 패밀리 카드 연회비 지원(오일뱅크 리터당 150원 할인·하나머니 10%) · 유류비 월 15만원 이상(**책임급 이상**) · 범현대 할인 현대자동차 5%·현대백화점 10%.

**면책 각주(원문)**: `*복리후생은 계열사간 일부 상이할 수 있습니다.` / 영문 `*Employee benefits may exhibit differences across affiliate companies.`

### ②-3 이 법인의 사업장과 원문의 적합도 — HD현대중공업과는 사정이 다르지만 그래도 법인 확정은 아니다

자사 `workplace.jsp` 기준 국내 사업장:

| 사업장 | 소재지 | 기능 |
|---|---|---|
| **본사** | 경기 성남 분당구 분당수서로 477 **(HD현대 글로벌 R&D센터 = GRC)** | 영업·경영지원 |
| 서울사무소 | 서울 종로구 율곡로 75 현대빌딩 | — |
| 울산 공장 | 울산 동구 방어진순환도로 700 | 전력변압기·고압차단기·전동기·발전기 설계·생산 |
| 울산 선암 공장 | 울산 남구 사평로 223 | 배전반·배전변압기·전력제어시스템 |
| 청주 배전캠퍼스 | 충북 청주 흥덕구 옥산면 | 중저압차단기 |
| R&D | GRC · 용인 기흥구 마북로(연구개발·신뢰성센터) | 연구 |

- 원문의 GRC 전제 항목(자율좌석제·칸틴·허먼밀러 의자·건강 케어(GRC)·수도권 통근버스)은 **본사·R&D 인력에는 실제로 적용될 개연성이 있다**. 울산 조선소가 본사인 HD현대중공업(09-01 불가 사유 「판교 편향 → 울산 조선사 귀속 오표기」)보다는 덜 어긋난다.
- 그러나 **생산 인력은 울산 2개 공장·청주에 있다.** 원문에는 인력 구분이 없고, `기숙사`(「수도권 외 사업장은 기숙사를 운영」)는 오히려 이 공장들을 가리킨다. HD현대(지주) 등록 때 이 항목을 **「지주 본사는 판교」라는 이유로 뺀 것과 정반대 방향**이다. 이 목록 중 어느 항목이 이 법인 어느 인력에 적용되는지 원문으로는 가를 수 없다.

## ③ robots 허용 — **양 도메인 모두 해당 경로 허용 · AI 봇 개별 차단 없음**

| 도메인 | robots.txt | 판정 |
|---|---|---|
| `www.hd-hyundaielectric.com` | 200 · 299B · `text/plain; charset=UTF-8` · **BOM 없음**(`55 73 65 72` = "User") · CRLF. 레코드 1개 `User-agent: *` / Disallow `/ko/jsp/product/` `/en/jsp/product/` `/ko/jsp/customer/download/` `/en/jsp/customer/download/` `/ko/data/` `/en/data/` + Daum 웹마스터 인증 주석. Sitemap 없음 | 실제 경로는 전부 `/elect/ko/…` 라 **Disallow 접두사가 현행 경로와 하나도 맞지 않는다**(개편 전 흔적). 사실상 전면 허용 |
| `recruit.hd.com` | 200 · 58B · **BOM 없음** · `User-agent: *` / `Disallow: /hdcareerAdministrator/` / `Allow: /` | `/kr/mainLayout/benefit` 과 `/js/*` 청크 **허용**. `sitemap.xml`(200 · 2,956B)에 `/kr/mainLayout/benefit`·`/en/mainLayout/benefit` 직접 등재 |
| `hd-hyundaielectric.com`(apex) | TLS 핸드셰이크 실패로 읽을 수 없음(④) | www 가 정본이라 무관 |

- ClaudeBot·anthropic-ai·GPTBot·CCBot·Google-Extended 를 이름으로 지정한 레코드는 **두 파일 어디에도 없다** → 전부 `*` 레코드를 따르며 허용.

## ④ 접근성

| 항목 | 결과 |
|---|---|
| 복지 셸 | `recruit.hd.com/kr/mainLayout/benefit` 200 · 1,781B · 0.33s. **`/kr` 셸과 바이트 동일**(cmp 일치) → 원본 HTML 에 복지 텍스트 0 |
| 데이터 위치 | `/kr` HTML → `/js/app.ed0500cb.js`(17,636B) → 청크 해시맵 → `/js/5869.08a09a96.js`(200 · 61,050B · 0.13s)의 `benefitList`. 각주·레이아웃은 `/js/2279.0664c5f8.js`(623,897B)의 `BenefitPage` 컴포넌트 |
| 헤드리스 렌더 | **생략.** 항목이 정적 청크에 문자열로 있어 렌더 없이 확정할 수 있고, benefit 라우트 하나가 청크 27개를 당겨 요청 한도(40)를 넘긴다. 09-01 HD현대 프로브가 렌더 경로(`.benefit__container`)를 이미 기록했다 |
| 채용공고 API | 공고 상세 청크 `3933.0dd63c31.js` 가 `v1/jobda/getRecruitNotice?recruitNoticeSn=` · `getRecruitNoticeList` 를 호출(JOBDA 연동). 청크 안에 복리후생·처우 필드명은 없다. **공고 본문은 열지 않았다**(휘발성·복지 페이지 아님 — 미검증) |
| 봇 차단 | 두 도메인 모두 없음. WAF·캡차·429 미관측. 일반 브라우저 UA 로 전부 정상 본문(2KB 미만 응답은 324B meta refresh 스텁뿐이고 차단 문구 없음) |
| TLS | `www.hd-hyundaielectric.com` curl exit 0 · TLSv1.3 · CN `*.hd-hyundaielectric.com` · TuringSign RSA Secure CA 2 · **만료 2026-10-02**(3주 남음). `recruit.hd.com` TLSv1.3 · CN `*.hd.com` · Thawte TLS RSA CA G1 · 만료 2026-12-27 |
| ⚠ apex | `https://hd-hyundaielectric.com` **curl exit 35**(`sslv3 alert handshake failure`) — 인증서 SAN 에는 apex 가 있으나 CloudFront 가 apex SNI 를 받지 않는다. `http://` apex 는 **CloudFront 403 · 915B**(「The request could not be satisfied」). **반드시 `www.`** |
| 서버 | 자사: CloudFront → Apache/JSP(`hd_electric_jsessionid` 쿠키, 필수 아님). 그룹: CloudFront |
| 인코딩 | 자사 루트 스텁만 EUC-KR, 본문 페이지는 UTF-8. `recruit.hd.com` 전부 UTF-8 |

## ⑤ 재무·직원 3축

- DART 설립 2017-04-03 = 현대중공업 인적분할 신설 법인. 사업보고서는 FY2017 부터 있을 것으로 보여 이력은 짧지 않다(약 9개년 — **리드 확인**).
- 분할 전(현대중공업 전기전자사업부) 수치는 이 법인의 DART 이력에 없다. 추이 그래프 시작점이 2017년이라는 점만 유의.

---

## 수집 설계 시 유의

1. **채택하면 중복 전개다.** 원문이 이미 라이브인 HD현대 19행(`db/seed/benefit/sql/HD현대.sql`, 같은 URL·같은 청크)과 같다. 웨이브 1 증거(`2026-09-01-evidence/wave1/HD현대.evidence.md`)가 「계열사 상세로 복제 전개 금지 — 같은 문단이 N개사에 붙으면 중복 콘텐츠이자 각주와 모순」으로 막아 둔 경우에 정확히 해당한다. 등록할지는 선발 단계에서 리드가 결정할 사안이다. 이 출처로는 HD현대와 **구별되는 복지를 한 줄도 만들 수 없다.**
2. 그래도 등록한다면 HD현대와 같은 조건이 전제다. 전 행에 「(그룹 통합 채용 기준) 계열사 간 일부 상이 가능」을 붙인다. 항목 선별 규칙도 **HD현대 것을 복사하면 안 된다** — 지주는 판교라서 기숙사를 뺐지만, 이 법인은 생산 사업장이 울산 2곳·청주라 기숙사가 오히려 해당한다. 본사(GRC) 한정 항목과 생산직 해당 항목을 원문으로 가를 수 없다는 점을 판정문에 남길 것.
3. **해시 3단 추적**: `app.js` 해시는 09-01 `deed2f3e` → 오늘 `ed0500cb` 로 바뀌었는데 `5869.08a09a96` 은 그대로다. 갱신 감지는 app 해시가 아니라 **복지 청크 해시(또는 benefitList 바이트 해시)** 로 해야 한다. 앱이 재배포돼도 복지는 안 바뀌었을 수 있다.
4. **호출 규약**: 자사 도메인은 `www.` 필수(apex https 핸드셰이크 실패 · http 403). 자사 인증서가 **2026-10-02 만료**라 그 뒤 재방문 시 TLS 검증 실패 여부를 다시 볼 것. 자사 도메인에서 복지를 찾는 수집기는 0건이 정상이다(「복지 미기재」 오판 금지).
5. 법인 고유 문구가 남아 있을 수 있는 곳은 `recruit.hd.com` 의 **HD현대일렉트릭 명의 채용공고 본문**(`v1/jobda/getRecruitNotice`)뿐인데, 공고는 휘발성이고 계약상 복지 페이지가 아니며 이번에 열지 않았다. 법인 구분 근거가 꼭 필요하면 이것이 남은 유일한 탐색 대상이다.
