# 삼성E&A (SAMSUNG E&A CO., LTD.) — 복지 수집 가능성 실사 프로브

- 회사: 삼성E&A / SAMSUNG E&A CO., LTD. (플랜트 EPC·엔지니어링, KOSPI 028050)
- 구 사명: **삼성엔지니어링** (2024년 「삼성E&A」로 변경). 구 도메인 `samsungengineering.com` 은 살아 있고 **301/302 로 `samsungena.com` 에 넘어간다**.
- 본사: 서울특별시 강동구 상일로6길 26
- 프로브 일시: 2026-09-05
- **판정: 가능 — 자기 도메인에 「복리후생」 전용 페이지가 있고, 항목명이 서버렌더 HTML 텍스트(h4/strong)로 그대로 나온다. 이미지 판독·헤드리스 불필요.**

---

## ① 공식 채용/복지 페이지 URL (공식 도메인만)

### 정본 — 자기 도메인 `samsungena.com`

| 용도 | URL |
|---|---|
| **복리후생 (정본)** | `https://www.samsungena.com/kr/careers/company-life` |
| 복리후생 (영문 대조용) | `https://www.samsungena.com/en/careers/company-life` |
| 인재양성(교육) | `https://www.samsungena.com/kr/careers/talent-development` |
| 채용공고 목록 | `https://www.samsungena.com/kr/careers/join-us/job-opening/list` |
| 채용FAQ | `https://www.samsungena.com/kr/careers/join-us/careers-faq` |

- 페이지 `<title>` = `복리후생 | 인재채용ㅣSAMSUNG E&A`. GNB 경로 = 인재채용 > 복리후생.
- ⚠ **sitemap.xml 이 낡았다.** `https://www.samsungena.com/resources/sitemap.xml`(200, 10,520B, 91 URL)은 복지 페이지를
  `/kr/careers/join-us/company-life` 로 적어 두었는데 이 URL 은 **HTTP 404 + `content-type: application/json`**
  (`{"timestamp":...,"status":404,"error":"Not Found",...}`)을 돌려준다. 실제 경로는 `join-us` 가 빠진 `/kr/careers/company-life` 다.
  사이트맵이 아니라 **페이지 내 GNB 링크를 따라가야** 200 이 온다.

### 보조 — 그룹 공통 채용사이트 `samsungcareers.com` (법인 귀속 확인됨)

- URL: `https://www.samsungcareers.com/subsid/detail/D80`
- **귀속 경로**: 그룹 채용 홈 > **관계사 소개 > 건설/중공업 > 삼성E&A** (계열사 코드 `D80`). 페이지 안에서 법인이 명시적으로 특정된다 —
  본문 헤딩이 그대로 **「삼성E&A의 근무 환경과 복지 제도」** 이고, 상세정보 블록에 주소(강동구 상일로6길 26 GEC)·채용문의(`recruit.sena@samsung.com`)·홈페이지(`https://samsungena.com/`)가 붙어 있다.
  그룹 공통 복지가 아니라 **법인 전용 복지 블록**이다.
- 이 페이지는 정본이 아니라 **보조 출처**로만 쓴다(자기 도메인 페이지가 있으므로 계약 §1 에 따라 정본은 samsungena.com).
- 3자 사이트(사람인·잡코리아·잡플래닛·캐치 등)는 확인하지 않았고 인용도 하지 않았다.

## ② 복지 항목 명시 여부 — **명시됨. 정본 23개 / 3개 카테고리, 보조 29개 / 3개 카테고리**

### 정본(samsungena.com `/kr/careers/company-life`) — 23개, 전부 HTML 텍스트

| 카테고리 | 항목 수 | 항목명 |
|---|---|---|
| 회사 생활 지원 | 10 | 사내 동호회 운영 및 활동 지원, 수면실을 갖춘 휴게공간, 사내도서관, 선택형 복지 포인트 지급, 테마파크 이용 지원, 투게더플러스, 통근버스, 사내식당, 전국 리조트 이용 지원, 장기 근속 휴가 및 휴가비 지원 |
| 건강 지원 | 7 | 심리 상담센터, 사내병원-가정의학과, 사내병원-정신건강의학과, 종합 건강 검진(배우자 포함), 의료비 지원(단체/실손 보험), 명상실, 피트니스 센터 |
| 가족 지원 | 6 | 직장 어린이집, 임신/출산 비용 지원, 학자금 지원(유치원, 대학교), 가족 초청 행사, 사옥 결혼식장 무료 대관, 경조 휴가 및 경조금 지원 |
| **계** | **23** | |

**예시 2개**: `종합 건강 검진(배우자 포함)`(건강 지원), `사옥 결혼식장 무료 대관`(가족 지원).

- 마크업: 「회사 생활 지원」은 `<h4>`, 「건강 지원」·「가족 지원」은 `<strong>`. 카테고리는 `<h3>`. **이미지 안 텍스트 아님** —
  `/resources/kr/images/careers/welfare/*.jpg` 는 전부 장식 사진이고 `alt=""` 로 비어 있다.
- **설명문은 「가족 지원」 6개에만** `<p class="sub_txt">` 로 붙어 있다(각 2~4문장). 회사 생활·건강 17개는 **라벨만**.
- **금액 명시 없음.** 본문에 원·만원 단위 금액이 하나도 없다.
- ⚠ **중복 렌더**: 「가족 지원」 6개 항목명이 캐러셀 본문과 하단 썸네일 내비에 **각각 한 번씩, 총 2회** 나온다. 그대로 파싱하면 6개가 12개로 부푼다.
- ⚠ 「타임라인」은 항목이 아니라 `<span class="blind">` 스크린리더용 라벨이다. 항목으로 세지 말 것.
- 영문 페이지(`/en/careers/company-life`, 200, 77,383B)도 같은 구조·같은 항목 수라 대조 검증에 쓸 수 있다.

### 보조(samsungcareers.com `/subsid/detail/D80`) — 29개, 전 항목에 설명문

`<h3>` 카테고리 3개 + `class="tag tip"` 항목 29개, 모두 서버렌더 HTML 텍스트.

| 카테고리 | 항목 수 | 항목명 |
|---|---|---|
| 가족, 의료 및 소득 지원 | 9 | 의료비 지원, 심리상담센터, 자녀학자금, 사내어린이집, 모성보호, 개인연금, 경조사 지원, 장기근속포상, 선택적 복리후생 |
| 자기 개발 지원 | 10 | 사내 직무 전환, 기술대학원, EPC 직무 교육, 프로젝트 리더 양성 교육, DT 교육, Career Track, 외국어 교육 지원, 사외 온라인교육, 지역전문가, MBA |
| 사내 문화 및 편의 | 10 | 자율출퇴근제, 자율 복장, 사내식당, 통근버스, 사내피트니스, 사내동호회, 여가 활동 지원, 도서관, GWP, 사내병원 |
| **계** | **29** | |

- 정본에 **없는** 항목이 여기에만 있다: `개인연금`, `모성보호`(출산전후휴가·육아기 단축·난임 치료비), `자율출퇴근제`(선택적 근로시간제), `자율 복장`, `GWP`, 그리고 자기개발 10종.
- 금액은 없지만 **정량 서술은 있다**: 사내식당 1,300석·9개 코너, 통근버스 100여대, 도서관 약 14,000권, 동호회 60개 이상.
- ⚠ 「자기 개발 지원」 10개는 계약 §3 의 "교육 커리큘럼"에 가깝다. 복지로 넣을지 교육으로 분리할지는 수집 설계에서 결정할 것.

## ③ robots 허용 — **정본 전면 허용, BOM 없음. AI 봇 개별 차단 없음**

`https://www.samsungena.com/robots.txt` (HTTP 200, 223B, **BOM 없음** — 선두 바이트가 `55 73 65 72` = `User`):

```
User-agent: *
Allow: /
Disallow: /*/security-report
Disallow: /*/contact-us
Disallow: /*/privacy
Disallow: /*/cctv
Disallow: /*/careers/join-us/recruitment-process

Sitemap: https://www.samsungena.com/resources/sitemap.xml
```

- **그룹은 `*` 하나뿐**이다. ClaudeBot·anthropic-ai·GPTBot·CCBot·Google-Extended 를 이름으로 막는 지시가 **없다** → AI 봇도 `*` 규칙을 따른다.
- 판정 대상 경로 `/kr/careers/company-life` 는 **허용**. 막힌 careers 경로는 `/*/careers/join-us/recruitment-process`(채용절차) 하나뿐이라 복지와 무관하다.
- `https://www.samsungengineering.com/robots.txt` → 302 로 위 파일에 합류(별도 규칙 없음).
- ⚠ 보조 출처 `samsungcareers.com` 은 **robots.txt 가 사실상 없다**: apex 는 301→www, www 는 302 로 `/sub/etc/error.html` 에 떨어지고
  거기서 **HTTP 200 + 본문 `{"code":500,"status":999,"message":"Internal server error"}`**(59B)를 준다. sitemap.xml 도 같은 방식으로 302→에러.
  명시적 금지가 없으니 기본 허용으로 보되, **이 59B 오류 JSON 을 robots 규칙으로 파싱하는 사고**를 조심할 것.

## ④ 접근성 — **서버렌더 HTML, 차단 없음, TLS 정상, UTF-8**

| 항목 | 정본 samsungena.com | 보조 samsungcareers.com |
|---|---|---|
| 응답 | HTTP 200, 78,829 bytes, 0.14s | HTTP 200, 123,041 bytes, 0.12s |
| 렌더링 | **SSR**. 항목 23개가 최초 HTML 에 그대로 존재 → curl + 파서로 충분, Playwright 불필요 | **SSR**. 항목 29개·설명문 모두 최초 HTML 에 존재 |
| JS 의존 | Swiper 캐러셀은 표시용. 콘텐츠는 JS 렌더 아님 | 상세 설명이 `<p>` 로 이미 들어 있음(툴팁 UI 만 JS) |
| 봇 차단 | 없음. **기본 curl UA(`curl/*`)로도 동일한 200·78,829B** — WAF·캡차·UA 게이트·429 미관측 | 없음. 기본 curl UA 로도 200·123,041B |
| TLS | 정상(`ssl_verify_result=0`). O=SAMSUNG E&A CO., LTD., CN=`*.samsungengineering.com`, SAN 에 `samsungena.com`·`*.samsungena.com`·`samsungena.co.kr` 포함. DigiCert Global G2, **만료 2026-11-18** | 정상. CDNetworks 공유 인증서 CN=`support100.cdnetworks.net`, SAN 에 `*.samsungcareers.com`. GlobalSign, **만료 2026-11-09** |
| 인코딩 | `<meta charset="UTF-8">`, 한글 정상 | `<meta charset="UTF-8">`, 한글 정상 |
| apex/www | `samsungena.com` 과 `www.samsungena.com` **둘 다 200**, 같은 IP `203.254.216.158`. 리다이렉트 없음 | apex 는 301→www. www 는 CDN(CDNetworks) IP |
| HEAD/GET | HEAD 도 200. 헤더에 HSTS·X-Frame-Options DENY·`X-ORACLE-DMS-*`(WebLogic), 세션 쿠키 `SSE_JSESSIONID` 발급 | — |
| 구 도메인 | `www.samsungengineering.com/kr/careers/company-life` → **302 1회** → `www.samsungena.com/...`, 최종 200 | — |

---

## 수집 설계 시 유의 (수집·SQL은 이번 범위 밖)

1. **sitemap 을 믿지 마라.** 사이트맵의 `/kr/careers/join-us/company-life` 는 404(그것도 JSON 404)다. 정본 URL 은 `/kr/careers/company-life`.
   수집기가 사이트맵만 보고 돌면 「복지 페이지 없음」으로 오판한다. 404 응답이 `text/html` 이 아니라 `application/json` 인 점도 soft-404 탐지 로직에 반영할 것.
2. **가족 지원 6개 중복 제거**가 필수다. 캐러셀 본문과 썸네일 내비가 같은 `<strong>` 라벨을 두 번 낸다 — 정본 23개가 중복 포함 시 29개로 잡힌다(보조 출처 29개와 숫자가 겹쳐 헷갈리기 쉽다).
3. **두 출처를 합칠 거면 중복 정규화가 필요하다.** 사내식당·통근버스·사내동호회·도서관·사내병원·피트니스·심리상담·학자금·어린이집·경조·장기근속·복지포인트가 양쪽에 이름만 다르게(예: 「선택형 복지 포인트 지급」 vs 「선택적 복리후생」, 「직장 어린이집」 vs 「사내어린이집」) 나온다.
   그룹 사이트에만 있는 것은 개인연금·모성보호·자율출퇴근제·자율 복장·GWP + 자기개발 10종이다.
4. **본문 분량은 보조 출처가 훨씬 두껍다.** 정본은 23개 중 6개에만 설명문이 붙어 본문 텍스트가 약 2,100자에 그치지만, 보조 출처의 복지 블록은 29개 전부 설명문(블록만 약 15KB 마크업)이라 콘텐츠 두께 개선에 유리하다. 다만 **배지 계보상 출처 표기는 도메인별로 갈라 적어야** 한다(자기 도메인 vs 그룹 채용사이트).
5. **사명 표기가 섞여 있다.** 본문·`<title>`·푸터는 「삼성E&A / SAMSUNG E&A」인데 **meta keywords·description 은 아직 「삼성엔지니어링」**이다(`삼성엔지니어링 복리후생 페이지입니다…`). 메타 태그를 회사명 판정에 쓰면 구 사명이 들어온다. 구 도메인 `samsungengineering.com` 도 살아서 리다이렉트하므로 URL 정규화 시 최종 URL 을 기록할 것.
6. **인증서 두 장 모두 2026-11 만료**(정본 11-18, 보조 11-09). 그 이후 재수집에서 TLS 검증 실패가 나면 갱신 문제부터 의심할 것.
