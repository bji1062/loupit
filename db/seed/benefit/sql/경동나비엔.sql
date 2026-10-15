-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 경동나비엔 복리후생 데이터 (신규 회사 — 웨이브 7)
-- 출처: AI 파싱 (2026-10-14)
-- URL: https://www.kdnavien.co.kr/ko/talent
-- badge: est
--
-- 참고:
--   정본 = 경동나비엔 자기 도메인 인재경영 · 채용 페이지 복리후생제도 10항목(SSR · 원본 HTML 본문에 항목 텍스트).
--   보조 1 = 2025 경동나비엔 지속가능경영보고서(국문 PDF · 게시 2026-06-30 · 보고 기간 2025-01-01~12-31 · 비재무 성과는
--     경동나비엔 국내 사업장 별도 기준) 72쪽 복리후생 표 · 67쪽 노사화합 활동 · 68쪽 교육 체계도 · 90쪽 품질 포상 체계.
--     PDF 는 kdnavien.co.kr ESG 보고서 목록에서 링크된 static.navienhouse.com(자사 공식몰 정적 호스트) 파일.
--   보조 2 = 2026 반기보고서(접수 20260814003740) 재무제표 주석 상여충당부채 문장 · 직원 등 현황 유연근무제도 사용 현황 표.
--   보조 3 = 경동 그룹 통합 채용 사이트 recruit.kdfamily.co.kr 인사제도 및 복리후생(법인 구분 없음 · 기등록 경동 계열 0).
--     법인 자료에 없는 3행(리프레시 휴가 · 장기근속 포상 · 가정의 날)만 서술 끝에 (그룹 통합 채용 기준) 각주.
--   귀속: 정본 · 보고서 · 공시 근거 행은 각주 없음(보고서 72쪽 주어 경동나비엔은).
--   금액: 원문에 원 단위 숫자 없음 — 금액 행 0(stated 0 · 추정 0). 식대 원문 없음.
--   제외: 출산 · 육아휴가 · 가족돌봄 휴가 · 휴직(법정) · 직무 · 리더십 · 신규입사자 · 법정 의무 교육(업무 교육) ·
--     대리점 · 협력사 대상 지원(다른 대상) · 기후변화 KPI 인센티브(부서 KPI) · 우리사주조합(주주 표 한 칸) ·
--     시차출퇴근제 · 원격근무제(공시 표 사용자 0명) · 그룹 페이지의 법인 자료와 겹치는 항목.
--   공고 근거 0행 / 전체 26행.
--   SORT 섹션 순서(정본 페이지 첫 등장): time_off 10 · health 20 · perks 30 · family 40 · leisure 50 · work_env 60,
--     보조 출처만: compensation 70 · flexibility 80 · growth 90.
-- 검증 · 감사 판정 반영(2026-10-14): 건강검진 행에서 법정 건강진단 구절 걷기 — 최종 26행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('kyungdong_navien', '경동나비엔',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '생활가전/렌탈', 'K', 'https://www.kdnavien.co.kr/ko/talent');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'kyungdong_navien');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.kdnavien.co.kr/ko/talent'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 휴가 (time_off) — 공식 인재경영 페이지 · 2025 지속가능경영보고서 · 그룹 채용 사이트 ──
  (@comp_id, 'summer_leave', '여름휴가 (유급 5일)', NULL, 'time_off',
   'est', NULL, TRUE, '연차와 별도인 年 5일 유급휴가 제공 (공식 인재경영 페이지 복리후생제도 여름휴가 항목), 유급 하계휴가 매년 여름 5일 (2025 지속가능경영보고서 72쪽 복리후생 항목) — 사용 시기 미기재', 10),
  (@comp_id, 'leave_general', '시간 단위 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '유연한 근무환경 조성을 위해 시간 단위 휴가 사용 지원 (2025 지속가능경영보고서 72쪽 복리후생 항목) — 사용 한도·신청 절차 미기재', 11),
  (@comp_id, 'refresh_leave', '리프레시 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '리프레시 휴가 제도 운영, 리프레시 휴가 이용 장려 (경동 채용 사이트 인사제도 및 복리후생 항목) — 휴가 일수·부여 조건 미기재 (그룹 통합 채용 기준)', 12),
  (@comp_id, 'long_service_leave', '장기근속 포상·포상휴가', NULL, 'time_off',
   'est', NULL, TRUE, '10년·20년·25년·30년 근속 포상, 20년·25년 포상휴가, 20년 부부동반 해외여행 등 (경동 채용 사이트 인사제도 및 복리후생 장기근속 포상 항목) — 포상 금액·휴가 일수 미기재 (그룹 통합 채용 기준)', 13),
  -- ── 건강 (health) — 공식 인재경영 페이지 · 2025 지속가능경영보고서 ──
  (@comp_id, 'health_check', '건강검진 지원', NULL, 'health',
   'est', NULL, TRUE, '임직원 건강검진 비용 지원 (공식 인재경영 페이지 복리후생제도 건강검진 지원 항목) — 검진 주기·비용 지원 범위 미기재', 20),
  (@comp_id, 'clinic', '건강관리실·물리치료실 (일부 사업장)', NULL, 'health',
   'est', NULL, TRUE, '사내 복지공간 운영 건강관리실·물리치료실, 일부 사업장에 한함 (2025 지속가능경영보고서 72쪽 복리후생 항목) — 운영 사업장·상주 인력 미기재', 21),
  (@comp_id, 'fitness', '헬스장 (일부 사업장)', NULL, 'health',
   'est', NULL, TRUE, '사내 복지공간 운영 헬스장, 일부 사업장에 한함 (2025 지속가능경영보고서 72쪽 복리후생 항목) — 운영 사업장·이용 시간 미기재', 22),
  -- ── 생활 지원 (perks) — 공식 인재경영 페이지 · 2025 지속가능경영보고서 ──
  (@comp_id, 'housing_loan', '사내근로복지기금 주택·생활자금 대출', NULL, 'perks',
   'est', NULL, TRUE, '사내근로복지기금 운영으로 주택 관련 자금 및 생활 필요 자금 대출 (공식 인재경영 페이지 복리후생제도 사내근로복지기금운영 항목), 사내대출제도 (2025 지속가능경영보고서 72쪽 복리후생 항목) — 대출 한도·이율 미기재', 30),
  (@comp_id, 'discount', '사원판매 할인', NULL, 'perks',
   'est', NULL, TRUE, '보일러·온수매트·환기청정기 등 사내 제품 임직원 할인 (공식 인재경영 페이지 복리후생제도 사원판매 할인 항목), 회사제품 할인 (2025 지속가능경영보고서 72쪽 복리후생 항목) — 할인율 미기재', 31),
  (@comp_id, 'snack_bar', '사내카페 (사업장별)', NULL, 'perks',
   'est', NULL, TRUE, '사업장별 사내카페 운영 (2025 지속가능경영보고서 72쪽 복리후생 항목) — 운영 사업장·이용 비용 미기재', 32),
  (@comp_id, 'commute_subsidy', '출퇴근 셔틀버스 (일부 사업장)', NULL, 'perks',
   'est', NULL, TRUE, '출퇴근 셔틀버스 운영, 일부 사업장에 한함 (2025 지속가능경영보고서 72쪽 복리후생 항목) — 운행 사업장·노선 미기재', 33),
  (@comp_id, 'birthday_gift', '생일 선물포인트', NULL, 'perks',
   'est', NULL, TRUE, '생일 선물포인트 지급 (2025 지속가능경영보고서 72쪽 복리후생 항목) — 포인트 규모 미기재', 34),
  -- ── 가족 (family) — 공식 인재경영 페이지 · 2025 지속가능경영보고서 ──
  (@comp_id, 'child_edu', '자녀 학자금 지원 (대학교)', NULL, 'family',
   'est', NULL, TRUE, '대학교 자녀 학자금 지원 (공식 인재경영 페이지 복리후생제도 자녀 학자금 지원 항목), 학자금 지원 (2025 지속가능경영보고서 72쪽 복리후생 항목) — 지원 한도·자녀 수 제한 미기재', 40),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '임직원 경조사 시 규정에 따라 휴가·경조금·경조 용품 지급 (공식 인재경영 페이지 복리후생제도 경조금 지원 항목), 경조사 지원 휴가 및 경조금 (2025 지속가능경영보고서 72쪽 복리후생 항목) — 경조 유형별 금액·휴가 일수 미기재', 41),
  (@comp_id, 'parenting', '영유아 위탁보육료 지원', NULL, 'family',
   'est', NULL, TRUE, '영유아 위탁보육료 지원 (공식 인재경영 페이지 복리후생제도 위탁보육료 지원 항목), 위탁보육료 지원·영유아보육지원 (2025 지속가능경영보고서 72쪽 복리후생 항목) — 지원 금액·대상 연령 미기재', 42),
  -- ── 여가 (leisure) — 공식 인재경영 페이지 · 2025 지속가능경영보고서 ──
  (@comp_id, 'resort', '회사 콘도 지원', NULL, 'leisure',
   'est', NULL, TRUE, '휴양지 법인 콘도 이용, 별도 심사에 따름 (공식 인재경영 페이지 복리후생제도 회사 콘도 지원 항목), 콘도회원권 제공 (2025 지속가능경영보고서 72쪽 복리후생 항목) — 이용 일수·비용 부담 미기재', 50),
  (@comp_id, 'club', '동호회 운영·활동비 지원', NULL, 'leisure',
   'est', NULL, TRUE, '사내동호회 운영 및 동호회 활동비 지원 (공식 인재경영 페이지 복리후생제도 동호회 운영 항목), 동호회 지원금 제공 (2025 지속가능경영보고서 72쪽 복리후생 항목) — 지원 금액 미기재', 51),
  (@comp_id, 'company_event', '사내 체육 행사·창립기념 행사', NULL, 'leisure',
   'est', NULL, TRUE, '연 2회 전 임직원 및 협력사 직원 대상 노사 공동 운영 사내 체육 행사(2025년 척사대회, 다트 던지기 대회), 제47주년 창립기념 행사 체육대회 진행 (2025 지속가능경영보고서 67쪽 노사화합 활동 항목)', 52),
  -- ── 근무 환경 (work_env) — 공식 인재경영 페이지 · 2025 지속가능경영보고서 ──
  (@comp_id, 'dormitory', '사내 기숙사 지원 (공장)', NULL, 'work_env',
   'est', NULL, TRUE, '원거리 거주자를 위한 사원 숙소 지원(공장) (공식 인재경영 페이지 복리후생제도 사내 기숙사 지원 항목) — 입주 자격·비용 부담 미기재', 60),
  (@comp_id, 'lounge', '여성 휴게실 (일부 사업장)', NULL, 'work_env',
   'est', NULL, TRUE, '사내 복지공간 운영 여성 휴게실, 일부 사업장에 한함 (2025 지속가능경영보고서 72쪽 복리후생 항목) — 운영 사업장·시설 규모 미기재', 61),
  -- ── 보상 (compensation) — 2026 반기보고서 · 2025 지속가능경영보고서 ──
  (@comp_id, 'profit_sharing', '경영실적 연동 상여', NULL, 'compensation',
   'est', NULL, TRUE, '임직원을 대상으로 당 회계연도의 경영실적 및 규정에 따라 상여 지급 (2026 반기보고서 재무제표 주석 충당부채 항목) — 지급 기준·지급률 미기재', 70),
  (@comp_id, 'excellence_award', '품질 기여도 포상·우수 임직원 포상', NULL, 'compensation',
   'est', NULL, TRUE, '품질 개선 우수 포상·불량 검출 포상·본부 3대 혁신 포상·품질 반성회 포상 등 4개 영역의 품질 기여도 기반 포상 체계 (2025 지속가능경영보고서 90쪽 품질경영 항목), 창립기념 행사 우수 임직원 포상 (2025 지속가능경영보고서 67쪽 노사화합 활동 항목) — 포상 기준·포상 내용 미기재', 71),
  (@comp_id, 'holiday_gift', '명절 선물포인트', NULL, 'compensation',
   'est', NULL, TRUE, '명절 선물포인트 지급 (2025 지속가능경영보고서 72쪽 복리후생 항목) — 포인트 규모·지급 시기 미기재', 72),
  -- ── 근무 유연성 (flexibility) — 2026 반기보고서 · 그룹 채용 사이트 ──
  (@comp_id, 'flex_work', '선택근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '선택근무제 (2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 80),
  (@comp_id, 'family_day', '가정의 날 (정시퇴근)', NULL, 'flexibility',
   'est', NULL, TRUE, '가정의 날 운영, 매주 수요일·금요일 정시퇴근 운영 (경동 채용 사이트 인사제도 및 복리후생 항목) — 적용 사업장 미기재 (그룹 통합 채용 기준)', 81),
  -- ── 성장 (growth) — 2025 지속가능경영보고서 ──
  (@comp_id, 'lang', '어학 과정 (전화영어·이러닝)', NULL, 'growth',
   'est', NULL, TRUE, '어학 과정(전화영어, 이러닝 등) (2025 지속가능경영보고서 68쪽 교육 체계도 항목) — 수강 대상·비용 부담 미기재', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
