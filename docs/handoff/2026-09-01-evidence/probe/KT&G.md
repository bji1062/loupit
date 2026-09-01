# KT&G (케이티앤지) 복지 수집 가능성 실사 프로브

- 회사: KT&G (담배·건강기능식품, KOSPI 033780)
- 프로브 일시: 2026-09-01
- **판정: 수집 불가** (복지 항목이 열거된 공식 문서가 존재하지 않음)

---

## ① 공식 채용사이트 / 복지 페이지 URL

| 구분 | URL | 도메인 성격 |
|---|---|---|
| 인사제도(복지 언급 유일 페이지) | https://www.ktng.com/career/hrsystem | **공식 자사 도메인** |
| 채용가이드 | https://www.ktng.com/career/recruit | 공식 자사 도메인 |
| 직무소개 | https://www.ktng.com/career/job/{marketing-sales, management-support, manufacturing, raw-material, rnd} | 공식 자사 도메인 |
| 공식 채용사이트(ATS) | https://ktng.recruiter.co.kr/career/home | **벤더 서브도메인** (MIDAS IN 「JOBFLEX」 ATS, `recruiter.co.kr`) — 자사 도메인 아님 |

- **전용 복지 페이지는 없다.** 과거 존재하던 `https://www.ktng.com/welfare` 는 현재 **404**.
- 구 URL `/personnel`, `/evaluation`, `/development`, `/model` 은 전부 리뉴얼로 **`/career/hrsystem` 한 페이지로 통합**됐다(네 URL 모두 동일 318KB 응답, 본문 동일 2,274자). ATS 사이트의 「인사제도」 GNB 는 아직 이 구 URL 들을 가리킨다.
- ⚠ `www.ktng.com/sitemap.xml` 이 광고하는 `/careers/*`(**복수형**) 경로는 **전부 404**. 실제 라이브는 `/career/*`(단수형). 사이트맵이 낡았다.

## ② 복지 항목 명시 여부 — **사실상 0개**

`/career/hrsystem` 의 「인사제도」 블록 전문(이게 전부다):

> Work & Life Balance를 통한 행복한 일터를 지향합니다.
> KT&G는 구성원 삶의 질 향상을 위한 복리후생제도를 운영하고 있습니다. 임직원의 연령과 근속기간을 고려하여 라이프사이클에 맞는 복지 미션을 수립하고 있으며, 임직원 본인 뿐만 아니라 가족들에게도 다양한 복리후생 프로그램을 제공하고 있습니다.

- 열거된 개별 항목(경조금·자녀학자금·의료비·사택/기숙사·건강검진·선택적복지 등) **0개**. 전부 방향성 산문.
- 페이지 전체(2,274자)를 복지 키워드 18종으로 전수 검색: `복리후생`(문구 내 언급 6회, 항목 아님) 외 `경조/학자금/의료비/사택/기숙사/건강검진/자녀/보육/육아휴직/연금/주택자금/콘도/휴양/선택적복지/유연근무/재택` **전부 0건**.
- 채용가이드(864자)·직무소개 5개 페이지도 복지 키워드 **0건**(단, 경영지원 직무 페이지에 `동호회` 1회 — 직무 설명 맥락이라 복지 항목 아님).
- 그나마 항목성 서술이 있는 건 **복지가 아니라 HRD**: 「약 1,200개 온·오프라인 사내 교육과정」, 「장기 위탁교육 — 국내 야간 대학·대학원 / E-MBA(서울대·카이스트) / 해외 MBA(QS 100위 이내)」, 「해외 주재원 파견·글로벌 프로젝트」, 「사내 공모제도」.
  - 예시 2개를 굳이 뽑으면: ① 장기 위탁교육(해외 MBA 지원) ② 사내 교육과정 1,200개 — **둘 다 복지 스키마에 넣기엔 경계선**.

## ③ robots.txt

**www.ktng.com** — 전면 허용, 문제 없음
```
User-Agent: *
Allow: /

Sitemap: https://www.ktng.com/sitemap.xml
Sitemap: https://en.ktng.com/sitemap.xml
```

**ktng.recruiter.co.kr** — `/career/*` 허용
```
User-Agent: * / Googlebot / Yeti / Daumoa / Bingbot
Allow: /
Disallow: /*/attachFile
Disallow: /attachFile*
Disallow: /bbs*
Disallow: /resources*
Disallow: /app*
Sitemap: https://ktng.recruiter.co.kr/sitemap.xml
```
→ 채용공고 경로 `/career/home`, `/career/job`, `/career/jobs/{id}` 는 **허용**. 마이페이지(`/app*`)·첨부(`attachFile`)만 차단.

**infra1-static.recruiter.co.kr** (첨부 PDF CDN) — `robots.txt` 가 **403**
```
<Error><Code>MissingKey</Code><Message>Missing Key-Pair-Id query parameter or cookie value</Message></Error>
```
→ robots 부재 + 3rd-party CDN. 파일 자체는 200 으로 받아지지만 정책 근거가 없다.

## ④ 접근성

| 대상 | 결과 |
|---|---|
| `www.ktng.com` | **정적 HTML(Next.js SSR)** — curl 로 본문 텍스트 파싱 가능. 200 OK, 봇차단 없음, TLS 정상, 응답 0.4~0.6s |
| `ktng.recruiter.co.kr` | **완전 클라이언트 렌더 SPA**(Next.js App Router). curl 본문 가시 텍스트 **16자**(제목만). RSC flight 페이로드에도 콘텐츠 없음 → **헤드리스 렌더 필수**. 봇차단·403 없음, TLS 정상 |
| 채용공고 본문 | 텍스트 본문이 **아예 없다**. 첨부 PDF 1개(`kt&g_2026년 하반기 신입(사무)사원 채용 직무소개서.pdf`)가 전부 |
| 그 PDF | 5.7MB / 11페이지 / **텍스트 레이어 10자 = 이미지 전용**. OCR 없이는 파싱 불가. 게다가 3rd-party CDN 호스팅 |
| 콘텐츠 API | `https://api-recruiter.recruiter.co.kr/position/v2/jobflex/{id}` — 브라우저 외 직접 호출 시 **500 `NullPointerException`**(테넌트 헤더 필요) |

### 함정 메모
1. `www.ktng.com` 의 404 는 HTTP 404 를 주긴 하나 **본문 260KB 짜리 SPA 에러 셸**이라 응답 크기로 성공 판정하면 오진한다.
2. 구 URL 4개(`/personnel` 등)가 **모두 같은 페이지**를 반환한다 — URL 다양성을 콘텐츠 다양성으로 착각하면 중복 적재.
3. 사이트맵의 `/careers/*` 는 죽은 경로다(위 ① 참조).

---

## 폴백 후보 (미검증)

- https://www.ktng.com/sustainability/archive/ktng-report — 「KT&G Report」 2017~2025 지속가능보고서 PDF. 공식 자사 도메인, robots 허용, `https://www.ktng.com/attach/download/{uuid}` 로 배포.
- 다만 ⓐ 다운로드가 JS 클릭 기반이라 UUID 를 렌더링으로 캐야 하고, ⓑ ESG 서술형 문서라 복지 「항목」 추출 신뢰도가 낮으며(보통 육아휴직 복귀율 같은 지표 표), ⓒ 수백 페이지 대용량이다. **비용 대비 회수 낮음 — 권장하지 않음.**

## 결론

**수집 불가.** KT&G 는 공식 도메인·공식 채용사이트 어디에도 복리후생을 **항목으로 열거하지 않는다**. 기술적 접근성(robots 전면 허용, SSR HTML)은 오히려 좋은 편이지만 **가져올 내용물이 없다**. 지금 파이프라인을 태우면 복지 항목 0개짜리 빈 레코드가 생긴다.
