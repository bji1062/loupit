# 웨이브 11 (붙여넣기 1차) 명단 · 리드 메모 (2026-10-16)

절차: 간소화 — 계약 `W/_CONTRACT.md`(= 웨이브 10 계약 + 붙여넣기 웨이브 줄 · (144)) · 검증 `wave-lite/_VERIFY-LITE.md` · 감사 · 통합 · 등록 `wave-lite/_AUDIT-INTEGRATE-REGISTER.md` · 어휘 93종. 대기 시드 없음(웨이브 6 ~ 10 공개됨 · 코퍼스 = 리포 252파일). 판정 번호 (147)부터.

## 대상 5 — 사용자 붙여넣기(2026-10-16)
| 회사 | eng | 앞 판정 | 붙여넣기 사본 | 앞 근거 | DART |
|---|---|---|---|---|---|
| 종근당 | chongkundang | 웨이브 6 불가(ATS 벤더 호스트 robots) | `W/chongkundang/user_paste_welfare.txt` | `2026-10-14-wave6/probe/종근당.md` · `probe/chongkundang/` | 00992871 · 185750 · CFS 5개년 |
| 케이뱅크 | kbank | 웨이브 6 불가(벤더 호스트) | `W/kbank/user_paste_benefits.txt` | `2026-10-14-wave6/probe/케이뱅크.md` · `probe/kbank/` | 01203312 · 279570 · 2023~ OFS(금융) |
| LG생활건강 | lg_hnh | 웨이브 7 불가(robots 전면) | `W/lg_hnh/user_paste_welfare.txt` | `2026-10-14-wave7/collect/LG생활건강.evidence.md` · `wave7/lg_hnh/` | 00356370 · 051900 · CFS 5개년 |
| 한화손해보험 | hanwha_general_ins | 웨이브 8 불가(렌더 벽) | `W/hanwha_general_ins/user_paste_benefits.txt` | `2026-10-15-wave8/collect/한화손해보험.evidence.md` · `wave8/hanwha_general_ins/` | 00135917 · 000370 · 2023~ CFS(금융) |
| 쎄트렉아이 | satrec_i | 웨이브 8 불가(채용 사이트 robots) | `W/satrec_i/user_paste_welfare.txt` | `2026-10-15-wave8/collect/쎄트렉아이.evidence.md` · `wave8/satrec_i/` | 00449254 · 099320 · CFS 5개년 |

## 진행
- 00:5x UTC 붙여넣기 5사 받음 → 사본 · sha256 · meta 저장 · 계약 · 명단 · 수집 5 투입.
- 쎄트렉아이 = 가능 · 19행(사본 18 · 공시 원격근무 1) · 정본 satreci.careerlink.kr/welfare(점검기 robots — 주간 점검이 내용 변화 못 잡음) · 금액 2(복지포인트 160 · 식대 864 추정) · 한화 형제 6 겹침 0 · 판단 요청 4(Meet-up Day culture_day · 방문 검진 clinic · 자기개발 conference/mba 가름 · 포인트 추정) · 제외 보건휴가 · 육아휴직 1년 · 님 호칭.
- 종근당 = 가능 · 21행 · 정본 ckd.recruiter.co.kr/career/Welfare(붙여넣기 · 점검기 ok 200 keyword True — 제목 · 설명 낱말) + 사업 · 반기 유연근무 표 2행 · 금액 0 · 형제 0 · 메일 @ckdpharm.com · 판단 요청 2(건강기능식품 임직원몰 discount vs welfare_point · 「일반」 검진 법정으로 걷음 · 하기휴가 summer_leave).
- LG생활건강 = 가능 · 24행 · 정본 후보 lghnh.com/recruit/system/welfare.jsp(robots 금지 — 웹 검색 제목으로만 확인 · **사용자에게 주소창 주소 확인 요청**) · 금액 0 · LG 형제 7 겹침 0 · 그룹 각주 없음 · 판단 요청 5 · 11-27 대상 1(난임치료 지원 — 일수 없음).
- 한화손해보험 = 가능 · 14행(페이지 12 · 공시 2) · 정본 hwgeneralins.com/intro/talenthall/benefits.do(점검기 ok · 본문 난독화 셸 — 변화 감지 불가) · 금액 1(식대 288 추정) · 한화 형제 6 겹침 0 · 메일 자체 도메인(hanwha.com 근거 없음) · 판단 요청 4(귀성여비 transport · 급여 블록 중식대 · 차량유지비 · 일반검진 뺌 · 체력단련휴가 leave_general) · 법정 제외(산전산후 100일 — 원문이 회사분 안 가름).
- 01:0x UTC 검증 레인 Q1 투입(종근당 · LG생활건강 · 쎄트렉아이).
- 케이뱅크 = 가능 · 15행(사본 13 · 공시 2 — 원격근무제 (조건부) · 육아휴직 최대 2년) · 금액 1(복지포인트 520 stated) · 업종 핀테크/은행(카카오뱅크 선례) · KT 겹침 0 · 판단 요청 4(커넥트데이 뺌 · 원격 조건부 · 성장지원 한 행 · 포인트 stated) · 추천 리워드 뺌 · 피어 보너스 excellence_award · 케미데이 company_event.
- **수집 끝(01:0x UTC): 가능 5/5** — 종근당 21 · 케이뱅크 15 · LG생활건강 24 · 한화손해보험 14 · 쎄트렉아이 19 = 93행. 검증 레인 Q2(케이뱅크 · 한화손해보험 — 금융) 투입.
- 감사 리드 칸 작성 · worktree `.claude/worktrees/paste1` · 브랜치 `data/wave11-paste-5-companies`(main b2b2ba3 위). 반영일 2026-10-16 — 대문 등록은 같은 날짜 객체(92사)에 5사를 더함.
- 레인 Q2 끝(REFUTED 0): 케이뱅크 15(SQL 변경 0 · 예외 1 · 판단 요청 4 기본안) · 한화손해보험 14(11 transport 문안 「무연고지 근무자 귀성여비 지급」 · 예외 1 · 산전산후 100일 제외 맞음).
- (147) **한화손해보험 「그 외 직원 : 매년 일반검진」 = 싣지 않음(기본안).** 원문이 법정 검진 이름만 적고 법정분 · 회사분을 스스로 가르지 않는다(계약 3-2) · 종근당 「일반 및 정밀 건강검진」에서 「일반」을 걷은 것과 같은 잣대 · 이 회사는 종합검진 행(50)이 있어 축이 비지 않는다.
- 레인 Q1 끝(REFUTED 0 · 판정 필요 0): 종근당 21(조치 0) · LG생활건강 24(12 서술 탭 이름 「그룹제품구입지원」으로 시작 · 예외 2 · LG에너지솔루션과 같은 구절 3 — 자기 도메인이라 각주 없음(근거표 정정)) · 쎄트렉아이 19 → 20(MISSED 1 — 공시 장기근속 급부 81 `long_service_bonus` 추가 · 80 명절 귀향비에 「전 직원 동일 기준 명절상여」 병합).
- **검증 5/5 끝(01:1x UTC).** 예상 최종 = 종근당 21 · 케이뱅크 15 · LG생활건강 24 · 한화손해보험 14 · 쎄트렉아이 20 = **94행 → 회사 257 · 복지 5,759**. 감사 투입.
- 01:4x UTC **감사 끝: BLOCK 0 · MED 2 · LOW 9 · 94행 · SD-3 257 · SD-4 5,759 · FN-1 256/255/256 · 금융사 21 · 코드 93 · large 146 / mid 111** · 예외 7 · 대문 = 2026-10-16 객체에 5사 더함(label 「회사 확장 웨이브 6 ~ 11」). MED-1 케이뱅크 재무 OFS 만 → 공개 뒤 FS_DIV_CD='OFS' · MED-2 LG생활건강 정본 주소 사용자 확인 대기(기본 = 수집본 주소).
- (148) **감사 §13 기본안 전부 채택.** 통합 · 등록 레인 투입(Sonnet · 한 레인에 B → C 순서).
- 01:5x UTC 통합 · 등록 1차 끝: 5파일 94행 · 모의본 diff 0 · 핀 257/5,759/256/255 · 금융사 21 · 대문 6 ~ 11 · 이메일 177문장 · KRX · corp · 별칭 · 리허설 5,759/257 · 운영 252사 증감 0 · run_tests ALL GREEN(1043 · 913 · 1286). ⚠ 항목 페이지 예외 7 미집행 → 같은 레인에 집행 지시.
- 02:0x UTC 예외 7 집행 · run_tests ALL GREEN(1043 · 913 · 1286) · 근거 사본 `docs/handoff/2026-10-16-paste1-evidence/`(27파일 · 비밀 값 대조 0) · **커밋 `52d9466`**(push 전) · 독립 검토 투입.
- 02:1x UTC 독립 검토 끝: HIGH 0 · MED 2(공개 명단 한 문장 정리 · LG 주소 확인 대기) · LOW 4 · 실명 0 · 비밀 값 파일 0. 반영 레인(MED-1 · LOW-1 · 2 · 4 · amend).
