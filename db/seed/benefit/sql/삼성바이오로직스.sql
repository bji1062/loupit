-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 삼성바이오로직스 복리후생 데이터
-- 출처: AI 파싱 (2026-10-02)
-- URL: https://www.samsungcareers.com/subsid/detail/DA0
-- badge: est
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 참고:
--   정본 = 삼성 공식 채용사이트의 삼성바이오로직스 법인 전용 페이지(/subsid/detail/DA0). 귀속 경로: samsungcareers.com
--     관계사 목록(/subsid/) → 삼성바이오로직스 → /subsid/detail/DA0. 같은 페이지 상세정보가 법인을 직접 밝힌다
--     (주소 인천광역시 연수구 송도바이오대로 300 · 주요 업무 바이오의약품 위탁생산(CMO) 및 위탁개발(CDO) ·
--     채용 문의 recruit.bio@samsung.com). 복지 절 section id=a6 제목 「삼성바이오로직스의 근무 환경과 복지 제도」
--     3묶음 21항목(button.tag 의 data-tip). 서버 렌더 HTML. robots.txt 없음(302 → 오류 페이지, 규칙 없음 = 허용).
--     본문 sha256 3fa42a5c…c52de1625f. 법인 전용 페이지라 그룹 통합 채용 기준 각주는 붙이지 않았다(삼성생명 · 삼성화재 형식).
--   보조 출처(법인 자기 도메인 samsungbiologics.com — robots 허용 경로): Careers 사내복지 /kr/careers/working-with-us/benefits
--     (바이오플라자 · 메디컬존 · 식당 · 편의시설) · 2026 ESG 보고서 국문 PDF(ESG 보고서 페이지의 내려받기, 101~103쪽
--     복지제도 표 · 95쪽 학위 및 자격증 · 97쪽 성과보상 · 우리사주) · 뉴스룸 Life 기사 3편(2021-12 · 2022-01 · 2022-09 FAQ)
--     · 2025-09-15 가족 초청행사 보도자료. 자기 도메인 복지 페이지는 항목이 DA0 보다 적어 정본으로 쓰지 않았다.
--   귀속: 자회사 삼성바이오에피스(/subsid/detail/DB0) 문구는 쓰지 않았다 — DA0 21문장과 글자까지 같은 DB0 문장 0.
--     구본 library(사내 북카페 · 책 자유 대여)는 DB0 문장과 맞고 이 법인 원문에 없어 뺐다.
--   원문 21항목 + 보조 출처 → 32행. 직무 관련 양성(회사 주도 교육) 제외 · 의료복지 1항목을 health_check · medical 2행으로 분해 ·
--     모성보호(사내어린이집 등) 1항목을 childcare · nap_room · parenting 으로 나눔. 재코딩 0 · 신규 코드 0.
--   법정 제도 제외: 출산전후휴가와 그 급여 · 배우자출산휴가 20일 · 법정 범위 육아휴직과 급여 · 육아기 단축 · 유사산휴가 ·
--     가족돌봄 휴가/휴직 · 퇴직연금 · 건강보험료 50%(사업주 부담분) 는 행에도 서술에도 넣지 않았다. 상회분(육아 휴직 2년 ·
--     임신 휴직 · 임신 13~30주 무급 단축 · 난임 휴가 유급 5일)만 ESG 보고서가 법적 기준과 나눠 밝힌 대로 실었다.
--     직원 5,455명(1,000인 이상)이지만 원문에 재취업지원 문구는 없다.
--   금액: 원문에 연 환산 가능한 원 단위 금액 0건(난임 시술비 연 100만 원은 한도라 NULL). 구본 추정 승계 5(health_check 100 ·
--     medical 100 · child_edu 300 · resort 50 · welfare_point 200 — 전부 틀 값, NOTE 끝 (추정)). meal 은 원문이 하루 네 끼를
--     밝히지만 운영값이 NULL 이라 승계할 추정치가 없어 NULL(근거표 판단 요청).
--   구본에서 뺀 행: edu_support(직무 · 리더십 교육 과정 — 월 1회 자율 수강 온라인 교육은 2026-10-04 되살림) · library(자회사 문구 · 이 법인 원문 없음).
-- 재수집(2026-10-02): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-02, RV-3-4): fertility_support 난임 치료 휴가를 상회분(유급 2일 → 5일)으로 다시 적음 · stock_option 서술의 회사 지원 미기재 꼬리를 원문(2022년 대출금 · 이자 지원)대로 — 최종 32행
-- 후속 정리 2(2026-10-04, R-3): 사용자가 정한 복지 범위 규칙 개정(규칙 8 · 기준 13 · 기준 18 · 기준 20 · 기준 23)과 코퍼스 판정을 반영 — 새 행 1(edu_support) · 서술 · 이름 수정 1(lang) — 최종 33행
-- 2026-10-06 식대 기준 금액 1끼 12,000원(리드 판정 (82)) — meal 행 금액 = 1끼 단가 × 끼니 × 연 240일, 꼬리에 식 공개

-- 1) 회사 등록 (기존 회사 — no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('samsung_bio', '삼성바이오로직스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '바이오', 'S', 'https://www.samsungcareers.com/subsid/detail/DA0');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'samsung_bio');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.samsungcareers.com/subsid/detail/DA0'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 경제적 부가혜택 (perks) ── 가족, 의료 및 소득 지원 · 사내 문화 및 편의 · 자기 도메인 사내복지
  (@comp_id, 'pension_support', '개인연금 지원', NULL, 'perks',
   'est', NULL, TRUE, '임직원의 노후 대비를 위해 개인연금 보험 가입액 일부 지원 (공식 채용 페이지 가족, 의료 및 소득 지원 항목 — 지원 비율·한도 미기재)', 10),
  (@comp_id, 'welfare_point', '선택적 복리후생 포인트', 200, 'perks',
   'est', '자기계발/취미/여행 등 관심사에 맞춰 자유롭게 쓰는 포인트를 매년 지급, 임직원 전용 복지몰 (공식 채용 페이지 · 뉴스룸 2021 — 연간 포인트 금액 미기재) (추정)', FALSE, NULL, 11),
  (@comp_id, 'discount', '제휴처 할인', NULL, 'perks',
   'est', NULL, TRUE, '송도 및 인근 지역 제휴업체(호텔, 식당, 병원, 뷰티/미용, 스포츠/문화 등) 할인 제공 (공식 채용 페이지 가족, 의료 및 소득 지원 항목 — 할인율 미기재)', 12),
  (@comp_id, 'meal', '사내식당 하루 네 끼 무료', 864, 'perks',
   'est', '다양한 메뉴의 건강식을 하루 네 끼(조식, 중식, 석식 및 야식) 무료 제공, 바이오플라자 920석 규모 식당과 푸드코트, 테이크아웃 메뉴 무상 제공 (공식 채용 페이지 사내 문화 및 편의 항목 · 공식 홈페이지 사내복지 항목 — 식대 금액 미기재) (하루 3끼 × 1끼 12,000원 × 연 240일 추정, 야식 제외)', FALSE, NULL, 13),
  (@comp_id, 'commute_subsidy', '통근버스', NULL, 'perks',
   'est', NULL, TRUE, '서울, 경기, 인천 등 수도권 통근버스 운영, 2022년 채용 FAQ 기준 27개 출퇴근 노선 (공식 채용 페이지 사내 문화 및 편의 항목 · 공식 뉴스룸 채용 FAQ — 이용 요금 미기재)', 14),
  (@comp_id, 'snack_bar', '사내 카페·베이커리·편의점', NULL, 'perks',
   'est', NULL, TRUE, '바이오플라자 사내 카페를 임직원 할인가로 이용, 베이커리·편의점 운영 (공식 홈페이지 사내복지 항목 — 할인율 미기재)', 15),

  -- ── 가족·돌봄 (family) ── 가족, 의료 및 소득 지원 · 2026 ESG 보고서 가족친화
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사 발생 시 경조금·경조물품 지원 — 임직원 결혼 및 부모 수연 경조금, 조의물품 및 장례 지원, 불의의 화재·자연재해 피해위로금 지급 (공식 채용 페이지 가족, 의료 및 소득 지원 항목 · 2026 ESG 보고서 복지제도 항목 — 경조 유형별 금액 미기재)', 20),
  (@comp_id, 'childcare', '사내 어린이집', NULL, 'family',
   'est', NULL, TRUE, '일과 육아를 조화롭게 유지하도록 사내 어린이집 운영 (공식 채용 페이지 가족, 의료 및 소득 지원 항목 · 2026 ESG 보고서 근무환경 개선 항목 — 위치·정원 미기재)', 21),
  (@comp_id, 'parenting', '출산·육아 지원', NULL, 'family',
   'est', NULL, TRUE, '출산 및 자녀입학 선물 지원, 자녀(만 12세 또는 초등학교 6학년 이하)당 최대 2년 육아 휴직, 최소 30일~최대 1년 무급 임신 휴직, 임신 13주~30주 무급 근로시간 단축, 임부 전용 주차구역 운영 (2026 ESG 보고서 복지제도 가족친화 항목 — 선물 금액 미기재)', 22),
  (@comp_id, 'child_edu', '자녀학자금', 300, 'family',
   'est', '자녀 유치원부터 대학교까지 학자금 지원, 장애자녀 학자금 지원 (공식 채용 페이지 · 2026 ESG 보고서 — 지원 한도·자녀 수 미기재) (추정)', FALSE, NULL, 23),
  (@comp_id, 'fertility_support', '난임 지원', NULL, 'family',
   'est', NULL, TRUE, '난임 시술비 연간 100만 원 한도(1회 50만 원 한도) 지원, 난임 휴직 최소 30일~최대 3개월(4차까지, 최대 1년), 난임 치료 휴가 유급 5일(법정 유급 2일에 3일 추가) (2026 ESG 보고서 복지제도 가족친화 항목)', 24),

  -- ── 건강·의료 (health) ── 가족, 의료 및 소득 지원 · 사내 문화 및 편의 · 2026 ESG 보고서 건강증진
  (@comp_id, 'health_check', '건강검진', 100, 'health',
   'est', '임직원과 가족 대상 건강검진 지원, 배우자 검진(배우자 미진행 시 직계 부모) 지원 (공식 채용 페이지 · 2026 ESG 보고서 — 검진 비용 미기재) (추정)', FALSE, NULL, 30),
  (@comp_id, 'medical', '의료비 지원', 100, 'health',
   'est', '임직원과 가족 의료비 지원 — 비급여 MRI/MRA·CT·초음파 검사료, 배우자·자녀 1만 원 초과 의료비, 입원 중 식비 (공식 채용 페이지 · 2026 ESG 보고서 — 연간 한도 미기재) (추정)', FALSE, NULL, 31),
  (@comp_id, 'mental', '심리상담센터', NULL, 'health',
   'est', NULL, TRUE, '전문 상담사가 상주하는 사내 상담센터(바이오 마음챙김 상담소)에서 심리검사·상담, 외부 상담소 연계 및 외부 명상 프로그램 입과 지원 (공식 채용 페이지 가족, 의료 및 소득 지원 항목 · 2026 ESG 보고서 복지제도 항목 — 상담 횟수 미기재)', 32),
  (@comp_id, 'clinic', '사내 부속의원 및 약국', NULL, 'health',
   'est', NULL, TRUE, '응급상황 대비와 건강 관리를 위해 사내 부속의원 및 약국 운영, 바이오플라자 메디컬존(부속의원, 치과, 물리치료실, 근골격치료센터) (공식 채용 페이지 사내 문화 및 편의 항목 · 공식 홈페이지 사내복지 항목 — 진료비 부담 미기재)', 33),
  (@comp_id, 'fitness', '사내 피트니스', NULL, 'health',
   'est', NULL, TRUE, '전문 강사의 개인별 맞춤 트레이닝 지원, 600평 규모 피트니스 센터(퍼스널트레이닝, 필라테스, 소그룹 운동) (공식 채용 페이지 사내 문화 및 편의 항목 · 공식 홈페이지 사내복지 항목 — 이용 요금 미기재)', 34),
  (@comp_id, 'insurance', '단체보험', NULL, 'health',
   'est', NULL, TRUE, '상해사망, 질병사망 등에 대한 단체 보험 가입 (2026 ESG 보고서 복지제도 건강증진 항목 — 보장 금액·가족 범위 미기재)', 35),

  -- ── 시간·휴가 (time_off) ── 가족, 의료 및 소득 지원 · 2026 ESG 보고서 복지제도
  (@comp_id, 'long_service_leave', '장기근속 포상', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속자의 공로에 감사하고 재충전 기회를 주기 위해 장기근속 휴가 및 휴가비 지원 (공식 채용 페이지 가족, 의료 및 소득 지원 항목 · 2026 ESG 보고서 — 근속 연수별 일수·금액 미기재)', 40),
  (@comp_id, 'refresh_leave', '추가 유급휴가 3일', NULL, 'time_off',
   'est', NULL, TRUE, '부여된 휴가를 모두 사용한 전 임직원에게 추가 유급휴가 3일 부여 (2026 ESG 보고서 복지제도 항목)', 41),

  -- ── 성장·커리어 (growth) ── 자기 개발 지원 · 2026 ESG 보고서 학위 및 자격증 취득 지원
  (@comp_id, 'career', '사내 직무전환', NULL, 'growth',
   'est', NULL, TRUE, '사내 Job Posting 제도로 적극적인 직무 전환 및 Career 발전 기회 제공 (공식 채용 페이지 자기 개발 지원 항목 — 지원 자격·주기 미기재)', 50),
  (@comp_id, 'lang', '외국어 교육·시험 응시료 지원', NULL, 'growth',
   'est', NULL, TRUE, '사내 어학과정(글로벌 임직원 한국어과정 포함), 온라인 과정, 전화영어, 오픽(OPIc) 응시료 지원 (공식 채용 페이지 자기 개발 지원 외국어 교육 항목 · 공식 홈페이지 자기개발 글로벌 소양 항목), 월 1회 온라인 콘텐츠·전화영어 교육과 OPIc 등급 향상·비즈니스 회화 어학 과정 단계·분기별 실시 (2026 ESG 보고서 95쪽 글로벌 역량 강화 교육), 2022년 기준 1:1 영어 화상 강의·연간 3회 OPIc 무료 응시 (공식 뉴스룸 2022 라이프 기사) — 지원 한도 미기재', 51),
  (@comp_id, 'self_development', '자격증 취득 지원', NULL, 'growth',
   'est', NULL, TRUE, '생산, 엔지니어링, 구매, 물류, 품질, 안전환경, 재무, 인사, 비즈니스 회화 등 전 직무 분야 자격증 취득 비용 지원 (2026 ESG 보고서 학위 및 자격증 취득 지원 항목 — 지원 한도 미기재)', 52),
  (@comp_id, 'mba', '학사학위 과정 지원', NULL, 'growth',
   'est', NULL, TRUE, '인하대학교 산학협력 임직원 전용 바이오제약공학과(3~4학년 편입과정) 운영, 선발된 임직원에게 입학금·전형료·등록금·교재비 지원, 2025·2026년 각 20명 선발 (2026 ESG 보고서 학위 및 자격증 취득 지원 항목)', 53),
  (@comp_id, 'edu_support', '자율 수강 온라인 교육', NULL, 'growth',
   'est', NULL, TRUE, '계약직을 포함한 전 임직원이 경영, 리더십, 금융, 인사·총무, 재무·회계, IT 등 다양한 주제의 온라인 교육 과정을 매월 1회 자율적으로 선택해 수강 (2026 ESG 보고서 95쪽 직무별 역량 강화 교육 항목) — 과정 수·비용 부담 미기재', 54),

  -- ── 근무환경 (work_env) ── 사내 문화 및 편의 · 2026 ESG 보고서 근무환경 개선
  (@comp_id, 'dormitory', '기숙사', NULL, 'work_env',
   'est', NULL, TRUE, '최신 시설을 갖춘 사외 기숙사 지원, 신규 입사자의 송도 정착 지원, 2022년 채용 FAQ 기준 통근버스 이용이 어려운 곳에 거주하는 임직원 대상·관리비 외 기숙사 비용 전액 지원 (공식 채용 페이지 사내 문화 및 편의 항목 · 2026 ESG 보고서 · 공식 뉴스룸 채용 FAQ)', 60),
  (@comp_id, 'nap_room', '남녀 휴게실·임산부 휴게실', NULL, 'work_env',
   'est', NULL, TRUE, '근무 중 휴식을 위한 남성·여성 휴게실 운영, 임산부 전용 휴게실·수유실 운영 (2026 ESG 보고서 근무환경 개선 항목 · 공식 채용 페이지 가족, 의료 및 소득 지원 항목)', 61),

  -- ── 여가·라이프 (leisure) ── 사내 문화 및 편의 · 보도자료
  (@comp_id, 'resort', '휴양소 지원', 50, 'leisure',
   'est', '휴양소/레크리에이션 센터와 제휴해 임직원과 가족의 여가 지원, 전국 제휴 리조트·호텔 이용 (공식 채용 페이지 · 뉴스룸 2021 — 이용 횟수·비용 부담 미기재) (추정)', FALSE, NULL, 70),
  (@comp_id, 'club', '사내동호회', NULL, 'leisure',
   'est', NULL, TRUE, '사내동호회 활동비 지원, 약 50개 사내 동호회가 참여하는 Club Festival 연 2회 개최 (공식 채용 페이지 사내 문화 및 편의 항목 · 2026 ESG 보고서 조직문화 항목 — 지원 금액 미기재)', 71),
  (@comp_id, 'company_event', '임직원 가족 초청행사', NULL, 'leisure',
   'est', NULL, TRUE, '2015년부터 매년 임직원 가족을 사업장에 초청하는 가족 초청행사 개최, 2025년 3일간 약 6,500명 참여 (공식 뉴스룸 2025년 9월 보도자료 · 2026 ESG 보고서 가족친화 프로그램 항목)', 72),

  -- ── 근무유연성 (flexibility) ── 사내 문화 및 편의
  (@comp_id, 'flex_work', '선택적 근로시간제', NULL, 'flexibility',
   'est', NULL, TRUE, '임직원 개개인이 월 단위로 근무시간을 자유롭게 조정하는 선택적 근로시간제 시행, 대상은 교대근무자를 제외한 임직원 (공식 채용 페이지 사내 문화 및 편의 항목 · 2026 ESG 보고서 근무시간 조정 제도 항목 — 의무 근무 시간대 미기재)', 80),
  (@comp_id, 'remote_work', '재택근무', NULL, 'flexibility',
   'est', NULL, TRUE, '필요시 집에서 업무를 수행하는 재택근무제도 운영, 업무 특성 및 임직원 요청에 따라 재택·원격 근무 (공식 채용 페이지 사내 문화 및 편의 항목 · 2026 ESG 보고서 — 사용 한도 미기재)', 81),

  -- ── 보상·금전 (compensation) ── 2026 ESG 보고서 성과보상 체계 · 우리사주 지원제도
  (@comp_id, 'incentive', '목표·성과 인센티브', NULL, 'compensation',
   'est', NULL, TRUE, '전 직원 대상 인센티브 — 목표 인센티브(경영목표 달성에 따라 상여 기초의 0~100%, 연 2회), 성과 인센티브(경영실적 초과이익에 대해 연봉 기준 0~50%), 수시 프로젝트 인센티브 (2026 ESG 보고서 성과보상 체계 항목 — 연도별 지급률 미기재)', 90),
  (@comp_id, 'stock_option', '우리사주조합', NULL, 'compensation',
   'est', NULL, TRUE, '우리사주조합 운영, 계약직을 포함한 모든 임직원이 우리사주제도(ESOP)에 참여 가능, 2022년 우리사주 유상증자 때 보호예수기간 1년의 대출금·대출이자 회사 지원 (2026 ESG 보고서 우리사주 지원제도 항목)', 91)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
