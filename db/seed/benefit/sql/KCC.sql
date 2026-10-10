-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- KCC 복리후생 데이터 (신규 회사 — 웨이브 5)
-- 출처: AI 파싱 (2026-10-10)
-- URL: https://www.kccworld.co.kr/jobs/hr-system.do
-- badge: est
--
-- 참고:
--   정본은 상장 법인 (주)케이씨씨(표시명 KCC)의 자기 도메인 www.kccworld.co.kr GNB 채용 > 인사 및 복지
--   페이지다. 복지제도 블록(div.welfareSystem)에 4탭 20항목이 서버렌더 HTML 텍스트로 있다.
--   탭은 aria-hidden 으로만 접혀 있어 원본 HTML 의 h3 제목 + p 설명 20쌍을 읽었다(헤드리스 렌더 없음).
--   같은 페이지 인사제도 보상체계(성과급 1행)와 인재육성(학술연수/MBA 1행)도 근거로 썼다.
--   보조 출처는 같은 도메인의 2026 KCC 지속가능성보고서 국문 PDF(보고 기간 2025-01-01~12-31,
--   보고 범위 KCC 국내 사업장) 6 · 45 · 59 · 61 · 62쪽이다(인쇄 쪽 = PDF 쪽).
--   원문은 웨이브 5 프로브가 2026-10-10 UTC 에 받은 사본을 다시 받지 않고 썼다.
--   귀속: 페이지와 보고서 모두 주어가 KCC 단수다. 그룹 각주 없음. 형제 KCC글라스 · KCC건설 ·
--   Momentive 페이지 문장은 쓰지 않았다(KCC글라스 12항목과 문장 일부가 비슷하나 KCC 자기 도메인 원문만 인용).
--   금액: 페이지 · 보고서 모두 원 · 만원 금액 0건이라 30행 전부 BENEFIT_AMT NULL(정성)이다.
--   제외: 퇴직연금제도 운영 · 4대 법정보험 · 출산휴가 60일 100% · 임신기 근로시간 단축 · 육아휴직 ·
--   가족돌봄휴직과 휴가 · 재취업 사전준비 지원(고령자고용법 · 직원 3,583명) · 연차 사용 촉진 ·
--   징검다리 연휴 지정 연차(본인 휴가) · 특수건강진단 · 업무 교육(승진자 · 직책자 · 핵심인재 단기 MBA ·
--   AI 리터러시 · 국내외 업무연수) · 팀장수당 · 연봉 체계 · 유류비(대상 불명) · 이사 보수 표.
--   공고 근거 0행 / 전체 30행.
--   SORT 섹션 순서(정본 페이지에서 처음 나온 순서, 보고서 전용 카테고리는 끝):
--   compensation 10 · growth 20 · work_env 30 · perks 40 · family 50 · leisure 60 · health 70 ·
--   flexibility 80 · time_off 90.
-- 검증 · 감사 판정 반영(2026-10-10): 선택근로 서술의 법정 낱말 제거 · 비연고지 교통비 행에 보고서 6쪽 유류비 구절 보탬 · 금연 프로그램은 싣지 않음 — 최종 30행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('kcc', 'KCC',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '화학', 'K', 'https://www.kccworld.co.kr/jobs/hr-system.do');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'kcc');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.kccworld.co.kr/jobs/hr-system.do'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) — 정본 페이지 인사제도 보상체계 · 보고서 61쪽 ──
  (@comp_id, 'incentive', '성과급', NULL, 'compensation',
   'est', NULL, TRUE, '「Pay by Performance」 원칙 아래 연간 업무성과에 따른 성과급을 지급해 임직원이 창출한 성과를 보상 (공식 채용 페이지 인사제도 보상체계 항목), 영업이익 및 목표달성률 기반 성과 보상 (2026 지속가능성보고서 61쪽 객관적이고 합리적인 보상 항목) — 지급률·지급 시기 미기재', 10),
  (@comp_id, 'holiday_gift', '명절비 지원', NULL, 'compensation',
   'est', NULL, TRUE, '명절비 지원 (2026 지속가능성보고서 61쪽 다양한 복리후생 항목) — 지급 금액·지급 명절·지급 방식 미기재', 11),

  -- ── 성장·교육 (growth) — 정본 페이지 복지제도 생활/문화 · 인재육성 · 보고서 59쪽 ──
  (@comp_id, 'lang', '사내 외국어 강좌', NULL, 'growth',
   'est', NULL, TRUE, '자기계발을 위한 사내 외국어 강좌(영어, 중국어, 일본어 등) 운영 (공식 채용 페이지 복지제도 생활/문화 자기계발 지원 항목), AI 기반 어학교육 시스템으로 개인별 수준에 맞는 맞춤형 학습 지원 (2026 지속가능성보고서 59쪽 지속적인 교육 시스템 혁신 항목) — 수강 대상·수강료 부담 미기재', 20),
  (@comp_id, 'edu_support', '사이버 강좌·초청 특강·E-book 플랫폼', NULL, 'growth',
   'est', NULL, TRUE, '자기계발을 위한 사이버 강좌(외국어, 자격증, E-MBA) 운영 (공식 채용 페이지 복지제도 생활/문화 자기계발 지원 항목), 저명인사 및 작가 초청 특강과 E-book 플랫폼을 활용한 자기주도 학습 제공 (2026 지속가능성보고서 59쪽 지속적인 교육 시스템 혁신 항목) — 수강 가능 과정·비용 부담 미기재', 21),
  (@comp_id, 'books', '신문 구독료 지원', NULL, 'growth',
   'est', NULL, TRUE, '최신 뉴스 및 정보 획득에 도움이 되도록 신문 구독료 지원 (공식 채용 페이지 복지제도 생활/문화 항목) — 지원 금액·구독 매체 수 미기재', 22),
  (@comp_id, 'mba', '국내외 학술연수·MBA', NULL, 'growth',
   'est', NULL, TRUE, '국내외 학술연수/MBA (공식 채용 페이지 인재육성 핵심리더 양성 항목), 선별된 우수 인재의 국내외 대학 MBA를 포함한 다양한 학위 과정 및 해외연수 과정 이수 지원 (2026 지속가능성보고서 59쪽 인재경영 항목) — 선발 기준·인원·학비 지원 범위 미기재', 23),

  -- ── 근무환경 (work_env) — 정본 페이지 복지제도 생활/문화 ──
  (@comp_id, 'dormitory', '사택/기숙사 지원', NULL, 'work_env',
   'est', NULL, TRUE, '거주지로부터 멀리 떨어져 근무하는 직원에게 사택/기숙사 지원 (공식 채용 페이지 복지제도 생활/문화 항목, 2026 지속가능성보고서 61쪽 다양한 복리후생 항목) — 입주 자격·본인 부담·운영 사업장 미기재', 30),

  -- ── 경제적 부가혜택 (perks) — 정본 페이지 복지제도 생활/문화 · 금융지원 · 건강/제휴 · 보고서 61쪽 ──
  (@comp_id, 'commute_subsidy', '통근버스 운영', NULL, 'perks',
   'est', NULL, TRUE, '직원들의 편리하고 효율적인 출퇴근을 위한 통근버스 운영 (공식 채용 페이지 복지제도 생활/문화 항목) — 운행 사업장·노선·이용료 미기재', 40),
  (@comp_id, 'transport', '비연고지 교통비 지원', NULL, 'perks',
   'est', NULL, TRUE, '비연고지에서 근무하는 직원에게 연고지 이동을 위한 교통비 지원 (공식 채용 페이지 복지제도 생활/문화 항목), 필요시 장거리 근무자의 주말 귀향비 지원 (2026 지속가능성보고서 61쪽 다양한 복리후생 항목), 유류비 지원 (같은 보고서 6쪽 이해관계자 참여 항목) — 지원 금액·지원 횟수·유류비 지원 대상 미기재', 41),
  (@comp_id, 'housing_loan', '주택자금 대부 (무주택 사원)', NULL, 'perks',
   'est', NULL, TRUE, '직원의 생활 안정을 위해 무주택 사원에게 장기 저리로 주택자금 대부 (공식 채용 페이지 복지제도 금융지원 항목, 2026 지속가능성보고서 61쪽 다양한 복리후생 항목) — 대부 한도·이율·상환 기간 미기재', 42),
  (@comp_id, 'welfare_fund_loan', '생활 안정자금 대부', NULL, 'perks',
   'est', NULL, TRUE, '생계적으로 문제가 있는 직원에게 채무 상환에 필요한 일부를 대부 (공식 채용 페이지 복지제도 금융지원 항목), 필요시 생활안정자금 지원 (2026 지속가능성보고서 61쪽 다양한 복리후생 항목) — 대부 한도·이율·심사 기준 미기재', 43),
  (@comp_id, 'discount', '현대/기아자동차 할인', NULL, 'perks',
   'est', NULL, TRUE, '현대/기아자동차 신차 구매 시 관계사 임직원 할인 (공식 채용 페이지 복지제도 건강/제휴 항목) — 할인율·구매 횟수 제한 미기재', 44),
  (@comp_id, 'welfare_point', '복지포인트', NULL, 'perks',
   'est', NULL, TRUE, '제휴 복지몰에서 자유롭게 사용할 수 있는 복지포인트 지급 (공식 채용 페이지 복지제도 건강/제휴 항목) — 연간 포인트 금액·지급 시기 미기재', 45),
  (@comp_id, 'telecom', '개인휴대전화비 지원 (책임급 이상·영업 외근직 등)', NULL, 'perks',
   'est', NULL, TRUE, '책임급 이상, 영업(외근)직, 그 외 필요하다고 인정된 직원(품의)에게 개인휴대전화비 지원 (2026 지속가능성보고서 61쪽 다양한 복리후생 항목) — 지원 금액·지원 방식 미기재', 46),

  -- ── 가족·돌봄 (family) — 정본 페이지 복지제도 생활/문화 · 금융지원 · 보고서 61~62쪽 ──
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사 발생 시 경조휴가 부여와 경조금, 경조화환, 장례물품 지원 (공식 채용 페이지 복지제도 생활/문화 항목, 2026 지속가능성보고서 61쪽 다양한 복리후생 항목) — 경조 구분별 금액·휴가 일수 미기재', 50),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀 교육에 따른 경제적 부담을 덜기 위해 고등학생 이상 자녀의 학자금 지원 (공식 채용 페이지 복지제도 금융지원 항목, 2026 지속가능성보고서 61쪽 다양한 복리후생 항목) — 지원 한도·자녀 수 제한 미기재', 51),
  (@comp_id, 'childcare', '직장어린이집 (서울 본사·울산공장)', NULL, 'family',
   'est', NULL, TRUE, '서울 본사와 울산공장에 직장어린이집 설치·운영, 어린이집 운영비용 전액 KCC 지원, 영유아 급간식은 정부기준 2배 이상의 예산 편성, 주 3회 원어민 영어수업과 생태 감각활동·체육활동·코딩 로봇활동 등 프로그램 전액 무료 제공 (2026 지속가능성보고서 62쪽 전문적이고 다채로운 직장어린이집 운영 항목) — 정원·입소 대상 연령 미기재', 52),

  -- ── 여가·라이프 (leisure) — 정본 페이지 복지제도 여가 · 보고서 61쪽 ──
  (@comp_id, 'resort', '무료 캠핑장·콘도미니엄 지원', NULL, 'leisure',
   'est', NULL, TRUE, '남한강변과 천연 잔디구장에 위치한 무료 캠핑장 운영 (공식 채용 페이지 복지제도 여가 항목), 콘도미니엄 지원 (같은 페이지 여가 Refresh Support 항목), 호텔·콘도·캠핑장 등 숙박/레저시설 지원 (2026 지속가능성보고서 61쪽 다양한 복리후생 항목) — 이용 일수·본인 부담·제휴 콘도 미기재', 60),
  (@comp_id, 'summer_vacation_subsidy', '휴가비 지원 (Refresh Support)', NULL, 'leisure',
   'est', NULL, TRUE, '휴가비를 지원해 몸과 마음의 재충전 지원 (공식 채용 페이지 복지제도 여가 Refresh Support 항목, 2026 지속가능성보고서 61쪽 리프레시 지원 항목) — 지급 금액·지급 시기 미기재', 61),
  (@comp_id, 'club', '동호회 지원', NULL, 'leisure',
   'est', NULL, TRUE, '다양한 동호회 활동을 통한 여가 선용 및 친목 도모 지원 (공식 채용 페이지 복지제도 여가 항목, 2026 지속가능성보고서 61쪽 다양한 복리후생 항목) — 동호회 수·지원 금액 미기재', 62),
  (@comp_id, 'sports_ticket', '부산 KCC 이지스 프로농구 티켓', NULL, 'leisure',
   'est', NULL, TRUE, '프로농구 팀 「부산 KCC 이지스」의 경기 티켓 지원 (공식 채용 페이지 복지제도 여가 항목) — 지원 매수·좌석 등급 미기재', 63),
  (@comp_id, 'leisure_ticket', '인천국제공항 마티나 라운지 무료 이용', NULL, 'leisure',
   'est', NULL, TRUE, '출장이나 휴가 중 인천국제공항 내 마티나 라운지 무료 이용 (공식 채용 페이지 복지제도 여가 항목) — 연간 이용 횟수·동반자 이용 여부 미기재', 64),

  -- ── 건강·의료 (health) — 정본 페이지 복지제도 건강/제휴 · 보고서 6 · 45 · 61쪽 ──
  (@comp_id, 'medical', '의료비 지원 (본인·배우자·자녀)', NULL, 'health',
   'est', NULL, TRUE, '본인, 배우자 및 자녀의 의료비 지원 (공식 채용 페이지 복지제도 건강/제휴 항목, 2026 지속가능성보고서 61쪽 다양한 복리후생 항목), 질병위로금 지급 (같은 보고서 6쪽 이해관계자 참여 항목) — 지원 한도·본인 부담률·위로금 금액 미기재', 70),
  (@comp_id, 'fitness', '피트니스센터 운영', NULL, 'health',
   'est', NULL, TRUE, '건강증진을 위해 헬스장, 수영장, 축구장 등 운영 (공식 채용 페이지 복지제도 건강/제휴 항목, 2026 지속가능성보고서 61쪽 휘트니스센터 운영 항목) — 운영 사업장·이용료 미기재', 71),
  (@comp_id, 'health_check', '건강검진 (매년)', NULL, 'health',
   'est', NULL, TRUE, '직원들이 건강한 삶을 영위할 수 있도록 매년 직원 건강검진 실시 (공식 채용 페이지 복지제도 건강/제휴 항목, 2026 지속가능성보고서 61쪽 다양한 복리후생 항목) — 검진 항목·비용 지원 범위·가족 검진 여부 미기재', 72),
  (@comp_id, 'clinic', '의무실·건강상담소', NULL, 'health',
   'est', NULL, TRUE, '의무실 설치와 건강상담소 운영, 의료인 보건관리자가 상주하는 사업장은 의무실에서 응급조치 및 의약품 처치 (2026 지속가능성보고서 45쪽 임직원의 건강·심리 관리 항목) — 운영 사업장 수·이용 시간 미기재', 73),
  (@comp_id, 'mental', '심리상담 지원 (EAP)', NULL, 'health',
   'est', NULL, TRUE, '개인 문제와 직무 스트레스 등에 대해 심리상담을 받을 수 있는 EAP(Employee Assistance Program) 2011년부터 시행 (2026 지속가능성보고서 45쪽 임직원의 건강·심리 관리 항목), 심리상담센터 운영 (같은 보고서 6쪽 이해관계자 참여 항목) — 상담 횟수·비용 부담·가족 이용 여부 미기재', 74),

  -- ── 유연근무 (flexibility) — 보고서 61쪽 근로시간 제도 개선 ──
  (@comp_id, 'flex_work', '선택적 근로시간제', NULL, 'flexibility',
   'est', NULL, TRUE, '근로시간 총량을 정해 근무 시작과 종료를 직원의 자율에 맡기는 선택적 근로시간제, 프로젝트성 업무 등 근무시간 초과가 예상되는 부서 및 직원 대상 탄력적 근로시간제, 출퇴근시간 조정 시스템 운영 (2026 지속가능성보고서 61쪽 근로시간 제도 개선 항목) — 적용 대상 직군·의무 근무시간대 미기재', 80),
  (@comp_id, 'pc_off', 'PC-off제', NULL, 'flexibility',
   'est', NULL, TRUE, '정시 퇴근 실현과 초과 근무 방지를 위한 PC-off제 및 근무시간 관리 시스템 운영 (2026 지속가능성보고서 61쪽 근로시간 제도 개선 항목) — PC 차단 시각·예외 승인 절차 미기재', 81),

  -- ── 휴가 (time_off) — 보고서 61쪽 근로시간 제도 개선 ──
  (@comp_id, 'leave_general', '2시간 단위 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '2시간 단위 휴가 도입으로 직원들의 개인 용무 등 단시간 활동 편의 제공 (2026 지속가능성보고서 61쪽 근로시간 제도 개선 항목) — 사용 한도·신청 절차 미기재', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
