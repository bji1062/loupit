-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SK온 복리후생 데이터 (신규 회사 — 웨이브 13)
-- 출처: AI 파싱 (2026-10-20)
-- URL: http://www.sk-on.com/recruit/hr_comp.asp
-- badge: est
--
-- 참고:
--   정본 = SK온㈜(DART 에스케이온 · 비상장 · 최대주주 SK이노베이션 90.3%) 자기 도메인 www.sk-on.com 의
--     인재채용 > 인사제도 > 평가/보상 페이지(/recruit/hr_comp.asp, SSR HTML, 보상 절 + 복리후생 6묶음).
--     꼬리말 법인 = SK온㈜ · 사업자등록번호 242-87-02258. robots = Disallow: /data/ 만(허용).
--     https 는 인증서 이름 불일치(*.skenergy.com 인증서)라 http 주소가 정본이다.
--   보조 = 같은 도메인 /recruit/hr_dev.asp(인재육성 — 장기연수) · OpenDART 2025 사업보고서(20260316001423) ·
--     2026 반기보고서(20260814003034) 유연근무제도 사용현황 표 · 주식기준보상 Value Sharing 절.
--   귀속: 법인 자기 도메인 페이지라 각주 없음. 모회사 SK이노베이션 평가/보상 페이지와 같은 틀이지만
--     항목이 다르다(SK온 = SK패밀리 카드 · 장기근속자 포상 · 주거비 지원 / SK이노베이션 = 생활안정자금 대부 등).
--     SK 그룹 채용 사이트 skcareers 에는 SK온 전용 페이지가 없어 쓰지 않았다.
--   금액: stated 0 · 추정 1(meal 576 = 하루 2끼 × 1끼 12,000원 × 연 240일). 나머지 금액 NULL(원문 숫자 없음).
--   제외: 법정(출산/육아 휴직 · 직무발명 보상 제도) · SK패밀리 카드(혜택이 적히지 않은 그룹 카드 이름) ·
--     임원 보수 칸 선택적 복리후생 금액 · PSU(대표이사 · 임원 전용) · 이사회 안건 제목 사내 근로복지기금 출연 ·
--     원격근무제 공시 사용자 전 기간 없음 · 리더 · 차세대 리더 · 직급별 · 직군별 육성(업무 교육).
--   공고 근거 0행 / 전체 19행.
--   SORT 섹션 순서 = 정본 페이지 보상 절 다음 복리후생 6묶음 순(compensation 10 · perks 20 · health 30 ·
--     work_env 40 · family 50 · leisure 60), 보조 출처에만 있는 카테고리(growth 70 · flexibility 80).
-- 검증 · 감사 판정 반영(2026-10-20): Value Sharing stock_grant 서술을 공시 부여 연도(2023~2025) 그대로로 교체 · 2025 사업보고서 환경 및 종업원 등에 관한 사항의 건강관리실 clinic (배터리부문) · 마음건강 관리 프로그램 mental (기유·윤활유부문) 추가 · 장기연수 mba 유지 · SK이노베이션 문장 혼입 0 각주 없음 · 참고 블록 보조 출처 줄과 공고 근거 0행 / 전체 19행은 이 판정으로 뒤집힘(21행) — 최종 21행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('sk_on', 'SK온',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '배터리', 'S', 'http://www.sk-on.com/recruit/hr_comp.asp');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'sk_on');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'http://www.sk-on.com/recruit/hr_comp.asp'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상 · 금전 (compensation) — 정본 보상 절 · 복리후생 기타 · 반기보고서 ──
  (@comp_id, 'incentive', '성과급 제도', NULL, 'compensation',
   'est', NULL, TRUE, '능력주의에 입각한 연봉제 및 성과급 제도, 책정기준 EVA(경제적 부가가치)와 KPI(핵심 성과지표)의 종합적 평가, 역량 및 성과가 우수한 구성원에게 더 많은 보상을 제공 (공식 인사제도 평가/보상 페이지 보상 항목) — 지급 시기·지급률 미기재', 10),
  (@comp_id, 'long_service_bonus', '장기근속자 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속자 포상 (공식 인사제도 평가/보상 페이지 복리후생 기타 항목) — 근속 기준·포상 내용 미기재', 11),
  (@comp_id, 'stock_grant', 'Value Sharing (임직원 주식기준보상)', NULL, 'compensation',
   'est', NULL, TRUE, '임직원 대상 주식기준보상 Value Sharing, 직원은 부여대상자 연봉 평균 30%의 주식 수에 해당하는 조건부가상주식을 2023년부터 2025년까지 매년 부여하고 연단위 개인별 성과 평가결과로 최종 수량 확정, 3년 의무재직과 기업공개 달성 시 보통주로 교환 지급하며 시한(최대 2027년 12월 31일)까지 가득조건 미충족 시 권리 소멸 (2026 반기보고서 주식기준보상 Value Sharing 항목, 2025 사업보고서 별도재무제표 주석 배터리 부문 임직원 Value Sharing 항목) — 부여대상자 선정 기준·2026년 이후 부여 여부 미기재', 12),

  -- ── 생활 · 금융 · 주거 (perks) — 정본 복리후생 금전적 지원 · 주거 지원 · 기타 ──
  (@comp_id, 'welfare_point', 'SK행복카드', NULL, 'perks',
   'est', NULL, TRUE, 'SK행복카드 (공식 인사제도 평가/보상 페이지 복리후생 금전적 지원 항목) — 카드 용도·연간 지급액 미기재', 20),
  (@comp_id, 'pension_support', '개인연금 지원', NULL, 'perks',
   'est', NULL, TRUE, '개인연금지원 (공식 인사제도 평가/보상 페이지 복리후생 금전적 지원 항목) — 회사 지원 비율·한도 미기재', 21),
  (@comp_id, 'housing_loan', '주택 구입·전세 융자', NULL, 'perks',
   'est', NULL, TRUE, '주택 구입 및 전세 융자 (공식 인사제도 평가/보상 페이지 복리후생 주거 지원 항목) — 융자 한도·이율 미기재', 22),
  (@comp_id, 'housing_support', '지방 근무 시 주거비 지원', NULL, 'perks',
   'est', NULL, TRUE, '지방 근무 시 기숙사 또는 주거비 지원 중 주거비 지원 (공식 인사제도 평가/보상 페이지 복리후생 주거 지원 항목) — 지원 금액·지급 방식 미기재', 23),
  (@comp_id, 'meal', '중식·석식 제공', 576, 'perks',
   'est', '구내식당 내 중/석식 제공 (공식 인사제도 평가/보상 페이지 복리후생 기타 항목) — 식대 단가·본인 부담 미기재 (하루 2끼 × 1끼 12,000원 × 연 240일 추정)', FALSE, NULL, 24),

  -- ── 건강 · 의료 (health) — 정본 복리후생 건강 관리 · 취미/레저활동 ──
  (@comp_id, 'health_check', '정기 건강검진', NULL, 'health',
   'est', NULL, TRUE, '정기 건강검진 (공식 인사제도 평가/보상 페이지 복리후생 건강 관리 항목) — 검진 주기·검진 항목·비용 지원 범위 미기재', 30),
  (@comp_id, 'medical', '의료비 지원 (배우자·자녀 포함)', NULL, 'health',
   'est', NULL, TRUE, '의료비 지원, 배우자·자녀 포함 (공식 인사제도 평가/보상 페이지 복리후생 건강 관리 항목) — 지원 한도·지원 범위 미기재', 31),
  (@comp_id, 'fitness', '피트니스 센터', NULL, 'health',
   'est', NULL, TRUE, 'Fitness Center (공식 인사제도 평가/보상 페이지 복리후생 취미/레저활동 항목) — 운영 사업장·이용료 미기재', 32),
  (@comp_id, 'clinic', '건강관리실 (배터리부문)', NULL, 'health',
   'est', NULL, TRUE, '배터리사업 구성원 건강증진을 위한 건강관리실 확대 (2025 사업보고서 환경 및 종업원 등에 관한 사항 배터리사업 항목) — 설치 사업장·운영 방식 미기재', 33),
  (@comp_id, 'mental', '마음건강 관리 프로그램 (기유·윤활유부문)', NULL, 'health',
   'est', NULL, TRUE, '구성원 정신 건강 관리를 위해 마음건강 관리 프로그램 운영 (2025 사업보고서 환경 및 종업원 등에 관한 사항 기유 및 윤활유사업 항목) — 프로그램 내용·이용 방식 미기재', 34),

  -- ── 근무환경 (work_env) — 정본 복리후생 주거 지원 ──
  (@comp_id, 'dormitory', '지방 근무 시 기숙사', NULL, 'work_env',
   'est', NULL, TRUE, '지방 근무 시 기숙사 또는 주거비 지원 중 기숙사 (공식 인사제도 평가/보상 페이지 복리후생 주거 지원 항목) — 입주 자격·운영 사업장 미기재', 40),

  -- ── 가족 · 돌봄 (family) — 정본 복리후생 가정 및 육아 지원 ──
  (@comp_id, 'event', '경조금·경조휴가', NULL, 'family',
   'est', NULL, TRUE, '경조휴가 및 경조금 (공식 인사제도 평가/보상 페이지 복리후생 가정 및 육아 지원 항목) — 경조 사유별 지급액·휴가 일수 미기재', 50),
  (@comp_id, 'childcare', '어린이집', NULL, 'family',
   'est', NULL, TRUE, '어린이집 (공식 인사제도 평가/보상 페이지 복리후생 가정 및 육아 지원 항목) — 설치 사업장·정원·운영 방식 미기재', 51),
  (@comp_id, 'child_edu', '자녀 학자금', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금 (공식 인사제도 평가/보상 페이지 복리후생 가정 및 육아 지원 항목) — 대상 학교급·지원 한도 미기재', 52),

  -- ── 여가 · 행사 (leisure) — 정본 복리후생 취미/레저활동 ──
  (@comp_id, 'resort', '휴양소·콘도', NULL, 'leisure',
   'est', NULL, TRUE, '휴양소·콘도 (공식 인사제도 평가/보상 페이지 복리후생 취미/레저활동 항목) — 이용 방식·지원 금액 미기재', 60),
  (@comp_id, 'club', '사내 동호회 활동 지원', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 활동 지원 (공식 인사제도 평가/보상 페이지 복리후생 취미/레저활동 항목) — 지원 금액·동호회 종류 미기재', 61),

  -- ── 성장 · 교육 (growth) — 같은 도메인 인재육성 페이지 ──
  (@comp_id, 'mba', '장기연수', NULL, 'growth',
   'est', NULL, TRUE, '장기연수를 통한 미래성장 역량 개발 (공식 인사제도 인재육성 페이지 구성원 역량개발 지원 항목) — 연수 형태·대상·선발 기준 미기재', 70),

  -- ── 근무 유연성 (flexibility) — 반기보고서 · 사업보고서 유연근무제도 사용현황 표 ──
  (@comp_id, 'flex_work', '시차출퇴근제·선택근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '시차출퇴근제 사용자 2026년 상반기 311명·2025년 655명·2024년 624명, 선택근무제 사용자 2026년 상반기 2,786명·2025년 2,945명·2024년 2,765명 (2026 반기보고서 · 2025 사업보고서 유연근무제도 사용현황 항목) — 대상 직무·사용 조건 미기재', 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
