-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 코미코 복리후생 데이터 (신규 회사 — 웨이브 7)
-- 출처: AI 파싱 (2026-10-14)
-- URL: https://www.komico.com/kr/recruit/person.php
-- badge: est
--
-- 참고:
--   정본은 상장 법인 (주)코미코의 자기 도메인 www.komico.com 인재채용 > 인사제도 페이지다.
--   SSR 이라 원본 HTML 에 인사정책 탭 다섯(인사방향 · 인사원칙 · 평가보상 · 인재육성 · 복지제도) 텍스트가 다 있다.
--   헤드리스 렌더 · 이미지 판독 불필요. 영문판 /en/recruit/person.php 도 같은 항목이다.
--   보조 출처는 OpenDART 2026 반기보고서(접수 20260814003614) 직원 등 현황 유연근무제도 사용 현황 표와
--   별도 재무제표 주석 우발채무와 약정사항(우리사주협력출연제도), 2025 사업보고서(접수 20260323001516)
--   별도 재무제표 주석 기타장기종업원급여. 직원 941명(2026-06-30 · 국내 안성법인 기준).
--   귀속: 페이지 문구가 코미코 구성원이라면 누구나 혜택 가능 으로 법인 단수 주어이고 그룹 · 계열사 단서가 없다.
--   공채는 MiCo 그룹사 차원이라 적혀 있으나 복지 문장은 이 법인 도메인 · 이 법인 주어다. 각주 없음.
--   지주 미코 · 형제 미코세라믹스 · 미코하이테크는 코퍼스 · 대기 폴더에 없다.
--   금액: 식대 1행만 추정(하루 3끼 × 1끼 12,000원 × 연 240일 = 864, 야식 제외). 원 단위 숫자 0건 — 나머지 NULL.
--   제외: 법정(공통교육의 성희롱예방교육 · 안전교육 · 육아지원제도 사용 현황 표) · 업무 교육(학점이수제 ·
--     관리감독자 · 조직활성화 · 면접관 · 승진대상자 · 신입사원 OJT · 평가자 · 직무교육 · 반도체교육) ·
--     사회공헌 활동 · 임원 보수 칸(특별인센티브 · 임원 의료지원 건강검진 단체상해보험 · 명절선물비) ·
--     원격근무제 사용자 수 0 · 실외 산책로(옥외 조경) · 채용 사이트(recruiter.co.kr) 복리후생 화면은 벤더 API 호스트에만 있어 읽지 않음.
--   공고 근거 0행 / 전체 24행.
--   SORT 섹션 순서 = 정본 페이지 등장 순(compensation 10 · growth 20 · work_env 30 · perks 40 ·
--     family 50 · health 60 · leisure 70), 공시에만 있는 flexibility 80.
-- 검증 · 감사 판정 반영(2026-10-14): 행 조치 없음 — 최종 24행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('komico', '코미코',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '반도체장비', 'K', 'https://www.komico.com/kr/recruit/person.php');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'komico');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.komico.com/kr/recruit/person.php'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상 (compensation) — 인사제도 평가/보상 · 복지제도 · 공시 ──
  (@comp_id, 'incentive', '성과급', NULL, 'compensation',
   'est', NULL, TRUE, '업적평가와 역량평가 결과와 연계된 성과급 (공식 홈페이지 인사제도 평가/보상 항목) — 지급 기준·지급률 미기재', 10),
  (@comp_id, 'excellence_award', '포상 제도', NULL, 'compensation',
   'est', NULL, TRUE, '업적평가와 역량평가 결과와 연계된 포상 (공식 홈페이지 인사제도 평가/보상 항목) — 포상 종류·기준·급부 미기재', 11),
  (@comp_id, 'holiday_gift', '명절 상품권·선물', NULL, 'compensation',
   'est', NULL, TRUE, '명절(설/추석) 상품권 or 선물 지급 (공식 홈페이지 인사제도 복지제도 가족 지원 각종 기념일 항목) — 금액·품목 미기재', 12),
  (@comp_id, 'stock_option', '우리사주조합', NULL, 'compensation',
   'est', NULL, TRUE, '기업의 경영과 이익분배에 참여하게 함으로써 종업원의 근로의욕을 고취시키고 재산 형성 촉진 (공식 홈페이지 인사제도 복지제도 기타 혜택 우리사주조합 항목), 근로자의 복지증진 및 애사심 고취 증진 목적의 우리사주협력출연제도 운영, 임직원 출연분에 일정 비율의 금액을 회사에서 대응 출연 (2026 반기보고서 재무제표 주석 우발채무와 약정사항 항목) — 회사 대응 출연 비율 미기재', 13),
  (@comp_id, 'long_service_bonus', '장기근속 급부', NULL, 'compensation',
   'est', NULL, TRUE, '장기 근속 임직원에게 장기종업원급여 제공, 주로 5년 이상 장기근무 임직원 대상 (2025 사업보고서 재무제표 주석 기타장기종업원급여 항목) — 급부 형태·금액 미기재', 14),
  -- ── 성장 (growth) — 인사제도 인재육성 Global교육 ──
  (@comp_id, 'lang', '어학 과정', NULL, 'growth',
   'est', NULL, TRUE, '어학 인텐시브 과정, 어학과정, 영어 프리젠테이션 과정 (공식 홈페이지 인사제도 인재육성 Global교육 항목) — 수강 대상·비용 지원 범위 미기재', 20),
  (@comp_id, 'mba', 'MBA/해외연수 특별과정', NULL, 'growth',
   'est', NULL, TRUE, 'MBA/해외연수 등 특별과정, 주재원특별과정 (공식 홈페이지 인사제도 인재육성 Global교육 항목) — 선발 기준·지원 범위 미기재', 21),
  -- ── 근무 환경 (work_env) — 복지제도 주거/식사 ──
  (@comp_id, 'dormitory', '기숙사', NULL, 'work_env',
   'est', NULL, TRUE, '원거리 지역에 거주하는 미혼 사원들을 위한 기숙사 지원, 회사 ↔ 기숙사간 통근버스 이용 약 5~10분 거리 위치 (공식 홈페이지 인사제도 복지제도 주거/식사 기숙사 항목) — 입주 비용·호실 형태 미기재', 30),
  -- ── 생활 (perks) — 복지제도 주거/식사 · 각종 기념일 · 업체 제휴 · 기타 혜택 ──
  (@comp_id, 'meal', '3식 무상 (사내식당)', 864, 'perks',
   'est', '사내식당을 운영하며 조식/중식/석식/야식 무상 제공 (공식 홈페이지 인사제도 복지제도 주거/식사 3식 무상 항목) — 식대 단가 미기재 (하루 3끼 × 1끼 12,000원 × 연 240일 추정, 야식 제외)', FALSE, NULL, 40),
  (@comp_id, 'commute_subsidy', '통근버스', NULL, 'perks',
   'est', NULL, TRUE, '인근지역 출퇴근시간 통근버스 지원, 회사 ↔ 기숙사 구간 · 회사 ↔ 평택역 구간별, 공도/대림동산 등 중도 승/하차 가능 (공식 홈페이지 인사제도 복지제도 주거/식사 통근버스 항목) — 운행 횟수·시간표 미기재', 41),
  (@comp_id, 'birthday_gift', '생일·결혼기념일 상품권·선물', NULL, 'perks',
   'est', NULL, TRUE, '본인 생일기념일, 결혼기념일 상품권 or 선물 지급 (공식 홈페이지 인사제도 복지제도 가족 지원 각종 기념일 항목) — 금액·품목 미기재', 42),
  (@comp_id, 'discount', '업체 제휴', NULL, 'perks',
   'est', NULL, TRUE, '헬스장, 호텔, 커피숍 등 업체 제휴, 상시 게시판 공지 (공식 홈페이지 인사제도 복지제도 여가/휴양 업체 제휴 항목) — 제휴 혜택 내용 미기재', 43),
  (@comp_id, 'housing_loan', '사내대출제도', NULL, 'perks',
   'est', NULL, TRUE, '전세자금, 주택구입, 가족 병가, 가계안정 자금 등 해당항목에 대해 사내 대출제도 활용, 각 항목별 차등 지원(이자 할인) (공식 홈페이지 인사제도 복지제도 기타 혜택 사내대출제도 항목) — 대출 한도·이율 미기재', 44),
  -- ── 가족 (family) — 복지제도 가족 지원 ──
  (@comp_id, 'child_edu', '자녀 학자금', NULL, 'family',
   'est', NULL, TRUE, '고등학생 ~ 대학생 자녀 학자금 지원, 자녀수 무관 (공식 홈페이지 인사제도 복지제도 가족 지원 자녀 학자금 항목) — 지원 금액·한도 미기재', 50),
  (@comp_id, 'event', '경조사비 지원', NULL, 'family',
   'est', NULL, TRUE, '경사: 본인 결혼, 부모(배우자포함) 회갑/고희금 지급, 조사: 부모(배우자포함) 조의금 등 지급 (공식 홈페이지 인사제도 복지제도 가족 지원 경조사비 지원 항목) — 경조금 금액 미기재', 51),
  (@comp_id, 'parenting', '자녀 출산·돌 경조금·학교 단계별 입학축하금', NULL, 'family',
   'est', NULL, TRUE, '자녀출산, 자녀돌, 자녀 학교 단계별 입학축하금 지급 (공식 홈페이지 인사제도 복지제도 가족 지원 경조사비 지원 항목) — 금액 미기재', 52),
  -- ── 건강 (health) — 복지제도 건강 관리 · 기타 혜택 사내 복지시설 ──
  (@comp_id, 'health_check', '종합 건강검진', NULL, 'health',
   'est', NULL, TRUE, '직원 본인 건강을 위한 지정병원 종합 검진 실시 지원, 직원 가족의 경우 일부 지원 가능 (공식 홈페이지 인사제도 복지제도 건강 관리 건강검진 항목) — 검진 주기·지원 금액 미기재', 60),
  (@comp_id, 'medical', '의료비 지원 (본인 입원비 실비)', NULL, 'health',
   'est', NULL, TRUE, '상해/질병에 대한 본인 입원비(실비) 지원 (공식 홈페이지 인사제도 복지제도 건강 관리 의료비 지원 항목) — 지원 한도 미기재', 61),
  (@comp_id, 'insurance', '단체 상해보험', NULL, 'health',
   'est', NULL, TRUE, '불의의 사고를 대비하여 직원 생활보장 지원차원 단체 상해보험 가입 (공식 홈페이지 인사제도 복지제도 건강 관리 상해보험 항목) — 보장 범위·보험금 미기재', 62),
  (@comp_id, 'fitness', '사내 헬스장·당구장·탁구장·농구장', NULL, 'health',
   'est', NULL, TRUE, '직원 편의시설 활용, 실내 헬스장 · 당구장 · 탁구장, 실외 농구장 (공식 홈페이지 인사제도 복지제도 기타 혜택 사내 복지시설 항목) — 이용 시간·비용 미기재', 63),
  -- ── 여가 (leisure) — 복지제도 여가/휴양 · 기타 혜택 사내 복지시설 ──
  (@comp_id, 'club', '동호회 운영 및 비용 지원', NULL, 'leisure',
   'est', NULL, TRUE, '임직원 친목도모 차원 동호회 운영 및 비용 지원, 산악, 야구, 축구, 골프, 배드민턴, 마라톤, 족구, 헬스동호회 운영 중 (공식 홈페이지 인사제도 복지제도 여가/휴양 동호회 운영 항목) — 지원 금액 미기재', 70),
  (@comp_id, 'resort', '휴양콘도', NULL, 'leisure',
   'est', NULL, TRUE, '임직원 휴가지원을 위해 법인 명의 콘도를 활용하며 대명/한화콘도에 대해 회원가 적용 (공식 홈페이지 인사제도 복지제도 여가/휴양 휴양콘도 항목) — 이용 횟수·본인 부담 미기재', 71),
  (@comp_id, 'leisure_room', '사내 PC방·노래방', NULL, 'leisure',
   'est', NULL, TRUE, '직원 편의시설 활용, 실내 PC방 · 노래방 (공식 홈페이지 인사제도 복지제도 기타 혜택 사내 복지시설 항목) — 이용 시간·비용 미기재', 72),
  -- ── 근무 유연성 (flexibility) — 2026 반기보고서 ──
  (@comp_id, 'flex_work', '시차출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제 활용, 유연근무의 방식 중 시차출퇴근제를 선택하여 시행, 시차출퇴근제 사용자 2026년 상반기 49명 (2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 출퇴근 시간대·적용 대상 미기재', 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
