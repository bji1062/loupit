-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 교보증권 복리후생 데이터 (신규 회사 — 웨이브 7)
-- 출처: AI 파싱 (2026-10-14)
-- URL: https://www.iprovest.com/compintro/esg/esgReport.htm
-- badge: est
--
-- 참고:
--   정본은 상장 법인 교보증권(주)의 자기 도메인 www.iprovest.com 회사소개 > 지속가능경영 > 통합보고서 목록 페이지다(EUC-KR · SSR).
--   행의 근거는 그 목록에 올라 있는 법인 단독 발행 2025 교보증권 통합보고서 국문 PDF
--   (발행 2026년 6월 · 보고 기간 2025-01-01~2025-12-31 · ESG 데이터 산정 범위 교보증권 서울 본사 및 국내 지점)
--   18쪽 이해관계자 소통 표 · 25쪽 주요 리스크 관리 현황 · 42쪽 CS 교육 · 59쪽 보상 체계 · 60쪽 인재 양성 ·
--   61쪽 일과 삶의 균형 및 복리후생 제도 표 · 62쪽 임직원 건강 및 안전.
--   공시 보조: OpenDART 2026 반기보고서(접수 20260814003361) 유연근무제도 사용현황 표와 재무제표 주석 특수관계자 거래(종업원 주택자금 대여).
--   채용 사이트 iprovest.recruiter.co.kr/career/benefits 는 본문이 robots 전면 금지 벤더 API 호스트에만 있어 읽지 않았다.
--   귀속: 보고서 주어가 모두 교보증권은 이고 그룹 공통 단서가 없다. 자기 발행 단독 보고서라 각주 없음.
--   기등록 형제(교보생명 계열) 코퍼스 0곳.
--   금액: 생일 케이크 포인트 5만 원 1행만 stated(5). 개인연금 50% 등 비율 · 대여 총액은 금액 아님 — 나머지 NULL.
--   제외: 법정(육아휴직 · 임신기 단축 · 배우자 출산휴가 사용 현황 · 산업안전보건 · 건강장해 예방 교육) ·
--     업무 교육(승진자 · 신입 입문 · 여성 리더 · 차세대 리더 · AI 리터러시 · 직능 · ESG 교육 · 관계사 디지털 교육) ·
--     자율복장제도(대응 코드 없음) · 명령휴가(내부통제 점검 제도) · 우리사주조합(주주 표 한 칸뿐) ·
--     임원 보수 산정 칸의 복지규정 복리후생비 · 사회공헌 봉사 프로그램 · 노사협의회.
--   공고 근거 0행 / 전체 21행.
--   SORT 섹션 순서 = 보고서 등장 순(leisure 10 · flexibility 20 · compensation 30 · health 40 · family 50 ·
--     growth 60 · time_off 70 · perks 80).
-- 검증 · 감사 판정 반영(2026-10-14): 반반차 행 이름 · 서술을 2시간 단위 휴가로(리드 판정 119) — 최종 21행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('kyobo_securities', '교보증권',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '증권', 'K', 'https://www.iprovest.com/compintro/esg/esgReport.htm');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'kyobo_securities');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.iprovest.com/compintro/esg/esgReport.htm'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 여가 (leisure) — 2025 통합보고서 18 · 61쪽 ──
  (@comp_id, 'club', '사내동호회', NULL, 'leisure',
   'est', NULL, TRUE, '임직원과의 커뮤니케이션 채널로 사내동호회 운영 (2025 통합보고서 18쪽 이해관계자 소통 표 임직원 항목) — 동호회 지원 내용·지원 금액 미기재', 10),
  (@comp_id, 'resort', '법인 콘도 회원가 지원', NULL, 'leisure',
   'est', NULL, TRUE, '법인 콘도 회원가 지원, 대상 전 임직원 (2025 통합보고서 61쪽 복리후생 제도 표 항목) — 콘도 이름·이용 횟수 미기재', 11),
  -- ── 근무 유연성 (flexibility) — 2025 통합보고서 18 · 61쪽 · 2026 반기보고서 ──
  (@comp_id, 'flex_work', '유연근로제·시차출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근로제(선택적 근로시간제) 운영 (2025 통합보고서 61쪽 일과 삶의 균형 항목), 유연근무제 (2025 통합보고서 18쪽 이해관계자 소통 표 임직원 대응활동 항목), 시차출퇴근제 · 선택근무제 (2026 반기보고서 유연근무제도 사용현황 항목) — 대상 직무·코어타임 미기재', 20),
  (@comp_id, 'pc_off', 'PC-OFF 제도', NULL, 'flexibility',
   'est', NULL, TRUE, 'PC-OFF 제도 운영 (2025 통합보고서 61쪽 일과 삶의 균형 항목, 18쪽 이해관계자 소통 표 임직원 대응활동 항목) — 적용 시각·대상 미기재', 21),
  (@comp_id, 'remote_work', '원격근무제 (조건부)', NULL, 'flexibility',
   'est', NULL, TRUE, '원격근무제(재택근무 포함), 재택근무 부분적 허용 (2026 반기보고서 유연근무제도 사용현황 항목) — 대상 직무·사용 조건 미기재', 22),
  -- ── 보상 (compensation) — 2025 통합보고서 25 · 42 · 59 · 61쪽 ──
  (@comp_id, 'excellence_award', '표창·포상제도', NULL, 'compensation',
   'est', NULL, TRUE, '표창 및 포상제도 개선으로 우수직원 선정 평가기준 세분화 및 포상 범위 확대 (2025 통합보고서 25쪽 주요 리스크 관리 현황 항목), CS 전화 모니터링 결과와 연계한 우수 직원 포상 제도 (2025 통합보고서 42쪽 CS 교육 강화 항목) — 포상 금액·포상 내용 미기재', 30),
  (@comp_id, 'profit_sharing', '집단성과급', NULL, 'compensation',
   'est', NULL, TRUE, '집단성과급 및 지원성과급, 매 사업연도 당사 실적에 따라 연봉 기준 차등 지급 (2025 통합보고서 59쪽 영업 및 지원 부문 보상 체계 표 항목), 지원직은 전직원 대상 집단성과급 외에 별도의 성과급 운영 (2025 통합보고서 59쪽 직원 보상 체계 항목) — 지급률 미기재', 31),
  (@comp_id, 'incentive', '영업 부문 성과급', NULL, 'compensation',
   'est', NULL, TRUE, '본사 영업부문은 영업조직 성과급제도에 따라 성과급 재원을 성과 기여에 따라 개인에게 차등 배분, 지점 영업부문은 WM사업본부 성과급제에 따라 개인별 영업실적에 따른 보상 (2025 통합보고서 59쪽 직원 보상 체계 항목) — 지급 기준·지급률 미기재', 32),
  (@comp_id, 'holiday_gift', '명절 귀성비·가정의 달 지원금', NULL, 'compensation',
   'est', NULL, TRUE, '명절 귀성비 및 가정의 달(5월) 지원금, 대상 전 임직원 (2025 통합보고서 61쪽 복리후생 제도 표 항목) — 지급 금액 미기재', 33),
  -- ── 건강 (health) — 2025 통합보고서 25 · 61 · 62쪽 ──
  (@comp_id, 'mental', '심리상담 프로그램·다솜헬스케어', NULL, 'health',
   'est', NULL, TRUE, '외부 전문 상담가의 심리상담 프로그램(직장내 대인관계, 직무 스트레스 등) 운영으로 임직원 1인당 연 6회 상담 지원 (2025 통합보고서 62쪽 임직원 건강 및 안전 항목), 임직원 및 가족 대상 건강관리 상담·심리지원 서비스인 다솜헬스케어 서비스 운영 (2025 통합보고서 25쪽 주요 리스크 관리 현황 항목) — 가족 범위 미기재', 40),
  (@comp_id, 'health_check', '종합건강검진', NULL, 'health',
   'est', NULL, TRUE, '전 임직원에게 매년 1회 종합건강검진 제공, 임직원의 부모 또는 배우자 검진 격년 지원 (2025 통합보고서 62쪽 임직원 건강 및 안전 항목), 선택형 검진기관 추가 운영 (2025 통합보고서 25쪽 주요 리스크 관리 현황 항목) — 검진 비용 지원 범위 미기재', 41),
  (@comp_id, 'medical', '의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '의료비 지원, 대상 전 임직원 (2025 통합보고서 61쪽 복리후생 제도 표 항목) — 지원 대상 가족 범위·지원 한도 미기재', 42),
  -- ── 가족 (family) — 2025 통합보고서 25 · 61쪽 ──
  (@comp_id, 'childcare', 'KRX 어린이집', NULL, 'family',
   'est', NULL, TRUE, 'KRX 어린이집 추가 운영으로 직원 자녀 보육 지원 확대 (2025 통합보고서 25쪽 주요 리스크 관리 현황 항목) — 이용 정원·위치 미기재', 50),
  (@comp_id, 'child_edu', '학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '학자금 지원, 대상 전 임직원 (2025 통합보고서 61쪽 복리후생 제도 표 항목) — 지원 대상·지원 한도 미기재', 51),
  (@comp_id, 'event', '경조금', NULL, 'family',
   'est', NULL, TRUE, '각종 경조금, 대상 전 임직원 (2025 통합보고서 61쪽 복리후생 제도 표 항목) — 경조 유형별 금액·경조휴가 미기재', 52),
  -- ── 성장 (growth) — 2025 통합보고서 60쪽 ──
  (@comp_id, 'edu_support', '이러닝·구독형 학습 시스템', NULL, 'growth',
   'est', NULL, TRUE, '이러닝 상시 학습 제도와 구독형(HRD FLEX) 마이크로러닝 학습 시스템으로 직원이 원하는 분야의 교육 무제한 수강 지원 (2025 통합보고서 60쪽 인재 양성 항목) — 과정 목록 미기재', 60),
  (@comp_id, 'mba', '석사 학위 취득 지원 (선발)', NULL, 'growth',
   'est', NULL, TRUE, '교보그룹AI빅데이터 석사학위 취득과정 선발 및 지원 (2025 통합보고서 60쪽 2025년 주요 임직원 교육 표 항목), 석사 학위 취득/최고위 과정 교육 지원 (2025 통합보고서 60쪽 차세대 리더 육성 항목) — 선발 기준·지원 범위 미기재', 61),
  -- ── 휴가 (time_off) — 2025 통합보고서 61쪽 ──
  (@comp_id, 'leave_general', '2시간 단위 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '2시간 단위로 나누어 쓰는 휴가제 운영 (2025 통합보고서 61쪽 일과 삶의 균형 항목) — 사용 한도·신청 절차 미기재', 70),
  -- ── 생활 · 금융 (perks) — 2025 통합보고서 61쪽 · 2026 반기보고서 ──
  (@comp_id, 'pension_support', '개인연금 지원', NULL, 'perks',
   'est', NULL, TRUE, '개인연금 월 보험료 50% 지원, 대상 근속 1년 이상 정규직 직원 (2025 통합보고서 61쪽 복리후생 제도 표 항목) — 지원 한도 미기재', 80),
  (@comp_id, 'birthday_gift', '생일 케이크 포인트', 5, 'perks',
   'est', '생일자 임직원 복지몰 5만 원 생일 케이크 포인트, 대상 전 임직원 (2025 통합보고서 61쪽 복리후생 제도 표 항목)', FALSE, NULL, 81),
  (@comp_id, 'housing_loan', '주택자금 대여', NULL, 'perks',
   'est', NULL, TRUE, '주택매입 및 주택전세의 용도로 종업원에게 대여 (2026 반기보고서 재무제표 주석 특수관계자 거래 항목) — 대여 한도·이율·신청 요건 미기재', 82)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
