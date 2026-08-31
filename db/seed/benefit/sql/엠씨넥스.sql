-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 엠씨넥스 복리후생 데이터
-- 출처: AI 파싱 (2026-08-31)
-- URL: https://www.mcnex.com/ko/company/01.AB07.03
-- badge: 'est' (추정치 — 공식 확인 시 'official'로 변경)
-- 참고: 근거는 전부 **엠씨넥스 공식 도메인**(mcnex.com) 두 페이지 —
--       ① 인재채용 「인사제도·복리후생」(01.AB07.03) — 복리후생 3분류(회사생활/건강생활/문화생활) + 인사제도.
--       ② ESG SOCIAL(Mcnex_ESG_Social) — 「복리후생 제도」 목록(유연근무제 추가) + 임직원 건강증진·인재육성 본문.
--       ⚠ DART 기업개황의 홈페이지 www.mcnex.co.kr 는 인증서가 *.mcnex.com 전용이라 엄격 TLS 로는
--         접속 불가(302 → https://mcnex.com/ 은 인증서 검증을 꺼야 관측된다). 정본 도메인 = mcnex.com.
--       두 페이지 모두 금액을 일절 공개하지 않는다 — 금액이 있는 4행(excellence_award 50 /
--       health_check 100 / event 50 / meal 288)은 구본(2026-04-15)의 앵커 추정치를 그대로 유지한
--       것(금액정책 (a) — 서술·출처는 새 페이지, 금액은 기존 앵커 보존). note 의 "추정" 표기로
--       DG-2 가 estimated 로 도출된다. 구본 excellence_award('장기근속/우수사원 포상' 50)를
--       excellence_award + long_service_bonus 두 행으로 쪼갤 때 앵커는 **같은 코드에만** 남기고
--       long_service_bonus 는 금액 없음으로 뒀다(50 을 양쪽에 복사하면 총액이 2배가 된다).
--       검증 판정(2026-08-31): child_edu(원문이 임원 자녀 한정 — 히트맵 고정 라벨이 한정을
--       지워 허위가 됨)·medical(병원 협약은 의료비 지원이 아님)·edu_support(ESG 커리큘럼
--       문단 — 같은 배치 엔켐 기준과 통일) 3행 제외, 금연펀드는 clinic 에 병기(테크윙 선례).
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (없는 경우)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('mcnex', '엠씨넥스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '카메라모듈', 'M', 'https://www.mcnex.com/ko/company/01.AB07.03');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'mcnex');

-- 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본은 NULL — INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.mcnex.com/ko/company/01.AB07.03'
 WHERE COMP_ID = @comp_id;

-- 3) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 4) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'excellence_award', '모범사원·칭찬 주인공 포상', 50, 'compensation',
   'est', '모범사원 포상, 칭찬 주인공 포상 (연 50만원 추정 — 구본 앵커 승계, 페이지에 금액 없음)', FALSE, NULL, 10),
  (@comp_id, 'long_service_bonus', '장기근속 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속 포상 (금액·근속 기준 미공개)', 20),
  (@comp_id, 'incentive', '성과급 제도', NULL, 'compensation',
   'est', NULL, TRUE, '경영성과와 소속부서 기여도에 따라 성과급 차등 지급 (인사제도 「성과급 제도 운영」)', 30),
  (@comp_id, 'holiday_gift', '각종 기념일 선물', NULL, 'compensation',
   'est', NULL, TRUE, '각종 기념일 선물 지급', 40),

  -- ── 유연근무 (flexibility) ──
  (@comp_id, 'flex_work', '유연근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제 도입 (ESG SOCIAL 「일과 삶의 균형」 — 유형·적용 범위 미공개)', 50),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'dormitory', '기숙사 지원', NULL, 'work_env',
   'est', NULL, TRUE, '기숙사 지원', 60),
  (@comp_id, 'lounge', '직원 휴게실', NULL, 'work_env',
   'est', NULL, TRUE, '직원 휴게실 운영 — 업무 피로 완화를 위한 사내 휴식 장소 제공', 70),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '종합 건강검진', 100, 'health',
   'est', '매년 일반·특수·종합 건강검진 실시 (연 100만원 추정 — 구본 앵커 승계, 페이지에 금액 없음)', FALSE, NULL, 80),
  (@comp_id, 'clinic', '건강관리 프로그램·사내 건강관리실', NULL, 'health',
   'est', NULL, TRUE, '건강관리 프로그램·금연펀드 운영, 사내 건강관리실 제공, 인근 병원 협약 의료 서비스', 90),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'event', '경조휴가·경조금 지원', 50, 'family',
   'est', '경조휴가 및 경조금 지원 (연 50만원 추정 — 구본 앵커 승계, 페이지에 금액 없음)', FALSE, NULL, 120),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'career', '멘토링 제도', NULL, 'growth',
   'est', NULL, TRUE, '멘토링 제도 운영 — 신입사원 온보딩 지원', 140),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'club', '사내 동호회·문화활동 지원', NULL, 'leisure',
   'est', NULL, TRUE, '사내동호회 활동 지원, 워크샵 및 문화활동 지원', 160),
  (@comp_id, 'resort', '법인 콘도', NULL, 'leisure',
   'est', NULL, TRUE, '법인 콘도 지원', 170),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'meal', '식사 제공', 288, 'perks',
   'est', '식사 제공 (연 288만원 추정 — 구본 앵커 승계, 페이지에 금액·끼니 범위 없음)', FALSE, NULL, 180)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
