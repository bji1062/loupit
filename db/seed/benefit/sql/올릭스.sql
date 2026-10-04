-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 올릭스 복리후생 데이터
-- 출처: AI 파싱 (2026-10-02)
-- URL: https://olixpharma.career.greetinghr.com/ko/culture
-- badge: est
--
-- 참고:
--   정본은 공식 홈(www.olixpharma.com) 헤더 Careers 링크가 가리키는 브랜드 채용 사이트(그리팅,
--   워크스페이스명 올릭스 주식회사 · 꼬리말 주소 = 올릭스 R&D Center)의 헤더 메뉴 근무 환경 페이지다.
--   국문 상시 페이지라 정본으로 골랐다. Next.js 서버 렌더라 원본 HTML 과 __NEXT_DATA__ 에 본문이 있다 — 헤드리스 렌더 없음.
--   보조 1 = 같은 사이트 채용 공고 5건(/ko/o/186257 상시채용 외)의 보상 및 복리후생 블록 — 5건 문안이 글자까지 같다.
--   보조 2 = 자기 도메인 ESG Social 페이지 개인 건강관리 절 · 영문 헤더 메뉴 Work Environment 페이지(캔틴 다과).
--   국문 자기 도메인 careers 메뉴는 HTML 주석 처리돼 있고 해당 경로가 404 라 근거로 쓰지 않았다.
--   귀속: 법인 단독 채용 사이트 — 그룹 각주 없음. 직원 76명(DART 2025) — 1,000인 미만.
--   법정 제도: 스톡옵션은 복지가 아니라 싣지 않았다. 사내 어학강좌는 2026-10-04 규칙 8 개정으로 lang 행(SORT 32)으로 싣는다.
--   금액: 원문 금액 0 · 구본 추정 승계 5(holiday_gift 20 · health_check 100 · insurance 30 · resort 50 · snack_bar 20 — 모두 틀 값, NOTE 끝에 (추정)).
--   구본에서 뺀 행: fitness · event · books · club · housing_support · parking(lang 은 2026-10-04 되살림).
--   재코딩 1: leave_general → refresh_leave(2026-10-04 연간 휴가 총 20일은 연차 일수라 leave_general 로 되돌림 — 기준 18 개정). 신규 코드 0.
-- 재수집(2026-10-02): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-02, RV-3-5): refresh_leave 이름과 서술을 연간 휴가 총 20일로 바꿈(일수는 총량이지 추가분이 아님) — 최종 13행
-- 후속 정리 2(2026-10-04, R-3): 사용자가 정한 복지 범위 규칙 개정(규칙 8 · 기준 13 · 기준 18 · 기준 20 · 기준 23)과 코퍼스 판정을 반영 — 새 행 1(lang) · 재코딩 1(refresh_leave → leave_general) — 최종 14행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('olix', '올릭스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '바이오', 'O', 'https://olixpharma.career.greetinghr.com/ko/culture');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'olix');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://olixpharma.career.greetinghr.com/ko/culture'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 시간·휴가 (time_off) — 근무 환경 Work & Life Balance · 채용 공고 ──
  (@comp_id, 'leave_general', '연간 휴가 총 20일', NULL, 'time_off',
   'est', NULL, TRUE, '휴식을 통해 업무에 더욱 몰입할 수 있도록 연간 휴가 총 20일 부여 (공식 채용 사이트 근무 환경 Work & Life Balance 항목 · 채용 공고 보상 및 복리후생 항목) — 근속에 따른 일수 변동·사용 방식 미기재', 10),
  (@comp_id, 'long_service_leave', '장기근무 리프레시 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '장기근무 시 리프레시 휴가 부여 (공식 채용 공고 보상 및 복리후생 항목) — 근속 기준·휴가 일수 미기재', 11),

  -- ── 유연근무 (flexibility) — 근무 환경 Work & Life Balance ──
  (@comp_id, 'flex_work', '시차 출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '일·가정 양립 지원을 위한 시차 출퇴근제 운영 (공식 채용 사이트 근무 환경 Work & Life Balance 항목 · 공식 홈페이지 영문 Work Environment 항목) — 출퇴근 선택 시간대 미기재', 20),

  -- ── 성장·커리어 (growth) — 근무 환경 Work & Life Balance · 채용 공고 ──
  (@comp_id, 'conference', '사외 직무교육·국내외 세미나', NULL, 'growth',
   'est', NULL, TRUE, '지속적인 자기개발을 위한 사외 직무교육·국내외 세미나 참여 기회 제공, 연구성과 우수자의 국외 학회 참석 기회 부여 (공식 채용 사이트 근무 환경 Work & Life Balance 항목 · 채용 공고 보상 및 복리후생 항목) — 비용 지원 범위·횟수 미기재', 30),
  (@comp_id, 'mba', '학위과정·해외연수', NULL, 'growth',
   'est', NULL, TRUE, '역량개발을 위한 학위과정 기회 제공, 연구성과 우수자의 해외연수(미국법인 및 해외 협력기관) 기회 부여 (공식 채용 사이트 근무 환경 Work & Life Balance 항목 · 채용 공고 보상 및 복리후생 항목) — 학비 지원 여부·선발 기준 미기재', 31),
  (@comp_id, 'lang', '사내 어학강좌', NULL, 'growth',
   'est', NULL, TRUE, '지속적인 자기개발을 위한 사내 어학강좌 운영 (공식 채용 사이트 근무 환경 Work & Life Balance 항목), 어학능력 향상을 위한 학습 기회 (같은 사이트 FAQ) — 강좌 언어·수강 방식·비용 부담 미기재', 32),

  -- ── 보상·금전 (compensation) — 채용 공고 보상 및 복리후생 ──
  (@comp_id, 'incentive', '성과급', NULL, 'compensation',
   'est', NULL, TRUE, '성과에 따른 성과급 (공식 채용 공고 보상 및 복리후생 항목). 공식 채용 사이트 회사 소개는 뛰어난 성과를 창출한 우수인재에게 개인 성과급·경영 성과급 제공으로 기재 — 지급 기준·지급률 미기재', 40),
  (@comp_id, 'holiday_gift', '명절 상품권', 20, 'compensation',
   'est', '명절 상품권 지급 (공식 채용 공고 보상 및 복리후생 기타 항목) — 지급 금액·횟수 미기재 (추정)', FALSE, NULL, 41),

  -- ── 경제적 부가혜택 (perks) — 채용 공고 · 영문 Work Environment ──
  (@comp_id, 'welfare_point', '선택적 복지제도 (페이코 복지포인트)', NULL, 'perks',
   'est', NULL, TRUE, '선택적 복지제도(페이코 복지포인트) 운영 (공식 채용 공고 보상 및 복리후생 기타 항목) — 연간 배정 포인트 미기재', 50),
  (@comp_id, 'snack_bar', '사무실 캔틴 다과 비치', 20, 'perks',
   'est', '모든 사무실에 설치된 캔틴에 다양한 다과 비치 (공식 홈페이지 영문 Work Environment 항목) — 운영 방식·비용 미기재 (추정)', FALSE, NULL, 51),

  -- ── 건강·의료 (health) — 채용 공고 · ESG Social 개인 건강관리 ──
  (@comp_id, 'insurance', '단체보험', 30, 'health',
   'est', '단체보험 (공식 채용 공고 보상 및 복리후생 기타 항목) — 보장 범위·가족 포함 여부 미기재 (추정)', FALSE, NULL, 60),
  (@comp_id, 'health_check', '연 1회 건강검진', 100, 'health',
   'est', '연 1회 건강검진 (공식 채용 공고 보상 및 복리후생 기타 항목 · 공식 홈페이지 ESG Social 개인 건강관리 항목) — 검진 기관·가족 포함 여부 미기재 (추정)', FALSE, NULL, 61),
  (@comp_id, 'clinic', '임직원 건강상담 (월 1회)', NULL, 'health',
   'est', NULL, TRUE, '임직원 건강상담 월 1회 (공식 홈페이지 ESG Social 개인 건강관리 항목) — 상담 인력·장소 미기재', 62),

  -- ── 여가·라이프 (leisure) — 채용 공고 ──
  (@comp_id, 'resort', '법인콘도 지원', 50, 'leisure',
   'est', '법인콘도 지원 (공식 채용 공고 보상 및 복리후생 기타 항목) — 이용 일수·지원 방식 미기재 (추정)', FALSE, NULL, 70)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
