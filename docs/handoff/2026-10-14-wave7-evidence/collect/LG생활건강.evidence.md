**판정: 불가(robots · 벽) — 출처 없음 · 공시만 후보 1행(collect/ 밖)**
- 정본 URL: 없음 — 자기 도메인 `https://www.lghnh.com/` 이 robots `User-agent: *` → `Disallow: /`(검색엔진 8종만 Allow) · 그룹 통합 채용 `careers.lg.com` 은 SPA 셸 + 데이터 전부 POST API
- 항목 수(법정 제외 추정): 자기 도메인 · 그룹 채널 본문 0건 열람 / 공시 문장으로 서는 행 1(`flex_work`)
- 렌더 방식: www.lghnh.com 미요청(robots 금지) · careers.lg.com = Vite SPA(`/assets/index-ChUslKQa.js`), 본문 API `https://api.careers.lg.com/rmk/*` 가 전부 `Me.post(...)` — GET 으로 받을 수 있는 데이터 없음 · 헤드리스 렌더 안 함(렌더도 POST 를 부른다)

붙여넣기 필요: `https://www.lghnh.com/` 의 인재채용 · 복리후생 메뉴 페이지(robots 금지로 하위 정확한 주소를 열람 · 확인하지 못함 — 사람이 홈 헤더 메뉴에서 연 주소를 함께 받아야 한다) · 보조 후보 `https://careers.lg.com/channel/detail/lghh`(그룹 채용 사이트의 LG생활건강 채널 — 복리후생 블록이 있는지 미확인)

- 점검: collect/ SQL 없음(판정 불가). 후보 파일 `/home/ubuntu/loupit-evidence/2026-10-14-wave7/lg_hnh/LG생활건강.candidate-1row.sql` 에 대해 ① 분할기 `5` · ② 길이 `0 violations` · ③ 법정 낱말 검출 2(SORT 10 이름 · 서술 「시차출퇴근」 — 확인 어휘 · 법정 아님 → 허용) · ④ 행 점검 `총 오류 0 — 통과`(리포 · `--corpus` 대기 폴더 둘 다) · ⑤ `10 flex_work h 0f77b7d2f5 mode start facets []`(원문 뜻대로 — 시차출퇴근) · ⑥ 미실측(정본이 상시 복지 페이지가 아니라 DART 뷰어 — 등록 시 리드가 정본을 정한다)
- 요청 수: 판정 7 / 수집 0 (`/home/ubuntu/loupit-evidence/2026-10-14-wave7/lg_hnh/req.log` — robots 3 · 그룹 번들 1 · OpenDART 3). 그 밖 DNS 조회만(HTTP 요청 아님) · 웹 검색 2회(출처 아님 — 정본 주소 탐색용, 회사 호스트 요청 0)
- UA: 일반 브라우저 UA(0-7 기본). 사이트 JS 에 박힌 키 · 토큰 사용 없음
- 그룹 · 형제 점검: 기등록 LG 형제 7사(LG CNS · LG디스플레이 · LG에너지솔루션 · LG유플러스 · LG이노텍 · LG전자 · LG화학 — 리포 시드 · 대기 폴더 동일) 전부 **자기 도메인 정본**이고 머리말에 careers.lg.com 을 근거로 쓰지 않았다고 적혀 있다. 이번엔 LG생활건강 원문 문장을 하나도 받지 못해 글자 대조할 문장이 없다. 그룹 번들에 「복지 · 복리 · welfare · benefit」 문자열 0건 — 템플릿 문장도 없음
- 공고 근거 0행 / 전체 0행(collect) · 후보 파일 1행
- DART: 설립 · 공시 이력 정상(사업 · 반기 · 분기보고서 2025~2026 7건 확인) — 이력 짧음 해당 없음
- 위험 표시 없음(collect 행 0). 후보 파일 1행은 공시 표 단독 근거

## 1. 출처 표

| 호스트 · URL | robots 판정 | 받은 것 · 날(UTC) | sha256 | 사본 경로 | 결론 |
|---|---|---|---|---|---|
| `https://www.lghnh.com/robots.txt` | 200 · 444B · BOM 없음 · 9 레코드(Googlebot · Bingbot · Slurp · DuckDuckBot · Yeti · Daumoa · ZumBot · NateCrawler = `Allow: /`, `*` = `Disallow: /`) → `*` · ClaudeBot · anthropic-ai · GPTBot · CCBot · Google-Extended 모두 **금지**(RFC 9309 가장 긴 일치 · `_work/robots.py`) | 2026-10-14 | `0c8ba8ff…4cf2` | `lg_hnh/robots_www.lghnh.com.txt` | 본문 미요청(채용 · 복리후생 · 지속가능경영보고서 PDF · 보도자료 모두 이 호스트) |
| `https://lghnh.com/robots.txt`(apex) | 403 · 20B 「403 Forbidden Error.」 | 2026-10-14 | `d2f73448…121b` | `lg_hnh/robots_lghnh.com.txt` | apex 는 403 — www 금지를 apex 로 돌아가지 않는다(우회 금지) · 본문 미요청 |
| `*.lghnh.com` 서브도메인(recruit · careers · esg · company · sustainability · ir · en · static · img · image · cdn · file · files · m · news · newsroom) | — | DNS 조회만 | — | — | 전부 NXDOMAIN — 다른 자기 도메인 호스트 없음 |
| `https://careers.lg.com/robots.txt` | 200 · 929B 인데 본문이 SPA 셸 HTML(soft-404) = robots 파일 없음 = 허용 | 2026-10-14 | `58c079ed…bdf72` | `lg_hnh/robots_careers.lg.com.txt` | 허용 |
| `https://careers.lg.com/assets/index-ChUslKQa.js` | 허용 | 2026-10-14 · 2,258,126B | `cbfde06a…16f7` | `lg_hnh/careers_index.js` | baseURL `https://api.careers.lg.com/rmk` · 회사 채널 `/channel/detail/:id`(LG생활건강 = `lghh`) · 채널 데이터 `/channel/retrieveChannelCompanyInfo` · `/main/retrieveCompanyContents` 등 **모두 POST** → 받지 않음(0-2). 번들 자체에 복지 문자열 0 |
| OpenDART `list.json`(corp_code 00356370 · 정기공시) | — | 2026-10-14 | `8fe8bb7c…5e0` | `lg_hnh/dart_list.json` | 최신 = 반기보고서 (2026.06) 접수 20260814002412 |
| OpenDART `document.xml` 20260814002412 반기보고서 (2026.06) | — | 2026-10-14 · zip 388,489B | `1ae658af…a729`(zip) · 텍스트 `bac3f72a…1c87` | `lg_hnh/dart_20260814002412/` · 텍스트 `lg_hnh/dart_h1_2026.txt` | 후보 1행 근거 |
| OpenDART `document.xml` 20260316000985 사업보고서 (2025.12) | — | 2026-10-14 · zip 644,446B | `b35c8bbd…dfdadf1`(zip) · 텍스트 `0347bea8…b7` | `lg_hnh/dart_20260316000985/` · 텍스트 `lg_hnh/dart_ar_2025.txt` | 같은 표의 전기 값 대조 |

정본 · 점검기: 상시 복지 페이지 없음 → ⑥ 미실측. 지주 (주)LG 보도자료(`lg.co.kr/media/release/…` — 웹 검색 결과)는 다른 법인 발행이라 출처 아님(1-4 · 1-6).

## 2. 행별 인용표 (후보 파일 · collect 아님)

| SORT | 코드 | 이름 | 원문 그대로 · 사본 경로:줄 | 출처 표기 | 칩 |
|---|---|---|---|---|---|
| 10 | `flex_work` | 시차출퇴근제 | 「(3) 공시대상기간 중 직원의 유연근무제 활용 여부와 사용 현황」 · 「유연근무제활용 여부 \| 일부 활용 중 \| 일부 활용 중 \| 일부 활용 중」 · 「시차출퇴근제사용자 수 \| 2,499 \| 2,481 \| 2,567」 — `lg_hnh/dart_h1_2026.txt:24933-24946`(전기 같은 표 `dart_ar_2025.txt:30756-30770`: 2,481 · 2,567 · 2,526) | 2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목 | 맨 칩 |

## 3. 코드 판단

시차출퇴근제 = `flex_work`(경계: 시차출퇴근 = flex_work · 법정 아님 · 공시 표의 제도 이름은 그 자체로 행). 신규 코드 없음.

## 4. 법정 제도

- 반기보고서 「(2) 육아지원제도 사용 현황」(육아휴직 · 육아기 근로시간 단축 · 배우자 출산휴가 사용자 수 — `dart_h1_2026.txt:24881~`)은 법정 제도 사용 통계라 행 없음.
- 퇴직급여: 「확정급여형 퇴직연금제도」(`dart_ar_2025.txt:4537`) = 법정 — 행 없음.
- 직원 수 3,987명(2026.06.30 합계 — `dart_h1_2026.txt` 직원 등 현황 합 계 줄) — 재취업지원 법정 대상 규모(1,000인 이상). 다만 재취업 지원 문장을 찾지 못해 판정할 행 없음.
- 🚨 11-27 재계산 대상: 난임 휴가 원문 없음 — 해당 없음.

## 5. 금액

금액 행 0. 숫자가 있지만 비운 것: 시차출퇴근제 사용자 2,499명(통계 — 금액 아님). 공시 「기타 복리후생 규정에 의거 … 지급」(`dart_h1_2026.txt:25613` 등)은 임원 개인 보수 산정 칸 — 직원 근거 아님 · 금액 쓰지 않음(§3-5).

## 6. 제외 목록

| 원문 | 이유 |
|---|---|
| 원격근무제(재택근무 포함) 사용자 수 「- \| - \| -」(`dart_h1_2026.txt:24951-24954`) · 선택근무제 사용자 수 「-」 | 지표 표의 이름 칸 · 사용 0(§3-12) |
| 「우리사주조합 \| - \| - \| -」(`dart_h1_2026.txt:23913`) | 주주 표 한 칸만 · 보유 0(§3-7) |
| 「기타장기종업원급여부채」(재무제표 계정 줄만) | 「장기 근속 임직원에게 …」 같은 제도 문장이 없음 — 계정 이름만으로 세우지 않음 |
| 임원 「성과인센티브 규정」 · 「기타 복리후생 규정」(보수 산정 칸) | 임원 전용(§3-5) |
| (주)LG 보도자료 「복지몰 · 스포츠관람 · 독서통신 · 사이버교육 · 자녀 여름캠프」(웹 검색 스니펫 · 2019년 · 지주 도메인) | 검색 스니펫 · 다른 법인 발행 · 옛 출처 — 인용 0 |

## 7. 낱말 스윕 · 항목 페이지

③ 검출 2(SORT 10 이름 · 서술 「시차출퇴근」) → 허용(확인 어휘 · 법정 아님). ⑤ `mode start` — 원문 뜻대로, 예외 후보 없음.

## 8. 판단 요청

1. **등록 경로** — 기본안: 지금은 등록하지 않는다(공시 1행으로는 회사 페이지가 사실상 비어 「없음」 축이 대부분이 된다). 리드가 사용자 붙여넣기(www.lghnh.com 복리후생 페이지 또는 careers.lg.com/channel/detail/lghh)를 받으면 그 사본으로 재투입하고, 후보 1행(`flex_work`)은 그때 함께 싣는다(붙여넣기 쪽에 같은 제도가 있으면 그 문장 + 반기보고서 괄호).
2. **robots 정본 경고** — 붙여넣기로 등록하면 정본이 robots 금지 호스트라 점검기 `robots`(점검 안 함). 기본안: 그대로 받아들이고 배포 시 주의에 남긴다.

## 9. 이메일 도메인 관측

`@lghnh.com` — careers.lg.com 번들의 계열사 개인정보 문의처 표 「LG생활건강 … 정보보안센터 · 문의처 : …@lghnh.com」(부서 공용 메일함 · 개인 아님). 법인 자기 도메인과 같다. MX 미확인.

## 10. 배포 시 주의

- 등록 시 정본 후보가 모두 robots 금지(www.lghnh.com `Disallow: /` for `*`) 또는 POST SPA(careers.lg.com) — 점검기는 `robots` 이거나 셸만 읽는다.
- 후보 파일 머리말 URL 은 DART 뷰어(임시) — 등록 때 리드가 정본을 바꾼다.

## 11. 확인하지 못한 것

- www.lghnh.com 의 인재채용 · 복리후생 · 지속가능경영보고서 · 보도자료 본문 전부(robots 금지 — 요청 0).
- careers.lg.com LG생활건강 채널(`/channel/detail/lghh`)의 실제 내용 — POST API 뿐이라 받지 않음. 복리후생 블록이 있는지 모른다.
- LG생활건강 채용 공고(careers.lg.com `/job/retrieveJobNoticesDetail` POST).
