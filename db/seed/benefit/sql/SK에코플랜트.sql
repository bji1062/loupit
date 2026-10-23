-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SK에코플랜트 복리후생 데이터 (신규 회사 — 웨이브 15)
-- 출처: AI 파싱 (2026-10-23)
-- URL: https://sustainability.skecoplant.com/2025/ko/generaltopic/s/humanresourcemanagement
-- badge: est
--
-- 참고:
--   정본은 비상장 법인 에스케이에코플랜트(주)의 자기 서브도메인 sustainability.skecoplant.com 에 실린
--   2025 지속가능경영보고서 웹판 인적자원 관리 절이다(Next.js SSR · 원본 HTML 본문에 복리후생 문장과 표가 있다).
--   같은 보고서 국문 PDF(234쪽 · 발행 2026년 7월 · 보고 기간 2025-01-01~2025-12-31 · 보고 범위 = SK에코플랜트 국내 사업장 83곳,
--   자회사 정량 데이터는 표마다 SKEE 등으로 따로 표기)로 쪽 번호를 맞추고 전문을 제도 이름으로 다시 찾았다(54쪽 구성원 건강 지원 표).
--   공시 보조: OpenDART 2025 사업보고서(접수 20260331003895) · 2026 반기보고서(접수 20260814002733) 유연근무제도 사용 현황 표.
--   www.skecoplant.com 은 robots 가 루트만 허용(Disallow 전체 · Allow 루트) — 루트 HTML 에서 보고서 링크만 얻고 하위 페이지는 받지 않았다.
--   SK Careers(그룹 통합 채용)에는 이 법인 전용 복리후생 페이지가 없어 쓰지 않았다.
--   귀속: 보고서 문장 주어가 SK에코플랜트는 이고 법인 자기 발행이라 각주 없음. 석사 과정 문장만 SK에코플랜트와 자회사 SK에코엔지니어링은 주어.
--   금액: 원문에 원 단위 고정 금액 0건 — meal 1행만 식대 식(하루 3끼 × 1끼 12,000원 × 연 240일 = 864 추정). 나머지 NULL.
--   제외: 법정(구성원 본인 일반 · 특수 건강검진 · 유소견자 사후관리 · 재취업 지원 서비스(직원 1,000명 이상) · 모성보호 프로그램 한 줄) ·
--     업무 교육(리더십 · FLP · 직무전환 · 조직 적응 · 에피 C.O.R.E) · 임원 전용 원어민 회화 · 장애인선수단 훈련 지원금 ·
--     사내 생성형 AI 에피AI(업무 시스템) · 사회공헌 봉사 프로그램 · Biz. Partner 대상 경조사 · 저리대출 · 안전 포상.
--   공고 근거 0행 / 전체 32행.
--   SORT 섹션 순서 = 정본 페이지 등장 순(growth 10 · health 20 · compensation 30 · flexibility 40 · work_env 50 · family 60 · perks 70 · time_off 80).
-- 검증 · 감사 판정 반영(2026-10-23): 109쪽 사이버대학교 위탁교육 학비 지원을 mba 에서 self_development 로 옮기고 mba 는 하이테크솔루션학과 석사 과정만 · 123 · 126쪽 에피가족 플로깅 페스티벌을 company_event 로 추가(여가 섹션 신설) · 반반차 원문의 화면 이름을 2시간 단위 휴가로(감사 — 같은 웨이브 우리은행 · 도화와 한 꼴) · 항목 페이지 예외 1(통합 밖 리드 집행) · 참고 블록의 사이버대 지원 내용 미기재 · SORT 섹션 순서 · 행 수 32행은 이 판정으로 뒤집힘 — 최종 33행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('sk_ecoplant', 'SK에코플랜트',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '건설', 'S', 'https://sustainability.skecoplant.com/2025/ko/generaltopic/s/humanresourcemanagement');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'sk_ecoplant');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://sustainability.skecoplant.com/2025/ko/generaltopic/s/humanresourcemanagement'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 성장 · 교육 (growth) — 2025 지속가능경영보고서 인적자원 관리 ──
  (@comp_id, 'career', 'Job Posting 제도 (사내 채용)', NULL, 'growth',
   'est', NULL, TRUE, '구성원의 주도적 커리어 개발을 지원하기 위한 사내 채용 제도인 Job Posting 제도 운영 (2025 지속가능경영보고서 106쪽 우수인재 확보 및 유지 항목) — 지원 자격·공모 주기 미기재', 10),
  (@comp_id, 'lang', '영어학습 지원 과정 (구성원·가족)', NULL, 'growth',
   'est', NULL, TRUE, '전 구성원의 글로벌 어학능력 향상을 위한 영어학습 지원 과정 운영, 학습 App.·전화영어·화상영어·원어민 회화 등 학습 채널 제공, 일정 수준 이상 이수 시 프리미엄 과정 참여 (2025 지속가능경영보고서 109쪽 글로벌 역량 강화 항목), 구성원·가족 영어학습 지원 (113쪽 일과 삶의 균형 프로그램 항목) — 비용 지원 범위·가족 대상 범위 미기재', 11),
  (@comp_id, 'self_development', '자격 취득 지원·사이버대학교 학비 지원', NULL, 'growth',
   'est', NULL, TRUE, '자격 취득 지원, 2025년부터 국내 주요 6개 사이버대학교와 산업체 위탁교육 협약을 체결해 학비 지원 및 비경쟁 입학 전형 (2025 지속가능경영보고서 109쪽 Professional 역량 강화 항목) — 지원 자격증 범위·학비 지원 비율·지원 금액 미기재', 12),
  (@comp_id, 'mba', '하이테크솔루션학과 석사 과정', NULL, 'growth',
   'est', NULL, TRUE, '성균관대학교와 협력한 하이테크솔루션학과 석사과정, 4년제 학사 학위를 보유한 재직기간 만 3년 이상 구성원 지원 후 심사 선발, 1년 6개월 전 과정 동안 학위 취득에 필요한 모든 비용 지원, 교육 기간 중 급여와 복리후생 동일 유지·근속년수 인정 (2025 지속가능경영보고서 110쪽 하이테크솔루션학과 석사 과정 운영 항목) — 연간 선발 인원 미기재', 13),
  (@comp_id, 'edu_support', 'mySUNI 온라인 학습 플랫폼·에피런 투게더 특강', NULL, 'growth',
   'est', NULL, TRUE, 'SK그룹 온라인 교육 플랫폼(mySUNI) 등 다양한 학습 기회 제공 (2025 지속가능경영보고서 113쪽 일과 삶의 균형 지원 항목), 전문가를 초빙해 점심시간에 진행하는 특별 강연 프로그램 에피런 투게더(Epi-Learn & Run Together), mySUNI 다시보기(VOD) 제공 (110쪽 Foundation 역량 강화 항목) — 수강 범위·지원 비용 미기재', 14),
  -- ── 건강 (health) — 2025 지속가능경영보고서 인적자원 관리 · 사업장 안전보건 ──
  (@comp_id, 'mental', '에피케어 심리상담 (구성원·가족)', NULL, 'health',
   'est', NULL, TRUE, '구성원과 직계 가족(배우자·자녀)의 마음건강 증진을 위한 심리상담 프로그램 에피케어, 대면·전화·화상·모바일 메신저 등 온·오프라인 채널 선택, 연 5회 전액 무료 지원, 개인의 심리상태에 따라 추가 지원, 전용 사이트 자가 마음검진 서비스 (2025 지속가능경영보고서 111쪽 에피케어 심리상담 항목), 심신 회복과 스트레스 완화를 위한 비대면 건강증진 프로그램 언택트 심기신(心氣身) (54쪽 건강 중점 관리 영역별 프로그램 표) — 상담 1회 시간 미기재', 20),
  (@comp_id, 'health_check', '가족 건강검진 지원 (배우자·직계가족 1인)', NULL, 'health',
   'est', NULL, TRUE, '직계가족 1인 건강검진 지원 (2025 지속가능경영보고서 54쪽 건강 중점 관리 영역별 프로그램 표 신체 건강 항목), 배우자 건강검진 지원, 2025년 가족 건강검진 지원 범위를 배우자에서 직계가족에 준하는 범위로 확대 (113쪽 일과 삶의 균형 프로그램 항목) — 검진 항목·비용 지원 범위·주기 미기재', 21),
  (@comp_id, 'clinic', '건강관리실·부속 치과 의원 (치과는 본사)', NULL, 'health',
   'est', NULL, TRUE, '건강관리실, 부속 치과 의원 운영 (2025 지속가능경영보고서 54쪽 건강 중점 관리 영역별 프로그램 표 근무 환경 항목), 본사 치과 진료 운영 (113쪽 일과 삶의 균형 프로그램 항목) — 건강관리실 운영 사업장·진료 비용 지원 범위 미기재', 22),
  (@comp_id, 'fitness', '본사 피트니스 센터', NULL, 'health',
   'est', NULL, TRUE, '헬스장 운영 (2025 지속가능경영보고서 54쪽 건강 중점 관리 영역별 프로그램 표 근무 환경 항목), 본사 피트니스 센터 운영 (113쪽 일과 삶의 균형 프로그램 항목) — 운영 시간·이용 비용 미기재', 23),
  (@comp_id, 'insurance', '단체상해보험·치아보험', NULL, 'health',
   'est', NULL, TRUE, '임직원 단체상해보험·치아보험 지원 (2025 지속가능경영보고서 113쪽 일과 삶의 균형 프로그램 항목 구성원·가족 지원) — 보장 범위·가족 가입 여부 미기재', 24),
  (@comp_id, 'medical', '실손 의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '실손 의료비 지원 (2025 지속가능경영보고서 113쪽 일과 삶의 균형 프로그램 항목 구성원·가족 지원) — 지원 한도·가족 포함 여부 미기재', 25),
  -- ── 보상 (compensation) — 2025 지속가능경영보고서 공정한 보수 ──
  (@comp_id, 'incentive', '성과 기반 인센티브 보너스 (연 1회)', NULL, 'compensation',
   'est', NULL, TRUE, '모든 구성원을 대상으로 연 1회 성과 기반 인센티브 보너스 지급, 개인 및 조직이 창출한 성과를 인정하고 보상 (2025 지속가능경영보고서 112쪽 공정한 보수 항목) — 지급 기준·지급률 미기재', 30),
  (@comp_id, 'stock_option', '우리사주제도', NULL, 'compensation',
   'est', NULL, TRUE, '구성원이 회사의 장기적 가치 증진에 동참할 수 있도록 우리사주제도 운영, 재직 중인 모든 구성원은 자유롭게 우리사주조합에 가입하거나 탈퇴, 모든 조합원은 퇴직자 등 양도인 수에 따른 조합 보유분에 대해 자유롭게 우리사주 취득 (2025 지속가능경영보고서 112쪽 공정한 보수 항목) — 회사 출연·지원 내용 미기재', 31),
  -- ── 근무 유연성 (flexibility) — 2025 지속가능경영보고서 일과 삶의 균형 · 사업 · 반기보고서 ──
  (@comp_id, 'flex_work', '시차출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '개인별 근무일정 설계 및 시차출퇴근 가능 (2025 지속가능경영보고서 113쪽 일과 삶의 균형 프로그램 항목 유연근무 및 초과근로 제한), 시차출퇴근제 사용자 수 2026년 상반기 337명 (2026 반기보고서 유연근무제도 사용 현황 항목) — 출퇴근 시간 범위·대상 직무 미기재', 40),
  (@comp_id, 'remote_work', '재택근무 (조건부)', NULL, 'flexibility',
   'est', NULL, TRUE, '업무특성 등을 고려한 재택근무 실시 (2025 지속가능경영보고서 113쪽 일과 삶의 균형 프로그램 항목), 원격근무제(재택근무 포함) 사용자 수 2026년 상반기 27명 (2026 반기보고서 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 41),
  (@comp_id, 'family_day', '금요일 16시 퇴근 (본사)', NULL, 'flexibility',
   'est', NULL, TRUE, '본사 구성원 금요일 16시 퇴근으로 여가 및 자기계발 등 시간 지원 (2025 지속가능경영보고서 113쪽 일과 삶의 균형 프로그램 항목) — 적용 주기·급여 처리 미기재', 42),
  (@comp_id, 'pc_off', 'PC Off 시스템', NULL, 'flexibility',
   'est', NULL, TRUE, 'PC Off 시스템 운영 (2025 지속가능경영보고서 113쪽 일과 삶의 균형 프로그램 항목 유연근무 및 초과근로 제한) — 적용 시간·대상 미기재', 43),
  -- ── 근무 환경 (work_env) — 2025 지속가능경영보고서 일과 삶의 균형 지원 ──
  (@comp_id, 'free_seating', '자율 좌석제', NULL, 'work_env',
   'est', NULL, TRUE, '자율 좌석제 등 유연한 근무 환경 조성 (2025 지속가능경영보고서 113쪽 일과 삶의 균형 지원 항목) — 적용 사업장 미기재', 50),
  -- ── 가족 (family) — 2025 지속가능경영보고서 일과 삶의 균형 ──
  (@comp_id, 'parenting', '육아휴직 최대 2년', NULL, 'family',
   'est', NULL, TRUE, '육아휴직 최대 2년으로 확대 (2025 지속가능경영보고서 113쪽 일과 삶의 균형 프로그램 항목 휴직·휴가 및 육아) — 휴직 중 급여 지급 여부 미기재', 60),
  (@comp_id, 'childcare', '본사 행복날개 어린이집', NULL, 'family',
   'est', NULL, TRUE, '직장 어린이집 운영 (2025 지속가능경영보고서 113쪽 일과 삶의 균형 지원 항목), 본사 행복날개 어린이집 운영 (113쪽 일과 삶의 균형 프로그램 항목) — 입소 정원·이용 비용 미기재', 61),
  (@comp_id, 'event', '장례 도우미 서비스', NULL, 'family',
   'est', NULL, TRUE, '장례 도우미 서비스 운영 (2025 지속가능경영보고서 113쪽 일과 삶의 균형 프로그램 항목 구성원·가족 지원) — 지원 대상 범위·서비스 내용 미기재', 62),
  -- ── 생활 · 금융 (perks) — 2025 지속가능경영보고서 일과 삶의 균형 ──
  (@comp_id, 'welfare_fund_loan', '행복우산 대출', NULL, 'perks',
   'est', NULL, TRUE, '행복우산 대출 제도 운영 (2025 지속가능경영보고서 113쪽 일과 삶의 균형 프로그램 항목 구성원·가족 지원) — 대출 용도·한도·이율 미기재', 70),
  (@comp_id, 'transport', '귀가 교통비 지원 (현장 구성원)', NULL, 'perks',
   'est', NULL, TRUE, '현장 구성원 귀가 교통비 지원 (2025 지속가능경영보고서 113쪽 일과 삶의 균형 프로그램 항목) — 지원 금액·횟수 미기재', 71),
  (@comp_id, 'relocation', '해외 근무 시 가족 동반 지원', NULL, 'perks',
   'est', NULL, TRUE, '해외 근무 시 가족 동반 지원 (2025 지속가능경영보고서 113쪽 일과 삶의 균형 프로그램 항목) — 지원 내용·범위 미기재', 72),
  (@comp_id, 'welfare_point', '선택적 복리후생 포인트', NULL, 'perks',
   'est', NULL, TRUE, '선택적 복리후생 포인트 지원 (2025 지속가능경영보고서 113쪽 일과 삶의 균형 프로그램 항목 구성원·가족 지원) — 포인트 금액·사용처 미기재', 73),
  (@comp_id, 'meal', '조식·중식·석식 제공', 864, 'perks',
   'est', '조식·중식·석식 제공 (2025 지속가능경영보고서 113쪽 일과 삶의 균형 프로그램 항목 구성원·가족 지원) — 운영 사업장·식대 단가 미기재 (하루 3끼 × 1끼 12,000원 × 연 240일 추정)', FALSE, NULL, 74),
  (@comp_id, 'car_rental', '가족행사 시 차량 지원 (기사 포함)', NULL, 'perks',
   'est', NULL, TRUE, '가족행사 시 차량 지원, 기사 및 차량 지원 (2025 지속가능경영보고서 113쪽 일과 삶의 균형 프로그램 항목 구성원·가족 지원) — 대상 행사·이용 횟수 미기재', 75),
  (@comp_id, 'grocery_support', '친환경농산물 이용 지원금', NULL, 'perks',
   'est', NULL, TRUE, '친환경농산물 이용 지원금 제도 운영 (2025 지속가능경영보고서 113쪽 일과 삶의 균형 프로그램 항목 구성원·가족 지원) — 지원 금액·이용처 미기재', 76),
  (@comp_id, 'telecom', '휴대폰 비용 지원', NULL, 'perks',
   'est', NULL, TRUE, '휴대폰 비용 지원 (2025 지속가능경영보고서 113쪽 일과 삶의 균형 프로그램 항목 구성원·가족 지원) — 지원 금액·대상 미기재', 77),
  -- ── 휴가 (time_off) — 2025 지속가능경영보고서 일과 삶의 균형 ──
  (@comp_id, 'long_service_leave', '장기근속 포상 및 특별휴가', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속 포상 및 특별 휴가 (2025 지속가능경영보고서 113쪽 일과 삶의 균형 프로그램 항목), 장기근속·정년도래 구성원 대상 특별휴가 부여 (113쪽 일과 삶의 균형 프로그램 성과 표 휴직·휴가 및 육아) — 근속 기준·휴가 일수·포상 내용 미기재', 80),
  (@comp_id, 'summer_leave', '여름휴가 (5일)', NULL, 'time_off',
   'est', NULL, TRUE, '여름휴가(5일) 부여 (2025 지속가능경영보고서 113쪽 일과 삶의 균형 프로그램 항목 휴직·휴가 및 육아) — 연차 사용일인지·유급 여부 미기재', 81),
  (@comp_id, 'leave_general', '2시간 단위 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '2시간 단위 휴가 제도 운영 (2025 지속가능경영보고서 113쪽 일과 삶의 균형 프로그램 항목 휴직·휴가 및 육아) — 사용 한도 미기재', 82),
  -- ── 여가 · 행사 (leisure) — 2025 지속가능경영보고서 사회공헌 ──
  (@comp_id, 'company_event', '에피가족 플로깅 페스티벌 (구성원 가족 참여)', NULL, 'leisure',
   'est', NULL, TRUE, '가정의 달과 창립기념일을 맞이해 구성원 가족이 함께하는 참여형 프로그램 에피가족 플로깅 페스티벌 개최, 가족단위 플로깅 투어·체험 활동 (2025 지속가능경영보고서 123쪽·126쪽 사회공헌 항목) — 개최 주기·참가 범위 미기재', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
