-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 동아에스티 복리후생 데이터 (신규 회사 — 웨이브 12)
-- 출처: AI 파싱 (2026-10-18)
-- URL: https://www.donga-st.com/html/board_report.php
-- badge: est
--
-- 참고:
--   정본 = 법인 자기 도메인 www.donga-st.com 의 보고서 목록(보고서 및 정책) 상시 페이지. 이 페이지가 싣는
--     2025 동아ST 지속가능경영보고서(국문 PDF · 2026년 9월 발행 · 보고 기간 2025.1.1~12.31 · 보고 범위 동아ST
--     본사 · 국내 생산본부 · 연구본부 · 영업권역)가 주 근거 — 45쪽 주요 복리후생 제도 표 · 44쪽 성과 평가 보상체계 ·
--     2025년 노사협의회 주요 성과 · 43쪽 교육 기관 파트너십. 영문판(같은 목록)은 해석 보조로만 봤다.
--   보조 1 = 동아쏘시오그룹 채용사이트의 동아ST 법인 전용 페이지 talent.dongasocio.com/kr/page/donga/HRF102020
--     복리후생 블록(LIFE · HEALTH · FAMILY · REFRESH · CULTURE · CAREER). 귀속 경로: 동아ST 홈 인재채용 버튼 →
--     그룹 채용사이트 → 계열사 목록 동아ST → HRF102020, 본문 제목 동아ST · 채용 문의 동아ST 전용 주소.
--     형제 에스티팜 페이지 HRF102040 과 항목이 달라(13 대 20 · 이름 다름) 공용 템플릿이 아니다 → 각주 없음.
--     이 호스트는 중간 인증서를 보내지 않는다 — 리프 AIA 의 Sectigo DV R36 을 받아 검증을 켠 채로 받았다.
--   보조 2 = OpenDART 2026 반기보고서(기재정정 20260820000424) · 2025 사업보고서(20260318001313) —
--     직원 등 현황 유연근무제도 사용 현황 표 · 별도 재무제표 주석(주식대응출연제도 · 기타장기종업원급여).
--   렌더 = 전부 서버 HTML · PDF 텍스트 · 공시 XML(헤드리스 없음). 사이트 키 사용 없음.
--   귀속 = 자기 발행 법인 단독 보고서 · 법인 전용 페이지 · 이 법인 공시 → 각주 없음.
--   금액 = stated 1행(복지포인트 연간 50만 원). 추정 0행. 나머지 NULL — 한도(입원 의료비 100만 원 · 대출 2천만 원) ·
--     1회성(결혼 · 출산 500만 원) · 주기가 사무직 2년에 1회라 연 금액이 아닌 검진 30만 원.
--   제외 = 법정(출산 초기 60일 유급 출산휴가 · 육아휴직 자녀 1인당 최대 1년 6개월 · 육아기 근로시간 단축) ·
--     업무 교육(신입사원 온보딩 · 리더십 · 직무 교육) · 급여성(제수당) · 대응 코드 없음(자율 복장 근무제) ·
--     은퇴설계 기본/심화과정(재취업지원 법정 범위와 갈리지 않아 판단 요청).
--   공고 근거 0행 / 전체 30행. SORT 섹션 순서 = 보고서 45쪽 표에 카테고리가 처음 나온 순서
--     growth · leisure · family · perks · time_off · flexibility · health · work_env, 표 밖 compensation 은 끝.
-- 검증 · 감사 판정 반영(2026-10-18): leave_general 이름과 서술의 최소 22일을 연간 휴가 최소 22일로(연차와 별개 휴가로 읽히지 않게) · 자녀 학자금 child_edu 에서 발행일 없는 채용 페이지의 고교 몫 걷기 · 비연고지 근무 지원 relocation 유지 · 항목 페이지 예외 2(통합 밖 리드 집행) — 최종 32행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('dong_a_st', '동아에스티',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '제약', 'D', 'https://www.donga-st.com/html/board_report.php');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'dong_a_st');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.donga-st.com/html/board_report.php'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 성장·교육 (growth) — 보고서 45쪽 자기개발 지원 · 43쪽 · 채용사이트 CAREER ──
  (@comp_id, 'lang', '사내 외국어 강좌', NULL, 'growth',
   'est', NULL, TRUE, '사내 외국어 강좌 지원 (2025 지속가능경영보고서 45쪽 주요 복리후생 제도 자기개발 지원 항목) — 강좌 언어·수강 대상·비용 부담 미기재', 10),
  (@comp_id, 'edu_support', '사이버 강좌·사내외 교육 지원', NULL, 'growth',
   'est', NULL, TRUE, '사이버 강좌 지원, 사내 및 사외교육 지원 (2025 지속가능경영보고서 45쪽 주요 복리후생 제도 자기개발 지원 항목), 전 임직원 대상 외부 기관(휴넷) 교육 포함 수석우니버지테트 통해 온라인·오프라인 콘텐츠 제공 (같은 보고서 43쪽 교육 기관 파트너십 항목), 사내외 교육 지원 (동아쏘시오그룹 채용사이트 동아ST 페이지 복리후생 CAREER 항목) — 지원 한도·대상 과정 미기재', 11),

  -- ── 여가·라이프 (leisure) — 보고서 45쪽 · 채용사이트 REFRESH · FAMILY · LIFE ──
  (@comp_id, 'resort', '콘도/리조트 지원', NULL, 'leisure',
   'est', NULL, TRUE, '한화, 켄싱턴, 대명, 리솜 등 총 44개점 지원 (2025 지속가능경영보고서 45쪽 주요 복리후생 제도 콘도/리조트 지원 항목), 법인 콘도/리조트 지원 (동아쏘시오그룹 채용사이트 동아ST 페이지 복리후생 REFRESH 항목) — 이용 횟수·본인 부담 미기재', 20),
  (@comp_id, 'company_event', '가족친화 프로그램·가족 초청 행사', NULL, 'leisure',
   'est', NULL, TRUE, '임직원 자녀 대상 여름방학 기간 「피닉스 캠프」 운영, 가족 초청 행사 등 진행 (2025 지속가능경영보고서 45쪽 주요 복리후생 제도 가족친화 프로그램 항목), 가족초청 행사 (동아쏘시오그룹 채용사이트 동아ST 페이지 복리후생 FAMILY 항목) — 행사 주기·참가 비용 미기재', 21),
  (@comp_id, 'club', '사내 동호회 지원', NULL, 'leisure',
   'est', NULL, TRUE, '다양한 사내 동호회 활동 지원 (2025 지속가능경영보고서 45쪽 주요 복리후생 제도 사내 동호회 지원 항목) — 동호회 종류·활동비 한도 미기재', 22),
  (@comp_id, 'welcome_kit', '웰컴키트 지급', NULL, 'leisure',
   'est', NULL, TRUE, '웰컴키트 지급 (동아쏘시오그룹 채용사이트 동아ST 페이지 복리후생 LIFE 항목) — 구성 품목·지급 대상 미기재', 23),

  -- ── 가족·돌봄 (family) — 보고서 45쪽 · 채용사이트 LIFE · FAMILY ──
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '사내 공제회를 통해 경조사 지원, 경조금 및 경조물품 지원 (2025 지속가능경영보고서 45쪽 주요 복리후생 제도 경조사 지원 항목), 결혼 시 인 당 500만 원의 가족지원금 지급 (같은 표 가족 지원 항목), 경조사 지원 · 결혼 축하금 지급 (동아쏘시오그룹 채용사이트 동아ST 페이지 복리후생 LIFE · FAMILY 항목) — 경조 구분별 금액 미기재', 30),
  (@comp_id, 'child_edu', '자녀 학자금', NULL, 'family',
   'est', NULL, TRUE, '대학교 학자금(8학기 전액, 자녀 수 제한 없음), 약학대학, 의과대학의 경우 1인당 12학기 까지 지원 (2025 지속가능경영보고서 45쪽 주요 복리후생 제도 자녀 학자금 지원 항목), 자녀 학자금 (동아쏘시오그룹 채용사이트 동아ST 페이지 복리후생 FAMILY 항목) — 지급 방식·신청 조건 미기재', 31),
  (@comp_id, 'parenting', '출산 가족지원금', NULL, 'family',
   'est', NULL, TRUE, '출산 시 인 당 500만 원의 가족지원금 지급 (2025 지속가능경영보고서 45쪽 주요 복리후생 제도 가족 지원 항목), 출산 축하금 지급 (동아쏘시오그룹 채용사이트 동아ST 페이지 복리후생 FAMILY 항목) — 지급 시기 미기재', 32),

  -- ── 경제적 부가혜택 (perks) — 보고서 45쪽 · 채용사이트 LIFE ──
  (@comp_id, 'welfare_point', '복지포인트 (연간 50만 원)', 50, 'perks',
   'est', '복지포인트 지급(연간 50만 원), 온라인 복지 플랫폼(이지웰)을 통해 이용 (2025 지속가능경영보고서 45쪽 주요 복리후생 제도 임직원 복지몰 운영 항목), 복지포인트 지급 (동아쏘시오그룹 채용사이트 동아ST 페이지 LIFE 항목)', FALSE, NULL, 40),
  (@comp_id, 'snack_bar', '사내 카페테리아', NULL, 'perks',
   'est', NULL, TRUE, '사내 카페테리아 운영 (2025 지속가능경영보고서 45쪽 주요 복리후생 제도 임직원 복지몰 운영 항목) — 운영 사업장·제공 품목·이용 비용 미기재', 41),
  (@comp_id, 'housing_loan', '사내 대출 (전세자금·생활안정자금)', NULL, 'perks',
   'est', NULL, TRUE, '전세자금 및 생활안정자금 대출, 금리 연 2%, 2천만 원 한도(단 생활안정자금은 3천만 원으로 한도 상향), 최장 36개월 원리금 분할상환 (2025 지속가능경영보고서 45쪽 주요 복리후생 제도 사내 대출 항목), 사내대출 (동아쏘시오그룹 채용사이트 동아ST 페이지 복리후생 LIFE 항목) — 대출 자격 요건 미기재', 42),
  (@comp_id, 'discount', '자사몰 임직원 할인', NULL, 'perks',
   'est', NULL, TRUE, '자사몰 임직원 할인 (동아쏘시오그룹 채용사이트 동아ST 페이지 복리후생 LIFE 항목) — 할인율·대상 품목 미기재', 43),
  (@comp_id, 'commute_subsidy', '통근버스 운영', NULL, 'perks',
   'est', NULL, TRUE, '통근버스 운영 (동아쏘시오그룹 채용사이트 동아ST 페이지 복리후생 LIFE 항목) — 운행 사업장·노선·이용료 미기재', 44),
  (@comp_id, 'relocation', '비연고지 근무 지원', NULL, 'perks',
   'est', NULL, TRUE, '비연고지 근무 지원 (동아쏘시오그룹 채용사이트 동아ST 페이지 복리후생 LIFE 항목) — 지원 형태·대상·금액 미기재', 45),

  -- ── 휴가 (time_off) — 보고서 45쪽 휴가제도 · 44쪽 · 채용사이트 CULTURE · REFRESH ──
  (@comp_id, 'leave_general', '연간 휴가 최소 22일·단체휴무·유급 보건휴가', NULL, 'time_off',
   'est', NULL, TRUE, '연간 유급휴가 최소 22일 운영, 부문별 하계휴가 유연제 운영 (2025 지속가능경영보고서 45쪽 주요 복리후생 제도 휴가제도 항목), 유급 보건휴가 시행 (같은 표 워라밸 증진 항목), 2026년 단체 휴무일 확정 (같은 보고서 44쪽 2025년 노사협의회 주요 성과 항목), 만근시 22일 유급휴가, 하계/동계/샌드위치 휴일 단체휴무 (동아쏘시오그룹 채용사이트 동아ST 페이지 복리후생 CULTURE 항목) — 단체휴무의 연차 사용일인지·일수·유급 여부, 보건휴가 사용 조건 미기재', 50),
  (@comp_id, 'long_service_leave', '장기근속 안식휴가', NULL, 'time_off',
   'est', NULL, TRUE, '장기 근속 안식휴가 운영 (2025 지속가능경영보고서 45쪽 주요 복리후생 제도 휴가제도 항목), 장기근속 시 안식휴가 (동아쏘시오그룹 채용사이트 동아ST 페이지 복리후생 REFRESH 항목) — 근속 기준·휴가 일수·유급 여부 미기재', 51),

  -- ── 근무 유연성 (flexibility) — 보고서 45쪽 워라밸 증진 · 공시 유연근무제도 사용 현황 ──
  (@comp_id, 'family_day', '패밀리데이 (월 1회 조기 퇴근)', NULL, 'flexibility',
   'est', NULL, TRUE, '월 1회 패밀리데이 조기 퇴근 (2025 지속가능경영보고서 45쪽 주요 복리후생 제도 워라밸 증진 항목), 월 1회 패밀리데이 조기퇴근 (동아쏘시오그룹 채용사이트 동아ST 페이지 복리후생 CULTURE 항목) — 퇴근 시각 미기재', 60),
  (@comp_id, 'flex_work', '유연근무제도', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제도 운영 (2025 지속가능경영보고서 45쪽 주요 복리후생 제도 워라밸 증진 항목), 유연근무제 활용, 선택근무제 사용자 수 335명 (2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 근무 시간대·대상 직무 미기재', 61),
  (@comp_id, 'pc_off', 'PC-OFF제', NULL, 'flexibility',
   'est', NULL, TRUE, 'PC-OFF제 운영 (2025 지속가능경영보고서 45쪽 주요 복리후생 제도 워라밸 증진 항목) — 적용 시각·예외 승인 방식 미기재', 62),
  (@comp_id, 'remote_work', '재택근무', NULL, 'flexibility',
   'est', NULL, TRUE, '재택근무 운영 (2025 지속가능경영보고서 45쪽 주요 복리후생 제도 워라밸 증진 항목), 원격근무제(재택근무 포함) 사용자 수 116명 (2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 63),
  (@comp_id, 'satellite_office', '거점오피스', NULL, 'flexibility',
   'est', NULL, TRUE, '거점오피스 운영 (2025 지속가능경영보고서 45쪽 주요 복리후생 제도 워라밸 증진 항목) — 거점 위치·이용 대상 미기재', 64),

  -- ── 건강·의료 (health) — 보고서 45쪽 · 44쪽 · 채용사이트 HEALTH ──
  (@comp_id, 'medical', '본인 입원 의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '연간 100만 원 한도의 본인 입원 의료비 지원 (2025 지속가능경영보고서 45쪽 주요 복리후생 제도 의료비 및 단체보험 항목), 입퇴원 의료비 (동아쏘시오그룹 채용사이트 동아ST 페이지 복리후생 HEALTH 항목) — 지원 비율 미기재', 70),
  (@comp_id, 'insurance', '본인 및 배우자 단체보험', NULL, 'health',
   'est', NULL, TRUE, '중증질환에 대한 직원 및 배우자 보험 가입 (2025 지속가능경영보고서 45쪽 주요 복리후생 제도 의료비 및 단체보험 항목), 본인 및 배우자 단체보험 (동아쏘시오그룹 채용사이트 동아ST 페이지 복리후생 HEALTH 항목) — 보장 범위·보험료 부담 미기재', 71),
  (@comp_id, 'health_check', '종합건강검진 지원', NULL, 'health',
   'est', NULL, TRUE, '전 직원 30만 원 종합건강검진 지원, 사무직 2년에 1회, 비사무직 만 45세 이상(연1회)·만 45세 미만(격년 1회) (2025 지속가능경영보고서 45쪽 주요 복리후생 제도 건강검진 항목), 종합건강검진 지원 대상을 기존 45세 이상에서 전 연령으로 확대 (같은 보고서 44쪽 2025년 노사협의회 주요 성과 항목), 건강검진패키지 지원 (동아쏘시오그룹 채용사이트 동아ST 페이지 복리후생 HEALTH 항목) — 검진 항목·가족 검진 여부 미기재', 72),
  (@comp_id, 'fitness', '사내헬스장 (Wings)·GX 프로그램', NULL, 'health',
   'est', NULL, TRUE, '사내헬스장(Wings) 운영 및 임직원 대상 GX 프로그램 운영 (2025 지속가능경영보고서 45쪽 주요 복리후생 제도 건강한 일터 만들기 항목) — 운영 사업장·이용 비용 미기재', 73),

  -- ── 근무환경 (work_env) — 보고서 45쪽 모성보호 · 채용사이트 LIFE ──
  (@comp_id, 'nap_room', '모유수유시설 (용인연구소)', NULL, 'work_env',
   'est', NULL, TRUE, '용인연구소 모유수유시설 운영 (2025 지속가능경영보고서 45쪽 주요 복리후생 제도 모성보호 항목) — 시설 규모·운영 시간 미기재', 80),
  (@comp_id, 'dormitory', '기숙사 운영', NULL, 'work_env',
   'est', NULL, TRUE, '기숙사 운영 (동아쏘시오그룹 채용사이트 동아ST 페이지 복리후생 LIFE 항목) — 입주 자격·운영 사업장·본인 부담 미기재', 81),

  -- ── 보상·금전 (compensation) — 보고서 44쪽 성과 평가 및 보상 · 공시 재무제표 주석 ──
  (@comp_id, 'incentive', '차등 성과급', NULL, 'compensation',
   'est', NULL, TRUE, '회사 경영성과 연동, 부서 및 개인 성과를 반영하여 차등 지급하는 차등 성과급, 성과 평가 결과를 반영하여 임금 및 인센티브를 차등 지급하는 성과 연계 보상 제도 운영 (2025 지속가능경영보고서 44쪽 성과 평가 보상체계 항목) — 지급 기준·지급률 미기재', 90),
  (@comp_id, 'excellence_award', '정기 포상 (공로상·도전 및 성공사례 시상)', NULL, 'compensation',
   'est', NULL, TRUE, '개인공로상, 단체공로상, 도전 및 성공사례 시상금 지급, 영업·비영업을 포함한 전 분야 (2025 지속가능경영보고서 44쪽 성과 평가 보상체계 정기 포상 항목), 매년 도전 및 성공 사례 공모전을 통해 우수 성과자를 선발하고 성공 사례 포상 (같은 쪽 성과 평가 및 보상 항목) — 시상 규모·시상금 금액 미기재', 91),
  (@comp_id, 'stock_option', '우리사주조합 대응 출연', NULL, 'compensation',
   'est', NULL, TRUE, '종업원에게 주식매수제도에 참여할 수 있도록 우리사주조합을 통한 대응 출연 제도, 당기(2025년) 종업원 출연금액의 50%를 대응 출연 (2025 사업보고서 별도 재무제표 주석 주식대응출연제도 항목, 2026 반기보고서 같은 주석 항목) — 출연 한도·인출 가능 시점 미기재', 92),
  (@comp_id, 'long_service_bonus', '장기근속 장기종업원급여', NULL, 'compensation',
   'est', NULL, TRUE, '일정 기간 이상 근속한 종업원에게 장기종업원급여 제공 (2025 사업보고서 별도 재무제표 주석 기타장기종업원급여 항목) — 근속 기준·급부 형태·금액 미기재', 93)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
