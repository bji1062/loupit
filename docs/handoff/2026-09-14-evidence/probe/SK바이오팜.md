# SK바이오팜 (SK Biopharmaceuticals · KOSPI 326030) — 복지 수집 가능성 실사 프로브

- 회사: SK바이오팜 / SK biopharmaceuticals (중추신경계 신약, 본사 경기 성남 판교)
- DART: corp_code `00878696`, 정식명 **「에스케이바이오팜」** — 영문 약칭 SK 를 한글로 음차한 등기명이다. 서비스 표시명(SK바이오팜)과 DART 명이 문자열로 일치하지 않으므로 corp_code 로 매칭할 것. 설립 2011-04-01.
- 공식 도메인: `www.skbp.com` (DART hm_url 그대로 생존. apex `skbp.com` 은 무응답 — ④)
- 프로브 일시: 2026-09-14 · 요청 23회(skbp.com 16 · skcareers.com 7)
- **판정: 가능** — 법인 자기 도메인 `www.skbp.com` 의 「지속가능경영 > ESG 성과 > Human Capital Management」 페이지에 **SK바이오팜 복리후생 16항목 / 4카테고리가 서버렌더 HTML 텍스트**로 있다. 그룹 공통 복지가 아니고 「계열사별 상이」 면책도 없다. robots 허용(AI 봇 개별 차단 없음), 봇 UA 차등 응답 없음.

- 정본 URL: `https://www.skbp.com/kor/sustainability/talent.do` (섹션 `<h4>복리후생</h4>` 아래 `ul.m_list.n2`)
- 항목 수: 16줄 / 4카테고리 (회사 생활 6 · 자녀 양육 3 · 건강 관리 3 · 주거 및 여가 활동 4). 가운뎃점으로 묶인 복합 항목을 풀면 약 24개.
- 렌더 방식: SSR(JSP `.do`, `JSESSIONID`). 최초 HTML 에 텍스트로 존재 → curl + HTML 파서로 충분, 헤드리스 불필요.

> 리드 메모 응답: 「SK 그룹 공통 채용사이트만 나오는」 경우가 **아니다**. 복지는 법인 자기 도메인에 있다. SK Careers(skcareers.com)는 SK바이오팜을 채용 주체로 식별하지만(귀속 경로 ①-2) **법인별 복지 콘텐츠가 없다** — 정본 후보에서 제외한다.

---

## ① 공식 채용/복지 페이지 URL

### 1. 법인 자기 도메인 `www.skbp.com` — 정본

| 용도 | URL | 결과 |
|---|---|---|
| 홈 | `https://www.skbp.com/` → 302 → `/kor.do` | 200, 26,432B. GNB 는 JS 로 그려져 원본 href 에 채용 링크가 안 보인다 → sitemap 으로 찾았다 |
| sitemap | `https://www.skbp.com/sitemap.xml` (robots 의 Sitemap 지시, **자기 도메인 것** — 그룹 sitemap 아님) | 200, 12,551B, `<loc>` 80개(국·영) |
| **복리후생 (정본)** | **`https://www.skbp.com/kor/sustainability/talent.do`** | 200, 32,359B. `<title>Human Capital Management &lt; ESG 성과 &lt; 지속가능경영 &lt; SK바이오팜</title>` |
| 채용 | `https://www.skbp.com/kor/recruit/careers.do` (메뉴 「소통채널 > 채용」) | 200, 16,652B. 채용 절차(지원서→서류→SKCT→면접→채용검진)만. 복지 항목 0. 「수시 채용의 모든 과정은 SK그룹 채용 플랫폼인 SK Careers(skcareers.com)를 통해 진행됩니다」 + 버튼 `https://www.skcareers.com/Recruit?CorpCode=10013` |
| 영문 대응 | `https://www.skbp.com/eng/sustainability/talent.do` | 200, 30,221B. 같은 4카테고리·16줄이지만 **내용이 번역 관계가 아니다**(②) |

- 채용 전용 서브도메인은 없다: `recruit.`·`careers.`·`career.skbp.com`, `skbp.recruiter.co.kr` 전부 NXDOMAIN.
- ⚠ 복지는 채용 메뉴가 아니라 **지속가능경영(ESG) 메뉴** 아래에 있다. 표준 경로(`/recruit`·`/careers`)만 보면 0건으로 오판한다.

### 2. 그룹 채용사이트 `www.skcareers.com` — 채용 주체 식별 O, 법인 복지 X

**귀속 경로 (SK바이오팜이 채용 주체로 식별되는 근거)**
1. 법인 채용 페이지의 버튼이 `skcareers.com/Recruit?CorpCode=10013` 으로 간다 → SK Careers 안의 SK바이오팜 코드 = `10013`.
2. `https://www.skcareers.com/AreasWork/Bio`(GNB 「Areas of Work > Bio」) 원본 JS 에 `//SK바이오팜 → 10013 //SK케미칼 → 10015 //SK바이오사이언스 -> 10039(제외)` 주석과 `corpcode = ['10013','10015']`. 하단 슬라이더 카드 「SK바이오팜」은 `https://www.skbp.com/kor/recruit/careers.do` 로 되돌아간다(법인 사이트가 소개 주체).
3. `POST /AreasWork/GetRecruitList` (`sort=2`, `corpCode=["10013"]`) → JSON `totalCount 5`, 전 건 `corpName: "SK biopharmaceuticals"`(예: `R261954` 경영기획 경력, Permanent, 판교).
4. 공고 상세 `https://www.skcareers.com/Recruit/Detail/R261954` (200, 65,155B): 「회사 SK biopharmaceuticals」 표기, 근무지·기타사항만. **복리/복지 문자열 0건.** API 응답 필드에도 복지 없음(`corpName·title·jobRole·recruitType·workingType·workingArea…`).

**그룹 공통 복지 페이지 = 정본 아님**: `https://www.skcareers.com/Culture` 는 주어가 「SK」이고 법인 구분 없는 서술(「승인 없는 휴가 제도」「사내 어린이집 운영 등 다양한 모성 보호 제도」「mySUNI」). **SK바이오팜 16줄에는 사내 어린이집·승인 없는 휴가가 없다** → 법인 페이지가 그룹 문구를 복사한 템플릿이 아니라는 대조 근거. 반대로 이 그룹 문구를 SK바이오팜 카드에 붙이면 없는 제도를 만든다.

## ② 복지 항목 명시 여부 — **명시됨, 16줄 / 4카테고리, 전부 HTML 텍스트**

리드 문구: 「구성원이 행복해 질 수 있도록 일과 삶의 균형을 지원하는 복리후생 제도를 운영하고 있습니다.」 (같은 페이지 상단 섹션 주어 「SK바이오팜은…」)
마크업: `<ul class="m_list n2"><li><img …talent_N.png alt=""><strong><span>회사</span>생활</strong><div class="list"><p>항목</p>…`

| 카테고리 | 줄 수 | 항목 (원문) |
|---|---|---|
| 회사 생활 | 6 | 선택적 근로 시간제·재택근무제 시행 / 장기 근속자 포상·휴가 지급 / 사내 식당 운영(중·석식 제공) / 경조사 발생 시 휴가·경조금 지급 / 출근버스 및 차량 보조금 지원 / 여름 휴가, 해피프라이데이 (1달에 1회, 주 4일 근무) |
| 자녀 양육 | 3 | 유치원~대학교 교육비 지원 / 태아 검진·난임 치료 시 휴가 / 출산휴가·육아휴직 제도 운영 |
| 건강 관리 | 3 | 직원 및 배우자 대상 건강검진 / 의료비 지원 / 독감예방접종 진행 |
| 주거 및 여가 활동 | 4 | 주택 구입·임차 시 대출 지원 / 다양한 교육 기회 및 지원금 제공 / 선택적 복리후생(복지 포인트) 지급 / 사내 동호회 활동 지원 |
| **계** | **16** | |

**예시 2개**
- `유치원~대학교 교육비 지원` (자녀 양육)
- `여름 휴가, 해피프라이데이 (1달에 1회, 주 4일 근무)` (회사 생활)

**금액 명시: 0건.** 정량·조건 표현만 있다 — 해피프라이데이 「1달에 1회, 주 4일 근무」, 사내 식당 「중·석식」, 건강검진 대상 「직원 및 배우자」, 교육비 범위 「유치원~대학교」.

- 항목별 설명문은 없다(심텍형 라벨 목록). 아이콘 이미지 `talent_1~4.png`(`/resources/img/kor/tmp/`)는 카테고리 장식이고 `alt=""` — 항목은 이미지에 의존하지 않는다.
- **유령 항목 점검**: 원본 주석 21개를 전부 열었다 — 복지 관련 주석 블록 없음(메뉴 `전자공고`·`IR뉴스` 두 줄과 `20230925 텍스트 수정` 표식뿐, 후자는 역량개발 섹션). `display:none`·`hidden` 0건. 캐러셀 중복 없음. 「상이」「계열사」「관계사」 문자열 0건.
- **국·영 불일치**: 영문판도 4카테고리·16줄이지만 대응이 어긋난다 — 국문 「태아 검진·난임 치료 시 휴가」 ↔ 영문 「Flexible work system during pregnancy and childcare」, 국문 「다양한 교육 기회 및 지원금 제공」·「사내 동호회 활동 지원」 ↔ 영문 「Subsidies for educational training」·「Financial assistance for in-house club operations」(순서 교차), 영문엔 「Welfare points & cards」(카드). 국문을 정본으로 하고 영문은 쓰지 않는다.
- 같은 페이지의 「구성원 역량 개발」 표(New Comer·SKMS 워크숍·국내 MBA 등 약 17개 프로그램)는 **교육 커리큘럼**이라 계약 §3 상 복지 항목에 넣지 않는다.

## ③ robots — **양 도메인 모두 해당 경로 허용, AI 봇 개별 차단 없음**

| 도메인 | robots.txt | 판정 |
|---|---|---|
| `www.skbp.com` | 200, 89B, `text/plain`, **BOM 없음**(`55 73 65`). `User-agent: *` / `Disallow: /skbpFile` / `Allow: /` / `Sitemap: https://www.skbp.com/sitemap.xml` | `/kor/sustainability/talent.do`·`/kor/recruit/careers.do` **허용**. 아이콘 경로 `/resources/img/…` 도 허용 |
| `www.skcareers.com` | 200, 357B, BOM 없음. `User-agent: *` **다음에 빈 줄** 후 `Allow: /$`·`/Recruit`·`/recruit`·`/Culture`·`/AreasWork`·`/areasWork`·`/Notice`·`/FAQ`·`/Terms`·`/Privacy`·`/Sitemap.xml` 등 + `Disallow: /*?searchText=` | 레코드로 묶어 읽든(빈 줄 무시, RFC 9309·Google 방식), 빈 줄에서 레코드를 끊든(구 규격 — 규칙이 고아가 되어 무시) **둘 다 허용**. `Disallow: /` 가 없어 Allow 목록 밖 경로도 기본 허용 |

- ClaudeBot·anthropic-ai·GPTBot·CCBot·Google-Extended 를 이름으로 지정한 그룹은 **두 도메인 모두 없다** → `*` 규칙 상속, 허용.
- 실측: `talent.do` 를 ClaudeBot / GPTBot / CCBot / `curl/8.5.0` UA 로 GET → **4종 전부 200, 32,359B, md5 `60a2153a` 로 일반 브라우저 UA 와 동일**, 복지 텍스트 그대로. UA 차단·디코이 없음.

## ④ 접근성 — **SSR HTML, 차단 없음, TLS 정상 / apex 무응답**

| 항목 | 결과 |
|---|---|
| 응답 | `talent.do` GET 200, **32,359B**, 0.08~0.18s (6회 측정). `careers.do` 200, 16,652B, 0.18s |
| 렌더링 | **서버사이드 렌더**(Apache + JSP `.do`, `JSESSIONID`). 16줄이 최초 HTML 에 텍스트 → 헤드리스 불필요. JS(`sustainability.js` 등)는 탭·UI 용 |
| 봇 차단 | 관측 없음. 앞단이 AWS ALB(`skbp-waf-alb-845503091.ap-northeast-2.elb.amazonaws.com` — 이름상 WAF 경유)이고 `AWSALBTG` 쿠키가 붙지만 쿠키 없이 첫 요청부터 전문 수신. 캡차·429·차단 안내문 없음, 본문 2KB 초과 |
| HEAD/GET | HEAD 200 = GET 200 (판정은 GET 기준) |
| TLS | 정상(`ssl_verify_result=0`), HTTP/2. `CN=*.skbp.com`, SAN `*.skbp.com, skbp.com`, GlobalSign GCC R6 AlphaSSL CA 2025, 유효 2026-07-03 ~ **2027-01-18** |
| 인코딩 | UTF-8(`text/html;charset=UTF-8`), 한글 정상 |
| ⚠ www/apex | `www.skbp.com` → ALB(43.202.147.6 / 15.165.6.100). **apex `skbp.com` 은 다른 IP(169.56.102.107)로 풀리고 TCP 연결 20초 타임아웃(curl exit 28)** — 인증서 SAN 에 apex 가 있어도 호스트가 응답하지 않는다. **반드시 `www.`** |
| skcareers.com | 전 페이지 SSR(ASP.NET 계열), 200, 0.07~0.15s. 공고 목록만 `POST /AreasWork/GetRecruitList` JSON. UTF-8 이지만 일부 한글이 **숫자 문자 참조(`&#48148;…`)**로 박혀 있어 unescape 전에는 「바이오팜」 문자열 검색이 0건으로 나온다 |

## ⑤ 재무·직원 3축 (리드 확인용)

- 설립 2011-04-01(DART) — 최근 설립 아님. 다만 **KOSPI 상장은 2020년**(이 프로브에서 공시로 재확인하지 않음)이라, 사업보고서·`empSttus` 이력이 상장 이후 연도부터일 가능성이 있다 → 5개년 추이(2021~2025)가 채워지는지 리드가 DART 로 확인할 것.
- DART 정식명이 「에스케이바이오팜」이라 `corp_code_map` 에 이름으로 매칭하면 놓친다. 리포의 `db/seed/corp_code_map.csv`·`generator/data/krx_sector.csv` 에 현재 SK바이오팜 행 없음(신규 등록).
- 참고: 기등록 SK 3사 시드(`db/seed/benefit/sql/SK하이닉스.sql` 등)는 헤더가 「출처: AI 파싱 (2026-04-15) / URL: 수동 입력 / badge est」이고 `CAREERS_BENEFIT_URL NULL` 이다 — SK 형제사에 맞출 공식 출처 선례가 없으니 형제사 데이터를 끌어오지 말 것.

---

## 수집 설계 시 유의 (수집·SQL은 이번 범위 밖)

1. **복지는 채용 메뉴가 아니라 ESG 메뉴(`/kor/sustainability/talent.do`)에 있다.** `careers.do` 와 SK Careers 공고 상세는 복지 0건이다. 출처 URL 을 채용 페이지로 적으면 검증자가 항목을 못 찾는다.
2. **한 줄에 제도 2개가 묶여 있다**(「선택적 근로 시간제·재택근무제」「장기 근속자 포상·휴가」「경조사 휴가·경조금」「주택 구입·임차 대출」 등). 분리할지 원문 한 줄로 둘지 어휘표 기준으로 정하고 원문 보존 필드를 둘 것. 「해피프라이데이」 줄은 `<br>` 이 끼어 있어 태그 제거 시 공백 정규화가 필요하다. 「출산휴가·육아휴직」은 법정 제도라 미수록 규칙에 걸리고, 「태아 검진… 휴가」도 법정(임신 중 정기검진 시간)과 겹치는지 판정할 것.
3. **SK 그룹 문구와 섞지 말 것.** 「해피프라이데이」는 SK 그룹 공통 브랜드어라 형제사마다 정의가 다를 수 있다 — SK바이오팜 원문 정의 「1달에 1회, 주 4일 근무」를 그대로 쓰고, SK Careers `/Culture`(사내 어린이집·승인 없는 휴가)나 기등록 SK 3사 설명을 붙이지 말 것.
4. **최신성 위험.** 같은 페이지의 성과 수치가 `'21~'23년`에 멈춰 있고 sitemap `lastmod` 는 80개 URL 전부 `2025-02-03T02:13:16` 로 동일(생성 시각이지 내용 갱신 시각 아님)이다. 갱신 감지는 `ul.m_list.n2` 블록 바이트 해시로 하고, 국문판만 쓴다(영문판은 항목 대응이 어긋남).
5. **호출 규약**: `www.` 필수(apex 타임아웃), GET, 일반 브라우저 UA. 인증서 2027-01-18 만료. 법인 검증은 `<title>` 끝의 `SK바이오팜` 과 `<h4>복리후생</h4>` 존재로 한다.
