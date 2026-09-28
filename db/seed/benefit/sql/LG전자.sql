-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- LG전자 복리후생 데이터
-- 출처: AI 파싱 (2026-09-27)
-- URL: https://www.lge.co.kr/company/recruit/hr
-- badge: est
--
-- 참고:
--   정본은 자기 도메인 www.lge.co.kr 의 회사소개 > 인재채용 > 인사제도 페이지(/company/recruit/hr) 안
--   임금체계 블록(인센티브 · 성과급)과 복리후생 블록이다. 복리후생은 아코디언 4개
--   (회사생활 5 · 가족 9 · 건강 5 · 여가활동 3 = 22항목)이고 각 항목은 「내용 더 보기」 버튼이 여는
--   ui_accordion 패널 안에 있다 — HTML 주석이나 template 속 블록이 아니다. SSR HTML 이라 헤드리스 렌더 불필요.
--   robots 는 User-agent: * 묶음에서 이 경로를 막지 않는다(Claude 계열 봇 묶음도 같은 규칙으로 허용).
--   끊긴 옛 URL /company/recruit 는 404 그대로다(리다이렉트 없음). 인재채용 메뉴는 이제
--   /company/recruit/talent(인재상) · /hr(인사제도) · /foster(인재육성) 세 탭으로 나뉘어 있고 복지는 /hr 에 있다.
--   보조 출처(같은 회사 공식 문서): /company/recruit/foster 인재육성 · /sustainability/diversity-inclusion 다양성과 포용 ·
--   /sustainability/decent-workplace 존중받는 일터 · 2025-2026 LG전자 지속가능경영보고서(www.lg.com PDF 148쪽).
--   그룹 통합 채용 careers.lg.com 은 요청하지 않았다 — 자기 도메인에 정본이 있고, SPA 셸이며,
--   2026-09-01 웨이브 관측 robots 가 AI 봇을 막았다.
--
--   금액: 명시값 1행(welfare_point 연 100만원). 승계 추정치 4행(health_check 100 · medical 100 · resort 100 ·
--     commute_subsidy 120 — NOTE 끝에 (추정)). 구본 추정치 가운데 event 100(1회성 경조금) · insurance 50 ·
--     club 30 · sports_ticket 30(같은 값을 추정치로 쓴 다른 회사가 3곳 미만이고 값의 전제가 원문에 없음)은 NULL.
--   재코딩 2: bonus → incentive(원문 인센티브) · leave_general → summer_leave(원문 휴가 제도 = 하계휴가 4일).
--   원문 성과급(회사 경영성과 연동)은 profit_sharing, 휴가 제도의 회사 · 노조 창립 기념일은 foundation_day_leave 로 나눴다.
--   제외: 법정 제도(출산 전후 휴가 · 배우자 출산 휴가 · 육아 휴직 기본 · 육아기 근로시간 단축 · 임산부 단축근무 ·
--     권장휴가와 연차 촉진) · 사내 교육 과정(그룹 · 직무 교육, 신입 · 경력 교육체계, 연령대별 생애 과정, 문화 강좌) ·
--     리더 한정 멘탈케어 · 금연 · 체중 관리 캠페인 · 사내벤처 · 쇼핑몰 임직원 전용관(복리후생 서술 아님).
--   SORT 섹션 순서 = 정본 페이지에서 카테고리가 처음 나온 순서
--     (compensation 10 · perks 20 · leisure 30 · time_off 40 · flexibility 50 · family 60 · health 70 · growth 80).
-- 재수집(2026-09-27): 구본(2026-03-31 AI 파싱)의 근거 URL 이 끊겨(404 — 2026-09-27 출처 주간 점검) 공식 출처로 다시 세웠다
-- 검증(2026-09-28, RV-2): retirement_support 행 삭제 — BML 은 고령자고용법 21조의3 재취업지원서비스 본체(활동비·교육훈련비는 그 비용, 근로시간 단축은 남녀고용평등법 22조의3 법정 허용) — 최종 26행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('lg_elec', 'LG전자',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '전자/가전', 'L', 'https://www.lge.co.kr/company/recruit/hr');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'lg_elec');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.lge.co.kr/company/recruit/hr'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'incentive', '인센티브', NULL, 'compensation',
   'est', NULL, TRUE, '조직과 개인 성과를 고려한 인센티브 지급 가능 (공식 인사제도 페이지 임금체계 항목 — 지급 기준·지급률 미기재)', 10),
  (@comp_id, 'profit_sharing', '성과급', NULL, 'compensation',
   'est', NULL, TRUE, '회사의 경영성과에 따라 성과급 지급 여부와 지급 금액 결정 (공식 인사제도 페이지 임금체계 항목 — 지급 시기·산정 기준 미기재)', 11),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '선택적 복리후생 포인트', 100, 'perks',
   'est', '현금과 동일한 복리후생 포인트 연 100만원, 생활·건강·교육·레저·패션·제품 등에 사용 (공식 인사제도 페이지 복리후생 회사생활 항목)', FALSE, NULL, 20),
  (@comp_id, 'commute_subsidy', '출퇴근 버스', 120, 'perks',
   'est', '사업장별 특성과 교통편을 고려한 통근버스 운행 (공식 인사제도 페이지 복리후생 회사생활 항목 — 노선·이용료 미기재) (추정)', FALSE, NULL, 21),
  (@comp_id, 'meal', '사내식당', NULL, 'perks',
   'est', NULL, TRUE, '임직원 건강 증진을 위한 사내 식당 운영 (공식 인사제도 페이지 복리후생 회사생활 항목 — 제공 끼니·식대 부담 미기재)', 22),
  (@comp_id, 'housing_loan', '주택자금 지원', NULL, 'perks',
   'est', NULL, TRUE, '주택 구입 및 임차가 필요한 임직원에게 주택자금 융자 지원 (공식 인사제도 페이지 복리후생 가족 항목 — 융자 한도·이율 미기재)', 23),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'club', '동호회 활동', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 활동비 지원, 레저 문화·스포츠·음악·봉사활동 등 (공식 인사제도 페이지 복리후생 회사생활 항목 — 지원 금액·지원 기준 미기재)', 30),
  (@comp_id, 'resort', '콘도 지원', 100, 'leisure',
   'est', '전국 주요 관광지 유명 콘도를 임직원 할인금액으로 이용 지원 (공식 인사제도 페이지 복리후생 여가활동 항목 — 할인율·이용 횟수 미기재) (추정)', FALSE, NULL, 31),
  (@comp_id, 'sports_ticket', '스포츠 티켓 지원', NULL, 'leisure',
   'est', NULL, TRUE, 'LG트윈스 야구단, LG 세이커스 농구단, FC 서울 축구단 등 홈경기 티켓 제공 (공식 인사제도 페이지 복리후생 여가활동 항목 — 제공 매수·신청 방식 미기재)', 32),
  (@comp_id, 'company_event', '가족초청행사·가족 참여형 프로그램', NULL, 'leisure',
   'est', NULL, TRUE, '가족초청행사와 가족 참여형 프로그램 (2025-2026 지속가능경영보고서 55쪽 가족친화 제도). 같은 보고서 54쪽과 공식 지속가능경영 다양성과 포용 페이지에는 생애주기 Caring 프로그램의 지역별 가족프로그램 운영으로 기재 — 행사 내용·개최 주기 미기재', 33),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'long_service_leave', '장기근속 포상', NULL, 'time_off',
   'est', NULL, TRUE, '10년 이상 장기근속자에게 5년마다 포상금과 휴가 지급, 20년·30년 근속 시 배우자 동반 해외여행 제공 (공식 인사제도 페이지 복리후생 회사생활 항목 — 포상금액·휴가 일수 미기재)', 40),
  (@comp_id, 'summer_leave', '하계휴가 4일', NULL, 'time_off',
   'est', NULL, TRUE, '임직원 재충전을 위한 하계휴가 4일 별도 제공 (공식 인사제도 페이지 복리후생 여가활동 휴가 제도 항목 — 사용 시기 미기재)', 41),
  (@comp_id, 'foundation_day_leave', '회사·노조 창립기념일 휴무', NULL, 'time_off',
   'est', NULL, TRUE, '회사 창립 기념일 1일, 노조 창립 기념일 1일 별도 제공 (공식 인사제도 페이지 복리후생 여가활동 휴가 제도 항목 — 기념일 날짜 미기재)', 42),

  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'flex_work', '출퇴근 유연제도', NULL, 'flexibility',
   'est', NULL, TRUE, '출퇴근 시간을 유연하게 조절해 자기계발·자녀 통학 등에 활용 (공식 인사제도 페이지 복리후생 가족 항목). 지속가능경영보고서 55쪽에는 코어 타임 외 근무시간을 자율 조정하는 유연 근무제로 기재 — 코어 타임·정산 기간 미기재', 50),
  (@comp_id, 'remote_work', '원격 근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '업무 특성과 상황에 따라 재택 근무를 포함한 원격 근무 제도 운영 (2025-2026 지속가능경영보고서 55쪽 일·생활 균형 지원 제도). 공식 지속가능경영 다양성과 포용 페이지에는 원격근무 시스템으로 기재 — 대상 직무·사용 일수 미기재', 51),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'event', '경조금·상조서비스·재해 지원', NULL, 'family',
   'est', NULL, TRUE, '임직원 본인 및 가족의 결혼·환갑·사망 등 경조사 시 축하금 또는 위로금 지급, 직계 가족 조사 시 상조 전문 인력·조화·물품 지원, 홍수·태풍·화재 등 천재지변 피해 시 위로금 지원 (공식 인사제도 페이지 복리후생 가족 항목 — 경조 종류별 금액 미기재)', 60),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '임직원 취학 자녀 학자금 지원, 중·고·대학교 (공식 인사제도 페이지 복리후생 가족 항목 — 지원 한도·지원 자녀 수 미기재)', 61),
  (@comp_id, 'childcare', '육아시설 (직장 어린이집)', NULL, 'family',
   'est', NULL, TRUE, '사업장별 육아시설에서 희망 임직원의 자녀 돌봄 (공식 인사제도 페이지 복리후생 가족 항목). 지속가능경영보고서 141쪽에는 전국 주요 사업장에 직장 어린이집을 설치·운영한다고 기재 — 설치 사업장·정원 미기재', 62),
  (@comp_id, 'parenting', '육아휴직 최대 2년·자녀 입학 선물', NULL, 'family',
   'est', NULL, TRUE, '출산 이후 최대 2년의 육아휴직 (2025-2026 지속가능경영보고서 55쪽 가족친화 제도), 자녀 초등학교 입학·수능 선물 (같은 보고서 54쪽 생애주기 Caring 프로그램·공식 지속가능경영 다양성과 포용 페이지) — 휴직 중 급여·선물 내용 미기재', 63),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'medical', '의료비 지원', 100, 'health',
   'est', '임직원 본인 및 가족의 질병·상해 의료비 지원 (공식 인사제도 페이지 복리후생 건강 항목 — 지원 한도·가족 범위 미기재) (추정)', FALSE, NULL, 70),
  (@comp_id, 'health_check', '건강검진', 100, 'health',
   'est', '임직원 및 배우자 종합 건강검진 주기적 실시 (공식 인사제도 페이지 복리후생 건강 항목 — 검진 주기·비용 한도 미기재) (추정)', FALSE, NULL, 71),
  (@comp_id, 'mental', '심리·건강 상담', NULL, 'health',
   'est', NULL, TRUE, '전문 심리상담사 및 의료인의 상담으로 임직원 스트레스·건강관리 지원 (공식 인사제도 페이지 복리후생 건강 항목). 지속가능경영보고서 44·45쪽에는 트윈타워·평택·마곡·서초·가산·구미·창원1·창원2·고객가치혁신부문·서울역빌딩·인천 등 국내 사업장 11곳 심리상담실에서 대면·화상·전화·이메일·SNS 상담과 가족 관련 프로그램 운영으로 기재 — 상담 횟수 한도 미기재', 72),
  (@comp_id, 'fitness', '체력단련실', NULL, 'health',
   'est', NULL, TRUE, '사업장별 임직원 체력단련실 운영 (공식 인사제도 페이지 복리후생 건강 항목). 지속가능경영보고서 62쪽에는 주요 사업장 내 피트니스 센터 운영으로 기재 — 운영 사업장·이용료 미기재', 73),
  (@comp_id, 'insurance', '단체보험', NULL, 'health',
   'est', NULL, TRUE, '암, 뇌혈관 질환, 사망 등 발생 시 보험금 지급 (공식 인사제도 페이지 복리후생 건강 항목 — 보장 금액·가입 대상 미기재)', 74),
  (@comp_id, 'clinic', '부속의원·건강관리실', NULL, 'health',
   'est', NULL, TRUE, '부속의원, 건강관리실 운영 (공식 지속가능경영 존중받는 일터 페이지 임직원 건강 관리 프로그램 항목·지속가능경영보고서 62쪽) — 설치 사업장·진료 과목 미기재', 75),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'mba', '학위 파견 (국내·해외)', NULL, 'growth',
   'est', NULL, TRUE, '학위 파견 (국내/해외) — 인재육성 Process 의 Training-Job 단계 (공식 인재육성 페이지·지속가능경영보고서 53쪽). 같은 페이지 교육체계 표에는 사업가/핵심인재 과정에 MBA 로 기재 — 선발 기준·인원·비용 부담 범위 미기재', 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
