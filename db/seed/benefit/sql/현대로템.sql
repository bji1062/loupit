-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 현대로템 복리후생 데이터
-- 출처: AI 파싱 (2026-10-02)
-- URL: https://hyundai-rotem.recruiter.co.kr/career/welfare
-- badge: est
--
-- 참고:
--   정본은 현대로템 공식 채용 사이트(마이다스 잡플렉스 ATS, 기업 사이트 상단 인재채용 링크의 같은 호스트)
--   복지제도 페이지 /career/welfare 다. 제목 현대로템 채용 | 복지제도 · JSON-LD publisher 현대로템.
--   본문은 robots 전면 금지 API 에서만 와서 자동 수집기가 읽지 못한다. 원문 = 사이트 운영자가 2026-10-02
--   브라우저로 페이지를 열어 붙여 넣은 화면 본문(사본 hyundai_rotem/user_paste_welfare_2026-10-02.txt ·
--   sha256 91983cb3…50c8). 근무여건 · 가정 · 여가활동 3구역 카드 16개, 항목 이름만 있고 설명은 거의 없다.
--   보조 출처: 2026 현대로템 지속가능경영보고서(국문 PDF, 기업 사이트 지속가능경영보고서 목록의 첫 카드,
--     /upload/2026/8/20260825080848015172.pdf, 127쪽, sha256 70c9a7c9…0167) p.61 복지제도 표
--     (편의제공 · 생활안정 지원 · 동기부여 및 여가 활동 · 가족 친화적인 문화 구축 4묶음 22항목),
--     p.50 건강증진 프로그램 및 시설, p.49 해외 의료 및 보안 지원 시스템, p.56 인재 확보 및 평가(보상 체계).
--   행마다 서술 괄호에 실제 근거를 적었다 — 공식 채용 사이트 복지제도 항목 · 2026 지속가능경영보고서 항목.
--     채용 페이지 카드 16개는 전부 행이 되었거나 행 서술에 들어갔다(온라인 교육 프로그램 및 어학 수강 지원 카드는 2026-10-04 규칙 8 개정으로 edu_support · lang 행이 되었다).
--     보고서에만 있는 행 13: health_check · mental · fitness · overseas_safety · transport · relocation ·
--     parenting · childcare · incentive · birthday_leave · uniform · dormitory · flex_work.
--   귀속: 채용 사이트 · 보고서 모두 현대로템 법인 단독 — 그룹 공통 페이지가 아니라 각주 없음.
--     현대자동차 · 기아 · 현대모비스 · 현대건설 정본 문구는 옮기지 않았다.
--   직군: 두 원문 모두 생산직 · 사무직을 가르지 않는다(incentive 행의 책임급 직원 한정은 원문 그대로).
--   금액: 원문 명시 금액 0건. 구본 추정치 승계 7행(child_edu 200 · commute_subsidy 120 · welfare_point 200 ·
--     resort 50 · medical 100 · health_check 100 · meal 288 — 전부 틀 값, NOTE 끝에 (추정)). meal 288 은
--     채용 페이지가 중식 제공을 밝혀 구본 전제(중식 1식)가 원문에 있다. event 50 은 경조금이라 승계하지 않았다.
--   법정 제도 제외: 육아휴직 · 정년퇴직 예정자 재취업 및 창업 교육(1,000인 이상 사업주 의무)은 행이 아니다.
--   구본에서 뺀 행: edu_support · lang — 온라인 교육 프로그램 · 어학 수강 지원은 2026-10-04 규칙 8 개정으로 되살렸다(SORT 30 · 31). 신임/향상과정 · 신입사원 교육 등 직무 교육은 그대로 제외.
--   재코딩: long_service_leave → long_service_bonus (원문은 장기 근속자 포상 — 휴가 언급 없음).
--   SORT 섹션 순서 = 채용 페이지에서 카테고리가 처음 나온 순서, 보고서에만 있는 행은 해당 섹션 끝,
--     채용 페이지에 없는 카테고리는 보고서 순서로 뒤에 (health 10 · perks 20 · leisure 40 ·
--     family 50 · compensation 60 · time_off 70 · work_env 80 · flexibility 90).
-- 재수집(2026-10-02): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-02, RV-3-4): 29행 전부 붙여넣기 원문 · 2026 지속가능경영보고서와 글자 대조 · 어학 수강 지원은 비용 지원 문장이 없어 미수록 · 최종 29행
-- 후속 정리 2(2026-10-04, R-3): 사용자가 정한 복지 범위 규칙 개정(규칙 8 · 기준 13 · 기준 18 · 기준 20 · 기준 23)과 코퍼스 판정을 반영 — 새 행 2(lang · edu_support) — 최종 31행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hyundai_rotem', '현대로템',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '철도/방산', 'H', 'https://hyundai-rotem.recruiter.co.kr/career/welfare');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_rotem');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://hyundai-rotem.recruiter.co.kr/career/welfare'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강·의료 (health) — 근무여건 의료비 지원 / 보고서 생활안정 지원 · 건강증진 · 해외 의료 및 보안 ──
  (@comp_id, 'medical', '의료비 지원', 100, 'health',
   'est', '의료비 지원 (공식 채용 사이트 복지제도 근무여건 항목), 직원 및 가족 의료비 지원 (2026 지속가능경영보고서 복지제도 생활안정 지원 항목) — 지원 한도·가족 범위 미기재 (추정)', FALSE, NULL, 10),
  (@comp_id, 'health_check', '직원·가족 종합검진·독감 예방접종', 100, 'health',
   'est', '직원 및 가족 종합검진 지원 (2026 지속가능경영보고서 복지제도 생활안정 지원 항목), 매년 전 임직원 종합건강검진·독감 예방접종 지원 (같은 보고서 건강증진 항목) — 검진 비용 한도 미기재 (추정)', FALSE, NULL, 11),
  (@comp_id, 'mental', '상담센터·정신건강 프로그램', NULL, 'health',
   'est', NULL, TRUE, '직장생활 및 스트레스 관리를 위한 상담센터와 정신건강 프로그램 운영 (2026 지속가능경영보고서 건강증진 프로그램 및 시설 항목) — 이용 횟수·비용 미기재', 12),
  (@comp_id, 'fitness', '맞춤형 건강증진 프로그램', NULL, 'health',
   'est', NULL, TRUE, '근골격계 질환 예방을 위해 희망 직원 대상 맞춤형 건강증진 프로그램 운영, 소도구를 활용한 스트레칭·전문가 특강·테이핑 실습 (2026 지속가능경영보고서 건강증진 프로그램 및 시설 항목, 2025년 도입)', 13),
  (@comp_id, 'overseas_safety', '해외 근무자 의료·보안 지원', NULL, 'health',
   'est', NULL, TRUE, 'International SOS 와 협력해 해외 주재원 및 가족, 출장자·파견자에게 365일 24시간 긴급 의료 상담·현지 병원 안내 및 예약·통역, 보안 상담·긴급 대피 지원 (2026 지속가능경영보고서 해외 의료 및 보안 지원 시스템 항목)', 14),

  -- ── 경제적 부가혜택 (perks) — 근무여건 차량구입 · 통근버스 · 중식 / 가정 복지 포인트 · 주택구입 · 개인연금 / 보고서 편의제공 · 생활안정 ──
  (@comp_id, 'discount', '차량구입 지원', NULL, 'perks',
   'est', NULL, TRUE, '차량구입 지원 (공식 채용 사이트 복지제도 근무여건 항목), 차량구입 지원금 (2026 지속가능경영보고서 복지제도 편의제공 항목) — 지원 금액·조건 미기재', 20),
  (@comp_id, 'commute_subsidy', '통근버스', 120, 'perks',
   'est', '통근버스 지원 (공식 채용 사이트 복지제도 근무여건 항목), 출퇴근 통근 셔틀 운행 (2026 지속가능경영보고서 복지제도 편의제공 항목) — 운행 사업장·노선 미기재 (추정)', FALSE, NULL, 21),
  (@comp_id, 'meal', '중식 제공·조석식 일부 지원', 288, 'perks',
   'est', '중식 제공, 조·석식 일부 지원 (공식 채용 사이트 복지제도 근무여건 항목), 사내 식당 운영 (2026 지속가능경영보고서 복지제도 편의제공 항목) — 식대 단가·조석식 지원 범위 미기재 (추정)', FALSE, NULL, 22),
  (@comp_id, 'welfare_point', '복지포인트 (상/하반기)', 200, 'perks',
   'est', '상/하반기 복지 포인트 (공식 채용 사이트 복지제도 가정 항목), 복지포인트 지급 및 복지 카드 발급, 사외 체육시설 이용 등 건강관리에 사용 (2026 지속가능경영보고서) — 연간 지급액 미기재 (추정)', FALSE, NULL, 23),
  (@comp_id, 'housing_loan', '주택구입·전세자금 지원', NULL, 'perks',
   'est', NULL, TRUE, '주택구입/전세자금 지원 (공식 채용 사이트 복지제도 가정 항목), 주택 구입 및 전세 자금 지원 (2026 지속가능경영보고서 복지제도 생활안정 지원 항목) — 지원 방식·한도·이율 미기재', 24),
  (@comp_id, 'pension_support', '개인연금 지원', NULL, 'perks',
   'est', NULL, TRUE, '개인연금 지원 (공식 채용 사이트 복지제도 가정 항목 · 2026 지속가능경영보고서 복지제도 생활안정 지원 항목) — 지원 비율·한도 미기재', 25),
  (@comp_id, 'transport', '차량 유류비 지원', NULL, 'perks',
   'est', NULL, TRUE, '차량 유류비 지원 (2026 지속가능경영보고서 복지제도 편의제공 항목) — 지원 금액·대상 미기재', 26),
  (@comp_id, 'relocation', '이사비·부임비 지원', NULL, 'perks',
   'est', NULL, TRUE, '근무자 이동에 따른 이사비 및 부임비 지원 (2026 지속가능경영보고서 복지제도 생활안정 지원 항목) — 지원 금액 미기재', 27),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'lang', '어학 수강 지원', NULL, 'growth',
   'est', NULL, TRUE, '어학 수강 지원 (공식 채용 사이트 복지제도 근무여건 온라인 교육 프로그램 및 어학 수강 지원 항목), 글로벌 역량 강화를 위한 어학 교육 (2026 지속가능경영보고서 인재 육성 항목) — 지원 방식·한도·대상 어종 미기재', 30),
  (@comp_id, 'edu_support', '온라인 교육 프로그램', NULL, 'growth',
   'est', NULL, TRUE, '온라인 교육 프로그램 (공식 채용 사이트 복지제도 근무여건 온라인 교육 프로그램 및 어학 수강 지원 항목), 자기주도적 학습 환경을 위한 약 3,200개 이러닝 콘텐츠의 스마트러닝 플랫폼 운영 (2026 지속가능경영보고서 인재 육성 항목) — 콘텐츠 분야·수강 방식 미기재', 31),

  -- ── 여가·라이프 (leisure) — 근무여건 모바일 E-BOOK / 가정 하계 휴가비 / 여가활동 동호회 · 휴양소 ──
  (@comp_id, 'library', '전자 도서관·모바일 E-BOOK', NULL, 'leisure',
   'est', NULL, TRUE, '모바일 E-BOOK 콘텐츠 지원 (공식 채용 사이트 복지제도 근무여건 항목), 전자 도서관 서비스 제공 (2026 지속가능경영보고서 복지제도 동기부여 및 여가 활동 항목) — 이용 범위 미기재', 40),
  (@comp_id, 'summer_vacation_subsidy', '하계 휴가비', NULL, 'leisure',
   'est', NULL, TRUE, '하계 휴가비 (공식 채용 사이트 복지제도 가정 명절 및 하계 휴가비 항목), 하계휴가비 지급 (2026 지속가능경영보고서 복지제도 편의제공 항목) — 지급액 미기재', 41),
  (@comp_id, 'club', '동호회 활동 지원', NULL, 'leisure',
   'est', NULL, TRUE, '각종 동호회 활동 지원 (공식 채용 사이트 복지제도 여가활동 항목), 동호회 활동 보조비 지급 및 사내 활동 장소 지원 (2026 지속가능경영보고서 복지제도 동기부여 및 여가 활동 항목) — 보조비 금액 미기재', 42),
  (@comp_id, 'resort', '사계절 휴양소', 50, 'leisure',
   'est', '사계절 휴양소 지원 (공식 채용 사이트 복지제도 여가활동 항목), 사계절 휴양소 운영 (2026 지속가능경영보고서 복지제도 동기부여 및 여가 활동 항목) — 휴양소 위치·이용 일수 미기재 (추정)', FALSE, NULL, 43),

  -- ── 가족·돌봄 (family) — 가정 자녀 학자금 · 경조사 / 보고서 가족 친화적인 문화 구축 ──
  (@comp_id, 'child_edu', '자녀 학자금·유아 교육비', 200, 'family',
   'est', '자녀 학자금 (공식 채용 사이트 복지제도 가정 항목), 유아 교육비 및 중학생, 고등학생, 대학생 자녀 학자금 지원 (2026 지속가능경영보고서 복지제도 편의제공 항목) — 지원 한도·자녀 수 미기재 (추정)', FALSE, NULL, 50),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '각종 경조사 지원 (공식 채용 사이트 복지제도 가정 항목), 경조 휴가·경조금·경조 화환 지급 (2026 지속가능경영보고서 복지제도 편의제공 항목) — 경조 종류별 금액·휴가 일수 미기재', 51),
  (@comp_id, 'parenting', '자녀출산 및 양육지원', NULL, 'family',
   'est', NULL, TRUE, '자녀출산 및 양육지원 (2026 지속가능경영보고서 복지제도 가족 친화적인 문화 구축 항목) — 지원 내용·금액 미기재', 52),
  (@comp_id, 'childcare', '직장 어린이집', NULL, 'family',
   'est', NULL, TRUE, '직장 어린이집 운영 (2026 지속가능경영보고서 복지제도 가족 친화적인 문화 구축 항목) — 운영 사업장·정원 미기재', 53),

  -- ── 보상 (compensation) — 가정 명절 휴가비 / 여가활동 장기 근속자 포상 / 보고서 보상 체계 ──
  (@comp_id, 'holiday_gift', '명절 휴가비·명절선물', NULL, 'compensation',
   'est', NULL, TRUE, '명절 휴가비 (공식 채용 사이트 복지제도 가정 명절 및 하계 휴가비 항목), 명절선물 지급 (2026 지속가능경영보고서 복지제도 편의제공 항목) — 지급액·선물 구성 미기재', 60),
  (@comp_id, 'long_service_bonus', '장기 근속자 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기 근속자 포상 (공식 채용 사이트 복지제도 여가활동 항목), 장기근속자 포상 제공 (2026 지속가능경영보고서 복지제도 동기부여 및 여가 활동 항목) — 근속 구간·포상 내용 미기재', 61),
  (@comp_id, 'incentive', '성과 연동 변동급·인센티브', NULL, 'compensation',
   'est', NULL, TRUE, '평가 결과를 보상에 연계하는 변동급 운영, 책임급 직원은 평가 등급에 따라 업적연봉(비누적식 변동급) 비율 차등 적용, 일부 인센티브는 현업 리더에게 자율권을 주어 성과 창출 인원에게 적시 보상 (2026 지속가능경영보고서 인재 확보 및 평가 항목) — 지급 기준·지급률 미기재', 62),

  -- ── 시간·휴가 (time_off) — 여가활동 하기 휴가 및 다양한 휴가제도 / 보고서 동기부여 및 여가 활동 ──
  (@comp_id, 'summer_leave', '하기 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '하기 휴가 및 다양한 휴가제도 (공식 채용 사이트 복지제도 여가활동 항목), 하계휴가 제공 (2026 지속가능경영보고서 복지제도 동기부여 및 여가 활동 항목) — 휴가 일수·유급 여부·사용 시기 미기재', 70),
  (@comp_id, 'birthday_leave', '개인 기념일 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '개인 기념일 휴가 제공 (2026 지속가능경영보고서 복지제도 동기부여 및 여가 활동 항목) — 기념일 범위·휴가 일수 미기재', 71),

  -- ── 근무환경 (work_env) — 보고서 편의제공 · 생활안정 지원 ──
  (@comp_id, 'uniform', '근무복·체육복', NULL, 'work_env',
   'est', NULL, TRUE, '근무복/체육복 지급 (2026 지속가능경영보고서 복지제도 편의제공 항목) — 지급 주기·대상 미기재', 80),
  (@comp_id, 'dormitory', '기숙사', NULL, 'work_env',
   'est', NULL, TRUE, '기숙사 운영 (2026 지속가능경영보고서 복지제도 생활안정 지원 항목) — 운영 사업장·입주 조건 미기재', 81),

  -- ── 유연근무 (flexibility) — 보고서 가족 친화적인 문화 구축 ──
  (@comp_id, 'flex_work', '유연근무제도', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제도 운영 (2026 지속가능경영보고서 복지제도 가족 친화적인 문화 구축 항목) — 제도 유형·적용 대상 미기재', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
