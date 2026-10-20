-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 무신사 복리후생 데이터 (신규 회사 — 웨이브 13)
-- 출처: AI 파싱 (2026-10-20)
-- URL: https://www.musinsacareers.com/ko/benefit
-- badge: est
--
-- 참고:
--   정본 URL = 채용 사이트 복리후생 페이지(점검기 ok · 복지 낱말 있음). 자기 도메인 임팩트 페이지(corp.musinsa.com/ko/impact)는
--     점검기 실측 403(blocked)이라 URL 로 쓰지 않았다.
--   주 근거 = 주식회사 무신사 자기 도메인 corp.musinsa.com 임팩트 페이지의 2026 MUSINSA IMPACT REPORT(국문 PDF · 기업명 주식회사 무신사 ·
--     PDF 수정일 2026-07-21 · 보고 기간 2025-01-01~12-31 · 보고 범위 무신사 국내사업장) 53 · 54 · 55 · 56 · 59쪽.
--     PDF 주소는 임팩트 페이지가 부르는 공개 API(prd-new-api.corp.musinsa.com/api/public/impact-reports · 키 없음)의 pdfUrl.
--     PDF 텍스트 추출(PyMuPDF) + 55쪽 5칸 표는 쪽 이미지로 짝 확인. 헤드리스 렌더 없음.
--   보조 = 무신사 채용 사이트 www.musinsacareers.com/ko/benefit(그리팅 · SSR 원본 HTML · 꼬리말 MUSINSA Inc.).
--     이 채용 사이트는 무신사 · 29CM · 무신사페이먼츠 · 무신사 스탠다드 · 무신사로지스틱스 · 무신사 글로벌 구분 필터로
--     종속회사(무신사페이먼츠 · 무신사로지스틱스) 공고도 함께 싣고 FAQ 가 여러 계열사 중복 지원을 안내한다 → 판정 (161) 대로
--     그룹 통합 채용 페이지로 보고, 이 페이지 문구를 쓴 행은 서술 끝에 (그룹 통합 채용 기준). 보고서만 근거인 행은 각주 없음.
--   공시 = 2025 사업보고서(접수 20260331003116) · 2026 반기보고서(접수 20260831000288) 유연근무제도 사용 현황 주석.
--   금액: 금액 행 1(welfare_point 연 350만 포인트 · 1포인트 1원 기준 환산이라 추정). stated 0.
--     쇼핑 지원금 월 10만 원 한도 · 생일 쇼핑 지원금 20만 원 · 초등학교 입학 축하금 50만원 · 근속 휴가비 50만원 단위는 NULL.
--     식대: 조식 · 중식 · 석식이 「운영」으로만 적혀 회사 부담이 안 드러나 금액 NULL.
--   제외: 육아휴직 · 출산휴가 · 법정 의무 교육(법정) · 온보딩 · 조직 리더 교육(업무 교육) · 사내 추천 제도 · 재입사 제도 ·
--     약정 보너스 · RSU · 스톡옵션(재량 부여) · 자율 복장 · 우리사주조합(정관 · 주주 표뿐) · 임원 보수 칸 복리후생 금액.
--   공고 근거 0행 / 전체 22행.
--   SORT 섹션 순서(정본 보고서 53~59쪽에 처음 나온 순서): compensation 10 · flexibility 20 · family 30 · perks 40 ·
--     health 50 · time_off 60 · leisure 70 · 채용 사이트에만 있는 work_env 80.
-- 검증 · 감사 판정 반영(2026-10-20): 사내 식당 meal 출처 괄호를 23쪽 실제 절 이름(친환경 요소를 반영한 공간)으로 · 그룹 통합 채용 사이트 근거 9행 각주 유지 · 생일 쇼핑 지원금 · 월 쇼핑 지원금 한도 · 식대 금액 NULL 유지 · 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 22행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('musinsa', '무신사',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '패션', 'M', 'https://www.musinsacareers.com/ko/benefit');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'musinsa');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.musinsacareers.com/ko/benefit'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상 (compensation) — 2026 임팩트 리포트 53 · 56쪽 ──
  (@comp_id, 'incentive', '성과 인센티브', NULL, 'compensation',
   'est', NULL, TRUE, '기대 수준의 성과 달성 여부를 반기 단위로 점검하고 그 결과에 따라 개별화된 보상 제공, 보상 체계는 인센티브 지급 등으로 구성 (2026 임팩트 리포트 53쪽 성과 보상 제도 항목) — 지급 기준·지급률 미기재', 10),
  (@comp_id, 'excellence_award', 'MUSINSA WAY Awards', NULL, 'compensation',
   'est', NULL, TRUE, '업무 과정에서 핵심 가치를 모범적으로 실천한 사례를 선정해 시상하는 MUSINSA WAY Awards 운영 (2026 임팩트 리포트 56쪽 MUSINSA WAY Awards 항목) — 포상 내용 미기재', 11),

  -- ── 근무 유연성 (flexibility) — 2026 임팩트 리포트 54쪽 · 공시 ──
  (@comp_id, 'flex_work', '선택적 근로시간제', NULL, 'flexibility',
   'est', NULL, TRUE, '월 소정 근로시간을 기준으로 업무 집중이 필요한 코어타임(11시~16시)을 준수하는 가운데 출퇴근 및 근무 시간을 유연하게 조정 (2026 임팩트 리포트 54쪽 유연 근무 항목), 1개월 단위로 본인의 근무시간을 관리하는 선택적근로시간제(선택근무제) 활용 (2026 반기보고서 유연근무제도 사용 현황 항목)', 20),
  (@comp_id, 'remote_work', '재택근무', NULL, 'flexibility',
   'est', NULL, TRUE, '조직별 업무 특성에 맞추어 자율적으로 스케줄 조정을 통한 주 2회 재택 근무 시행 (2026 임팩트 리포트 54쪽 재택 근무 항목), 조직별 업무 특성에 맞춘 재택근무제도 시행 (2026 반기보고서 유연근무제도 사용 현황 항목) — 조직별 적용 기준 미기재', 21),

  -- ── 가족 (family) — 2026 임팩트 리포트 55쪽 ──
  (@comp_id, 'parenting', '출산·입학 축하금, 위탁 보육비 지원', NULL, 'family',
   'est', NULL, TRUE, '구성원 자녀 출산 및 초등학교 입학 시 축하금 (2026 임팩트 리포트 55쪽 사내 생활 지원 항목), 어린이집 재원 중인 만 0세~5세 이하 자녀를 둔 구성원(부모)의 보육비 일부 및 추가 비용(특별 활동비, 현장 학습비 등) 지원, 연령별 법정 보육료 지원 단가의 50%를 지급 (같은 쪽 위탁 보육비 지원 항목), 초등학교 입학 시 50만원 축하금 지원 (무신사 채용 사이트 복리후생 생활지원 항목) — 출산 축하금 금액 미기재 (그룹 통합 채용 기준)', 30),
  (@comp_id, 'child_edu', '자녀 대학교 등록금 지원', NULL, 'family',
   'est', NULL, TRUE, '구성원 자녀 대학교 입학 시 등록금 지원 (2026 임팩트 리포트 55쪽 사내 생활 지원 항목) — 지원 금액·지원 횟수 미기재', 31),
  (@comp_id, 'event', '경조금·경조 휴가·경조 물품', NULL, 'family',
   'est', NULL, TRUE, '경조 휴가, 경조 물품 및 경조금 지원 (2026 임팩트 리포트 55쪽 사내 생활 지원 항목) — 경조 사유별 금액·휴가 일수 미기재', 32),

  -- ── 생활 · 금융 (perks) — 2026 임팩트 리포트 55쪽 · 채용 사이트 ──
  (@comp_id, 'welfare_fund_loan', '사내 대출·금융권 대출 이자 지원', NULL, 'perks',
   'est', NULL, TRUE, '사내 대출 제도 운용 및 금융권 대출에 대한 이자 지원 (2026 임팩트 리포트 55쪽 사내 생활 지원 항목) — 대출 용도·한도·이율 미기재', 40),
  (@comp_id, 'discount', '쇼핑 지원금(Self-Love비)·자사 플랫폼 할인', NULL, 'perks',
   'est', NULL, TRUE, '월 10만 원 한도로 무신사/29CM/솔드아웃/무신사 엠프티 온라인 사이트 및 오프라인 매장 쇼핑 지원금(Self-Love비) 지급, 자사 플랫폼 할인 혜택 제공 (2026 임팩트 리포트 55쪽 무신사 스토어 혜택 항목), 매월 무신사 최대 40% 쿠폰 7장 · 29CM 20% 장바구니 쿠폰 5장 · 엠프티 최대 30% 쿠폰 2장 (무신사 채용 사이트 복리후생 스토어 혜택 항목) — 할인율 외 사용 조건 미기재 (그룹 통합 채용 기준)', 41),
  (@comp_id, 'birthday_gift', '생일 쇼핑 지원금', NULL, 'perks',
   'est', NULL, TRUE, '생일 월 무신사 패밀리 사이트 내 제품 구매 시 쇼핑 지원금 20만 원 추가 지급 (2026 임팩트 리포트 55쪽 무신사 스토어 혜택 항목) — 사용 기한 미기재', 42),
  (@comp_id, 'welfare_point', '복지 포인트', 350, 'perks',
   'est', '연 350만 복지 포인트 지급, 자기 계발·가족 건강검진·물품 구매 등 온오프라인에서 자유롭게 사용 (2026 임팩트 리포트 55쪽 복지 포인트 항목) — 1포인트 1원 기준 환산', FALSE, NULL, 43),
  (@comp_id, 'meal', '사내 식당 모락모락', NULL, 'perks',
   'est', NULL, TRUE, '본사 사내 식당 모락모락 (2026 임팩트 리포트 23쪽 친환경 요소를 반영한 공간 항목), 사내 식당 모락모락 운영, 조식/중식/석식/To-go Bag 운영 (무신사 채용 사이트 복리후생 사내 식당, 사내 카페 항목) — 식대 부담 방식 미기재 (그룹 통합 채용 기준)', 44),
  (@comp_id, 'snack_bar', '사내 카페 아즈니섬', NULL, 'perks',
   'est', NULL, TRUE, '사내 카페 아즈니섬 운영, 임직원 55% 할인 (무신사 채용 사이트 복리후생 사내 식당, 사내 카페 항목) — 운영 사업장 미기재 (그룹 통합 채용 기준)', 45),

  -- ── 건강 (health) — 2026 임팩트 리포트 55 · 59쪽 ──
  (@comp_id, 'health_check', '종합건강검진·독감 예방 접종', NULL, 'health',
   'est', NULL, TRUE, '연 1회 건강 검진, 독감 예방 접종 지원 (2026 임팩트 리포트 55쪽 건강/휴식 항목), 매년 1회 종합건강검진 제공 (같은 보고서 59쪽 구성원 건강 관리 항목), 검진 당일 검진휴가 (0.5일) 제공 (무신사 채용 사이트 복리후생 건강/휴식 항목) — 검진 항목·비용 지원 범위 미기재 (그룹 통합 채용 기준)', 50),
  (@comp_id, 'mental', '심리 상담·전문가 자문', NULL, 'health',
   'est', NULL, TRUE, '연 10회 심리 상담 지원 (2026 임팩트 리포트 55쪽 건강/휴식 항목), 전문업체와 연계한 심리 상담 서비스로 대인관계, 업무, 직무 등 다양한 요인으로 발생한 스트레스와 개별 고민 상담 (같은 보고서 59쪽 전문가 심리 상담 서비스 지원 항목), 연 10회 심리상담 및 전문가 자문 지원, 개인 정서, 재무/법률/세무 상담 제공 (무신사 채용 사이트 복리후생 건강/휴식 항목) — 가족 이용 여부 미기재 (그룹 통합 채용 기준)', 51),
  (@comp_id, 'insurance', '단체 상해보험 (본인·배우자·자녀)', NULL, 'health',
   'est', NULL, TRUE, '단체 상해 보험 가입 (본인, 배우자, 자녀) (2026 임팩트 리포트 55쪽 건강/휴식 항목), 직원 본인 및 배우자, 자녀를 대상으로 단체상해보험을 통해 질병 상해 치료를 보장 (같은 보고서 59쪽 구성원 건강 관리 항목) — 보장 한도 미기재', 52),
  (@comp_id, 'clinic', '사내 건강관리실 CLINIC', NULL, 'health',
   'est', NULL, TRUE, '본사 건물 무신사 성수 N1에 사내 건강관리실 CLINIC 운영, 근무 중 몸이 좋지 않을 때 쉴 수 있는 휴식 공간과 상처 드레싱에 필요한 의약외품 등 제공, 인바디와 혈압계 구비 (2026 임팩트 리포트 59쪽 건강관리실 CLINIC 운영 항목) — 의료 인력 상주 여부 미기재', 53),

  -- ── 휴가 (time_off) — 2026 임팩트 리포트 55쪽 · 채용 사이트 ──
  (@comp_id, 'long_service_leave', '장기근속 포상 휴가·추가 복지 포인트', NULL, 'time_off',
   'est', NULL, TRUE, '3년, 6년, 9년, 12년 만근 시 추가 복지 포인트 및 포상 휴가 제공 (2026 임팩트 리포트 55쪽 건강/휴식 항목), 근속 3년 당 7일의 리프레시 휴가 제공(7일/14일/21일 등), 근속 3년 당 50만원의 휴가비 (복지포인트) 지급(50만원/100만원/150만원 등) (무신사 채용 사이트 복리후생 장기 근속 휴가 및 휴가비 지급 항목) — 휴가 사용 기한 미기재 (그룹 통합 채용 기준)', 60),
  (@comp_id, 'leave_general', '2시간 단위 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '휴가는 1일 8시간, 0.5일 4시간, 0.25일 2시간 단위로 유연하게 사용 가능 (2026 임팩트 리포트 55쪽 건강/휴식 항목)', 61),

  -- ── 여가 · 행사 (leisure) — 2026 임팩트 리포트 56쪽 ──
  (@comp_id, 'company_event', '감사 이벤트·월간 패션왕', NULL, 'leisure',
   'est', NULL, TRUE, '연 2회 감사 이벤트 운영, 초복 시즌 전 구성원 삼계탕 특식 제공 · 럭키드로우 등 (2026 임팩트 리포트 56쪽 무신사 피플을 응원합니다 항목), 매월 무신사 월간 패션왕 선정 및 1등 소정의 상품 제공 (같은 쪽 수요출근룩과 무신사 월간 패션왕 항목) — 겨울 행사 내용 미기재', 70),

  -- ── 근무 환경 (work_env) — 채용 사이트 ──
  (@comp_id, 'work_tools', 'AI Agent·업무 장비 지원', NULL, 'work_env',
   'est', NULL, TRUE, 'AI Excellence 실현을 위한 전사 AI Agent 제공 (Claude, Cursor 등), 업무에 필요한 모든 물품 (MRO) 지원, 최고급 사양의 업무 장비 및 시설 지원 (무신사 채용 사이트 복리후생 프리미엄 업무 장비 지원 항목) — 장비 교체 주기 미기재 (그룹 통합 채용 기준)', 80),
  (@comp_id, 'office_furniture', '허먼 밀러 의자', NULL, 'work_env',
   'est', NULL, TRUE, '허먼 밀러 의자 지원 (무신사 채용 사이트 복리후생 프리미엄 업무 장비 지원 항목) — 지원 대상 미기재 (그룹 통합 채용 기준)', 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
