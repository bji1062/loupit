-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 삼성화재 복리후생 데이터 (신규 회사)
-- 출처: AI 파싱 (2026-09-05)
-- URL: https://www.samsungcareers.com/subsid/detail/E21
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고: 근거는 전부 삼성 공식 채용사이트의 **삼성화재 법인 전용 페이지** 한 곳이다.
--       복지 섹션은 같은 페이지의 앵커 #a6(section id=a6) 이고 제목이 법인명을 달고 있다 —
--       「삼성화재의 근무 환경과 복지 제도」. 서버렌더 HTML 이라 헤드리스 브라우저 불필요.
--       귀속 경로: samsungcareers.com 홈 → 관계사 소개(/subsid/) → 금융 → 삼성화재
--       → /subsid/detail/E21. 같은 페이지가 법인을 직접 명시한다(주소 서울특별시 서초구
--       서초대로74길 14 · 주요 업무 손해보험 · 홈페이지 www.samsungfire.com).
--       법인 전용 페이지라 「그룹 통합 채용 기준」 각주는 붙이지 않았다(KB금융 선례와 구분).
--       ⚠ 자기 도메인 samsungfire.com 에는 채용·복지 페이지가 없다(실측 /recruit/ 404).
--       ⚠ 그룹 공통 /insight/welfare 17항목은 한 건도 섞지 않았다. 그 페이지 스스로
--          「관계사별 복지 제도는 각 회사별 페이지에서 확인 가능합니다」라고 분리해 둔다.
--       ⚠ 페이지의 「기타 > 채용 홈페이지」 링크(www.sfnew.com → inpk.link/sfminew)는
--          보험설계사 모집 랜딩이자 3자 단축링크라 출처로 쓰지 않았다.
--       ⚠ data-tip 속성값에 이스케이프 안 된 꺾쇠가 있어(Dream Campus+ · 선택적 근로시간제)
--          정규식 태그 제거는 항목명을 깨뜨린다. 버튼 블록을 원문 그대로 잘라 파싱했다.
--       원문 30항목 → 7항목 제외(회사 주도 교육 커리큘럼·인사제도·조직문화 담당자) →
--       23항목. 그중 4개가 복수 제도를 병기한 복합 라벨이라 분해(+6), 코어타임은
--       선택적 근로시간제와 같은 flex_work 라 병합(-1) → **28행**. 신규 코드 0.
--       금액: 페이지에 원 단위 금액이 0건이다. 정량 표현은 비율·시간뿐이고
--       (개인연금 약 50% · 코어타임 10~16시 · 주 40시간) 이는 금액이 아니다.
--       → 28행 전부 BENEFIT_AMT NULL · QUAL_YN TRUE. 신규 회사라 승계할 앵커도 없다.
--       법정 제도 미수록: 모성보호제도의 「임신기간 단축 근무」는 법정이라 행으로 만들지
--       않았고 parenting 행 서술에서도 뺐다. 4대보험·퇴직연금·연차는 페이지에 아예 없다.
-- ⚠ LOGO_NM 확인 요망: 지시받은 값 그대로 「삼」을 넣었으나 코퍼스 실측은 113개사 중
--   112개가 영문 이니셜이고(한글은 효성중공업 「효」 1건뿐) 삼성 계열 7개사는 전부 「S」다
--   (삼성전자·삼성SDI·삼성물산·삼성바이오로직스·삼성생명·삼성전기·삼성카드).
--   형제 법인과 배지 글자가 어긋나는 것을 원치 않으면 이 한 글자를 S 로 바꾸면 된다.
--       ⚠ 검증·감사 판정 반영(2026-09-05): 행 조치 없음(28행 그대로). SORT 30·70·82 의
--       사용자 노출 서술에서 코드 선택 근거·병합 사실·법정 여부 판단을 걷어냈다 —
--       이 세 필드는 API 응답과 비교 엔진으로 그대로 나간다. SORT 60 은 원문이
--       「지역전문가, MBA, 석사 학위」 한 라벨이라 mba 1행으로 유지한다.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('samsung_fire', '삼성화재',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '보험', 'S', 'https://www.samsungcareers.com/subsid/detail/E21');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'samsung_fire');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.samsungcareers.com/subsid/detail/E21'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '복지포인트', NULL, 'perks',
   'est', NULL, TRUE, '매년 선택적 복지포인트를 지급해 현금처럼 사용 가능 (공식 페이지 가족·의료·소득 지원 항목 — 연간 포인트 금액 미기재)', 10),
  (@comp_id, 'pension_support', '개인연금 지원', NULL, 'perks',
   'est', NULL, TRUE, '노후 지원 목적 개인연금의 약 50%를 회사가 지원 (공식 페이지가 밝힌 정량 표현은 지원 비율뿐 — 지원 금액·납입 한도 미기재)', 11),
  (@comp_id, 'welfare_fund_loan', '사내 근로복지기금 대출', NULL, 'perks',
   'est', NULL, TRUE, '생활안정 지원 항목의 사내 근로복지기금 대출 (공식 페이지 — 대출 한도·이율·용도 미기재)', 12),
  (@comp_id, 'birthday_gift', '기념일 선물', NULL, 'perks',
   'est', NULL, TRUE, '생일·결혼기념일 등에 복지포인트 지급 (공식 페이지 — 지급 포인트 금액 미기재)', 13),
  (@comp_id, 'meal', '사내 식당', NULL, 'perks',
   'est', NULL, TRUE, '사내 식당 운영 (공식 페이지 사내 문화 및 편의 항목 — 제공 끼니·식대 단가 미기재)', 14),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진 지원', NULL, 'health',
   'est', NULL, TRUE, '정기 건강검진을 지원하고 검진 시 공가 제공 (공식 페이지 — 검진 주기·대상 가족 범위·비용 미기재)', 20),
  (@comp_id, 'insurance', '신종단체보험', NULL, 'health',
   'est', NULL, TRUE, '상해·질병·후유장해·진단비·실손 의료비 등 임직원 대상 단체보험 지원 (공식 페이지 — 보장 한도·보험료 미기재)', 21),
  (@comp_id, 'mental', '심리상담 지원', NULL, 'health',
   'est', NULL, TRUE, '사내 심리상담실을 통한 심리상담 지원 (공식 페이지 — 상담 횟수·가족 포함 여부 미기재)', 22),
  (@comp_id, 'fitness', '사내 피트니스', NULL, 'health',
   'est', NULL, TRUE, '사내 피트니스 운영 (공식 페이지 사내 문화 및 편의 항목 — 이용 조건·사업장 범위 미기재)', 23),
  (@comp_id, 'clinic', '사내 병원', NULL, 'health',
   'est', NULL, TRUE, '사내 병원 운영 (공식 페이지 사내 문화 및 편의 항목 — 진료 과목·이용 대상 미기재)', 24),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'parenting', '출산 축하금·임산부 지원', NULL, 'family',
   'est', NULL, TRUE, '생활안정 지원의 출산 축하금과 모성보호제도의 임산부 물품지원 (공식 페이지 — 축하금 액수·지원 품목 미기재)', 30),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '생활안정 지원 항목의 경조사 지원 (공식 페이지 — 경조금·경조휴가 구분과 금액 미기재)', 31),
  (@comp_id, 'childcare', '사내 어린이집', NULL, 'family',
   'est', NULL, TRUE, '자녀교육 지원 항목의 사내 어린이집 (공식 페이지 — 정원·대상 연령·사업장 미기재)', 32),
  (@comp_id, 'child_edu', '자녀 학자금·취학 축하 선물', NULL, 'family',
   'est', NULL, TRUE, '취학 자녀 축하 선물과 자녀 학자금(유치원·중/고/대학교·해외대 포함) 지원 (공식 페이지 — 지원 한도·자녀 수 제한·금액 미기재)', 33),
  (@comp_id, 'fertility_support', '난임 치료비 지원', NULL, 'family',
   'est', NULL, TRUE, '모성보호제도의 난임 치료비 지원 (공식 페이지 — 지원 한도·횟수 미기재)', 34),

  -- ── 휴가 (time_off) ──
  (@comp_id, 'long_service_leave', '장기근속 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '근속 년수별 휴가 제공 (공식 페이지 장기근속휴가/포상 항목 — 근속 구간·휴가 일수 미기재)', 40),

  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'long_service_bonus', '장기근속 포상', NULL, 'compensation',
   'est', NULL, TRUE, '근속 년수별 휴가비·기념품 지원 (공식 페이지 장기근속휴가/포상 항목 — 포상 금액·기준 근속 미기재)', 50),
  (@comp_id, 'excellence_award', 'Try 상', NULL, 'compensation',
   'est', NULL, TRUE, '독창적이고 엉뚱한 시도와 실패까지 응원하기 위한 Try 상 운영 (공식 페이지 — 포상 규모·선정 기준 미기재)', 51),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'mba', '핵심인재 양성(MBA·석사학위)', NULL, 'growth',
   'est', NULL, TRUE, '전문성을 갖춘 글로벌 인재 양성을 위한 지역전문가·MBA·석사 학위 취득 프로그램 운영 (공식 페이지 — 선발 인원·지원 금액 미기재)', 60),
  (@comp_id, 'books', '전자도서관·도서 구입비', NULL, 'growth',
   'est', NULL, TRUE, '교보문고 제휴 e북 열람 및 매년 도서 구입비 지원 (공식 페이지 전자도서관/북마크 항목 — 연간 지원 금액 미기재)', 61),
  (@comp_id, 'edu_support', '전문자격 취득 지원', NULL, 'growth',
   'est', NULL, TRUE, '계리사·손해사정사·CFA 등 금융보험 자격과 기타 자격증의 교육 과정·취득 지원금 운영 (공식 페이지 — 지원금 액수 미기재)', 62),
  (@comp_id, 'self_development', '역량개발도전제도', NULL, 'growth',
   'est', NULL, TRUE, '직무·직급 관계 없이 본인이 관심있는 분야를 계획하고 학습하도록 비용 지원 (공식 페이지 — 지원 한도 미기재)', 63),

  -- ── 근무 유연성 (flexibility) ──
  (@comp_id, 'flex_work', '선택적 근로시간제·코어타임', NULL, 'flexibility',
   'est', NULL, TRUE, '라이프스타일에 맞춰 자율적으로 유연근무가 가능한 선택적 근로시간제 운영, 주 40시간을 충족하는 범위에서 코어타임(10~16시) 외 자유 출퇴근 가능 (10시 출근 또는 16시 퇴근) — 공식 페이지 (신청 절차·적용 대상 미기재)', 70),
  (@comp_id, 'pc_off', 'PC On/Off 시스템', NULL, 'flexibility',
   'est', NULL, TRUE, 'PC On/Off 시스템을 통한 근무시간 관리 (공식 페이지 — 자동 차단 시각·예외 절차 미기재)', 71),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '휴양소 지원', NULL, 'leisure',
   'est', NULL, TRUE, '전국의 다양한 리조트 대상 이용료 지원 (공식 페이지 — 제휴처 목록·지원 한도 미기재)', 80),
  (@comp_id, 'leisure_ticket', '캐리비안베이 지원', NULL, 'leisure',
   'est', NULL, TRUE, '성수기·비수기 캐리비안베이 티켓 지원 (공식 페이지 — 지급 매수·본인 부담 미기재)', 81),
  (@comp_id, 'company_event', '가족친화프로그램', NULL, 'leisure',
   'est', NULL, TRUE, '자녀 영어캠프·글램핑·안내견학교/모빌리티뮤지엄 방문·회사 사무실 자녀 초대 등 가족 참여 프로그램 운영 (공식 페이지 — 개최 주기·참가 자격 미기재)', 82),
  (@comp_id, 'club', '취미반 지원', NULL, 'leisure',
   'est', NULL, TRUE, '임직원의 문화·여가활동 지원을 위한 사내 취미반 지원, 스포츠·문화탐구·학습 등 분야 (공식 페이지 — 활동비 한도 미기재)', 83)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
