# JYP Ent. (JYP Entertainment Corporation · KOSDAQ 035900) — 복지 수집 가능성 실사 프로브

- 회사: JYP Ent. / JYP Entertainment Corporation (엔터테인먼트·가요기획), KOSDAQ 035900
- 본사: 서울특별시 강동구 (TLS 인증서 `L = Gangdong-gu`, 채용 공고 근무지 표기 `JYP Center`)
- 프로브 일시: 2026-09-20 · HTTP 요청 약 33회(한도 40, 리다이렉트 포함) · 전 구간 일반 브라우저 UA · 요청 간 ≥1.3초
- 프로브 범위: 판정만. 수집·SQL 작성은 하지 않았다.

**판정: 가능** — **정규직 채용 사이트가 연습생·오디션과 완전히 분리된 별도 도메인으로 존재한다**(`recruit.jype.com` ↔ `audition.jype.com`, 공식 홈 푸터에서 서로 다른 FAMILY 링크). 그 채용 사이트의 `Work & Life` 페이지에 임직원 복리후생 **12항목 / 4카테고리**가 서버렌더 HTML 텍스트로 있고, robots 는 네 호스트 모두 해당 경로를 허용하며 AI 봇 선별 차단이 없다.

- 정본 URL: `https://recruit.jype.com/ko/benefits` (메뉴 「Work & Life」, `/benefits` 는 307 → `/ko/benefits`)
- 항목 수: **12개 / 4카테고리**(Work 3 · Refresh 3 · Life 3 · Family 3), 항목마다 이름(`h3`) + 한 줄 설명(`p`). **원 단위 금액 명시는 0건**
- 렌더 방식: Next.js App Router **SSR 프리렌더**(`x-nextjs-prerender: 1`). 원본 HTML 가시 텍스트와 `self.__next_f` 플라이트 페이로드 양쪽에 있다. 헤드리스 렌더 불필요

> ⚠ 리드가 지목한 함정은 실측으로 해소됐다. 채용 사이트 전체(홈·공고 34건·FAQ)에서 `연습생`·`오디션`·`audition` **0건**이고, 공고는 전부 정규직·계약직·인턴 등 임직원 채용이다. 오디션은 `audition.jype.com` 이라는 **별도 서브도메인**으로 분리돼 있어 이 정본 URL 로는 섞여 들어올 수 없다.

---

## ① 공식 채용/복지 페이지 URL

### 도메인 지도 (DART hm_url 오염 점검 포함)

| 호스트 | 결과 |
|---|---|
| `www.jype.com` | **200** · 공식 기업 사이트(Next.js, CloudFront `x-amz-cf-pop: ICN80`). `<title>JYP Entertainment</title>` |
| `jype.com` (apex) | **301** → `https://www.jype.com/…` (nginx, 경로 유지) |
| **`recruit.jype.com`** | **200** · **정규직 채용 사이트(정본이 여기 있다)** |
| `recruit-apply.jype.com` | 200 · 공고 상세·지원 화면. DNS 는 CNAME `jype1.career.greetinghr.com`(그리팅 ATS)이지만 **회사 도메인 하위 브랜드 서브도메인**이다 |
| `audition.jype.com` | 이번 프로브에서 **요청하지 않았다**(복지와 무관·범위 밖). 공식 홈 링크로 존재만 확인 |
| `jypent.com` / `www.jypent.com` | ⚠ **DART hm_url 로 이 주소가 오면 쓰지 마라.** DNS 가 `overdue.aliyun.com`(170.33.12.185)으로 해석된다 — 만료·회수된 주소다 |
| `careers.jype.com`·`jobs.jype.com` 등 | **와일드카드 DNS 착시**. `zzqq-nonexist-7731.jype.com`·`nonexist-probe-9921.jype.com` 도 똑같이 apex IP(43.203.13.120)로 해석된다 → 존재 증거가 아니다. 반면 `recruit.jype.com`·`www.jype.com` 은 **서로 다른 CloudFront 배포**(`d2ovy3m3nkxiv8` / `d12ypt1ew3vyop`)를 가리켜 실재 레코드다 |

- 찾아간 경로: `www.jype.com/` 푸터 `FAMILY` → `JYP RECRUIT`(`https://recruit.jype.com`) → GNB 「Work & Life」 → `/ko/benefits`. `robots.txt` 의 `Sitemap:` 지시(`https://recruit.jype.com/sitemap.xml`)로도 같은 URL 에 닿는다.
- 채용 사이트 sitemap **66 URL**. 콘텐츠 페이지는 `/`(People & Culture) · `/jobs` · `/benefits` · `/faqs` · `/articles`(11) · `/news`(43) · `/notices`(5) 뿐이고, **복지 페이지는 `/benefits` 하나다**. 그룹 sitemap 으로 새는 구간(이수페타시스형)은 없다 — 전부 `recruit.jype.com` 자기 것이다.
- 공식 기업 사이트 `www.jype.com` 본문에는 `복리`·`복지`·`채용` **0건**이다. 기업 사이트만 긁으면 항목 0으로 오판한다.

### 귀속 경로 — 이 페이지가 상장 법인 JYP Ent. 것이라는 근거

1. **자기 도메인이다.** `recruit.jype.com` 은 상장 법인 도메인 `jype.com` 의 서브도메인이고, 3자 채용사이트도 그룹 공통 포털도 아니다.
2. **TLS 인증서 주체가 법인이다.** `www.jype.com` 과 `recruit.jype.com` 은 **동일 OV 인증서**를 쓴다 — `O = JYP Entertainment Corporation, C = KR, ST = Seoul, L = Gangdong-gu`, `CN = JYP-ISE.jype.com`, SAN `jype.com`·`*.jype.com`, GlobalSign RSA OV SSL CA 2018.
3. **푸터·소개문 주어가 법인이다.** 전 페이지 푸터 `© JYP ENTERTAINMENT Corp. All rights reserved.`, 홈 소개문 「**JYP Entertainment**는 'Leader in Entertainment' 비전을 토대로 …」.
4. **항목 내용이 본사 전용이다.** `JYP BOB`(사내 식당), `무사고 안전 운전 수당 **(매니저 대상)**`(매니저 직군은 JYP Entertainment 공고에만 있다), `소속 아티스트의 콘서트 초대권`.
5. 인터뷰 콘텐츠(`/articles` 11건) 태그가 전부 `JYPE · <부서>` 형식이다(F&B Team · STUDIO J · IT LAB · SOUND LAB · Compliance Team · Sustainability Team 등).

### ⚠ 같은 채용 사이트가 자회사 공고도 싣는다 — 그래도 「가능」인 이유

`/ko/jobs` 의 `구분` 필터에 법인이 **3개** 있다: `JYP Entertainment` · `Blue Garage` · `INNIT Entertainment`. 실측 공고 **34건**의 내역은 아래와 같다.

| 구분 | 공고 수 | 근무지 표기 |
|---|---|---|
| JYP Entertainment | **24** | 전부 `JYP Center` |
| Blue Garage | **10** | 전부 `Blue Garage` |
| INNIT Entertainment | **0** (필터에만 존재) | — |

- Blue Garage 공고 원문: 「**Blue Garage는 JYP Entertainment의 자회사로**, … 기존 **JYP360**에서 사명을 변경하며 …」, 근무지 주소 `서울특별시 강동구 성안로 7-13 2층` (JYP Center 와 다른 주소).
- **형제 법인 대조(계약 §1)를 실제로 돌렸다.** Blue Garage 는 **자기 도메인 `bluegarage.co` 에 자기 복지 목록을 따로 싣는다** — `/ko/careers` 의 `BENEFITS` 블록 **4개**(`사내 식당 (JYP BOB) 무료 중/석식` · `유연근무제 및 리프레시 휴가, 각종 건강 지원` · `다양하게 운영되는 활발한 동호회 제도` · `복지 포인트 및 문화/교육 지원비`), 푸터 `© BLUE GARAGE Corp.` · 사업자등록번호 `327-87-02151` · 대표이사 `정민종`.
- 즉 **항목 수(12 vs 4)·문구·호스트·사업자등록번호가 전부 다르다.** JYP 쪽 `/benefits` 는 자회사와 공유하는 템플릿이 아니라 법인 자기 페이지다. 다만 4개 항목(식당·유연근무/리프레시·동호회·복지포인트)은 **양쪽에 겹친다** — 공유 시설·제도로 보인다. 이 겹침은 JYP Ent. 행의 진위를 흔들지 않지만, **`bluegarage.co` 를 JYP Ent. 출처로 쓰면 안 된다**(다른 법인이다).
- 계약 「웨이브 4 추가」의 조건부 트리거(그룹 공통 복지 + 「계열사별 상이」 면책 + 기등록 형제)는 **셋 다 해당하지 않는다**: `/benefits` 에 적용 범위·면책 문구가 **한 줄도 없고**, Blue Garage·INNIT 는 비상장이라 우리 코퍼스에 형제로 등록될 일이 없다(더존비즈온 선례와 같은 구조). 그래서 조건부로 내리지 않았다.
- ⚠ 그래도 원문에 「JYP Entertainment 임직원 전용」이라는 명시는 없다. 각 행 출처 주석에 **「법인 자기 채용 사이트의 Work & Life 페이지. 같은 사이트가 자회사(Blue Garage) 공고도 게시하나 자회사는 자기 도메인에 별도 복지 목록을 둔다」** 정도는 남기는 것이 안전하다.

### 공고 본문에는 복리후생 섹션이 없다

`recruit-apply.jype.com/o/229442`(JYP Entertainment 마케팅)·`/o/236048`(Blue Garage 생산 MD) 두 건을 열었다. 둘 다 `복리후생`·`복지`·`휴가`·`경조`·`건강검진`·`식대` **0건**이다. 본문은 주요업무·자격요건·우대사항·전형절차뿐이다 → **공고에서 캘 복지 행은 없다.** 정본은 `/benefits` 하나다.

## ② 복지 항목 명시 여부 — **12항목 / 4카테고리, 전부 HTML 텍스트**

마크업: `<section id="benefits-{work,refresh,life,family}-section">` > `h2`(카테고리, 배너 이미지 위 오버레이) > `ul` > `li` > `h3`(항목명) + `p`(설명).

| 카테고리 | # | 항목명 (`h3` 원문) | 설명 (`p` 원문) |
|---|---|---|---|
| Work | 1 | JYP BOB | 구성원에게 체계적인 유기농 식단의 중식과 석식을 무료로 제공하며, 건강과 환경에 이로운 사내 문화를 조성합니다. |
| | 2 | 유연 근무제 | 선택적 근로제도, 주 1회 재택근무, 자율좌석제를 운영하여 개별 구성원의 다양한 업무 니즈를 존중하고 업무 효율성 향상에 기여합니다. |
| | 3 | 무사고 안전 운전 수당 | 안전 운전 장려를 위해 무사고 안전 수당을 지원하며, 책임감 있고 안전한 운전 문화를 위해 노력합니다. (매니저 대상) |
| Refresh | 4 | 문화 활동 | 소속 아티스트의 콘서트 초대권을 제공하여, 함께 즐기고 교류하는 특별한 문화 경험의 기회를 제공합니다. |
| | 5 | 리프레시 제도 | 3·6·10·15·20년 근속 시 15일 유급휴가와 장기근속 포상 및 표창을 제공하며, 하계 휴가비를 지원해 휴식과 재충전을 돕습니다. |
| | 6 | 복지 포인트 | 문화 · 도서구입 · 생일 등 다양한 용도의 복지포인트를 지급하며, 사내 카페 이용 포인트를 제공합니다. |
| Life | 7 | 동호회 활동 | 동호회 활동을 통해 구성원 간의 이해와 소통을 확대하고, 존중과 배려를 바탕으로 한 건강한 문화를 실현해 나갑니다. |
| | 8 | 건강관리 | 매년 건강검진 및 건강검진 휴가를 제공합니다. 단체 상해보험 가입, 독감 예방접종, 멘탈케어 프로그램 지원, 금연 성공 축하금 지급 등 구성원의 건강을 최우선으로 생각합니다. |
| | 9 | 자기 계발 교육비 | 구성원의 지속적인 역량 개발을 위해 직무, 어학, OA 등 다양한 자기 계발 교육 비용을 지원하며, 입사자 · 리더십 · 세미나 등의 다양한 교육을 제공합니다. |
| Family | 10 | 경조사 지원 | 경조사비, 경조 휴가, 화환/조화, 상조 서비스 지원, 반려동물 경조 휴가 등을 제공하며 구성원 삶 전반에 걸친 다양한 순간을 든든히 지원합니다. |
| | 11 | 자녀 학습 지원금 | 유치원부터 고등학생 자녀까지 자녀의 교육비 부담 완화를 위한 학습 지원금을 제공합니다. |
| | 12 | 휴양 시설 | 임직원이 편안한 여가와 휴식을 누릴 수 있도록 전국 제휴 휴양 시설 할인 혜택을 제공합니다. |

**예시 2개**: `JYP BOB`(Work — 중·석식 무료), `리프레시 제도`(Refresh — 근속 15일 유급휴가).

- **금액 명시: 원 단위 0건.** 정량 표현은 `3·6·10·15·20년 근속 시 15일 유급휴가`, `주 1회 재택근무`, `중식과 석식 무료`, `유치원~고등학생 자녀` 넷뿐이다. **환산 가능 행은 거의 없고 정성 서술 위주**다(법정 기준선 메모의 「정성 72%」 경향과 같다).
- **한 항목에 제도가 여럿 묶여 있다.** 8번(건강검진 + 단체상해보험 + 독감예방접종 + 멘탈케어 + 금연 축하금 = 5), 10번(경조사비 + 경조휴가 + 화환/조화 + 상조 + 반려동물 경조휴가 = 5), 5번(근속 유급휴가 + 장기근속 포상·표창 + 하계 휴가비 = 3), 6번(복지포인트 + 사내 카페 포인트 = 2). 기계적으로 12행을 만들면 제도가 뭉개진다 — 분해하면 **20행 이상**이 된다.
- **법정 제도와 겹치는 서술**(미수록 규칙 적용 대상): 8번의 `매년 건강검진`(법정 검진), 2번의 `선택적 근로제도`(근기법 제52조), 10번의 `경조 휴가` 일부. 반면 `건강검진 휴가`·`반려동물 경조 휴가`·`금연 성공 축하금`·`주 1회 재택`·`자율좌석제`는 법정 위에 얹은 것이다.
- **유령 항목 점검**: HTML 주석 **7개 중 한글 포함 0개**(옛 블록 없음). `display:none` 0건, `aria-hidden` 0건, `hidden=""` 1건은 React Suspense 빈 placeholder(`<div hidden=""><!--$--><!--/$--></div>`)로 복지와 무관. 캐러셀 중복 없음(각 항목 문자열은 가시 텍스트에 1회).
- **이미지 안 항목 없음**: `<img>` 12장은 전부 장식 배너(`/_next/image?url=%2Fstatic%2Fbenefits%2F{work,refresh,life,family}-section-banner-0N%402x.webp`, `alt="… section banner 0N"`)이고 CI 로고 2장이다. 항목 텍스트가 이미지 안에 든 경우는 없다.
- **플라이트 페이로드 교차 확인**: `self.__next_f` 10조각을 디코드(22,478자)해 한글 문자열을 전수로 뽑았다. 복지 관련 문자열은 위 12항목과 정확히 일치하고, **가시 텍스트에 없는 숨은 항목은 없다**(나머지는 인재상·전형절차·빈 목록 안내문).

## ③ robots 허용 — **네 호스트 모두 해당 경로 허용, AI 봇 명시 차단 없음**

계약 「웨이브 4 추가」대로 **호스트마다 robots.txt 를 단독으로 먼저 받고, 허용을 확인한 뒤에만 본문을 요청했다.**

| 호스트 | robots.txt 응답 | 레코드 | 해당 경로 판정 |
|---|---|---|---|
| `www.jype.com` | **200 · 127B · text/plain**, **BOM 없음**(선두 `55 73 65` = `Use`), LF | `User-Agent: *` → `Allow: /` + `Disallow: /api/` + `Disallow: /_next/`. `Host:` · `Sitemap:` 각 1줄. 레코드 **1개** | `/`·`/Sustainability/*` **허용** |
| **`recruit.jype.com`** | **200 · 86B · text/plain**, **BOM 없음**, LF | `User-Agent: *` → `Allow: /` + `Disallow: /api/`. `Sitemap:` 1줄. 레코드 **1개** | **`/ko/benefits` 허용** |
| `recruit-apply.jype.com` | **200 · 212B · text/plain**, **BOM 없음**(선두가 `0a` = 빈 줄 1개로 시작), LF | `User-Agent: *` → `Allow: /` + `Disallow:` 7줄(`/o/*/apply`, `/ko/o/*/apply`, `/en/o/*/apply`, `/m/*`, `/a/*`, `/ko/a/*`, `/en/a/*`). 레코드 **1개** | `/o/{id}`·`/ko/o/{id}` **허용**(막히는 것은 지원서 제출 화면뿐) |
| `d1al7qj7ydfbpt.cloudfront.net` (ESG 자산) | **403 · 111B · XML** `<Error><Code>AccessDenied</Code>` (S3 오리진) | 규칙 파일 없음 | RFC 9309 의 **unavailable(4xx) → 전면 허용**. 단 「404 = 허용」만 아는 파서는 403 을 오류로 볼 수 있으니 방어 필요 |
| `bluegarage.co` (대조용, 출처 아님) | 200 · 67B | `User-Agent: *` → `Allow: /` | 허용 |

- **AI 봇 UA 판정**: 네 호스트 어디에도 `ClaudeBot`·`anthropic-ai`·`GPTBot`·`CCBot`·`Google-Extended` 를 이름으로 건 레코드가 **없다** → 전부 `*` 레코드를 따라 **허용**. 네패스식 AI 봇 선별 차단이 아니다.
- **레코드 묶음 함정(신한형) 해당 없음**: 각 호스트의 robots 가 `User-Agent` 줄 **1개짜리 레코드 1개**뿐이라, 레코드를 끊는 방식에 따라 판정이 뒤집힐 여지가 없다.
- **실측 교차 확인**: ClaudeBot UA·GPTBot UA 로 `/ko/benefits` 를 GET 하면 **둘 다 200 · 72,865B** 로 브라우저 UA 와 **바이트가 동일**하다. UA 차등 응답·차단이 없다.
- ⚠ `recruit.jype.com` 의 `*` 가 **`/api/` 를 막는다.** 공고 목록·복지 데이터를 JSON API 로 긁지 말고 **`/ko/benefits` HTML(또는 그 안의 플라이트 페이로드)** 로만 수집해야 한다.
- `jype.com`(apex) 의 robots 는 **301** 로 `www` 에 넘어간다 — apex 를 단독 호스트로 보고 「규칙 없음」 처리하면 안 된다.

## ④ 접근성 — SSR · 차단 없음 · TLS 정상 · UTF-8

| 항목 | 결과 |
|---|---|
| 응답(정본) | `/ko/benefits` **200 · 72,865B · 0.24s**. `x-nextjs-cache: HIT`, `x-nextjs-prerender: 1`, `etag: "kuq0ny89qj1gvt"`. 본문이 2KB 를 크게 넘고 차단 키워드(접근 차단·Access Denied·Request Blocked·비정상 접근 등) 없음 |
| 다른 페이지 | `/ko` 200 · 165,647B · 0.08s / `/ko/jobs` 200 · 219,034B · 0.51s / `/ko/faqs` 200 · 120,112B · 0.22s / `www.jype.com/` 200 · 180,459B · 0.26s |
| 렌더링 | **Next.js App Router SSR 프리렌더.** 12항목이 원본 HTML 가시 텍스트에 있고 `self.__next_f` 플라이트에도 한 번 더 있다 → `curl` + HTML 파서로 충분. **헤드리스 렌더는 쓰지 않았다**(계약 「웨이브 4 추가」 준수) |
| 봇 차단 | 없음. CloudFront(`x-amz-cf-pop: ICN80-P2/P3`) + Datadog RUM. WAF·캡차·429·쿠키 게이트 관측 안 됨. `recruit-apply` 는 Cloudflare 이지만 챌린지 없이 200 |
| HEAD/GET | **HEAD 는 한 번도 쓰지 않았다.** 생존·판정 전부 GET 기준 |
| soft-404 | **없다.** `/ko/zzq-nonexistent-probe-7731` → **진짜 404**(상태코드 404 · 28,953B Next.js 404 페이지). 200 으로 위장하지 않는다 |
| TLS | curl exit 0 · `ssl_verify_result=0` · HTTP/2. `www`·`recruit` 공용 OV 인증서 `O=JYP Entertainment Corporation`, `CN=JYP-ISE.jype.com`, SAN `jype.com`·`*.jype.com`, GlobalSign RSA OV SSL CA 2018, 2025-11-20 ~ **2026-12-22 만료**. `recruit-apply.jype.com` 은 별도 `CN=recruit-apply.jype.com`, Google Trust Services WE1, 2026-09-02 ~ **2026-12-01 만료**(90일형) |
| 인코딩 | 전 구간 **UTF-8**(`content-type: text/html; charset=utf-8` + `<meta charSet="utf-8"/>`). EUC-KR·cp949 구간 없음 |
| www/apex | `jype.com` → **301** `www.jype.com`(nginx, 경로 유지). `recruit.jype.com` 은 서브도메인 단독 |
| 로케일 | `/benefits` → **307** `location: /ko/benefits` + `set-cookie: NEXT_LOCALE=ko`. ⚠ `/en/benefits` → **307 `location: /ko/en/benefits`** 라는 엉뚱한 경로로 간다 — **채용 사이트는 한국어 전용**이고 영문판이 없다(sitemap 의 `xhtml:link` 도 `hreflang="ko"` 하나뿐). 영문 경로를 넣으면 404 로 떨어져 0건 오판이 난다 |
| 갱신 시점 | 채용 sitemap 전 URL `lastmod` 가 **2026-08-18T06:28:05.787Z** 로 동일(정적 생성 시각으로 보인다). `changefreq`: `/jobs` daily · `/benefits` weekly |
| ⚠ 공고 수 표시 불일치 | 홈 SSR 본문에는 「**0개 포지션 채용 중**」이라고 나오는데 `/ko/jobs` 에는 **34건**이 렌더돼 있다. 홈 카운터는 robots 가 막은 `/api/` 를 런타임에 호출해 채우는 값으로 보인다 → **홈의 숫자를 지표로 쓰지 말 것** |

## ⑤ 재무·직원 3축 — 리드 확인 필요

- **이번 프로브에서 DART 는 조회하지 않았다.** 설립일·사업보고서 이력·empSttus 가용 여부는 **확인하지 못했다**(리드 확인 몫).
- 신설 법인 신호는 관측되지 않았다: 공식 사이트에 `/JYP/History` 연혁 페이지와 IR 섹션(STOCK·DIVIDEND·SHAREHOLDERS MEETING·FINANCIAL·DISCLOSURE)이 모두 있고, ESG 보고서가 **2021~2025 5개년** 게시돼 있다.
- ⚠ `www.jype.com/IR/Financial` 은 본문이 **3자 IR 위젯 iframe**(`ir.gsifn.io`, CSP `frame-src` 에 등재)이라 원본 HTML 에 수치가 없다. 재무는 이 페이지가 아니라 **DART 에서** 봐야 한다.
- 지속가능경영보고서는 **별도 법인 구분 없이 「JYP Entertainment」 단일 주어**로 보이나, 아래 ⑥ 의 인코딩 문제로 **보고 범위 문구를 읽어 확인하지 못했다**.

## ⑥ 보조 출처 — 지속가능경영보고서 PDF는 **한글이 기계 판독 불가**

- 경로: `www.jype.com/Sustainability/ESGReporting` → 2021~2025 KOR/ENG PDF 10개. 2025 KOR = `https://d1al7qj7ydfbpt.cloudfront.net/esg/report/2025/(KOR)+2025+JYP+Entertainment+Sustainability+Report.pdf`
- 실측: **HTTP 200 · 39,527,319B · 137쪽 · PDF 1.7 · Last-Modified 2026-07-30**. 텍스트 레이어는 있다(pypdf 추출 149,016자).
- ⚠ **그런데 한글이 전부 깨진다.** 폰트 서브셋의 ToUnicode CMap 이 어긋나 한글 글리프가 아랍·키릴·구르무키 등 엉뚱한 코드포인트로 나온다(예: `ࢲ`=U+08B2, `ח`=U+05D7). NFC 정규화로 복구되지 않는다. 실제로 `복리후생`·`휴가`·`건강검진`·`복지` **전부 0건**으로 잡히는데, 이것은 「내용이 없다」가 아니라 **「검색이 불가능하다」**는 뜻이다. 영문 제목·숫자만 정상 추출된다.
- → 이 PDF 로 복지를 보강하려면 **페이지 이미지 OCR 이 필요**하다. 이번 판정은 이 PDF 에 **의존하지 않는다**(정본 `/benefits` 만으로 성립). 보고 범위(연결/별도, 종속회사 포함 여부)도 같은 이유로 **확인하지 못했다** — 한국금융지주 선례처럼 그룹 전사 보고서일 가능성을 배제하지 못했으니, 나중에 OCR 로 열더라도 **보고 범위 문구부터 읽고** 쓸 것.
- ESG 팩트북(`/Sustainability/ESGFactBook`)은 HTML 이지만 본문이 환경(RE100·온실가스) 중심이고 `복리후생`·`임직원`·`휴가`·`건강검진` **0건**이다. SOCIAL 탭은 이번에 열지 않았다.

---

## 수집 설계 시 유의

1. **정본은 `https://recruit.jype.com/ko/benefits` 하나로 고정한다.** `www.jype.com`(복지 0건)·`/en/benefits`(307 → `/ko/en/benefits` 엉뚱한 경로)·`/api/`(robots 금지)·공고 본문(복리후생 섹션 없음)은 전부 0건이거나 금지다. 셀렉터는 `section[id^=benefits-]` > `h2`(카테고리) + `li > h3`(항목명) + `li > p`(설명)로 12개가 정확히 떨어진다.
2. **한 항목에 제도가 여러 개 묶여 있다 — 12행을 그대로 만들면 안 된다.** 「건강관리」 5제도, 「경조사 지원」 5제도, 「리프레시 제도」 3제도, 「복지 포인트」 2제도. 분해하면 20행 이상이고, 이때 **법정 제도(매년 건강검진 · 선택적 근로제도 · 법정 경조휴가)는 미수록 규칙으로 걸러야 한다.** 반대로 `건강검진 휴가`·`반려동물 경조 휴가`·`금연 성공 축하금`·`주 1회 재택근무`·`자율좌석제`는 법정 위에 얹은 것이라 남긴다.
3. **원 단위 금액이 0건이다.** 환산·비교축에 쓸 수 있는 정량값은 근속 15일 유급휴가(3·6·10·15·20년)와 주 1회 재택뿐이다. 금액 보강은 지속가능경영보고서 PDF 뿐인데 **한글 텍스트 레이어가 깨져 OCR 없이는 못 읽는다**(⑥). 금액 없이 정성 행으로 등록될 것을 전제로 카드 문안을 짜라.
4. **자회사 혼입을 막아라.** 같은 채용 사이트가 `Blue Garage`(자회사, 공고 10건)·`INNIT Entertainment` 공고를 함께 싣는다. 공고를 긁는 어떤 보조 경로를 쓰더라도 `구분 == JYP Entertainment` (근무지 `JYP Center`)만 남기고, **`bluegarage.co` 의 4항목 복지 목록은 절대 JYP Ent. 출처로 쓰지 마라**(별도 법인 · 사업자등록번호 327-87-02151). 항목 4개가 겹쳐 보이는 것은 시설 공유이지 같은 출처가 아니다.
5. **연습생·오디션은 `audition.jype.com` 으로 완전히 분리돼 있다.** 정본 경로로는 섞이지 않지만, 표시명·검색 수요를 다룰 때 「JYP 채용」 키워드에는 오디션 수요가 섞일 수 있다(후보 표 메모와 같다). 갱신 감지는 `/benefits` 의 `etag`(현재 `"kuq0ny89qj1gvt"`) 또는 12항목 텍스트 해시로 하고, **인증서가 2026-12-22(채용 도메인 공용)·2026-12-01(`recruit-apply`)에 만료**되므로 연말 재수집 때 TLS 실패를 차단으로 오판하지 말 것.
