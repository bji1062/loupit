-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- DB손해보험 복리후생 데이터
-- 출처: AI 파싱 (2026-10-04)
-- URL: https://www.idbins.com/pc/bizxpress/cmy/adp/FWCOMV1732.shtm
-- badge: est
--
-- 참고:
--   정본은 DB손해보험 자기 도메인 회사 소개의 「급여 및 복리후생」 페이지 /pc/bizxpress/cmy/adp/FWCOMV1732.shtm 다.
--   주어는 「DB손해보험 가족의 삶의 질적 향상을 위하여」 — 이 법인 자기 문장이라 그룹 각주 없음.
--   idbins.com 은 robots.txt 가 전면 금지라 자동 수집기가 읽지 않는다. 원문 = 사이트 운영자가 2026-10-04 브라우저로
--   페이지를 열어 붙여 넣은 화면 본문(사본 db_insurance/user_paste_FWCOMV1732_2026-10-04.txt · sha256 bcddfb20…d741).
--   목차 13항목(급여 · 선택적 복리후생제 · 휴가제도 · 하계휴양소 · 콘도 · 주택구입/전세자금 대출 · 소액신용대출 ·
--   사택 대여금 · 연고지 왕래 교통비 · 학자금 · 의료비 · 사내 동호회 · 기타).
--   보조 출처: OpenDART 2025 사업보고서(기재정정 20260331003904) · 2026 반기보고서(20260814003682) 3행 —
--     직원 등 현황 유연근무제도 사용 현황(remote_work · flex_work) · 보수 산정기준의 전 임직원 생산성향상격려금(incentive).
--     보고서 근거 행은 서술 괄호에 보고서 이름을 적어 구분했다.
--   귀속: 법인 자기 도메인 · 법인 공시만 썼다. DB Inc. · DB하이텍 · DB생명 · DB증권 등 형제 · 종속 법인 문장 0.
--   금액: 원문 고정 금액 0 — 유치원 월 15만원 범위 · 고교 전액(연간 400만) · 암진단비 2천만원 · 입원의료비 1천만원 한도는
--     범위 · 한도라 금액 칸에 넣지 않고 서술에 그대로 적었다. 구본 추정치 4행 승계(health_check 100 · medical 100 ·
--     resort 50 · welfare_point 200 — 붙여넣기 원문이 같은 제도를 확인 · 다른 회사 틀 값 · medical 은 한도 안 · 서술 끝 추정 표지).
--   제외: 법정 제도(연차 15일과 가산 · 출산 전후 90일 · 유산/사산 휴가 · 태아검진 휴가 · 배우자 출산 휴가 20일 ·
--     보건 휴가 · 난임 휴가 6일 · 가족 돌봄 휴가 10일) · 자격수당 · 직책수당 · 교통비(급여 항목의 급여성 지급) ·
--     사내근로복지기금 출연 · 자기주식 증여 공시(기금 대출 행으로 흡수, 회사 전체 규모라 행 아님).
--   1,000인 이상 사업장(2025 직원 4,716명). 원문에 재취업 지원 문구 없음.
--   SORT 섹션 순서 = 붙여넣기 원문에서 카테고리가 처음 나온 순서, 공시 근거 행은 끝
--     (perks 10 · time_off 20 · family 30 · health 40 · leisure 50 · work_env 60 · growth 70 · flexibility 80 · compensation 90).
-- 재수집(2026-10-04): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-04, RV-3-6 레인 5b): 급여 항목 교통비를 transport 서술에서 뺌 · 구본 추정치 4행 승계(리드 판정 (58)) — 최종 19행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('db_insurance', 'DB손해보험',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '보험', 'D', 'https://www.idbins.com/pc/bizxpress/cmy/adp/FWCOMV1732.shtm');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'db_insurance');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.idbins.com/pc/bizxpress/cmy/adp/FWCOMV1732.shtm'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 경제적 부가혜택 (perks) — 선택적 복리후생제 · 주택구입/전세자금 대출 · 소액신용대출 · 연고지 왕래 교통비 · 기타 ──
  (@comp_id, 'transport', '연고지 왕래 교통비·P직급 이상 차량 유지비', NULL, 'perks',
   'est', NULL, TRUE, '비연고지에 발령받아 가족과 떨어져 근무 중인 직원에게 매주 해당 연고지(배우자 및 직계자녀 거주지로 제한) 왕복 교통비를 거리별 차등 지급 (공식 홈페이지 급여 및 복리후생 연고지 왕래 교통비 지원 항목), P직급(5년차 이상 수석) 이상 차량 유지비 지원 (같은 페이지 기타 항목) — 교통비·차량 유지비 지급액 미기재', 10),
  (@comp_id, 'welfare_point', '선택적 복리후생제(복지포인트)', 200, 'perks',
   'est', '전 직원 대상으로 개인의 필요 내지 기호에 따라 복지 항목 및 수혜수준을 스스로 선택하여 사용할 수 있는 제도 (공식 홈페이지 급여 및 복리후생 선택적 복리후생 제도 항목) — 포인트 금액·지급 주기 미기재 (추정)', FALSE, NULL, 11),
  (@comp_id, 'housing_loan', '주택구입자금 및 전세자금 대출', NULL, 'perks',
   'est', NULL, TRUE, '무주택 직원이 국민주택 규모 이하의 주택을 신축, 분양받거나 임차하고자 할 때 필요한 자금을 장기저리로 대출, 3년 이상 근무한 기혼 세대주 대상 (공식 홈페이지 급여 및 복리후생 주택구입자금 및 전세자금 대출 항목) — 대출 한도·금리 미기재', 12),
  (@comp_id, 'welfare_fund_loan', '소액신용대출', NULL, 'perks',
   'est', NULL, TRUE, '1년 이상 근무 중인 직원 대상 사내근로기금을 통한 소액대출 시행 (공식 홈페이지 급여 및 복리후생 소액신용 대출 항목) — 대출 용도·한도·금리 미기재', 13),

  -- ── 시간·휴가 (time_off) — 휴가제도 근속 휴가 · 질병 휴가 · 기타 장기 근속 · 본인 생일 ──
  (@comp_id, 'long_service_leave', '근속 휴가·장기 근속자 포상', NULL, 'time_off',
   'est', NULL, TRUE, '근속기간에 따른 휴가(10년/15년/20년/25년 근속 5일, 30년/35년 근속 10일)와 휴가보조비 지급 (공식 홈페이지 급여 및 복리후생 휴가제도 근속 휴가 항목), 장기 근속자 포상 및 휴가비 지원 (같은 페이지 기타 장기 근속 항목) — 휴가보조비·포상 금액 미기재', 20),
  (@comp_id, 'leave_general', '질병 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '질병·상해 발생 시 질병 휴가, 연간 휴가 사용 후 2개월까지 (공식 홈페이지 급여 및 복리후생 휴가제도 질병 휴가 항목) — 유급 여부 미기재', 21),
  (@comp_id, 'birthday_leave', '본인 생일 반일 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '본인 생일에 반일 휴가 부여 (공식 홈페이지 급여 및 복리후생 기타 본인 생일 반일 휴가 항목)', 22),

  -- ── 가족·돌봄 (family) — 경조 휴가 · 경조금 지급 · 학자금 지원 · 자녀입학 축하선물 · 임신/출산선물 ──
  (@comp_id, 'event', '경조금·경조 휴가', NULL, 'family',
   'est', NULL, TRUE, '대소 경조사 시 규정에 따라 휴가 및 경조금 지급 (공식 홈페이지 급여 및 복리후생 휴가제도 경조 휴가 · 기타 경조금 지급 항목) — 경조 사유별 휴가 일수·경조금 금액 미기재', 30),
  (@comp_id, 'child_edu', '자녀 학자금 지원(유치원·고교·대학)', NULL, 'family',
   'est', NULL, TRUE, '만 4세 이상 미취학 자녀 유치원 월 15만원 범위 2년, 고교 재학 중인 자녀 전액(연간 400만) 3년(12학기), 대학(2년제 포함) 재학 중인 자녀 전액 4년(8학기), 자녀 인원 제한 없음 (공식 홈페이지 급여 및 복리후생 학자금 지원 항목)', 31),
  (@comp_id, 'parenting', '자녀입학 축하선물·임신/출산 선물', NULL, 'family',
   'est', NULL, TRUE, '자녀의 초·중·고·대학교 입학 시 축하선물 지급, 직원 임신/출산 시와 직원의 배우자 출산 시 축하 선물 지급 (공식 홈페이지 급여 및 복리후생 기타 자녀입학 축하선물 · 임신/출산선물 항목) — 선물 품목·금액 미기재', 32),

  -- ── 건강·의료 (health) — 휴가제도 건강검진 휴가 · 기타 건강진단 · 의료비 지원 ──
  (@comp_id, 'health_check', '정밀 건강진단·건강검진 휴가', 100, 'health',
   'est', '매년 정밀 건강진단 실시(배우자 포함) (공식 홈페이지 급여 및 복리후생 기타 건강진단 항목), 본인 건강검진을 위한 휴가 1일 부여 (같은 페이지 휴가제도 건강검진 휴가 항목) — 검진 항목·비용 미기재 (추정)', FALSE, NULL, 40),
  (@comp_id, 'medical', '의료비 지원', 100, 'health',
   'est', '불의의 질병 등으로 지출되는 과다한 의료비 지원, 임직원 본인 및 배우자·자녀 대상, 지원 항목 암진단비 2천만원·입원의료비 1천만원 한도 (공식 홈페이지 급여 및 복리후생 의료비 지원 항목) — 연간 지원액 미기재 (추정)', FALSE, NULL, 41),

  -- ── 여가·라이프 (leisure) — 하계휴양소 설치 · 콘도 운영 · 사내 동호회 ──
  (@comp_id, 'resort', '하계휴양소·콘도 운영', 50, 'leisure',
   'est', '하계 휴가기간 중 직원의 선호도를 감안하여 전국 주요 관광지에 휴양소 운영 (공식 홈페이지 급여 및 복리후생 하계휴양소 설치 항목), 설악·낙산·양평·청평·단양·용인·용평·수안보·경주·부산·남원·무주·통영·원주·제주 등 전국 20여 개 지역 콘도를 연중 본인 필요 시 사전 신청 후 이용 (같은 페이지 콘도 운영 항목) — 이용 비용·횟수 미기재 (추정)', FALSE, NULL, 50),
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '사진·테니스·등산·낚시·사이클·마라톤·인라인스케이트·축구·스키/스노우보드 등 40여 개 동호회, 행사에 소요되는 직접 경비 지원 (공식 홈페이지 급여 및 복리후생 사내 동호회 항목)', 51),

  -- ── 근무환경 (work_env) — 사택 대여금 ──
  (@comp_id, 'dormitory', '사택 대여(비연고지 근무)', NULL, 'work_env',
   'est', NULL, TRUE, '비연고지에 발령을 받아 가족과 떨어져 근무하는 직원에게 사택을 대여 (공식 홈페이지 급여 및 복리후생 사택 대여금 항목) — 사택 형태·입주 기간·비용 부담 미기재', 60),

  -- ── 성장·교육 (growth) — 기타 지원 ──
  (@comp_id, 'self_development', '조사연구비 지원(P직급 이상)', NULL, 'growth',
   'est', NULL, TRUE, 'P직급(5년차 이상 수석) 이상 조사연구비 지원 (공식 홈페이지 급여 및 복리후생 기타 항목) — 지원 금액·사용 범위 미기재', 70),

  -- ── 근무 유연성 (flexibility) — 사업보고서 · 반기보고서 직원 등 현황 유연근무제도 사용 현황 ──
  (@comp_id, 'remote_work', '원격근무제(재택근무 포함)', NULL, 'flexibility',
   'est', NULL, TRUE, '원격근무제(재택근무 포함) 도입·활용, 사용자 2025년 36명 · 2026년 상반기 1명 (2025 사업보고서 · 2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 80),
  (@comp_id, 'flex_work', '시차출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제로 시차출퇴근제 도입·활용, 사용자 2023~2025년 0명 · 2026년 상반기 0명 (2025 사업보고서 · 2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 대상·출퇴근 시간대 미기재', 81),

  -- ── 보상·금전 (compensation) — 사업보고서 · 반기보고서 보수 산정기준 ──
  (@comp_id, 'incentive', '생산성향상격려금', NULL, 'compensation',
   'est', NULL, TRUE, '전 임직원을 대상으로 2025년도 경영목표 달성에 대한 격려 및 2026년 경영목표 달성을 위한 동기부여 차원에서 생산성향상격려금 지급 (2026 반기보고서 · 2025 사업보고서 임원 개인별 보수 산정기준 항목) — 지급 기준·지급률 미기재', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
