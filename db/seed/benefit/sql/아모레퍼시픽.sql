-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 아모레퍼시픽 복리후생 데이터
-- 출처: AI 파싱 (2026-10-02)
-- URL: https://www.apgroup.com/int/ko/careers/life-and-culture/life-and-culture.html
-- badge: est
--
-- 참고:
--   정본은 ㈜아모레퍼시픽 자기 도메인 www.apgroup.com(법적 고지 = ㈜아모레퍼시픽의 홈페이지 · 2025 사업보고서 홈페이지 기재)의
--   채용 → 라이프 & 컬처 페이지다. 서버 렌더 HTML 의 BENEFITS AT AMOREPACIFIC 절에 복지 16항목이 제목+설명+사업장 태그로 있다.
--   페이지 주어는 아모레퍼시픽(그룹 아님)이고 계열사별 단서가 없다 — 이 법인 원문으로 썼다(각주 없음).
--   보조: 같은 도메인 지속가능성 보고서 메뉴의 2025 아모레퍼시픽홀딩스 지속가능성 보고서(지주 발행 · 보고 대상에 아모레퍼시픽 포함)
--     63쪽 모성보호 지원 · 임직원 건강·복지 증진 프로그램 표. 주어가 아모레퍼시픽 그룹이라 그 문장에 기댄 서술에는
--     아모레퍼시픽 그룹 공통 각주를 달았다. 보고서에만 있는 행은 nap_room 1행.
--   형제 법인(이니스프리 · 에뛰드 · 에스쁘아 · 오설록 · 코스비전 등) · 지주 아모레퍼시픽홀딩스 자신의 복지 문구는 쓰지 않았다.
--   채용 공고(careers.apgroup.com, 그룹 공용 ATS) 2건에는 복리후생 블록이 없다 — 공고 근거 0행.
--   OpenDART 2025 사업보고서(접수 20260318000785): 유연근무제도 사용현황(선택근무제)을 flex_work 에,
--     직원 보수 산정기준의 급여규정 부가급여(조직성과급 · 전 직원 공통 지급률 Profit Sharing)를 incentive ·
--     profit_sharing 에 썼다. 스톡그랜트 공시는 지급할 수 있다는 재량 규정이라 제외.
--   금액: 구본 추정 승계 2(welfare_point 200 · resort 50 — 둘 다 틀 값, NOTE 끝에 (추정)). holiday_gift 30 · child_edu 100 ·
--     discount 50 은 회사 고유값인데 원문에 전제가 없어 승계하지 않았다.
--   제외: 단축 근무 · 태아검진 외출 · 육아기 단축 · 가족돌봄 등 법정 제도 · 직무 교육 · 학습 플랫폼(회사 주도 교육 과정) ·
--     스톡그랜트 · RSU · 구본 생일 반일 휴가 · 가산 휴가 · 루프가든 · 미술관 · 평생 학습(현행 원문 없음).
--   SORT 섹션 순서 = 라이프 & 컬처 목록에서 카테고리가 처음 나온 순서, 보고서에만 있는 카테고리는 끝
--     (time_off 10 · leisure 20 · family 30 · perks 40 · work_env 50 · compensation 60 · health 70 · flexibility 80).
--     사업보고서 · 보고서에서 보탠 행은 해당 카테고리 섹션 끝(nap_room 52 · profit_sharing 61 · incentive 62).
-- 재수집(2026-10-02): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-02, RV-3-7): flex_work 근거에 2025 사업보고서 선택근무제를 보탬 · 사업보고서 직원 보수 산정기준의 Profit Sharing · 조직성과급과 보고서 수유 시설을 행으로 보탬 — 최종 24행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('amorepacific', '아모레퍼시픽',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '화장품', 'A', 'https://www.apgroup.com/int/ko/careers/life-and-culture/life-and-culture.html');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'amorepacific');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.apgroup.com/int/ko/careers/life-and-culture/life-and-culture.html'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 시간·휴가 (time_off) — 라이프 & 컬처 휴가 제도 ──
  (@comp_id, 'refresh_leave', 'Refresh · Happy Vacation', NULL, 'time_off',
   'est', NULL, TRUE, '기본 휴가 외에도 Refresh, Happy Vacation 사용 가능, 건강한 여가 문화와 휴식으로 재충전할 수 있도록 운영하는 휴가 제도 (공식 채용 사이트 라이프 & 컬처 휴가 제도 항목) — 휴가 일수·부여 조건·유급 여부 미기재', 10),

  -- ── 여가·라이프 (leisure) — 라이프 & 컬처 휴가 제도 ──
  (@comp_id, 'resort', '임직원 전용 휴양지·콘도', 50, 'leisure',
   'est', '임직원 전용 휴양지와 콘도 서비스 이용 (공식 채용 사이트 라이프 & 컬처 휴가 제도 항목) — 이용 일수·지원 금액 미기재 (추정)', FALSE, NULL, 20),

  -- ── 가족·돌봄 (family) — 라이프 & 컬처 예비맘 배려 · 사내 어린이집 · 자녀 학자금 / 2025 보고서 일과 생활의 균형 추구 ──
  (@comp_id, 'parenting', '예비맘 배려·출산 육아 지원', NULL, 'family',
   'est', NULL, TRUE, '예비맘 배려 물품 지원 (공식 채용 사이트 라이프 & 컬처 예비맘 배려 프로그램 항목), 임산부 전용 사무실 의자 등 맞춤형 사무 환경 물품과 임신 축하 선물, 임신부 주 1회 원격근무, 출산 전후 휴가 중 법적 무급 기간의 월 급여 수준 보장, 출산휴가에 이어 사용하는 90일의 육아휴직에 통상임금의 60% 지원(임신 중 사용 시에도 최대 90일 동일), 출산 축하 경조금 (2025 아모레퍼시픽홀딩스 지속가능성 보고서 일과 생활의 균형 추구, 아모레퍼시픽 그룹 공통) — 경조금 금액 미기재', 30),
  (@comp_id, 'childcare', '사내 어린이집', NULL, 'family',
   'est', NULL, TRUE, '최고의 시설과 교육 프로그램을 갖춘 사내 어린이집 운영(서울 · 용인 · 오산 사업장) (공식 채용 사이트 라이프 & 컬처 사내 어린이집 항목) — 정원·이용 조건 미기재', 31),
  (@comp_id, 'child_edu', '자녀 학자금·보조금', NULL, 'family',
   'est', NULL, TRUE, '구성원의 자녀 교육을 지원하기 위한 다양한 자녀 학자금/보조금 (공식 채용 사이트 라이프 & 컬처 자녀 학자금 지원 항목) — 지원 학령·한도·자녀 수 미기재', 32),

  -- ── 경제적 부가혜택 (perks) — 라이프 & 컬처 카온 · 자판기/사내 매점 · 선택형 복지포인트 · 주택자금 · 기숙사/통근버스 · 식당 ──
  (@comp_id, 'car_wash', '스팀 세차 서비스 카온', NULL, 'perks',
   'est', NULL, TRUE, '사내 주차장과 세차장을 연계한 스팀 세차 서비스 카온 매월 2회 무료 제공 — 장애를 가진 직원들의 사회경제적 자립을 돕는 서비스, 오산 사업장 (공식 채용 사이트 라이프 & 컬처 카온 항목)', 40),
  (@comp_id, 'snack_bar', '자판기·사내 매점', NULL, 'perks',
   'est', NULL, TRUE, '24시간 운영되는 자판기와 사내 매점 — 다양한 음료와 간식, 건강을 위한 제품을 편리하고 저렴하게 이용 (공식 채용 사이트 라이프 & 컬처 자판기/사내 매점 항목)', 41),
  (@comp_id, 'welfare_point', '선택형 복지포인트', 200, 'perks',
   'est', '자기계발 지원과 다양한 복지 혜택 제공을 위한 복지 포인트 지급 (공식 채용 사이트 라이프 & 컬처 선택형 복지포인트 항목) — 지급 금액 미기재 (추정)', FALSE, NULL, 42),
  (@comp_id, 'discount', '자사 제품 특별가 구매', NULL, 'perks',
   'est', NULL, TRUE, '자사 제품을 특별한 가격에 구매 (공식 채용 사이트 라이프 & 컬처 선택형 복지포인트 항목) — 할인율·구매 한도 미기재', 43),
  (@comp_id, 'birthday_gift', '생일 선물', NULL, 'perks',
   'est', NULL, TRUE, '생일 선물 제공 (공식 채용 사이트 라이프 & 컬처 선택형 복지포인트 항목) — 선물 내용·금액 미기재', 44),
  (@comp_id, 'housing_loan', '주택자금 대출 지원 (매매/전세)', NULL, 'perks',
   'est', NULL, TRUE, '주거 안정을 위한 주택자금 지원 혜택(매매/전세) (공식 채용 사이트 라이프 & 컬처 주택자금 대출지원 항목) — 대출 한도·이율·자격 미기재', 45),
  (@comp_id, 'commute_subsidy', '통근버스', NULL, 'perks',
   'est', NULL, TRUE, '편리한 출퇴근 환경을 위한 통근버스 운영(용인 · 오산 · 대전 사업장) (공식 채용 사이트 라이프 & 컬처 기숙사/통근버스 항목) — 노선·운행 횟수 미기재', 46),
  (@comp_id, 'meal', '사내 식당 (조식·중식·석식)', NULL, 'perks',
   'est', NULL, TRUE, '조식/중식/석식 매일 제공(비건, 저염식, 테이크아웃 등 다양한 메뉴를 저렴한 가격에 이용) (공식 채용 사이트 라이프 & 컬처 식당/카페테리아 항목) — 회사 부담액·식대 미기재', 47),

  -- ── 근무환경 (work_env) — 라이프 & 컬처 휴게시설 · 기숙사/통근버스 / 2025 보고서 수유 시설 ──
  (@comp_id, 'lounge', '휴게시설', NULL, 'work_env',
   'est', NULL, TRUE, '편안하고 아늑한 휴게시설 — 여유롭게 휴식을 취하고 스트레스를 해소할 수 있는 쉼의 공간 (공식 채용 사이트 라이프 & 컬처 휴게시설 항목)', 50),
  (@comp_id, 'dormitory', '기숙사', NULL, 'work_env',
   'est', NULL, TRUE, '편리한 출퇴근 환경을 위한 기숙사 운영(용인 · 오산 · 대전 사업장) (공식 채용 사이트 라이프 & 컬처 기숙사/통근버스 항목) — 입주 자격·비용 미기재', 51),
  (@comp_id, 'nap_room', '여성 휴게실 내 수유 시설', NULL, 'work_env',
   'est', NULL, TRUE, '각 사업장의 여성 휴게실 내 수유 시설 운영 (2025 아모레퍼시픽홀딩스 지속가능성 보고서 임직원 건강·복지 증진 프로그램, 아모레퍼시픽 그룹 공통) — 이용 시간·설비 미기재', 52),

  -- ── 보상·금전 (compensation) — 라이프 & 컬처 선택형 복지포인트 / 2025 사업보고서 직원 보수 산정기준 ──
  (@comp_id, 'holiday_gift', 'Happy Gift (연 3회)', NULL, 'compensation',
   'est', NULL, TRUE, '매년 3회(설날/추석/근로자의 날) Happy Gift 제공 (공식 채용 사이트 라이프 & 컬처 선택형 복지포인트 항목) — 선물 내용·금액 미기재', 60),
  (@comp_id, 'profit_sharing', 'Profit Sharing', NULL, 'compensation',
   'est', NULL, TRUE, '전기 사업연도 영업이익 대비 당기 사업연도 영업이익 증가분을 전 직원 공통 지급률로 배분해 지급 (2025 사업보고서 직원 보수 산정기준, 급여규정 부가급여) — 지급률·지급 시기 미기재', 61),
  (@comp_id, 'incentive', '조직성과급', NULL, 'compensation',
   'est', NULL, TRUE, '급여규정에 따른 부가급여로, 조직 매출액·영업이익 재무성과와 전략성과를 종합한 조직 성과 리뷰 결과에 따라 지급 (2025 사업보고서 직원 보수 산정기준) — 전 직원 지급률 미기재', 62),

  -- ── 건강·의료 (health) — 라이프 & 컬처 해피라이프 컨설팅 · 건강 케어 · 마사지 테라피 · 헬스짐 · 스포츠 / 2025 보고서 건강·복지 증진 프로그램 ──
  (@comp_id, 'mental', '해피라이프 컨설팅', NULL, 'health',
   'est', NULL, TRUE, '구성원의 스트레스와 고민을 케어하는 전문 상담 컨설팅 프로그램 (공식 채용 사이트 라이프 & 컬처 해피라이프 컨설팅 항목), 전화·모바일·PC로 신청해 대면·전화·화상 중 원하는 방식으로 심리 상담 (2025 아모레퍼시픽홀딩스 지속가능성 보고서, 아모레퍼시픽 그룹 공통) — 이용 횟수 미기재', 70),
  (@comp_id, 'clinic', '사내 클리닉·건강 관리실', NULL, 'health',
   'est', NULL, TRUE, '사내 클리닉, 상담, 건강 관리실 운영 — 건강 검진 사후 관리, 영양 상태 등에 따른 의료 상담, 헬스케어 챌린지 프로그램 (공식 채용 사이트 라이프 & 컬처 사내 임직원 건강 케어 항목), AP 클리닉 — 세브란스병원 산하 법인과 협력해 가정의학과 전문의 상주, 전문의약품 처방·수액 치료·예방 접종·물리 치료 (2025 아모레퍼시픽홀딩스 지속가능성 보고서, 아모레퍼시픽 그룹 공통)', 71),
  (@comp_id, 'massage', '마사지 테라피 라온', NULL, 'health',
   'est', NULL, TRUE, '국가 공인 안마사 자격증을 소지한 시각 장애인 안마사의 전문 수기 치료, 휴게 공간 안마의자 상시 이용 (공식 채용 사이트 라이프 & 컬처 임직원 전용 마사지 테라피 항목), 마사지 시설 이름 라온 (2025 아모레퍼시픽홀딩스 지속가능성 보고서, 아모레퍼시픽 그룹 공통)', 72),
  (@comp_id, 'fitness', '사내 헬스짐·체육시설', NULL, 'health',
   'est', NULL, TRUE, '요가, PT, 필라테스, 발레 등 운동 프로그램을 갖춘 피트니스 센터 (공식 채용 사이트 라이프 & 컬처 사내 헬스짐 항목), 테니스장 · 풋살장 · 실내 체육시설 — 오산 사업장 (같은 페이지 스포츠/체육시설 항목), AP 피트니스 — 호텔신라 자회사 SHP 코퍼레이션과 협력, 분기별 최대 800명 이용 (2025 아모레퍼시픽홀딩스 지속가능성 보고서, 아모레퍼시픽 그룹 공통)', 73),

  -- ── 근무 유연성 (flexibility) — 2025 사업보고서 유연근무제도 사용현황 / 2025 보고서 임직원 건강·복지 증진 프로그램 ──
  (@comp_id, 'flex_work', '자율 근무제도', NULL, 'flexibility',
   'est', NULL, TRUE, '선택근무제 활용 (2025 사업보고서 유연근무제도 사용현황), 총 근로시간 한도 내에서 자율적으로 근로 시간을 배분하는 제도 (2025 아모레퍼시픽홀딩스 지속가능성 보고서 임직원 건강·복지 증진 프로그램, 아모레퍼시픽 그룹 공통) — 코어타임·적용 직군 미기재', 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
