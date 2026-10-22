-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 오스템임플란트 복리후생 데이터 (신규 회사 — 웨이브 14)
-- 출처: AI 파싱 (2026-10-22)
-- URL: https://career.osstem.com/ko/culture
-- badge: est
--
-- 참고:
--   정본 = 회사 공식 홈 kr.osstem.com ESG 사회 인재경영 페이지(Vue SPA — 본문은 라우트 청크 js/EsgTalent.26e08b6e.js 의 정적 HTML).
--   보조 = 같은 홈 ESG 안전보건경영 페이지(청크 js/EsgSafetyHealth.4a2730a4.js) 임직원 건강증진 프로그램 ·
--          2026 반기보고서(접수 20260814003478) 유연근무제도 사용현황 표 · 임원 보수 산정기준 칸 중 전사 임직원 지급 기준과 동일 문장만.
--   렌더 = 번들 청크 정적 추적(헤드리스 렌더 없음). 채용 ATS osstem.recruiter.co.kr 는 robots 전면 금지라 읽지 않았다.
--   귀속 = 이 법인 자기 도메인 · 자기 공시 문장만. 비상장(옛 종목코드 048260 상장폐지) · 그룹 형제 없음 · 각주 없음.
--   금액 = 금액 행 0(전 행 정성). 학비 50% · 115평 · 3일 · 2주는 비율 · 규모 · 일수라 서술에만.
--   제외 = 임신기 근로시간 단축 · 육아휴직 · 배우자 출산휴가 통계(법정) · 입문 · 직급 · 리더십 · 법정의무 · 멘토링 교육과정(업무 교육) ·
--          조직문화 특강 · 문화 DAY(리더 교육 과정 칸) · 주재원 파견 역량 훈련 · 후보군(파견 준비 교육) · 수습 급여(급여) ·
--          가족친화 인증(인증) · 임원 경영성과급 · 육성지도비 · 자가운전보조금(임원 전용) · 시차출퇴근제 · 원격근무제(네 기간 모두 사용자 없음).
--   공고 근거 0행 / 전체 19행 · SORT 섹션 = growth 10 · compensation 20 · family 30 · time_off 40 · work_env 50 · flexibility 60 · health 70(보조 출처만).
-- 검증 · 감사 판정 반영(2026-10-22): 정본 URL 을 자기 채용 사이트 career.osstem.com Culture 페이지로 교체 · 외국어 · 사외 교육 · 학위 · 영업 인센티브 · 명절 선물(정기상여 구절 뺌 · 리드 판정 174) · 우수 사원 포상과 올림피아드 · 임신 축하 선물과 양육수당 · 장기 근속 포상 · 종합 건강검진 9행 이름과 서술 교체 · 장기근속 포상 long_service_bonus 행은 long_service_leave 로 병합 삭제 · 자녀 학자금 · 피트니스 · 의료비 · 사내 치과 할인 · 사내 식당 · 도서 대출 · 웰컴키트 · 가족 초청 문화행사 8행 추가 · 참고 블록의 정본 · 보조 출처 · 제외 · 행 수 19행과 붙여넣기 후보는 이 판정으로 뒤집힘 — 최종 26행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('osstem', '오스템임플란트',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '의료기기', 'O', 'https://career.osstem.com/ko/culture');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'osstem');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://career.osstem.com/ko/culture'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 성장 (growth) — 인재경영 페이지 역량 체계 · 인재관리 프로세스 ──
  (@comp_id, 'lang', '외국어 교육·자격취득 지원·고득점자 포상', NULL, 'growth',
   'est', NULL, TRUE, '영어, 중국어, 일본어 등 원어민 교사의 방문 수업 (공식 채용 사이트 Culture Welfare 외국어 교육 항목), 입사 이후 공인 외국어 시험에서 고득점 취득 시 시험 응시료 및 포상금 지급 (같은 페이지 외국어 고득점자 포상 항목), 외국어 자격취득 지원 (공식 홈페이지 인재경영 역량기반 인재관리 프로세스 항목), 어학 자기주도 학습 지원 (같은 페이지 생애주기별 역량 체계 재직 글로벌 역량 항목) — 지원 금액·고득점 기준 미기재', 10),
  (@comp_id, 'edu_support', '사외 교육비·초청 특강·OA 교육', NULL, 'growth',
   'est', NULL, TRUE, '회사와 협약된 직무 교육과정 수강비 전액 지원 (공식 채용 사이트 Culture Welfare 외부 직무 교육 항목), 인문학, 경제, 예술 등 저명 인사의 초청 강연 정기 진행 (같은 페이지 조직 문화 특강 항목), 엑셀·PPT·스피치 등 OA 활용 역량 강화 교육 운영 (같은 페이지 Education 전문 교육 프로그램 항목), 사외위탁교육비 전액 지원 (공식 홈페이지 인재경영 역량기반 인재관리 프로세스 항목) — 신청 조건·교육 한도 미기재', 11),
  (@comp_id, 'mba', '치의학 석·박사 과정 지원 (연구조직)·해외 주재원 과정', NULL, 'growth',
   'est', NULL, TRUE, '회사와 협약을 체결한 서울대 및 연세대 치의학대학원 석·박사 과정의 학비 50%를 연구 조직 재직자에게 지원 (공식 채용 사이트 Culture Welfare 치의학 전문 석·박사 과정 지원 항목), 글로벌 인재 육성을 위해 전세계 해외 법인에서 근무할 수 있는 주재원 기회 제공 (같은 페이지 해외 주재원 과정 항목) — 선발 기준·지원 기간 미기재', 12),

  -- ── 보상 (compensation) — 인재경영 페이지 · 2026 반기보고서 ──
  (@comp_id, 'incentive', '영업 인센티브', NULL, 'compensation',
   'est', NULL, TRUE, '개인별, 지점별, 아이템별 실적에 따라 매월 성과금 지급, 반기 및 연간 실적 포상금 및 해외연수 기회 제공 (공식 채용 사이트 Culture Welfare 영업 인센티브 항목) — 지급률·대상 직무 범위 미기재', 20),
  (@comp_id, 'holiday_gift', '명절·가정의 달 선물', NULL, 'compensation',
   'est', NULL, TRUE, '명절과 가정의 달에 식료품, 구강관리 물품과 같은 선물세트 지급 (공식 채용 사이트 Culture Welfare 명절, 가정의 달 선물 항목), 명절과 가정의 달에 자사 프리미엄 칫솔, 치약 등 구강 관리 용품 지급 (같은 페이지 구강 관리 용품 선물 항목) — 선물 금액 미기재', 21),
  (@comp_id, 'excellence_award', '우수 사원/팀 포상·오스템 올림피아드', NULL, 'compensation',
   'est', NULL, TRUE, '타의 모범이 되는 임직원과 부서를 매년 선정하여 포상 (공식 채용 사이트 Culture Welfare 우수 사원/팀 포상 항목), 사내 경연 대회를 통해 R&D 우수 아이디어를 공모·포상, 매월 누구나 아이디어 제안, 반기별 경연 대회 수상자 선정, 정식 프로젝트 착수 시 포상금 추가 지급 (같은 페이지 오스템 올림피아드 항목), 보상 올림피아드 인센티브 (공식 홈페이지 인재경영 역량기반 인재관리 프로세스 항목) — 포상 금액·선정 인원 미기재', 23),

  -- ── 가족 (family) — 인재경영 페이지 일·가정 양립과 웰빙 ──
  (@comp_id, 'parenting', '모성보호 패키지·임신 축하 선물·자녀 양육수당·입학 축하금', NULL, 'family',
   'est', NULL, TRUE, '임신한 임직원에게 전자파 차단 담요, 태명 자수가 들어간 배냇 저고리 등 축하 선물 지급 (공식 채용 사이트 Culture Welfare 임신 축하 선물 항목), 핑크 사원증·전자파 차단 담요 등 모성보호 패키지 (공식 홈페이지 인재경영 일·가정 양립과 웰빙 항목), 미취학 자녀에 대해 자녀수 제한 없이 매년 지원금 지급 (공식 채용 사이트 Culture Welfare 자녀 양육수당 지원 항목), 초, 중, 고등학교 입학 축하금 (공식 채용 사이트 Culture Welfare 자녀 입학 축하금 지원 항목) — 지원 금액 미기재', 30),
  (@comp_id, 'fertility_support', '유급 난임치료휴가 연 3일', NULL, 'family',
   'est', NULL, TRUE, '법정 기준을 초과하는 연 3일 유급 난임치료휴가, 법정 유급 2일에 1일 추가 (공식 홈페이지 인재경영 일·가정 양립과 웰빙 항목) — 신청 조건 미기재', 31),
  (@comp_id, 'childcare', '직장어린이집', NULL, 'family',
   'est', NULL, TRUE, '본사 내 115평 규모 직장어린이집 (공식 홈페이지 인재경영 일·가정 양립과 웰빙 항목) — 정원·이용 조건 미기재', 32),
  (@comp_id, 'child_edu', '자녀 학자금 지원 (초·중·고·대학)', NULL, 'family',
   'est', NULL, TRUE, '초·중·고등학교와 더불어 대학교 학자금을 일정 범위 내에 지원 (공식 채용 사이트 Culture Welfare 자녀 대학 학자금 지원 항목) — 지원 한도·자녀 수 제한 미기재', 33),

  -- ── 휴가 (time_off) — 인재경영 페이지 일·가정 양립과 웰빙 ──
  (@comp_id, 'long_service_leave', '장기 근속 포상·5년 근속 리프레시 휴가 2주', NULL, 'time_off',
   'est', NULL, TRUE, '5년 이상 장기 근속자에게 포상금과 포상 휴가 제공 (공식 채용 사이트 Culture Welfare 장기 근속 포상 항목), 5년 근속자 2주 리프레쉬 휴가 부여 (공식 홈페이지 인재경영 일·가정 양립과 웰빙 항목) — 포상 금액·유급 여부·이후 근속 주기 미기재', 40),
  (@comp_id, 'birthday_leave', '생일 반일휴가', NULL, 'time_off',
   'est', NULL, TRUE, '생일 반일휴가 부여 (공식 홈페이지 인재경영 일·가정 양립과 웰빙 항목) — 사용 기한·유급 여부 미기재', 41),

  -- ── 근무 환경 (work_env) — 인재경영 페이지 일·가정 양립과 웰빙 ──
  (@comp_id, 'nap_room', '임산부 전용 휴게실·식당', NULL, 'work_env',
   'est', NULL, TRUE, '임산부 전용 휴게실·식당 (공식 홈페이지 인재경영 일·가정 양립과 웰빙 항목) — 설치 사업장·규모 미기재', 50),
  (@comp_id, 'parking', '임산부 전용 주차공간', NULL, 'work_env',
   'est', NULL, TRUE, '임산부 전용 주차공간 (공식 홈페이지 인재경영 일·가정 양립과 웰빙 항목) — 설치 사업장·면수 미기재', 51),

  -- ── 근무 유연성 (flexibility) — 인재경영 페이지 · 2026 반기보고서 ──
  (@comp_id, 'flex_work', '선택적 근로제', NULL, 'flexibility',
   'est', NULL, TRUE, '선택적 근로제로 근무시간을 유연하게 조절 (공식 홈페이지 인재경영 일·가정 양립과 웰빙 항목), 선택근무제 사용자 수 2026년 반기 1,646명·2025년 1,644명·2024년 2,962명 (2026 반기보고서 유연근무제도 사용현황 항목) — 적용 대상·의무 근무시간대 미기재', 60),

  -- ── 건강 (health) — 안전보건경영 페이지 임직원 건강증진 프로그램 ──
  (@comp_id, 'clinic', '사내 건강관리실', NULL, 'health',
   'est', NULL, TRUE, '사내 건강관리실 상시 운영, 핵심 건강증진 프로그램 이몸튼튼 (공식 홈페이지 안전보건경영 임직원 건강증진 프로그램 항목) — 운영 시간·이몸튼튼 프로그램 내용 미기재', 70),
  (@comp_id, 'smoking_cessation', '금연클리닉', NULL, 'health',
   'est', NULL, TRUE, '금연클리닉 (공식 홈페이지 안전보건경영 임직원 건강증진 프로그램 항목) — 프로그램 내용·지원 조건 미기재', 71),
  (@comp_id, 'mental', '심리상담', NULL, 'health',
   'est', NULL, TRUE, '심리상담 (공식 홈페이지 안전보건경영 임직원 건강증진 프로그램 항목) — 상담 방식·이용 횟수 미기재', 72),
  (@comp_id, 'health_check', '종합 건강검진 (임직원·배우자)', NULL, 'health',
   'est', NULL, TRUE, '임직원 및 배우자를 대상으로 매년 종합 건강검진 실시 (공식 채용 사이트 Culture Welfare 종합 건강검진 항목), 정기 건강검진 (공식 홈페이지 안전보건경영 임직원 건강증진 프로그램 항목) — 검진 항목·비용 지원 범위 미기재', 73),
  (@comp_id, 'fitness', '사내 피트니스 센터', NULL, 'health',
   'est', NULL, TRUE, '마곡 본사 150평 규모 피트니스 센터 월 1만원 이용, PT, 필라테스, 요가, 서킷 트레이닝, 댄스 수업 등 프로그램 진행 (공식 채용 사이트 Culture Welfare 사내 피트니스 센터 항목) — 운영 시간·다른 사업장 이용 여부 미기재', 74),
  (@comp_id, 'medical', '의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '임직원 본인의 질병이나 부상 발생 시 치료 및 입원비 지원 (공식 채용 사이트 Culture Welfare 의료비 지원 항목) — 지원 한도·가족 포함 여부 미기재', 75),
  -- ── 생활 (perks) — 공식 채용 사이트 Culture Welfare ──
  (@comp_id, 'discount', '사내 치과 진료비 지원', NULL, 'perks',
   'est', NULL, TRUE, '마곡 본사 2층 트윈 치과에서 임직원과 직계 가족에게 최신 디지털 치과 진료를 임직원 할인가에 제공 (공식 채용 사이트 Culture Welfare 사내 치과 진료비 지원 항목) — 할인율 미기재', 80),
  (@comp_id, 'meal', '사내 식당 운영', NULL, 'perks',
   'est', NULL, TRUE, '각 사업장 별 사내 식당 운영, 영양사의 균형잡힌 건강한 식단 제공 (공식 채용 사이트 Culture Welfare 사내 식당 운영 항목) — 제공 끼니·식대 부담 미기재', 81),
  -- ── 여가 (leisure) — 공식 채용 사이트 Culture Welfare · Education ──
  (@comp_id, 'library', '사내 도서 대출', NULL, 'leisure',
   'est', NULL, TRUE, '경영, 문학, 리더십 등 다양한 도서 제공, 신간 구비 (공식 채용 사이트 Culture Welfare 사내 도서 대출 항목) — 이용 방식·도서 구입 지원 여부 미기재', 90),
  (@comp_id, 'welcome_kit', '신규 입사자 웰컴키트', NULL, 'leisure',
   'est', NULL, TRUE, '업무 활용도가 높은 물품을 엄선하여 신규 입사자에게 선물 (공식 채용 사이트 Culture Welfare 신규 입사자 웰컴키트 항목) — 구성 물품 미기재', 91),
  (@comp_id, 'company_event', '가족·지인 초청 사내 문화행사', NULL, 'leisure',
   'est', NULL, TRUE, '가족·지인 초청 사내 문화행사 운영 (공식 채용 사이트 Culture Education 공통 역량 개발 과정 항목) — 행사 주기·내용 미기재', 92)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
