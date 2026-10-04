-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 네오위즈 복리후생 데이터
-- 출처: AI 파싱 (2026-10-02)
-- URL: https://www.neowiz.com/kr/career
-- badge: est
--
-- 참고:
--   정본은 법인 자기 도메인(neowiz.com, 서버 렌더) 헤더 메뉴 인재채용 → 지원 안내 상시 페이지의 「네오위즈 혜택」 카드 21개다.
--   꼬리말 사업자등록번호 120-87-14245 = OpenDART 기업개황 (주)네오위즈 bizr_no 와 같다 — 지주 네오위즈홀딩스(nwhcorp.com)와 다른 법인.
--   보조: 같은 사이트 헤더 메뉴 영문판 /en/career Benefits — Visa Sponsorship 만 더 썼다. Neowiz Santa Monica(미국 법인) 4항목은 쓰지 않았다.
--     OpenDART 2026 반기보고서(접수 20260814003548) · 2025 사업보고서(접수 20260319001284) 유연근무제도 사용 현황 주석 — flex_work 근거.
--     법인 발행 2025 지속가능경영보고서(2026-06-25 발간, 보고 범위 네오위즈 판교 본사 — 자기 도메인 /kr/esg 가 cdn.neowiz.com PDF 로 링크)
--     26 · 27 · 29 · 32쪽 — NeoFlex · Neo-dot · 단기 인센티브 · 가족친화휴가 · 건강검진 · 마인드브릿지 · 단체보험 · 주차권 추첨.
--     회사 채용 공고(jobs.lever.co/neowiz — 자기 도메인 /kr/career/jobs 가 목록을 내준다) 근무시간 · 담당업무 칸 — flex_work · car_wash 보조.
--   귀속: 법인 자기 도메인 페이지 주어는 네오위즈, 그룹 · 계열사 낱말 없음 — 그룹 각주 없음. 네오위즈홀딩스 보도자료 · 미국 법인 항목은 쓰지 않았다.
--   법정 제도: 출산 전후 휴가 · 난임 치료 휴가는 법정을 넘는 일수 · 유급분만 상회분으로 적었다. 배우자 출산휴가 분할 사용 · 배우자 유산 ·
--     사산휴가(2026-09-18 법정 신설과 겹침)는 쓰지 않았다. 직원 899명 — 재취업지원 의무 대상 아님(원문에 해당 문구도 없음).
--   금액: 원문 금액 0. 구본 추정 승계 1(meal 432 — 하루 세 끼 명시 · 틀 값, NOTE 끝에 (추정)).
--   구본에서 뺀 행: discount(자사 게임쿠폰). 재코딩 1(birthday_leave → birthday_gift). 신규 코드 0.
--   SORT 섹션 순서 = 혜택 카드에서 카테고리가 처음 나온 순서(perks 10 · health 20 · work_env 30 · family 40 · compensation 50 · leisure 60 · time_off 70), 공시 flexibility 80.
-- 재수집(2026-10-02): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-04, RV-3-7): 2025 지속가능경영보고서로 fertility_support · incentive 행 추가 · 건강검진 · 심리상담 · 단체보험 · 육아 · 주차 · 선택근무 서술 보강 — 최종 23행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('neowiz', '네오위즈',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '게임', 'N', 'https://www.neowiz.com/kr/career');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'neowiz');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.neowiz.com/kr/career'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 경제적 부가혜택 (perks) — 네오위즈 혜택 카드 · 영문 Benefits ──
  (@comp_id, 'meal', '구내식당 (하루 세 끼 무료)', 432, 'perks',
   'est', '구내식당 하루 세 끼 모두 무료, Take Out 메뉴 포함 (공식 채용 페이지 네오위즈 혜택 항목 · 영문 채용 페이지 조식·중식·석식 무료 항목) — 1식 단가 미기재 (추정)', FALSE, NULL, 10),
  (@comp_id, 'snack_bar', '카페테리아', NULL, 'perks',
   'est', NULL, TRUE, '드립 커피부터 따끈한 빵·간식까지 제공하는 사내 카페테리아 (공식 채용 페이지 네오위즈 혜택 항목) — 이용 요금·운영 시간 미기재', 11),
  (@comp_id, 'car_wash', '카케어 (출장 세차)', NULL, 'perks',
   'est', NULL, TRUE, '출장 세차 등 차량 관리 서비스, 사옥 주차장 내 차량 외관 관리 (공식 채용 페이지 네오위즈 혜택 카케어 항목 · 공식 채용 공고 Car Care Assistant 담당업무) — 이용 횟수·본인 부담 미기재', 12),
  (@comp_id, 'housing_loan', '사내 대출 및 이자 지원', NULL, 'perks',
   'est', NULL, TRUE, '결혼 준비와 보금자리 마련을 위한 사내 대출 운영, 대출 이자 일부 지원 (공식 채용 페이지 네오위즈 혜택 항목) — 대출 한도·금리·이자 지원 비율 미기재', 13),
  (@comp_id, 'birthday_gift', '생일 선물', NULL, 'perks',
   'est', NULL, TRUE, '생일에 회사가 준비한 선물 (공식 채용 페이지 네오위즈 혜택 기념일 선물 항목) — 선물 내용·금액 미기재', 14),
  (@comp_id, 'visa_support', '비자 발급 지원 (E7)', NULL, 'perks',
   'est', NULL, TRUE, 'E7 비자 발급 지원, 요건을 갖춘 입사 예정자 대상 (공식 영문 채용 페이지 Benefits Visa Sponsorship 항목) — 지원 범위·비용 부담 미기재', 15),

  -- ── 건강·의료 (health) — 네오위즈 혜택 카드 ──
  (@comp_id, 'clinic', '웰니스 센터', NULL, 'health',
   'est', NULL, TRUE, '업무 중 통증·피로감을 돌보는 전문 인력 상주 웰니스 센터, 건강관리와 휴식 지원 (공식 채용 페이지 네오위즈 혜택 항목) — 운영 시간·전문 인력 구성 미기재', 20),
  (@comp_id, 'massage', '사내 마사지 서비스 (헬스 키핑)', NULL, 'health',
   'est', NULL, TRUE, '전문 마사지사가 함께하는 사내 마사지 서비스 「헬스 키핑」 운영 (공식 채용 페이지 네오위즈 혜택 항목) — 이용 횟수·본인 부담 미기재', 21),
  (@comp_id, 'insurance', '단체상해보험 (배우자·자녀 포함)', NULL, 'health',
   'est', NULL, TRUE, '구성원과 가족(배우자·자녀)의 질병·사고·사망을 보장하는 단체보험, 업무 중과 일상생활의 사고 포함, 2025년 정신 및 행동장애 보장 추가와 뇌혈관질환·허혈성심장질환 진단 보장 확대 (공식 채용 페이지 네오위즈 혜택 단체상해보험 항목 · 2025 지속가능경영보고서 29쪽) — 보장 한도·보험료 부담 미기재', 22),
  (@comp_id, 'health_check', '건강 검진 지원', NULL, 'health',
   'est', NULL, TRUE, '전 구성원 매년 종합 건강검진 기본 비용 전액 지원, 검진일 연 1회 반일(4시간) 인정휴가 (공식 채용 페이지 네오위즈 혜택 항목 · 2025 지속가능경영보고서 29쪽) — 가족 포함 여부 미기재', 23),
  (@comp_id, 'mental', '심리 상담 서비스 (마인드 브릿지)', NULL, 'health',
   'est', NULL, TRUE, '사내 심리 상담 서비스 「마인드 브릿지」 운영, 이용 횟수 제한 없음, 사옥 내 전용 상담실 대면 상담과 온라인 비대면 상담, 상담 내용·일정은 회사에 공유·기록되지 않음 (공식 채용 페이지 네오위즈 혜택 항목 · 2025 지속가능경영보고서 29쪽) — 가족 이용 여부 미기재', 24),

  -- ── 근무환경 (work_env) — 네오위즈 혜택 카드 ──
  (@comp_id, 'parking', '카케어 (주차)', NULL, 'work_env',
   'est', NULL, TRUE, '편리한 주차 등 차량 관리 서비스, 사내 주차권은 한정된 복지 자원이라 노사협의회가 공정성을 맡는 추첨으로 배정 (공식 채용 페이지 네오위즈 혜택 카케어 항목 · 2025 지속가능경영보고서 32쪽) — 주차 무료 여부·주차 면수 미기재', 30),

  -- ── 가족·돌봄 (family) — 네오위즈 혜택 카드 ──
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사 지원, 유가족 지원 포함 (공식 채용 페이지 네오위즈 혜택 항목) — 경조금 금액·경조 범위 미기재', 40),
  (@comp_id, 'parenting', '출산 전후 휴가 120일·위탁 보육료 50%·자녀 입학 선물', NULL, 'family',
   'est', NULL, TRUE, '출산 전후 휴가 단태아 120일·미숙아 130일·다태아 150일 유급(법정보다 30일 추가), 배우자 태아검진 동행 반일 유급 휴가(정기검진 횟수 기준), 만 0~5세 자녀 어린이집 위탁 보육료 지원(연령별 법정보육료의 50%, 구성원이 고른 어린이집과 회사가 직접 위탁 계약), 자녀 초등학교 입학 시 축하 선물 (공식 채용 페이지 네오위즈 혜택 출산 전후 휴가·위탁 보육료 지원·자녀 입학 선물 항목 · 2025 지속가능경영보고서 29쪽)', 41),
  (@comp_id, 'fertility_support', '난임 치료 휴가 (유급 6일)', NULL, 'family',
   'est', NULL, TRUE, '난임 치료 휴가 유급 6일(법정 유급 2일에 4일 추가) (2025 지속가능경영보고서 29쪽 가족친화휴가 제도)', 42),

  -- ── 보상 (compensation) — 네오위즈 혜택 카드 / 2025 지속가능경영보고서 27쪽 ──
  (@comp_id, 'holiday_gift', '명절 선물', NULL, 'compensation',
   'est', NULL, TRUE, '명절에 회사가 준비한 선물 (공식 채용 페이지 네오위즈 혜택 기념일 선물 항목) — 선물 내용·금액 미기재', 50),
  (@comp_id, 'incentive', '단기 인센티브 (개인 성과·프로젝트 성과)', NULL, 'compensation',
   'est', NULL, TRUE, '개인 성과 보상과 프로젝트 재무 성과에 연동한 프로젝트 성과 보상으로 이루어진 단기 인센티브, 프로덕트의 재무 성과를 인센티브와 직접 연동하는 보상 구조 (2025 지속가능경영보고서 27쪽 보상 원칙·보상 구조) — 지급 기준·지급률 미기재', 51),

  -- ── 여가·라이프 (leisure) — 네오위즈 혜택 카드 ──
  (@comp_id, 'resort', '법인콘도 (전국 제휴 리조트)', NULL, 'leisure',
   'est', NULL, TRUE, '가족·친구와 휴가를 보낼 수 있는 전국 제휴 리조트 이용 지원 (공식 채용 페이지 네오위즈 혜택 법인콘도 항목) — 이용 횟수·숙박비 부담 미기재', 60),
  (@comp_id, 'leisure_room', '사내 게임룸', NULL, 'leisure',
   'est', NULL, TRUE, '플레이스테이션·XBOX 등 다양한 게임을 동료와 함께 즐기는 사내 게임룸 (공식 채용 페이지 네오위즈 혜택 항목) — 운영 시간 미기재', 61),
  (@comp_id, 'company_event', '사내 게임 대회', NULL, 'leisure',
   'est', NULL, TRUE, '동료와 겨루는 사내 게임 대회와 상금 (공식 채용 페이지 네오위즈 혜택 항목) — 개최 주기·상금 규모 미기재', 62),
  (@comp_id, 'club', '동호회', NULL, 'leisure',
   'est', NULL, TRUE, '스포츠·문화·게임 등 다양한 사내 동호회 활동 지원 (공식 채용 페이지 네오위즈 혜택 항목) — 활동비 금액 미기재', 63),

  -- ── 시간·휴가 (time_off) — 네오위즈 혜택 카드 ──
  (@comp_id, 'long_service_leave', '3년 근속마다 리프레시 휴가 10일', NULL, 'time_off',
   'est', NULL, TRUE, '3년 근속 시마다 유급 휴가 10일 (공식 채용 페이지 네오위즈 혜택 리프레시 휴가 항목) — 휴가비 지급 여부 미기재', 70),

  -- ── 근무 유연성 (flexibility) — 2025 지속가능경영보고서 26쪽 · 2026 반기보고서 · 채용 공고 근무시간 ──
  (@comp_id, 'flex_work', '완전선택적 근로시간제 NeoFlex·월말 자율 휴무', NULL, 'flexibility',
   'est', NULL, TRUE, '1개월 단위 완전선택적근로시간제 NeoFlex(코어타임 없이 오전 6시부터 오후 10시 사이에서 업무 시작·종료 시각과 1일 근로시간을 직원이 정하고 1개월 단위로 의무근로시간 관리, 전 구성원 적용, 포괄임금제 폐지와 실제 근무 시간 기록·보상), 매월 마지막 근무일 Neo-dot에는 그달 의무근로시간을 채웠고 업무에 지장이 없으면 출근 없이 타임오프 (2025 지속가능경영보고서 26쪽 · 2026 반기보고서 유연근무제도 사용 현황 · 공식 채용 공고 근무시간 항목)', 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
