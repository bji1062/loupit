-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- HL만도 복리후생 데이터 (신규 회사)
-- 출처: AI 파싱 (2026-09-19)
-- URL: https://www.hlmando.com/ko/career.do
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고: 근거는 전부 HL만도 자기 도메인(www.hlmando.com) 두 페이지다. 정본이 둘이고
--       합쳐야 목록이 완성된다.
--       ① /ko/career.do — GNB 인재채용 > Life 섹션(워라밸 6 + 각종 지원 및 건강관리 9)
--          + 교육 탭의 국내외 학술연수 1
--       ② /ko/sustainability/human-rights-and-safety.do — 임직원 > 조직문화 >
--          유연한 근무환경을 위한 다양한 제도 4 + 복리후생(시설 3 · 생활 11 · 건강문화 6)
--       둘 다 서버렌더 HTML(Apache + JSP, .do) 이라 헤드리스 렌더·이미지 판독 불필요.
--       robots 는 www.hlmando.com 단독으로 먼저 받았고 User-agent * / Allow: / 전면 허용.
--       ⚠ 분류 제목 h3/h5 가 class=hidden_cont(text-indent -9999px) 로 시각적으로만
--          숨겨져 있다. 가시 텍스트만 긁으면 워라밸·각종 지원 및 건강관리·시설 지원·
--          생활 지원·건강문화생활 지원 다섯 분류명이 통째로 사라진다. 원본 HTML 파싱.
--       ⚠ ② 생활 지원 목록에 주석 처리된 항목 2개가 들어 있다(퇴직자 기념품 지급 ·
--          명절선물 지급). 화면에 렌더되지 않으므로 유령으로 보고 두 항목 모두 제외했다.
--          프로브는 이 두 건을 복지 문구 없는 주석으로 분류했었다 — 실측으로 뒤집혔다.
--       원문 합계 40항목(① 15 + 교육 1, ② 24) → 주제 중복 12쌍 병합 → 고유 28 →
--       법정 제도 3건 제외 → 25행. 신규 코드 0.
--       법정 제도 미수록: 국민연금/건강보험제도 운용(4대보험) · 산업재해 보상 ·
--       출산 휴가와 육아 지원 블록의 출산·육아 휴직, 남성 출산휴가, 가족 돌봄 휴가,
--       육아기 근로시간 단축. 행으로 만들지 않았고 다른 행 서술에도 넣지 않았다.
--       금액: 두 페이지에 원 단위 금액이 0건이다. 정량 표현은 동호회 75개 · 주 40시간 ·
--       21시 이후 퇴근 시 최소 12시간 · 등록금 전액뿐이고 이는 연 환산 금액이 아니다.
--       → 25행 전부 BENEFIT_AMT NULL · QUAL_YN TRUE. 신규 회사라 승계할 앵커도 없다.
--       귀속: 두 페이지 모두 주어가 법인이다(HL Mando 복리후생 제도는… / HL Mando는…).
--       계열사·상이 면책 0건, 형제 법인 HL D and I한라와 고유 문자열 양방향 0회 일치 →
--       그룹 통합 채용 기준 각주는 붙이지 않았다.
--       ⚠ 구 사명 www.mando.com · 지주 www.hlholdings.com 은 443 무응답이라 robots 조차
--          받지 못했다(금지 취급, 본문 미요청). 그룹 ATS hlcompany.recruiter.co.kr 은
--          robots 가 /app* 을 막고 복지 페이지가 HL그룹 단위라 쓰지 않았다.
--       ⚠ 공식 이메일 도메인은 웹 도메인과 다르다 — hlcompany.com(MX 있음).
--          hlmando.com 에는 MX 레코드가 없다.
--       ⚠ 이 사이트는 Last-Modified·ETag 가 없어 갱신 감지는 본문 해시로만 가능하다.
--          sitemap.xml 의 /ko/career/… 경로는 302 로 죽어 있으니 발견 경로로 쓰지 말 것.
--       ⚠ 검증·감사 판정 반영(2026-09-19): 25 → 23행(삭제 1 · 병합 1). SORT 41 welfare_fund_loan → welfare_fund
--       재코딩(원문에 대출 낱말이 없다) · SORT 31 적립휴가를 SORT 10 flex_work 서술로 흡수 · SORT 81 nap_room
--       (샤워실·탈의실) 삭제 · SORT 82 에서 안전보호구 삭제 · SORT 45 개인연금 명칭·서술 교체.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hl_mando', 'HL만도',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '자동차부품', 'H', 'https://www.hlmando.com/ko/career.do');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hl_mando');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.hlmando.com/ko/career.do'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무 유연성 (flexibility) ──
  (@comp_id, 'flex_work', '유연근무제도', NULL, 'flexibility',
   'est', NULL, TRUE, '생활패턴에 맞춰 출퇴근 시간을 정하는 유연근무제도, 업무량에 따라 개인 근무시간을 월 단위로 관리, 21시 이후 퇴근 시 최소 12시간 후 출근, 초과 근무시간은 조기 퇴근 또는 적립휴가로 대체 (공식 채용 페이지 워라밸 항목과 지속가능경영 조직문화 페이지 근무제도 — 신청 절차·적용 대상 미기재)', 10),
  (@comp_id, 'remote_work', '재택근무제도', NULL, 'flexibility',
   'est', NULL, TRUE, '근무 장소에 상관없이 업무를 볼 수 있는 재택근무제도, 근무계획에 따라 근무장소를 자유롭게 선택 (공식 채용 페이지 워라밸 항목과 지속가능경영 조직문화 페이지 근무제도 — 이용 일수·신청 조건 미기재)', 11),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '75개의 다양한 사내 동호회 운영으로 취향이 맞는 사람들과 취미 활동, 지속가능경영 조직문화 페이지의 취미반 운영 (공식 채용 페이지 워라밸 항목 — 활동비 지원 여부 미기재)', 20),
  (@comp_id, 'resort', '호텔·리조트 법인 회원가', NULL, 'leisure',
   'est', NULL, TRUE, '전국에서 유명한 호텔·리조트를 법인 회원가로 이용, 지속가능경영 조직문화 페이지의 하기 휴양소 운영 (공식 채용 페이지 워라밸 항목 — 제휴처 목록·이용 한도 미기재)', 21),
  (@comp_id, 'company_event', '종합행사', NULL, 'leisure',
   'est', NULL, TRUE, '사생대회·체육대회 등 종합행사 운영 (지속가능경영 조직문화 페이지 건강·문화생활 지원 항목 — 개최 주기·참가 대상 미기재)', 22),

  -- ── 휴가 (time_off) ──
  (@comp_id, 'summer_leave', '여름휴가', NULL, 'time_off',
   'est', NULL, TRUE, '여름휴가를 자유롭게 사용해 원하는 때에 휴식, 연중 희망 일정에 맞춰 사용 (공식 채용 페이지 워라밸 항목과 지속가능경영 조직문화 페이지 근무제도 — 휴가 일수·사용 절차 미기재)', 30),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '복지몰 포인트', NULL, 'perks',
   'est', NULL, TRUE, '복지몰 포인트를 사용해 여행·문화공연·자기개발에 이용 (공식 채용 페이지 워라밸 항목 — 연간 포인트 금액 미기재)', 40),
  (@comp_id, 'welfare_fund', '생활안정자금 지원', NULL, 'perks',
   'est', NULL, TRUE, '사내 근로 복지 기금을 운용해 긴급 생활 안정 자금을 지원, 지속가능경영 조직문화 페이지의 사내근로복지기금 운영 (공식 채용 페이지 각종 지원 및 건강관리 항목 — 지원 한도·신청 요건 미기재)', 41),
  (@comp_id, 'housing_loan', '주택자금 장기융자', NULL, 'perks',
   'est', NULL, TRUE, '주거 안정 목적의 주택 구매·임차 자금 장기융자 제도, 지속가능경영 조직문화 페이지의 주택융자금지급 (공식 채용 페이지 각종 지원 및 건강관리 항목 — 융자 한도·이율 미기재)', 42),
  (@comp_id, 'meal', '급식·구내식당', NULL, 'perks',
   'est', NULL, TRUE, '급식 제공과 기타 복지시설의 구내식당 운영 (지속가능경영 조직문화 페이지 생활 지원·시설 지원 항목 — 제공 끼니·식대 단가 미기재)', 43),
  (@comp_id, 'commute_subsidy', '통근 차량 지원', NULL, 'perks',
   'est', NULL, TRUE, '통근을 위한 차량 지원 (지속가능경영 조직문화 페이지 생활 지원 항목 — 운행 노선·대상 사업장 미기재)', 44),
  (@comp_id, 'pension_support', '개인연금(편의 제공)', NULL, 'perks',
   'est', NULL, TRUE, '개인연금 등 편의 제공 (지속가능경영 조직문화 페이지 생활 지원 항목 — 회사 지원금 여부·지원 비율 미기재)', 45),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'child_edu', '자녀 교육비 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀 교육비로 유치원 보조비와 고등학교·대학교 등록금 전액 지원, 지속가능경영 조직문화 페이지의 학자금 지급 (공식 채용 페이지 각종 지원 및 건강관리 항목 — 자녀 수 제한·지원 한도 미기재)', 50),
  (@comp_id, 'childcare', '사내 어린이집', NULL, 'family',
   'est', NULL, TRUE, '주요 모든 사업장 내 어린이집을 운영해 육아 문제를 해소, 외부 전문기관의 놀이 중심 프로그램을 연령별 발달 수준에 맞게 제공 (공식 채용 페이지 각종 지원 및 건강관리 항목과 지속가능경영 조직문화 페이지 사내 어린이집 프로그램 — 정원·대상 연령 미기재)', 51),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사가 생기면 경조 용품과 조사 서비스를 지원, 지속가능경영 조직문화 페이지의 경조금·조사지원제도 (공식 채용 페이지 각종 지원 및 건강관리 항목 — 경조금 액수·경조휴가 일수 미기재)', 52),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진 지원', NULL, 'health',
   'est', NULL, TRUE, '정기적인 건강검진 지원과 배우자 동반 검진 안내, 지속가능경영 조직문화 페이지의 건강진단 (공식 채용 페이지 각종 지원 및 건강관리 항목 — 검진 주기·검진 비용 미기재)', 60),
  (@comp_id, 'medical', '의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '예상치 못한 질병과 사고로 과도한 의료비가 발생하면 의료비 일부를 지원, 지속가능경영 조직문화 페이지의 일반재해 등 보조금 지급 (공식 채용 페이지 각종 지원 및 건강관리 항목 — 지원 비율·한도 미기재)', 61),
  (@comp_id, 'fitness', '사내 피트니스 센터', NULL, 'health',
   'est', NULL, TRUE, '다양한 운동기구가 비치된 사내 피트니스 센터 운영, 지속가능경영 조직문화 페이지의 체육시설 (공식 채용 페이지 각종 지원 및 건강관리 항목 — 사업장 범위·이용 조건 미기재)', 62),
  (@comp_id, 'clinic', '사내 건강관리실', NULL, 'health',
   'est', NULL, TRUE, '사내 건강관리실을 운영해 질병과 사고 발생 시 신속하게 의료 서비스를 지원, 지속가능경영 조직문화 페이지 시설 지원의 의무실 (공식 채용 페이지 각종 지원 및 건강관리 항목 — 상주 인력·진료 범위 미기재)', 63),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'mba', '국내외 학술연수', NULL, 'growth',
   'est', NULL, TRUE, '미래 인재로 선발된 임직원에게 국내외 유수 대학에서 연구하고 학위를 취득할 수 있도록 지원 (공식 채용 페이지 교육 항목 — 선발 인원·지원 금액 미기재)', 70),

  -- ── 근무 환경 (work_env) ──
  (@comp_id, 'dormitory', '사원주택', NULL, 'work_env',
   'est', NULL, TRUE, '아파트·기숙사 형태의 사원주택 운영 (지속가능경영 조직문화 페이지 시설 지원 항목 — 입주 자격·사업장 범위 미기재)', 80),
  (@comp_id, 'uniform', '피복(근무복) 지급', NULL, 'work_env',
   'est', NULL, TRUE, '피복 지급 (지속가능경영 조직문화 페이지 생활 지원 항목 — 지급 주기·대상 직군 미기재)', 82),

  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'stock_option', '우리사주조합', NULL, 'compensation',
   'est', NULL, TRUE, '우리사주조합 운영 (지속가능경영 조직문화 페이지 생활 지원 항목 — 배정 한도·청약 조건 미기재)', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
