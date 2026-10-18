-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 대교 복리후생 데이터 (신규 회사 — 웨이브 12)
-- 출처: AI 파싱 (2026-10-18)
-- URL: https://www.daekyo.com/kr/model_staff
-- badge: est
--
-- 참고:
--   정본 = 대교 공식 홈 직원채용 상시 페이지(자기 도메인 · SSR · 복지 문구 없음 · 회사 채용 사이트 링크만).
--   복지 원문 = 그 페이지와 홈 팝업이 링크한 회사 계정 채용 사이트(잡코리아 채용대행 jrs.jobkorea.co.kr/daekyo)의
--   2026 대교 신입사원 공개채용 공고(접수 2026.04.08~05.05 · 마감 · 지금도 공개 · 더 새 공고 없음) 이미지 안
--   구성원 혜택 표(복지 제도 · 인사 제도 · 교육 제도)와 비전 및 성장 지원 절 — 이미지 판독(960x5515 PNG).
--   보조 = OpenDART 2026 반기보고서(20260814003757) 유연근무제도 사용 현황 · 자기주식 처분,
--   2025 사업보고서 기재정정(20260609000080) 자기주식 주석 · 재무제표 주석 기타장기종업원급여.
--   귀속 = 법인 단독(공고 주체 대교 · 공시 법인 대교) — 각주 없음. 대교홀딩스 그룹 사이트 인재상 페이지는 복지 없음.
--   금액 = 원문에 숫자 금액 없음 — 전 행 정성(stated 0 · 추정 0).
--   제외 = 법정(육아기 단축근무 · 4대 보험) · 업무 교육(온라인 직무 교육 · 사회 초년생 적응 · 직무역량 단계 과정) ·
--   발령 전 교육기간 비용(급여성) · 선택근무제(세 기간 사용자 0) · 주식선택권 · 임원 보수 경영성과급.
--   공고 근거 17행 / 전체 19행(공시 단독 2행 = 시차출퇴근제 · 원격근무제).
--   SORT 섹션 = 공고 이미지에 처음 나온 순서 growth · health · leisure · compensation · family · perks · time_off, 공시만 flexibility.
-- 검증 · 감사 판정 반영(2026-10-18): jrs.jobkorea.co.kr/daekyo 는 회사 계정 채용 사이트(ATS) · 직무 전환 career 서술에 교사·교육관리직 트랙 출처와 다른 직군 적용 여부 미기재 · 온라인 직무 교육 상시 지원을 edu_support 에 병합 · 참고 블록의 공고 근거 17행 / 전체 19행은 16행(공시 단독 3행) · 제외 줄의 온라인 직무 교육은 이 판정으로 뒤집힘 — 최종 19행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('daekyo', '대교',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '교육', 'D', 'https://www.daekyo.com/kr/model_staff');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'daekyo');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.daekyo.com/kr/model_staff'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 성장 (growth) — 2026 신입사원 공개채용 공고 ──
  (@comp_id, 'career', '개별 지원을 통한 직무 전환', NULL, 'growth',
   'est', NULL, TRUE, '추후 개별 지원 및 선발 과정을 통해 교육관리자(교육팀장, 러닝센터장 등), 본사 STAFF, 글로벌 인재(해외 근무) 등 직무 전환 가능 (2026 신입사원 공개채용 공고 교사·교육관리직 비전 및 성장 지원 직무 비전 항목) — 다른 직군 적용 여부·지원 시기·선발 기준 미기재', 10),
  (@comp_id, 'edu_support', '산학협력 위탁교육·온라인 직무 교육·학습조직 활동비 지원', NULL, 'growth',
   'est', NULL, TRUE, '산학협력 위탁교육 지원, 온라인 직무 교육 상시 지원, 학습조직 통해 함께 성장해요 북클럽/그로잉 클럽 활동비 지원 (2026 신입사원 공개채용 공고 구성원 혜택 교육 제도 항목), 자율적 자기 성장, 학습 지원 프로그램(그로잉 클럽/북클럽) (같은 공고 성장 지원 공통역량 지원 항목) — 위탁교육 과정·온라인 과정 범위·지원 범위·활동비 금액 미기재', 11),
  (@comp_id, 'conference', '외부 전문 교육 지원', NULL, 'growth',
   'est', NULL, TRUE, '외부 전문 교육 지원 (2026 신입사원 공개채용 공고 구성원 혜택 교육 제도 항목) — 교육 과정·지원 범위 미기재', 12),

  -- ── 건강 (health) — 2026 신입사원 공개채용 공고 ──
  (@comp_id, 'health_check', '정기 건강검진 지원', NULL, 'health',
   'est', NULL, TRUE, '정기 건강검진지원 (2026 신입사원 공개채용 공고 구성원 혜택 복지 제도 항목) — 검진 주기·비용 지원 범위 미기재', 20),

  -- ── 여가 (leisure) — 2026 신입사원 공개채용 공고 ──
  (@comp_id, 'company_event', '부모님 효도여행 지원', NULL, 'leisure',
   'est', NULL, TRUE, '부모님을 위한 효도여행 지원 (2026 신입사원 공개채용 공고 구성원 혜택 복지 제도 항목) — 참가 대상·지원 범위·시행 주기 미기재', 30),
  (@comp_id, 'resort', '하계 휴양소·법인 콘도', NULL, 'leisure',
   'est', NULL, TRUE, '하계 휴양소 및 법인 콘도 운영 (2026 신입사원 공개채용 공고 구성원 혜택 복지 제도 항목) — 이용 횟수·비용 부담 미기재', 31),
  (@comp_id, 'club', '사내 취미 동아리', NULL, 'leisure',
   'est', NULL, TRUE, '사내 취미 동아리 운영 (2026 신입사원 공개채용 공고 구성원 혜택 복지 제도 항목) — 활동비 지원 여부·금액 미기재', 32),
  (@comp_id, 'library', '독서플랫폼 지원 (밀리의 서재)', NULL, 'leisure',
   'est', NULL, TRUE, '독서플랫폼 지원(밀리의 서재) (2026 신입사원 공개채용 공고 구성원 혜택 교육 제도 항목) — 이용 대상·지원 범위 미기재', 33),

  -- ── 보상 (compensation) — 2026 신입사원 공개채용 공고 · 공시 ──
  (@comp_id, 'holiday_gift', '명절선물', NULL, 'compensation',
   'est', NULL, TRUE, '명절선물 제공 (2026 신입사원 공개채용 공고 구성원 혜택 복지 제도 항목) — 선물 품목·금액 미기재', 40),
  (@comp_id, 'long_service_bonus', '장기근속 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속 포상 (2026 신입사원 공개채용 공고 구성원 혜택 인사 제도 포상제도 항목), 장기 근속 임직원에게 장기종업원급여를 제공 (2025 사업보고서 재무제표 주석 종업원급여 항목) — 근속 기준·포상 형태·금액 미기재', 41),
  (@comp_id, 'excellence_award', '우수사원 포상', NULL, 'compensation',
   'est', NULL, TRUE, '우수사원 포상 등 포상제도 운영으로 동기부여 (2026 신입사원 공개채용 공고 구성원 혜택 인사 제도 포상제도 항목) — 포상 기준·포상 내용 미기재', 42),
  (@comp_id, 'stock_grant', '자기주식 포상 지급', NULL, 'compensation',
   'est', NULL, TRUE, '임직원 등 조직원 포상 목적으로 자기주식(우선주)을 지급, 2025년 2월·4월·7월 이사회 결의 (2025 사업보고서 자기주식 항목), 성과 우수 구성원 포상을 위하여 자기주식 우선주를 처분해 2026년 1월 교부 완료 (2026 반기보고서 자기주식 항목) — 지급 대상 기준·1인당 주식 수 미기재', 43),

  -- ── 가족 (family) — 2026 신입사원 공개채용 공고 ──
  (@comp_id, 'event', '경조금·경조휴가·장의 용품 지원', NULL, 'family',
   'est', NULL, TRUE, '경조금, 경조 휴가지원, 장의 용품 지원 (2026 신입사원 공개채용 공고 구성원 혜택 복지 제도 항목) — 경조 사유별 금액·휴가 일수 미기재', 50),
  (@comp_id, 'child_edu', '학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '학자금지원 (2026 신입사원 공개채용 공고 구성원 혜택 복지 제도 대부금, 학자금지원 항목) — 지원 대상·학교 급·금액 미기재', 51),

  -- ── 생활 (perks) — 2026 신입사원 공개채용 공고 ──
  (@comp_id, 'welfare_fund_loan', '대부금 지원', NULL, 'perks',
   'est', NULL, TRUE, '대부금 지원 (2026 신입사원 공개채용 공고 구성원 혜택 복지 제도 대부금, 학자금지원 항목) — 대출 용도·한도·이율 미기재', 60),
  (@comp_id, 'discount', '자사 제품 학습 할인', NULL, 'perks',
   'est', NULL, TRUE, '자사 제품 학습 시 할인 지원 (2026 신입사원 공개채용 공고 구성원 혜택 교육 제도 항목) — 할인율·이용 대상 미기재', 61),

  -- ── 휴가 (time_off) — 2026 신입사원 공개채용 공고 ──
  (@comp_id, 'summer_leave', '하계 휴가 (유급 5일)', NULL, 'time_off',
   'est', NULL, TRUE, '무더운 여름철 Refresh, 5일 유급 하계 휴가 (2026 신입사원 공개채용 공고 구성원 혜택 인사 제도 항목) — 연차 사용일인지 미기재', 70),

  -- ── 근무 유연성 (flexibility) — 2026 반기보고서 ──
  (@comp_id, 'flex_work', '시차출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제 활용, 시차출퇴근제 사용자 수 2026년 상반기 509명·2025년 421명·2024년 325명 (2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 80),
  (@comp_id, 'remote_work', '원격근무제(재택근무 포함)', NULL, 'flexibility',
   'est', NULL, TRUE, '원격근무제(재택근무 포함) 사용자 수 2026년 상반기 108명·2025년 83명·2024년 109명 (2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
