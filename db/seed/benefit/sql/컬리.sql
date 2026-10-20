-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 컬리 복리후생 데이터 (신규 회사 — 웨이브 13)
-- 출처: AI 파싱 (2026-10-20)
-- URL: https://kurly.career.greetinghr.com/ko/life
-- badge: est
--
-- 참고:
--   정본 = 주식회사 컬리 채용 사이트(그리팅 워크스페이스 kurly) Life 페이지 복리후생 절.
--     www.kurly.com 앱 번들이 이 채용 사이트를 Kurly Careers 로 링크하고, 사이트 꼬리말 · 개인정보 동의문의
--     주체가 주식회사 컬리(사업자등록번호 261-81-23567 = OpenDART bizr_no 와 같음)라 이 법인 것으로 본다.
--     항목 8개는 이미지 1장(1920x800 PNG · 2026-06-29 업로드) 안에만 있다 — 판독 사본 image_transcript.txt.
--   보조 = OpenDART 2026 반기보고서(20260812000464) 유연근무제도 사용 현황 표 ·
--     2025 사업보고서(20260327000997) 별도 재무제표 주석 기타장기종업원급여.
--   렌더 방식 = 원본 HTML 의 __NEXT_DATA__ (getCareerPageDetail) 에서 이미지 주소를 읽고 이미지를 판독 · 헤드리스 렌더 없음.
--   귀속 = 법인 전용 채용 사이트 · 각주 없음. 자회사 컬리넥스트마일 출처는 쓰지 않았다.
--   금액 = 전 행 NULL(원문에 숫자 금액 없음).
--   제외 = 공시 선택근무제(세 기간 모두 -) · RSU 와 주식매수선택권(재량 부여) · 임원 보수 칸 · 육아지원제도 표(법정).
--   공고 근거 0행 / 전체 13행.
--   SORT 섹션 순서 = perks 10 · compensation 20 · time_off 30 · work_env 40 · leisure 50 · flexibility 60 · family 70 · health 80.
-- 검증 · 감사 판정 반영(2026-10-20): 행 조치 없음 · 수집본 13행 그대로 · 이미지 8칸 재판독 일치 · 격년 건강검진 health_check 유지(법정 검진 이름 아님) · 항목 페이지 예외 2(통합 밖 리드 집행) — 최종 13행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('kurly', '컬리',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '유통', 'K', 'https://kurly.career.greetinghr.com/ko/life');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'kurly');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://kurly.career.greetinghr.com/ko/life'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 생활 · 금융 (perks) — 채용 사이트 Life 복리후생 ──
  (@comp_id, 'welfare_point', '컬리 적립금 (입사 100일 축하·분기별)', NULL, 'perks',
   'est', NULL, TRUE, '컬리 적립금 지급 중 입사 100일 축하 및 분기별 적립금 (공식 채용 페이지 Life 복리후생 컬리 적립금 지급 항목) — 적립금 금액·사용처 미기재', 10),
  (@comp_id, 'birthday_gift', '생일 적립금', NULL, 'perks',
   'est', NULL, TRUE, '컬리 적립금 지급 중 생일 적립금 (공식 채용 페이지 Life 복리후생 컬리 적립금 지급 항목) — 적립금 금액 미기재', 11),
  -- ── 보상 (compensation) — 채용 사이트 Life 복리후생 · 2025 사업보고서 ──
  (@comp_id, 'holiday_gift', '명절 적립금', NULL, 'compensation',
   'est', NULL, TRUE, '컬리 적립금 지급 중 명절 적립금 (공식 채용 페이지 Life 복리후생 컬리 적립금 지급 항목) — 적립금 금액·지급 명절 미기재', 20),
  (@comp_id, 'long_service_bonus', '장기근속 임직원 장기종업원급여', NULL, 'compensation',
   'est', NULL, TRUE, '장기 근속 임직원에게 장기종업원급여 제공 (2025 사업보고서 별도 재무제표 주석 기타장기종업원급여 항목) — 근속 기준·급부 형태·금액 미기재', 21),
  -- ── 휴가 (time_off) — 채용 사이트 Life 복리후생 ──
  (@comp_id, 'leave_general', '매월 퍼플데이 (유급 반일 휴가)', NULL, 'time_off',
   'est', NULL, TRUE, '일상의 리프레시를 위해 매월 퍼플데이 제도 운영, 연차 외 추가 0.5일 유급 휴가 제공 (공식 채용 페이지 Life 복리후생 매월 퍼플데이 제도 운영 항목)', 30),
  (@comp_id, 'long_service_leave', '장기근속 리프레시 (유급휴가·휴가비)', NULL, 'time_off',
   'est', NULL, TRUE, '함께 해주심에 감사의 의미를 담아 장기근속 리프레시 유급휴가, 휴가비 지원 (공식 채용 페이지 Life 복리후생 장기근속 리프레시 항목) — 근속 기준·휴가 일수·휴가비 금액 미기재', 31),
  -- ── 업무 환경 (work_env) — 채용 사이트 Life 복리후생 ──
  (@comp_id, 'work_tools', 'AI Tool 제공', NULL, 'work_env',
   'est', NULL, TRUE, '업무 효율성을 높일 수 있도록 Gemini, Claude Premium 엔터프라이즈 제공 (공식 채용 페이지 Life 복리후생 AI Tool 제공 항목)', 40),
  -- ── 여가 (leisure) — 채용 사이트 Life 복리후생 ──
  (@comp_id, 'welcome_kit', '웰컴키트 선물', NULL, 'leisure',
   'est', NULL, TRUE, '입사 첫 날 축하의 의미를 담아 웰컴키트 선물 (공식 채용 페이지 Life 복리후생 웰컴키트 선물 항목) — 구성 품목 미기재', 50),
  -- ── 근무 유연성 (flexibility) — 채용 사이트 Life 복리후생 · 2026 반기보고서 ──
  (@comp_id, 'flex_work', '시차 출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '일과 생활의 균형을 위해 시차 출퇴근제 운영, 오전 8시 ~ 10시 내 30분 단위 선택 (공식 채용 페이지 Life 복리후생 시차 출퇴근제 운영 항목), 유연근무제 활용 및 시차출퇴근제 (2026 반기보고서 유연근무제도 사용 현황 항목)', 60),
  (@comp_id, 'remote_work', '원격근무제(재택근무 포함)', NULL, 'flexibility',
   'est', NULL, TRUE, '원격근무제(재택근무 포함) (2026 반기보고서 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 61),
  -- ── 가족 (family) — 채용 사이트 Life 복리후생 ──
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '기쁨은 축복하고 슬픔은 위로하는 경조사 지원, 경조사 축하금/조의금, 유급휴가 (공식 채용 페이지 Life 복리후생 경조사 지원 항목) — 경조 범위·금액·휴가 일수 미기재', 70),
  -- ── 건강 (health) — 채용 사이트 Life 복리후생 ──
  (@comp_id, 'insurance', '단체상해보험', NULL, 'health',
   'est', NULL, TRUE, '건강한 신체를 위해 단체상해보험 (공식 채용 페이지 Life 복리후생 의료비&건강검진 지원 항목) — 보장 범위·가족 포함 여부 미기재', 80),
  (@comp_id, 'health_check', '격년 건강검진 지원', NULL, 'health',
   'est', NULL, TRUE, '건강한 신체를 위해 격년 단위 건강검진 지원 (공식 채용 페이지 Life 복리후생 의료비&건강검진 지원 항목) — 검진 항목·비용 지원 범위 미기재', 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
