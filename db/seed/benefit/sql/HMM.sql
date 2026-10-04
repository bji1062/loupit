-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- HMM 복리후생 데이터
-- 출처: AI 파싱 (2026-10-01)
-- URL: https://careers.hmm21.com/hmm21/page/user/company_support
-- badge: est
--
-- 참고:
--   정본은 HMM 자기 도메인(hmm21.com)의 채용 사이트 careers.hmm21.com 헤더 메뉴 HMM 소개 → 복리후생 페이지
--   (/hmm21/page/user/company_support)다. benefits system 복리후생 제도 21항목. 서버 렌더 HTML 에 항목 본문이 그대로 있다
--   — 헤드리스 렌더 없음. 항목 그림(benefit01~21.png)은 아이콘이라 판독 대상이 아니다.
--   보조 출처: 같은 사이트 헤더 메뉴 HMM 소개 → 인사제도(/company_promo)의 주재원 제도 · 교육 훈련 제도 절.
--   귀속: 꼬리말 (주)HMM · ⓒHMM CO.,LTD. · 채용 메일 recruit@hmm21.com · 부산본사 주소 — 법인 단독 채용 사이트라 그룹 각주 없음.
--   해상직: 회사소개 페이지가 선원 등 해상직 채용은 에이치엠엠오션서비스로 안내한다. 원문 복리후생 21항목은 직군을
--     가르지 않아 서술에 직군을 적지 않았다. 선원 수당 항목은 원문에 없다.
--   robots: www.hmm21.com 은 User-agent * 에 Disallow / 라 요청하지 않았다(지속가능경영보고서 · 보도자료 미확인).
--     careers.hmm21.com/robots.txt 는 403(파일 없음) — RFC 9309 의 접근 불가 4xx 라 허용으로 판정.
--   금액: 원문 환산 1(child_edu 유아교육비 월 10만원 → 120) · 구본 추정 승계 7(snack_bar 30 · welfare_point 200 ·
--     telecom 30 · pension_support 50 · resort 50 · insurance 30 · health_check 100 — 전부 틀 값,
--     NOTE 끝에 (추정)). transport 30 은 회사 고유값이라, event 50 은 경조금이라, parenting 10 은 1회성이라
--     승계하지 않았다. 원문에 원 단위 금액은 유아교육비 월 10만원 하나다.
--   구본에서 뺀 행: lang 은 2026-10-04 되살렸다(회사가 여는 어학교육 — 규칙 8 개정으로 SORT 72).
--   재코딩: edu_support → self_development (남는 제도가 전문자격 취득 지원제도 하나).
--   SORT 섹션 순서 = 정본 페이지에서 카테고리가 처음 나온 순서, 인사제도 페이지 항목은 끝
--     (perks 10 · leisure 20 · family 30 · health 40 · work_env 50 · time_off 60 · growth 70).
-- 재수집(2026-10-01): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-01, RV-3-3): 유아교육비(월 10만원 · 연 120 환산)를 parenting 에서 child_edu 로 옮김(유치원 · 유아교육비 = 자녀 학자금 축) · parenting 은 출산축하 아기용품 정성 행 — 최종 22행
-- 후속 정리 2(2026-10-04, R-3): 사용자가 정한 복지 범위 규칙 개정(규칙 8 · 기준 13 · 기준 18 · 기준 20 · 기준 23)과 코퍼스 판정을 반영 — 새 행 1(lang) — 최종 23행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hmm', 'HMM',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '해운', 'H', 'https://careers.hmm21.com/hmm21/page/user/company_support');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hmm');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://careers.hmm21.com/hmm21/page/user/company_support'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 경제적 부가혜택 (perks) — 복리후생 제도 식대지원 · 사내카페 · 복지포인트 · 교통비/통신비 · 기념일 · 개인연금 · 부임이사 ──
  (@comp_id, 'meal', '식대 지원', NULL, 'perks',
   'est', NULL, TRUE, '모바일 식권 플랫폼으로 중식대 및 야근식대 포인트 지급, 약 300개 제휴점 이용 가능 (공식 채용 사이트 복리후생 식대지원 항목) — 1식 단가·월 지급액 미기재', 10),
  (@comp_id, 'snack_bar', '사내카페', 30, 'perks',
   'est', '사내카페 운영, 월간 한도 내 이용금액의 50% 지원 (공식 채용 사이트 복리후생 사내카페 운영 항목) — 월간 한도 금액 미기재 (추정)', FALSE, NULL, 11),
  (@comp_id, 'welfare_point', '복지카드·포인트', 200, 'perks',
   'est', '여가 및 자기개발을 위한 복지카드 및 포인트 지급 (공식 채용 사이트 복리후생 복지포인트 지급 항목) — 연간 지급액 미기재 (추정)', FALSE, NULL, 12),
  (@comp_id, 'transport', '교통비 지원', NULL, 'perks',
   'est', NULL, TRUE, '교통비 일정액 지급 (공식 채용 사이트 복리후생 교통비/통신비 지원 항목) — 지급액 미기재', 13),
  (@comp_id, 'telecom', '통신비 지원', 30, 'perks',
   'est', '통신비 일정액 지급 (공식 채용 사이트 복리후생 교통비/통신비 지원 항목) — 지급액 미기재 (추정)', FALSE, NULL, 14),
  (@comp_id, 'birthday_gift', '생일축하 상품권', NULL, 'perks',
   'est', NULL, TRUE, '생일축하용 백화점 상품권 지급 (공식 채용 사이트 복리후생 기념일 축하 항목) — 상품권 금액 미기재', 15),
  (@comp_id, 'pension_support', '개인연금 지원', 50, 'perks',
   'est', '외부 금융상품 가입 후 가입금액의 50% 지원 (공식 채용 사이트 복리후생 개인연금 지원 항목) — 지원 한도 미기재 (추정)', FALSE, NULL, 16),
  (@comp_id, 'relocation', '부임이사 지원', NULL, 'perks',
   'est', NULL, TRUE, '장거리 부임 시 이사비, 부임여비 등 지원 (공식 채용 사이트 복리후생 부임이사 지원 항목) — 지원 금액·거리 기준 미기재', 17),

  -- ── 여가·라이프 (leisure) — 복리후생 제도 사내 동호회 · 법인콘도 ──
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '독서, 야구, 축구, 농구, 산악, 볼링, 마라톤, 테니스 등 사내 동호회 운영 (공식 채용 사이트 복리후생 사내 동호회 운영 항목) — 활동비 지원액 미기재', 20),
  (@comp_id, 'resort', '법인콘도', 50, 'leisure',
   'est', '다양한 지역에 소재한 유명 휴양시설 이용 가능 (공식 채용 사이트 복리후생 법인콘도 이용 항목) — 이용 일수·비용 부담 미기재 (추정)', FALSE, NULL, 21),

  -- ── 가족·돌봄 (family) — 복리후생 제도 경조사 · 기념일 · 종합보육 · 유아교육비 · 자녀학자금 · 웨딩카 ──
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사비 지급, 특별휴가 부여, 축하화환 및 근조화환(장례용품) 발송 (공식 채용 사이트 복리후생 경조사 지원 항목), 결혼 시 법인차량(대형세단) 대여 및 유류대·톨비 지원 (같은 페이지 웨딩카 지원 항목) — 경조 종류별 금액·휴가 일수 미기재', 30),
  (@comp_id, 'parenting', '출산축하 아기용품', NULL, 'family',
   'est', NULL, TRUE, '출산축하 아기용품 지급 (공식 채용 사이트 복리후생 기념일 축하 항목) — 용품 구성·금액 미기재', 31),
  (@comp_id, 'childcare', '종합보육제도', NULL, 'family',
   'est', NULL, TRUE, '위탁보육제도 운영 및 맞춤형 영유아돌봄서비스 확대 제공 (공식 채용 사이트 복리후생 종합보육제도 운영 항목) — 위탁 보육시설·돌봄서비스 내용 미기재', 32),
  (@comp_id, 'child_edu', '자녀학자금·유아교육비', 120, 'family',
   'est', '취학 직전 자녀 대상 2년간 월 10만원 유아교육비 지원, 고등학교 및 대학교 등록금 일부 또는 전액 지원 (공식 채용 사이트 복리후생 유아교육비·자녀학자금 지원 항목) — 월 10만원을 연 120만원으로 환산', FALSE, NULL, 33),

  -- ── 건강·의료 (health) — 복리후생 제도 단체상해보험 · 심리상담 · 건강검진 · 독감예방접종 · 건강증진 ──
  (@comp_id, 'insurance', '단체상해보험', 30, 'health',
   'est', '각종 질병 및 사고 대비 단체상해보험 가입 (공식 채용 사이트 복리후생 단체상해보험가입 항목) — 보장 금액 미기재 (추정)', FALSE, NULL, 40),
  (@comp_id, 'mental', '심리상담 프로그램', NULL, 'health',
   'est', NULL, TRUE, '직장, 가족 등 고민 주제에 대한 전문가의 대면·비대면 상담 제공 (공식 채용 사이트 복리후생 심리상담 프로그램 지원 항목) — 이용 횟수 미기재', 41),
  (@comp_id, 'health_check', '본인·가족 건강검진·독감 예방접종', 100, 'health',
   'est', '본인 및 가족 종합건강검진 지원 (공식 채용 사이트 복리후생 본인 및 가족 건강검진 항목), 지정병원 독감예방주사 무상 접종 (같은 페이지 독감예방접종 항목) — 검진 비용 한도·가족 범위 미기재 (추정)', FALSE, NULL, 42),
  (@comp_id, 'fitness', '건강증진 지원', NULL, 'health',
   'est', NULL, TRUE, '근골격계 건강보호 프로그램(요가), 건강상담실 운영 (공식 채용 사이트 복리후생 건강증진 지원 항목) — 운영 주기·장소 미기재', 43),

  -- ── 근무환경 (work_env) — 복리후생 제도 모성보호실 ──
  (@comp_id, 'nap_room', '모성보호실', NULL, 'work_env',
   'est', NULL, TRUE, '냉장고, 소파, 유축기 등을 갖춘 모유 수유시설인 모성보호실 운영 (공식 채용 사이트 복리후생 모성보호실 운영 항목)', 50),

  -- ── 시간·휴가 (time_off) — 복리후생 제도 장기근속자 포상 ──
  (@comp_id, 'long_service_leave', '장기근속자 포상 (Refresh 휴가)', NULL, 'time_off',
   'est', NULL, TRUE, '근속연수에 따라 Refresh 휴가 등 포상 제공 (공식 채용 사이트 복리후생 장기근속자 포상 항목) — 근속 구간·휴가 일수 미기재', 60),

  -- ── 성장·커리어 (growth) — 인사제도 주재원 제도 · 교육 훈련 제도 ──
  (@comp_id, 'career', '주재원 제도', NULL, 'growth',
   'est', NULL, TRUE, '영업, 관리 전 직무를 대상으로 전세계 20여개 법인과 60여개 지점 및 사무소에 근무할 주재원 매년 선발 (공식 채용 사이트 인사제도 주재원 제도 항목)', 70),
  (@comp_id, 'self_development', '전문자격 취득 지원', NULL, 'growth',
   'est', NULL, TRUE, '전문자격 취득 지원제도 운영 (공식 채용 사이트 인사제도 교육 훈련 제도 직무 역량 항목) — 지원 대상 자격·지원 금액 미기재', 71),
  (@comp_id, 'lang', '어학교육 (전화·온라인 · BIZ English Workshop)', NULL, 'growth',
   'est', NULL, TRUE, '전화·온라인 어학교육과 BIZ English Workshop 운영 (공식 채용 사이트 인사제도 교육 훈련 제도 글로벌 역량 항목) — 참여 대상·비용 부담 미기재', 72)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
