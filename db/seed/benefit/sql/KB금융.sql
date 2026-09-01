-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- KB금융 복리후생 데이터 (신규 회사)
-- 출처: AI 파싱 (2026-09-01)
-- URL: https://careers.kbfg.com/life/benefit
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고: 근거는 전부 KB금융그룹 공식 통합 채용사이트(careers.kbfg.com) Life > Benefits 페이지.
--       Vue SPA 라 본문이 index HTML 에 없다 — 청크 /assets/Benefit-aa8d9d65.js 파싱으로 항목을
--       확보했고, Playwright 렌더로 같은 문장이 실제 DOM(.popup__item-desc 43노드)에 있음을 재확인.
--       페이지 섹션 5개(가족·건강 친화적 복지 지원 / 여가 및 리프레시 지원 /
--       사내 편의시설 및 보건시설 제공 / 주거지원, 장기근속 및 기타 복지 운영 / 다양한 근무제도)
--       아래 총 21개 항목 = 21행. 관계사(국민은행 등) 전용 표시가 붙은 항목은 없다.
--       페이지는 금액을 단 하나도 공개하지 않는다 → 전 행 BENEFIT_AMT NULL · QUAL_YN TRUE
--       (신규 회사라 앵커 없음 = 금액 추정 금지).
--       참고: 그룹 통합 채용 사이트 기준 — 지주가 채용 주체로 등재된 사이트이며,
--       세부 운영은 계열사별 상이할 수 있음.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('kbfg', 'KB금융',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '금융지주', 'K', 'https://careers.kbfg.com/life/benefit');

SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'kbfg');

-- 기존 행이 이미 있었다면 URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://careers.kbfg.com/life/benefit'
 WHERE COMP_ID = @comp_id;

DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'childcare', 'KB어린이집', NULL, 'family',
   'est', NULL, TRUE, '계열사별 어린이집·수유실 등 육아 시설 운영', 10),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '미취학 자녀보육비부터 대학교 학자금까지 지원', 11),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '임직원 및 가족 경조사에 경조금·경조휴가·화환(조화)·상조서비스 제공', 12),
  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진', NULL, 'health',
   'est', NULL, TRUE, '임직원 및 가족구성원 대상 질병 조기발견 목적의 건강검진 제도 운영', 20),
  (@comp_id, 'medical', '의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '임직원 및 가족구성원 대상 의료비 지원 제도 운영', 21),
  (@comp_id, 'mental', '심리상담서비스', NULL, 'health',
   'est', NULL, TRUE, '전문심리상담사가 상주하는 사내 심리상담센터 운영 및 전국 심리상담센터 연계', 22),
  (@comp_id, 'clinic', 'KB사내의원', NULL, 'health',
   'est', NULL, TRUE, '근무장소에서 전문의 처방·진료를 받을 수 있는 사내의원(의무실) 운영', 23),
  (@comp_id, 'fitness', 'KB피트니스센터', NULL, 'health',
   'est', NULL, TRUE, '전문강사의 필라테스·PT 강습 및 체력단련이 가능한 피트니스센터 운영', 24),
  -- ── 근무환경 (work_env) ──
  (@comp_id, 'lounge', '휴게 및 문화공간', NULL, 'work_env',
   'est', NULL, TRUE, '사옥 내 임직원 휴게·문화공간 운영', 30),
  -- ── 근무 유연성 (flexibility) ──
  (@comp_id, 'flex_work', '선택적 근로시간제/시차출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '1개월 총 근로시간 범위 내 자율 결정, 시차출퇴근제로 출·퇴근시간 조정 가능', 40),
  (@comp_id, 'remote_work', '재택근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '부여받은 업무를 자택 등 지정된 장소에서 수행 가능', 41),
  -- ── 휴가 (time_off) ──
  (@comp_id, 'leave_general', '휴가제도(연차 외)', NULL, 'time_off',
   'est', NULL, TRUE, '기본 연차 부여 외에 건강검진·본인 생일 등 사유를 반영한 휴가제도 운영', 50),
  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '임직원 전용 콘도', NULL, 'leisure',
   'est', NULL, TRUE, '전국 각지 콘도 연중숙박서비스 지원(가족 구성원 포함)', 60),
  (@comp_id, 'travel_support', '휴양프로그램', NULL, 'leisure',
   'est', NULL, TRUE, '하계 성수기 등 특정 시즌에 운영되는 임직원·가족 휴양 프로그램', 61),
  (@comp_id, 'company_event', 'KB 패밀리데이', NULL, 'leisure',
   'est', NULL, TRUE, '그룹 사옥에 임직원과 가족을 초청해 문화시설을 체험하는 행사 지원', 62),
  (@comp_id, 'club', '동호인회 지원', NULL, 'leisure',
   'est', NULL, TRUE, '같은 취미를 공유하는 임직원 사내 동호인회 지원', 63),
  -- ── 보상 (compensation) ──
  (@comp_id, 'long_service_bonus', '장기근속기념품', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속 임직원의 공로에 대한 기념품 수여', 70),
  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '선택적 복지제도', NULL, 'perks',
   'est', NULL, TRUE, '본인 및 가족구성원에게 적합한 복지를 스스로 선택하는 선택적 복지제도 운영', 80),
  (@comp_id, 'meal', '사내식당·사내카페', NULL, 'perks',
   'est', NULL, TRUE, '전문영양사가 꾸린 식단의 사내식당 및 사내카페 운영', 81),
  (@comp_id, 'housing_support', '주거 지원', NULL, 'perks',
   'est', NULL, TRUE, '일정기간 무주택 요건 충족자에 한해 임차보증금 일부 지원', 82),
  (@comp_id, 'team_dinner', '부서 문화행사 지원', NULL, 'perks',
   'est', NULL, TRUE, '각 부서의 문화행사를 지원해 부서 내 화합을 도움', 83)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
