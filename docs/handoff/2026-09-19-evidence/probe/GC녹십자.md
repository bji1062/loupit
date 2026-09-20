# GC녹십자 (GC Biopharma · (주)녹십자 · KOSPI 006280) — 복지 수집 가능성 실사 프로브

- 회사: 주식회사 녹십자 / 제약·혈액제제·백신. 등재 표시명 **GC녹십자**, 별칭에 **「녹십자」** 필수(DART 정식명이 「녹십자」)
- DART: corp_code **00129679**, stock_code 006280 (`_ROSTER.md` 6번 행 기재값. 이번 프로브에서 DART 는 조회하지 않았다)
- 법인 식별값(자기 도메인 푸터 실측): **㈜녹십자 · 사업자등록번호 303-81-17108 · 경기도 용인시 기흥구 이현로 30번길 107 (보정동) · Tel 031-260-9300 / Fax 031-260-9433**
- 프로브 일시: 2026-09-20 (HTTP 요청 23회 + TLS 핸드셰이크 2회. robots.txt 4건은 호스트마다 단독으로 먼저 받았고, 본문은 그 판정 뒤에만 요청했다)

**판정: 가능** — 그룹 채용사이트(`recruit.gccorp.com`)의 **GC녹십자 법인 전용 복리후생 페이지**에 22항목/4카테고리가 서버렌더 HTML 텍스트로 있다. robots 허용(AI 봇 개별 차단 없음)·봇 차단 없음·TLS 정상. 단 **정본 도메인이 자기 도메인이 아니라 지주(녹십자홀딩스) 소유 도메인**이라는 점은 출처 표기에 반드시 남겨야 한다.

- 정본 URL: `https://recruit.gccorp.com/kor/culture/benefits/gc-biopharma` (가족사 탭 「GC녹십자」 = `active`, `h2.company-title` = `GC녹십자`)
- 항목 수: **22항목 / 4카테고리**(6·5·6·5). 보조 정본 `/kor/culture/hr/gc-biopharma`(인사제도)에 근무제도 6건 추가 — 아래 ②-3
- 렌더 방식: **SSR HTML 텍스트**(Apache + Java/Spring, JSESSIONID). 항목 전부가 최초 HTML 의 `ol.description-list > li.description-item > div.item-content > p` 안에 있다. 이미지·JS 렌더·숨김 탭 없음 → `curl` + HTML 파서로 충분

> ⚠ **가장 큰 함정: `gccorp.com` 은 GC녹십자 도메인이 아니라 지주 (주)녹십자홀딩스(KOSPI 005250) 도메인이다.** `https://www.gccorp.com/` 의 `<title>` 이 `(주)녹십자홀딩스`이고 푸터 사업자등록번호가 **135-81-05009**(GC녹십자의 303-81-17108 과 다름)다. 같은 사이트의 `/kor/culture/benefits/**gc**` 는 **지주 복지 25항목**이고 GC녹십자 것이 아니다. 슬러그 한 토막(`gc` ↔ `gc-biopharma`) 차이로 다른 법인 복지가 붙는다.

---

## ① 공식 채용/복지 페이지 URL

### 도메인 생존 확인

| 호스트 | DNS | GET 결과 | 판정 |
|---|---|---|---|
| `www.gcbiopharma.com` | 3.38.13.140 | `/` → **301** → `/kor/index.do` → 200 · 49,176B · 0.15s · `<title>GC녹십자` | **GC녹십자 공식 자기 도메인(생존)** |
| `gcbiopharma.com` (apex) | 3.38.13.140 | **301 → `https://www.gcbiopharma.com/kor/index.do`** | www 로 정규화 |
| `careers.gcbiopharma.com` | 34.84.36.126 (`RMK50.jobs2web.com`) | 200 · 67,633B · 0.38s · `<title>` **빈 문자열** | SAP SuccessFactors RMK 껍데기. 자체 복지 콘텐츠 0 — 아래 참조 |
| `recruit.gccorp.com` | 218.236.125.181 | 200 · `<title>GC녹십자그룹 채용사이트` | **그룹 채용사이트(정본 호스트)** |
| `www.gccorp.com` | 218.236.125.182 | 301 → `/kor/index` → 200 · 38,797B · `<title>(주)녹십자홀딩스` | **지주 법인 사이트 — 다른 법인** |
| `greencross.com` | **172.16.2.176 (RFC1918 사설 IP)** | 요청 불가 | **죽은 레코드**. `www.greencross.com` 은 **NXDOMAIN**(curl exit 6). DART hm_url 이 이쪽이면 오염으로 보고 `www.gcbiopharma.com` 으로 갈아탈 것 |
| `gcbiopharma.co.kr` / `recruit.gcbiopharma.com` / `careers.gccorp.com` / `career.gccorp.com` | — | NXDOMAIN | 없음 |

- `greencross.com` 은 버려진 도메인이 아니라 **여전히 GC 소유**다(아래 ④ TLS 의 SAN 에 `greencross.com` 포함). 다만 A레코드가 사설 IP라 외부에서 못 뜬다.

### 자기 도메인 `www.gcbiopharma.com` — **복지 페이지 없음 (확인 완료)**

- 홈(`/kor/index.do`) 원본 HTML 의 href 전수(68개)에서 채용·복지 관련 링크는 **단 하나**, 외부로 나가는 `https://recruit.gccorp.com/kor/main` 뿐이다. 푸터 "Careers 미래를 함께할 인재 채용" 도 같은 곳으로 간다.
- `https://www.gcbiopharma.com/sitemap.xml` : 200 · 3,853B · `<loc>` **24개** — `recruit`·`career`·`welfare`·`benefit`·`people`·`hr` **0건**. 회사소개/제품/IR/ESG 계열뿐이다.
- → 에스티팜과 달리 **자기 도메인이 정본이 될 수 없다.** 삼성화재 선례(자기 도메인에 복지 0 → 그룹 채용사이트의 법인 전용 페이지가 정본)와 같은 구조다.

### `careers.gcbiopharma.com` — 회사명 서브도메인이지만 내용은 전부 외부 링크

- SAP SuccessFactors Recruiting Marketing(`jobs2web.com`, `career_company=gccorpP1`) 인스턴스. 가시 텍스트 1,204자 중 대부분이 쿠키 동의문이고, **복지 항목 0**.
- 링크 전수: `recruit.gccorp.com` 의 `/kor/about/introduction`·`/kor/culture/hr/gc`·`/kor/brand/gc-campus`·`/kor/recruit/list`·`/kor/faq/list` + `career50.sapsf.com/career?career_company=gccorpP1`. 즉 **그룹 채용사이트로 넘기는 껍데기**이고, 나가는 링크도 그룹 기본값(`/culture/hr/**gc**`, 지주 탭)이다.
- → 회사명이 붙은 서브도메인이지만 **출처로 쓸 콘텐츠가 없다.** 정본은 `recruit.gccorp.com` 쪽이다.

### 정본 = 그룹 채용사이트 `recruit.gccorp.com` 의 GC녹십자 법인 전용 탭

| 용도 | URL |
|---|---|
| **복리후생 (정본)** | `https://recruit.gccorp.com/kor/culture/benefits/gc-biopharma` |
| 인사제도 (보조 정본) | `https://recruit.gccorp.com/kor/culture/hr/gc-biopharma` |
| 교육 (항목 0, 참고) | `https://recruit.gccorp.com/kor/culture/edu/gc-biopharma` |
| 영문판 (해석 보조, 정본 아님) | `https://recruit.gccorp.com/eng/culture/benefits/gc-biopharma` |
| 가족사 소개(귀속 경로) | `https://recruit.gccorp.com/kor/about/gc-family-1` |
| **지주 복지 — 절대 쓰지 말 것** | `https://recruit.gccorp.com/kor/culture/benefits/gc` |

**운영 주체**: 이 사이트의 푸터는 **(주)녹십자홀딩스 · 사업자등록번호 135-81-05009 · Fax 031-260-9413** 이다(모든 하위 페이지 동일). 즉 호스트는 지주 것이고, 그 위에 **가족사 16개의 법인별 탭**이 얹혀 있는 구조다.

**귀속 경로 (GC녹십자가 채용 주체로 식별되는 근거)**
1. GC녹십자 자기 도메인 `www.gcbiopharma.com` 홈의 유일한 채용 링크 → `recruit.gccorp.com/kor/main`.
2. `recruit.gccorp.com` GNB `GC Culture > 복리후생` → `/kor/culture/benefits/gc` → 상단 **가족사 탭 16개** 중 **「GC녹십자」** → `/kor/culture/benefits/gc-biopharma`.
   (탭 슬러그: `gc` 지주 · **`gc-biopharma` GC녹십자** · `gc-cell` · `gcms` · `gc-genome` · `gccl` · `gc-labs` · `gc-medis` · `genes-labs` · `gc-wellbeing` · `green-vet` · `gc-imed` · `gc-care` · `gcem` · `gc-invacfarm` · `mogam`)
3. 해당 페이지가 법인을 본문에서 명시한다 — `<main class="… benefits-gc-biopharma-main">`, `<h2 class="company-title">GC녹십자</h2>`, 도입문 「**GC녹십자** 구성원의 행복한 GC Life를 위해 **GC녹십자**는 다양한 복리후생 프로그램을 운영하고 있습니다」, 항목 안에도 「**GC녹십자** 및 가족사 건강 상품 구매를 위한 복지몰 운영」.
4. `/kor/about/gc-family-1`(가족사)이 **GC(GC Holdings)**와 **GC녹십자(GC Biopharma)**를 별도 카드로 분리해 각각의 TEL/FAX/주소를 적는다. GC녹십자 카드의 **Fax 031-260-9433** 이 자기 도메인 푸터 값과 일치하고, 지주 카드의 Fax 031-260-9413 과 다르다 → 두 법인이 사이트 안에서 구분돼 있다.
5. 채용공고 목록 `/kor/recruit/list` 의 필터 첫 축이 **「가족사」**다(공고를 법인별로 가른다).

**법인 전용 페이지 증거 (형제 법인 대조)** — 같은 템플릿 클래스를 쓰지만 **내용도 구조도 다르다**.

| 탭 | URL 슬러그 | `h2.company-title` | 본문 크기 | 항목 구성 |
|---|---|---|---|---|
| **GC녹십자** | `gc-biopharma` | **GC녹십자** | 24,040B | `li.description-item` 4개 · 각 `h3.item-title` = **서술형 카테고리 문장** + `p` 항목 6/5/6/5 = **22** |
| GC (지주) | `gc` | 복지에 대한 GC의 자세 | 36,629B | `li.description-item` **25개** · `h3.item-title` = **항목명**(DR.GC·GYM·어떠케어·OPENHOUSE·사내예식·Beer… ) · 카테고리 = HEALTHCARE/FAMILY/REFRESH/Life&Safety |
| GC셀 | `gc-cell` | GC셀 | 28,343B | `li.description-item` **18개** · `h3.item-title` = 항목명(구내식당·이뮨셀LC 항암치료 지원·제대혈 은행 할인 …) · `p` 항목 **0** |

→ 세 페이지가 **항목 수·항목 문구·마크업 사용법까지 전부 다르다**(GC녹십자만 `p` 리스트형, 나머지는 `item-title` 라벨형). 공용 목록 복붙이 아니라 **법인별로 따로 작성된 블록**이다.
→ 페이지 어디에도 **「계열사별 상이」류 면책이 없다.** 오히려 상단 안내문이 「다양한 **GC 가족사들의** 복리후생을 확인해 보세요」로 법인별 분리를 사이트가 직접 선언한다.

**기등록 형제 점검**: 리포 `db/seed/benefit/sql/` 138개 파일에 GC 계열(GC·GC녹십자·GC셀·GC녹십자MS·GC녹십자웰빙·GC지놈·유비케어·목암 등) **0건**. (「지놈앤컴퍼니」는 GC지놈과 무관한 독립 KOSDAQ 법인이다.) → 웨이브 4 계약 §「그룹 공통 복지 + 기등록 형제」 보류 조건에 **해당하지 않는다**. 더존비즈온 선례대로 진입 가능하다.

## ② 복지 항목 명시 여부 — **명시됨, 22항목 / 4카테고리, 전부 HTML 텍스트**

### ②-1 정본 `/kor/culture/benefits/gc-biopharma`

마크업: `main.gc-culture-benefits-main.benefits-gc-biopharma-main` > `section` > `h2.company-title`(법인명) + `p.title-text`(도입문) + `ol.description-list` > `li.description-item` > `h3.item-title`(카테고리 문장) + `div.item-content` > `p`(항목 1개씩).

| 카테고리(`h3.item-title`) | 항목 수 | 항목 (원문 그대로) |
|---|---|---|
| 구성원이 몰입할 수 있는 근무환경을 지원합니다. | 6 | 매일 새로운 생각을 불러일으키는 Creative한 회의실 및 사무실 · 잠깐의 휴식을 위한 사내 카페, 남성/여성 휴게실 · 편리한 출퇴근을 위한 출퇴근 셔틀버스 및 전 직원 무상 주차 · 아이와 함께 출근하고 퇴근하는 직장어린이집 · 집으로 돌아가기 전 건강을 챙길 수 있는 피트니스센터 · 건강관리를 편하게 할 수 있는 전문의 상주 사내 병원 |
| 직장 생활에서의 쉼표를 마련해 드립니다. | 5 | 충분한 휴식을 위한 연 2회 장기 휴가 (여름/겨울, 1주일 간) · 장기 근속자에 대한 Amazing Holiday · 가정 내 어려움을 지원하는 휴직/병가제도 · 직원의 생애주기에 맞는 경조휴가제도 (경조지원 포함) · 휴가를 즐겁게 보낼 수 있는 콘도 및 리조트 회원가 이용 |
| 구성원 및 가족의 건강한 Life를 지원합니다. | 6 | 개인의 건강을 위한 단체 상해보험 가입 · 건강한 가정을 위해 배우자를 포함한 건강검진 지원 · 건강한 식습관을 위한 사내 식당 · 스트레스 관리를 위한 심리상담 프로그램 지원(EAP) · 질병 예방을 위한 백신접종 지원 · GC녹십자 및 가족사 건강 상품 구매를 위한 복지몰 운영 |
| 행복한 GC Life를 응원 합니다. | 5 | 개인의 기호에 맞게 Self-선물을 하는 복지포인트 (명절/근로자의날/창립기념일) · 내 집 마련에 도움을 주는 사내 대출 제도 · 학비 부담을 덜어주는 자녀 학자금 지원제도 · 매월 신규 도서가 추가되는 사내 도서관 · 다양한 취미활동을 지원하는 사내 동호회 |
| **계** | **22** | |

**예시 2개**: `충분한 휴식을 위한 연 2회 장기 휴가 (여름/겨울, 1주일 간)` · `스트레스 관리를 위한 심리상담 프로그램 지원(EAP)`.

- **항목이 라벨이 아니라 「수식어 + 제도명」 서술문**이다(심텍·GC셀식 라벨형이 아님). 재코딩이 반드시 필요하다 — 아래 「수집 설계 시 유의」 2.
- **금액 명시 0건.** 정량 표현은 기간·빈도뿐 — 「연 2회」, 「1주일 간」, 「매월」.
- 숨김 여부: 페이지 전체에 `display:none`·`visibility:hidden`·`hidden=` **0건**(`aria-hidden="true"` 1건은 장식 아이콘). HTML 주석 9개는 전부 라이브러리 로딩 메모(AOS·gsap·ScrollMagic·공지 로더)이고 **복지 관련 유령 블록 0건**.
- 이미지 안 항목 없음. 본문 `<img>` 5개는 CI 2장·SNS 2장·배경 1장(`/common/images/gc-culture/benefits/gc-biopharma/bg-1.png` · 200 · 148,313B · **962×1136 PNG**). 배경 이미지는 **판독 결과 GC 로고 + 석양 실루엣 사진으로 텍스트 0** → 장식용 확정(`alt=""`).

### ②-2 영문판 `/eng/culture/benefits/gc-biopharma` — 17개로 접힘, 국문보다 정보가 하나 더 많다

- 2~4번째 카테고리는 국문과 **1:1 대응**(5·6·5 = 16). 그러나 **첫 카테고리 6항목이 영문에서는 한 문단으로 합쳐져 `p` 1개**가 된다 → 같은 파서로 세면 **17개**가 나온다. 개수 검증을 영문으로 하면 안 된다.
- 영문에만 있는 정보 1건: `In-house restaurants for healthy eating habits (**lunch/dinner provided, free**)` — 국문 「건강한 식습관을 위한 사내 식당」에는 **중·석식 무료 제공**이라는 조건이 없다.
- → 정본은 국문. 영문은 해석 보조로만.

### ②-3 보조 정본 `/kor/culture/hr/gc-biopharma`(인사제도) — 근무제도 6건 추가

같은 가족사 탭 구조이고 `h2.company-title` = `GC녹십자`. 복지 페이지에 없는 **근무·조직 제도**가 서술형으로 나열된다.

| 구분 | 항목 |
|---|---|
| 근무 제도 | **시차출퇴근제** · **선택적근로시간제** · **보상 휴가제** · **거점오피스 제도** · **PC-OFF 제도**(근무시간 종료 시 PC 화면 차단) |
| 조직 문화 | **자율복장제도** · 「님」 호칭 |
| 성장·보상 | 절대평가/다면평가 · 온·오프라인 학습지원 · **사외 석박사 학위과정 지원** · 직무순환(개인 주도 커리어 개발) · 목표성과급/경영성과급/기타인센티브 |

- 성과급·평가제도는 복지 항목이 아니라 보상 체계 서술이다. 채택한다면 **근무 제도 5건 + 자율복장 1건** 정도가 한계이고, 출처 URL 을 복지 페이지와 분리해 달아야 한다.
- `/kor/culture/edu/gc-biopharma`(교육): 온보딩·직무전문가 육성·리더십 Journey·CoP·어학 교육 등 **교육 커리큘럼 서술**이다. 계약 §3 기준 **항목 0**. 다만 「석/박사 지원 제도, 사외 MBA」는 인사제도 페이지와 중복 언급된다.

### ②-4 채용공고는 정본이 아니다

- `/kor/recruit/list` 는 200 · 36,014B 이지만 **가시 텍스트 607자**뿐인 **CSR 목록**이다. 공고는 `/interface/announcementList`(+ `/interface/list/B001|B002|B005|A110` 필터, `/interface/recruit-csrf-token`) 를 jQuery Ajax 로 불러온다. 이번 프로브에서는 **호출하지 않았다.**
- 지원 자체는 `career50.sapsf.com/career?career_company=gccorpP1`(SAP SuccessFactors, 그룹 단일 인스턴스)로 나간다 — 법인 구분이 쿼리에 없으므로 출처로 부적합.

## ③ robots — 관련 호스트 4곳 전부 해당 경로 허용, AI 봇 개별 차단 없음

| 호스트 | 상태 | 내용 | 판정 |
|---|---|---|---|
| **`recruit.gccorp.com`** (정본) | **404** · 196B · Apache 기본 404 HTML | robots 부재 | **허용**(404 = 허용). 파서가 404 HTML 을 규칙으로 읽지 않게 할 것 |
| `www.gcbiopharma.com` | 200 · 113B · **BOM 없음**(`55 73 65` = "Use") · LF | 레코드 1개: `User-agent: *` / `Allow: /` / `Disallow: /greenadm/` / `Disallow: /eng_adm/` / `Sitemap: https://www.gcbiopharma.com/sitemap.xml` | 관리자 경로 2개만 금지. 본문 경로 **허용** |
| `www.gccorp.com` | 200 · 23B · **BOM 없음** · **CRLF** | 레코드 1개: `User-agent: *` / `Allow: /` | 전면 허용 |
| `careers.gcbiopharma.com` | 200 · 252B · **BOM 없음** · LF | 레코드 1개: `User-agent: *` / `Disallow:` ×10 (`/applybutton/` `/talentcommunity/` `/mobile/talentcommunity/` `/emailsubscribe/` `/email/image/` `/services/` `/preapply/` `/error` `/unsubscribe/` `/reset/`) | 루트·콘텐츠 경로 허용 |

- **AI 봇 개별 차단 0건.** 네 호스트 어디에도 `ClaudeBot`·`anthropic-ai`·`GPTBot`·`CCBot`·`Google-Extended` 를 이름으로 지정한 레코드가 없다. 전부 `User-agent: *` 하나뿐이라 **AI 봇도 `*` 레코드를 따른다 = 정본 경로 허용**.
- 여러 UA 줄이 한 레코드로 묶인 경우(웨이브 2 신한형) **없음** — 모든 파일이 UA 줄 1개짜리 단일 레코드다.
- 절차: robots.txt 4건을 **각각 단독 호출**로 먼저 받았고, 본문 요청은 그 판정이 끝난 뒤에 시작했다. 금지 경로에 닿은 요청 **0건**.

## ④ 접근성

| 항목 | `recruit.gccorp.com/kor/culture/benefits/gc-biopharma` (정본) | `www.gcbiopharma.com` (자기 도메인) |
|---|---|---|
| 응답 | 200 · **24,040B** · 0.72s / 0.88s (2회) | 200 · 49,176B · 0.15s |
| 렌더링 | **SSR**(`Server: Apache`, Java/Spring — `JSESSIONID`, `_csrf` 메타). 22항목이 원본 HTML 에 텍스트로 존재 → **헤드리스 불필요** | SSR(`JSESSIONID`). 복지 콘텐츠는 없음 |
| 봇 차단 | **없음.** WAF·캡차·429·쿠키 게이트 미관측. 일반 브라우저 UA 로 2회 요청 모두 200 동일 본문. 「접근 차단·Access Denied·Request Blocked·비정상 접근·잘못된 페이지」 키워드 **0건**, 2KB 미만 응답 없음 | 없음 |
| 응답 안정성 | 2회 요청 본문 diff = **`<meta name="_csrf">` 한 줄만 다름**. 복지 22항목 텍스트는 **완전 동일** | — |
| HEAD/GET | HEAD 200(본문 0) · GET 200 — 차이 없음. 판정·항목 추출은 전부 GET 로 했다 | — |
| TLS | 정상 `ssl_verify_result=0`, **TLSv1.3**, HTTP/1.1. 인증서 `CN=*.gccorp.com`, **`O=(주)녹십자`**, 발급 GeoTrust TLS RSA CA G1 (DigiCert Global Root G2), 유효 **2026-04-07 ~ 2026-10-22**. SAN = `*.gccorp.com`, `gccorp.com`, `*.mogam.re.kr`, `mogam.re.kr`, `*.greencross.com`, `greencross.com`, `*.gclabs.co.kr`, `gclabs.co.kr` | 정상(HTTP/2) |
| 보안 헤더 | `Strict-Transport-Security: max-age=31536000 ; includeSubDomains` · `X-Frame-Options: SAMEORIGIN` · `X-Content-Type-Options: nosniff` · `Cache-Control: no-store` | `X-Frame-Options: SAMEORIGIN`, `nosniff` |
| 인코딩 | **UTF-8**(`Content-Type: text/html;charset=UTF-8` + `Content-Language: ko-KR`). 한글 정상, EUC-KR/cp949 아님 | UTF-8, 한글 정상 |
| www/apex | `recruit.` 는 서브도메인 단독(apex `gccorp.com` 은 지주 사이트로 별개) | apex → 301 → www |
| 법인 식별 | ⚠ **모든 가족사 탭의 `<title>` 이 똑같이 `GC녹십자그룹 채용사이트`**, `og:title`·`og:description` 도 동일. **제목으로는 법인을 식별할 수 없다** — `h2.company-title` 과 `main` 클래스로만 가른다 | `<title>GC녹십자` |

- 인증서 `O` 가 **(주)녹십자**인데 사이트 푸터 운영 주체는 **(주)녹십자홀딩스**다. 두 값이 엇갈리므로 **법인 귀속 근거로 인증서를 쓰지 말 것** — 근거는 페이지 본문(`h2.company-title`)과 가족사 카드의 Fax/주소다.

## ⑤ 재무·직원 3축 메모

- **DART 미조회.** 이번 프로브는 HTTP 실사만 했다. corp_code `00129679` / stock_code `006280` 은 `_ROSTER.md` 기재값을 옮긴 것이고 이번 세션에서 DART 로 검증하지 않았다 — **리드가 확인할 것.**
- ⚠ **설립일 주의**: 채용사이트 가족사 카드는 GC(지주)와 GC녹십자의 설립일을 **둘 다 「1969년 11월」**로 적는다. 이는 그룹 창립연도를 양쪽에 재사용한 값이라 **DART 법인 설립일 대용으로 쓸 수 없다.** 지주회사 전환 분할 이력이 있으면 DART 설립일이 이와 크게 다를 수 있으니 DART 원본으로 확인해야 한다.
- 신설 법인 의심 사유는 없다(KOSPI 006280, 사이트에 50년 업력 서술). 사업보고서 이력 길이는 리드 확인 몫.
- 리포 기록: `docs/handoff/2026-09-19-evidence/candidates-2026-09-19.md` 2차 풀 6번(시총 195위, 수요 3.359), `datalab-2026-09-19.md` 9위. 「녹십자 채용」 검색량에 GC 계열 전체가 섞이므로 **등재 표시명 GC녹십자 + 별칭 「녹십자」** 는 확정 사항.

---

## 수집 설계 시 유의

1. **정본 슬러그를 틀리면 다른 법인 복지가 붙는다.** `/kor/culture/benefits/**gc-biopharma**`(GC녹십자 22항목)와 `/kor/culture/benefits/**gc**`(지주 (주)녹십자홀딩스 25항목)는 한 글자 차이인데 전혀 다른 법인이다. 수집기는 응답마다 **`h2.company-title` 텍스트 == `GC녹십자`** 와 **`<main>` 클래스에 `benefits-gc-biopharma-main` 포함**을 둘 다 검증하고, 하나라도 어긋나면 그 응답을 버릴 것. `<title>` 은 전 가족사가 동일하므로 검증에 쓰면 안 된다.
2. **항목이 라벨이 아니라 서술문이라 재코딩이 필수다.** 「매일 새로운 생각을 불러일으키는 Creative한 회의실 및 사무실」, 「집으로 돌아가기 전 건강을 챙길 수 있는 피트니스센터」처럼 수식어가 앞에 붙는다. 수식어를 떼고 제도명(사내 카페·셔틀버스·직장어린이집·피트니스센터·사내 병원…)을 뽑되 **원문은 근거표에 그대로 보존**할 것. 「전 직원 무상 주차」·「남성/여성 휴게실」처럼 한 `p` 안에 제도가 2개 들어간 항목이 3건 있으니(1-2·1-3·1-6) 분할 여부를 먼저 정할 것.
3. **변경 감지를 바이트 해시로 하면 매번 오탐이다.** 응답마다 `<meta name="_csrf">` 값이 바뀐다(2회 요청 diff 가 이 한 줄뿐). 해시는 반드시 **`ol.description-list` 구간만** 떠서 낼 것.
4. **영문판으로 개수를 검증하지 말 것.** 영문은 첫 카테고리 6항목이 한 문단으로 합쳐져 `p` 기준 17개로 세진다. 대신 영문에만 있는 「사내 식당 = lunch/dinner provided, **free**」는 국문에 없는 조건이니, 채택한다면 출처를 영문판으로 따로 달 것.
5. **출처 표기에 「지주 도메인의 법인 전용 탭」임을 남길 것.** 자기 도메인 `www.gcbiopharma.com` 에는 복지 페이지가 아예 없고(사이트맵 24 URL 중 채용 0), 정본 호스트 `recruit.gccorp.com` 의 푸터 사업자는 **(주)녹십자홀딩스(135-81-05009)** 다. 삼성화재 선례와 같은 구조이므로 각 행 각주에 「GC녹십자 법인 전용 탭 `gc-biopharma`」를 명시해 법인 불일치 오염과 구분할 것. 보조로 쓸 인사제도 6건(시차출퇴근제·선택적근로시간제·보상휴가제·거점오피스·PC-OFF·자율복장)은 **출처 URL 을 `/kor/culture/hr/gc-biopharma` 로 분리**해 달 것.
6. **TLS 인증서가 2026-10-22 만료**다(`*.gccorp.com`). 그 이후 재수집하면 검증 실패를 먼저 의심할 것. 그리고 **`greencross.com` 은 사설 IP(172.16.2.176)로 죽어 있고 `www.greencross.com` 은 NXDOMAIN** 이니, DART hm_url 이 그쪽이면 `www.gcbiopharma.com` 으로 갈아치울 것.
