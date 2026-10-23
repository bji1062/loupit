-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- KCC글라스 복리후생 데이터 (신규 회사 — 웨이브 15)
-- 출처: AI 파싱 (2026-10-23)
-- URL: https://www.kccglass.co.kr/career/personnelSystem/welfare.do
-- badge: est
--
-- 참고:
--   정본은 상장 법인 (주)케이씨씨글라스(표시명 KCC글라스)의 자기 도메인 www.kccglass.co.kr GNB 인재채용 > 인사제도 >
--   복리후생 페이지다. 12항목(h3 제목 + p 설명)이 서버렌더 HTML 텍스트로 있다(헤드리스 렌더 없음).
--   보조 출처 1 = 같은 도메인 채용공고 메뉴가 연결한 회사 계정 채용 사이트 kccglass.career.greetinghr.com/ko/benefit
--   BENEFITS 22항목(서버렌더 HTML). 보조 출처 2 = 같은 도메인 ESG 보고서 목록의 2025/26 ESG 보고서 국문 PDF
--   (발행 2026년 6월 · 보고 기간 2025-01-01~12-31 · 보고 범위 KCC글라스 본사 및 국내 사업장) 83 · 89 · 98 · 100 · 101 · 102쪽
--   (인쇄 쪽 · PDF 는 두 쪽 펼침). 보조 출처 3 = 같은 도메인 인사제도 직급체계 · 평가 · 보상 페이지 보상체계 항목.
--   보조 출처 4 = OpenDART 2026 반기보고서(접수 20260820000314 · 기재정정) 유연근무제도 사용 현황 표.
--   귀속: 세 자기 출처 모두 주어가 KCC글라스 단수다. 그룹 각주 없음. 보고서 해외법인(PT. KCC GLASS INDONESIA) 절은 쓰지 않았다.
--   형제 KCC(기등록) 정본과 문장이 일부 같으나(사택/기숙사 · 자녀학자금 · 동호회 · 건강검진 · 의료비) 이 법인 자기 도메인 원문만 인용.
--   금액: 원문 금액은 출산 경조금(1회성) · 경진대회 상금(1회성)뿐이라 28행 전부 BENEFIT_AMT NULL(정성)이다.
--   제외: 퇴직연금제도 · 출산 전후 휴가 90일 · 유산 사산 휴가 · 육아휴직 최대 1년 6개월(법정 상한과 같음) · 재취업 지원 프로그램
--   (고령자고용법 · 직원 2,045명) · 대사증후군 관리 프로그램(유소견자 사후관리) · 근골격계 유해요인 조사 사후관리 · 연장근무 대체휴무 ·
--   정시퇴근 장려 문구 · 사내 온라인 직무교육 · 온보딩 · 직급 · 직무교육 · 휴게공간 설치 추진(인권영향평가 개선조치) · 해외법인 제도 ·
--   사회공헌 명절선물 · 사내이사 보수 칸.
--   공고 근거 0행 / 전체 28행.
--   SORT 섹션 순서(정본 페이지에서 처음 나온 순서, 보조 출처 전용 카테고리는 끝):
--   health 10 · perks 20 · family 30 · work_env 40 · growth 50 · leisure 60 · time_off 70 · flexibility 80 · compensation 90.
-- 검증 · 감사 판정 반영(2026-10-23): 행 조치 없음 · KCC 와 겹친 문장은 자기 도메인 원문이라 각주 없음 · 심리상담은 발행일 있는 보고서 연 6회 · 유형 large(공정위공시 대규모기업집단현황공시 개별회사용 제출 = 공시대상기업집단 KCC 소속) · 업종 가구 인테리어 합류 · 항목 페이지 예외 5(통합 밖 리드 집행) — 최종 28행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('kcc_glass', 'KCC글라스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '가구/인테리어', 'K', 'https://www.kccglass.co.kr/career/personnelSystem/welfare.do');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'kcc_glass');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.kccglass.co.kr/career/personnelSystem/welfare.do'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강 (health) — 정본 페이지 의료비 · 휘트니스 · 건강검진 · 채용 사이트 · 보고서 83 · 98 · 102쪽 ──
  (@comp_id, 'medical', '의료비 지원 (본인·배우자·자녀)', NULL, 'health',
   'est', NULL, TRUE, '본인, 배우자 및 자녀의 의료비를 지원하여 정신적, 경제적 부담 경감 (공식 채용 페이지 복리후생 의료비 지원 항목 · 공식 채용 사이트 BENEFITS 의료비 지원 항목), 임직원, 배우자 및 자녀 의료비 지원 (2025/26 ESG 보고서 102쪽 대표 복리후생제도 가족의료비 항목) — 지원 한도·본인 부담률 미기재', 10),
  (@comp_id, 'fitness', '휘트니스 센터·체력단련실 운영', NULL, 'health',
   'est', NULL, TRUE, '건강증진을 위하여 헬스장 등 운영 (공식 채용 페이지 복리후생 휘트니스 센터 운영 항목), 임직원의 건강과 체력 증진을 위한 사내 체력단련실 운영 (공식 채용 사이트 BENEFITS 체력단련실 운영 항목) — 운영 사업장·이용료 미기재', 11),
  (@comp_id, 'health_check', '건강검진 (임직원·배우자)·예방접종·검진 유급휴가', NULL, 'health',
   'est', NULL, TRUE, '매년 직원 건강검진 실시 (공식 채용 페이지 복리후생 건강검진실시 항목), 임직원 및 배우자 건강검진 지원, 대상포진 (만 55세 이상 임직원 중 희망자)·폐렴 (만 50세 이상 임직원 중 희망자) 예방접종 (2025/26 ESG 보고서 102쪽 대표 복리후생제도 건강지원 항목), 건강검진 휴무 제도 유급휴가를 2026년부터 기존 4시간에서 8시간(전일)으로 확대 (같은 보고서 98쪽 노사협의회 주요 협의 내용 항목) — 검진 항목·비용 지원 범위 미기재', 12),
  (@comp_id, 'mental', '임직원 심리상담 (연 6회)', NULL, 'health',
   'est', NULL, TRUE, '연 6회 임직원 심리상담 서비스 제공 (비밀 유지) (2025/26 ESG 보고서 102쪽 대표 복리후생제도 심리상담 항목), 심리상담 프로그램 인당 이용 횟수를 기존 4회에서 6회로 확대 (같은 보고서 98쪽 노사협의회 주요 협의 내용 항목), 전국 각지의 심리 상담 센터와의 제휴를 통한 심리상담 서비스 (공식 채용 사이트 BENEFITS 임직원 심리상담 항목) — 비용 부담·가족 이용 여부 미기재', 13),
  (@comp_id, 'clinic', '건강관리실', NULL, 'health',
   'est', NULL, TRUE, '근로자가 필요시 언제든지 이용할 수 있도록 건강관리실 운영, 상비약 및 응급의약품 비치, 외상 및 응급처치, 건강상담, 혈압·혈당 측정 등 건강 관리 서비스 (2025/26 ESG 보고서 83쪽 임직원 건강증진 및 보건 관리 항목) — 운영 사업장·상주 인력 미기재', 14),

  -- ── 생활·금융 (perks) — 정본 페이지 주택자금 대부 · WORK-LIFE BALANCE · 채용 사이트 · 보고서 102쪽 ──
  (@comp_id, 'housing_loan', '주택자금 대부 (무주택 사원)', NULL, 'perks',
   'est', NULL, TRUE, '직원의 생활안정을 위하여 무주택 사원에 대하여 주택자금 대부 지원 (공식 채용 페이지 복리후생 주택자금 대부 항목), 무주택 사원에 대하여 장기 저리로 주택자금 대부 (공식 채용 사이트 BENEFITS 주택자금 대부 항목), 주택 구입, 전세, 생활 안정 등에 필요한 대부금 지원 (2025/26 ESG 보고서 102쪽 대표 복리후생제도 대부금 지원 항목) — 대부 한도·이율·상환 기간 미기재', 20),
  (@comp_id, 'transport', '장거리 근무자 주말 귀향비 지원', NULL, 'perks',
   'est', NULL, TRUE, '즐거운 직장생활 영위를 위하여 장거리 근무자의 주말 귀향비 지원 (공식 채용 페이지 복리후생 WORK-LIFE BALANCE 항목) — 지원 금액·지원 횟수 미기재', 21),
  (@comp_id, 'meal', '사내 식당 운영', NULL, 'perks',
   'est', NULL, TRUE, '건강하고 맛있는 식사를 제공하는 사내 식당 운영 (공식 채용 사이트 BENEFITS 사내 식당 운영 항목) — 제공 끼니·본인 부담 미기재', 22),
  (@comp_id, 'commute_subsidy', '사업장 셔틀버스 운영', NULL, 'perks',
   'est', NULL, TRUE, '각 지역별 통근버스를 배차하여 안전하고 효율적인 출퇴근 지원 (공식 채용 사이트 BENEFITS 각 사업장 셔틀버스 운영 항목) — 운행 사업장·노선 미기재', 23),
  (@comp_id, 'discount', '차량 구매 할인·현대백화점 할인', NULL, 'perks',
   'est', NULL, TRUE, '제휴된 자동차 브랜드 또는 딜러사를 통해 차량 구매 시 할인 혜택 (공식 채용 사이트 BENEFITS 차량 구매 할인 혜택 제공 항목), 현대백화점 10% 상시 할인 혜택 (같은 사이트 현대백화점 패밀리카드 혜택 항목) — 제휴 브랜드·차량 할인율 미기재', 24),

  -- ── 가족 (family) — 정본 페이지 자녀학자금 · 경조사 · 채용 사이트 · 보고서 102쪽 ──
  (@comp_id, 'child_edu', '자녀 학자금 지원 (고등학생 이상)', NULL, 'family',
   'est', NULL, TRUE, '자녀 교육에 따른 경제적 부담을 덜어주기 위하여 고등학생 이상 자녀의 학자금 지원 (공식 채용 페이지 복리후생 자녀학자금 지원 항목 · 공식 채용 사이트 BENEFITS 자녀학자금 지원 항목, 2025/26 ESG 보고서 102쪽 대표 복리후생제도 자녀학자금 항목) — 지원 한도·자녀 수 제한 미기재', 30),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사 발생 시 경조휴가 부여, 경조금, 경조화환(조화) 장례물품 지원 (공식 채용 페이지 복리후생 경조사 지원 항목 · 공식 채용 사이트 BENEFITS 경조사 지원 항목), 결혼, 사망, 환갑, 출산 시 경조휴가 및 지원금 지급 (2025/26 ESG 보고서 102쪽 대표 복리후생제도 경조사 지원 항목) — 경조 구분별 금액·휴가 일수 미기재', 31),
  (@comp_id, 'childcare', '사내 어린이집', NULL, 'family',
   'est', NULL, TRUE, 'KCC 직장어린이집에서 쾌적한 보육환경과 자녀를 위한 체계적인 보육과정, 전문 영양사의 급식과 간식 제공 (공식 채용 사이트 BENEFITS 사내 어린이집 운영 항목), 사내 어린이집 설치 및 운영 (2025/26 ESG 보고서 102쪽 대표 복리후생제도 육아 항목) — 운영 사업장·정원 미기재', 32),
  (@comp_id, 'parenting', '출산 축하금 (출산 경조금)', NULL, 'family',
   'est', NULL, TRUE, '출산 시 축하금 지원 (공식 채용 사이트 BENEFITS 출산 장려금 지원 항목), 자녀 출산시 출산 경조금 지급 (첫째 50만 원, 둘째 100만 원, 셋째 이후 200만 원) (2025/26 ESG 보고서 102쪽 대표 복리후생제도 출산 항목) — 지급 시기 미기재', 33),

  -- ── 근무환경 (work_env) — 정본 페이지 사택/기숙사 운영 · 채용 사이트 ──
  (@comp_id, 'dormitory', '사택/기숙사 운영', NULL, 'work_env',
   'est', NULL, TRUE, '거주지로부터 멀리 떨어져 근무하는 직원에게 사택/기숙사 지원 (공식 채용 페이지 복리후생 사택/기숙사 운영 항목 · 공식 채용 사이트 BENEFITS 사택/기숙사 운영 항목) — 입주 자격·본인 부담·운영 사업장 미기재', 40),

  -- ── 성장·교육 (growth) — 정본 페이지 자기계발 지원 · 채용 사이트 · 보고서 100쪽 ──
  (@comp_id, 'lang', '사내 외국어 강좌·화상 영어회화', NULL, 'growth',
   'est', NULL, TRUE, '직원의 자기계발을 위하여 사내 외국어 강좌 운영 (공식 채용 페이지 복리후생 자기계발 지원 항목), 화상 영어회화 지원 (공식 채용 사이트 BENEFITS 자기계발 지원 항목), 사내 온라인 교육 플랫폼을 통한 일상 회화부터 OPIc, TOEIC, TOEIC Speaking 등 공인 어학 시험 대비 과정, 원어민과의 화상 영어 프로그램 (2025/26 ESG 보고서 100쪽 어학교육 항목) — 수강 대상·수강료 부담 미기재', 50),
  (@comp_id, 'edu_support', '온라인 강좌·사외교육비 지원', NULL, 'growth',
   'est', NULL, TRUE, '직원의 자기계발을 위하여 온라인 강좌 운영 (공식 채용 페이지 복리후생 자기계발 지원 항목), 직무 관련 사외교육비 지원 (공식 채용 사이트 BENEFITS 자기계발 지원 항목) — 지원 한도·수강 가능 과정 미기재', 51),

  -- ── 여가 (leisure) — 정본 페이지 REFRESH SUPPORT · 동호회 지원 · 채용 사이트 · 보고서 102쪽 ──
  (@comp_id, 'resort', '휴양소·콘도미니엄·KCC가족 캠핑장', NULL, 'leisure',
   'est', NULL, TRUE, '콘도미니엄 지원 (공식 채용 페이지 복리후생 REFRESH SUPPORT 항목), 다양한 휴양소와의 제휴를 통해 임직원과 가족들이 함께 여가를 보낼 수 있도록 지원 (공식 채용 사이트 BENEFITS 휴양소 지원 항목), 휴양소 및 KCC가족 캠핑장 이용 지원 (2025/26 ESG 보고서 102쪽 대표 복리후생제도 가족 휴양시설 제공 항목) — 이용 일수·본인 부담 미기재', 60),
  (@comp_id, 'summer_vacation_subsidy', '휴가비 지원 (REFRESH SUPPORT)', NULL, 'leisure',
   'est', NULL, TRUE, '휴가비를 지원하여 몸과 마음의 재충전 지원 (공식 채용 페이지 복리후생 REFRESH SUPPORT 항목) — 지급 금액·지급 시기 미기재', 61),
  (@comp_id, 'club', '동호회 지원', NULL, 'leisure',
   'est', NULL, TRUE, '다양한 동호회 활동을 통한 여가 선용 및 친목 도모 지원 (공식 채용 페이지 복리후생 동호회 지원 항목 · 공식 채용 사이트 BENEFITS 동호회 지원 항목, 2025/26 ESG 보고서 102쪽 대표 복리후생제도 동호회 활동 지원 항목) — 동호회 수·지원 금액 미기재', 62),

  -- ── 휴가 (time_off) — 채용 사이트 휴식 지원 · 장기근속 포상 ──
  (@comp_id, 'leave_general', '2시간 단위 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '2시간 단위의 유연한 휴가 사용 (공식 채용 사이트 BENEFITS 휴식 지원 항목) — 사용 한도·신청 절차 미기재', 70),
  (@comp_id, 'summer_leave', '하계휴가 (5일)', NULL, 'time_off',
   'est', NULL, TRUE, '임직원 재충전을 위해 법정 휴가 외에 하계휴가(5일) 별도 제공 (공식 채용 사이트 BENEFITS 휴가 제도 항목) — 사용 시기 미기재', 71),
  (@comp_id, 'long_service_leave', '장기근속 포상 (유급 휴가·콘도 숙박권)', NULL, 'time_off',
   'est', NULL, TRUE, '근속 년수에 따라 유급 휴가 및 고급 콘도 숙박권 지급 (공식 채용 사이트 BENEFITS 장기근속 포상 항목) — 근속 기준·휴가 일수 미기재', 72),

  -- ── 근무 유연성 (flexibility) — 채용 사이트 PC-OFF · 보고서 102쪽 · 2026 반기보고서 ──
  (@comp_id, 'pc_off', 'PC-OFF 제도', NULL, 'flexibility',
   'est', NULL, TRUE, '정시 퇴근을 장려하는 자동 컴퓨터 종료 시스템 운영 (공식 채용 사이트 BENEFITS PC-OFF 제도 운영 항목) — PC 차단 시각·예외 승인 절차 미기재', 80),
  (@comp_id, 'flex_work', '선택적 근로시간제·시차출퇴근제·탄력적 근로시간제', NULL, 'flexibility',
   'est', NULL, TRUE, '정해진 근로시간 총량을 기반으로 출퇴근 시간을 자율적으로 설정하는 선택적 근로시간제, 프로젝트성 업무 등으로 근로시간 초과가 예상되는 부서의 탄력적 근로시간제 (2025/26 ESG 보고서 102쪽 근로시간 제도 개선 항목), 시차출퇴근제·선택근무제 (2026 반기보고서 유연근무제도 사용 현황 항목) — 적용 대상 직군·의무 근무시간대 미기재', 81),
  (@comp_id, 'remote_work', '재택근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '회사가 아닌 자택 등의 공간에서 장소의 구애 없이 근무할 수 있는 재택근무제 시행 (2025/26 ESG 보고서 102쪽 근로시간 제도 개선 항목), 원격근무제(재택근무 포함) (2026 반기보고서 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 82),

  -- ── 보상·금전 (compensation) — 같은 도메인 인사제도 보상체계 · 보고서 89 · 101쪽 ──
  (@comp_id, 'incentive', '성과급 (PS·PI)', NULL, 'compensation',
   'est', NULL, TRUE, '연간 업무성과에 따른 성과급 지급 (공식 채용 페이지 인사제도 보상체계 항목), 연말 경영성과급(PS), 핵심인재 인센티브(PI) 등 금전적 보상 제도 운영, 평가 결과에 따라 성과급 지급 액수 차등 적용 (2025/26 ESG 보고서 101쪽 객관적이고 합리적인 보상 항목) — 지급 기준·지급률 미기재', 90),
  (@comp_id, 'excellence_award', '혁신 활동 포상·품질분임조 경진대회', NULL, 'compensation',
   'est', NULL, TRUE, '임직원의 자발적인 개선 활동 장려를 위해 개별 과제 평가를 통해 혁신 활동 성과 우수자에게 포상 실시, 전사 품질분임조 경진대회 금상 과제에 상금 1천만 원 전달 (2025/26 ESG 보고서 89쪽 경영혁신대회 항목) — 포상 기준·포상 주기 미기재', 91)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
