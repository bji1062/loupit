# JYP Ent. 복지 수집 근거 (2026-09-20)

- 대상: **JYP Ent.** / JYP Entertainment Corporation (KOSDAQ 035900) · slug `jyp` · `mid` · INDUSTRY_NM `엔터테인먼트` · LOGO_NM `J`
- 산출물: `wave4/JYP.sql` — **20행**, 전부 `BADGE_CD='est'` · `BENEFIT_AMT` 전건 NULL · `QUAL_YN` 전건 TRUE
- 계약: `docs/handoff/2026-09-19-evidence/_COLLECT-CONTRACT.md` (웨이브 4 추가 규칙 포함) · 어휘표 `_VOCAB.md` 87종
- 수집 세션 HTTP 요청 **7회**(한도 60) · 전 구간 일반 브라우저 UA · 요청 간 ≥1.2초 · HEAD 미사용 · 헤드리스 렌더 미사용
- 내려받은 원본: `…/scratchpad/wave4/jyp/` (아래 해시표)

---

## 1. 출처 (공식 1차 출처만)

### 채택

| # | URL | 상태 | 크기 | sha256 (전체) | 용도 |
|---|---|---|---|---|---|
| 1 | `https://recruit.jype.com/robots.txt` | 200 · text/plain | 86 B | `340ba929bcfa00e58bbe0444ba70ea770e515de788ff16ee6a4c464ca248458b` | 경로 허용 판정 |
| 2 | **`https://recruit.jype.com/ko/benefits`** | 200 · `etag: "kuq0ny89qj1gvt"` · `x-nextjs-prerender: 1` | 72,865 B | `9114c24cf2b6e8726088b2586df7889f2161644146c0686e107359141eb50301` | **정본 — 20행 전부의 근거** |
| 3 | `https://www.jype.com/robots.txt` | 200 | 127 B | `a2ba557ec0782c3ee3b1c29e971c79b89d9e51ea7e0d6dfb1a5d8ffd5eb9a62f` | 경로 허용 판정 |
| 4 | `https://www.jype.com/` | 200 | 180,459 B | `2a3b85aa51ea04d8b5b6dc058bed586dec15ceda6cf478a34608898850b0190b` | 귀속 경로(푸터 FAMILY → JYP RECRUIT)·이메일 탐색 |
| 5 | `https://privacy.jype.com/robots.txt` | **404 · 9 B** | 9 B | `0019dfc4b32d63c1392aa264aed2253c1e0c2fb09216f8e2cc269bbfb8bb49b5` | 규칙 파일 없음 → RFC 9309 unavailable = 전면 허용 |
| 6 | `https://privacy.jype.com/recruit` | 200 | 331,064 B | `8a7773cecb9cc33dd769dc5ed3660e4e2d3993c9d0037e14976df7aeaca32181` | **이메일 도메인 관측(규칙 7) 전용** — 복지 행 근거 0건 |
| 7 | `https://recruit.jype.com/ko/faqs` | 200 | 120,112 B | `703dfffec2c1742d7f4d60fd88469aa9ac751550e7ed27413b358cc0a206ede9` | 문의처·이메일 탐색(결과 0건). 복지 행 근거 0건 |

프로브(별도 세션)가 기록한 정본 크기 72,865 B·etag `"kuq0ny89qj1gvt"` 와 **이번 재수집 바이트가 완전히 같다** — 2026-09-20 시점 페이지 변경 없음.

### robots 판정 (계약 예절 — 호스트마다 단독 선행)

| 호스트 | 레코드 | 해당 경로 |
|---|---|---|
| `recruit.jype.com` | `User-Agent: *` → `Allow: /` + `Disallow: /api/`, `Sitemap:` 1줄. 레코드 1개 | `/ko/benefits` **허용**, `/ko/faqs` 허용 |
| `www.jype.com` | `User-Agent: *` → `Allow: /` + `Disallow: /api/` + `Disallow: /_next/`. `Host:`·`Sitemap:` | `/` **허용** |
| `privacy.jype.com` | robots.txt **404** | 규칙 없음 → **허용** |

- 세 호스트 모두 `ClaudeBot`·`anthropic-ai`·`GPTBot`·`CCBot`·`Google-Extended` 를 이름으로 건 레코드가 없다 → `*` 레코드를 따른다.
- ⚠ **`/api/` 가 금지**다. 공고·복지를 JSON API 로 긁으면 안 된다 — 이 파일은 HTML 만 썼다.
- `jype.com` apex 의 robots 는 301 로 `www` 에 넘어간다. apex 를 단독 호스트로 보고 「규칙 없음」 처리하면 안 된다.

### 귀속 판단 (계약 규칙 6) — 그룹 각주를 달지 않은 이유

1. **자기 도메인이다.** `recruit.jype.com` 은 상장 법인 도메인 `jype.com` 의 서브도메인이고 3자 ATS 도 그룹 공통 포털도 아니다.
2. **TLS 주체가 법인이다.** `www` 와 `recruit` 가 같은 OV 인증서 — `O = JYP Entertainment Corporation, C = KR, ST = Seoul, L = Gangdong-gu`, `CN = JYP-ISE.jype.com`, SAN `jype.com`·`*.jype.com`.
3. **푸터 주어가 법인이다.** 정본 페이지 푸터 원문: `© JYP ENTERTAINMENT Corp. All rights reserved.` (재수집 HTML 에서 직접 확인).
4. **내용이 본사 전용이다.** `JYP BOB`(사내 식당)·`소속 아티스트의 콘서트 초대권`.
5. **자회사 혼입 차단.** 같은 채용 사이트가 자회사 `Blue Garage` 공고 10건을 싣지만 ① 이 파일의 근거는 `/benefits` 한 페이지뿐이고 ② 공고 본문에는 복리후생 섹션이 아예 없으며 ③ `bluegarage.co` 의 복지 목록 4개는 **한 글자도 쓰지 않았다**(별도 법인 · 사업자등록번호 327-87-02151).
6. **각주를 안 단 근거.** `/benefits` 에 적용 범위·계열사별 상이 면책 문구가 **한 줄도 없고**, 형제 법인(Blue Garage·INNIT)은 비상장이라 코퍼스에 형제로 등록될 일이 없다(더존비즈온 선례와 같은 구조). 넷마블식 「컴퍼니 공통」 각주도, 그룹 템플릿 각주도 성립하지 않는다.

### 렌더 방식 · 수집 방법

- Next.js App Router **SSR 프리렌더**(`x-nextjs-prerender: 1`, `x-nextjs-cache: HIT`). `curl` + HTML 파서로 충분해 **헤드리스 렌더를 쓰지 않았다**(계약 예절 준수 — 렌더가 끌어오는 하위 리소스가 금지 경로 `/api/` 를 건드릴 위험도 함께 회피).
- 셀렉터: `section[id^=benefits-]`(4개: `benefits-work-section`·`refresh`·`life`·`family`) > `li` > `h3`(항목명) + `p`(설명) → **12항목이 정확히 떨어진다.**
- **유령 항목 교차 확인**: `self.__next_f` 플라이트 페이로드 10조각을 디코드(22,478자)해 한글 문자열을 전수로 뽑았다. 복지 문자열은 위 12항목과 **정확히 일치**하고 가시 텍스트에 없는 항목은 0건이다(나머지는 인재상·전형절차·빈 목록 안내문). 캐러셀 중복·주석 속 죽은 블록 없음.

### 공식 이메일 도메인 관측 (계약 규칙 7)

- **관측 도메인: `jype.com`** — 채용 개인정보처리방침(`privacy.jype.com/recruit`)에서 `recruit@jype.com` · `privacy@jype.com` · `privacy_help@jype.com` · `ann@jype.com` · `hikim@jype.com` · `recruit_bg@jype.com` 관측.
- MX 실측: `jype.com` → `10 SMTP.GOOGLE.com.` (Google Workspace). **웹 도메인과 메일 도메인이 같다** — 이수페타시스형 불일치 아님.
- ⚠ 같은 문서에 `innit@innitent.com`·`recruit@innitent.com` 이 함께 있으나 **INNIT Entertainment(별개 법인) 도메인**이다. 재직인증 화이트리스트에 넣으면 안 된다.
- 정본 `/benefits` 와 `/ko/faqs` 에는 이메일 주소가 **0건**이다.

### 갱신 감지

- `/ko/benefits` 의 `etag: "kuq0ny89qj1gvt"` 또는 12항목 텍스트 해시로 감지.
- ⚠ 인증서 만료 **2026-12-22**(채용 도메인 공용). 연말 재수집 때 TLS 실패를 봇 차단으로 오판하지 말 것.

---

## 2. 행별 인용표 (20행 — 행마다 원문 문장)

원문은 전부 `https://recruit.jype.com/ko/benefits` 의 `h3`(항목명) / `p`(설명)다. 「원문」 칸은 **그대로 옮긴 문장**이다.

| SORT | BENEFIT_CD | 카테고리 | 원문 항목명 (`h3`) | 원문 문장 (`p`) |
|---:|---|---|---|---|
| 10 | `meal` | perks | JYP BOB | 구성원에게 체계적인 유기농 식단의 중식과 석식을 무료로 제공하며, 건강과 환경에 이로운 사내 문화를 조성합니다. |
| 11 | `welfare_point` | perks | 복지 포인트 | 문화 · 도서구입 · 생일 등 다양한 용도의 복지포인트를 지급하며, 사내 카페 이용 포인트를 제공합니다. |
| 12 | `snack_bar` | perks | 복지 포인트 | (같은 문장) …사내 카페 이용 포인트를 제공합니다. |
| 20 | `flex_work` | flexibility | 유연 근무제 | 선택적 근로제도, 주 1회 재택근무, 자율좌석제를 운영하여 개별 구성원의 다양한 업무 니즈를 존중하고 업무 효율성 향상에 기여합니다. |
| 21 | `remote_work` | flexibility | 유연 근무제 | (같은 문장) …주 1회 재택근무… |
| 30 | `free_seating` | work_env | 유연 근무제 | (같은 문장) …자율좌석제를 운영하여… |
| 40 | `leisure_ticket` | leisure | 문화 활동 | 소속 아티스트의 콘서트 초대권을 제공하여, 함께 즐기고 교류하는 특별한 문화 경험의 기회를 제공합니다. |
| 41 | `summer_vacation_subsidy` | leisure | 리프레시 제도 | (같은 문장) …하계 휴가비를 지원해 휴식과 재충전을 돕습니다. |
| 42 | `club` | leisure | 동호회 활동 | 동호회 활동을 통해 구성원 간의 이해와 소통을 확대하고, 존중과 배려를 바탕으로 한 건강한 문화를 실현해 나갑니다. |
| 43 | `resort` | leisure | 휴양 시설 | 임직원이 편안한 여가와 휴식을 누릴 수 있도록 전국 제휴 휴양 시설 할인 혜택을 제공합니다. |
| 50 | `long_service_leave` | time_off | 리프레시 제도 | 3·6·10·15·20년 근속 시 15일 유급휴가와 장기근속 포상 및 표창을 제공하며, 하계 휴가비를 지원해 휴식과 재충전을 돕습니다. |
| 51 | `leave_general` | time_off | 경조사 지원 | (같은 문장) …반려동물 경조 휴가 등을 제공하며… |
| 60 | `long_service_bonus` | compensation | 리프레시 제도 | (같은 문장) …장기근속 포상 및 표창을 제공하며… |
| 70 | `health_check` | health | 건강관리 | 매년 건강검진 및 건강검진 휴가를 제공합니다. 단체 상해보험 가입, 독감 예방접종, 멘탈케어 프로그램 지원, 금연 성공 축하금 지급 등 구성원의 건강을 최우선으로 생각합니다. |
| 71 | `insurance` | health | 건강관리 | (같은 문장) …단체 상해보험 가입… |
| 72 | `smoking_cessation` | health | 건강관리 | (같은 문장) …금연 성공 축하금 지급… |
| 73 | `mental` | health | 건강관리 | (같은 문장) …멘탈케어 프로그램 지원… |
| 80 | `self_development` | growth | 자기 계발 교육비 | 구성원의 지속적인 역량 개발을 위해 직무, 어학, OA 등 다양한 자기 계발 교육 비용을 지원하며, 입사자 · 리더십 · 세미나 등의 다양한 교육을 제공합니다. |
| 90 | `event` | family | 경조사 지원 | 경조사비, 경조 휴가, 화환/조화, 상조 서비스 지원, 반려동물 경조 휴가 등을 제공하며 구성원 삶 전반에 걸친 다양한 순간을 든든히 지원합니다. |
| 91 | `child_edu` | family | 자녀 학습 지원금 | 유치원부터 고등학생 자녀까지 자녀의 교육비 부담 완화를 위한 학습 지원금을 제공합니다. |

### 항목 ↔ 행 수지

| 원문 항목 (12) | → 행 | 비고 |
|---|---:|---|
| JYP BOB | 1 | `meal` |
| 유연 근무제 | 3 | `flex_work`(선택적 근로제도) + `remote_work`(주 1회 재택) + `free_seating`(자율좌석제) — **세 제도가 원문에 이름으로 나열된다. 중복 계상이 아니다** |
| 무사고 안전 운전 수당 | **0** | 제외(§6) |
| 문화 활동 | 1 | `leisure_ticket` |
| 리프레시 제도 | 3 | `long_service_leave`(근속 15일 유급휴가) + `long_service_bonus`(포상·표창) + `summer_vacation_subsidy`(하계 휴가비) |
| 복지 포인트 | 2 | `welfare_point` + `snack_bar`(사내 카페 이용 포인트) |
| 동호회 활동 | 1 | `club` |
| 건강관리 | 4 | `health_check`(검진+검진 휴가+독감 예방접종) + `insurance` + `mental` + `smoking_cessation` |
| 자기 계발 교육비 | 1 | `self_development` — 교육 비용 지원분만. 교육 제공분은 제외(§6) |
| 경조사 지원 | 2 | `event`(경조사비·경조 휴가·화환/조화·상조) + `leave_general`(반려동물 경조 휴가) |
| 자녀 학습 지원금 | 1 | `child_edu` |
| 휴양 시설 | 1 | `resort` |
| **합계** | **20** | 계약 목표 12~25 안 |

SORT 섹션 순서 = 원문 페이지에서 그 카테고리가 처음 나온 순서: perks 10 · flexibility 20 · work_env 30 · leisure 40 · time_off 50 · compensation 60 · health 70 · growth 80 · family 90.

---

## 3. 코드 매핑 판단 · 어휘 함정 회피

### 신규 코드 — **1개**

**`smoking_cessation` (health) · 「금연 성공 축하금」**

- 원문: 「… 금연 성공 축하금 지급 …」 — 혜택 내용(금연 성공 시 축하금 지급)을 원문이 스스로 밝힌다(계약 규칙 5 조건 충족).
- 어휘표 87종에 대응 코드가 없다. 검토하고 버린 후보 — `medical`(의료비 지원: 축하금은 의료비가 아니다) · `mental`(심리상담: 이미 멘탈케어가 차지) · `health_check`(검진) · `excellence_award`(우수사원 포상: 성과 포상이다) · `clinic`(사내 의원·건강관리실: JYP 는 시설 서술이 없다).
- ⚠ **코퍼스 선례는 「병기」쪽이다.** 테크윙은 `clinic` 행에 「건강관리실 운영(정규직 간호사), 금연수당 지원」으로, 엠씨넥스는 금연펀드를 `clinic` 에 병기했다. 다만 두 회사 모두 **금연을 얹을 `clinic` 행이 있었고** JYP 에는 없다. `health_check` 에 얹으면 검진·예방접종·금연 축하금이 한 행에 뭉개진다.
- **감사가 신규 코드를 원치 않으면 대안은 하나다** — SORT 72 행을 지우고 SORT 70 `health_check` 의 서술 끝에 「금연 성공 축하금 지급」을 붙이면 19행이 된다. 행 내용은 보존되고 코드만 사라진다.

### 어휘 함정 회피 (계약 규칙 5 · 8-2 · 웨이브 3·4 추가)

| 함정 | 이 파일의 처리 |
|---|---|
| `refresh_leave` vs `long_service_leave` | 원문 항목명이 **「리프레시 제도」**지만 내용은 「3·6·10·15·20년 **근속 시**」다. 웨이브 3 확정 규칙대로 근속 연동 휴가는 `long_service_leave`. **`refresh_leave` 를 쓰지 않았다** — 이름에 낚이면 「조건 없는 추가 휴가」로 오분류된다 |
| `long_service_leave` vs `long_service_bonus` | 휴가(15일 유급휴가)와 포상금·표창을 **각각 다른 코드**로 나눴다 |
| `summer_leave` vs `summer_vacation_subsidy` | 원문은 「하계 **휴가비**」 — 휴가 자체가 아니라 돈이다. `summer_leave`(time_off)가 아니라 `summer_vacation_subsidy`(leisure, 심텍 선례) |
| `welfare_point` 범위 | 포인트·복지몰 한정. 사내 카페 이용 포인트는 카페 이용 지원이라 `snack_bar` 로 분리 |
| `self_development` vs `welfare_point` | 「자기 계발 교육비」는 개인 자기계발비 지원이므로 `self_development`(growth). 복지포인트 칸에 넣지 않았다 |
| `self_development` vs `lang`·`edu_support` | 원문은 「직무, 어학, OA 등 … 교육 **비용을 지원**」이라는 **하나의 비용 지원 제도**다. 어학을 `lang` 으로 따로 떼면 한 제도가 두 행이 된다 → 1행으로 두고 서술에 직무·어학·OA 를 명시 |
| `remote_work` / `free_seating` / `flex_work` | 셋 다 어휘표에 있는 기존 코드다(`free_seating` 은 n=1). 원문이 세 제도를 이름으로 나열하므로 각각 1행 |
| `leisure_ticket` vs `sports_ticket`·`culture_day` | 콘서트 초대권은 공연 관람권 → `leisure_ticket`. 스포츠도 아니고 「문화가 있는 날」류 휴무도 아니다 |
| `leave_general` (반려동물 경조 휴가) | 웨이브 3 3분할 규칙의 「사건 보상」에 해당. `event`(family, 경조금)는 이미 SORT 90 이 쓰고 있고 BENEFIT_CD 가 회사당 UNIQUE 라 휴가는 별도 코드가 필요했다. 신규 코드를 만들지 않고 기존 `leave_general` 로 해결 |
| `event` 병합 | 경조사비 + 화환/조화 + 상조 서비스 = 같은 코드로 귀결 → 1행에 담고 서술에 셋 다 적었다(넷마블 상조 물품 → `event` 선례와 같다) |
| `child_edu` vs `parenting` | 유치원~고등학생 자녀 **학습 지원금**은 자녀 교육비 → `child_edu`. 입학축하금이 아니므로 `parenting` 흡수 대상이 아니다 |
| `meal` AMT | 끼니(중식·석식)는 밝혔지만 단가가 없다 → AMT NULL(웨이브 4 추가 규칙) |
| `snack_bar` vs `lounge` | 원문은 공간 소개가 아니라 **이용 포인트 제공**이다. 휴게 공간 행을 만들지 않았다 |
| 급여성 수당 | 「무사고 안전 운전 수당」은 급여성 수당이라 행이 아니다(§6) |

### 비용 지원 ○ / 회사 주도 교육 커리큘럼 × (계약 규칙 8)

같은 문장이 둘을 함께 담고 있어 **문장 안에서 잘랐다.**

- ○ 수록: 「직무, 어학, OA 등 다양한 자기 계발 교육 **비용을 지원**하며」 → `self_development` 1행.
- × 제외: 「입사자 · 리더십 · 세미나 등의 다양한 **교육을 제공합니다**」 → 회사 주도 교육 커리큘럼이라 행이 아니다. `edu_support` 를 만들지 않았다.
- 규칙 8-1 점검: 학위·해외 파견형 육성(MBA·학술연수·지역전문가·주재원)은 **정본 페이지 전체에 0건**이다. `mba`·`career` 행 없음.

---

## 4. 법정 제도 미수록 확인 (계약 규칙 3)

- 정본 페이지에 4대보험·퇴직급여·주5일·법정 연차·육아휴직·육아기 단축·출산휴가·난임휴가·근로자의 날 문구가 **한 건도 없다**. 따라서 지울 것도 없었다.
- 기계 스윕 실행: `python3 docs/handoff/2026-09-19-evidence/_legal_scan.py wave4/JYP.sql` → **행 20 · 검출 0**(법정 검출어·편집 검출어 양쪽 모두 0). 사용자 노출 3필드에 판단 근거·법조문·행 구조 서술이 남아 있지 않다.

### ⚠ 판단이 갈리는 곳 2건 — 리드 지시와 다르게 처리했다

리드 프롬프트와 프로브는 **「매년 건강검진 · 선택적 근로시간제 · 법정 경조휴가」를 규칙 3 으로 걸러라**고 했다. 셋 모두 검토했고, **셋 다 남겼다.** 근거는 아래와 같다 — 감사가 뒤집을 판단이면 행 단위로 집행 가능하도록 지점을 적어 둔다.

**① 선택적 근로제도 → `flex_work` 로 남김 (SORT 20)**

- 근기법 제52조는 선택적 근로시간제를 **허용**할 뿐 사용자에게 도입을 **강제하지 않는다**(근로자대표와의 서면 합의로 도입하는 선택 제도다). 「법이 시킨 것」이 아니라 「법이 열어 둔 것을 회사가 도입한 것」이다.
- 계약 규칙 3 의 열거 목록에 없다. `generator/data/legal_baseline.json` 의 identify 항목 15개(annual_leave·maternity_leave·spouse_birth_leave·parental_leave·parental_work_reduction·infertility_leave·family_care_leave/absence·menstrual_leave·labor_day·public_holiday·weekly_rest·overtime_premium·social_insurance·severance)에도 없다.
- 어휘표 `flex_work`(n=64)의 **대표 명칭 자체가 「유연근무제 · 자율출퇴근제 · 선택적 근로시간제」**다. 여기서만 빼면 64개사와 비교 축이 어긋난다.
- ⚠ 이 행을 지우면 「유연 근무제」 항목의 `flex_work` 축이 통째로 비고, 남는 것은 `remote_work`·`free_seating` 둘뿐이다.

**② 매년 건강검진 → `health_check` 로 남김 (SORT 70)**

- 산업안전보건법 일반건강진단은 사무직 **2년 1회**가 기준이다. 원문의 「**매년** 건강검진」은 그 주기를 상회하고, 같은 문장의 「**건강검진 휴가**」는 규칙 3 이 허용하는 회사 재량 추가 휴가다.
- 계약 규칙 3 열거 목록·`legal_baseline.json`·`_legal_scan.py` 의 `LEGAL_TERMS` 어디에도 건강검진이 없다.
- 코퍼스 `health_check` 는 **122개사**가 쓰고, 그 서술에 「매년 건강검진 지원」·「매년 1회 종합건강검진 + 검진 휴가」·「본인+배우자(40세~) 종합검진, 검진일 공가」가 이미 라이브로 나가 있다. JYP 만 빼면 122개사와 어긋난다.

**③ 경조 휴가 → `event` 행 서술에 남김 (SORT 90)**

- 근로기준법에 **일반 경조휴가 규정은 없다**(취업규칙·단체협약 사항이다). 법정인 것은 배우자 출산휴가인데 원문에 「배우자 출산」 문구가 없다.
- 심텍 `event` 행이 「경조금·경조휴가 구분 미기재」로 이미 라이브다 — 같은 처리를 따랐다.
- ⚠ 뒤집으려면 SORT 90 서술에서 「경조 휴가·」 6자만 빼면 된다(행은 유지).

---

## 5. 금액 (계약 규칙 4)

- **명시 금액 0건 → 20행 전부 `BENEFIT_AMT NULL` · `QUAL_YN TRUE`.** 신규 회사라 승계할 구본·앵커도 없고 타사 값을 끌어오지 않았다.
- 페이지의 정량 표현 4개는 전부 금액이 아니다:
  - `3·6·10·15·20년 근속 시 15일 유급휴가` — 일수(서술로만)
  - `주 1회 재택근무` — 빈도
  - `중식과 석식을 무료로 제공` — 끼니만, **단가 없음** → 웨이브 4 추가 규칙대로 `meal` AMT NULL
  - `유치원부터 고등학생 자녀까지` — 대상 범위
- 비율·1회성 지급을 금액 칸에 넣지 않았다(현대제철 「본인 100%」 → `100` 사고 재발 방지).
- 보강 가능 출처가 **없다**: 지속가능경영보고서 PDF(39.5 MB · 137쪽)는 폰트 서브셋 ToUnicode CMap 이 어긋나 한글이 아랍·키릴 코드포인트로 깨진다 — **이 세션에서 열지 않았다.** OCR 없이는 금액을 못 읽고, 보고 범위(연결/별도)도 확인 불가라 썼다면 귀속 위험이 더 컸다.

---

## 6. 제외 목록

| 제외 대상 | 원문 | 사유 |
|---|---|---|
| **무사고 안전 운전 수당** (원문 12항목 중 1개, 통째로) | 「안전 운전 장려를 위해 무사고 안전 수당을 지원하며, 책임감 있고 안전한 운전 문화를 위해 노력합니다. **(매니저 대상)**」 | ① **급여성 수당**이다(계약 8-2: 급여성 수당은 복지가 아니다) ② 원문이 **직군을 한정**한다 — 한정을 지우면 허위고(규칙 6), 한정을 살리면 전 직원 제도가 아니다. 프로브도 이 항목이 매니저 직군 전용임을 근무지·직군 실측으로 확인했다 |
| 입사자·리더십·세미나 교육 제공 | 「… 입사자 · 리더십 · 세미나 등의 다양한 교육을 제공합니다.」 | 회사 주도 교육 커리큘럼(규칙 8) |
| 비전·인재상·행동 규범 문구 | 「Leader in Entertainment」·「우리는 … 라는 가치체계를 …」 등 | 제도 근거가 아니다(규칙 2) |
| 배너 이미지 12장 | `/_next/image?url=…{work,refresh,life,family}-section-banner-0N@2x.webp`, `alt="… section banner 0N"` | 전부 장식 배너. **이미지 안에 든 항목 텍스트 0건** |
| `bluegarage.co` 의 복지 4항목 | 사내 식당(JYP BOB) 무료 중/석식 · 유연근무제 및 리프레시 휴가 · 동호회 제도 · 복지 포인트 및 문화/교육 지원비 | **별도 법인**(사업자등록번호 327-87-02151, 대표이사 정민종). 항목이 겹쳐 보이는 것은 시설 공유이지 같은 출처가 아니다 — **한 글자도 쓰지 않았다** |
| 채용 공고 34건 | — | 복리후생 섹션이 **0건**이다(프로브가 2건 실측). 이 세션에서는 공고를 요청조차 하지 않았다 |
| `www.jype.com` 본문 | — | 복리·복지·채용 **0건**. 귀속 경로 확인용으로만 썼다 |
| 지속가능경영보고서 PDF·ESG 팩트북 | — | PDF 한글 텍스트 레이어 파손(§5) · 팩트북은 복리후생 0건. 이 세션에서 열지 않았다 |
| `audition.jype.com` | — | 연습생·오디션 도메인. 임직원 복지와 무관하고 요청하지 않았다 |
| `/api/` 하위 | — | **robots 금지**(§1) |

---

## 7. 배포 시 주의

- `COMP_ENG_NM='jyp'` — 코퍼스 138사와 충돌 없음(실측: `j` 로 시작하는 기존 slug 은 `jlk`·`jusung` 뿐).
- `COMP_NM='JYP Ent.'` — **표시명에 마침표가 들어간다.** `db.seed.load._split_sql_statements` 로 실측한 결과 이 파일은 **정확히 5문장**이다(마침표는 분할에 영향 없음). 문자열·주석에 홑따옴표·겹따옴표 0건.
- `INDUSTRY_NM='엔터테인먼트'` — **기존 값에 합류했다.** 하이브(`hybe`)가 같은 값을 쓴다 → trending 폴백 쌍이 JYP Ent. ↔ 하이브로 묶인다. 새 변형(「엔터」·「가요기획」)을 만들지 않았다. ⚠ 코퍼스에 `미디어/엔터`(CJ ENM 엔터테인먼트부문) 라는 **다른 값**이 따로 있다 — 셋을 합칠지는 감사 몫이고 이 파일은 건드리지 않았다.
- `COMP_TP_CD='mid'` — KOSDAQ 상장 중견. 리드 지시값 그대로.
- `LOGO_NM='J'` — 영문명 이니셜 대문자 1자(코퍼스 관례와 일치).
- 회사 추가 후 **정적 페이지 재생성 필수**.
- `CAREERS_BENEFIT_URL` 은 `/ko/benefits`(로케일 포함)로 넣었다. ⚠ `/benefits` 는 307 로 여기 오지만 **`/en/benefits` 는 `/ko/en/benefits` 라는 엉뚱한 경로로 튄다** — 채용 사이트는 한국어 전용이다. 영문 경로를 넣으면 404 가 된다.

---

## 8. 검증자가 봐야 할 지점

### ① §4 의 판단 3건 — 이 파일에서 가장 다툴 만한 곳

리드가 「걸러라」고 한 **선택적 근로제도(SORT 20)·매년 건강검진(SORT 70)·경조 휴가(SORT 90 서술)** 를 **남겼다.** 근거는 §4 에 전부 적었다(계약 규칙 3 열거 목록 · `legal_baseline.json` identify 15항목 · `_legal_scan.py` 검출어 · 코퍼스 실측 122사/64사). 뒤집는 집행 지점도 §4 에 행 단위로 적어 뒀다. **이 셋을 걸러야 한다는 판단이 서면 행 3개가 아니라 행 2개 + 서술 6자 수정이다.**

### ② 「유연 근무제」 한 항목 → 3행

`flex_work`·`remote_work`·`free_seating`. 원문이 세 제도를 **이름으로 나열**하므로 중복 계상이 아니라고 봤다. 다만 ①에서 `flex_work` 를 걷어내면 남는 두 행의 상위 라벨이 사라진다 — 두 판단은 함께 봐야 한다.

### ③ 신규 코드 `smoking_cessation` 1개

§3 에 후보 5개 기각 사유와 **병기 대안(19행으로 줄이는 방법)** 을 적어 뒀다.

### ④ `snack_bar` (SORT 12)

「사내 카페 이용 포인트」를 `welfare_point` 와 분리한 판단. 원문이 「복지포인트를 지급하며, **사내 카페 이용 포인트를 제공합니다**」로 두 번 말한다. 한 행으로 합치자는 견해도 가능하다.

### ⑤ 행 수 20 · 금액 0건

계약 목표 12~25 안이고, 원 단위 금액이 0건인 것은 프로브 실측과 이번 재수집이 일치한다. **금액 있는 행이 하나도 없는 것이 정상**이다 — 어디선가 금액이 붙어 오면 그건 타사 값이다.

### ⑥ 재현 방법

```
curl -sS --max-time 20 -A 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0 Safari/537.36' https://recruit.jype.com/ko/benefits
```
→ 72,865 B · sha256 `9114c24c…50301`. `section[id^=benefits-] > li > h3/p` 로 12항목이 떨어진다. **헤드리스 불필요 · `/api/` 금지.**
