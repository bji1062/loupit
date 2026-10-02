-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 두산 복리후생 데이터
-- 출처: AI 파싱 (2026-10-02)
-- URL: https://www.doosan.com/kr/csr/about-csr/?menu=csr-report
-- badge: est
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 참고:
--   ㈜두산은 지주 겸 사업부문(전자BG · 디지털이노베이션BU 등)이다. 정본은 ㈜두산 자기 도메인(www.doosan.com, 꼬리말 (주)두산)
--     사회책임경영 > 보고서 목록이다. 행 근거는 그 목록이 주는 ㈜두산 지속가능경영보고서 2025(국문 PDF, 148쪽,
--     /file/down/dda1f452-dcf3-4134-b16a-b1197336227c, 발행 2026-06-30) p.33 인재경영 · p.28 인권경영이다.
--   보고서 보고 범위 = ㈜두산 국내외 사업장(정성 성과). p.33 복지 문장의 주어는 전부 ㈜두산이다
--     (㈜두산은 최적의 근무환경을 제공하고자 모든 임직원을 대상으로 다양한 제도와 복지시설을 운영). 2024 보고서 p.35 도 같은 제도.
--   두산 그룹 채용 사이트 career.doosan.com 복리후생 · 출산육아지원 페이지는 계열사 별 상이 면책이 붙은 그룹 공통 서술이고
--     ㈜두산 적용을 밝히지 않아 행 근거로 쓰지 않았다. 계열사(두산에너빌리티 · 두산밥캣 · 두산로보틱스 · 두산매거진 등) 문구 0.
--   구본 12행은 머리말대로 계열사 두산매거진 데이터라 폐기했다 — 추정 금액 승계 0 · 구본 코드 유지 규칙 미적용.
--   법정 제외: 휴가 사용 촉진 · 임신기 근로시간 단축 · 난임치료휴가 · 가족돌봄휴가 · 배우자 출산휴가와 육아휴직의 법정 기간.
--   금액: 명시값 환산 1행(parenting 보육지원금 월 20만원 = 연 240 환산, 추정치). 그 밖 11행 정성.
--   SORT 섹션 순서 = 보고서 p.33 표 순서(health 10 · flexibility 20 · family 30 · work_env 40) · p.36 보상(compensation 50).
-- 재수집(2026-10-02): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-02, RV-3-5): parenting 서술에서 배우자 출산휴가 추가분을 뺌(보고서의 법정 10일+추가 10일 = 현행 법정 20일) · 보고서 p.36 전 임직원 성과 연계 보상과 p.125 현금 성과급을 incentive 행으로 보탬 — 최종 12행

-- 1) 회사 등록 (기존 회사 — no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('doosan', '두산',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '인프라/에너지', 'D', 'https://www.doosan.com/kr/csr/about-csr/?menu=csr-report');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'doosan');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.doosan.com/kr/csr/about-csr/?menu=csr-report'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강·의료 (health) ── 보고서 p.33 임직원 건강 증진
  (@comp_id, 'mental', '심리상담 서비스', NULL, 'health',
   'est', NULL, TRUE, '직장 내 심리적인 고충, 개인적인 정서문제, 가족갈등 등에 대해 전문상담사와 1:1 심리상담 제공(필요 시 심리검사 지원), 연수원 내 마음이완 · 에너지충전 등 마음 건강지원 프로그램 (지속가능경영보고서 2025 인재경영 항목 — 상담 횟수 · 가족 이용 여부 미기재)', 10),
  (@comp_id, 'fitness', '사내 피트니스센터·건강지원 프로그램', NULL, 'health',
   'est', NULL, TRUE, '직장 내 피트니스센터(Fitness Center) 운영, PT · 요가 · 필라테스 · 자세 교정 프로그램, 금연 프로그램, 연수원 내 신체 이완 프로그램 등 신체 건강지원 프로그램 (지속가능경영보고서 2025 인재경영 항목 — 이용 비용 미기재)', 11),
  (@comp_id, 'medical', '실비보험 치료비 지원', NULL, 'health',
   'est', NULL, TRUE, '직장 실비보험을 통한 치료비 지원 (지속가능경영보고서 2025 인재경영 항목 — 보장 한도 · 가족 포함 여부 미기재)', 12),

  -- ── 근무유연성 (flexibility) ── 보고서 p.33 자기주도적 근무 · p.28 임직원 노동권 보장
  (@comp_id, 'remote_work', '재택근무 (Remote Work)', NULL, 'flexibility',
   'est', NULL, TRUE, '출퇴근 부담 완화와 자율성 · 효율성 제고를 위해 재택근무, 거점오피스 등 다양한 근무 장소에서 업무 수행이 가능한 Remote Work 제도 운영 (지속가능경영보고서 2025 인재경영 항목 — 재택 가능 일수 미기재)', 20),
  (@comp_id, 'satellite_office', '거점오피스', NULL, 'flexibility',
   'est', NULL, TRUE, '분당 두산타워, 동대문 두산타워를 이용할 수 있도록 거점오피스 제공 및 재택근무 병행 운영 (지속가능경영보고서 2025 인재경영 항목)', 21),
  (@comp_id, 'flex_work', '시차출퇴근제·선택적 근로시간제', NULL, 'flexibility',
   'est', NULL, TRUE, '업무적 · 개인적(육아 등) 필요에 따라 근무시간대를 변경해 출근하는 시차출퇴근제, 총 근로시간 범위 안에서(월 단위) 업무량에 따라 근무시간을 자율적으로 조정하는 선택적 근로시간제 (지속가능경영보고서 2025 인재경영 항목 — 의무 근로시간대 미기재)', 22),
  (@comp_id, 'pc_off', 'PC 셧다운제', NULL, 'flexibility',
   'est', NULL, TRUE, '과도한 근무시간을 방지하기 위해 PC 셧다운제를 운영하며 근무시간 모니터링 (지속가능경영보고서 2025 인권경영 임직원 노동권 보장 항목 — 종료 시각 미기재)', 23),

  -- ── 가족·돌봄 (family) ── 보고서 p.33 출산 및 육아 지원
  (@comp_id, 'childcare', '직장 어린이집', NULL, 'family',
   'est', NULL, TRUE, '만 1~5세 영유아 대상 직장 내 어린이집 운영(필요경비 전체 지원) (지속가능경영보고서 2025 인재경영 출산 및 육아 지원 항목 — 위치 · 정원 미기재)', 30),
  (@comp_id, 'parenting', '출산·육아 지원', 240, 'family',
   'est', '만 1~2세 사내 어린이집 미이용 자녀 보육지원금 월 20만원(연 240만원 환산), 출산경조금 첫째 300·둘째 500·셋째 이상 1,000만원, 임신 축하 상품권·임신부 주차권, 육아휴직 첫 달 기본급 차액 지원, 육아휴직자 팀장·팀원 지원금 최대 50만원, 복직 후 3개월 자녀 긴급 돌봄, 육아휴직 1년 추가(유급 여부 미기재)', FALSE, NULL, 31),

  -- ── 근무환경 (work_env) ── 보고서 p.33 최적의 근무환경 조성 · 출산 및 육아 지원
  (@comp_id, 'lounge', '오피스 휴게라운지', NULL, 'work_env',
   'est', NULL, TRUE, '임직원의 휴식과 복지를 위한 오피스 휴게라운지 (지속가능경영보고서 2025 인재경영 최적의 근무환경 조성 항목 — 위치 · 시설 구성 미기재)', 40),
  (@comp_id, 'nap_room', '모유 수유실', NULL, 'work_env',
   'est', NULL, TRUE, '직장 내 모유 수유실 운영 (지속가능경영보고서 2025 인재경영 출산 및 육아 지원 항목)', 41),

  -- ── 보상 (compensation) ── 보고서 p.36 임직원 평가 · p.125 사회 성과
  (@comp_id, 'incentive', '성과급(성과 연계 보상)', NULL, 'compensation',
   'est', NULL, TRUE, '전 임직원 대상 개인별 역량과 조직·개인 성과에 연계된 보상제도 운영, 임직원 보상에 현금 성과급 포함 (지속가능경영보고서 2025 인재경영 임직원 평가 항목 · 사회 성과 데이터 — 지급 기준·지급률 미기재)', 50)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
