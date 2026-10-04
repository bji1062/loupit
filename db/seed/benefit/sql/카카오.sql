-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 카카오 복리후생 데이터
-- 출처: AI 파싱 (2026-09-28)
-- URL: https://careers.kakao.com/kakaolife
-- badge: est
--
-- 참고:
--   정본은 카카오 자사 채용 사이트 카카오 영입(careers.kakao.com)의 카카오 생활 페이지(/kakaolife) 안
--   크루 혜택 블록이다. 4섹션 22항목(생활 속 지원 8 · 업무 몰입 지원 4 · 휴식 지원 5 · 건강 증진 지원 5).
--   사이트는 React SPA 라 서버 응답은 1,563 B 셸이고, 항목 본문은 번들 /static/js/main.41c46ebd.js 안의
--   ko 번역 JSON(kakaolife.*)에 있으며 크루 혜택 컴포넌트의 benefitCont 배열이 렌더 순서를 정한다 — 헤드리스 렌더 없음.
--   robots: careers.kakao.com/robots.txt 는 HTTP 401(본문 없음) — RFC 9309 의 unavailable(4xx)이라 규칙 없음 = 허용.
--   귀속: 채용 공고 API 의 회사명이 전부 카카오(Kakao Corp)이고 페이지 오피스 위치가 카카오 본사·판교아지트 등
--   카카오 사업장이다 — 법인 전용 페이지라 그룹 각주를 달지 않았다. 카카오페이 · 카카오뱅크 페이지는 보지 않았다.
--   제외: 번역 JSON 에만 있고 어느 컴포넌트도 부르지 않는 Mytime 제도(고아 키) · 로그인 뒤 처우 제안 화면 전용 문구
--   (salarySuggest — 식비 월 20만원 · 가족 돌봄 휴가 등, 공개 페이지가 아니라 행 근거로 쓰지 않음). 사내 강연·북토크는 2026-10-04 규칙 8 개정으로 edu_support 서술에 되살렸다.
--   금액: 명시값 2행(welfare_point 연 360 · holiday_gift 설 · 추석 각 30만원 = 60) · 환산 1행(long_service_leave 3년마다
--     휴가비 200만원 → 연 67) · 승계 추정치 3행(health_check 100 · insurance 30 · resort 50 — NOTE 끝에 (추정)).
--     구본 추정치 meal 240 · snack_bar 144 · commute_subsidy 120 은 승계하지 않았다(전제가 공식 원문과 다르거나 원문에 없음).
--   구본에서 뺀 행: flex_work · parenting · self_development · work_tools (공개 원문 근거 없음).
--   재코딩: 없음.
--   SORT 섹션 순서 = 정본 페이지에서 카테고리가 처음 나온 순서
--     (perks 10 · family 20 · health 30 · compensation 40 · leisure 50 · growth 60 · time_off 70 · work_env 80).
-- 재수집(2026-09-28): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-09-28, RV-3): commute_subsidy 추정치 120 승계 복원 — 미승계 근거(유료 통근버스)가 로그인 뒤 처우 제안 화면 문구라 L7 로 공개 원문이 아니고 R6 ② 열거 유형에도 없음(H1 20사 · 카카오페이 대칭) — 최종 23행
-- 후속 정리 2(2026-10-04, R-3): 사용자가 정한 복지 범위 규칙 개정(규칙 8 · 기준 13 · 기준 18 · 기준 20 · 기준 23)과 코퍼스 판정을 반영 — 서술 · 이름 수정 1(edu_support) — 최종 23행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('kakao', '카카오',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        'IT/플랫폼', 'K', 'https://careers.kakao.com/kakaolife');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'kakao');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://careers.kakao.com/kakaolife'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 경제적 부가혜택 (perks) — 생활 속 지원 · 업무 몰입 지원 · 휴식 지원 ──
  (@comp_id, 'welfare_point', '카카오 베네핏 카드', 360, 'perks',
   'est', '업무 몰입과 자기개발, 여가/취미 활동 지원을 위해 연 360만원까지 사용할 수 있는 개인별 베네핏 카드 지급 (공식 채용 사이트 카카오 생활 크루 혜택 생활 속 지원 카카오 베네핏 항목)', FALSE, NULL, 10),
  (@comp_id, 'housing_loan', '복지대출 지원', NULL, 'perks',
   'est', NULL, TRUE, '주택구입 및 임차, 생활안정을 위해 최대 1억 5천만원까지 대출금을 지원하고 대출자금의 2% 초과 이자 지원 (공식 채용 사이트 카카오 생활 크루 혜택 생활 속 지원 복지대출 지원 항목 — 연계 금융기관·자격 요건 미기재)', 11),
  (@comp_id, 'discount', '카카오프렌즈샵 20% 할인', NULL, 'perks',
   'est', NULL, TRUE, '사내 프렌즈샵과 온라인스토어에서 카카오프렌즈 캐릭터 아이템 20% 할인 구매 (공식 채용 사이트 카카오 생활 크루 혜택 생활 속 지원 카카오프렌즈샵 할인 항목 — 연간 한도 미기재)', 12),
  (@comp_id, 'commute_subsidy', '통근버스/순환버스', 120, 'perks',
   'est', '서울/경기 지역 내 다양한 셔틀 노선 제공과 판교역 부근 순환버스 운영 (공식 채용 사이트 카카오 생활 크루 혜택 업무 몰입 지원 통근버스/순환버스 항목 — 노선 수·이용 요금 미기재) (추정)', FALSE, NULL, 13),
  (@comp_id, 'snack_bar', '상시 음료·간식·사내 카페', NULL, 'perks',
   'est', NULL, TRUE, '상시로 제공되는 음료 및 간식(공식 채용 사이트 카카오 생활 크루 혜택 업무 몰입 지원 먹거리/교통비 지원 항목), 다양한 메뉴의 사내 카페(같은 사이트 휴식 지원 휴식공간 항목) — 사내 카페 이용 요금 미기재', 14),
  (@comp_id, 'meal', '야근 저녁 식대 실비', NULL, 'perks',
   'est', NULL, TRUE, '야근 시 저녁 식대 실비 지원 (공식 채용 사이트 카카오 생활 크루 혜택 업무 몰입 지원 먹거리/교통비 지원 항목 — 야근 기준 시간·평상시 식사 제공 미기재)', 15),
  (@comp_id, 'transport', '야근 택시비 실비', NULL, 'perks',
   'est', NULL, TRUE, '밤 10시 이후 안전한 귀가를 위한 택시비 실비 지원 (공식 채용 사이트 카카오 생활 크루 혜택 업무 몰입 지원 먹거리/교통비 지원 항목 — 지원 한도 미기재)', 16),

  -- ── 가족·돌봄 (family) — 생활 속 지원 ──
  (@comp_id, 'childcare', '어린이집', NULL, 'family',
   'est', NULL, TRUE, '만 0세부터 5세반까지 구성된 학급, 푸르니 표준보육과정을 기본으로 체육·음악·영어 등 특성화 프로그램 운영 (공식 채용 사이트 카카오 생활 크루 혜택 생활 속 지원 어린이집 항목 — 설치 장소·정원 미기재)', 20),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '크루 및 크루 가족의 경조사 발생 시 경조휴가와 경조사비·화환·용품 제공 (공식 채용 사이트 카카오 생활 크루 혜택 생활 속 지원 경조사 지원 항목 — 경조 종류별 금액·휴가 일수 미기재)', 21),

  -- ── 건강·의료 (health) — 생활 속 지원 · 건강 증진 지원 ──
  (@comp_id, 'insurance', '단체상해보험·가족사랑 지원', 30, 'health',
   'est', '본인, 배우자, 자녀, 본인과 배우자의 부모까지 보장성 보험료와 실손의료비 지원(공식 채용 사이트 카카오 생활 크루 혜택 건강 증진 지원 단체상해보험 항목), 크루가 불의의 사고 또는 질병으로 사망 시 가족에게 보험금 2억원 일시금 지원(같은 사이트 생활 속 지원 가족사랑 지원 항목) — 보험료 지원 한도 미기재 (추정)', FALSE, NULL, 30),
  (@comp_id, 'massage', '톡클리닉 (헬스키퍼)', NULL, 'health',
   'est', NULL, TRUE, '국가공인 안마사 자격을 갖춘 헬스키퍼에게 월 2회 안마·지압·수기치료 (공식 채용 사이트 카카오 생활 크루 혜택 건강 증진 지원 톡클리닉 항목 — 본인 부담 여부 미기재)', 31),
  (@comp_id, 'mental', '톡테라스 (상담·명상)', NULL, 'health',
   'est', NULL, TRUE, '대인관계·업무 이슈·커리어 이슈 등으로 스트레스를 받는 크루를 위한 상담 프로그램과 명상 프로그램 (공식 채용 사이트 카카오 생활 크루 혜택 건강 증진 지원 톡테라스 항목 — 상담 횟수 한도 미기재)', 32),
  (@comp_id, 'clinic', '톡의보감 (사내 양호실)', NULL, 'health',
   'est', NULL, TRUE, '응급상황 대응, 일반의약품, 상처드레싱, 건강상담이 가능한 사내 양호실 (공식 채용 사이트 카카오 생활 크루 혜택 건강 증진 지원 톡의보감 항목 — 운영 시간·상주 인력 미기재)', 33),
  (@comp_id, 'health_check', '종합건강검진·검진 휴가', 100, 'health',
   'est', '매년 1회 종합건강검진 무료 지원과 건강검진 휴가 제공 (공식 채용 사이트 카카오 생활 크루 혜택 건강 증진 지원 종합검진 항목 — 검진 항목·가족 적용 미기재) (추정)', FALSE, NULL, 34),

  -- ── 보상·금전 (compensation) — 생활 속 지원 ──
  (@comp_id, 'holiday_gift', '명절선물 (카카오페이머니)', 60, 'compensation',
   'est', '설과 추석에 각각 30만원씩 카카오페이머니(현금) 지급 (공식 채용 사이트 카카오 생활 크루 혜택 생활 속 지원 명절선물 항목)', FALSE, NULL, 40),

  -- ── 여가·라이프 (leisure) — 생활 속 지원 · 업무 몰입 지원 · 휴식 지원 ──
  (@comp_id, 'leisure_ticket', '이모티콘 플러스·톡클라우드·멜론 이용권', NULL, 'leisure',
   'est', NULL, TRUE, '이모티콘 플러스, 톡클라우드, 멜론 이용권 지급 (공식 채용 사이트 카카오 생활 크루 혜택 생활 속 지원 이모티콘/톡클라우드/멜론 이용권 항목 — 이용권 등급·지급 기간 미기재)', 50),
  (@comp_id, 'library', '전자도서관/크루의 서재', NULL, 'leisure',
   'est', NULL, TRUE, '업무 관련 도서를 전자도서관에서 ebook으로 지원, 매월 주제별 도서 큐레이션과 크루 추천 도서 (공식 채용 사이트 카카오 생활 크루 혜택 업무 몰입 지원 전자도서관/크루의 서재 항목 — 대출 권수 미기재)', 51),
  (@comp_id, 'resort', '호텔/리조트 지원', 50, 'leisure',
   'est', '크루의 재충전을 위해 국내 최상급 호텔/리조트 이용 지원 (공식 채용 사이트 카카오 생활 크루 혜택 휴식 지원 호텔/리조트 지원 항목 — 이용 횟수·할인율 미기재) (추정)', FALSE, NULL, 52),
  (@comp_id, 'club', '동호회 지원', NULL, 'leisure',
   'est', NULL, TRUE, '40개가 넘는 사내 동호회, 활발한 동호회 활동을 위한 매달 지원비 (공식 채용 사이트 카카오 생활 크루 혜택 휴식 지원 동호회 지원 항목 — 월 지원 금액 미기재)', 53),

  -- ── 성장·커리어 (growth) — 업무 몰입 지원 ──
  (@comp_id, 'edu_support', '사내/사외 교육 (MOOC·사외교육·컨퍼런스·북토크)', NULL, 'growth',
   'est', NULL, TRUE, '크루 성장을 위한 각종 MOOC, 사외교육, 해외 컨퍼런스 지원, 외부연사를 모신 주제별 북토크·세미나와 크루가 직접 진행하는 강연 (공식 채용 사이트 카카오 생활 크루 혜택 업무 몰입 지원 사내/사외 교육 항목 — 지원 한도·신청 기준·개최 주기 미기재)', 60),

  -- ── 시간·휴가 (time_off) — 휴식 지원 ──
  (@comp_id, 'long_service_leave', '리프레시 제도 (만 3년마다)', 67, 'time_off',
   'est', '만 3년 근무마다 1개월 유급휴가와 휴가비 200만원 지급 (공식 채용 사이트 카카오 생활 크루 혜택 휴식 지원 리프레시 제도 항목) — 3년에 한 번 받는 휴가비 200만원을 연 67만원으로 환산', FALSE, NULL, 70),
  (@comp_id, 'leave_general', '리커버리 데이', NULL, 'time_off',
   'est', NULL, TRUE, '매월 마지막 주 금요일을 리커버리 데이로 운영, 휴식과 충전·업무리듬 재조정·회고 및 다음 업무 계획 수립에 활용 (공식 채용 사이트 카카오 생활 크루 혜택 휴식 지원 리커버리 데이 항목 — 휴무 여부 미기재)', 71),

  -- ── 근무환경 (work_env) — 휴식 지원 ──
  (@comp_id, 'lounge', '휴게공간 (안마의자·수면)', NULL, 'work_env',
   'est', NULL, TRUE, '업무 중 잠깐의 충전을 위한 휴게공간의 안마의자와 수면 공간 (공식 채용 사이트 카카오 생활 크루 혜택 휴식 지원 휴식공간 항목 — 설치 사업장·이용 시간 미기재)', 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
