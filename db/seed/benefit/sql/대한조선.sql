-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 대한조선 복리후생 데이터 (신규 회사 — 웨이브 9)
-- 출처: AI 파싱 (2026-10-15)
-- URL: https://www.daehanship.com/personnelsys3
-- badge: est
--
-- 참고:
--   정본 = 자기 도메인 인재채용 > 인사제도 > 복리후생(personnelsys3 · SSR · 카드 9칸).
--   보조 = 2024 대한조선 지속가능경영보고서(자기 도메인 esg3 다운로드 idx 3565 · 2025-07 발행 · 보고 기간 2024 · 법인 단독)
--     64~65쪽 복리후생 표 · 68~69쪽 인사제도 직무역량 교육 · 112~113쪽 보건 경영 표,
--     같은 도메인 인사제도 인재육성 커리큘럼 이미지(SVG 판독) · 2026년 신입/경력사원 상시 모집 공고 본문 이미지(연봉 칸).
--   렌더 = 원본 HTML · 이미지 2장 판독(SVG 는 로컬 오프라인 렌더).
--   귀속 = 법인 자기 도메인 · 법인 단독 보고서 → 각주 없음. 최대주주 KHI 계열 형제 코퍼스 0.
--   금액 = 금액 행 0(의료비 50%·전액은 비율 · 나머지 숫자 없음).
--   제외 = 법정(출산 전후 휴가 90/120일 · 주 40시간 · 연차수당 · 육아휴직 지표) · 본인 연차 사용 Refresh 휴가 ·
--     업무 교육(입문 · 직무순환 · 리더/핵심인재 · 사외 위탁 · 직무 e-러닝 · 독서 통신 · 산학 · 기술교육원) ·
--     협력사 대상 복지 · 급여성(자격수당 · 성과연동형 임금체계) · 혹서기 휴게시간 연장 · 혹서기/혹한기 물품(판단 요청) ·
--     공고 직무내용의 사내식당 · 우리사주조합(보호예수 표 한 칸) · 직무스트레스 예방 프로그램(계획).
--   공고 근거 3행 / 전체 19행(성과급 · 귀향비 · 휴가비).
--   SORT 섹션 = family 10 · work_env 20 · health 30 · time_off 40 · perks 50 · growth 60 · leisure 70 · flexibility 80 · compensation 90.
-- 검증 · 감사 판정 반영(2026-10-15): 패밀리데이 이름 · 서술에 17시 퇴근과 정규 근무시간(리드 판정 135) — 최종 19행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('daehan_shipbuilding', '대한조선',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '조선', 'D', 'https://www.daehanship.com/personnelsys3');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'daehan_shipbuilding');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.daehanship.com/personnelsys3'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 가족 (family) — 공식 채용 페이지 복리후생 + 2024 지속가능경영보고서 ──
  (@comp_id, 'child_edu', '임직원 자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '미취학, 대학교 학자금 지원 (공식 채용 페이지 복리후생 임직원 자녀 학자금 지원 항목, 2024 지속가능경영보고서 64~65쪽 복리후생 자녀 학자금 지원 항목) — 지원 금액·한도 미기재', 10),
  (@comp_id, 'parenting', '다자녀 양육비 지원', NULL, 'family',
   'est', NULL, TRUE, '다자녀 양육비 지원 (공식 채용 페이지 복리후생 항목, 2024 지속가능경영보고서 64~65쪽 복리후생 자녀 학자금 지원 항목) — 대상 자녀 수·지원 금액 미기재', 11),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '휴가, 경조금, 화환 및 조사 물품 지원 (2024 지속가능경영보고서 64~65쪽 복리후생 경조사 지원 항목), 휴가, 경조금, 조사물품 지원 (공식 채용 페이지 복리후생 경조사 지원 항목) — 경조사별 금액·휴가 일수 미기재', 12),
  (@comp_id, 'childcare', '직장 어린이집 운영', NULL, 'family',
   'est', NULL, TRUE, '직장 어린이집 운영 (공식 채용 페이지 복리후생 항목), 목포대 신해양산업단지 캠퍼스 내 공동 직장어린이집 운영 (2024 지속가능경영보고서 64~65쪽 복리후생 직장 어린이집 운영 항목) — 정원·이용 조건 미기재', 13),
  -- ── 근무 환경 (work_env) — 공식 채용 페이지 복리후생 + 2024 지속가능경영보고서 ──
  (@comp_id, 'dormitory', '기숙사 운영', NULL, 'work_env',
   'est', NULL, TRUE, '독신자 숙소 제공 (공식 채용 페이지 복리후생 기숙사 운영 항목), 임직원 숙소 제공 (2024 지속가능경영보고서 64~65쪽 복리후생 기숙사 운영 항목) — 입주 조건·비용 부담 미기재', 20),
  -- ── 건강 (health) — 공식 채용 페이지 복리후생 + 2024 지속가능경영보고서 ──
  (@comp_id, 'medical', '의료비 지원 (본인·가족)', NULL, 'health',
   'est', NULL, TRUE, '본인 및 가족 의료비 지원 (공식 채용 페이지 복리후생 의료비 지원 항목), 임직원 가족의 입원 진료비 중 본인 부담금의 50% 지원 · 직원 본인의 외래 진료비 및 약값 본인 부담금 전액 지원 (2024 지속가능경영보고서 64~65쪽 복리후생 의료비 지원 항목) — 연간 한도 미기재', 30),
  (@comp_id, 'clinic', '건강관리실', NULL, 'health',
   'est', NULL, TRUE, '건강관리실 누적 이용 실적 2024년 4,446명 (2024 지속가능경영보고서 112~113쪽 보건 경영 표 의료서비스 이용 인원 항목) — 운영 시간·진료 범위 미기재', 31),
  -- ── 휴가 (time_off) — 공식 채용 페이지 복리후생 + 2024 지속가능경영보고서 ──
  (@comp_id, 'long_service_leave', '장기근속자 휴가 및 포상금', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속자 휴가 및 포상금 지원 (공식 채용 페이지 복리후생 항목), 장기근속자 휴가 및 포상금 지급 (2024 지속가능경영보고서 64~65쪽 복리후생 장기근속 항목) — 근속 기준·휴가 일수·포상 금액 미기재', 40),
  (@comp_id, 'summer_leave', '하계휴가', NULL, 'time_off',
   'est', NULL, TRUE, '하계휴가 1주일 부여 (2024 지속가능경영보고서 64~65쪽 복리후생 하계휴가 및 혹서기 휴게시간 연장 항목) — 본인 휴가 사용일인지·유급 여부 미기재', 41),
  (@comp_id, 'leave_general', '유급 보건 휴가 (여직원)', NULL, 'time_off',
   'est', NULL, TRUE, '여직원 대상 월 1일 유급휴가 부여 (2024 지속가능경영보고서 64~65쪽 복리후생 보건 휴가 항목) — 사용 절차 미기재', 42),
  -- ── 생활 · 금융 (perks) — 공식 채용 페이지 복리후생 + 2024 지속가능경영보고서 ──
  (@comp_id, 'commute_subsidy', '출퇴근 버스 운영', NULL, 'perks',
   'est', NULL, TRUE, '출퇴근 버스 운영 (공식 채용 페이지 복리후생 항목), 평일/주말 출퇴근 버스 운영, 귀향 버스(부산) 운영, 야간 버스 운영 (2024 지속가능경영보고서 64~65쪽 복리후생 출퇴근 버스 운영 항목) — 노선·이용 비용 미기재', 50),
  -- ── 성장 · 교육 (growth) — 공식 채용 페이지 복리후생 · 인재육성 + 2024 지속가능경영보고서 ──
  (@comp_id, 'self_development', '국가자격 취득 지원', NULL, 'growth',
   'est', NULL, TRUE, '취득 축하금, 응시료 지원 (공식 채용 페이지 복리후생 국가자격 취득 지원 항목, 2024 지속가능경영보고서 64~65쪽 복리후생 국가 자격 취득 지원 항목) — 대상 자격·금액 미기재', 60),
  (@comp_id, 'lang', '사내 영어회화 과정', NULL, 'growth',
   'est', NULL, TRUE, '사내 영어회화 과정 운영 (공식 채용 페이지 인재육성 커리큘럼 직무 역량 향상 교육 항목), 사이버 교육 외국어 자율적 교육 (2024 지속가능경영보고서 68~69쪽 인사제도 직무역량 교육 항목) — 수강 대상·비용 부담 미기재', 61),
  (@comp_id, 'edu_support', '사이버 교육 (휴넷 HRD-Flex)', NULL, 'growth',
   'est', NULL, TRUE, '사이버 교육 휴넷 HRD-Flex 849과정, 인문 · 자격증 등 자율적 교육 (2024 지속가능경영보고서 68~69쪽 인사제도 직무역량 교육 항목) — 수강 한도·비용 부담 미기재', 62),
  -- ── 여가 (leisure) — 2024 지속가능경영보고서 + 채용 공고 ──
  (@comp_id, 'club', '사내 동호회 활동 지원', NULL, 'leisure',
   'est', NULL, TRUE, '설립/운영경비 지원 (2024 지속가능경영보고서 64~65쪽 복리후생 사내 동호회 활동 지원 항목) — 지원 금액·동호회 수 미기재', 70),
  (@comp_id, 'summer_vacation_subsidy', '휴가비', NULL, 'leisure',
   'est', NULL, TRUE, '연봉 외 별도 휴가비 (2026년 상시 모집 공식 채용 공고 연봉 항목) — 지급 시기·금액 미기재', 71),
  -- ── 근무 유연성 (flexibility) — 2024 지속가능경영보고서 ──
  (@comp_id, 'family_day', '패밀리데이 (17시 퇴근)', NULL, 'flexibility',
   'est', NULL, TRUE, '매월 마지막 주 금요일 및 동절기 금요일 격주 17시 퇴근 (2024 지속가능경영보고서 64~65쪽 복리후생 패밀리데이 운영 항목), 평일 08시부터 17시까지 근무 (공식 채용 페이지 인사제도 근무제도 항목) — 연장근무 제한 여부·적용 대상 직무 미기재', 80),
  -- ── 보상 (compensation) — 채용 공고 ──
  (@comp_id, 'incentive', '성과급', NULL, 'compensation',
   'est', NULL, TRUE, '연봉 외 별도 성과급 (2026년 상시 모집 공식 채용 공고 연봉 항목) — 지급 기준·지급률 미기재', 90),
  (@comp_id, 'holiday_gift', '귀향비', NULL, 'compensation',
   'est', NULL, TRUE, '연봉 외 별도 귀향비 (2026년 상시 모집 공식 채용 공고 연봉 항목) — 지급 시기·금액 미기재', 91)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
