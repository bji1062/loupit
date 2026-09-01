# LG CNS — 복지 수집 가능성 실사 프로브

- 회사: LG CNS (IT서비스, KOSPI 상장 2026-02)
- 프로브 일자: 2026-09-01
- **판정: 수집 가능 (GO)** — 공식 도메인 · 정적 SSR · robots 허용 · 항목 32개 명시

> 본 문서는 **판정만** 담는다. 수집·SQL 작성은 하지 않았다.

---

## ① 공식 URL

| 구분 | URL | 상태 |
|---|---|---|
| **복지 정본** | `https://www.lgcns.com/kr/careers/benefits` | HTTP 200 · 131,936 bytes · SSR |
| 채용 소개 | `https://www.lgcns.com/kr/careers/who-we-are` | HTTP 200 · 111,385 bytes |
| 사이트맵(KR) | `https://www.lgcns.com/content/lgcns.sitemap.kr-sitemap.xml` | 200 · 113 loc (benefits 포함) |

- 도메인 `www.lgcns.com` = LG CNS 자사 공식 도메인. 제3자(잡코리아/블라인드 등) 아님.
- ⚠ 구 URL `https://www.lgcns.com/careers/life/` (검색결과에 아직 노출)는 **301 → `/kr/careers/life` → 404**. 죽은 경로다. 반드시 `/kr/careers/benefits` 를 쓸 것.
- ⚠ `careers.lg.com`(LG 그룹 공동 채용 포털)은 **쓰지 마라** — 아래 ③ 참조.

## ② 복지 항목 명시 여부 — **명시됨. 9개 대분류 · 32개 항목 (각 항목마다 한 줄 설명 동반)**

| 대분류 | 항목 수 | 항목 |
|---|---|---|
| 가족 Care | 5 | 사내 어린이집 / 5월 Family Day / 자녀 대상 선물 지원 / 자녀 학자금 지원 / 가족 경조사 지원 |
| 건강 Care | 5 | 종합건강검진 / 단체상해보험 / 사내 피트니스 센터 / 사내 심리상담소 및 헬스테라피 / 중대 의료비 |
| 리프레시 | 3 | 안식휴가 / 프리미엄 콘도 지원 / 주중 임직원 골프 지원 |
| 생활 지원 | 6 | 과학기술인공제회 / 학자금 이자 지원 / 복지포인트 / LG전자 가전 할인 / 무료 전기차 대여 / 출퇴근 통근버스 운행 |
| 프로젝트 Care | 2 | 프로젝트 현장 케어 / 팀 빌딩 프로그램 |
| 즐거운 직장 | 3 | 사내 동아리 / 프로 스포츠 관람 지원 / 디지털 코딩농활 |
| 공간 | 3 | 공유오피스 제공 / 자율책임근무제 / 사내 카페 행복마루 |
| 기념 선물 | 3 | 결혼·임신 축하 선물 / 명절 기념 복지 포인트 / 호칭 변경 기념 선물 |
| 성장 지원 | 2 | 자격증 취득 지원 / 전자도서관 |

**예시 2건 (원문 그대로, 설명 포함)**
1. **사내 어린이집** — "사내 어린이집 운영(마곡/여의도/상암)"
2. **출퇴근 통근버스 운행** — "약 220여개의 통근버스 노선 운행"

(추가 참고: "프리미엄 콘도 지원 — 아난티·파라스파라(안토)·리솜·롯데·메리어트 및 곤지암 리조트 지원", "안식휴가 — 일정 근속 기준연한에 따라 유급휴가 및 휴가비 지급" 등 구체 수치·브랜드까지 기재되어 있어 본문 밀도가 높다.)

## ③ robots

**`https://www.lgcns.com/robots.txt` (전문)**
```
User-agent: *
Disallow: /bin/
Disallow: /content/lgcns/
Disallow: /language-masters
Disallow: /content/dam
Sitemap: https://www.lgcns.com/sitemap.xml
```
- `/kr/careers/benefits` 는 **어떤 Disallow 규칙에도 걸리지 않는다 → 허용**.
- AI 크롤러 개별 차단(GPTBot/ClaudeBot/CCBot 등) **없음**. Content-Signal 지시자 **없음**.

**⚠ 대조: `careers.lg.com/robots.txt` 는 다르다 (Cloudflare Managed)**
```
User-agent: *
Content-Signal: search=yes,ai-train=no,use=reference
Allow: /
User-agent: ClaudeBot   → Disallow: /
User-agent: GPTBot / CCBot / Google-Extended / Bytespider / Amazonbot / ... → Disallow: /
```
→ LG 그룹 포털은 **ClaudeBot 명시 차단 + ai-train=no**. 게다가 Vite/React **SPA 셸**(`<div id="root">`)이라 정적으로 본문이 안 나온다. 이 도메인은 수집 대상에서 **제외**한다. lgcns.com 만 쓴다.

## ④ 접근성

| 항목 | 결과 |
|---|---|
| 렌더링 | **정적 SSR (Adobe AEM)** — JS 없이 본문 전량 HTML 에 포함. 헤드리스 브라우저 불필요 |
| HTTP | 200, 131,936 bytes |
| UA 민감도 | **없음** — Chrome UA / curl 기본 UA / `python-requests/2.31.0` 모두 **200 · 동일 바이트 수** |
| 차단·캡차·쿠키월 | 없음 (쿠키 배너는 있으나 본문 렌더에 영향 없음) |
| 지역 제한 | 없음 |

**파싱 함정 (수집 시 주의)**
1. AEM `data-cmp-*` 속성 안에 **JSON 이스케이프된 richtext 사본**이 들어 있어(`...</p>\r\n"}}"`) 순진하게 태그를 벗기면 **같은 문구가 두 번** 잡히고 `"}}"` 같은 찌꺼기가 섞인다. `.cmp-richtext` 요소의 **텍스트 노드만** 취하고 속성값은 버려야 한다.
2. 페이지 상단에 **i18n 사전 전체가 JSON 으로 인라인**되어 있다(IR·재무·푸터 문구 수백 건). 복지 항목만 골라내려면 컨테이너 스코프를 좁혀야 한다.
3. 구 경로 `/careers/life/` 로 하드코딩하면 **404**. 소스 URL 은 `/kr/careers/benefits`.

## 결론

- 수집 가능 여부: **GO**
- 근거: 공식 자사 도메인 · robots 허용(AI 봇 개별 차단 없음) · 정적 SSR · UA 무관 200 · 항목 32개 + 항목별 설명 확보
- 다음 단계로 넘길 때 넘겨야 할 것: 소스 URL `https://www.lgcns.com/kr/careers/benefits`, 9개 대분류 구조, 파싱 함정 3종, `careers.lg.com` 사용 금지 사유
