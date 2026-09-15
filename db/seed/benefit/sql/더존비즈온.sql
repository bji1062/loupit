-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 더존비즈온 복리후생 데이터 (신규 회사)
-- 출처: AI 파싱 (2026-09-14)
-- URL: https://www.douzone.com/job/benefits.jsp
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고:
--   정본은 더존비즈온 자기 도메인 www.douzone.com 의 채용 > 복리후생제도 페이지다
--   (푸터 운영 주체 (주)더존비즈온 사업자등록번호 134-81-08473, TLS 인증서 O=Douzone Bizon Co.,Ltd.).
--   SSR JSP 텍스트 8항목, 카테고리·금액 없음. 헤드리스 불필요. 주석 블록 속 복지 항목 0개.
--   ⚠ 그러나 브레드크럼이 HOME > 더존ICT그룹 > 채용 > 복리후생제도 이고 본문에 법인명이 없다.
--   ⚠ 공유 구조: 채용 포털 recruit.douzone.com 은 법인 코드 5개(8000·K1000·2000·E2000·T1000)의
--     공고를 받는데 /benefits 라우트에는 법인 파라미터가 없어 5개 코드가 한 복리후생 페이지를 공유한다.
--     공고 176건 중 164건이 코드 8000 = 더존비즈온(제목에 더존비즈온이 들어간 122건이 전부 8000, 타 코드 0건).
--     recruit.douzone.com/benefits 는 benefits.jsp 와 글자까지 같은 복사본이라 따로 세지 않았다.
--     「계열사별 상이」 류 면책 문구는 어느 출처에도 없다.
--   귀속 설계(검증 R3-A·횡단 감사 반영, 2026-09-15):
--     공고 REM2026048(모집회사 더존비즈온, PNG 860x6491 sha256 ac970230…)의 복리후생제도 9카드는
--     키컴 공고 REM2026002(모집회사 키컴, PNG sha256 73ac302b…)와 제목·설명·순서가 같은 더존ICT그룹 공통 템플릿이다.
--     모집회사 칸은 모집분야 표의 행 값일 뿐 복리후생 블록의 귀속 근거가 아니다.
--     → 14행 전부 QUAL_DESC 말미 (그룹 통합 채용 기준) 각주. 공고는 거점 한정어(강촌 본사·을지타워·부산)·통근 노선·
--       사내 카페·명절선물의 보조 출처로만 쓰고, 사용자 노출 문안에 법인 명시 출처로 적지 않는다.
--     등록 유지 근거: 기등록 더존 계열 법인 0(복제 전개 아님) · 계열사별 상이 면책 0 · 사업장·도메인·운영 주체가
--       더존비즈온(HD현대 선례). 이 템플릿으로 형제 법인(키컴·더존비앤씨티·더존에듀캠 등)을 추가 등록하지 말 것.
--     사내어린이집(강촌캠퍼스)은 더존비즈온 본사 시설이다.
--   두 목록을 합집합으로 부풀리지 않았다 — 같은 제도는 한 행(코드 UNIQUE)에 두고 행마다 출처를 밝혔다.
--   14행 · 금액 0건(두 출처 모두 금액·비율 표현 없음, 공고 급여는 회사 내규) · 신규 코드 0.
--   분리: 복리후생시설 한 줄(카페테리아·사내식당·헬스케어센터·사내어린이집·통근버스)은 코드별 행으로,
--     공고 건강관리(건강검진 + 헬스케어센터)는 health_check + fitness, 공고 경조지원의 명절선물은 holiday_gift,
--     그룹 휴가제도의 하계휴가·비정기 단체휴가는 summer_leave + leave_general 로 나눴다.
--     거점 한정어(강촌 본사·을지타워·부산)는 설명에 보존했다 — 어린이집·식당·카페는 전 사업장 제도가 아니다.
--   법정 제도 미수록: 단체상해보험 설명의 전제인 4대 사회보험 · 휴가제도의 연차휴가·출산전후휴가 ·
--     공고 근무 조건의 법정복리(4대 사회보험, 퇴직금 지급). 행으로도, 다른 행 서술로도 넣지 않았다.
--   제외: 교육지원의 정기교육·개인별 교육(회사 주도 교육, 비용 지원 문구 없음 — 도서구매만 books 행) ·
--     그룹 페이지 카페테리아(구내식당인지 카페인지 원문이 가르지 않아 행 근거로 쓰지 않음) · 인재상·전형절차.
--   SORT 섹션 순서 = 정본 페이지 항목 순서에서 각 카테고리가 처음 나온 순서
--     (health 10 · family 20 · growth 30 · leisure 40 · time_off 50 · perks 60).
--   ⚠ 검증·감사 판정 반영(2026-09-15): 행 수 14 그대로. 공고 출처 11행(SORT 10·11·12·20·21·30·40·60·61·62·63)의
--     출처 표기를 더존ICT그룹 기준으로 바꾸고 (그룹 통합 채용 기준) 각주를 붙였다 — 14행 전부 그룹 기준.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('douzone', '더존비즈온',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        'IT서비스', 'D', 'https://www.douzone.com/job/benefits.jsp');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'douzone');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.douzone.com/job/benefits.jsp'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강·의료 (health) — 정본 단체상해보험·건강관리·복리후생시설 ──
  (@comp_id, 'insurance', '단체상해보험', NULL, 'health',
   'est', NULL, TRUE, '직원들의 안정된 근무여건 조성을 위한 단체상해보험 가입 지원 (더존ICT그룹 복리후생제도 페이지·채용공고 단체상해보험 항목 — 보장 범위·보험료 부담 미기재) (그룹 통합 채용 기준)', 10),
  (@comp_id, 'health_check', '정기 건강검진', NULL, 'health',
   'est', NULL, TRUE, '정기 건강검진 실시 (더존ICT그룹 복리후생제도 페이지·채용공고 건강관리 항목 — 검진 항목·주기·가족 포함 여부·비용 미기재) (그룹 통합 채용 기준)', 11),
  (@comp_id, 'fitness', '사내 헬스케어센터', NULL, 'health',
   'est', NULL, TRUE, '강촌 본사·을지타워·부산에 사내 헬스케어센터 운영 (더존ICT그룹 채용공고 건강관리 항목 · 복리후생제도 페이지 복리후생시설 항목 헬스케어센터(필라테스) — 이용 조건·프로그램 구성 미기재) (그룹 통합 채용 기준)', 12),

  -- ── 가족·돌봄 (family) — 정본 경조지원·복리후생시설 ──
  (@comp_id, 'event', '경조지원', NULL, 'family',
   'est', NULL, TRUE, '경조사 발생 시 경조휴가·화환·경조금 지급 (더존ICT그룹 복리후생제도 페이지·채용공고 경조지원 항목 — 경조 구분별 금액·휴가 일수 미기재) (그룹 통합 채용 기준)', 20),
  (@comp_id, 'childcare', '사내 어린이집', NULL, 'family',
   'est', NULL, TRUE, '직원의 일과 가정의 균형을 위해 강촌 본사에 사내 어린이집 운영 (더존ICT그룹 채용공고 사내 어린이집 운영 항목 · 복리후생제도 페이지 복리후생시설 항목 사내어린이집(강촌캠퍼스) — 정원·대상 연령 미기재) (그룹 통합 채용 기준)', 21),

  -- ── 성장·교육 (growth) — 정본 교육지원 ──
  (@comp_id, 'books', '도서구매 지원', NULL, 'growth',
   'est', NULL, TRUE, '직원들의 자기계발을 위한 도서구매 지원 (더존ICT그룹 복리후생제도 페이지·채용공고 교육지원 항목 — 지원 한도·구매 방식 미기재) (그룹 통합 채용 기준)', 30),

  -- ── 여가·라이프 (leisure) — 정본 동호회지원·각종행사 ──
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '직원들의 여가생활 활성화를 위해 사내동호회(축구, 야구, 농구, 헬스 등) 활동 지원 (더존ICT그룹 복리후생제도 페이지·채용공고 동호회 항목 — 활동비 지원액 미기재) (그룹 통합 채용 기준)', 40),
  (@comp_id, 'company_event', '전 직원 워크샵·체육대회', NULL, 'leisure',
   'est', NULL, TRUE, '전 직원 워크샵과 체육대회, 축하공연 등의 이벤트 행사 실시 (더존ICT그룹 복리후생제도 페이지 각종행사 항목 — 개최 주기·참가 범위 미기재) (그룹 통합 채용 기준)', 41),

  -- ── 휴가 (time_off) — 정본 휴가제도 ──
  (@comp_id, 'summer_leave', '하계휴가', NULL, 'time_off',
   'est', NULL, TRUE, '하계휴가 실시 (더존ICT그룹 복리후생제도 페이지 휴가제도 항목 — 부여 일수·별도 부여 여부 미기재) (그룹 통합 채용 기준)', 50),
  (@comp_id, 'leave_general', '비정기 단체휴가', NULL, 'time_off',
   'est', NULL, TRUE, '비정기 단체휴가 실시 (더존ICT그룹 복리후생제도 페이지 휴가제도 항목 — 시기·일수·유급 여부 미기재) (그룹 통합 채용 기준)', 51),

  -- ── 경제적 부가혜택 (perks) — 정본 복리후생시설 + 공고 경조지원 ──
  (@comp_id, 'meal', '사내 식사·간식 제공', NULL, 'perks',
   'est', NULL, TRUE, '강촌 본사 및 을지타워에서 무료 사내식당(조·중·석식)과 간식 제공 (더존ICT그룹 채용공고 사내 식사/간식 제공 항목 · 복리후생제도 페이지 복리후생시설 항목 사내식당(조,중,석식 제공) — 그 밖의 사업장 제공 여부 미기재) (그룹 통합 채용 기준)', 60),
  (@comp_id, 'snack_bar', '사내 카페', NULL, 'perks',
   'est', NULL, TRUE, '직원 편의를 위해 강촌 본사와 을지타워에 사내 카페 운영 (더존ICT그룹 채용공고 사내 카페 운영 항목 — 무료 여부·이용 한도 미기재) (그룹 통합 채용 기준)', 61),
  (@comp_id, 'commute_subsidy', '통근버스', NULL, 'perks',
   'est', NULL, TRUE, '강촌 본사와 잠실역·강변역·천호역·구리역·태릉입구역·상봉역·평내호평역·춘천지역 간 통근버스 운행 (더존ICT그룹 채용공고 통근버스 운행 항목 · 복리후생제도 페이지 복리후생시설 항목 — 운행 시간·요금 부담 여부 미기재) (그룹 통합 채용 기준)', 62),
  (@comp_id, 'holiday_gift', '명절선물', NULL, 'perks',
   'est', NULL, TRUE, '명절선물 제공 (더존ICT그룹 채용공고 경조지원 항목 — 선물 품목·금액·지급 횟수 미기재) (그룹 통합 채용 기준)', 63)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
