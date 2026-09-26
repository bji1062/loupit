-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SK이노베이션 복리후생 데이터
-- 출처: AI 파싱 (2026-09-26)
-- URL: https://www.skinnovation.com/recruit/hr_comp
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
--
-- 참고:
--   재수집(2026-09-26): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다 — 대조 보고서 2026-09-25-official-compare
-- 감사(RA-1 2026-09-26) 반영: health_check 100 추정 승계(운영 금액출처 estimated) · 행복연금 문안에서 퇴직연금 낱말 제거 · retirement_support 삭제(법정 재취업지원서비스)
--   정본 = SK이노베이션㈜ 자사 도메인 www.skinnovation.com 의 Career > 인사제도 > 평가/보상 페이지
--     (/recruit/hr_comp, SSR HTML, 복리후생 6묶음). 푸터 법인 = SK이노베이션㈜ 서울 종로구 종로 26 ·
--     사업자등록번호 101-86-32319. 자회사(SK에너지·SK온 등) 페이지가 아니다. robots = Allow: / .
--     국문 본문은 2026-09-26 재요청 결과 sha256 e709bfdb8a9e… 로 09-25 사본과 바이트 동일.
--   보조 = 같은 도메인 /recruit/hr_dev(인재육성: Mental Care·Physical Care·연수 프로그램) 과
--     SK이노베이션 통합보고서 2024 국문 PDF(207쪽, 사이트 지속가능경영보고서 목록의 최신본) 105~106쪽.
--     보고서는 보고 범위가 SK이노베이션 계열이라 주어가 SK이노베이션은 인 문장만 근거로 썼다
--     (SK이노베이션 계열은 주어 문장·장애인표준사업장 자회사·울산CLX/SKIET 한정 서술은 제외).
--   쓰지 않은 후보: recruit.skinnovation.com(403) · skinnovation.recruiter.co.kr(robots 전면 금지) ·
--     www.skcareers.com(SK 그룹 공통 — 이 법인 적용 명시 없음) · esg.skinnovation.com 2025 웹리포트(CSR).
--   정본이 법인 자사 페이지라 그룹 통합 채용 각주는 달지 않았다.
--   금액: 공식 원문 금액 0건. 구본 추정치 중 승계 조건(같은 제도 확인·원문과 무충돌·앵커 규칙)을
--     통과한 4행만 NOTE 에 (추정) 을 붙여 승계(welfare_point 200·medical 100·child_edu 200·resort 50).
--     구본 공식 수치 표기 행(health_check 100·meal 432)과 경조금·성과급 추정치는 승계하지 않았다.
--   구본 26행 → 25행. 재코딩 1(incentive → profit_sharing) · 신규 6 · 삭제 7(NOT_FOUND 6 + edu_support).
--   parenting 행은 legal_rows.json 등록 행이라 BENEFIT_NM 을 바꾸지 않았다(서술만 회사 상회분으로 교체).
--   SORT 섹션 순서 = 정본 복리후생 6묶음에서 카테고리가 처음 나온 순서, 그다음 통합보고서 순서
--     (perks 10 · health 20 · work_env 30 · time_off 40 · family 50 · leisure 60 · growth 70 ·
--      compensation 80 · flexibility 90).
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op, 등록 값은 구본과 동일)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('sk_innovation', 'SK이노베이션',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '에너지/화학', 'S', 'https://www.skinnovation.com/recruit/hr_comp');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'sk_innovation');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.skinnovation.com/recruit/hr_comp'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 경제적 부가혜택 (perks) — 정본 금전적 지원 · 주거 지원 · 기타 ──
  (@comp_id, 'welfare_point', 'SK행복카드', 200, 'perks',
   'est', 'SK행복카드 (공식 인사제도 평가/보상 페이지 복리후생 금전적 지원 항목 — 카드 용도·연간 지급액 미기재) (추정)', FALSE, NULL, 10),
  (@comp_id, 'pension_support', '행복연금 (회사 1:1 매칭 적립)', NULL, 'perks',
   'est', NULL, TRUE, '행복연금 제도 — 구성원 납입액과 회사 지원금을 1:1로 매칭해 연금 계좌에 납입하고 매년 초 지급되는 경영성과금 일부를 추가 납입 (공식 인사제도 평가/보상 페이지 복리후생 금전적 지원 항목 · 통합보고서 2024 106쪽 — 회사 지원 한도 미기재)', 11),
  (@comp_id, 'welfare_fund_loan', '생활안정자금 대부', NULL, 'perks',
   'est', NULL, TRUE, '생활 안정 자금 대부 (공식 인사제도 평가/보상 페이지 복리후생 금전적 지원 항목 — 대부 한도·이율·신청 요건 미기재)', 12),
  (@comp_id, 'housing_loan', '주택 구입·전세 융자', NULL, 'perks',
   'est', NULL, TRUE, '주택 구입 및 전세 융자 (공식 인사제도 평가/보상 페이지 복리후생 주거 지원 항목 · 통합보고서 2024 106쪽 복리후생 지원 — 융자 한도·이율 미기재)', 13),
  (@comp_id, 'meal', '중식·석식 제공', NULL, 'perks',
   'est', NULL, TRUE, '중/석식 제공 (공식 인사제도 평가/보상 페이지 복리후생 기타 항목 — 제공 방식·식대 단가 미기재)', 14),

  -- ── 건강·의료 (health) — 정본 건강 관리 · 취미/레저활동 · 기타 ──
  (@comp_id, 'health_check', '정기 건강검진', 100, 'health',
   'est', '정기 건강검진 (공식 인사제도 평가/보상 페이지 복리후생 건강 관리 항목 — 검진 주기·검진 항목·가족 대상 여부 미기재) (추정)', FALSE, NULL, 20),
  (@comp_id, 'medical', '의료비 지원 (배우자·자녀 포함)', 100, 'health',
   'est', '의료비 지원, 배우자·자녀 포함 (공식 인사제도 평가/보상 페이지 복리후생 건강 관리 항목 — 지원 한도 미기재) (추정)', FALSE, NULL, 21),
  (@comp_id, 'fitness', '피트니스센터', NULL, 'health',
   'est', NULL, TRUE, 'Fitness Center (공식 인사제도 평가/보상 페이지 복리후생 취미/레저활동 항목), 사내 헬스 트레이닝 지원 (공식 인사제도 인재육성 페이지 구성원 Physical Care 항목) — 운영 사업장·이용료 미기재', 22),
  (@comp_id, 'mental', '하모니아 상담코칭 센터', NULL, 'health',
   'est', NULL, TRUE, '하모니아 상담코칭 센터 — 본사·기술원·울산Complex 사업장마다 전문 상담사 1~3명 상주, 업무 스트레스·대인관계 전문 심리상담과 신입 온보딩·경력 개발 코칭, 자녀 방학 프로그램 (공식 인사제도 평가/보상 페이지 복리후생 기타 항목 · 인재육성 페이지 구성원 Mental Care 항목 · 통합보고서 2024 106쪽 정신건강 지원 — 이용 횟수·비용 부담 미기재)', 23),

  -- ── 근무환경 (work_env) — 정본 주거 지원 · 통합보고서 모성 보호 ──
  (@comp_id, 'dormitory', '지방 근무 기숙사·주거비 지원', NULL, 'work_env',
   'est', NULL, TRUE, '지방 근무 시 기숙사 또는 주거비 지원 (공식 인사제도 평가/보상 페이지 복리후생 주거 지원 항목 — 입주 자격·주거비 지원 금액 미기재)', 30),
  (@comp_id, 'nap_room', '모유 수유실·여성 휴게실', NULL, 'work_env',
   'est', NULL, TRUE, '모성 보호를 위한 모유 수유실과 여성 휴게실 운영 (통합보고서 2024 106쪽 모성 보호 제도 운영 — 설치 사업장 미기재)', 31),

  -- ── 시간·휴가 (time_off) — 정본 가정 및 육아 지원 · 통합보고서 ──
  (@comp_id, 'leave_general', '경조휴가', NULL, 'time_off',
   'est', NULL, TRUE, '경조 휴가 (공식 인사제도 평가/보상 페이지 복리후생 가정 및 육아 지원 항목 — 경조 사유별 휴가 일수 미기재)', 40),
  (@comp_id, 'long_service_leave', '근속 포상휴가 (O! Leave)', NULL, 'time_off',
   'est', NULL, TRUE, '10년 주기로 근속 포상휴가와 연계된 O! Leave 제도, 최대 한 달까지 휴식 (통합보고서 2024 106쪽 유연한 근무환경 조성 — 포상휴가 일수·유급 여부 미기재)', 41),

  -- ── 가족·돌봄 (family) — 정본 가정 및 육아 지원 · 통합보고서 모성 보호 ──
  (@comp_id, 'event', '경조금 지원', NULL, 'family',
   'est', NULL, TRUE, '경조금 (공식 인사제도 평가/보상 페이지 복리후생 가정 및 육아 지원 항목 — 경조 사유별 지급액 미기재)', 50),
  (@comp_id, 'parenting', '출산/육아 지원', NULL, 'family',
   'est', NULL, TRUE, '임신 초기 또는 출산 직전 구성원에게 최소 1개월, 최대 3개월의 출산 전 휴직 제공 (통합보고서 2024 106쪽 모성 보호 제도 운영 — 휴직 중 급여 지급 여부 미기재)', 51),
  (@comp_id, 'childcare', '사내 어린이집', NULL, 'family',
   'est', NULL, TRUE, '어린이집 (공식 인사제도 평가/보상 페이지 복리후생 가정 및 육아 지원 항목) · 사내 어린이집 운영 (통합보고서 2024 106쪽 복리후생 지원) — 설치 사업장·정원 미기재', 52),
  (@comp_id, 'child_edu', '자녀 학자금', 200, 'family',
   'est', '자녀 학자금 (공식 인사제도 평가/보상 페이지 복리후생 가정 및 육아 지원 항목 — 대상 학교급·지원 한도 미기재) (추정)', FALSE, NULL, 53),

  -- ── 여가·라이프 (leisure) — 정본 취미/레저활동 ──
  (@comp_id, 'resort', '휴양소·콘도', 50, 'leisure',
   'est', '휴양소·콘도 (공식 인사제도 평가/보상 페이지 복리후생 취미/레저활동 항목 — 이용 방식·지원 금액 미기재) (추정)', FALSE, NULL, 60),
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 활동 지원 (공식 인사제도 평가/보상 페이지 복리후생 취미/레저활동 항목 — 지원 금액 미기재)', 61),

  -- ── 성장·커리어 (growth) — 통합보고서 105~106쪽 · 인재육성 페이지 ──
  (@comp_id, 'mba', '중장기 연수 (MBA·직무 학위)', NULL, 'growth',
   'est', NULL, TRUE, '중장기 연수 제도 — 학습과 역량 개발 의지가 높은 우수 인재 대상 국내외 우수 대학·전문 연구기관의 MBA, 직무 학위 등 연수 프로그램, 교육 파견 또는 일과 학업 병행 (통합보고서 2024 105쪽 중장기 연수 지원 · 공식 인사제도 인재육성 페이지 연수 프로그램 — 선발 기준·인원·비용 지원 범위 미기재)', 70),

  -- ── 보상·금전 (compensation) — 통합보고서 106쪽 ──
  (@comp_id, 'profit_sharing', '경영성과금', NULL, 'compensation',
   'est', NULL, TRUE, '매년 초 경영성과금 지급 (통합보고서 2024 106쪽 행복연금 제도 서술 — 지급 기준·규모 미기재)', 80),

  -- ── 근무유연성 (flexibility) — 통합보고서 106쪽 유연한 근무환경 지원 표 ──
  (@comp_id, 'flex_work', '선택적 근무제 (자율 출퇴근)', NULL, 'flexibility',
   'est', NULL, TRUE, '선택적 근무제 — 자율적으로 출퇴근 시간 조정 가능 (통합보고서 2024 106쪽 유연한 근무환경 지원 — 코어타임·정산 기간 미기재)', 90),
  (@comp_id, 'pc_off', 'PC-off', NULL, 'flexibility',
   'est', NULL, TRUE, '불필요한 초과 근로를 방지하기 위해 일정 시간 초과 시 자동으로 PC 종료 (통합보고서 2024 106쪽 유연한 근무환경 지원 — 종료 기준 시간·예외 절차 미기재)', 91),
  (@comp_id, 'remote_work', '재택근무', NULL, 'flexibility',
   'est', NULL, TRUE, '재택근무 제도와 화상회의·업무 공유 시스템 등 재택근무 인프라 (통합보고서 2024 106쪽 유연한 근무환경 지원 — 허용 일수·신청 조건 미기재)', 92)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
