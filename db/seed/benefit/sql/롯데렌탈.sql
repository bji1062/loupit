-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 롯데렌탈 복리후생 데이터 (신규 회사 — 웨이브 7)
-- 출처: AI 파싱 (2026-10-14)
-- URL: https://www.lotterental.com/cmm/fms/FileDown.do?atchFileId=FILE_000000000000480&fileSn=1
-- badge: est
--
-- 참고:
--   정본은 상장 법인 롯데렌탈(주)이 자기 도메인 www.lotterental.com 지속가능경영 > ESG경영 목록에 올린
--   「롯데렌탈 지속가능경영보고서 2025」 국문 PDF(발행처 롯데렌탈 · 2026년 6월 발행 · 104쪽 · 보고 기간 2025-01-01~2025-12-31
--   일부 2026 상반기 포함 · 비재무 범위 상장법인 롯데렌탈 본사 및 국내 전 사업장 중심, 일부 성과만 자회사 포함).
--   복리후생 47쪽(LIFE CYCLE 맞춤형 복지 · 우리사주 이자 지원 · 노사협의회 · 복리후생 현황 표) · 44쪽(워라밸 제도) ·
--   43쪽(성장 지원 · 가족친화 · 육아) · 45 · 46쪽(리더데이 · Help Cloud · 해피리워드) · 40쪽(사내 카페) · 39쪽(사내공모) ·
--   41쪽(교육체계도) · 11쪽(중요 이슈 표) · 4쪽(CEO 메시지).
--   보조: 같은 도메인 PR센터 보도자료 2026-09-11 일자리 으뜸기업 2년 연속 선정(GET 으로 열림 · SSR) — 보고서보다 새 판이라
--   육아휴직 · 자녀돌봄휴직 · 난임 · 임산부 교통비 · 리더데이 문장은 이쪽을 앞에 둔다. OpenDART 2026 반기보고서
--   (접수 20260814001915) 유연근무제도 사용 현황 표(시차출퇴근제 · 원격근무제 · 유자녀 근로자 대상 선택적 재택근무).
--   렌더: 보고서 PDF 텍스트 추출 · 보도자료 원본 HTML · 헤드리스 렌더 없음 · 이미지 판독 없음.
--   인재채용 페이지 /homepage/html/web/recruit/ 는 robots 가 모든 봇에 막아 받지 않았다(정본 아님).
--   귀속: 보고서 · 보도자료 모두 롯데렌탈 주어 문장 · 자기 발행 · 그룹 공통 단서 없음 → 각주 없음.
--   롯데그룹 계열(최대주주 호텔롯데) · 2026-08-11 최대주주 지분 61.17퍼센트 매각 계약 체결(거래 종결 전, 반기보고서).
--   자회사(롯데오토리스 · 롯데오토케어 · 그린카)와 해외법인 몫은 싣지 않았다.
--   금액: 전 행 NULL(원문 숫자는 출산 경조금 200만 원 · 난임시술비 100만 원 · 임산부 교통비 월 최대 50만 원 —
--   1회성 · 조건부 · 한도라 금액 칸에 넣지 않았다).
--   제외: 법정(연차 · 반일 휴가 · 기본 육아휴직 · 임신 중 육아휴직 · 임신 육아기 근로시간 단축 · 출산휴가) ·
--   권장(단체 휴가 권장일) · 업무 교육(직급 · 리더십 · 승진자 · 네트워킹 스쿨 · Skill boost · 신입) ·
--   소통 채널(맛있는 수다 · 와글와글스토밍 · 리얼보이스 · One Team) · 해외법인 우수 직원 초청 연수(다른 법인) ·
--   고충 처리 절차 안의 심리 상담 연결 · 근무환경 개선 공사 · 고객용 셔틀버스 · 임원 보수 칸 문장.
--   공고 근거 0행 / 전체 32행. 신규 코드 0.
--   SORT 섹션 순서 = 보고서 등장 순(flexibility 10 · time_off 20 · family 30 · leisure 40 · growth 50 · perks 60 ·
--   compensation 70 · health 80).
-- 검증 · 감사 판정 반영(2026-10-14): 업무상 병가 의료비 medical 삭제(법정 요양보상 · 산재) · 남성 육아휴직 의무화는 유지(리드 판정 123) — 최종 31행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('lotte_rental', '롯데렌탈',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '자동차렌탈', 'L', 'https://www.lotterental.com/cmm/fms/FileDown.do?atchFileId=FILE_000000000000480&fileSn=1');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'lotte_rental');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.lotterental.com/cmm/fms/FileDown.do?atchFileId=FILE_000000000000480&fileSn=1'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무 유연성 (flexibility) — 보고서 4 · 44쪽 · 2026 반기보고서 · 보도자료 ──
  (@comp_id, 'family_day', '해피프라이데이', NULL, 'flexibility',
   'est', NULL, TRUE, '월 2회 금요일에 2시간 일찍 퇴근하는 조기 퇴근 프로그램 해피프라이데이 (2025 지속가능경영보고서 44쪽 워라밸 제도 항목), 해피 프라이데이 월 2회 2시간 조기 퇴근 지원 (2026-09-11 공식 보도자료 일자리 으뜸기업 항목) — 적용 대상 직군 미기재', 10),
  (@comp_id, 'flex_work', '유연근무제·시차출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '육아와 자기 계발 등의 상황에 맞춰 근무 시간을 유연하게 조절할 수 있는 유연근무제 시행 (2025 지속가능경영보고서 44쪽 워라밸 제도 항목), 출퇴근 시간을 결정할 수 있는 시차출퇴근제 (2026 반기보고서 유연근무제도 사용 현황 항목) — 출근 시간대 선택 범위 미기재', 11),
  (@comp_id, 'remote_work', '자녀돌봄 재택근무 (해피워크)', NULL, 'flexibility',
   'est', NULL, TRUE, '갑작스러운 자녀돌봄이 필요한 워킹맘, 워킹대디를 위한 재택근무 프로그램 해피워크 (2025 지속가능경영보고서 44쪽 워라밸 제도 항목), 유자녀 근로자 대상 선택적 재택근무 · 원격근무제(재택근무 포함) (2026 반기보고서 유연근무제도 사용 현황 항목) — 사용 한도·신청 조건 미기재', 12),

  -- ── 휴가 (time_off) — 보고서 4 · 44쪽 · 보도자료 ──
  (@comp_id, 'birthday_leave', '생일 3시간 조기 퇴근 (생일축하한DAY)', NULL, 'time_off',
   'est', NULL, TRUE, '생일을 맞은 임직원이 3시간 일찍 퇴근하여 특별한 날을 보낼 수 있도록 하는 조기 퇴근 프로그램 생일축하한DAY (2025 지속가능경영보고서 44쪽 워라밸 제도 항목)', 20),
  (@comp_id, 'summer_leave', '하계휴가 5일', NULL, 'time_off',
   'est', NULL, TRUE, '하계휴가 4일에서 5일로 확대 (2025 지속가능경영보고서 44쪽 확대된 휴가 제도 항목) — 추가 휴가인지·유급 여부 미기재', 21),
  (@comp_id, 'leave_general', '2시간 단위 휴가·배우자 해외 동반 휴직', NULL, 'time_off',
   'est', NULL, TRUE, '2시간 단위 휴가 제도 운영 (2025 지속가능경영보고서 44쪽 확대된 휴가 제도 항목), 배우자의 해외 근무로 가족과 함께 출국해야 하는 임직원을 위한 휴직제도 (2026-09-11 공식 보도자료 일자리 으뜸기업 항목) — 사용 한도·휴직 기간 미기재', 22),

  -- ── 가족 (family) — 보도자료 · 보고서 43 · 44 · 47쪽 ──
  (@comp_id, 'parenting', '육아휴직 최대 2년·자녀돌봄휴직·출산 경조금', NULL, 'family',
   'est', NULL, TRUE, '육아휴직 사용이 가능한 자녀 연령 기준을 만 8세에서 만 12세로 확대, 육아휴직을 최대 2년까지 사용할 수 있도록 지원, 만 12세 이하 또는 초등학교 6학년 이하 자녀를 둔 모든 근로자가 이용할 수 있는 자녀돌봄휴직, 출산 시 200만 원의 경조금 지급 (2026-09-11 공식 보도자료 일자리 으뜸기업 항목), 남성 육아휴직 의무화 · 출산 축하금 (2025 지속가능경영보고서 44 · 47쪽 일과 삶의 균형 항목) — 휴직 중 급여 지원 미기재', 30),
  (@comp_id, 'child_edu', '자녀 학자금', NULL, 'family',
   'est', NULL, TRUE, '임직원 자녀 학자금 (2025 지속가능경영보고서 47쪽 LIFE CYCLE 복리후생 현황 표 항목), 자녀의 성장 단계에 맞춘 학자금 지원제도 운영 (2026-09-11 공식 보도자료 일자리 으뜸기업 항목) — 지원 학령·한도 미기재', 31),
  (@comp_id, 'fertility_support', '난임 지원 (난임휴직 최대 1년·난임시술비)', NULL, 'family',
   'est', NULL, TRUE, '최대 1년의 난임휴직 보장, 1인당 100만 원의 난임시술비 지급, 남성 근로자의 배우자까지 지원 대상에 포함 (2026-09-11 공식 보도자료 일자리 으뜸기업 항목), 난임 지원 제도 (2025 지속가능경영보고서 47쪽 LIFE CYCLE 복리후생 현황 표 항목) — 시술비 지급 횟수 미기재', 32),
  (@comp_id, 'event', '경조사 지원 (경조금·경조휴가·상조·웨딩카)', NULL, 'family',
   'est', NULL, TRUE, '경조비(휴가) 지원, 상조지원(경조금, 화환), 웨딩카 지원 (2025 지속가능경영보고서 47쪽 LIFE CYCLE 복리후생 현황 표 항목) — 경조 종류별 금액·휴가 일수 미기재', 33),

  -- ── 여가 · 행사 (leisure) — 보고서 11 · 43 · 47쪽 ──
  (@comp_id, 'club', '사내 동호회 지원', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 지원 (2025 지속가능경영보고서 47쪽 LIFE CYCLE 복리후생 현황 표 항목), 사내동호회 운영 (같은 보고서 11쪽 중요 이슈 항목) — 지원 금액·동호회 종류 미기재', 40),
  (@comp_id, 'company_event', '롯데렌탈 한마음 페스티벌', NULL, 'leisure',
   'est', NULL, TRUE, '가족과 함께하는 체육대회 행사 롯데렌탈 한마음 페스티벌 개최 (2025 지속가능경영보고서 43쪽 가족친화기업 인증 항목) — 개최 주기 미기재', 41),
  (@comp_id, 'resort', '휴양소 및 콘도 지원', NULL, 'leisure',
   'est', NULL, TRUE, '휴양소 및 콘도 지원 (2025 지속가능경영보고서 47쪽 LIFE CYCLE 복리후생 현황 표 항목) — 이용 횟수·지원 금액 미기재', 42),
  (@comp_id, 'leisure_ticket', '무료이용권', NULL, 'leisure',
   'est', NULL, TRUE, '무료이용권 (2025 지속가능경영보고서 47쪽 LIFE CYCLE 복리후생 현황 표 항목), 2025년 임직원 무료이용권 지급 (같은 쪽 노사협의회 실시 현황 항목) — 이용권 종류·매수 미기재', 43),

  -- ── 성장 · 교육 (growth) — 보고서 11 · 39 · 41 · 43쪽 ──
  (@comp_id, 'mba', '사외 MBA 지원', NULL, 'growth',
   'est', NULL, TRUE, '사외 MBA 등 인재개발 지원 (2025 지속가능경영보고서 11쪽 중요 이슈 항목), 교육체계의 사외 MBA · 사내위탁대학 · 사이버대학 과정 (같은 보고서 41쪽 임직원 교육체계 항목) — 지원 대상·선발 기준·지원 범위 미기재', 50),
  (@comp_id, 'self_development', '자격증 취득 지원', NULL, 'growth',
   'est', NULL, TRUE, '빅데이터 분석, 자동차 진단, 재경·투자, IT·데이터 등 다양한 영역의 자격증 취득 지원 (2025 지속가능경영보고서 43쪽 성장 지원 프로그램 항목) — 지원 범위·한도 미기재', 51),
  (@comp_id, 'edu_support', '사외 교육 지원', NULL, 'growth',
   'est', NULL, TRUE, '실무 적용 역량을 높이기 위한 사외 교육 지원 (2025 지속가능경영보고서 43쪽 성장 지원 프로그램 항목) — 지원 한도·대상 미기재', 52),
  (@comp_id, 'career', '사내공모 제도', NULL, 'growth',
   'est', NULL, TRUE, '필요한 인재를 확보하기 위한 사내공모 운영 (2025 지속가능경영보고서 39쪽 인재 채용 정책 항목) — 지원 자격·운영 주기 미기재', 53),

  -- ── 생활 · 금융 (perks) — 보고서 40 · 47쪽 · 보도자료 ──
  (@comp_id, 'snack_bar', '사내 카페 Mo:Ca (모카)', NULL, 'perks',
   'est', NULL, TRUE, '선릉 본사 · 서계 · 문래 사옥 사내 카페 Mo:Ca(모카) 운영 (2025 지속가능경영보고서 40쪽 장애인 고용과 복지 지원 항목) — 이용 가격·운영 시간 미기재', 60),
  (@comp_id, 'welfare_point', '복지포인트', NULL, 'perks',
   'est', NULL, TRUE, '복지포인트 (2025 지속가능경영보고서 47쪽 LIFE CYCLE 복리후생 현황 표 항목), 2025년 하반기 복지포인트 배정 협의 (같은 쪽 노사협의회 실시 현황 항목) — 배정 금액 미기재', 61),
  (@comp_id, 'telecom', '통신비 지원', NULL, 'perks',
   'est', NULL, TRUE, '통신비 지원 (2025 지속가능경영보고서 47쪽 LIFE CYCLE 복리후생 현황 표 항목) — 지원 대상·금액 미기재', 62),
  (@comp_id, 'discount', '장기렌터카 할인', NULL, 'perks',
   'est', NULL, TRUE, '장기렌터카 할인 (2025 지속가능경영보고서 47쪽 LIFE CYCLE 복리후생 현황 표 항목) — 할인율·대상 차종 미기재', 63),
  (@comp_id, 'housing_loan', '주택자금 대출', NULL, 'perks',
   'est', NULL, TRUE, '주택자금 대출 (2025 지속가능경영보고서 47쪽 LIFE CYCLE 맞춤형 복지 항목 · 복리후생 현황 표 항목) — 대출 한도·이율 미기재', 64),
  (@comp_id, 'welfare_fund_loan', '생활안정자금 대출', NULL, 'perks',
   'est', NULL, TRUE, '생활안정자금 대출 (2025 지속가능경영보고서 47쪽 LIFE CYCLE 맞춤형 복지 항목 · 복리후생 현황 표 항목) — 대출 한도·이율 미기재', 65),
  (@comp_id, 'pension_support', '개인연금', NULL, 'perks',
   'est', NULL, TRUE, '개인연금 (2025 지속가능경영보고서 47쪽 LIFE CYCLE 맞춤형 복지 항목 · 복리후생 현황 표 항목) — 회사 부담 비율·금액 미기재', 66),
  (@comp_id, 'transport', '임산부 교통비 지원', NULL, 'perks',
   'est', NULL, TRUE, '임신 8개월 차 근로자의 출퇴근을 위해 택시비를 포함한 교통비를 월 최대 50만 원까지 지원 (2026-09-11 공식 보도자료 일자리 으뜸기업 항목), 임산부 교통비 지원 (2025 지속가능경영보고서 47쪽 LIFE CYCLE 복리후생 현황 표 항목) — 지원 기간 미기재', 67),
  (@comp_id, 'team_dinner', '리더데이 (부서 활동비·조기 퇴근)', NULL, 'perks',
   'est', NULL, TRUE, '반기 1회 운영하는 리더데이에 3시간 조기 퇴근과 활동비 지원 (2026-09-11 공식 보도자료 일자리 으뜸기업 항목), 팀 리더가 직접 액티비티를 기획하고 팀원들과 함께 참여하는 사내 프로그램 (2025 지속가능경영보고서 45쪽 리더데이 항목) — 활동비 금액 미기재', 68),

  -- ── 보상 (compensation) — 보고서 46 · 47쪽 ──
  (@comp_id, 'excellence_award', '우수 제안 포상·칭찬 포인트 (해피리워드)', NULL, 'compensation',
   'est', NULL, TRUE, '집단지성 게시판 Help Cloud 우수 제안으로 선정된 아이디어 별도 포상 (2025 지속가능경영보고서 46쪽 Help Cloud 항목), 임직원 간 칭찬 플랫폼 해피리워드 칭찬 1건당 1,000포인트 적립 · 현금처럼 사용 (같은 쪽 해피리워드 항목) — 포상 금액 미기재', 70),
  (@comp_id, 'stock_option', '우리사주제도 (이자 지원)', NULL, 'compensation',
   'est', NULL, TRUE, '전 임직원을 대상으로 우리사주제도 운영, 금리 인상에 따른 우리사주 조합원 상승 이자분에 대한 금전적 지원 연장 (2025 지속가능경영보고서 47쪽 우리사주 이자 지원 항목) — 지원 금액·기간 미기재', 71),

  -- ── 건강 (health) — 보고서 47쪽 ──
  (@comp_id, 'health_check', '건강검진 (배우자 지원)', NULL, 'health',
   'est', NULL, TRUE, '건강검진(배우자 지원) (2025 지속가능경영보고서 47쪽 LIFE CYCLE 복리후생 현황 표 항목), 2025년 임직원 건강검진 시행 협의 (같은 쪽 노사협의회 실시 현황 항목) — 검진 주기·비용 지원 범위 미기재', 80),
  (@comp_id, 'insurance', '임직원 단체상해보험', NULL, 'health',
   'est', NULL, TRUE, '임직원 단체상해보험 (2025 지속가능경영보고서 47쪽 LIFE CYCLE 복리후생 현황 표 항목) — 보장 범위 미기재', 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
