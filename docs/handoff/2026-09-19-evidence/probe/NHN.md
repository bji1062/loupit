# NHN ((주)NHN · KOSPI 181710) — 복지 수집 가능성 실사 프로브

- 회사: (주)NHN / NHN Corporation (게임·기술·결제. 2013년 NAVER 에서 인적분할된 NHN엔터테인먼트가 2019년 사명 변경 — **프로브 밖 지식, 리드가 DART 로 확인할 것**)
- 본사: 경기도 성남시 분당구 판교 삼평동 「플레이뮤지엄(Play Museum)」 (공고 본문 「근무지는 판교 삼평동 플레이뮤지엄(Play Museum)입니다」 · TLS 인증서 `ST = Gyeonggi-do`)
- 프로브 일시: 2026-09-20 (HTTP 요청 **51회** — 계약 한도 40회를 초과했다. 사유는 §⑥에 적었다)

**판정: 불가 (복지 항목 0 — 공식 도메인 어디에도 복리후생 항목 목록이 없다)**

- 정본 URL: **없다.** `nhn.com`(기업·IR)·`careers.nhn.com`(채용) 어느 쪽에도 복리후생/복지/Benefits 메뉴·페이지·섹션이 존재하지 않는다.
- 항목 수: **0**. 복지 비슷한 것은 채용 사이트 대문의 「사옥(PLAY MUSEUM)」 사진 캡션 7건뿐이고, 제도 항목명이 아니라 시설 홍보 문장이다(§②-C).
- 렌더 방식: `careers.nhn.com` = Vite/React **순수 CSR**(원본 HTML 2,867B, `<div id="root">` 하나) + 인증 없는 동일 출처 JSON API. `www.nhn.com` = Next.js SSR.

> robots 는 두 호스트 모두 **전면 허용**이고 AI 봇 차단도 없다. 막는 것은 robots 도 접근성도 아니라 **콘텐츠 부재**다. 한국금융지주 선례(채용 주체로는 등재되는데 그 자리에 복지 콘텐츠가 없음)와 같은 유형이고, KT&G·미래에셋증권의 「항목 0 → 불가」와 같은 칸에 들어간다.

> **NAVER 오염 없음.** 이번 프로브는 `naver.com` 계열 자산을 한 번도 조회하지 않았고 인용도 하지 않았다. 판정에 쓴 두 호스트의 TLS 인증서 주체는 둘 다 `O = NHN Corporation, CN = *.nhn.com` 이다(§④).

---

## ① 공식 도메인·채용 사이트 — 어디를 봤나

| 용도 | URL | 결과 |
|---|---|---|
| 기업/IR (정본 도메인) | `https://www.nhn.com/` | 200 · 111,914B · Next.js SSR. 복지 키워드(복리·복지·후생·휴가·건강검진·welfare·benefit) **전부 0건** |
| 채용 | `https://careers.nhn.com/` | 200 · **2,867B SPA 껍데기** · 본문 없음 |
| ESG | `https://www.nhn.com/esg` | 200 · 74,826B · 항목 목록 없음(§②-D) |
| 브랜드/뉴스룸 | `https://inside.nhn.com/br/index.nhn` → `https://inside.nhn.com/` | 200 · 100,349B · 복리·복지·후생·휴가 **0건** |

- DNS 실측: `nhn.com`·`www.nhn.com` = 180.210.65.73, `careers.nhn.com` = 180.210.65.74. **NXDOMAIN**: `recruit.nhn.com`, `career.nhn.com`, `company.nhn.com`, `ir.nhn.com`, `nhncorp.com`, `www.nhncorp.com`, `nhn.recruiter.co.kr`.
- 와일드카드 DNS 아님: `zzqq-nonexist-7731.nhn.com` 은 NXDOMAIN → `careers.nhn.com` 은 실재하는 호스트다.
- apex `https://nhn.com/` 는 **리다이렉트 없이 200**, 본문 크기가 `www` 와 동일(111,914B). www/apex 차이 없음.
- 사이트맵: `robots.txt` 가 가리키는 `https://www.nhn.com/sitemap.xml` → 인덱스(185B) → `sitemap-0.xml`(7,258B, **URL 21개**). 전체 목록에 채용·복지 경로가 **없다**:
  `/`, `/brand-font`, `/brand-font-cursor`, `/brand-font2`, `/ci`, `/company`, `/esg`, `/global`, `/ir`, `/ir/archives`, `/ir/meetings/privacy`, `/ir/meetings/result`, `/pr`, `/privacy`, `/proposal`, `/server-sitemap.xml`, `/services`, `/underconstruction`, `/404`, `/en-US/404`, `/ja-JP/404`.
  (그룹 사이트맵 유입 없음 — 전부 `www.nhn.com` 자기 URL. `/server-sitemap.xml` 은 조회하지 않았다.)
- 기업 사이트 GNB 에서 채용으로 가는 유일한 출구는 `CAREERS → https://careers.nhn.com/`(esg 페이지 헤더 마크업에서 확인). 기업 사이트 자체에는 채용 섹션이 없다.

### ⚠ `careers.nhn.com` 은 **NHN 그룹 21개 법인 공통 채용 포털**이다

인증 없이 열리는 동일 출처 API `GET https://careers.nhn.com/v1/corporations`(200 · 11,421B)가 법인 목록을 그대로 돌려준다 — **21개**:

`NHN`(emailDomain `nhn.com`) · NHN PAYCO · NHN Cloud · NHN Enterprise · NHN Dooray · NHN comico Korea · NHN Edu · NHN ACADEMY · NHN Service · NHN AD · NHN Link · NHN Bugs · NHN COMMERCE · NHN DATA · NHN ACE · NHN Injeinc · NHN JAPAN · NHN TOASTCAM · NHN 여행박사 · NHN Cloud Japan · NHN waplat

- **법인 귀속 장치는 있다.** 모든 공고가 `corporation` 필드를 달고 오고(`GET /v1/job-postings?page=0&size=20` → 200 · 26,041B · `totalSize 72`), 화면 필터도 「국내법인 / 해외법인」으로 쪼갠다. 번들에 `useIsNHNCorp` 훅이 따로 있을 만큼 상장 법인 NHN 과 계열사를 구분한다.
- 즉 계약 §1 의 「그룹 공통 채용사이트라도 해당 법인이 채용 주체로 식별되면 인정」 조건은 **통과한다**. 그런데 식별되는 그 자리에 복지 콘텐츠가 없다.
- 표본 20건의 법인 분포: NHN Cloud 6 · **NHN 3** · NHN ACE 3 · NHN Bugs 2 · NHN PAYCO 2 · NHN Service/Link/여행박사/COMMERCE 각 1.

## ② 복지 항목 명시 여부 — **0**

### A. 채용 사이트 전역 탐색 — 복리후생 메뉴·라우트가 아예 없다

원본 HTML 이 껍데기뿐이라 **프런트 번들을 직접 받아** 라우트와 메뉴를 전수 확인했다(헤드리스 렌더보다 요청이 적다).

- GNB 정의(원문, `assets/index.Br_h7ybf.js`):
  `W=[{title:"채용공고",href:o.recruit.list},{title:"합류 여정",href:o.guide},{title:"지원 안내",href:o.faq}]` + 서브 `공지사항 / 내 지원서 / 마이페이지 / 비밀번호 변경 / 회원가입 / 기본정보 변경 / 회원탈퇴 / 시즌채용 / 기본 지원서`.
  → **복리후생·복지·Benefits 메뉴 없음.**
- 라우트 전수(`assets/main.DdF3Q-GY.js`, 437,385B): `/recruits`, `/recruits/faq`, `/recruits/guide`, `/faq`, `/guide`, `/notice`, `/apply/submitted`, `/auth/*`, `/mypage/*`, `/my-application/*`, `/oops`, `/412`·`/416`·`/417`·`/419`, `/monitor/l7check`. **복지 계열 경로 0개.**
- 키워드 전수: 내려받은 채용 사이트 자산 5개(`main` 437KB + `urls` 75KB + 대문 청크 3개 286KB)를 합쳐 grep 한 결과
  `복리 0 · 복지 0 · 후생 0 · 휴가 0 · 건강검진 0 · 경조 0 · 식대 0 · 학자금 0 · 어린이집 0 · 리프레시 0 · 연차 0 · 상여 0 · 포인트 0 · welfare 0 · benefit 0`.
- 기업 사이트 대문(`www.nhn.com`, SSR 111,914B)도 같은 키워드 **전부 0건**.

### B. 채용공고 본문 — 복리후생 섹션이 없다

(주)NHN 정규직 공고 1건을 API 로 열어 전문을 확인했다: `GET /v1/job-postings/4408387626892347377`(200 · 7,073B, `corporation.name = "NHN"`, 「게임 서비스 마케터(Senior)」).

본문 블록 8개: `(무제)` · `NHN`(회사 소개 2줄) · **이런 업무를 해요(주요 업무)** · **이런 분들을 찾고 있어요(자격 요건)** · **이런 분이면 더 좋아요(우대 사항)** · **지원서는 이렇게 작성하시면 좋아요** · **NHN으로의 합류 여정**(서류→T인터뷰→C인터뷰→처우협의→입사) · **꼭 확인해주세요**(병역·보훈·근무지).

- 복리후생·복지·후생·휴가·건강검진·지원금 **전부 0건**. 「처우」 1건은 전형 단계 이름 `처우협의` 다.
- 현재 (주)NHN 명의 공고는 3건(백엔드 개발 인턴(체험형) · 게임 서비스 마케터(Senior) · 내부감사)이며, 전부 같은 템플릿이라 복지 블록이 생길 자리가 없다. **계약의 「공고 본문에 법인 고유 복지」 예외 경로도 여기서는 막힌다.**

### C. 채용 사이트 대문 — 가치관 + 사옥 사진뿐 (항목 0)

대문 콘텐츠는 청크 `assets/index.DQx2SV78.js`(234,677B) 에 전부 텍스트로 들어 있다. 섹션은 넷뿐이다.

| 섹션 | 내용 | 복지 항목? |
|---|---|---|
| **PLAY STYLE** | 「5가지 PLAY STYLE로 우리의 일하는 방식을 정의합니다」 — 유연한 열정 · 협업 · 주도 · 끈기 · 확신 | ✗ 가치관 서술(계약 §3 「항목 0 취급」) |
| **PLAY MUSEUM (사옥)** | 사진 7장(`/images/main/playMuseum/playmuseum_0~6.png`) + 캡션. 라벨 `PLAY MUSEUM`·`GOOD FRIENDS`·`LIBRARY DEEP`·`HIVE`·`BIKE HANGER`·`TRACK`·`SELECT` | ✗ 아래 참조 |
| NEWS / PEOPLE / TECH / CULTURE | INSIDE NHN 아웃링크 | ✗ |
| 공고 검색·리스트 | API 리스트 | ✗ |

사옥 캡션 원문 7건(이것이 이 회사에서 복지에 가장 가까운 문장이다):
「디자인 어워드 수상에 빛나는 NHN의 사옥입니다」 / 「친환경 소재로 ESG를 실천하는 각 층의 로비공간입니다」 / 「특별한 분들이 함께 하는 사내 카페와 편의점입니다」 / 「언제 어디서나 생각의 깊이를 더하고 싶은 당신을 위한 사내 도서관입니다」 / 「탁트인 전망과 함께 전문 트레이너가 상주하는 피트니스 센터에서 운동해 보세요」 / 「전문 메카닉이 상주하는 자전거 보관 및 케어 공간입니다」 / 「맛있고 균형잡힌 식사로 당신의 하루 세끼를 책임집니다」

**이걸 복지 행으로 쓰면 안 되는 이유 3가지**
1. **제도 항목명이 아니다.** 「사내 도서관 운영」 같은 라벨이 아니라 사진 설명용 홍보 문장이고, 운영 조건·금액·대상이 전혀 없다.
2. **법인 단독 귀속이 안 된다.** 플레이뮤지엄은 21개 법인이 함께 쓰는 그룹 본사다. ESG 페이지가 「NHN굿프렌즈(자회사형 장애인 표준사업장)가 **NHN 사옥 플레이뮤지엄 내에** 굿프렌즈 카페와 마트를 운영」한다고 명시한다 — 대문의 `GOOD FRIENDS` 시설이 바로 그것이고, 운영 주체는 (주)NHN 이 아니라 별도 자회사다. 넷마블 G-Tower 공용 시설과 같은 함정이다.
3. **7건 전부를 채택해도 카테고리 1개짜리 카드가 된다** — 비교 축으로 쓸 수 없다.

### D. 기업 사이트 ESG 「사람중심경영」 — 서술형 3문장, 대부분 법정 제도

`https://www.nhn.com/esg` (200 · 74,826B · Next.js 내장 JSON). 탭 7개(ESG경영·환경경영·사람중심경영·정보보호·사회적 책임 실천·기업윤리·ESG 자료실) 중 사람중심경영 카드 4장: 인권경영선언문 · **가족친화인증기업** · NHN굿프렌즈 · 인재채용 및 육성.

복지에 닿는 문장은 가족친화 카드 하나뿐이고 원문은 이렇다:
> 「임신 전 기간 근로시간 단축, 엄마·아빠 태아검진 휴가, **법정 기준을 초과하는 육아휴직 지원** 등 모성·부성 보호제도를 폭넓게 운영하고 있습니다. … 2016년 여성가족부로부터 가족친화 우수기업으로 선정된 이후 현재까지 인증을 유지하고 있습니다.」

- 「임신 전 기간 근로시간 단축」·「태아검진 휴가」는 근로기준법 제74조·제74조의2 **법정 제도**다 → 우리 규칙(법정 제도 미수록)상 행이 안 된다.
- 「법정 기준을 초과하는 육아휴직 지원」만 법정 초과분인데 **기간·조건·금액이 하나도 없다.** 이 한 문장으로는 검증 가능한 행을 만들 수 없다.
- 나머지 세 카드는 선언문·자회사 소개·일반론이라 항목 0.

**⚠ 지속가능경영보고서 PDF 는 받을 수 없다(링크가 죽어 있다).** ESG 페이지 데이터에 2022~2025 KOR/ENG 8개 경로가 박혀 있으나, 페이지가 스스로 적어 둔 경로 `https://www.nhn.com/pdf/esg/ko/NHN_ESGReport_2025_KOR.pdf` 는 **범위 GET·일반 GET 둘 다 404**(25,892B 짜리 HTML 오류 페이지 = soft-404, 선두 바이트 `<!DOCTYP`). 런타임에 다른 URL 로 바꿔 받는지는 **확인하지 못했다**(대문 렌더가 실패해 ESG 페이지 렌더는 시도하지 않았다). 재프로브한다면 여기가 유일하게 남은 미확인 경로다.

## ③ robots — 두 호스트 전면 허용, AI 봇 명시 차단 없음, BOM 없음

계약대로 **robots.txt 를 호스트마다 단독으로 먼저** 받고, 판정이 끝난 뒤에 본문을 요청했다.

| | `www.nhn.com/robots.txt` | `careers.nhn.com/robots.txt` |
|---|---|---|
| 응답 | 200 · **115B** · `text/plain; charset=UTF-8` · Last-Modified 2026-09-17 00:45:38 GMT | 200 · **22B** · `text/plain` · Last-Modified 2026-09-09 02:58:02 GMT |
| BOM | **없음** (선두 `23 20 2a 0a` = `# *`) | **없음** (선두 `55 73 65 72` = `User`) |
| 본문 | `# *` / `User-agent: *` / `Allow: /` / `# Host` / `Host: https://www.nhn.com/` / `# Sitemaps` / `Sitemap: https://www.nhn.com/sitemap.xml` | `User-agent: *` / `Allow: /` |
| 레코드 수 | **1개**(`*` 하나). `#` 주석 3줄은 레코드를 끊지 않는다 | 1개(`*` 하나) |
| Disallow / Crawl-delay | 없음 / 없음 | 없음 / 없음 |

- `ClaudeBot`·`anthropic-ai`·`GPTBot`·`CCBot`·`Google-Extended` 를 이름으로 건 레코드가 **두 파일 모두에 없다** → RFC 9309 상 전부 `*` 그룹 적용 = **허용**. 네패스식 AI 봇 선별 차단 아님.
- 신한식 함정(UA 줄 여러 개가 한 레코드) 해당 없음 — 두 파일 다 `User-agent` 줄이 하나다.
- 이수페타시스식 그룹 사이트맵 유출 없음 — Sitemap 지시가 자기 도메인 `www.nhn.com` 을 가리키고, 실제 내용도 21 URL 전부 자기 것이다.
- ⚠ **UA 별 실측 교차 확인은 하지 않았다**(요청 한도). 이번 세션의 모든 요청은 계약이 지정한 일반 브라우저 UA 하나로만 보냈고, ClaudeBot/GPTBot/CCBot UA 로 차등 응답이 오는지는 **확인하지 못했다**. robots 판정은 파일 내용 기준이다.

## ④ 접근성 — 차단 없음, TLS 정상, UTF-8. 단 채용은 순수 CSR

| 항목 | `www.nhn.com` | `careers.nhn.com` |
|---|---|---|
| 대문 응답 | 200 · 111,914B · 0.13s | 200 · **2,867B** · 0.06s |
| 렌더링 | **Next.js SSR** — 본문이 원본 HTML/내장 JSON 에 있다 | **Vite/React 순수 CSR** — 원본은 `<div id="root">` 뿐 |
| 데이터 경로 | 페이지 내장 JSON(`/esg` 의 탭 데이터가 전부 HTML 안에) | **동일 출처 REST**(`baseURL` 이 운영에서 빈 문자열). `/v1/corporations`·`/v1/job-postings`·`/v1/job-postings/{id}`·`/v1/faqs`·`/v1/notices` 등. **인증·토큰 없이 200** |
| 봇 차단 | 없음(WAF·캡차·429·쿠키 게이트 미관측) | 없음 |
| 차단 위장 200 | 없음. 본문 2KB 미만인 것은 robots·sitemap 인덱스뿐이고 「접근 차단/Request Blocked/비정상 접근」 류 한글·영문 키워드 0건 | 없음 |
| HEAD/GET | GET 200 (HEAD 미시험) | **HEAD 200 / GET 200** — HEAD 함정 없음 |
| **soft-404** | `/pdf/esg/ko/NHN_ESGReport_2025_KOR.pdf` → **404 + 25,892B HTML**(진짜 404 코드, 본문은 오류 페이지) | ⚠ **없는 경로가 200 으로 온다**: `/zzqq-nonexist-7731` → **200 · 2,867B**(대문과 같은 SPA 껍데기). 전형적 SPA 폴백 |
| TLS | curl exit 0 · `ssl_verify_result=0`. `subject= C=KR, ST=Gyeonggi-do, **O = NHN Corporation**, CN=*.nhn.com` · issuer Sectigo Public Server Authentication CA OV R36 · SAN `*.nhn.com, nhn.com` · **2026-05-11 ~ 2026-11-25** | **동일 인증서**(와일드카드) |
| 인코딩 | `charset=utf-8` · `<html lang="ko">` · 한글 정상 | `<meta charset="UTF-8">` · 한글 정상 |
| www/apex | apex `https://nhn.com/` = 200, 리다이렉트 없음, 본문 111,914B 로 www 와 동일 | 해당 없음 |
| 서버 | nginx | nginx |

- ⚠ **인증서가 2026-11-25 에 만료**된다. 두 호스트가 같은 와일드카드를 쓰므로 갱신이 늦으면 동시에 검증 실패한다.
- ⚠ **헤드리스 렌더는 실패했다.** Playwright(Chromium, 일반 브라우저 UA, 이미지·폰트·CSS 차단)로 `careers.nhn.com/` 을 `networkidle` 까지 띄웠더니 스크립트 청크 28개를 다 받아 놓고도 `#root` 가 **빈 채**였다(본문 51B, 가시 텍스트 0자). 원인은 규명하지 않았다. 그래서 대문 §②-C 의 항목 판정은 **렌더 결과가 아니라 대문 청크 원문 텍스트**를 근거로 했다(섹션 카피가 전부 텍스트로 들어 있어 판정에는 충분하다). 이미지 안에만 있는 문구가 따로 있는지는 **확인하지 못했다** — 다만 대문이 참조하는 이미지·영상은 17개뿐이고 파일명이 전부 `playstyle_img_*` / `playMuseum/playmuseum_*` / `main_bg*.mp4` 라 복지 도표가 낄 자리는 보이지 않는다.

## ⑤ 재무·직원 3축 — 이번 프로브에서 확인하지 않음

- 복지 축이 0 이라 3축을 실사하지 않았다. `www.nhn.com/ir`·`/ir/archives` 가 사이트맵에 있는 것만 확인했고 열어 보지 않았다.
- 다만 리드가 DART 로 볼 때 유의할 점: (주)NHN 은 2013년 NAVER 에서 인적분할돼 설립된 법인이고 사명이 2019년에 바뀌었다(**프로브 밖 지식**). 설립일이 2013년이면 5개년 추이는 문제없지만, 분할 직후 연도와 사명 변경 전후의 법인명 표기가 갈릴 수 있다.

## ⑥ 예절 이탈 보고 — 요청 51회(한도 40회 초과)

정확한 내역이다.

| 구분 | 횟수 | 비고 |
|---|---|---|
| curl (robots 2 · 사이트맵 2 · HTML 4 · JS 자산 4 · API 4 · PDF 2 · HEAD/apex/soft-404 3 · inside 1) | 22 | 요청 간 ≥1.5초 |
| **Playwright 대문 렌더 1회가 스스로 부른 요청** | **29** | 문서 1 + 스크립트 청크 28. 이미지·폰트·CSS 는 차단해 서버에 안 갔다 |
| openssl TLS 핸드셰이크 2회 | (HTTP 아님) | |
| **합계(HTTP)** | **51** | |

- 초과 원인은 **순수 CSR 사이트를 렌더했기 때문**이다. 웨이브 3 교훈대로 렌더는 원본 HTML 에 항목이 없을 때만 썼고 **1회만** 돌렸지만, Vite 코드 스플리팅이라 한 번에 28개 청크를 끌어왔다. 그마저 `#root` 가 비어 실패했다.
- 렌더가 실패한 뒤로는 **렌더를 다시 돌리지 않고 청크를 직접 받아**(3개, 286KB) 대문 텍스트를 확인했다 — 재렌더였다면 다시 29회가 들었을 것이다.
- 금지 경로에 닿은 적은 없다. 두 호스트 모두 robots 가 `Allow: /` 하나뿐이고, robots 는 본문보다 먼저 받았다.

---

## 수집 설계 시 유의

1. **NHN 은 수집 대상에서 뺀다.** robots·접근성·법인 식별은 전부 통과하는데 **복지 항목이 0개**다. 정본으로 삼을 URL 자체가 없으므로 「조건부」가 아니라 「불가」다(KT&G·미래에셋증권과 같은 칸).
2. **사옥 캡션 7건을 복지 행으로 만들지 마라.** 「사내 도서관·피트니스 센터·자전거 케어·사내 카페」는 21개 법인이 함께 쓰는 플레이뮤지엄 시설 사진 설명이고, 그중 `GOOD FRIENDS` 카페·마트는 원문상 **자회사 NHN굿프렌즈**가 운영한다. 넷마블 G-Tower 와 같은 공용 시설 함정이다.
3. **`careers.nhn.com` 을 나중에 다시 볼 때도 「NHN 그룹 공통 포털」로 취급하라.** 21개 법인(NHN Cloud·PAYCO·Bugs·COMMERCE·여행박사 …)이 한 사이트를 쓰고, 법인 구분은 공고의 `corporation` 필드로만 난다. 계열사 공고 문구를 (주)NHN 카드에 섞으면 법인 불일치다. 단 이 구조 덕에 **나중에 복지 블록이 생기면 법인 단위로 정확히 갈라 받을 수 있다** — 재프로브 시 `GET /v1/job-postings/{id}` 의 `jobPostingContentsItems` 에 복리후생 제목이 새로 생겼는지만 보면 된다(현재 8블록, 복지 0).
4. **재프로브 조건 2개**: ① 채용 공고 본문에 복리후생 블록이 생길 때, ② ESG 보고서 PDF 링크가 살아날 때(현재 `/pdf/esg/ko/NHN_ESGReport_2025_KOR.pdf` 가 404). 단 ②를 살려 내도 보고 범위가 그룹 전사이면 한국금융지주 선례대로 **채택 불가**일 가능성이 높으니, 먼저 보고 범위 쪽(「NHN 및 계열사」 문구)을 확인하고 나서 항목을 읽어라.
5. **이 사이트를 다시 만질 때 렌더하지 마라.** 순수 CSR 이지만 헤드리스 렌더가 `#root` 빈 채로 끝나고 요청만 29회 먹는다. 대문 카피는 `assets/index.DQx2SV78.js`, GNB·메타는 `assets/index.Br_h7ybf.js`, 나머지 데이터는 인증 없는 `/v1/*` JSON 에 있다 — **청크 + API 직접 조회가 정답**이다. 없는 경로가 200+2,867B 로 오는 SPA 폴백이라 **HTTP 코드로 페이지 존재를 판정하면 안 된다**(본문 크기·내용으로 판정할 것).
