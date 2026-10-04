-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 삼성물산 복리후생 데이터
-- 출처: AI 파싱 (2026-10-02)
-- URL: https://www.samsungcareers.com/subsid/detail/E7A
-- badge: est
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 참고:
--   삼성물산은 건설 · 상사 · 리조트 · 패션 4개 부문이다. 회사 공통 복지 페이지는 없다(공식 홈 samsungcnt.com 인재채용은
--     부문별 채용 사이트 링크 4개뿐). 그래서 행마다 적용 부문을 서술에 적었다. 4개 부문 원문 모두에 있는 제도만 부문 넷을 다 적고,
--     어느 원문도 전 부문 공통이라고 밝히지 않으므로 회사 공통이라는 말은 쓰지 않았다.
--   출처 = 삼성 공식 채용사이트의 부문 전용 페이지 넷(/subsid/detail/B12 건설 · B11 상사 · E71 리조트 · E7A 패션 — 각 페이지
--     상세정보가 주소 · 주요 업무로 삼성물산 해당 부문을 밝힌다) + 부문 자기 도메인 채용 페이지(secc.co.kr/ko/recruit/welfare ·
--     trading.samsungcnt.com/people/culture.do · rnc.samsungcnt.com/careers/wealth · samsungfashion.com/recruitIntro.do · hrPolicy.do).
--     전부 서버 렌더 HTML, 헤드리스 없음. 복지 절은 section id=a6 의 button.tag data-tip.
--   정본 = 행이 가장 많이 나오는 단일 페이지인 패션부문 페이지 E7A(22행). 부문 자기 도메인 samsungfashion.com 채용소개는
--     같은 26항목을 라벨로만 싣는다(설명 없음) — 복지 절이 더 많지 않아 E7A 를 골랐다.
--   법인 전용 페이지라 그룹 통합 채용 기준 각주는 붙이지 않았다(삼성생명 · 삼성화재 선례). 형제 법인 문구 0.
--   원문 부문 4쪽 + 자기 도메인 5쪽 → 34행. 재코딩 0 · 신규 코드 0. 구본 11행은 상사부문 페이지 문구와 맞아 자기 법인(A).
--   법정 제외: 패션부문 육아휴직 및 모성보호제도 · 상사부문 법정복리후생(4대보험) · 패션부문 건강/산재/고용보험 · 국민연금.
--   금액: 원문 원 단위 금액 0. 구본 추정 승계 6(health_check 100 · medical 100 · insurance 30 · child_edu 300 ·
--     welfare_point 200 · resort 100 — 전부 틀 값, NOTE 끝 (추정)). event 50 은 경조금이라 승계하지 않았다.
--   4개 부문 모두에 있는 제도가 아닌 행 21개는 항목명 끝 괄호에 적용 부문을 적었다(서술에도 부문별로 적음).
-- 재수집(2026-10-02): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-02, RV-3-4): 상사부문 의료비 지원 항목(본인·배우자·자녀 실손 의료비 보험 가입)을 medical 서술에 넣어 4개 부문 행으로 — 항목명 부문 괄호 삭제 · 최종 34행
-- 후속 정리 2(2026-10-04, R-3): 사용자가 정한 복지 범위 규칙 개정(규칙 8 · 기준 13 · 기준 18 · 기준 20 · 기준 23)과 코퍼스 판정을 반영 — 새 행 1(welfare_fund_loan) · 서술 · 이름 수정 2(edu_support · lang) — 최종 35행

-- 1) 회사 등록 (기존 회사 — no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('samsung_ct', '삼성물산',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '건설/무역', 'S', 'https://www.samsungcareers.com/subsid/detail/E7A');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'samsung_ct');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.samsungcareers.com/subsid/detail/E7A'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강·의료 (health) ── 가족, 의료 및 소득 지원 · 사내 문화 및 편의
  (@comp_id, 'health_check', '건강검진 지원', 100, 'health',
   'est', '건설부문 종합건강검진·배우자 검진, 상사부문 본인·배우자 검진(연령별 차등), 리조트부문 본인·배우자 정기 검진, 패션부문 본인·배우자 종합검진·3대질병검진 (4개 부문 공식 채용 페이지) — 검진 비용 미기재 (추정)', FALSE, NULL, 10),
  (@comp_id, 'medical', '의료비 지원', 100, 'health',
   'est', '건설부문 의료비 지원, 상사부문 본인·배우자·자녀 실손 의료비 보험 가입, 리조트부문 임직원 가족 의료비 지원, 패션부문 본인·배우자·자녀 실손의료비 지원 (4개 부문 공식 채용 페이지 의료비 항목) — 지원 한도 미기재 (추정)', FALSE, NULL, 11),
  (@comp_id, 'insurance', '단체보험 (건설·상사·리조트부문)', 30, 'health',
   'est', '건설부문 단체·실손보험, 상사부문 질병사망·상해사망·후유장해·3대 질병진단 단체보험과 본인·배우자·자녀 실손 의료비 보험 가입, 리조트부문 단체보험 (3개 부문 공식 채용 페이지) — 보험료 미기재 (추정)', FALSE, NULL, 12),
  (@comp_id, 'mental', '심리상담센터 (건설·리조트·패션부문)', NULL, 'health',
   'est', NULL, TRUE, '임직원 마음 건강을 위한 심리상담센터 운영 — 건설부문, 리조트부문 마인드케어센터(직장·가족 고민 심리 상담과 자문), 패션부문 사내 전문 심리상담센터 무료 이용 (3개 부문 공식 채용 페이지 심리상담 항목 — 상담 횟수·가족 이용 여부 미기재)', 13),
  (@comp_id, 'clinic', '사내 부속의원·치과병원 (건설부문)', NULL, 'health',
   'est', NULL, TRUE, '건설부문 사내 부속의원 및 치과병원, 사내진료실 운영 (건설부문 공식 채용 페이지 사내병원 · 건강관리 항목 — 진료 과목·이용 조건 미기재)', 14),
  (@comp_id, 'fitness', '피트니스 지원', NULL, 'health',
   'est', NULL, TRUE, '건설부문 사내 피트니스 시설과 레포츠센터, 상사부문 외부 레포츠·피트니스센터 연계와 이용료 지원, 리조트부문 사내 헬스클럽, 패션부문 회사 인근 피트니스 센터 이용금액 지원 (4개 부문 공식 채용 페이지 — 지원 한도 미기재)', 15),

  -- ── 가족·돌봄 (family) ── 가족, 의료 및 소득 지원
  (@comp_id, 'childcare', '어린이집', NULL, 'family',
   'est', NULL, TRUE, '건설부문 사내 어린이집, 상사부문 영유아 자녀 어린이집 지원, 리조트부문 용인 지역 사내 어린이집, 패션부문 자녀 어린이집 입소 지원 (4개 부문 공식 채용 페이지 어린이집 항목 — 정원·위치 미기재)', 20),
  (@comp_id, 'child_edu', '자녀학자금', 300, 'family',
   'est', '상사부문 중·고·대학 학자금과 유치원비 지원·미취학 아동 양육보조비, 패션부문 유치원·중·고·대학교 학자금, 리조트부문 대학 학자금, 건설부문 자녀 학자금 (4개 부문 공식 채용 페이지) — 지원 한도 미기재 (추정)', FALSE, NULL, 21),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '건설부문 경조지원·경조휴가와 결혼도움방, 상사부문 경조금·경조휴가·경조화환(직급과 근속연수에 따라 차등), 리조트부문 결혼·부의 등 경조사 지원, 패션부문 각종 경조금과 부모님 환갑·칠순 축하선물, 사옥예식장 이용 (4개 부문 공식 채용 페이지 경조사 항목 — 경조 유형별 금액·휴가 일수 미기재)', 22),
  (@comp_id, 'parenting', '출산·입학 축하선물 (건설·패션부문)', NULL, 'family',
   'est', NULL, TRUE, '건설부문 출산선물, 패션부문 출산·복직·자녀입학 축하선물 (건설부문 채용 사이트 복리후생 가족친화 항목 · 패션부문 공식 채용 페이지 경조금 및 결혼 도움방 항목 — 선물 내용·금액 미기재)', 23),

  -- ── 경제적 부가혜택 (perks) ── 가족, 의료 및 소득 지원 · 사내 문화 및 편의
  (@comp_id, 'housing_loan', '주택자금 지원 (상사·리조트·패션부문)', NULL, 'perks',
   'est', NULL, TRUE, '상사부문 무주택자 주택임차·구입 시 사내근로복지기금 저금리 대출, 리조트부문 주택 대부제도, 패션부문 주택 신규임차·구입 시 대출금 일부 이자 지원 (3개 부문 공식 채용 페이지 — 대출 한도·금리·이자 지원율 미기재)', 30),
  (@comp_id, 'pension_support', '개인연금 지원', NULL, 'perks',
   'est', NULL, TRUE, '개인연금 지원 — 건설부문(노후자금 마련), 상사부문(가입 임직원 회사 지원금 지급), 리조트부문(개인연금 운용 지원), 패션부문(납입금액 일부 지원) (4개 부문 공식 채용 페이지 개인연금 항목 — 지원 비율·금액 미기재)', 31),
  (@comp_id, 'welfare_point', '선택적 복리후생 포인트', 200, 'perks',
   'est', '건설부문 Cafeteria Benefit 복지예산 포인트, 상사부문 연간 복지포인트, 리조트부문 교육·의료·문화 생활용 블루베리 포인트, 패션부문 선택적 복리후생 포인트 (4개 부문 공식 채용 페이지) — 연간 금액 미기재 (추정)', FALSE, NULL, 32),
  (@comp_id, 'discount', '임직원 할인 (리조트·패션부문)', NULL, 'perks',
   'est', NULL, TRUE, '패션부문 자사 및 수입브랜드 구매 시 임직원 할인율 우대(ILMO 임직원 할인), 리조트부문 에버랜드와 삼성물산 패션(SSF)에서 쓰는 할인포인트 지급 (2개 부문 공식 채용 페이지 — 할인율·포인트 금액 미기재)', 33),
  (@comp_id, 'snack_bar', '임직원 전용 카페 (패션부문)', NULL, 'perks',
   'est', NULL, TRUE, '패션부문 임직원 전용 카페 ILMO CAFE 운영 (패션부문 공식 채용 페이지 사내 문화 및 편의 항목 — 이용 가격 미기재)', 34),
  (@comp_id, 'meal', '사내식당 (건설·리조트부문)', NULL, 'perks',
   'est', NULL, TRUE, '건설부문 사내식당(다양한 메뉴와 Take out 코너), 리조트부문 사내식당과 점심비용 일부 지원 (2개 부문 공식 채용 페이지 사내식당 항목 — 제공 끼니·식대 단가 미기재)', 35),
  (@comp_id, 'commute_subsidy', '통근버스 (건설·리조트부문)', NULL, 'perks',
   'est', NULL, TRUE, '건설부문 수도권 지역 통근버스, 리조트부문 용인과 서울 본사지역 출퇴근 셔틀 무료 운영 (2개 부문 공식 채용 페이지 — 노선 수 미기재)', 36),
  (@comp_id, 'team_dinner', '부서별 문화활동 지원 (리조트부문)', NULL, 'perks',
   'est', NULL, TRUE, '리조트부문 부서별 특색 있는 문화 활동 지원 (리조트부문 공식 채용 페이지 사내 문화 및 편의 항목 — 지원 금액 미기재)', 37),
  (@comp_id, 'welfare_fund_loan', '사내대출 (건설부문)', NULL, 'perks',
   'est', NULL, TRUE, '건설부문 사내대출 (건설부문 채용 사이트 복리후생 가족친화 항목) — 대출 용도·한도·금리 미기재', 38),

  -- ── 성장·커리어 (growth) ── 자기 개발 지원
  (@comp_id, 'mba', 'MBA·EMBA 지원', NULL, 'growth',
   'est', NULL, TRUE, '건설부문 MBA 및 전문학위 취득(국내외 우수대 파견교육), 상사부문 삼성 MBA/EMBA, 리조트부문 MBA 과정 지원, 패션부문 삼성 EMBA(국내외 MBA 과정 수학 지원) (4개 부문 공식 채용 페이지 자기 개발 지원 항목 — 선발 기준·인원 미기재)', 40),
  (@comp_id, 'career', '지역전문가·해외 파견·사내 FA', NULL, 'growth',
   'est', NULL, TRUE, '건설부문 지역전문가(중국, 베트남, 멕시코 등 파견)와 해외 선진사 인턴십, 상사부문 해외 지역전문가(1~2년 해외파견)와 세계은행·유럽부흥개발은행 2년 파견 근무, 리조트부문 지역전문가, 패션부문 패션 전략지역 파견·패션스쿨 단기연수와 사내전배를 위한 Free Agent 제도 (4개 부문 공식 채용 페이지 자기 개발 지원 항목 — 선발 기준·인원 미기재)', 41),
  (@comp_id, 'edu_support', '온라인 교육비·스터디그룹·사내교육 플랫폼 (건설·패션·리조트부문)', NULL, 'growth',
   'est', NULL, TRUE, '건설부문 비즈니스·어학·직무 온라인 교육 콘텐츠 제공과 비용 지원, 사내 스터디그룹 지원, 패션부문 자기계발·커리어설계를 위한 온라인 강의 교육비 지원, 리조트부문 사내 온라인 교육 플랫폼(CiC) 운영 (3개 부문 공식 채용 페이지 E-learning 지원 · 스터디그룹 · CiC 사내교육 플랫폼 항목) — 지원 한도 미기재', 42),
  (@comp_id, 'conference', '사외교육 지원 (패션부문)', NULL, 'growth',
   'est', NULL, TRUE, '패션부문 직무 관련 외부 교육기관 교육 수강 시 교육비 지원 (패션부문 공식 채용 페이지 자기 개발 지원 항목 — 지원 한도 미기재)', 43),
  (@comp_id, 'books', '도서 구입 지원 (패션부문)', NULL, 'growth',
   'est', NULL, TRUE, '패션부문 임직원 도서구입비 일부 지원과 사내 포럼 (패션부문 공식 채용 페이지 자기 개발 지원 항목 — 지원 한도 미기재)', 44),
  (@comp_id, 'lang', '외국어 교육·시험 응시 지원 (건설·상사·패션·리조트부문)', NULL, 'growth',
   'est', NULL, TRUE, '건설부문 사내 외국어 집합과정·온라인 외국어 과정 운영, 상사부문 어학 온라인 학습과정 지원, 패션부문 영어/제2외국어 사내교육·전화영어 과정 지원, 리조트부문 어학 학습 및 외국어 시험 응시 지원 (4개 부문 공식 채용 페이지 외국어 능력 향상 · 온라인 학습지원 · 외국어 교육 지원 · 외국어 학습 장려 항목) — 지원 한도·대상 시험 미기재', 45),
  (@comp_id, 'self_development', '자격 취득 장려 (리조트부문)', NULL, 'growth',
   'est', NULL, TRUE, '리조트부문 직무 관련 자격 취득을 위한 온라인 강의와 자격 취득 축하금 지원 (리조트부문 공식 채용 페이지 자기 개발 지원 항목 — 축하금 금액·대상 자격 미기재)', 46),

  -- ── 근무유연성 (flexibility) ── 사내 문화 및 편의
  (@comp_id, 'flex_work', '유연근무제·자율출퇴근제 (패션부문)', NULL, 'flexibility',
   'est', NULL, TRUE, '패션부문 8시~10시 사이 자유로운 출근시간 보장, 필수 근무시간 안에서 본인이 근무시간 관리 (패션부문 공식 채용 페이지 사내 문화 및 편의 항목)', 50),

  -- ── 여가·라이프 (leisure) ── 사내 문화 및 편의
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '임직원 취미생활과 동호회 활동 지원 — 건설부문, 상사부문, 리조트부문, 패션부문(사내동호회와 개인 관심사 연구활동 지원) (4개 부문 공식 채용 페이지 동호회 항목 — 지원 금액 미기재)', 60),
  (@comp_id, 'resort', '휴양소 지원', 100, 'leisure',
   'est', '건설부문 전국 각지 휴양소, 상사부문 전국 제휴 콘도·리조트 숙박, 리조트부문 법인콘도 선착순 이용, 패션부문 전국 리조트와 삼성영덕연수원 법인회원가 예약 (4개 부문 공식 채용 페이지) — 이용 횟수·비용 부담 미기재 (추정)', FALSE, NULL, 61),
  (@comp_id, 'leisure_ticket', '에버랜드·캐리비안베이 이용권', NULL, 'leisure',
   'est', NULL, TRUE, '건설부문 에버랜드·캐리비안베이, 상사부문 테마파크·워터파크(캐리비안베이) 이용권, 리조트부문 연간 한도 안에서 연간회원권·이용권 신청과 에버랜드·캐리비안 베이·내부 매장용 파크포인트, 패션부문 캐리비안베이·에버랜드 이용권 (4개 부문 공식 채용 페이지 — 매수·한도 미기재)', 62),
  (@comp_id, 'company_event', '문화행사 (상사부문)', NULL, 'leisure',
   'est', NULL, TRUE, '상사부문 임직원이 리프레시할 수 있는 다양한 행사 및 활동 운영 (상사부문 공식 채용 페이지 사내 문화 및 편의 항목 — 행사 종류·횟수 미기재)', 63),
  (@comp_id, 'library', '전자도서관 (상사부문)', NULL, 'leisure',
   'est', NULL, TRUE, '상사부문 전자도서 대여 서비스 제공 (상사부문 채용 사이트 문화 페이지 복리후생 휴식/여가지원 항목 — 대여 한도 미기재)', 64),

  -- ── 근무환경 (work_env) ── 리조트부문
  (@comp_id, 'dormitory', '기숙사 (리조트부문)', NULL, 'work_env',
   'est', NULL, TRUE, '리조트부문 에버랜드 인근 용인 지역 기숙사, 먼 곳에 거주하는 미혼 직원에게 저렴한 가격의 1인 1실 (리조트부문 공식 채용 페이지 기숙사 운영 항목 — 입주 기간·비용 미기재)', 70),

  -- ── 시간·휴가 (time_off) ── 건설 · 리조트부문
  (@comp_id, 'long_service_leave', '장기근속 휴가·휴가비 (건설·리조트부문)', NULL, 'time_off',
   'est', NULL, TRUE, '건설부문 5년 단위 장기근속자 휴가와 휴가비, 리조트부문 장기근속 직원 정기 리프레시 휴가와 휴가비 (2개 부문 공식 채용 페이지 장기근속 항목 — 휴가 일수·휴가비 금액 미기재)', 80),

  -- ── 보상·금전 (compensation) ── 부문 채용 사이트 보상 · 급여 항목
  (@comp_id, 'incentive', '성과급 (건설·패션부문)', NULL, 'compensation',
   'est', NULL, TRUE, '건설부문 개인성과급(업무성과급), 경영목표 달성도에 따라 반기별 목표인센티브, 연 1회 성과인센티브, 준공·수주·혁신 인센티브, 패션부문 개인·집단성과에 따른 성과급(총보상 = 계약연봉+성과급) (건설·패션부문 채용 사이트 보상체계 · 급여체계 항목 — 지급률 미기재)', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
