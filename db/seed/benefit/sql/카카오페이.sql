-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 카카오페이 복리후생 데이터
-- 출처: AI 파싱 (2026-09-26)
-- URL: https://kakaopay.career.greetinghr.com/ko/benefit
-- badge: est
--
-- 참고:
--   정본은 카카오페이 자사 채용 사이트(www.kakaopay.com 푸터 채용 링크 → 그리팅 ATS 호스팅
--   kakaopay.career.greetinghr.com) 메뉴 PAY-GUIDE 의 복리 후생 페이지 하나다. 4섹션 21항목
--   (근무환경 지원 6 · 생활 속 지원 6 · 휴식 지원 4 · 건강 지원 5). 섹션 이름은 이미지 4장(Benefit_01~04.png,
--   아이콘+제목 482x128)에만 있고 항목 본문은 원본 HTML 의 __NEXT_DATA__ JSON 에 전부 있다 — 헤드리스 렌더 없음.
--   robots: kakaopay.career.greetinghr.com 은 Allow: / (지원서·관리 경로만 Disallow),
--   opening-attachments.greetinghr.com 은 Allow: /. 2026-09-25 대조 때 받은 사본과 2026-09-26 재요청본의
--   항목 블록 48개가 글자까지 같다.
--
--   귀속: 21항목 모두 페이지가 카카오페이 크루 대상이라고 밝힌다. 카카오 본사 careers.kakao.com 과
--   다른 계열사 페이지는 보지 않았고 섞지 않았다. 프렌즈샵 할인·판교 어린이집은 그룹 자산을 쓰지만
--   이 페이지가 카카오페이 크루에게 적용한다고 적어 근거로 삼았다.
--
--   금액: 명시값 3행(카카오페이 포인트 연 360만 · 명절 설·추석 각 30만원 · 안식 휴가비 만 3년마다 200만원 →
--   연 67 환산). 공식에 금액이 없고 구본 추정치가 있던 6행은 금액 정책 (a) 조건을 확인해 추정치를 승계했다
--   (검진 100 · 실비 100 · 치과 30 · 리조트 50 · 통근 120 · 음료·편의점 144). 구본 식대 240 은 공식에 없는
--   수치라 승계하지 않았다.
--
--   분리: 먹거리와 교통비 지원 1항목 → snack_bar(상시 음료) · meal(야근 저녁 식대) · transport(야근 택시비).
--   휴식공간 운영 1항목 → nap_room(수면실·맘스룸) · massage(안마실). 예방접종 지원 → health_check 에 합침.
--   사내 도서관 대출은 도서 구매 항목 안의 문장이라 books 한 행에 둔다.
--
--   구본에서 뺀 행: stock_option · remote_work · event · parking (공식 근거 없음).
--   재코딩: work_tools → car_rental (구본 행 중 공식이 뒷받침하는 것은 주말 업무용 차량 대여뿐).
--
--   SORT 섹션 순서는 페이지에서 그 카테고리가 처음 나온 순서다
--     (flexibility 10 · perks 20 · growth 30 · family 40 · compensation 50 · time_off 60 ·
--      work_env 70 · health 80 · leisure 90).
-- 재수집(2026-09-26): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다 — 대조 보고서 2026-09-25-official-compare
-- 감사(RA-1 2026-09-26) 반영: snack_bar 144 추정치 미승계(카카오 계열 고유값, 전제 가격이 원문에 없음)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — 이 INSERT 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('kakao_pay', '카카오페이',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '핀테크', 'K', 'https://kakaopay.career.greetinghr.com/ko/benefit');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'kakao_pay');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://kakaopay.career.greetinghr.com/ko/benefit'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 유연근무 (flexibility) — 근무환경 지원 ──
  (@comp_id, 'flex_work', '완전 선택적 근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '완전 선택적 근무제. 크루들의 효율적인 시간관리를 위해 1개월 단위 소정근로 시간 내에서 자율적으로 근무 (공식 채용 페이지 복리 후생 근무환경 지원 항목 — 적용 대상 미기재)', 10),

  -- ── 경제적 부가혜택 (perks) — 근무환경 지원 · 생활 속 지원 ──
  (@comp_id, 'snack_bar', '상시 음료·K-MART 편의점', NULL, 'perks',
   'est', NULL, TRUE, '상시 음료 제공(공식 채용 페이지 복리 후생 근무환경 지원 먹거리와 교통비 지원 항목), 즉석라면·냉동식품 등 편의식품을 저렴한 가격에 이용하는 카카오페이만의 편의점 K-MART(같은 페이지 K-MART 항목) — 음료 유무료·할인율 미기재', 20),
  (@comp_id, 'meal', '사내식당 춘식도락·야근 저녁 식대', NULL, 'perks',
   'est', NULL, TRUE, '사내식당 춘식도락의 영양가 있는 식단(공식 채용 페이지 복리 후생 근무환경 지원 춘식도락 항목), 야근 시 저녁 식대 지원(같은 페이지 먹거리와 교통비 지원 항목) — 식대 단가·본인 부담 여부 미기재', 21),
  (@comp_id, 'transport', '야근 택시비', NULL, 'perks',
   'est', NULL, TRUE, '야근 시 택시비 지원 (공식 채용 페이지 복리 후생 근무환경 지원 먹거리와 교통비 지원 항목 — 지원 한도·적용 시각 미기재)', 22),
  (@comp_id, 'commute_subsidy', '통근버스', 120, 'perks',
   'est', '장거리 거주 크루를 위한 서울/경기 지역 셔틀 노선 운영 (공식 채용 페이지 복리 후생 근무환경 지원 통근버스 항목 — 노선 수·본인 부담 여부 미기재) (추정)', FALSE, NULL, 23),
  (@comp_id, 'welfare_point', '카카오페이 포인트', 360, 'perks',
   'est', '크루들의 자기개발, 여가/취미 활동 지원을 위해 연 360만 카카오페이 포인트 지급 (공식 채용 페이지 복리 후생 생활 속 지원 카카오페이 포인트 지급 항목)', FALSE, NULL, 24),
  (@comp_id, 'housing_loan', '대출이자 지원', NULL, 'perks',
   'est', NULL, TRUE, '주택구입 및 임차, 생활안정을 위해 최대 3억의 대출 프로그램을 연계하고 대출자금의 2% 초과 이자 지원 (공식 채용 페이지 복리 후생 생활 속 지원 대출이자 지원 항목 — 연계 금융기관·자격 요건 미기재)', 25),
  (@comp_id, 'discount', '카카오프렌즈 제품 20% 할인', NULL, 'perks',
   'est', NULL, TRUE, '카카오 사내 프렌즈샵 또는 온라인 스토어에서 카카오프렌즈 굿즈 20% 할인 (공식 채용 페이지 복리 후생 생활 속 지원 카카오프렌즈 제품 할인 항목 — 연간 한도 미기재)', 26),
  (@comp_id, 'car_rental', '주말 업무용 차량 대여', NULL, 'perks',
   'est', NULL, TRUE, '업무용 차량 카니발을 크루의 가족이나 친구들과 함께 이용하는 크루 카쉐어링 운영 (공식 채용 페이지 복리 후생 생활 속 지원 주말 업무용 차량 대여 항목 — 이용 요금·신청 방법 미기재)', 27),

  -- ── 성장·교육 (growth) — 근무환경 지원 ──
  (@comp_id, 'books', '업무용 도서 구매 무제한 지원', NULL, 'growth',
   'est', NULL, TRUE, '업무용 도서 구매 무제한 지원과 사내 도서관 대출 (공식 채용 페이지 복리 후생 근무환경 지원 업무용 도서 구매 무제한 지원 항목)', 30),

  -- ── 가족·돌봄 (family) — 생활 속 지원 ──
  (@comp_id, 'childcare', '사내 어린이집', NULL, 'family',
   'est', NULL, TRUE, '워킹맘, 워킹대디를 위한 판교 지역 내 3곳의 사내 어린이집 지원 (공식 채용 페이지 복리 후생 생활 속 지원 어린이집 항목 — 입소 기준·정원 미기재)', 40),

  -- ── 보상·금전 (compensation) — 생활 속 지원 ──
  (@comp_id, 'holiday_gift', '명절선물 (카카오페이머니)', 60, 'compensation',
   'est', '설과 추석에 각 30만원씩 카카오페이머니 지급 (공식 채용 페이지 복리 후생 생활 속 지원 명절선물 항목)', FALSE, NULL, 50),

  -- ── 휴가·휴직 (time_off) — 휴식 지원 ──
  (@comp_id, 'long_service_leave', '안식 휴가 (만 3년마다)', 67, 'time_off',
   'est', '만 3년 근무마다 1개월 유급휴가와 휴가비 200만원 지급 (공식 채용 페이지 복리 후생 휴식 지원 안식 휴가 항목) — 3년에 한 번 받는 휴가비 200만원을 연 67만원으로 환산', FALSE, NULL, 60),
  (@comp_id, 'leave_general', '리프레시 데이', NULL, 'time_off',
   'est', NULL, TRUE, '매월 마지막 주 금요일을 리프레시데이로 운영 (공식 채용 페이지 복리 후생 휴식 지원 리프레시 데이 항목 — 휴무·조기퇴근 여부 미기재)', 61),

  -- ── 근무환경 (work_env) — 휴식 지원 ──
  (@comp_id, 'nap_room', '수면실·맘스룸', NULL, 'work_env',
   'est', NULL, TRUE, '휴식을 위한 수면실, 맘스룸 운영 (공식 채용 페이지 복리 후생 휴식 지원 휴식공간 운영 항목 — 설치 사업장·이용 시간 미기재)', 70),

  -- ── 건강·의료 (health) — 휴식 지원 · 건강 지원 ──
  (@comp_id, 'massage', '안마실 (전문 안마사)', NULL, 'health',
   'est', NULL, TRUE, '전문 안마사에게 받을 수 있는 안마실 운영 (공식 채용 페이지 복리 후생 휴식 지원 휴식공간 운영 항목 — 이용 횟수·본인 부담 여부 미기재)', 80),
  (@comp_id, 'medical', '실비 보험 (본인·배우자·부모님·자녀)', 100, 'health',
   'est', '크루 본인, 배우자, 부모님, 자녀까지 실비보험 지원 (공식 채용 페이지 복리 후생 건강 지원 실비 보험 항목 — 보장 한도 미기재) (추정)', FALSE, NULL, 81),
  (@comp_id, 'health_check', '종합 건강검진·예방접종', 100, 'health',
   'est', '매년 1회 종합 건강검진 무료 지원(공식 채용 페이지 복리 후생 건강 지원 종합 건강검진 항목), 환절기 예방접종 지원(같은 페이지 예방접종 지원 항목) — 검진 비용·접종 종류 미기재 (추정)', FALSE, NULL, 82),
  (@comp_id, 'mental', '심리 상담', NULL, 'health',
   'est', NULL, TRUE, '지친 마음에 위로가 필요한 크루에게 전문 심리상담 지원 (공식 채용 페이지 복리 후생 건강 지원 심리 상담 항목 — 지원 횟수 미기재)', 83),
  (@comp_id, 'insurance', '치과 보험 (본인·배우자·자녀)', 30, 'health',
   'est', '크루 본인, 배우자, 자녀에게 치과보험 지원 (공식 채용 페이지 복리 후생 건강 지원 치과 보험 항목 — 보장 범위 미기재) (추정)', FALSE, NULL, 84),

  -- ── 여가·라이프 (leisure) — 휴식 지원 ──
  (@comp_id, 'resort', '휴양시설 리조트 지원', 50, 'leisure',
   'est', '회사가 보유한 국내 최상급 호텔/리조트를 연 5회 기업 할인가로 제공 (공식 채용 페이지 복리 후생 휴식 지원 휴양시설 리조트 지원 항목 — 할인율 미기재) (추정)', FALSE, NULL, 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
