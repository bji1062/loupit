-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- LS머트리얼즈 복리후생 데이터 (신규 회사 — 웨이브 10)
-- 출처: AI 파싱 (2026-10-15)
-- URL: https://www.lsmaterials.co.kr/kr/recruitment/personnel_system.html
-- badge: est
--
-- 참고:
--   정본 = 상장 법인 LS머트리얼즈 자기 도메인(lsmaterials.co.kr) 채용정보 > 인사제도 페이지.
--     SSR 원본 HTML 에 인재 육성 교육 표 · 평가/보상 · LS머트리얼즈 복리후생 제도 16항목이 다 있다(렌더 없음).
--   보조 1 = 같은 도메인 채용공고에서 링크된 회사 계정 채용 사이트(lsmaterials-recruit.career.greetinghr.com)
--     복리후생 · 인재육성/평가보상 페이지(SSR) — 정본에 없는 생일자 선물대 · 장기근속 휴가 · 유연근무제 · 수유실 ·
--     성과급 PI/PS 만 여기서 받쳤다.
--   보조 2 = 같은 도메인 지속가능경영 > 인적자본 페이지와 자료실 인적자본 정책 PDF(2025-12 제정 · 2026-06 파일).
--   보조 3 = OpenDART 2026 반기보고서(접수 20260814003148) 유연근무제도 사용 현황 · 재무제표 주석 장기종업원급여.
--   귀속: 모든 문장의 주어가 LS머트리얼즈(법인 단수) · 그룹 공통 · 계열사별 상이 단서 없음 — 각주 없음.
--     LS그룹 공용 채용 인사제도 페이지(LS는 주어)는 한 건도 쓰지 않았다(요청 0회).
--     기등록 형제 LS ELECTRIC · LS마린솔루션 · 가온전선 시드와 문장 겹침 없음.
--     구명 LS엠트론 사업부(2021-01 물적분할) 자료는 쓰지 않았다.
--   금액: 식대 1행만 추정(하루 3끼 × 1끼 12,000원 × 연 240일 = 864). 출생 축하금 최대 1천만원은 1회성 · 한도라 NULL.
--   제외: 법정(연차휴가 · 임신기 · 육아기 근로시간 단축 · 출산휴가 · 육아휴직 · 복직 시 직무 복귀 · 법정의무교육) ·
--     업무 교육(신입 OJT · 멘토링 · 직급별 · 리더십 · 진급대상자 · 사외 실무역량 교육 · 사이버연수원) ·
--     진급자 어학성적 평가 · 임원 보수 칸 · 원격근무제(공시 사용자 0 · 자기 출처 문장 없음).
--   공고 근거 0행 / 전체 21행.
--   SORT 섹션 순서 = 정본 페이지 등장 순(growth 10 · compensation 20 · family 30 · leisure 40 · time_off 50 ·
--     perks 60 · health 70), 보조 출처에만 있는 flexibility 80 · work_env 90.
-- 검증 · 감사 판정 반영(2026-10-15): 복리후생 목록 자기계발 지원의 사내교육 몫과 인재 육성 교육 표 사이버연수원(사내)을 edu_support 1행으로 추가(참고 블록 제외 줄의 사이버연수원은 이 판정으로 뒤집힘) · 참고 블록의 공고 근거 0행 / 전체 21행은 전체 22행 — 최종 22행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('ls_materials', 'LS머트리얼즈',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '전자부품', 'L', 'https://www.lsmaterials.co.kr/kr/recruitment/personnel_system.html');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'ls_materials');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.lsmaterials.co.kr/kr/recruitment/personnel_system.html'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 성장 (growth) — 인사제도 인재 육성 교육 · 복리후생 ──
  (@comp_id, 'lang', '외국어 교육 지원 (전화 외국어·어학 검정·교육비)', NULL, 'growth',
   'est', NULL, TRUE, '글로벌 교육: 전화 외국어 지원 · 외국어 어학 검정 지원 · 외국어 교육비 지원 (공식 채용 페이지 인사제도 인재 육성 교육 항목), 자기계발 지원: 외국어 학원 등 지원 (공식 채용 페이지 인사제도 복리후생 항목) — 언어·지원 한도·대상 미기재', 10),
  (@comp_id, 'edu_support', '자기계발 지원 (사내교육·사이버연수원)', NULL, 'growth',
   'est', NULL, TRUE, '자기계발 지원: 사내교육 등 지원 (공식 채용 페이지 인사제도 복리후생 항목), 사이버연수원(사내) (공식 채용 페이지 인사제도 인재 육성 교육 항목) — 개설 과정·수강 대상·비용 부담 미기재', 11),
  -- ── 보상 (compensation) — 인사제도 평가/보상 · 복리후생 ──
  (@comp_id, 'incentive', '성과급 (PI·PS)', NULL, 'compensation',
   'est', NULL, TRUE, '구성원들의 성과 목표 달성과 역량 향상을 유인하기 위해 성과급 제도를 운영 (공식 채용 페이지 인사제도 평가/보상 항목), 성과급 지급(PI/PS)을 통해 직원들의 목표달성과 성과향상을 유인 (공식 채용 사이트 인사 제도 평가/보상 항목) — 지급 기준·지급률 미기재', 20),
  (@comp_id, 'excellence_award', '우수사원 포상', NULL, 'compensation',
   'est', NULL, TRUE, '포상제도 운영: 우수사원 포상 (공식 채용 페이지 인사제도 복리후생 항목, 공식 채용 사이트 인사 제도 복리후생 항목) — 포상 기준·포상 내용 미기재', 21),
  (@comp_id, 'long_service_bonus', '장기근속 포상', NULL, 'compensation',
   'est', NULL, TRUE, '포상제도 운영: 장기근속 포상 (공식 채용 페이지 인사제도 복리후생 항목, 공식 채용 사이트 인사 제도 복리후생 항목), 장기근속 임직원에게 지급하는 장기종업원급여 (2026 반기보고서 재무제표 주석 장기종업원급여충당부채 항목) — 근속 기준·포상 내용·금액 미기재', 22),
  -- ── 가족 (family) — 인사제도 복리후생 · 지속가능경영 인적자본 ──
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '경조사 지원 (공식 채용 페이지 인사제도 복리후생 항목, 공식 채용 사이트 인사 제도 복리후생 항목) — 경조 종류·지원 금액 미기재', 30),
  (@comp_id, 'child_edu', '자녀 학자금 (중·고·대학교)', NULL, 'family',
   'est', NULL, TRUE, '학자금 지원: 자녀 중/고/대학교 학자금 (공식 채용 페이지 인사제도 복리후생 항목, 공식 채용 사이트 인사 제도 복리후생 항목) — 지원 한도·자녀 수 제한 미기재', 31),
  (@comp_id, 'parenting', '출생 축하 지원금 (자녀·손자녀 출산 시 최대 1천만원)', NULL, 'family',
   'est', NULL, TRUE, '출생 축하 지원금 운영: 임직원 자녀/손자녀 출산 시 축하금(최대 1천만원) 지급 (공식 채용 페이지 인사제도 복리후생 항목), 자녀 및 손자녀 출산 시 출생 축하 및 양육 지원금을 지급 (공식 지속가능경영 인적자본 페이지 생애주기별 맞춤 보장 항목) — 축하금 지급 기준·양육 지원금 금액·지급 기간 미기재', 32),
  -- ── 여가 (leisure) — 인사제도 복리후생 ──
  (@comp_id, 'resort', '숙박비 지원 (호텔·콘도)', NULL, 'leisure',
   'est', NULL, TRUE, '숙박비 지원: 호텔/콘도 등 비용 지원 (공식 채용 페이지 인사제도 복리후생 항목), 호텔/콘도 등 이용 시 비용 지원 (공식 채용 사이트 인사 제도 복리후생 항목) — 지원 한도·이용 횟수 미기재', 40),
  (@comp_id, 'club', '사내 동호회 (봉사·풋살·레포츠회 등)', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 운영: 봉사/풋살/레포츠회 등 (공식 채용 페이지 인사제도 복리후생 항목), 봉사/풋살/레포츠회 등 동호회(인포멀) 운영 (공식 채용 사이트 인사 제도 복리후생 항목) — 활동비 지원 금액·가입 조건 미기재', 41),
  (@comp_id, 'company_event', '야유회 (연 1회)', NULL, 'leisure',
   'est', NULL, TRUE, '야유회 실시: 연 1회 실시 (공식 채용 페이지 인사제도 복리후생 항목), 직원 단합을 위한 야유회 실시 (공식 채용 사이트 인사 제도 복리후생 항목) — 참가 대상·비용 지원 범위 미기재', 42),
  -- ── 휴가 (time_off) — 인사제도 복리후생 ──
  (@comp_id, 'summer_leave', '하계휴가 (유급 5일)', NULL, 'time_off',
   'est', NULL, TRUE, '휴가 제도: 하계휴가 (유급 5일) 부여 (공식 채용 페이지 인사제도 복리후생 항목), 하계휴가 (공식 채용 사이트 인사 제도 복리후생 휴가/유연근무제 항목) — 사용 시기·부여 대상 미기재', 50),
  (@comp_id, 'long_service_leave', '장기근속 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속 휴가 (공식 채용 사이트 인사 제도 복리후생 휴가/유연근무제 항목) — 근속 기준·휴가 일수·부여 조건 미기재', 51),
  -- ── 생활 · 편의 (perks) — 인사제도 복리후생 ──
  (@comp_id, 'meal', '구내식당 (조·중·석식 무료 제공)', 864, 'perks',
   'est', '구내식당 운영: 조/중/석/야식 무료 제공 (공식 채용 페이지 인사제도 복리후생 항목) — 식대 단가 미기재 (하루 3끼 × 1끼 12,000원 × 연 240일 추정, 야식 제외)', FALSE, NULL, 60),
  (@comp_id, 'housing_loan', '주택자금 지원 (주택구입·전세자금)', NULL, 'perks',
   'est', NULL, TRUE, '주택자금 지원: 주택구입/전세자금 지원 (공식 채용 페이지 인사제도 복리후생 항목, 공식 채용 사이트 인사 제도 복리후생 항목) — 지원 방식·한도·이율·대상 미기재', 61),
  (@comp_id, 'birthday_gift', '생일자 선물', NULL, 'perks',
   'est', NULL, TRUE, '생일 등 지원 (공식 채용 페이지 인사제도 복리후생 경조사 지원 항목), 생일자 선물대 등 지원 (공식 채용 사이트 인사 제도 복리후생 경조사 지원 항목) — 선물 품목·금액 미기재', 62),
  -- ── 건강 (health) — 인사제도 복리후생 · 지속가능경영 인적자본 ──
  (@comp_id, 'medical', '본인·가족 의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '의료비 지원: 본인/가족의료비 지원 (공식 채용 페이지 인사제도 복리후생 항목, 공식 채용 사이트 인사 제도 복리후생 항목) — 지원 범위·한도·가족 범위 미기재', 70),
  (@comp_id, 'health_check', '종합검진 (임직원·배우자)', NULL, 'health',
   'est', NULL, TRUE, '건강검진 지원: 종합검진 실시(임직원/배우자) (공식 채용 페이지 인사제도 복리후생 항목, 공식 채용 사이트 인사 제도 복리후생 항목) — 검진 주기·검진 항목·비용 지원 범위 미기재', 71),
  (@comp_id, 'fitness', '헬스장·샤워실 운영', NULL, 'health',
   'est', NULL, TRUE, '헬스장/샤워실 운영: 사내 복지시설 운영 (공식 채용 페이지 인사제도 복리후생 항목), 샤워장/헬스장 등 운영 (공식 채용 사이트 인사 제도 복리후생 사내 복지시설 운영 항목) — 운영 시간·이용 조건 미기재', 72),
  (@comp_id, 'insurance', '단체상해보험 (전 직원 가입)', NULL, 'health',
   'est', NULL, TRUE, '단체상해보험 가입: 전직원 가입 (공식 채용 페이지 인사제도 복리후생 항목), 직원 단체상해보험 가입 (공식 지속가능경영 인적자본 페이지 임직원 웰빙 및 종합 케어 항목) — 보장 범위·보험금 한도 미기재', 73),
  -- ── 근무 유연성 (flexibility) — 채용 사이트 · 인적자본 · 2026 반기보고서 ──
  (@comp_id, 'flex_work', '유연근무제 (시차출퇴근제·탄력적 근로시간제)', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제 시행 (공식 채용 사이트 인사 제도 복리후생 휴가/유연근무제 항목), 시차 출퇴근제, 탄력적 근로시간제 등 개별 상황에 맞춘 유연한 일과 생산성을 장려 (공식 지속가능경영 인적자본 페이지 유연한 근무 제도 항목), 시차출퇴근제 사용자 수 1명 (2026 반기보고서 유연근무제도 사용 현황 항목) — 출퇴근 시간대·적용 대상 미기재', 80),
  -- ── 근무환경 (work_env) — 채용 사이트 ──
  (@comp_id, 'nap_room', '수유실', NULL, 'work_env',
   'est', NULL, TRUE, '수유실 등 운영 (공식 채용 사이트 인사 제도 복리후생 사내 복지시설 운영 항목) — 설치 사업장·이용 조건 미기재', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
