-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 삼성생명 복리후생 데이터
-- 출처: AI 파싱 (2026-10-01)
-- URL: https://www.samsungcareers.com/subsid/detail/E11
-- badge: est
-- 코퍼스 정리(2026-10-10 · 웨이브 5 감사 후속): PlusWeek 연속 휴가 행 삭제 — 최종 26행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 참고:
--   정본 = 삼성 공식 채용사이트의 삼성생명 법인 전용 페이지(/subsid/detail/E11). 귀속 경로: samsungcareers.com
--     관계사 소개(/subsid/) → 금융 → 삼성생명 → /subsid/detail/E11. 같은 페이지 상세정보가 법인을 직접 밝힌다
--     (주소 서울시 서초구 서초대로 74길 11 삼성생명보험주식회사 · 주요 업무 생명보험, 자산운용 등 · 홈페이지
--     www.samsunglife.com · 채용 문의 recruit.sli@samsung.com). 복지 절은 section id=a6, 제목 「삼성생명의 근무 환경과
--     복지 제도」 — 3묶음 26항목(button.tag tip 의 data-tip). 서버 렌더 HTML 이라 헤드리스 불필요.
--     robots.txt 는 없다(302 → /sub/etc/error.html — 규칙 없음 = 허용). 본문 sha256 f75631d3…9a668f20.
--   법인 전용 페이지라 그룹 통합 채용 기준 각주는 붙이지 않았다(삼성화재 · 삼성증권 선례). 그룹 공통 /insight/welfare 는 쓰지 않았다.
--   법인 자기 도메인 www.samsunglife.com 은 Vue SPA 다. 헤더 메뉴 API(/gw/api/display/menu/all)와 sitemap.xml 의
--     채용정보 3쪽(인재상 · 직무소개 · 채용지원 안내)에는 복지 절이 없다. 번들에만 있는 인사제도 라우트(PDK-HRCAI026170M)는
--     헤더 메뉴 · 사이트맵 어디에도 없어 근거로 쓰지 않았다(행을 세우는 데도, 비우는 데도 쓰지 않음).
--   원문 26항목 → 학습 플랫폼 1(Grow Campus)은 2026-10-04 규칙 8 개정으로 edu_support 행으로 되살림 · 복합 라벨 2 분해(사내 피트니스·병원·식당 3행 · 모성보호 2행) ·
--     파견형 4항목을 mba 1행에 흡수 → 24행. 재코딩 1(edu_support → self_development) · 신규 코드 0.
--   법정 제도 제외: 육아휴직 · 임신기 단축근무(모성보호 항목 안) 문구는 행에도 서술에도 넣지 않았다. 재취업지원 문구는 원문에 없다.
--   금액: 원문에 원 단위 금액이 0건(정량 표현은 보험료 절반 · 연 25매 · PC 시각뿐). 구본 추정 승계 5(health_check 100 ·
--     insurance 30 · child_edu 200 · resort 50 · pension_support 50 — 전부 틀 값). 구본 공식 수치 welfare_point 80 은
--     원문에 숫자가 없어 승계하지 않았다. parenting 50 · event 50 · meal 288 은 승계 조건 미달이라 NULL.
-- 재수집(2026-10-01): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-01, RV-3-2): 자기 도메인 헤더 메뉴의 영문 Human Resource Management 쪽에서 incentive(개인·조직 성과급) · leave_general(PlusWeek 연속 휴가) 정성 행 2 추가 — 최종 26행
-- 후속 정리 2(2026-10-04, R-3): 사용자가 정한 복지 범위 규칙 개정(규칙 8 · 기준 13 · 기준 18 · 기준 20 · 기준 23)과 코퍼스 판정을 반영 — 새 행 1(edu_support) · 서술 · 이름 수정 1(lang) — 최종 27행

-- 1) 회사 등록 (기존 회사 — no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('samsung_life', '삼성생명',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '보험', 'S', 'https://www.samsungcareers.com/subsid/detail/E11');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'samsung_life');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.samsungcareers.com/subsid/detail/E11'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 경제적 부가혜택 (perks) ── 가족, 의료 및 소득 지원 · 사내 문화 및 편의
  (@comp_id, 'welfare_point', '복지포인트', NULL, 'perks',
   'est', NULL, TRUE, '임직원 개개인의 선호와 필요에 따라 자유롭게 사용할 수 있는 복지포인트 제공 (공식 채용 페이지 가족, 의료 및 소득 지원 항목 — 연간 포인트 금액 미기재)', 10),
  (@comp_id, 'pension_support', '개인연금 지원', 50, 'perks',
   'est', '안정적인 노후생활 보장을 위해 지정된 개인연금 상품의 보험료 절반을 회사가 지원 (공식 채용 페이지 가족, 의료 및 소득 지원 항목 — 지원 금액·납입 한도 미기재) (추정)', FALSE, NULL, 11),
  (@comp_id, 'birthday_gift', '기념일 선물', NULL, 'perks',
   'est', NULL, TRUE, '생일, 결혼기념일 등 기념일에 임직원이 직접 선택한 선물 지급 (공식 채용 페이지 가족, 의료 및 소득 지원 항목 — 선물 금액·지급 횟수 미기재)', 12),
  (@comp_id, 'meal', '사내 식당', NULL, 'perks',
   'est', NULL, TRUE, '사내 식당 운영 (공식 채용 페이지 사내 문화 및 편의 항목 — 제공 끼니·식대 단가 미기재)', 13),

  -- ── 건강·의료 (health) ── 가족, 의료 및 소득 지원 · 사내 문화 및 편의
  (@comp_id, 'health_check', '건강검진 지원', 100, 'health',
   'est', '건강검진을 정기적으로 실시하고 검진 시 공가 부여 (공식 채용 페이지 가족, 의료 및 소득 지원 항목 — 검진 비용·가족 범위 미기재) (추정)', FALSE, NULL, 20),
  (@comp_id, 'insurance', '단체정기보험', 30, 'health',
   'est', '임직원 본인뿐 아니라 배우자와 자녀까지 단체보장보험 가입 지원 (공식 채용 페이지 가족, 의료 및 소득 지원 항목 — 보장 내용·보험료 미기재) (추정)', FALSE, NULL, 21),
  (@comp_id, 'mental', '마음건강센터', NULL, 'health',
   'est', NULL, TRUE, '사내 마음건강센터 운영, 임직원 누구나 방문해 전문상담사와 상담 가능 (공식 채용 페이지 가족, 의료 및 소득 지원 항목 — 상담 횟수·가족 이용 여부 미기재)', 22),
  (@comp_id, 'fitness', '사내 피트니스', NULL, 'health',
   'est', NULL, TRUE, '사내 피트니스 운영 (공식 채용 페이지 사내 문화 및 편의 항목 — 이용 조건·사업장 범위 미기재)', 23),
  (@comp_id, 'clinic', '사내 병원', NULL, 'health',
   'est', NULL, TRUE, '사내 병원 운영 (공식 채용 페이지 사내 문화 및 편의 항목 — 진료 과목·이용 조건 미기재)', 24),

  -- ── 가족·돌봄 (family) ── 가족, 의료 및 소득 지원
  (@comp_id, 'parenting', '출산지원금·임부물품 지원', NULL, 'family',
   'est', NULL, TRUE, '출산지원금 운영과 임부물품 지원 (공식 채용 페이지 가족, 의료 및 소득 지원 항목 — 지원 금액·지급 시점 미기재)', 30),
  (@comp_id, 'fertility_support', '난임 치료비 지원', NULL, 'family',
   'est', NULL, TRUE, '난임 치료비 지원 (공식 채용 페이지 가족, 의료 및 소득 지원 항목 — 지원 한도·횟수 미기재)', 31),
  (@comp_id, 'childcare', '사내 어린이집', NULL, 'family',
   'est', NULL, TRUE, '사내 어린이집 운영 (공식 채용 페이지 가족, 의료 및 소득 지원 항목 — 위치·정원 미기재)', 32),
  (@comp_id, 'child_edu', '자녀학자금 지원', 200, 'family',
   'est', '유치원, 고등학교, 대학교 임직원 자녀 학자금 지원 (공식 채용 페이지 가족, 의료 및 소득 지원 항목 — 지원 한도·자녀 수 미기재) (추정)', FALSE, NULL, 33),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '임직원 경조사 발생 시 경조금, 경조물품, 화환 및 경조휴가 지원 (공식 채용 페이지 가족, 의료 및 소득 지원 항목 — 경조 유형별 금액·휴가 일수 미기재)', 34),

  -- ── 성장·커리어 (growth) ── 자기 개발 지원
  (@comp_id, 'self_development', '자격 취득 지원', NULL, 'growth',
   'est', NULL, TRUE, '90여 개 자격증의 응시료 및 교육비 지원 (공식 채용 페이지 자기 개발 지원 항목 — 지원 한도·대상 자격증 목록 미기재)', 40),
  (@comp_id, 'lang', '외국어교육·시험 응시료 지원', NULL, 'growth',
   'est', NULL, TRUE, '다양한 어학교육 과정 운영과 어종별 외국어 시험 응시료 지원 (공식 채용 페이지 자기 개발 지원 외국어교육 지원 항목), 전화영어(중국어) 지원 (공식 홈페이지 영문 인사제도 Opportunities 항목 — 지원 한도·대상 시험 미기재)', 41),
  (@comp_id, 'books', '독서 지원', NULL, 'growth',
   'est', NULL, TRUE, '도서구입비 혹은 독서플랫폼 구독료 지원 (공식 채용 페이지 자기 개발 지원 항목 — 지원 한도 미기재)', 42),
  (@comp_id, 'mba', '해외MBA·금융석사과정', NULL, 'growth',
   'est', NULL, TRUE, '미국, 영국 등 주요 대학 해외MBA 과정과 차세대 리더급 금융전문가 양성 금융석사과정 지원, 다양한 국가에 파견하는 지역전문가, 선진사 업무체험 글로벌 직무연수, 비학위 국내 학술연수 지원 (공식 채용 페이지 자기 개발 지원 항목 — 선발 기준·인원 미기재)', 43),
  (@comp_id, 'edu_support', 'Grow Campus 학습 플랫폼', NULL, 'growth',
   'est', NULL, TRUE, 'PC/모바일 기반 학습 플랫폼 Grow Campus 로 언제 어디서나 학습 (공식 채용 페이지 자기 개발 지원 Grow Campus 항목 — 과정 분야·이용 조건 미기재)', 44),

  -- ── 근무유연성 (flexibility) ── 사내 문화 및 편의
  (@comp_id, 'pc_off', 'PC ON/OFF 시스템', NULL, 'flexibility',
   'est', NULL, TRUE, '8시 10분 이후 PC가 켜지고 18시 20분에 자동으로 꺼지는 PC ON/OFF 시스템, 매주 수·금요일은 17시 40분 OFF (공식 채용 페이지 사내 문화 및 편의 항목)', 50),
  (@comp_id, 'flex_work', '선택적 근로시간제', NULL, 'flexibility',
   'est', NULL, TRUE, '임직원 개개인이 근무시간을 자유롭게 조정할 수 있는 선택적 근로시간제 운영 (공식 채용 페이지 사내 문화 및 편의 항목 — 의무 근무 시간대 미기재)', 51),

  -- ── 여가·라이프 (leisure) ── 사내 문화 및 편의
  (@comp_id, 'company_event', '가족친화 프로그램', NULL, 'leisure',
   'est', NULL, TRUE, '가족 글램핑, 부모님 해외 효도여행, 자녀 영어·스키캠프 등 가족과 함께하는 프로그램 운영 (공식 채용 페이지 사내 문화 및 편의 항목 — 참가 대상·비용 부담 미기재)', 60),
  (@comp_id, 'resort', '휴양소 지원', 50, 'leisure',
   'est', '전국 유명 콘도 및 호텔과 제휴해 임직원이 법인 명의로 숙박 예약 가능 (공식 채용 페이지 사내 문화 및 편의 항목 — 이용 횟수·비용 부담 미기재) (추정)', FALSE, NULL, 61),
  (@comp_id, 'leisure_ticket', '캐리비안베이 입장권', NULL, 'leisure',
   'est', NULL, TRUE, '연 25매의 캐리비안베이 입장권 지원 (공식 채용 페이지 사내 문화 및 편의 항목)', 62),
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회를 통한 친목 도모와 취미생활, 회사가 동호회 활동비 지원 (공식 채용 페이지 사내 문화 및 편의 항목 — 지원 금액 미기재)', 63),

  -- ── 보상·금전 (compensation) ── 공식 홈페이지 영문 인사제도
  (@comp_id, 'incentive', '성과급', NULL, 'compensation',
   'est', NULL, TRUE, '연봉과 별도로 개인성과급(업무성과급, 영업관리자 영업인센티브)과 조직성과급(목표인센티브 연 2회, 성과인센티브 연 1회) 지급 (공식 홈페이지 영문 인사제도 Salary and Treatment 항목 — 지급 기준·지급률 미기재)', 70)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
