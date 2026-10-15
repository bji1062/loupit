-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 현대위아 복리후생 데이터 (신규 회사 — 웨이브 6)
-- 출처: AI 파싱 (2026-10-14)
-- URL: https://www.hyundai-wia.com/upload/download/Hyundai_WIA_SR_2026_Ko.pdf
-- badge: est
--
-- 참고:
--   정본은 상장 법인 현대위아가 자기 도메인 www.hyundai-wia.com 에 직접 올린 2026 지속가능성보고서 PDF
--   (지속가능성 보고서 목록 페이지 /sustainability/sustainabilityreport.asp 에서 링크 · 2026-06-29 게시 ·
--   보고 기간 2025-01-01~2025-12-31 · 126쪽 · 이 회사가 올린 가장 새 판).
--   보조 공시: OpenDART 2026 반기보고서(접수 20260814002618) 직원 등 현황 유연근무제도 사용현황 표 1구절.
--   본문 행은 54쪽 복리후생 제도 표(업무 환경 · 휴가·장기근속 · 건강·안전 · 생활지원 및 편의제공 ·
--   출산·육아 · 문화·여가 · 교육비·경조사 7칸). 보조 쪽: 49쪽 사내공모 · 51쪽 학습 플랫폼·러닝셀·어학 ·
--   52쪽 성과급·포상제도 · 53쪽 WIA Awards · 55쪽 동호회 · 121쪽 심리 상담·가족 의료비.
--   렌더 방식: PDF 텍스트 레이어(pypdf) · 헤드리스 렌더 0회 · 이미지 판독 0건.
--   귀속: 주어가 「현대위아는」이고 계열사 단서가 없다. 그룹 통합 채용 페이지가 아니라 자기 발행
--   보고서라 각주 없음. 현대차그룹 형제 8사 시드와 같은 문장 0건.
--   채용 사이트 hyundai-wia.recruiter.co.kr 의 복지 본문은 robots 금지 호스트에서만 채워져 읽지 않았다.
--   금액: stated 1행(선물비 연 50만원) · 추정 0행. 나머지는 금액 없음 또는 대상이 불명확해 NULL.
--   제외: 법정(4대보험 · 안전보호구 · 임신기 근로시간 단축 · 태아검진 시간 · 출산휴가 90일 ·
--   배우자 출산휴가 20일 · 육아기 근로시간 단축 · 난임치료휴가 6일 중 2일 유급 · 가족돌봄 휴가와 휴직) ·
--   출장비(업무 경비) · 업무 교육(직무 맞춤 · AI/DT · 신입 트랙 · 얼리버드 세미나) · 안전 포상 ·
--   그룹 공통 공모전 · 임원 보수 · 협력사 대상 지원 · 칭찬 플랫폼 W+ · 숙련 재고용.
--   공고 근거 0행 / 전체 33행. 신규 코드 0개.
--   SORT 섹션 순서 = 54쪽 표에서 카테고리가 처음 나온 순서
--   (flexibility 10 · work_env 20 · time_off 30 · growth 40 · health 50 · perks 60 ·
--    compensation 70 · family 80 · leisure 90).
-- 검증 · 감사 판정 반영(2026-10-14): 주간 연속 2교대 포인트를 self_development 에서 welfare_point 로 재코딩(perks SORT 64 · 금액 NULL) · 자격증 취득 지원 self_development 추가 · 반기보고서 원격근무제(재택근무 포함) remote_work 추가 — 최종 35행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hyundai_wia', '현대위아',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '자동차부품', 'H', 'https://www.hyundai-wia.com/upload/download/Hyundai_WIA_SR_2026_Ko.pdf');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_wia');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.hyundai-wia.com/upload/download/Hyundai_WIA_SR_2026_Ko.pdf'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 유연근무 (flexibility) — 2026 지속가능성보고서 54쪽 ──
  (@comp_id, 'flex_work', '선택적 근로시간제', NULL, 'flexibility',
   'est', NULL, TRUE, '선택적 근로시간제: 출퇴근 시간 선택하여 자기주도적 근로 계획 (2026 지속가능성보고서 54쪽 복리후생 제도 업무 환경 항목), 선택근무제 사용자 수 1,946명 (2026 반기보고서 직원 등 현황 유연근무제도 사용현황 표, 2026년 6월 30일 기준) — 의무 근로시간대·정산 기간·적용 대상 미기재', 10),
  (@comp_id, 'remote_work', '원격근무제(재택근무 포함)', NULL, 'flexibility',
   'est', NULL, TRUE, '원격근무제(재택근무 포함) 활용, 사용자 2026년 상반기 57명 · 2025년 70명 (2026 반기보고서 직원 등 현황 유연근무제도 사용현황 항목) — 대상 직무·사용 조건 미기재', 11),

  -- ── 근무환경 (work_env) — 2026 지속가능성보고서 54쪽 ──
  (@comp_id, 'free_seating', '자율좌석제 (일부 사업장)', NULL, 'work_env',
   'est', NULL, TRUE, '자율좌석제: 일부 사업장 자율좌석제 운영 (2026 지속가능성보고서 54쪽 복리후생 제도 업무 환경 항목) — 운영 사업장 미기재', 20),
  (@comp_id, 'uniform', '작업복 지급·외주세탁', NULL, 'work_env',
   'est', NULL, TRUE, '작업복 지급 및 외주세탁 지원 (2026 지속가능성보고서 54쪽 복리후생 제도 건강·안전 지원 항목) — 지급 대상·지급 주기 미기재', 21),
  (@comp_id, 'dormitory', '기숙사', NULL, 'work_env',
   'est', NULL, TRUE, '기숙사 지원: 멀티플렉스형 기숙사 운영 (2026 지속가능성보고서 54쪽 복리후생 제도 생활지원 및 편의제공 항목) — 입주 대상·운영 사업장·본인 부담 미기재', 22),

  -- ── 휴가 (time_off) — 2026 지속가능성보고서 54쪽 ──
  (@comp_id, 'summer_leave', '하계 휴가 5일', NULL, 'time_off',
   'est', NULL, TRUE, '하계 휴가: 연·월차 외 5일의 하계 휴가 제공 (2026 지속가능성보고서 54쪽 복리후생 제도 휴가·장기근속 지원 항목) — 사용 시기 미기재', 30),
  (@comp_id, 'leave_general', '리스타트 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '리스타트 휴가 (2026 지속가능성보고서 54쪽 복리후생 제도 휴가·장기근속 지원 항목) — 휴가 일수·부여 대상·부여 조건·유급 여부 미기재', 31),
  (@comp_id, 'long_service_leave', '장기근속포상', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속포상: 근속 10년~35년까지 5년 단위 휴가, 격려금, 기념품 지급 (2026 지속가능성보고서 54쪽 복리후생 제도 휴가·장기근속 지원 항목) — 근속 연수별 휴가 일수·격려금 금액·기념품 내용 미기재', 32),

  -- ── 성장·교육 (growth) — 2026 지속가능성보고서 54쪽 · 49쪽 · 51쪽 ──
  (@comp_id, 'retirement_support', '정년퇴직자 해외여행 지원', NULL, 'growth',
   'est', NULL, TRUE, '정년퇴직 지원: 정년퇴직자 대상 해외여행 지원 (2026 지속가능성보고서 54쪽 복리후생 제도 휴가·장기근속 지원 항목) — 여행 지역·지원 금액·동반 가족 지원 여부 미기재', 40),
  (@comp_id, 'self_development', '자격증 취득 지원', NULL, 'growth',
   'est', NULL, TRUE, '자격증 취득 지원 (2026 지속가능성보고서 51쪽 자기주도적 직무 역량 강화 항목) — 지원 대상 자격증·지원 비용·지원 방식 미기재', 41),
  (@comp_id, 'career', '사내공모 전환배치', NULL, 'growth',
   'est', NULL, TRUE, '사내공모 기반 전환배치 제도 운영, 신규 업무 포지션, 신설팀 인력 보강 등 외부 충원이 어려운 직무를 대상으로 사내 공모를 진행 (2026 지속가능성보고서 49쪽 사내공모 및 전환배치 항목) — 지원 자격·공모 주기 미기재', 42),
  (@comp_id, 'edu_support', '스마트 러닝 플랫폼·러닝셀', NULL, 'growth',
   'est', NULL, TRUE, '임직원의 자기주도 학습을 지원하기 위해 사내 학습 동아리인 러닝셀 제도 운영 (2026 지속가능성보고서 51쪽 자기주도적 직무 역량 강화 항목), 스마트 러닝 플랫폼에서 다양한 직무, 소양 분야 온라인 상시학습 콘텐츠 운영 3,626개 과정 (같은 쪽 온라인 학습 플랫폼 표) — 러닝셀 지원 내용·수강 비용 부담 미기재', 43),
  (@comp_id, 'lang', '사내 어학과정', NULL, 'growth',
   'est', NULL, TRUE, '임직원의 글로벌 업무 대응 역량 강화를 위해 수준별 외국어 교육과 자기주도 학습 프로그램 운영, 상시 학습 자료와 정기 어학 캠페인 제공, 실무 중심의 집중 과정 (2026 지속가능성보고서 51쪽 글로벌 역량 강화 항목) — 수강 대상·수강 비용 부담·교육 언어 미기재', 44),

  -- ── 건강·의료 (health) — 2026 지속가능성보고서 54쪽 · 121쪽 ──
  (@comp_id, 'health_check', '정기검진·종합검진 지원', NULL, 'health',
   'est', NULL, TRUE, '임직원 정기검진, 종합검진 지원 (2026 지속가능성보고서 54쪽 복리후생 제도 건강·안전 지원 항목) — 검진 주기·비용 지원 범위·가족 대상 여부 미기재', 50),
  (@comp_id, 'medical', '가족 의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '의료비 지원: 건강보험증 등재 가족 의료비 지원 (2026 지속가능성보고서 54쪽 복리후생 제도 건강·안전 지원 항목), 임직원 및 그 가족의 의료비 지원 (같은 보고서 121쪽 UN SDGs 임직원 건강 및 웰빙 증진 항목) — 지원 한도·지원 비율 미기재', 51),
  (@comp_id, 'clinic', '사내 의원 H+·건강관리실', NULL, 'health',
   'est', NULL, TRUE, '사내 의원 운영: 사내 의원 H+ 및 사업장별 건강관리실 운영 (2026 지속가능성보고서 54쪽 복리후생 제도 건강·안전 지원 항목) — 진료 과목·운영 시간 미기재', 52),
  (@comp_id, 'fitness', '헬스장', NULL, 'health',
   'est', NULL, TRUE, '헬스장 운영: 사업장별 최신 기구 구비 운영 (2026 지속가능성보고서 54쪽 복리후생 제도 건강·안전 지원 항목) — 이용 시간·이용 비용 미기재', 53),
  (@comp_id, 'insurance', '단체상해보험', NULL, 'health',
   'est', NULL, TRUE, '보험 지원: 파견직 포함 전 임직원 대상 단체상해보험 지원 (2026 지속가능성보고서 54쪽 복리후생 제도 건강·안전 지원 항목) — 보장 내용·가족 가입 여부 미기재', 54),
  (@comp_id, 'mental', '심리 상담', NULL, 'health',
   'est', NULL, TRUE, '사내 의원을 설립, 운영하고 있으며 정기검진과 심리 상담 또한 지원 (2026 지속가능성보고서 121쪽 UN SDGs 임직원 건강 및 웰빙 증진 항목) — 상담 방식·이용 횟수·가족 이용 여부 미기재', 55),

  -- ── 경제적 부가혜택 (perks) — 2026 지속가능성보고서 54쪽 ──
  (@comp_id, 'meal', '식사·간식 지원', NULL, 'perks',
   'est', NULL, TRUE, '식사 및 간식 지원: 영양가 높은 다양한 메뉴 제공 (2026 지속가능성보고서 54쪽 복리후생 제도 건강·안전 지원 항목) — 제공 끼니·본인 부담 미기재', 60),
  (@comp_id, 'commute_subsidy', '통근버스', NULL, 'perks',
   'est', NULL, TRUE, '통근 지원: 통근버스 운영 (2026 지속가능성보고서 54쪽 복리후생 제도 생활지원 및 편의제공 항목) — 운행 노선·운행 사업장 미기재', 61),
  (@comp_id, 'housing_support', '주택 구입·전세 보조금', NULL, 'perks',
   'est', NULL, TRUE, '주택 구입 및 전세 보조금 지원 (2026 지속가능성보고서 54쪽 복리후생 제도 생활지원 및 편의제공 항목) — 지원 금액·지원 대상·지원 방식 미기재', 62),
  (@comp_id, 'discount', '그룹사 차량 구입비 지원', NULL, 'perks',
   'est', NULL, TRUE, '그룹사 차량 구입시 구입비 지원 (2026 지속가능성보고서 54쪽 복리후생 제도 생활지원 및 편의제공 항목) — 지원 금액·할인율·구입 주기 미기재', 63),
  (@comp_id, 'welfare_point', '주간 연속 2교대 포인트', NULL, 'perks',
   'est', NULL, TRUE, '주간 연속 2교대 포인트: 자기개발을 위한 40만원/반기 포인트 지급 (2026 지속가능성보고서 54쪽 복리후생 제도 문화·여가 지원 항목) — 지급 대상 범위·포인트 사용처 미기재', 64),

  -- ── 보상·금전 (compensation) — 2026 지속가능성보고서 54쪽 · 52쪽 · 53쪽 ──
  (@comp_id, 'holiday_gift', '선물비', 50, 'compensation',
   'est', '선물비: 복지 후생 향상을 위해 50만원/년 지급 (2026 지속가능성보고서 54쪽 복리후생 제도 생활지원 및 편의제공 항목) — 지급 시기·지급 방식 미기재', FALSE, NULL, 70),
  (@comp_id, 'incentive', '성과급 (일반직 평가 기반)', NULL, 'compensation',
   'est', NULL, TRUE, '일반직의 경우 평가 결과를 기반으로 성과급을 산정·지급 (2026 지속가능성보고서 52쪽 성과평가 체계 항목) — 지급 기준·지급률 미기재', 71),
  (@comp_id, 'profit_sharing', '경영 성과 성과급', NULL, 'compensation',
   'est', NULL, TRUE, '성과 평가 기반 급여 외에도 매년 경영 성과에 따른 이익을 성과급으로 제공 (2026 지속가능성보고서 52쪽 보상 체계 항목) — 지급 대상·지급률 미기재', 72),
  (@comp_id, 'excellence_award', '포상제도', NULL, 'compensation',
   'est', NULL, TRUE, '우수사원, 품질·원가 혁신, 개선 제안, 우수과제 등 다양한 분야의 성과에 대한 포상 제도, R&D Innovation Challenge Award·모범사원상·위아다움 포상·제안제도 우수 포상 등 (2026 지속가능성보고서 52쪽 포상제도 운영 항목), WIA Awards 대표이사 훈격 포상 연말 통합 시상식 (같은 보고서 53쪽 2025 조직문화 프로그램 표) — 포상 금액·선정 기준 미기재', 73),

  -- ── 가족·돌봄 (family) — 2026 지속가능성보고서 54쪽 ──
  (@comp_id, 'parenting', '육아휴직 최대 2년·도담이 키즈 바우처', NULL, 'family',
   'est', NULL, TRUE, '만 8세 이하, 초등학교 2학년 이하의 자녀 양육을 요하는 근로자에게 한 자녀당 최대 2년 육아휴직 제공 (법정 1년에 최대 1년 추가), 도담이 키즈 바우처: 자녀 출생 시 「첫 만남 바우처」, 초등학교 입학 시 「첫 등교 바우처」 발행 (2026 지속가능성보고서 54쪽 복리후생 제도 출산·육아 지원 항목) — 휴직 중 급여·바우처 금액·사용처 미기재', 80),
  (@comp_id, 'childcare', '직장 어린이집', NULL, 'family',
   'est', NULL, TRUE, '직장 어린이집 운영: 만 0세~5세 반 운영 (2026 지속가능성보고서 54쪽 복리후생 제도 출산·육아 지원 항목) — 운영 사업장·정원·보육료 부담 미기재', 81),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금 지원: 임직원의 중·고등·대학교 재학 자녀 학자금 지원 (2026 지속가능성보고서 54쪽 복리후생 제도 교육비·경조사 지원 항목) — 지원 한도·자녀 수 제한 미기재', 82),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사 지원: 본인 및 자녀 결혼 지원, 가족 사망 시 조사 지원 (2026 지속가능성보고서 54쪽 복리후생 제도 교육비·경조사 지원 항목) — 경조금 금액·경조휴가 일수 미기재', 83),

  -- ── 여가·라이프 (leisure) — 2026 지속가능성보고서 54쪽 · 55쪽 ──
  (@comp_id, 'company_event', '문화 행사', NULL, 'leisure',
   'est', NULL, TRUE, '문화 행사: 음악회, 체육, 영화관람 행사 등 (2026 지속가능성보고서 54쪽 복리후생 제도 문화·여가 지원 항목) — 행사 횟수·가족 참여 여부 미기재', 90),
  (@comp_id, 'club', '동호회 활동비 지원', NULL, 'leisure',
   'est', NULL, TRUE, '동호회 지원: 취미·스포츠 동호회 월별 활동비 지원 (2026 지속가능성보고서 54쪽 복리후생 제도 문화·여가 지원 항목), 사내 동호회 지원 및 적극 참여를 통한 활동 장려 (같은 보고서 55쪽 2025 주요 임직원 커뮤니케이션 활동 표) — 활동비 금액 미기재', 91),
  (@comp_id, 'resort', '휴양시설 회원가 이용', NULL, 'leisure',
   'est', NULL, TRUE, '휴양시설 이용 지원: 콘도, 리조트 등 회원가 제공 (2026 지속가능성보고서 54쪽 복리후생 제도 문화·여가 지원 항목) — 제휴 시설 목록·이용 한도 미기재', 92)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
