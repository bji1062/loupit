-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 호텔신라 복리후생 데이터 (신규 회사 — 웨이브 9)
-- 출처: AI 파싱 (2026-10-15)
-- URL: https://www.samsungcareers.com/subsid/detail/E50
-- badge: est
--
-- 참고:
--   정본은 삼성 채용 사이트의 호텔신라 법인 전용 페이지(/subsid/detail/E50)다. 복지 절은 같은 페이지
--   section id=a6 「호텔신라의 근무 환경과 복지 제도」 3블록 23항목(가족, 의료 및 소득 지원 9 · 자기 개발 지원 6 ·
--   사내 문화 및 편의 8). 서버렌더 HTML 이라 헤드리스 렌더 · 이미지 판독 불필요.
--   귀속 경로: samsungcareers.com 관계사 소개 목록 → 호텔신라 → /subsid/detail/E50. 같은 페이지 상세정보가
--   법인을 직접 명시한다(주소 서울특별시 중구 동호로 249 · 주요 업무 면세유통, 호텔서비스, 레저사업 ·
--   홈페이지 www.hotelshilla.net). 자기 도메인 www.hotelshilla.net 채용안내 페이지도 이 주소로 링크한다.
--   형제 페이지 E21(삼성화재)과 23항목을 대조해 설명 문장 일치 0건 — 템플릿 아님. 법인 전용 페이지라 각주 없음.
--   그룹 공통 /insight/welfare 문장은 한 건도 쓰지 않았다.
--   자기 도메인에는 복리후생 페이지가 없다(채용안내는 신입 채용 절차뿐). 자기 발행 지속가능경영보고서는
--   사이트 메뉴가 POST 전용 호출로만 나와 목록 위치를 찾지 못했다 — 쓰지 않았다.
--   공시 보조: OpenDART 2026 반기보고서(접수 20260814001955) 유연근무제도 사용현황 표(시차출퇴근제) ·
--   대주주 이외의 이해관계자와의 거래 항목(임직원 주택자금 대여). 직원 1,924명(2026-06-30 본사 기준).
--   금액: 원문에 원 단위 숫자 0건 — 전 행 BENEFIT_AMT NULL.
--   제외: 법정(출산전후 휴가 · 육아기 휴직 및 근로시간 단축 · 난임휴가) · 업무 교육(직무 교육 지원) ·
--     공시 원격근무제 사용자 수 표(값 없음 · 복지 맥락 문장 없음) · 임원 보수 칸(설/추석상여 · 임원 처우).
--   복합 라벨 분해: 건강검진 및 의료비 지원 → health_check + insurance. 병합: 경조사 지원 + 결혼 도움방 → event,
--     심리상담센터 + 명상 프로그램 → mental, 호텔 할인 + 면세점 할인 → discount.
--   공고 근거 0행 / 전체 21행.
--   SORT 섹션 순서 = 정본 페이지 등장 순(health 10 · family 20 · perks 30 · growth 40 · leisure 50 ·
--     work_env 60), 공시에만 있는 flexibility 70.
-- 검증 · 감사 판정 반영(2026-10-15): 자기 도메인 인사제도 · 복리후생 · 인재육성 3쪽 반영 — 의료실비 medical · 인센티브제도 incentive · 장기근속 포상 long_service_bonus 추가 · 어학 · 온라인 교육 · 지역전문가 행 병합 · 업종 유통(리드 판정 136) · 참고 블록의 자기 도메인 복리후생 페이지 없음 문장은 이 판정으로 뒤집힘 · 항목 페이지 예외 3(통합 밖 리드 집행) — 최종 24행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hotel_shilla', '호텔신라',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '유통', 'H', 'https://www.samsungcareers.com/subsid/detail/E50');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hotel_shilla');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.samsungcareers.com/subsid/detail/E50'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강 (health) — 삼성 채용 사이트 호텔신라 페이지 ──
  (@comp_id, 'health_check', '종합건강검진 (본인·가족)', NULL, 'health',
   'est', NULL, TRUE, '임직원 본인 및 가족의 종합건강검진 지원 (삼성 채용 사이트 호텔신라 페이지 건강검진 및 의료비 지원 항목) — 검진 주기·가족 범위·지원 금액 미기재', 10),
  (@comp_id, 'insurance', '단체보험', NULL, 'health',
   'est', NULL, TRUE, '단체보험 가입 (삼성 채용 사이트 호텔신라 페이지 건강검진 및 의료비 지원 항목) — 보장 범위·가입 대상 미기재', 11),
  (@comp_id, 'mental', '심리상담센터·명상 프로그램', NULL, 'health',
   'est', NULL, TRUE, '임직원의 정신적인 건강을 위해 사내 상담실 및 외부 상담센터 지원 (삼성 채용 사이트 호텔신라 페이지 심리상담센터 항목), 명상 교육 및 힐링 명상 캠프 운영 (같은 페이지 명상 프로그램 항목) — 상담 횟수·비용 지원 범위·캠프 참가 대상 미기재', 12),
  (@comp_id, 'fitness', '피트니스 지원', NULL, 'health',
   'est', NULL, TRUE, '임직원 건강증진을 위해 외부 피트니스 업체 법인권으로 이용 가능 (삼성 채용 사이트 호텔신라 페이지 피트니스 지원 항목) — 제휴 업체·본인 부담·이용 한도 미기재', 13),
  (@comp_id, 'medical', '의료실비 지원', NULL, 'health',
   'est', NULL, TRUE, '의료실비 (호텔신라 공식 홈페이지 복리후생 의료실비/단체보험 항목), 의료비 지원 (삼성 채용 사이트 호텔신라 페이지 건강검진 및 의료비 지원 항목) — 지원 방식·한도·가족 범위 미기재', 14),
  -- ── 가족 (family) — 삼성 채용 사이트 호텔신라 페이지 ──
  (@comp_id, 'fertility_support', '난임 치료비 지원', NULL, 'family',
   'est', NULL, TRUE, '난임 치료비 지원 (삼성 채용 사이트 호텔신라 페이지 가족, 의료 및 소득 지원 항목) — 지원 금액·지원 횟수 미기재', 20),
  (@comp_id, 'child_edu', '자녀 학자금', NULL, 'family',
   'est', NULL, TRUE, '중 · 고교 및 대학교 등록금, 유치원보육비 지원 (삼성 채용 사이트 호텔신라 페이지 자녀 학자금 항목) — 지원 한도·자녀 수 제한 미기재', 21),
  (@comp_id, 'event', '경조사 지원·결혼 도움방', NULL, 'family',
   'est', NULL, TRUE, '경조휴가 및 관련 물품, 경조금 지원 (삼성 채용 사이트 호텔신라 페이지 경조사 지원 항목), 임직원 본인 및 자녀 대상 사내 예식장 대관 및 결혼 준비 지원 (같은 페이지 결혼 도움방 항목) — 경조금 금액·휴가 일수·대관 비용 미기재', 22),
  -- ── 생활 · 금융 (perks) — 삼성 채용 사이트 호텔신라 페이지 · 2026 반기보고서 ──
  (@comp_id, 'housing_loan', '주거 안정 지원 (주택임차·구입자금 대출)', NULL, 'perks',
   'est', NULL, TRUE, '주택임차 및 구입자금 일부 대출 지원 (삼성 채용 사이트 호텔신라 페이지 주거 안정 지원 항목), 임직원 주택자금 대여 (2026 반기보고서 대주주 이외의 이해관계자와의 거래 항목) — 대출 한도·이율·상환 조건 미기재', 30),
  (@comp_id, 'pension_support', '개인연금 지원', NULL, 'perks',
   'est', NULL, TRUE, '개인연금 납입액 일부 회사비용 지원 (삼성 채용 사이트 호텔신라 페이지 개인연금 항목) — 회사 부담 비율·한도 미기재', 31),
  (@comp_id, 'welfare_point', '선택적 복리후생 (복지포인트)', NULL, 'perks',
   'est', NULL, TRUE, '개인의 선호에 따른 복리후생을 선택하여 사용하는 복지포인트 (삼성 채용 사이트 호텔신라 페이지 선택적 복리후생 항목) — 연간 포인트 금액 미기재', 32),
  (@comp_id, 'discount', '호텔·면세점 임직원 할인', NULL, 'perks',
   'est', NULL, TRUE, '제주호텔 및 신라스테이, 신라모노그램 이용시 임직원 할인 제공 (삼성 채용 사이트 호텔신라 페이지 호텔 할인 항목), 신라면세점 임직원 할인 및 구매 지원 복지포인트 제공 (같은 페이지 면세점 할인 항목) — 할인율·포인트 금액 미기재', 33),
  (@comp_id, 'meal', '사내식당', NULL, 'perks',
   'est', NULL, TRUE, '전문 영양사와 쉐프가 제공하는 한식/인터내셔널 식단 및 건강식 (삼성 채용 사이트 호텔신라 페이지 사내식당 항목) — 제공 끼니·본인 부담 미기재', 34),
  (@comp_id, 'snack_bar', '사내카페 (직원가)', NULL, 'perks',
   'est', NULL, TRUE, '아티제 카페를 직원가로 이용 가능 (삼성 채용 사이트 호텔신라 페이지 사내카페 항목) — 할인율·운영 사업장 미기재', 35),
  -- ── 성장 · 교육 (growth) — 삼성 채용 사이트 호텔신라 페이지 ──
  (@comp_id, 'career', '지역전문가·SGBP 해외법인 실습', NULL, 'growth',
   'est', NULL, TRUE, '해외로 파견되어 해당 나라의 언어, 문화 등을 습득하는 글로벌 인재 육성 프로그램 (삼성 채용 사이트 호텔신라 페이지 지역전문가 항목), 삼성 그룹 지역전문가 · SGBP(Shilla Global Business Program, 단기 해외법인 실습 프로그램) (호텔신라 공식 홈페이지 인재육성 교육체계 글로벌교육 항목) — 선발 기준·파견 기간·지원 범위 미기재', 40),
  (@comp_id, 'lang', '외국어 교육 지원', NULL, 'growth',
   'est', NULL, TRUE, '외국어 회화 자격시험 응시료 지원 및 사내 어학 과정, 온라인 과정, 전화 외국어 지원 (삼성 채용 사이트 호텔신라 페이지 외국어 교육 지원 항목), SGPL(Samsung Global expert Program in Language, 외국어 생활관) · 어학 AI 어플리케이션(스픽) · 디지털 외국어 생활관 (호텔신라 공식 홈페이지 인재육성 교육체계 글로벌교육 항목) — 응시료 한도·수강 대상 미기재', 41),
  (@comp_id, 'edu_support', '온라인교육센터', NULL, 'growth',
   'est', NULL, TRUE, '자기개발을 위한 온라인 강의 제공 (삼성 채용 사이트 호텔신라 페이지 온라인교육센터 항목), CiC 디지털 러닝센터 온라인 과정(직무, 어학, IT, 리더십, 소양 등) · 클래스 101 온라인 과정 (호텔신라 공식 홈페이지 인재육성 교육체계 온라인교육 항목) — 수강 한도·비용 부담 미기재', 42),
  -- ── 여가 (leisure) — 삼성 채용 사이트 호텔신라 페이지 ──
  (@comp_id, 'library', '온라인도서관', NULL, 'leisure',
   'est', NULL, TRUE, '관심분야별 도서 구비 및 매월 업데이트되는 신간 도서 대여 가능 (삼성 채용 사이트 호텔신라 페이지 온라인도서관 항목) — 대여 한도 미기재', 50),
  (@comp_id, 'club', '사내동호회', NULL, 'leisure',
   'est', NULL, TRUE, '직원들의 여가활동과 취미생활 지원 (삼성 채용 사이트 호텔신라 페이지 사내동호회 항목) — 지원 금액·동호회 종류 미기재', 51),
  (@comp_id, 'resort', '휴양소 지원', NULL, 'leisure',
   'est', NULL, TRUE, '전국 각지의 휴양소, 리조트 할인 및 에버랜드 법인권 이용 (삼성 채용 사이트 호텔신라 페이지 휴양소 지원 항목) — 이용 횟수·할인율 미기재', 52),
  -- ── 근무 환경 (work_env) — 삼성 채용 사이트 호텔신라 페이지 ──
  (@comp_id, 'dormitory', '기숙사 (제주호텔 직원)', NULL, 'work_env',
   'est', NULL, TRUE, '제주호텔 직원을 위한 기숙사 제공 (삼성 채용 사이트 호텔신라 페이지 기숙사 항목) — 입주 조건·본인 부담 미기재', 60),
  -- ── 근무 유연성 (flexibility) — 2026 반기보고서 ──
  (@comp_id, 'flex_work', '시차출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제 활용, 시차출퇴근제 사용자 수 620명 (2026 반기보고서 직원 등 현황 유연근무제도 사용현황 항목) — 대상 직무·사용 조건 미기재', 70),
  -- ── 보상 (compensation) — 호텔신라 공식 홈페이지 인사제도 · 복리후생 · 2026 반기보고서 ──
  (@comp_id, 'incentive', '인센티브 제도 (TAI·OPI·업적성과급)', NULL, 'compensation',
   'est', NULL, TRUE, '회사의 경영성과에 따른 별도의 인센티브제도 운영, TAI(Target Achievement Incentive) 목표달성 성과급(월 기본급의 최대 100%, 연2회), OPI(Overall Performance Incentive) 성과 인센티브(연봉의 최대 50%, 연1회), 업적평가에 따른 업적성과급 (호텔신라 공식 홈페이지 인사제도 항목) — 연도별 지급률 미기재', 80),
  (@comp_id, 'long_service_bonus', '장기근속 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속 포상 (호텔신라 공식 홈페이지 복리후생 항목), 장기근속보상 미지급비용으로 구성된 기타장기종업원급여 (2026 반기보고서 재무제표 주석 종업원급여 항목) — 근속 기준·포상 내용·금액 미기재', 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
