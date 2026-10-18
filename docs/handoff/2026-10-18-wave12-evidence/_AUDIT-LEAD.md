# 웨이브 12(후보 풀 3차 첫 웨이브) — 감사 · 통합 · 등록 리드 칸 (2026-10-18)

본문 = `/home/ubuntu/loupit-evidence/wave-lite/_AUDIT-INTEGRATE-REGISTER.md`(고정). 이 파일은 그 계약 「리드가 채우는 칸」의 웨이브 12 값이다. **SendFeedback 도구 금지 · 하위 에이전트 금지.** OpenDART 키 문자열을 로그 · 보고서 · 도구 출력 어디에도 찍지 않는다(요청 URL 을 출력할 때 crtfc_key 값을 지운다).

| 칸 | 값 |
|---|---|
| `W` = 웨이브 폴더 · 웨이브 번호 `N` | `/home/ubuntu/loupit-evidence/2026-10-18-wave12` · `N = 12` |
| 대상 시드 · `K` · 함께 묶는 대기 웨이브 | `W/collect/*.sql` **18파일**(하나투어 · SM엔터테인먼트 · 웅진씽크빅 · 매일유업 · KG모빌리티 · 남양유업 · 대교 · 메가스터디교육 · LX하우시스 · 애경산업 · 롯데하이마트 · DB하이텍 · 대상 · 트리니티항공 · 동아에스티 · 제주항공 · 넥센타이어 · 신세계인터내셔날). eng · slug 는 각 시드 `INSERT IGNORE INTO TCOMPANY` 줄 — **유형은 시드 등록 문장을 실측해 센다**. **불가 2(쿠쿠홈시스 robots · 진에어 벽 — collect 에 SQL 없음 · 진에어 후보 4행은 `W/jin_air/`)는 대상 아님.** 대기 웨이브 **없음** |
| 출발 코퍼스 | `main` = `51fefa7`(웨이브 11 공개 뒤) · 회사 **257** · 복지 **5,759** · 쓰이는 코드 **93** · FN-1 매핑 · 법인 · 재적용 **256 · 255 · 256** · large **146** / mid **111**(시드 등록 문장 실측). 코퍼스 시드 폴더 = `/home/ubuntu/loupit/.claude/worktrees/wave12/db/seed/benefit/sql`(257파일 — main 과 같음 · 이것 하나만 센다 · 읽기만) |
| 리드 판정 목록 | `W/_ROSTER.md` (152) ~ (158) + 풀 3차 로스터 `/home/ubuntu/loupit-evidence/2026-10-17-pool3/_ROSTER.md` (149) ~ (151) + 붙여넣기 1차 로스터 `/home/ubuntu/loupit-evidence/2026-10-16-paste1/_ROSTER.md` (147) ~ (148) + 웨이브 10 (142) ~ (146) · 9 (134) ~ (141) · 8 (131) ~ (133) · 7 (114) ~ (130) — 확정값(검증과 엇갈리면 리드가 이긴다) |
| `WT` = worktree · 브랜치 | `/home/ubuntu/loupit/.claude/worktrees/wave12` · `data/wave12-18-companies`(main `51fefa7` 위 — 리드가 만듦) |
| 반영일 | **`2026-10-23`**(주 1회 공개 · 직전 공개 10-16). `company_registrations.json` 은 **새 날짜 객체**를 `waves` 맨 앞에(label 「회사 확장 웨이브 12」). 공개가 밀리면 리드가 날짜를 고친다 |
| 직전 리허설 폴더 · 금융사 | `/home/ubuntu/loupit-evidence/2026-10-16-paste1/rehearsal/`(기대값 「운영 = main」 — 대기분 0 · 기존 257사 행 증감 0) · **금융사 0** |
| 직전 감사(뼈대 · `_audit.py` 출발점) | `/home/ubuntu/loupit-evidence/2026-10-16-paste1/audit/` |
| KRX 업종 | `W/dart/company-20.json` 의 `induty_code`(OpenDART 표준산업분류)로 웨이브 9 `krx-check.md` 규칙대로 감사가 확정 — 새 웹 요청 없이 |
| DART 축 | `W/dart/check-2026-10-18.json` — 18사 모두 재무 · 직원 5개년(2021~2025). 재무 **CFS 16 · OFS 만 1(롯데하이마트)** |

## 이번 웨이브 전용 결론 항목 (감사 §13 에 하나씩)

1. **새 업종 값 둘** — `교육`(웅진씽크빅 · 메가스터디교육 · 대교 — 같은 웨이브 3사 · 바이트 동일) · `여행`(하나투어 1사 — 코퍼스 85종에 여행 · 관광 값 0 · trending 폴백 짝 없는 업종). 새 값 유지 / 기존 값 합류 결론 · trending 영향. 그 밖 14사 업종(항공 · 자동차 · 타이어 · 식품 · 유통 · 반도체 · 가구/인테리어 · 제약 · 엔터테인먼트 · 패션 · 화장품)은 기존 값 합류 확인.
2. **옛 사명 · DART 정식명 · 별칭** — 트리니티항공(구 티웨이항공 · 2026-03-31 사명 변경 · DART 홈 URL 아직 twayair.com) · KG모빌리티(DART 「케이지모빌리티」 · 구 쌍용자동차) · LX하우시스(DART 「엘엑스하우시스」 · 구 LG하우시스) · SM엔터테인먼트(DART 종목명 「에스엠」 · 정식 「에스엠엔터테인먼트」) · DB하이텍(구 동부하이텍) · 동아에스티(영문 Dong-A ST · DART 홈 donga.co.kr 은 동아제약 쪽) · 대상(표시명이 일반 낱말 — slug · 검색 충돌 확인) → `WAVE12_ALIASES` · corp_code_map note.
3. **DART 재무 축** — 롯데하이마트 재무 **OFS 만 5개년** → §4 표에 「공개 뒤 `TCORP.FS_DIV_CD = 'OFS'`(리드 · 운영)」. 나머지 17사 CFS.
4. **그룹 공용 메일** — 롯데하이마트 → **lotte.net 그룹 줄**(사용자 결정 그룹 · 10-14) · LX하우시스(LX인터내셔널 기등록) · DB하이텍(DB손해보험 기등록) · 신세계인터내셔날(이마트 기등록) · 애경산업 · 제주항공(같은 웨이브 AK홀딩스 형제) · SM엔터테인먼트(카카오 형제) · 대상 · 동아에스티(에스티팜 기등록 · 동아쏘시오 공용 도메인 여부) · KG모빌리티 → 계약 §7 규칙(사용자가 그룹 단위 인증을 정한 그룹만 그룹 줄 병합).
5. **같은 웨이브 형제(AK홀딩스)** — 제주항공 50 resort 「애경 그룹 임직원 혜택(골프장 · 테르메덴 등)」과 애경산업 원문 대조 · 그룹 공통 각주 꼴 일치 · 「제주항공 기업 우대 서비스」(애경산업 discount) — 레인 V6 결론을 한 잣대로.
6. **그룹 각주 일관성** — 대상 20행 「, 대상그룹 공통 문구」(레인 V5 판정 — 그룹 채용 사이트 「계열사 또는 근무지에 따라 일부 차이」 단서) · 신세계인터내셔날 9행 「(그룹 통합 채용 기준)」(레인 V8) · 롯데하이마트(롯데 형제 7) · LX하우시스 · DB하이텍 · SM엔터테인먼트 · 동아에스티 — 기등록 형제 시드와 10자 이상 조각 대조.
7. **정본 URL · 배포 시 주의** — 트리니티항공(점검기 blocked — Akamai 403 · 브라우저 UA 200) · 넥센타이어 nexenuniverse.com(도메인 만료 2026-11-08 — 레인 V8 캠페인 도메인 판정) · 매일유업(게시 날짜 없는 정본 — 검증이 현행 인정) · 제주항공(PDF static.jejuair.net) · 신세계인터내셔날(PDF img.sikorea.co.kr · keyword None) · 동아에스티(보고서 목록 페이지 · 복지 낱말 없음) · LX하우시스(robots.txt 가 200 차단 안내 HTML) → §14.
8. **한시적 출처(공고 이미지)** — 대교 공고 근거 16행(jrs.jobkorea.co.kr/daekyo = 회사 계정 ATS · 마감 공고) · 메가스터디교육 공고 이미지 3행 · DB하이텍 ESG 렌더 판독 → 사본 sha256 확인 · §14.
9. **리드 판정 (154) 시설 행 · (147) 법정 검진 이름만 · (155)** — 18사 전부에 같은 잣대로 적용됐는지(사본 모드 회사 포함) · 어긋난 행은 §5.
10. **등록하면 안 되는 회사 · 붙여넣기 후보** — 쿠쿠홈시스(`https://recruit.cuckoo.co.kr/recruit/Main.do` · robots) · 진에어(`https://jinair.recruiter.co.kr/appsite/company/callSubPage?code1=4000&code2=4300` · 벽 · 공시 후보 4행) · 보강 후보 5(SM `https://www.smentertainment.com/sustainability/society/` · 매일유업 `https://maeil.recruiter.co.kr/career/benefit` · 트리니티항공 `https://trinityairways.recruiter.co.kr/career/benefits` · 제주항공 `https://jejuair.recruiter.co.kr/career/welfare` · 넥센타이어 `https://nexentire.recruiter.co.kr/career/welfare`) → §14.
11. **11-27 난임 개정** — LX하우시스 24(유급 3일 = 법정 2 + 1 → 11-27 부터 상회분 소멸) 등 근거표 「11-27 재계산 대상」 전수 표를 §14 에. 공개(10-23)가 11-27 전이므로 지금 문구는 현행법.
12. **금액** — 식대 추정 SM엔터테인먼트 288 · KG모빌리티 288 · DB하이텍 864 · 넥센타이어 864(3끼/2끼 산식 — 1끼 12,000원 기준) · 동아에스티 복지포인트 50 stated.
13. **항목 페이지 예외** — 검증 보고서마다의 예외 후보(해시 · mode)를 §10-1 에 모아 `validate_all` 0 으로.
