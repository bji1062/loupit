# LS ELECTRIC (LS일렉트릭) — 복지 수집 가능성 실사

- 회사: LS ELECTRIC(엘에스일렉트릭㈜), 전력기기, KOSPI
- 프로브 일자: 2026-09-01
- **판정: 수집 가능 (GREEN)** — 회사 전용(계열사 자체) 복지 페이지가 공식 도메인에 **정적 HTML**로 존재

## ① 공식 URL

| 구분 | URL | 성격 |
|---|---|---|
| **정본(회사 전용)** | `https://www.ls-electric.com/ko/recruit/intro` | LS ELECTRIC 자체 채용 소개. 탭 5개(WHY LS ELECTRIC / 인재상 / 인사운영방식 / **복리후생** / 인재육성)가 **한 문서에 모두 서버 렌더**됨 |
| 참고(그룹 공통) | `https://www.lsholdings.com/ko/careers/personnel-system` | **LS그룹 공통** 인사·복리후생. 페이지 자체에 *"복리후생제도는 각 계열사 별 차이가 있을 수 있습니다"* 명시 → 회사 귀속 근거로 쓰면 안 됨 |
| 참고(ATS) | `https://lselectric.recruiter.co.kr/career/home` | 채용 공고 ATS. 도메인이 **recruiter.co.kr**(제3자 호스팅)이고 Next.js CSR. 복지 서술 없음 → 사용 불가 |

→ **공식 도메인 자체 페이지 존재. 그룹 공통에 의존하지 않아도 됨.**

## ② 복지 항목 명시 여부

**명시 — 7개 항목, 전부 제목 + 설명문 1줄 구조**(`<p class="tit">` + `<div class="desc">`)

리드 문구: "LS ELECTRIC은 사원 개개인이 LS ELECTRIC을 자랑스러운 일터로 생각하고, 가정과 직장에서 보람있는 생활을 영위할 수 있도록 실질적인 지원과 혜택을 제공해 드리고 있습니다."

전체 7개:

1. **주택지원 제도** — 주택마련 자금 및 전세 자금 지원 및 지방사업장 근무시 기숙사/사택 제공
2. **건강진단/의료비지원** — 임직원 및 배우자의 종합검진과 가족 의료비를 지원
3. 경조사 지원 — 각종 경조사별 경조금, 화환 및 경조휴가 지원
4. 휴양소 운영 — 임직원의 여가생활을 위하여 휴양시설 운영
5. 학자금 지원 — 중학교·고등학교·전문대학·대학교 취학자녀 학자금 지원
6. 장기근속상 — 장기근속에 따른 휴가 및 여행 혹은 포상금 지원
7. 사원복지카드 — 기념일(생일/결혼기념일), 명절(설/추석) 맞이 복지포인트 지급

카테고리 매핑 예상: 주거(1), 건강/의료(2), 경조(3), 휴양/여가(4), 교육/자녀(5), 포상/근속(6), 복지포인트(7) — 7개가 서로 다른 축이라 중복 없음.

## ③ robots

`https://www.ls-electric.com/robots.txt` (HTTP 200)

```
User-agent:*
Allow: /
Disallow: /ko/upload/
Disallow: /ko/dl/
Disallow: /@mgt
Disallow: /education/data/
Disallow: /ko/@mgt
Disallow: /ko/education/data/
```

→ **`/ko/recruit/intro` 는 Disallow 4패턴 어디에도 걸리지 않음. 명시 Allow: / 적용. 허용.**

(참고: `lselectric.recruiter.co.kr/robots.txt` 는 `Disallow: /app*` 이라 공고 상세 `/app/jobnotice/view` 는 **금지**. 어차피 안 씀.)

## ④ 접근성

- **정적 HTML.** `curl` 원본 응답(54,578 bytes)에 복리후생 7개 항목 텍스트가 그대로 들어 있음. JS 렌더링 불필요.
- 탭 UI는 jQuery `.click()` 으로 `display` 만 토글 — 콘텐츠는 처음부터 DOM에 존재. **탭 클릭 없이 파싱 가능.**
- 봇 차단 없음: **기본 curl UA(위장 없음)로도 HTTP 200 / 53KB**. UA 위장 불필요.
- 스택: ASP.NET MVC, `Content-Type: text/html; charset=utf-8`, HSTS. 리다이렉트 없음.
- 파싱 앵커: `<!-- 복리후생 -->` … `<!--// 복리후생 -->` HTML 주석 쌍(블록 1,693 bytes)이 감싸고 있어 추출 경계가 깔끔함. 그 안에서 `p.tit` / `div.desc` 페어 7개.

## 함정

- ⚠ **`/ko/recruit/intro` 한 URL이 5개 탭을 다 담는다.** 문서 전체를 긁으면 인재상·인재육성 문구까지 복지로 섞여 들어온다 → 반드시 `<!-- 복리후생 -->` 주석 블록으로 먼저 자른 뒤 항목을 뽑을 것.
- ⚠ **lsholdings.com 은 LS그룹 공통이고 "계열사별 차이 있음"을 자기 페이지에 써 뒀다.** 여기서 항목을 가져오면 우리가 회사 귀속을 허위로 만드는 셈. 정본은 ls-electric.com 하나로 고정.
- ⚠ 사람인/캐치/인크루트에 뜨는 항목(통근버스, 구내식당 등)은 **공식 페이지에 없다.** 3자 취업포털 = 출처 규칙 위반이므로 채우지 말 것. 공식 7개로만 간다.
- 항목 설명이 모두 서술문이라 정량 수치(금액·일수)는 거의 없음 — 본문 분량 기여는 중간 수준.
