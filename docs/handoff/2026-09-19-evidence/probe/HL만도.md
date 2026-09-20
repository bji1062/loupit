# HL만도 (HL Mando Corporation · KOSPI 204320 · 자동차부품 제동·조향·ADAS) — 복지 수집 가능성 실사 프로브

**판정: 가능** — 법인 자기 도메인 `www.hlmando.com` 안에 **두 개의 서로 다른 복지 목록**이 서버렌더 HTML 텍스트로 있다. 둘 다 주어가 「HL Mando」이고 「계열사별 상이」류 면책이 **0건**이다. HL그룹 통합 채용사이트(`hlcompany.recruiter.co.kr`)에 의존하지 않으며, 그 사이트의 복지 페이지는 그룹 단위(「HL그룹 소개」)에다 CSR 이라 이번 판정에 **쓰지 않았다**.

- 정본 URL(2개, 둘 다 자기 도메인):
  ① `https://www.hlmando.com/ko/career.do` — GNB 「인재채용」의 **Life** 섹션(워라밸 6 + 각종 지원 및 건강관리 9)
  ② `https://www.hlmando.com/ko/sustainability/human-rights-and-safety.do` — 「노동인권 & 안전 > 임직원 > 조직문화」의 **복리후생** 블록(시설 3 · 생활 11 · 건강/문화 6) + 근무제도 4
- 항목 수: **원문 합계 39개**(① 15 · ② 24) → 주제 중복 11쌍을 합치면 **고유 약 28개**. 원 단위 **금액 명시 0건**(정량은 「75개 동호회」·「주 40시간」·「최소 12시간 후 출근」뿐)
- 렌더 방식: **서버렌더 HTML**(Apache + JSP/Spring `.do`, `JSESSIONID`). 두 페이지 모두 최초 HTML 에 전 항목이 텍스트로 있다. 헤드리스 렌더·이미지 판독 **불필요**(그래서 하지 않았다)

> ⚠ **리드가 지적한 HL그룹 혼동 위험 — 실측으로 해소됐다.** 형제 법인 **HL D&I한라**(`www.hldni.com/html/recruit/welfare.asp`)도 자기 도메인에 복지 페이지를 따로 갖고 있는데, 분류 체계·문구·항목이 HL만도와 **양방향 0회 일치**다(아래 ①-2). HL그룹은 복지 페이지를 법인별로 따로 쓴다 → 그룹 템플릿이 아니다.
> ⚠ **구 사명 「만도」 자산은 이번에 하나도 쓰지 않았다.** `www.mando.com`·`www.hlholdings.com` 은 **443 연결 타임아웃**(curl exit 28)이라 robots 조차 못 받았고, robots 를 못 받은 호스트에는 본문 요청을 보내지 않았다(RFC 9309 기준 금지 취급).

---

- 회사: HL만도(주) / HL Mando Corporation. 리드 로스터 기준 DART corp_code `01042775`, KOSPI 204320
- DART hm_url 계열 도메인 `hlmando.com` → **살아 있다**(오염 없음). apex·www 모두 `20.214.250.115`
- 프로브 일시: 2026-09-20 00:28~00:41 UTC
- 요청 수: **HTTP 30회** + TLS 핸드셰이크 2회 = 32
  (hlmando.com 21 · hlcompany.recruiter.co.kr 3 · hldni.com 3 · hlholdings.com 1(타임아웃) · mando.com 1(타임아웃) · CSS 3회는 hlmando.com 21 에 포함)
- 내려받은 파일: `/tmp/claude-0/-home-ubuntu-loupit/f1d13a36-92d2-4e1c-9ce2-b6e64e0505ce/scratchpad/probe/hl_mando/`

## ① 공식 채용/복지 페이지 URL

| 도메인 · 경로 | 성격 | 복지 항목 |
|---|---|---|
| `www.hlmando.com/` | 법인 공식 홈페이지 | 67B 짜리 `<script>location.href="/ko/main.do";</script>` 스텁(차단 아님) |
| `www.hlmando.com/ko/main.do` | 국문 메인 · 200 · 79,499B · 0.14s | GNB 「인재채용」 → `/ko/career.do`. 별도로 `hlcompany.recruiter.co.kr/appsite/company/index`(그룹 ATS) 외부 링크 1개 |
| **`/ko/career.do`** | **인재채용(People · Life · Join us)** | **Life 섹션 15항목** ← 정본 ① |
| **`/ko/sustainability/human-rights-and-safety.do`** | **노동인권 & 안전** | **조직문화 > 복리후생 20항목 + 근무제도 4** ← 정본 ② |
| `/ko/sustainability/sustainable-management.do` | 지속가능경영 | 200 · 82,196B. 복지 키워드 **0건**. 「2020~2025년 HL만도 지속가능경영보고서」를 `javascript:reportDownload(25)` 로 내려받게 돼 있다(**이번에 받지 않음** — 보조 출처 후보) |
| `/ko/hl-mando/company.do` | 회사 소개 | 200 · 118,865B. 설립일·매출·임직원수(아래 ⑤). 복지 항목 0 |
| `/en/career.do` | Global HL Mando | 200 · 50,758B. **복지 키워드 0건** — 해외 법인 채용 랜딩이라 한↔영 대조는 불가능 |
| `recruit.` · `careers.` · `career.` · `job.hlmando.com` | — | **A 레코드 없음** |
| `hlcompany.recruiter.co.kr` | **HL그룹 통합 채용사이트** | robots 로 `/appsite*` 차단(③) · 허용 경로 `/career/welfare` 는 그룹 단위 CSR(아래) |
| `www.mando.com` · `www.hlholdings.com` | 구 사명 도메인 · 지주 | **443 타임아웃(curl exit 28)** → 본문 미요청 |

### 법인 귀속 근거 (자기 도메인이라 그룹 귀속 경로가 필요 없다)

1. 정본 ② 의 복리후생 리드 문장 주어가 법인이다: 「**HL Mando 복리후생 제도는** 인간존중 경영이념을 바탕으로 임직원 모두가 일하는 보람을 느끼고, 안정적인 생활하며, 나아가 생산성을 향상시킬 목적으로 운영하고 있습니다.」 근무제도·육아 블록도 「**HL Mando는** …」으로 시작한다.
2. 두 페이지 본문(주석 제거 후) 안에 **「계열사」 0건**. 「상이」로 잡힌 1건은 「동료 3명 **이상이**」의 오검출이다. 한화솔루션·HD현대식 「계열사 간 상이할 수 있습니다」 면책이 **없다**.
3. 「그룹」 3건은 전부 **교육 블록**(Halla Business School · 「그룹 내 공통 직무」 · 「그룹 내 전체 사무직」 Work Smart 2.0)이다. 교육은 계약 §3 기준 복지 항목에서 제외되므로, **복지 항목 쪽에는 그룹 귀속 표기가 한 건도 없다**.
4. TLS 인증서 `O = HL Mando Corporation`(SAN `*.hlmando.com`·`hlmando.com`·`*.mando.com`·`*.hlmando.cn`) — 도메인이 이 법인 소유임이 인증서로 확인된다.
5. 푸터 `Copy right 2022 HL Mando Corp.`, robots 주석 `hlmando.com robots File / Updated on Sep 05, 2022` — HL 리브랜딩(2021) **이후**에 만든 사이트다. 구 「만도」 시절 잔존 페이지가 아니다.

### ①-2 형제 법인 대조 — HL D&I한라 (`www.hldni.com`, 2026-09-20 실측)

같은 HL그룹 상장사인 HL D&I한라도 **자기 도메인에 복리후생 페이지**(`/html/recruit/welfare.asp`, 200 · 18,313B · ASP · `COPYRIGHT 2017 Halla Corporation`)를 따로 운영한다.

| 비교 | HL만도 | HL D&I한라 |
|---|---|---|
| 위치 | 채용 페이지 Life 섹션 + 지속가능경영 하위 | 채용 메뉴에 **복리후생 전용 페이지** |
| 분류 | ① 워라밸 / 각종 지원 및 건강관리 ② 시설·생활·건강/문화 지원 | **법정 복리후생제도 4 / 법정 외 복리후생제도 16** |
| 항목 수 | 39(중복 포함) | 20 |
| 마크업 | `div.work_balance` + `div.support_healthcare` > `swiper-slide` > `h4`+`p` | 테이블/아이콘 나열(`welfare_icon1~5.png`) |
| 고유 문구 | 복지몰 포인트 · 사내 건강관리실 · 75개 동호회 · 하기 휴양소 · 사원주택 · 피복과 안전보호구 | 공조화운영 · 서클지원 · 한마음대축제 · 창립기념행사 · 김장지원금 · 사내복지카드제도 · 「년리 3%」 주택융자 |
| 금액·수치 | 원 단위 0 | 「년리 3%」 · 「우리사주 20% 이내」 |

- **양방향 교차 검사**: HL만도 고유 문자열 13종을 HL D&I한라 페이지에서 찾으면 **전부 0회**, HL D&I한라 고유 문자열 11종을 HL만도 두 페이지에서 찾으면 **전부 0회**다. 주제가 겹치는 것(주택자금·건강검진·경조·우리사주·학자금·동호회·체육행사)조차 문구·조건이 전혀 다르다.
- → **그룹 공통 템플릿이 아니다.** 「조건부(그룹 공통)」로 내릴 근거가 없다.
- 참고: HL D&I한라 푸터의 계열사 목록 = HL그룹 · HL만도 · HL클레무브 · HL홀딩스 · HL안양아이스하키단 · 만도브로제 · HL에코텍 · HL로지스앤코 · 목포신항만운영 · 한라대학교.
- **리포 코퍼스 확인**: `db/seed/benefit/sql/` 138개 파일에 `HL`·`한라`·`만도` 파일명이 **0개** → 기등록 형제 법인이 없다. 설령 그룹 공통이었더라도 더존비즈온 선례(형제 없으면 진입 가능)에 걸린다. 기등록 짝 현대모비스는 `현대모비스.sql` 로 존재한다(별도 그룹).

### ①-3 HL그룹 통합 채용사이트 — 판정에 쓰지 않았다

- `hlcompany.recruiter.co.kr/career/welfare` 는 robots 허용 경로여서 받아 봤다(200 · 22,677B). **`<title>HL그룹 소개 | HL그룹 채용</title>`, `description` 「HL그룹의 HL그룹 소개를 소개하는 페이지입니다」** — 법인이 아니라 **그룹 단위 페이지**다.
- Next.js App Router **CSR**: 셸과 RSC 페이로드(11 청크, 13,185자)에 「복리」·「복지」가 **0건**이고 본문은 클라이언트에서 API 로 받아 온다. 콘텐츠는 `infra1-static.recruiter.co.kr/builder/2026/04/14/...` 의 빌더 이미지로 보이는 정황만 확인했다(og:image). **렌더·API 추적은 하지 않았다** — 계약의 「헤드리스 렌더는 원본·데이터 JSON 에 항목이 없을 때만」 + 요청 한도 때문이고, 이 판정이 이 페이지에 의존하지 않기 때문이다.
- 귀속 경로 자체는 있다: 메타 `keywords` 가 `HL그룹,HL그룹채용,**HL만도채용**,HL클레무브채용,HL디엔아이한라채용` 이고 홈 GNB 에서 이 사이트로 나간다. 즉 **채용 주체로 식별은 되지만 복지 페이지가 그룹 단위**다 — 한국금융지주와 같은 구조인데, HL만도는 자기 도메인에 목록이 있어 사정이 정반대다.
- ⚠ **KAI 선례(다른 회사 샘플 템플릿)는 이번에 해당하지 않는다.** 이 `/career/welfare` 는 HL그룹 명의가 붙어 있고, 애초에 정본으로 쓰지 않는다.

## ② 복지 항목 — 원문 39개, 전부 HTML 텍스트

### ②-1 정본 ① `/ko/career.do` Life 섹션 — 15개 / 2블록

마크업: `<section id="life">` → `div.work_balance`(`li > p.intro` 6개) + `div.support_healthcare`(`swiper-slide > h4 > span.txt` + `p` 9개).

| 블록 (h3) | 수 | 항목 (원문 요약) |
|---|---:|---|
| 워라밸(Work-life Balance) | 6 | 유연근무제도(출퇴근 시간 선택) · 재택근무제도 · **75개**의 사내 동호회 · 여름휴가 자유 사용 · **복지몰 포인트**(여행·문화공연·자기개발) · 전국 호텔·리조트 **법인 회원가** |
| 각종 지원 및 건강관리 | 9 | 생활안정자금 지원(사내 근로 복지 기금) · 주택자금지원(구매·임차 장기융자) · 자녀 교육비 지원(유치원 보조비, 고교·대학 등록금 전액) · 어린이집 운영(주요 모든 사업장) · 경조사 지원(경조 용품·조사 서비스) · 건강검진 지원(배우자 포함) · 의료비 지원 · 피트니스 센터 운영 · **사내 건강관리실 운영** |

**예시 2개(원문)**
- `복지몰 포인트를 사용해 여행, 문화공연, 자기개발을 할 수 있습니다.`
- `자녀 교육비 지원 — 자녀 교육비(유치원 보조비, 고등학교·대학교 등록금 전액)를 지원합니다.`

### ②-2 정본 ② `/ko/sustainability/human-rights-and-safety.do` 조직문화 — 24개 / 4블록

| 블록 | 수 | 항목 (원문) |
|---|---:|---|
| 유연한 근무환경을 위한 다양한 제도 (h4) | 4 | 21시 이후 퇴근 시 **최소 12시간 후 출근** · 초과된 근무시간을 조기 퇴근 또는 **적립휴가로 대체** · 근무계획에 따라 근무장소 자유롭게 선택 · 연중 희망 일정에 맞춰 여름휴가 사용 |
| 복리후생 > 시설 지원 (h5) | 3 | 사원주택(아파트/기숙사) · 체육시설 · 기타 복지시설(구내식당, 의무실, 탈의실, 샤워실 등) |
| 복리후생 > 생활 지원 (h5) | 11 | 급식 · 우리사주조합 · 차량 지원(통근) · 피복과 안전보호구 지급 · 의료비 지원 · 사내근로복지기금 운영 · 경조금, 조사지원제도 · 주택융자금지급 · 학자금 지급 · 개인연금 등 편의 제공 · **국민연금/건강보험제도 운용** |
| 복리후생 > 건강·문화생활 지원 (h5) | 6 | 건강진단 · 취미반 운영 · 하기 휴양소 운영 · 종합행사(사생대회/체육대회 등) · **산업재해 보상** · 일반재해 등 보조금 지급 |

- 같은 페이지의 「출산 휴가와 육아 지원」 블록은 목록이 아니라 서술문이다: 출산·육아 휴직, **남성 출산휴가·가족 돌봄 휴가**, 육아기 근로시간 단축, **사내 어린이집**(외부 전문기관 놀이 중심 프로그램, 3C 역량). 항목화는 수집 단계 판단.

### ②-3 중복·법정 제도

- **①↔② 주제 중복 11쌍**: 의료비 · 경조(경조사 지원↔경조금·조사지원제도) · 주택자금(주택자금지원↔주택융자금지급) · 학자금(자녀 교육비↔학자금 지급) · 건강검진↔건강진단 · 피트니스 센터↔체육시설 · 생활안정자금↔사내근로복지기금 · 동호회↔취미반 · 여름휴가(양쪽) · 재택근무↔근무장소 자유 선택 · 유연근무(양쪽). 합치면 **고유 약 28개**.
- **법정 제도 성격 4~7개**(미수록 규칙 후보): 국민연금/건강보험제도 운용, 산업재해 보상, (②서술) 출산휴가·배우자 출산휴가·가족 돌봄 휴가·육아기 근로시간 단축. 걸러도 **20개 남짓**이 남는다.
- **금액 명시 0건**. 정량은 「75개 동호회」·「주 40시간」·「21시 이후 퇴근 시 최소 12시간」뿐. HL D&I한라와 달리 이율·비율 표기가 없다.
- **숨김·유령 점검**: 두 페이지 모두 본문 `display:none` 은 GTM `<noscript>` iframe **하나뿐**. HTML 주석 40·48개 중 복지 문구가 든 주석 **0건**. swiper 슬라이드 원본 중복 0. 아이콘 이미지는 `alt=""` 장식이고 **항목이 전부 텍스트**라 이미지는 받지 않았다.
- ⚠ **카테고리 제목만 시각적으로 숨겨져 있다**: `<h3 class="hidden_cont">워라밸(Work-life Balance)</h3>`, 같은 방식으로 `각종 지원 및 건강관리`. `template.css:4` 에 `.hidden_cont { text-indent:-9999px; overflow:hidden; height:2px; margin:-2px 0 0 !important; }` — **display:none 이 아닌 스크린리더용**이다. 가시 텍스트만 긁으면 분류명이 사라진다(⑥-1).

## ③ robots

| 호스트 | 상태 | 내용 | 해당 경로 판정 |
|---|---|---|---|
| `www.hlmando.com` | 200 · 255B · `text/plain` · **BOM 없음**(`23 23 23` = `#`) · CRLF · Last-Modified 2022-09-05 | 주석 6줄 + 레코드 1개: `User-agent: *` / `Allow: /` + `Sitemap: https://www.hlmando.com/sitemap.xml`. Disallow·Crawl-delay **없음** | **전면 허용** |
| `hlmando.com`(apex) | 200 · 255B · 동일 바이트 | 위와 같음 | 전면 허용 |
| `hlcompany.recruiter.co.kr` | 200 · 257B · **BOM 없음** · LF | ⚠ **UA 줄 5개가 한 레코드**: `User-Agent: *` / `Googlebot` / `Yeti` / `Daumoa` / `Bingbot` → `Allow: /` + `Disallow: /*/attachFile` `/attachFile*` `/bbs*` `/resources*` **`/app*`** + Sitemap | `/appsite/company/index` = **차단**(가장 긴 일치 `/app*`) · `/career/welfare`·`/sitemap.xml`·`/_next/*` = 허용 |
| `www.hldni.com` | 200 · 30B · CRLF | `User-agent:*`(공백 없음) / `Disallow: /namo/` | `/html/recruit/welfare.asp` **허용** |
| `www.mando.com` · `www.hlholdings.com` | **curl exit 28**(20s 타임아웃, TCP 443 무응답) | 받지 못함 | **금지 취급 → 본문 미요청** |

- **AI 봇 UA 별 판정**: 네 파일 어디에도 ClaudeBot·anthropic-ai·GPTBot·CCBot·Google-Extended 를 **이름으로 지정한 레코드가 없다** → 전부 `*` 레코드를 따라 위 판정과 같다. 네패스·산일전기식 AI 봇 선별 차단 **없음**.
- ⚠ **웨이브 2 신한 함정 해당**: `hlcompany.recruiter.co.kr` 은 UA 줄 5개가 한 레코드다. UA 줄마다 그룹을 끊으면 「`*` 는 Allow: / 뿐」으로 오판해 `/appsite` 를 밟는다. 레코드 단위로 읽어야 한다. 반대로 `urllib.robotparser` 로 읽어도 `/app*` 을 놓칠 수 있으니 이 호스트는 손으로 판정한다.
- **실측 UA 대조**: `ClaudeBot/1.0` · `GPTBot/1.1` UA 로 `/ko/career.do` 를 GET 하면 둘 다 **200 · 132,613B** 로 브라우저 UA 와 **바이트 수가 같고** 「복지몰 포인트」도 들어 있다. UA 차단·차등 응답·디코이 **없음**.

## ④ 접근성 — SSR, 차단 없음. 함정 3종(사이트맵 유령 경로·http 강등 302·Last-Modified 부재)

| 항목 | 결과 |
|---|---|
| 응답 | `/ko/career.do` **200 · 132,613B · 0.08~0.27s** / `human-rights-and-safety.do` 200 · 93,038B · 0.08s / `/ko/main.do` 200 · 79,499B · 0.14s |
| 렌더링 | **서버사이드 렌더**(Apache + JSP/Spring `.do`, `JSESSIONID` Set-Cookie). 39항목이 최초 HTML 에 텍스트로 있다. `__NEXT_DATA__`·JSON API 경로 없음 |
| 봇 차단 | WAF·캡차·429 **없음**. 쿠키 없이 첫 요청부터 전문. 2KB 미만 응답은 67B 리다이렉트 스텁뿐이고 차단 문구 0 |
| HEAD/GET | HEAD **200**(Content-Length 132,613) · GET 200 — 차이 없음. 상태줄이 `HTTP/1.1 200 200`(이유구 자리에 숫자)인 기벽이 있으나 파싱에 영향 없음 |
| TLS | TLSv1.3 `TLS_AES_256_GCM_SHA384` · `Verify return code: 0` · subject `C=KR, ST=Gyeonggi-do, L=Pyeongtaek-si, **O=HL Mando Corporation**, CN=*.mando.com` · SAN `*.mando.com`·`*.hlmando.com`·`hlmando.com`·`*.hlmando.cn`·`hlmando.cn`·`mando.com` · 발급자 Thawte TLS RSA CA G1(DigiCert) · 유효 2026-06-05 ~ **2026-12-20** |
| 인코딩 | UTF-8(헤더 `charset=UTF-8` + `<meta charset="UTF-8">` + `Content-Language: ko-KR`). 한글 정상 |
| www/apex | 둘 다 `20.214.250.115`, **apex 도 그대로 200**(리다이렉트 없음, 같은 67B 스텁). SAN 에 apex 포함이라 TLS 실패 없음 |
| 진짜 404 | 없는 `.do` 경로(`/ko/career/welfare.do`) → **HTTP 404**(47,207B 안내 페이지). soft-404 **아님** |
| ⚠ 사이트맵 유령 경로 | `sitemap.xml` 200 · 27,569B · URL **139개**, lastmod 가 전부 `2022-09-08` 한 값. 그런데 등재된 `/ko/career/`·`/ko/career/hr-policy`·`/ko/career/career-opportunities` 는 셋 다 **302 → `/404.do`** 다. 실제 채용 페이지 `/ko/career.do` 는 **사이트맵에 없다** → 발견 경로로 쓰면 정본을 놓치고 404 를 줍는다 |
| ⚠ http 강등 302 | 그 302 의 `Location` 이 **`http://www.hlmando.com/404.do`**(https 아님). 리다이렉트 추적 시 평문으로 내려간다 |
| ⚠ 갱신 감지 | 동적 페이지에 `Last-Modified`·`ETag`가 **없다**(`Transfer-Encoding: chunked`). 변경 감지는 본문 해시로만 가능 |

## ⑤ 재무·직원 3축

- 회사 소개 페이지가 밝힌 값(2025년 기준): 매출액 **8,393 십억원** · 임직원수 **Global 17,758명** · 신용등급 AA- · 글로벌 14개국 50여 거점.
- ⚠ **설립일이 법인 기준이 아니다.** 사이트는 「설립일 **1962년 10월 01일**」, 연혁은 「HL Mando 60여 년의 역사」로 적고, 연혁의 「㈜만도 유가증권시장 신규 상장」도 **2010년 블록**에 있다. 그러나 등록 대상인 상장 법인 **HL만도(204320)** 는 구 ㈜만도(현 HL홀딩스 060980)에서 갈라져 나온 법인이고, 로스터의 corp_code 는 `01042775` 다. **사이트의 설립일·상장 연혁은 승계 계보이지 이 법인의 DART 이력이 아니다.**
- 이번 세션에서 **DART·DB 는 조회하지 않았다**(계약상 DB 접속 금지). 사업보고서 이력 연수와 시계열 시작 연도(분할 신설 연도)는 **리드가 DART 로 확인해야 한다**. 재무·직원 그래프의 시작점이 1962 가 아니라는 점만 확실하다.
- 리포 파일 grep 기준 `204320`·`HL만도`·`hlmando` 는 웨이브 4 후보 문서 3개(`_ROSTER.md`·`candidates-2026-09-19.md`·`datalab-2026-09-19.md`)에만 나온다. 복지 시드 SQL 138개에는 없다.

---

## 수집 설계 시 유의

1. **정본이 두 개고, 둘을 합쳐야 목록이 완성된다.** `/ko/career.do` 에만 있는 것(복지몰 포인트·호텔·리조트 법인 회원가·사내 건강관리실)과 `human-rights-and-safety.do` 에만 있는 것(사원주택·급식·우리사주조합·통근 차량·피복/안전보호구·개인연금·하기 휴양소·종합행사)이 갈린다. 주제 중복 11쌍(②-3)은 **채용 페이지 문구가 더 서술적**이니 그쪽을 본문으로 잡고 지속가능경영 쪽을 보강으로 쓰는 편이 낫다. 합치면 고유 약 28개, 법정 제도(국민연금/건강보험·산업재해 보상·출산/육아 법정분)를 걸러도 20개 남짓.
2. **가시 텍스트만 파싱하면 분류명이 사라진다.** 「워라밸(Work-life Balance)」·「각종 지원 및 건강관리」 두 `h3` 이 `class="hidden_cont"`(text-indent:-9999px, height:2px) 로 시각적으로 숨겨져 있다. **원본 HTML 을 그대로 읽고** `hidden_cont` 를 제거 대상으로 삼지 말 것. 항목 본문은 `div.work_balance li p.intro` 6개와 `div.support_healthcare .swiper-slide h4 span.txt + p` 9개로 잡는다. 워라밸 6항목은 **항목명이 따로 없는 완결 문장**(`<strong>` 이 앞머리)이라 항목명을 만들어 붙여야 한다 — 이때 문장을 그대로 베끼면 필러가 된다.
3. **사이트맵을 발견 경로로 쓰지 마라.** `sitemap.xml` 의 `/ko/career/…` 세 경로는 302 → `http://…/404.do` 로 죽어 있고 실제 정본 `/ko/career.do` 는 사이트맵에 없다. 경로는 GNB 링크로 고정하고, 생존 판정은 상태코드(진짜 404 는 정상 동작)와 **본문에 「복지몰 포인트」·「HL Mando 복리후생 제도는」이 남아 있는지**로 한다. `Last-Modified`·`ETag` 가 없으니 갱신 감지는 본문 해시로.
4. **구 사명 도메인·지주 도메인에 손대지 마라.** `www.mando.com`·`www.hlholdings.com` 은 443 이 무응답이라 robots 조차 못 받았다(금지 취급). 인증서 SAN 에 `*.mando.com` 이 남아 있어도 복지 출처로 쓸 근거가 없고, 그룹 ATS `hlcompany.recruiter.co.kr` 은 `/app*` 이 robots 금지인 데다 복지 페이지가 「HL그룹」 단위다 — **경로와 무관하게 쓰지 않는다.**
5. **호출 규약**: `www.` 와 apex 둘 다 200 이지만 `www.` 로 고정. 인증서 **2026-12-20 만료** → 그 뒤 재수집 때 검증 실패 여부를 다시 볼 것. 리다이렉트 자동 추적(`-L`)은 http 강등을 타므로 끄거나 https 강제. 재무·직원 축을 붙일 때 **사이트의 1962년 설립·2010년 상장 표기를 그대로 쓰면 안 된다**(⑤) — DART corp_code `01042775` 기준 이력으로 맞출 것.
