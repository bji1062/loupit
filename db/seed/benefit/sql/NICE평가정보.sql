-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- NICE평가정보 복리후생 데이터 (신규 회사 — 웨이브 8)
-- 출처: AI 파싱 (2026-10-15)
-- URL: https://www.niceinfo.co.kr/person/work_life.nice
-- badge: est
--
-- 참고:
--   정본은 상장 법인 NICE평가정보(주)의 자기 도메인 www.niceinfo.co.kr 인재채용 > 일과 생활 페이지다.
--   SSR 이라 원본 HTML 에 8블록 22항목 텍스트가 다 있다. 헤드리스 렌더 · 이미지 판독 불필요. robots.txt 404(규칙 없음).
--   보조 출처: 같은 도메인 사람과 환경 > 지속가능경영 목록의 2026 NICE평가정보 지속가능경영보고서
--   (발간 2026년 6월 · 보고 기간 2025-01-01~2025-12-31 · 보고 범위 국내 본사 및 사업장 · 법인 단독 발행)
--   16쪽 NICE평가정보 복리후생 12항목 표와 인재육성 표 · 19쪽 ESG 경영체계 · 24쪽 안전보건 활동,
--   같은 도메인 다양성 존중 · 안전보건 페이지, OpenDART 2026 반기보고서(접수 20260813000967)
--   유연근무제도 사용 현황 표와 재무제표 주석 장기미지급비용 문장. 직원 770명(2025 사업보고서 직원 현황).
--   귀속: 정본과 보고서 모두 NICE평가정보가 주어인 법인 자료라 각주 없음.
--   NICE그룹 채용 사이트 지원제도 페이지는 계열사별 상이 단서가 있어 행 근거로 쓰지 않았다(근거표 참고).
--   금액: 원문에 원 단위 숫자 0건 — 전 행 BENEFIT_AMT NULL.
--   제외: 법정(육아휴직 · 육아기 근로시간단축 · 법정 건강검진 · 채용 신체검사 · 법정 의무교육) ·
--     업무 교육(신입 입문 연수 · 보직자 연수 · 직급별 리더십 연수 · 핵심분야 전문연수 · 실무 능력 교육 프로그램) ·
--     임원 보수 칸(복지카드 · 명절선물대 · 학자금 · 건강검진비) · 주주 표 우리사주조합 한 칸 ·
--     선택근무제(반기 사용자 0명) · 그룹 채용 사이트에만 있는 항목(복지포인트 · 웰컴키트 · 가족배려 등).
--   공고 근거 0행 / 전체 27행.
--   SORT 섹션 순서 = 정본 페이지 등장 순(time_off 10 · leisure 20 · flexibility 30 · family 40 ·
--     perks 50 · compensation 60 · growth 70 · health 80 · work_env 90).
-- 검증 · 감사 판정 반영(2026-10-15): 체력단련 휴가 서술에 연차와 별도로 복원 · 원격근무제 이름을 조건부로 · 외부기관연수 conference 삭제(업무 교육 · 고도의 전문가 양성 칸) — 최종 26행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('nice_info', 'NICE평가정보',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '신용정보', 'N', 'https://www.niceinfo.co.kr/person/work_life.nice');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'nice_info');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.niceinfo.co.kr/person/work_life.nice'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 휴가 (time_off) — 정본 · 보고서 · 공시 ──
  (@comp_id, 'leave_general', '결재 없는 휴가·1시간 단위 휴가·거주이전휴가', NULL, 'time_off',
   'est', NULL, TRUE, '휴가 신청에 결재자 없이 스스로 일정을 계획하는 결재없는 휴가, 체력단련 휴가를 1시간 단위로 쓰는 시간단위 휴가, 이사를 위한 연 1회 거주이전휴가 (공식 채용 페이지 일과 생활 결재없는 휴가·시간단위 휴가·거주이전휴가 항목) — 거주이전휴가 일수·유급 여부 미기재', 10),
  (@comp_id, 'refresh_leave', '체력단련 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '임직원의 건강과 휴식을 위해 연차와 별도로 제공하는 체력 단련 휴가 (공식 채용 페이지 일과 생활 체력단련 휴가 항목) — 휴가 일수·부여 조건 미기재', 11),
  (@comp_id, 'long_service_leave', '10년 단위 안식휴가', NULL, 'time_off',
   'est', NULL, TRUE, '10년 단위 안식휴가 (2026 지속가능경영보고서 16쪽 NICE평가정보 복리후생 항목), 장기근속휴가 및 장기근속보상 (2026 반기보고서 재무제표 주석 장기미지급비용 항목) — 휴가 일수·포상 금액 미기재', 12),

  -- ── 여가 (leisure) — 정본 · 보고서 · 다양성 존중 페이지 ──
  (@comp_id, 'resort', '휴양시설', NULL, 'leisure',
   'est', NULL, TRUE, '국내 대형 리조트 제휴 할인가 이용 (공식 채용 페이지 일과 생활 휴양시설 항목), 휴양콘도시설 지원 (2026 지속가능경영보고서 16쪽 NICE평가정보 복리후생 항목) — 이용 횟수·지원 금액 미기재', 20),
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '농구, 축구, 테니스, 수영 등 사내 동호회와 분기마다 회사 지원금 (공식 채용 페이지 일과 생활 사내 동호회 항목), 동호회 분기별 운영비 지원·연간 행사 지원, 축구·농구·탁구·골프·수영·테니스·게임 동호회 운영 (공식 홈페이지 다양성 존중 페이지 동호회 활동 항목) — 지원 금액 미기재', 21),

  -- ── 근무 유연성 (flexibility) — 정본 · 보고서 · 공시 ──
  (@comp_id, 'flex_work', '시차출퇴근제도·중식시차제도', NULL, 'flexibility',
   'est', NULL, TRUE, '아침 8시부터 10시까지 출근 시간을 30분 단위로 고르는 시차출퇴근제도, 오전 11시 30분부터 오후 1시 30분 사이 한 시간을 골라 식사하는 중식시차제도 (공식 채용 페이지 일과 생활 항목), 시차출퇴근제 시행 (2026 지속가능경영보고서 16쪽 NICE평가정보 복리후생 항목), 시차출퇴근제 사용자 2026 상반기 384명 (2026 반기보고서 유연근무제도 사용 현황 항목) — 적용 제외 직무 미기재', 30),
  (@comp_id, 'family_day', '동절기 단축근무', NULL, 'flexibility',
   'est', NULL, TRUE, '11월부터 2월까지 한 시간씩 일찍 퇴근하는 동절기 단축근무 (공식 채용 페이지 일과 생활 동절기 단축근무 항목) — 적용 대상 직무 미기재', 31),
  (@comp_id, 'pc_off', 'PC-OFF제도', NULL, 'flexibility',
   'est', NULL, TRUE, '퇴근 시간이 되면 PC가 자동으로 종료되는 PC-OFF제도 (공식 채용 페이지 일과 생활 PC-OFF제도 항목), PC off 제도 시행 (2026 지속가능경영보고서 16쪽 NICE평가정보 복리후생 항목)', 32),
  (@comp_id, 'remote_work', '원격근무제 (조건부)', NULL, 'flexibility',
   'est', NULL, TRUE, '원격근무제(재택근무 포함) 사용자 2026 상반기 15명 (2026 반기보고서 유연근무제도 사용 현황 항목), 코로나/독감 대응 재택근무 등 시행 (2026 지속가능경영보고서 24쪽 안전보건 활동 항목) — 대상 직무·사용 조건 미기재', 33),
  (@comp_id, 'satellite_office', '거점오피스', NULL, 'flexibility',
   'est', NULL, TRUE, '복리후생 증대 활동으로 거점오피스 도입 (2026 지속가능경영보고서 19쪽 ESG 경영체계 사회 이슈 대응 항목) — 위치·이용 대상 미기재', 34),

  -- ── 가족 (family) — 정본 · 보고서 ──
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '유치원부터 대학교까지 자녀 연령에 따른 자녀 학자금 지원 제도 (공식 채용 페이지 일과 생활 학자금 지원 항목), 자녀학자금 지원 (2026 지속가능경영보고서 16쪽 NICE평가정보 복리후생 항목) — 지원 금액·자녀 수 한도 미기재', 40),
  (@comp_id, 'childcare', '사내 어린이집', NULL, 'family',
   'est', NULL, TRUE, '임직원의 출퇴근 부담을 덜기 위한 만 1~5세 영유아 대상 사내 어린이집 운영 (공식 채용 페이지 일과 생활 사내 어린이집 항목) — 정원·이용 비용 미기재', 41),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사 시 휴가 부여와 경조금, 화환(조화), 각종 경조물품 지원 (공식 채용 페이지 일과 생활 경조사 지원 항목), 경조사 지원 (2026 지속가능경영보고서 16쪽 NICE평가정보 복리후생 항목) — 경조 유형별 휴가 일수·경조금 금액 미기재', 42),

  -- ── 생활 지원 (perks) — 정본 ──
  (@comp_id, 'housing_loan', '주택자금대출', NULL, 'perks',
   'est', NULL, TRUE, '주택 구입 및 임차 등 생활 안정을 위한 사내 대출 제도 (공식 채용 페이지 일과 생활 주택자금대출 항목) — 대출 한도·이율 미기재', 50),
  (@comp_id, 'snack_bar', '사내 편의점', NULL, 'perks',
   'est', NULL, TRUE, '사옥 내 24시간 무인 편의점 운영, 간단한 간식과 음료 비치 (공식 채용 페이지 일과 생활 사내 편의점 항목) — 이용 비용 부담 미기재', 51),

  -- ── 보상 (compensation) — 정본 · 보고서 ──
  (@comp_id, 'holiday_gift', '명절 선물', NULL, 'compensation',
   'est', NULL, TRUE, '설날과 추석 회사 선물 (공식 채용 페이지 일과 생활 명절 선물 항목), 명절(설, 추석) 선물 지급 (2026 지속가능경영보고서 16쪽 NICE평가정보 복리후생 항목) — 선물 금액·품목 미기재', 60),
  (@comp_id, 'excellence_award', '우수임직원 포상', NULL, 'compensation',
   'est', NULL, TRUE, '재무적/비재무 성과, 회사 경영방침 측면에서 탁월한 성과를 낸 우수 직원 및 팀 선정 포상 (2026 지속가능경영보고서 16쪽 우수임직원포상 항목) — 포상 내용·선정 주기 미기재', 61),

  -- ── 성장 (growth) — 정본 · 보고서 · 다양성 존중 페이지 ──
  (@comp_id, 'edu_support', '교육비 지원·NICE 지식큐브·NICE ACADEMY', NULL, 'growth',
   'est', NULL, TRUE, '업무 전문성 향상을 위한 각종 교육의 교육비 지원, 매달 빅데이터·인문학·개인정보 보호법·AI 등 분야 전문가를 초청하는 NICE 지식큐브 (공식 채용 페이지 일과 생활 교육비 지원·사내 교육 항목), NICE ACADEMY 빅데이터 과정·인문학 특강 (2026 지속가능경영보고서 16쪽 자기계발 학습지원 항목), 업무와 업무 외 영역의 무료 교육 플랫폼 제공(직무, 지식, 어학, 취미 등) (공식 홈페이지 다양성 존중 페이지 임직원의 교육·훈련 항목) — 교육비 지원 한도 미기재', 70),
  (@comp_id, 'lang', '어학 교육비·어학연수비 지원·외국어 강좌', NULL, 'growth',
   'est', NULL, TRUE, '어학 향상을 위한 각종 교육 비용 지원 (공식 채용 페이지 일과 생활 교육비 지원 항목), 어학 역량 향상을 위한 어학연수비 지원 (2026 지속가능경영보고서 16쪽 인재육성강화 항목), NICE ACADEMY 외국어 강좌 (같은 보고서 16쪽 자기계발 학습지원 항목) — 지원 한도·대상 언어 미기재', 71),
  (@comp_id, 'books', '도서 구매비 지원', NULL, 'growth',
   'est', NULL, TRUE, '도서 구매 비용 지원 (공식 채용 페이지 일과 생활 교육비 지원 항목) — 지원 한도 미기재', 72),
  (@comp_id, 'mba', '학위 취득 지원', NULL, 'growth',
   'est', NULL, TRUE, '매년 우수인재를 선발해 대학원 이상의 심화학습 과정 지원 (공식 채용 페이지 일과 생활 학위 취득 지원 항목), 고급 인력 양성을 위한 우수인재 선발 학위과정 지원 (2026 지속가능경영보고서 16쪽 학위과정지원 항목) — 선발 인원·지원 범위 미기재', 73),
  (@comp_id, 'self_development', '자기개발비 지원', NULL, 'growth',
   'est', NULL, TRUE, '자기개발비 지원 (2026 지속가능경영보고서 16쪽 NICE평가정보 복리후생 항목) — 지원 금액·사용 범위 미기재', 74),

  -- ── 건강 (health) — 정본 · 보고서 · 안전보건 페이지 ──
  (@comp_id, 'insurance', '단체상해보험', NULL, 'health',
   'est', NULL, TRUE, '임직원과 배우자, 부모, 자녀 대상 단체상해보험 제공, 실손·치과 보험 중 선택 (공식 채용 페이지 일과 생활 단체상해보험 항목), 직원 및 가족 상해보험 가입 (2026 지속가능경영보고서 16쪽 NICE평가정보 복리후생 항목) — 보장 한도·회사 부담 범위 미기재', 80),
  (@comp_id, 'health_check', '건강검진', NULL, 'health',
   'est', NULL, TRUE, '임직원 및 배우자 연 1회 건강검진 무료 지원, 배우자 외 임직원 가족은 회사와 제휴된 가격으로 건강검진 지원 (공식 채용 페이지 일과 생활 건강검진 항목), 건강검진 실시 (2026 지속가능경영보고서 16쪽 NICE평가정보 복리후생 항목) — 검진 항목 미기재', 81),
  (@comp_id, 'mental', '근로자 EAP 지원', NULL, 'health',
   'est', NULL, TRUE, '근로자 EAP 지원 (공식 홈페이지 안전보건 페이지 2026년도 활동 계획 항목, 2026 지속가능경영보고서 24쪽 안전보건 활동 항목) — 상담 범위·이용 횟수 미기재', 82),

  -- ── 근무 환경 (work_env) — 정본 ──
  (@comp_id, 'lounge', '사내 쉼터', NULL, 'work_env',
   'est', NULL, TRUE, '사옥 내 리클라이너 및 안마의자가 비치된 휴게실 (공식 채용 페이지 일과 생활 사내 쉼터 항목)', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
