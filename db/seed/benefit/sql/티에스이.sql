-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 티에스이 복리후생 데이터 (신규 회사)
-- 출처: AI 파싱 (2026-09-19)
-- URL: https://www.tse21.com/kor/careers/companybenefits.html
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고: 정본은 회사 자기 도메인 www.tse21.com 의 「채용안내 > 복리후생」 페이지 한 곳이다.
--       가비아 Apache 정적 SSR 이라 헤드리스가 필요 없고, 항목 13개가 최초 HTML 의
--       .swiper-slide > .card-bgeffect 안 h3(항목명) + p(설명)로 그대로 들어 있다.
--       robots.txt 는 302 로 가비아 오류 문서를 주는 부재 상태라 전 경로 허용이다.
--       보조 출처는 공식 홈 「채용정보 & FAQ」 버튼이 여는 회사 전용 ATS
--       tse21.ninehire.site/culture 이며, 라벨 보정과 적용 범위 단서 2건에만 썼다.
--       ATS 는 companyName 이 티에스이 단수라 법인 귀속이 확정된다 — 그룹 통합
--       채용사이트가 아니므로 「그룹 통합 채용 기준」 각주는 붙이지 않았다.
--       회사 사이트에 계열사 공통 복지 페이지도, 계열사별 상이 면책 문구도 없다.
--       ⚠ ATS 홈 /tsecareers 에는 나인하이어 샘플 복지 8개가 7번 반복 서버렌더돼 있다
--         (강남역 20분거리 · 크루 · 3년근무마다 1개월 유급휴가와 휴가비 200만원 ·
--          셔틀 노션). 티에스이 사업장은 전부 충남 천안과 대구사무소다.
--         invisible 플래그도 섹션 제목(복지 및 혜택 - 1)도 진짜 블록과 같아 구조로는
--         못 거른다. 그래서 __NEXT_DATA__ 의 homepage.pages 에서 pageUrl 이 culture
--         인 페이지 객체만 떼어내 읽었고, 강남역·크루·노션·200만원 네 문자열을
--         오염 카나리아로 세어 culture 객체 0건 / tsecareers 객체 7·14·7·7건을 확인했다.
--         이 8개는 한 건도 수록하지 않았다.
--       ⚠ 정본 페이지 하단에는 주간 8호차·야간 2호차 통근버스 시간표가 약 260행
--         같은 텍스트로 박혀 있다. 항목 파싱을 .swiper-slide 카드 13장으로 한정했고
--         정류장 이름은 한 건도 항목으로 뽑지 않았다.
--       ⚠ 회사가 붙인 카테고리 라벨이 내용과 어긋난다 — 건강검진이 Culture & Leisure,
--         동호회가 Health / Etc 에 있다. 9카테고리는 회사 라벨이 아니라 항목 내용으로
--         정했다(건강상담·건강검진 → health, 동호회 → leisure).
--       원문 13항목 → 4대 보험 정책 1건 제외(법정 기준선) → 12항목.
--       그중 「월별 건강상담 및 정기 건강검진」이 두 제도를 「및」으로 병기한 복합 라벨이라
--       2행으로 분리(clinic + health_check) → **13행**. 신규 코드 0개.
--       금액: 페이지 전체에 원 단위 통화 표현이 0건이다(만원 0회, 숫자+원 0회).
--       정량 표현은 4-5인실 · 무이자 · 매월 마지막 금요일 · 1년에 한 번 · 무료 3식뿐이고
--       전부 조건·주기라 금액이 아니다 → 13행 전부 BENEFIT_AMT NULL · QUAL_YN TRUE.
--       신규 회사라 승계할 앵커도 없어 타사 금액을 끌어오지 않았다.
--       법정 제도 미수록: 「4대 보험 정책 — 직원들을 위한 4대 사회보험을 지원합니다」는
--       행으로 만들지 않았고 다른 행 서술에도 넣지 않았다. 퇴직연금·법정 연차·법정
--       육아/출산 관련 문구는 정본 페이지에 아예 없다.
--       제외: 인사제도 페이지(/kor/careers/personnelpolicies.html)의 승진 체계·연봉제·
--       인센티브 3건은 임금·평가·승진 체계라 복지가 아니다(넷마블 개별연봉제 선례).
--       적용 범위 단서 2건은 서술에 그대로 남겼다 — 사내카페는 ATS 가 「사업장별 상이」로
--       적고, 통근버스는 천안 시내 노선으로 한정된다. 전 사업장 일괄로 단정하지 않았다.
--       재수집: 정본 응답에 Last-Modified·ETag 가 없다. 카드 13장 텍스트 해시로 감지할 것.
--       ⚠ 검증·감사 판정 반영(2026-09-19): 13 → 12행(병합 2 · 추가 1). SORT 51 가정의 날은 조기퇴근 서술이
--       없어 SORT 71 company_event 에 병합 · SORT 60 건강상담은 시설명이 없어 SORT 61 health_check 에 병합 ·
--       SORT 80 incentive 추가(인사제도 페이지) · SORT 23 에서 페이지 표기 방식 서술 제거.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('tse', '티에스이',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '반도체장비', 'T', 'https://www.tse21.com/kor/careers/companybenefits.html');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'tse');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.tse21.com/kor/careers/companybenefits.html'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무환경 (work_env) ──
  (@comp_id, 'dormitory', '기숙사 제공 (천안 시내 아파트)', NULL, 'work_env',
   'est', NULL, TRUE, '기숙사 제공 (천안 시내 아파트) — 천안 이외의 지역에 거주하는 직원을 위한 4-5인실 기숙사 운영 (공식 채용안내 복리후생 페이지 항목 — 입주 자격·본인 부담금·운영 동수 미기재)', 10),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'housing_loan', '주택 담보 대출 (무이자)', NULL, 'perks',
   'est', NULL, TRUE, '주택 담보 대출 (무이자) — 생애 최초 주택 구매자를 위한 무이자 주택 담보 대출 지원 (공식 채용안내 복리후생 페이지 항목 — 대출 한도·상환 기간·근속 요건 미기재)', 20),
  (@comp_id, 'commute_subsidy', '천안시 통근 버스 서비스', NULL, 'perks',
   'est', NULL, TRUE, '천안시 통근 버스 서비스 — 천안 시내로 운영되는 통근버스 (공식 채용안내 복리후생 페이지 항목 · 노선은 천안 시내 한정 — 타 사업장 노선·이용료 미기재)', 21),
  (@comp_id, 'meal', '카페테리아', NULL, 'perks',
   'est', NULL, TRUE, '카페테리아 — 무료 아침, 점심, 저녁 제공 (공식 채용안내 복리후생 페이지 항목 — 끼니별 단가·운영 사업장 미기재)', 22),
  (@comp_id, 'snack_bar', '사내카페 (사업장별 상이)', NULL, 'perks',
   'est', NULL, TRUE, '사내카페 운영 — 직원들의 편안한 휴식을 위한 사내카페 (공식 채용안내 복리후생 페이지 항목 — 사업장별 운영 여부가 다르고 운영 사업장·무료 여부 미기재)', 23),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사 지원 — 축하와 조의를 표하고 슬픔과 기쁨을 함께 나누기 위한 사내 상조회 운영 (공식 채용안내 복리후생 페이지의 「금전적 지원과 축하 및 조의를 위한 휴가」 항목, 회사 채용사이트 표기는 「경조사 지원」 — 경조금 금액·경조휴가 일수 미기재)', 30),

  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'holiday_gift', '명절 선물', NULL, 'compensation',
   'est', NULL, TRUE, '명절 선물 — 매년 설날과 추석에 전 직원에게 명절 선물 제공 (공식 채용안내 복리후생 페이지 항목 — 선물 품목·금액 미기재)', 40),

  -- ── 근무 유연성 (flexibility) ──
  (@comp_id, 'flex_work', '유연근무제 시행', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제 시행 — 직원들의 Work&Life 를 위한 유연근무제 시행 (공식 채용안내 복리후생 페이지 항목, 회사 채용사이트 설명 병기 — 적용 유형·코어타임·대상 직군 미기재)', 50),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '월별 건강상담 및 정기 건강검진 (간호사 상주)', NULL, 'health',
   'est', NULL, TRUE, '매월 건강상담·간호사 상주·연 1회 정기 건강검진 (공식 채용안내 복리후생 페이지 항목 — 상담 장소·이용 절차·검진 항목·검진 기관·가족 포함 여부·비용 부담 미기재)', 61),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'club', '동호회 활동 지원', NULL, 'leisure',
   'est', NULL, TRUE, '동호회 활동 지원 — 직원들의 건강한 문화생활을 위한 다양한 사내 동호회 활동 비용 지원 (공식 채용안내 복리후생 페이지 항목 — 지원 한도·동호회 수·가입 조건 미기재)', 70),
  (@comp_id, 'company_event', '가정의 날 과일 선물·종무식', NULL, 'leisure',
   'est', NULL, TRUE, '매월 마지막 금요일을 가정의 날로 지정해 전 직원에게 제철 과일 선물, 한 해를 돌아보고 새해를 맞이하는 종무식 개최 (공식 채용안내 복리후생 페이지 항목 — 조기 퇴근 여부·개최 시기 미기재)', 71),

  -- ── 보상·금전 (compensation) — 인사제도 페이지 ──
  (@comp_id, 'incentive', '성과 인센티브', NULL, 'compensation',
   'est', NULL, TRUE, '기업과 부서의 성과에 따른 인센티브 제공 (공식 채용안내 인사제도 페이지 항목 — 지급 기준·주기·산식 미기재)', 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
