-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 대한항공 복리후생 데이터
-- 출처: AI 파싱 (2026-10-02)
-- URL: https://kr.img.news.koreanair.com/wp-content/uploads/2026/06/2026_Korean_Air_ESG_Report_kr.pdf
-- badge: est
--
-- 참고:
--   정본 URL 은 법인 발행 2026 대한항공 ESG 보고서(국문 PDF, 119쪽)다. 대한항공 뉴스룸 news.koreanair.com 지속가능경영
--     게시글 2026 대한항공 ESG 보고서(2026-06-24)가 이 파일을 링크한다. 채용 사이트 복리후생 페이지
--     koreanair.recruiter.co.kr/career/hrp4 는 본문이 robots 전면 금지 API(api-recruiter.recruiter.co.kr) 에서만 와서
--     읽지 못해 정본으로 쓰지 않았다.
--   행 근거는 이 보고서와 2025 사업보고서(OpenDART 2026-03-18 제출, 보수 지급 기준의 경영성과급 · 안전장려금 구성)다.
--     보고서 근거 쪽은
--     55쪽 복리후생 제도 표(건강지원 · 노후생활 지원 · 여가생활 지원 · 육아지원 · 인센티브 · 생활 지원) 와
--     사내 건강 증진 시설 · 근무환경 개선, 52 · 53쪽 정신건강, 56쪽 가족친화 · 유연근무, 57쪽 재충전 · 보상 · Job Market,
--     58쪽 평생학습 · 교육체계, 74쪽 Beyond Excellence Service. 서술 괄호에 쪽을 적었다.
--   www.koreanair.com 은 robots.txt 부터 403(접속 거부) 이라 그 호스트 본문은 요청하지 않았다.
--   귀속: 보고 범위 = 대한항공 본사 및 대한항공 국내외 전 사업장(보고서 2쪽) — 법인 발행물이라 그룹 각주 없음.
--     한진칼 · 진에어 · 아시아나항공 · 에어부산 · 에어서울 문장은 쓰지 않았다(아시아나 공동 건강 프로그램 문장 제외).
--   직군: 원문이 대상을 밝힌 것만 서술에 적었다(해외체류 승무원 의료비 · 비행 업무 승무원 임신 휴직 · 정규직 비정규직 동일 지급).
--   금액: 월액 환산 1(pension_support 개인연금 월 5만원 → 60, NOTE 에 환산) · 구본 추정 승계 2(health_check 100 ·
--     resort 50 — 둘 다 틀 값, NOTE 끝에 (추정)). discount 200 은 회사 고유값이고 전제가 원문에 없어 승계하지 않았다.
--     항공권 매수 · 직원 1인당 평균 복리후생비(회사 전체 집계) 는 금액 칸에 넣지 않았다.
--   제외: 건강보험 · 국민연금 가입 · 법정 모성보호 제도 · 가족돌봄 등 근로시간 단축(법정) · 정년퇴직 예정자 전직 지원 프로그램
--     (1,000인 이상 재취업지원 법정) · 정년 재채용 · 공휴일 징검다리 휴무(본인 휴가 사용과 가를 수 없음) · 직장신협 운영(혜택 내용
--     미기재) · 회사 주도 교육과 건강 캠페인 · 안전 포상(Beyond Excellence SMS · Safety Champion).
--   구본에서 뺀 행: long_service_bonus(장기근속 여행 · 정년퇴직 여행비 문장 없음 — 장기근속 항공권은 discount 서술).
--   재코딩: edu_support → mba (남는 제도가 대학원 장학금 · 사내 기술대학 학위 과정 — 학위 지원).
--   SORT 섹션 순서 = 55쪽 복리후생 제도 표에서 카테고리가 처음 나온 순서, 다른 쪽 근거 행은 해당 섹션 끝
--     (health 10 · perks 20 · leisure 30 · family 40 · compensation 50 · work_env 60 · growth 70 · flexibility 80 · time_off 90).
-- 재수집(2026-10-02): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-04, RV-3-7): 정본 URL 을 ESG 보고서 PDF 로 · 2025 사업보고서 근거 profit_sharing(이익분배금) 행 추가 · incentive 를 실적장려금 · 안전장려금으로 · 문안 4 — 최종 31행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('korean_air', '대한항공',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '항공', 'D', 'https://kr.img.news.koreanair.com/wp-content/uploads/2026/06/2026_Korean_Air_ESG_Report_kr.pdf');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'korean_air');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://kr.img.news.koreanair.com/wp-content/uploads/2026/06/2026_Korean_Air_ESG_Report_kr.pdf'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강·의료 (health) — 2026 ESG 보고서 55쪽 건강지원 · 건강 증진 시설 / 52 · 53쪽 ──
  (@comp_id, 'health_check', '42세 이상 종합건강검진', 100, 'health',
   'est', '기본 건강검진 외 42세 이상 종합 검진 지원 (2026 대한항공 ESG 보고서 55쪽 복리후생 제도 건강지원 항목) — 검진 항목·비용 미기재 (추정)', FALSE, NULL, 10),
  (@comp_id, 'clinic', '사내 부속 의원·독감 예방접종', NULL, 'health',
   'est', NULL, TRUE, '사내 부속 의원 및 심리상담실, 출장 진단 및 상담 운영(항공전문의사 및 간호사, 심리상담사 등 전문인력 상주), 독감 예방접종 지원 (2026 대한항공 ESG 보고서 55쪽 복리후생 제도 건강지원 항목)', 11),
  (@comp_id, 'insurance', '자가보험 (직원·배우자 질병·사고·사망)', NULL, 'health',
   'est', NULL, TRUE, '자가보험 지원(직원 및 배우자 질병, 사고, 사망 시 지원) (2026 대한항공 ESG 보고서 55쪽 복리후생 제도 건강지원 항목) — 지원 금액·보장 범위 미기재', 12),
  (@comp_id, 'medical', '의료비 지원 (해외체류 승무원·출장자)', NULL, 'health',
   'est', NULL, TRUE, '해외체류 승무원 및 출장 중 발생한 의료비 지원 (2026 대한항공 ESG 보고서 55쪽 복리후생 제도 건강지원 항목), 암 치료 후 복귀 직원 대상 의료지원 프로그램 운영 (같은 보고서 53쪽) — 지원 한도 미기재', 13),
  (@comp_id, 'fitness', 'KOC 피트니스센터·사내 수영장', NULL, 'health',
   'est', NULL, TRUE, 'KOC 피트니스센터 상시 운영(요가, 타바타 등 GX 프로그램 및 PT 운영), 사내 수영장 상시 운영(정기 강습 진행), 부산 테크센터/대전연구원/화물청사 체력단련실 (2026 대한항공 ESG 보고서 55쪽 사내 건강 증진 시설)', 14),
  (@comp_id, 'mental', '사내 심리상담실 휴클리닉·마음건강검진', NULL, 'health',
   'est', NULL, TRUE, '사내 심리상담실 휴클리닉에서 임직원 누구나 익명성이 보장된 환경에서 전문 심리상담사의 온·오프라인 심리상담 지원 (2026 대한항공 ESG 보고서 52쪽), 마음건강검진 운영 및 위험군 대상 개별 상담, 트라우마 심리지원 프로그램 운영 (같은 보고서 53쪽)', 15),

  -- ── 경제적 부가혜택 (perks) — 55쪽 노후생활 지원 · 여가생활 지원 · 생활 지원 · 근무환경 개선 / 57쪽 ──
  (@comp_id, 'pension_support', '개인연금 지원 (월 5만원)', 60, 'perks',
   'est', '전 직원 개인연금 월 5만원 지원 (2026 대한항공 ESG 보고서 55쪽 복리후생 제도 노후생활 지원 항목) — 월 5만원을 연 60만원으로 환산', FALSE, NULL, 20),
  (@comp_id, 'discount', '직원 할인 항공권 (본인·직계가족)', NULL, 'perks',
   'est', NULL, TRUE, '본인 및 직계가족 할인 항공권 제공, 항공권 연간 25~35매 지원(결혼/효도/장기근속 등은 별도 지원) (2026 대한항공 ESG 보고서 55쪽 복리후생 제도 여가생활 지원 항목), 대표적인 복리후생 제도인 직원 할인 항공권을 고용 형태에 관계없이 공평하게 제공 (같은 보고서 57쪽) — 할인율·매수 산정 기준 미기재', 21),
  (@comp_id, 'welfare_point', '선택적 복지제도', NULL, 'perks',
   'est', NULL, TRUE, '선택적 복지제도 운영 (2026 대한항공 ESG 보고서 55쪽 복리후생 제도 생활 지원 항목) — 배정 포인트·금액 미기재', 22),
  (@comp_id, 'housing_loan', '주택 구입·전세자금 융자', NULL, 'perks',
   'est', NULL, TRUE, '주택 구입 및 전세자금 융자 (2026 대한항공 ESG 보고서 55쪽 복리후생 제도 생활 지원 항목) — 대출 한도·금리 미기재', 23),
  (@comp_id, 'snack_bar', '전사 커피라운지·매월 생수 지원', NULL, 'perks',
   'est', NULL, TRUE, '전사 커피라운지 운영 — 커피/차 상시 제공, 글로벌서비스센터 커피라운지 신규 조성 (2026 대한항공 ESG 보고서 55쪽 근무환경 개선), 전 임직원 매월 생수 지원 (같은 쪽 복리후생 제도 생활 지원 항목)', 24),
  (@comp_id, 'birthday_gift', '임직원 생일·크리스마스 케이크 등 기념일 지원', NULL, 'perks',
   'est', NULL, TRUE, '기념일 지원(임직원 생일, 크리스마스 케이크 지원 등) (2026 대한항공 ESG 보고서 55쪽 복리후생 제도 생활 지원 항목) — 품목·금액 미기재', 25),
  (@comp_id, 'meal', '사내 식당 (정비기지 식당 등)', NULL, 'perks',
   'est', NULL, TRUE, '식당 시설 개선 및 품질/편의성 향상 — 정비기지 식당 리모델링, 식당 메뉴 및 Grab&Go 품목 다양화, 외부식당 사용처 지속 확대 (2026 대한항공 ESG 보고서 55쪽 근무환경 개선) — 식대·제공 끼니 미기재', 26),

  -- ── 여가·라이프 (leisure) — 55쪽 여가생활 지원 / 56쪽 ──
  (@comp_id, 'resort', '국내 유명 콘도·호텔 할인·하계휴양소', 50, 'leisure',
   'est', '국내유명 콘도(리조트) 지원, 국내외 유명 호텔 할인가 제공, 부산지역 하계휴양소 운영 (2026 대한항공 ESG 보고서 55쪽 복리후생 제도 여가생활 지원 항목) — 이용 횟수·본인 부담 미기재 (추정)', FALSE, NULL, 30),
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 활동 지원, 동호회 재능 기부 행사 실시 (2026 대한항공 ESG 보고서 55쪽 복리후생 제도 여가생활 지원 항목) — 지원 금액·동호회 수 미기재', 31),
  (@comp_id, 'sports_ticket', '스포츠 경기 관람 지원', NULL, 'leisure',
   'est', NULL, TRUE, '스포츠 경기 관람 지원 (2026 대한항공 ESG 보고서 55쪽 복리후생 제도 여가생활 지원 항목) — 종목·지원 방식 미기재', 32),
  (@comp_id, 'company_event', '패밀리 데이·가족 영화 관람·수영장 가족 개방', NULL, 'leisure',
   'est', NULL, TRUE, '임직원 가족 영화 관람 행사, 사내 수영장 임직원 가족 대상 하계 오픈 행사 (2026 대한항공 ESG 보고서 55쪽 복리후생 제도 여가생활 지원 항목), 임직원 가족들을 회사로 초청해 일터를 직접 둘러보고 다양한 프로그램을 체험할 수 있는 패밀리 데이 행사 매년 진행 (같은 보고서 56쪽)', 33),

  -- ── 가족·돌봄 (family) — 55쪽 육아지원 · 생활 지원 / 56 · 57쪽 ──
  (@comp_id, 'parenting', '위탁보육비·보육수당·승무원 임신 휴직·입학 축하 선물', NULL, 'family',
   'est', NULL, TRUE, '위탁보육비 및 보육수당 지원 (2026 대한항공 ESG 보고서 55쪽 복리후생 제도 육아지원 항목), 직원이 직접 선택한 어린이집과 위탁 보육 계약을 체결하고 보육료 지원, 비행 업무를 하는 승무원은 태아 및 모체 보호를 위해 임신 사실을 인지한 시점부터 임신 휴직 사용 가능, 어린이 자녀를 둔 임직원 대상 어린이날·크리스마스 선물과 초등학교 입학 축하 선물 제공 (같은 보고서 56쪽) — 보육수당 금액 미기재', 40),
  (@comp_id, 'child_edu', '자녀 학자금 (국내외 고교·대학·특수학교)', NULL, 'family',
   'est', NULL, TRUE, '자녀 교육비 지원(국내외 고등학교/대학교/장애인 특수학교 자녀학자금, 해외 주재원 자녀 학자금 및 어학 교육비), 수험생 자녀 입시 설명회 개최 (2026 대한항공 ESG 보고서 55쪽 복리후생 제도 생활 지원 항목) — 지원 한도·자녀 수 미기재', 41),
  (@comp_id, 'event', '경조사 지원 (청원 휴가·경조금·화환·장례용품)', NULL, 'family',
   'est', NULL, TRUE, '경조사 지원(청원 휴가, 경조금, 화환 및 장례용품 등) (2026 대한항공 ESG 보고서 55쪽 복리후생 제도 생활 지원 항목), 각종 경조사 등 소정사유 발생 시 대상 근로자에게 필요한 유급휴가 부여 (같은 보고서 57쪽) — 경조금 액수·휴가 일수 미기재', 42),
  (@comp_id, 'fertility_support', '난임 휴직 (최대 1년)', NULL, 'family',
   'est', NULL, TRUE, '전문의에 의한 난임 판정을 받은 여성 직원 중 인공수정, 시험관 시술 희망자 대상 최대 1년 난임 휴직 (2026 대한항공 ESG 보고서 56 · 57쪽) — 휴직 중 급여 미기재', 43),

  -- ── 보상·금전 (compensation) — 55쪽 인센티브 / 57 · 74쪽 / 2025 사업보고서 보수 지급 기준 ──
  (@comp_id, 'incentive', '경영성과급 실적장려금·안전장려금', NULL, 'compensation',
   'est', NULL, TRUE, '경영성과급 중 실적장려금(영업이익에서 순이자비용을 초과한 금액 범위 내, 월 보수 기준 최대 150%)과 안전장려금(회사가 정한 안전목표 달성 시 월 보수의 100%)을 모든 임직원에게 지급, 정규직과 비정규직 평등 처우 (2025 사업보고서 이사 보수 산정기준 · 2026 대한항공 ESG 보고서 55쪽 인센티브 항목 · 57쪽) — 연도별 지급률 미기재', 50),
  (@comp_id, 'excellence_award', 'Beyond Excellence Service 우수 서비스 직원 포상', NULL, 'compensation',
   'est', NULL, TRUE, '서비스 현장에서 탁월한 역량으로 고객 만족에 기여한 직원을 선정하여 포상, 수상자를 본사로 초청하고 포상금 지급 (2026 대한항공 ESG 보고서 74쪽 Beyond Excellence Service 제도) — 포상금 액수·선정 인원 미기재', 51),
  (@comp_id, 'profit_sharing', '경영성과급 이익분배금', NULL, 'compensation',
   'est', NULL, TRUE, '경영성과급 중 이익분배금, 영업이익에서 순이자비용을 초과한 금액 범위 내에서 지급기준에 따라 월 보수 기준 최대 350%를 모든 임직원에게 지급 (2025 사업보고서 이사 보수 산정기준 항목) — 연도별 지급률 미기재', 52),

  -- ── 근무환경 (work_env) — 55쪽 생활 지원 · 근무환경 개선 · 육아지원 / 56쪽 ──
  (@comp_id, 'dormitory', '사택 제공 (1,079세대)', NULL, 'work_env',
   'est', NULL, TRUE, '사택제공 (1,079 세대) (2026 대한항공 ESG 보고서 55쪽 복리후생 제도 생활 지원 항목) — 입주 자격·지역 미기재', 60),
  (@comp_id, 'lounge', '현장 휴게 공간·T2 휴게 라운지', NULL, 'work_env',
   'est', NULL, TRUE, '현장 휴게 공간 개선 — 테크센터, 정비훈련원 휴게 공간 개선, 글로벌서비스센터 휴게 공간 신규 조성, T2 휴게 라운지 신규 조성(객실 비행준비실, 운송 통합 사무실) (2026 대한항공 ESG 보고서 55쪽 근무환경 개선)', 61),
  (@comp_id, 'nap_room', '모아사랑방(수유 공간)·수면실', NULL, 'work_env',
   'est', NULL, TRUE, '젖병 소독기 및 모유 보관 시설이 구비되어 있는 사내 수유 공간 모아사랑방 운영 (2026 대한항공 ESG 보고서 55쪽 육아지원 항목 · 56쪽), 글로벌서비스센터 수면실 신규 조성 (같은 보고서 55쪽 근무환경 개선)', 62),

  -- ── 성장·교육 (growth) — 55쪽 생활 지원 / 57 · 58쪽 ──
  (@comp_id, 'mba', '대학원 장학금·사내 기술대학(정석대학)', NULL, 'growth',
   'est', NULL, TRUE, '업무 관련 지정 대학/대학원 진학 시 직원 학자금 지원 (2026 대한항공 ESG 보고서 55쪽 복리후생 제도 생활 지원 항목), 항공대학교 및 인하대학교 항공/물류 관련 대학원에 진학하는 직원 장학금 지원(2025년 119명), 국내 최초의 사내 기술대학 정석대학 재학생 전원 전액 장학금, 경영관리교육 체계의 MBA 과정 (같은 보고서 58쪽) — 선발 기준·지원 범위 미기재', 70),
  (@comp_id, 'career', 'Job Market·사내 공모', NULL, 'growth',
   'est', NULL, TRUE, '직원이 희망 부서와 보유 역량을 기재한 자기성장 계획서를 등록하면 타 부서 충원 소요 발생 시 매칭해 선발·배치하는 Job Market 제도(2022년부터), 인력 충원이 필요한 부서 주관 사내 공모 제도로 희망 직무에 자율 지원 (2026 대한항공 ESG 보고서 57쪽)', 71),

  -- ── 근무 유연성 (flexibility) — 56쪽 유연근무제도 ──
  (@comp_id, 'flex_work', '출근시간 선택 유연근무', NULL, 'flexibility',
   'est', NULL, TRUE, '업무별 특성과 개인의 상황을 고려한 유연 근무 제도 운영, 개인의 상황에 따라 출근시간 선택 (2026 대한항공 ESG 보고서 56쪽 유연근무제도 운영) — 적용 직군·시간대 미기재', 80),

  -- ── 시간·휴가 (time_off) — 57쪽 임직원 재충전 기회 부여 ──
  (@comp_id, 'leave_general', '질병 유급휴가·상시 휴직', NULL, 'time_off',
   'est', NULL, TRUE, '업무외 질병/상병 등 소정사유 발생 시 대상 근로자에게 필요한 유급휴가 부여, 취학자녀 돌봄 등의 사유로 최대 3년까지 휴직이 가능한 상시 휴직제도 (2026 대한항공 ESG 보고서 57쪽 임직원 재충전 기회 부여) — 유급휴가 일수 미기재', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
