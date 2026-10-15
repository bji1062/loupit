-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SKC 복리후생 데이터 (신규 회사 — 웨이브 10)
-- 출처: AI 파싱 (2026-10-15)
-- URL: https://www.skc.kr/kor/career/life.do
-- badge: est
--
-- 참고:
--   정본은 상장 법인 SKC(주)의 자기 도메인 www.skc.kr Career > 라이프 페이지다(SSR · 원본 HTML 에 글이 다 있다).
--   이 페이지는 SKC Family(SKC와 투자사) 구성원 전체를 말하는 문구라(소통 문단의 SKC Family 구성원이라면 모두 ·
--   휴가 문단의 각 사별로) 이 페이지에만 기댄 행은 출처 괄호에 SKC Family 공통 문구 각주를 단다.
--   보조 출처(주 근거)는 같은 도메인 지속가능경영보고서 목록 최신 판 2026 SKC 지속가능경영보고서
--   (발행 2026-06-30 · 보고 기간 2025-01-01~2025-12-31 · 보고 경계 SKC 및 SK넥실리스 · SK피아이씨글로벌 · ISC 국내 사업장)
--   40쪽 일과 삶의 균형(유연근무제 · 복리후생) · 48쪽 임직원 보건 지원 · 39쪽 교육 프로그램 · 18쪽 이해관계자 참여.
--   보고 범위가 여러 법인이라 SKC는 주어 문장만 각주 없이 썼다. 법인 구분 없는 18쪽 표 근거 행(SKC Family Crew)만 통합 보고 각주.
--   공시 보조: OpenDART 2026 반기보고서(접수 20260814003336) · 2025 사업보고서 정정(접수 20260610000521)
--   직원 등 현황 유연근무제도 사용 현황 표(시차출퇴근제 · 원격근무제 사용자 수). 직원 134명(2026-06-30 · 미등기임원 포함).
--   렌더 · 이미지 판독 불필요. SK 그룹 형제(SK케미칼 · SK네트웍스 · SK가스 등) 정본 문장과 겹친 행 0.
--   금액: 원문에 원 단위 숫자 0건 — 전 행 BENEFIT_AMT NULL.
--   제외: 법정(임신기 · 육아기 근로시간 단축 · 가족돌봄 단축근무 · 사업장별 건강검진과 배치 전환 사후관리 · 법정 인권교육) ·
--     권장휴가(전사 구성원이 함께 휴식하는 권장휴가) · 양성 육아휴직 적극 권장 · 업무 교육(신입 · 영입 · 팀장 · 핵심인재 ·
--     SKMS Camp · AI 교육) · 평가 보상 문장(Fast Track · 차등 보상 · 보수 반영) · 소통 프로그램(Diversity Table · 행복토크 ·
--     콩 어플 · Common Ground · 시끌시끌) · 임원 장기성과급 · 주식선택권 · 다른 법인(SK넥실리스 · ISC 등) 제도.
--   공고 근거 0행 / 전체 21행.
--   SORT 섹션 순서 = 정본 페이지 등장 순(health 10 · family 20 · leisure 30 · time_off 40 · flexibility 50 · growth 60),
--     보고서에만 있는 perks 70 · work_env 80.
-- 검증 · 감사 판정 반영(2026-10-15): 원격근무 서술에 원문 낱말 자율적으로를 되살림 · 인싸Learn · mySUNI 서술에 라이프 페이지 mySUNI 수강 문장을 되살림(SKC Family 공통 문구 각주) · 분류는 항목 페이지 예외 4(통합 밖 리드 집행)로 맞춤 — 최종 21행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('skc', 'SKC',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '화학', 'S', 'https://www.skc.kr/kor/career/life.do');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'skc');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.skc.kr/kor/career/life.do'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강 (health) — 보고서 48쪽 · 40쪽 · 라이프 페이지 ──
  (@comp_id, 'health_check', '종합건강검진 (이해관계자 1인 포함)', NULL, 'health',
   'est', NULL, TRUE, '전 연령대 구성원 대상 매년 종합 건강검진 제공, 짝수 연도에는 이해관계자 1인에게도 동일한 검진 기회 부여 (2026 지속가능경영보고서 48쪽 임직원 보건 지원 항목), 종합건강검진 지원 대상을 구성원 외 이해관계자 1인까지 확대 (같은 보고서 40쪽 복리후생 항목) — 검진 항목·비용 지원 범위 미기재', 10),
  (@comp_id, 'medical', '의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '질병 및 사고 발생 시 경제적 부담 완화를 위한 의료비 지원 제도 운영 (2026 지속가능경영보고서 48쪽 임직원 보건 지원 항목), 의료비 지원 (같은 보고서 40쪽 복리후생 항목), 구성원의 건강을 위한 폭 넓은 의료비 지원 (공식 채용 페이지 라이프 항목, SKC Family 공통 문구) — 지원 대상·한도 미기재', 11),
  (@comp_id, 'mental', '심리상담 서비스 (마음건강 지원 프로그램)', NULL, 'health',
   'est', NULL, TRUE, '전 직원 대상 마음건강 지원 프로그램 시행, 직무 스트레스·관계 갈등·정서적 어려움 등 포괄, 구성원 본인과 직계 가족까지 참여 가능 (2026 지속가능경영보고서 48쪽 임직원 보건 지원 항목), 심리상담 서비스 제공 (같은 보고서 40쪽 복리후생 항목), 마음 건강을 위한 EAP 상담 프로그램 (공식 채용 페이지 라이프 항목, SKC Family 공통 문구) — 이용 횟수·비용 지원 범위 미기재', 12),
  (@comp_id, 'insurance', '단체상해보험', NULL, 'health',
   'est', NULL, TRUE, '질병 및 사고 발생 시 경제적 부담 완화를 위한 단체상해보험 가입 (2026 지속가능경영보고서 48쪽 임직원 보건 지원 항목) — 보장 범위·가입 대상 미기재', 13),
  (@comp_id, 'fitness', '사내 피트니스 공간', NULL, 'health',
   'est', NULL, TRUE, '사업장 내 체력단련 공간 구축, 본사 피트니스 공간 운영 (2026 지속가능경영보고서 48쪽 임직원 보건 지원 항목) — 이용 시간·운영 사업장 범위 미기재', 14),
  (@comp_id, 'massage', '헬스키퍼실 (본사)', NULL, 'health',
   'est', NULL, TRUE, '본사에 전문 자격을 갖춘 시각장애인이 상주하여 운영하는 헬스키퍼실 (2026 지속가능경영보고서 48쪽 임직원 보건 지원 항목) — 이용 방식·비용 미기재', 15),

  -- ── 가족 (family) — 라이프 페이지 · 보고서 40쪽 ──
  (@comp_id, 'event', '경조휴가·경조금', NULL, 'family',
   'est', NULL, TRUE, '경조사 시 넉넉한 경조휴가와 경조금 지원 (공식 채용 페이지 라이프 항목, SKC Family 공통 문구) — 경조 사유별 휴가 일수·지급 금액 미기재', 20),
  (@comp_id, 'parenting', '육아휴직 3개월 유급화', NULL, 'family',
   'est', NULL, TRUE, '3개월 유급화된 육아휴직 (2026 지속가능경영보고서 40쪽 복리후생 항목) — 유급 지급 수준·대상 조건 미기재', 21),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금 지원 (2026 지속가능경영보고서 40쪽 복리후생 항목) — 지원 학령·한도 미기재', 22),

  -- ── 여가 (leisure) — 보고서 40쪽 · 18쪽 · 라이프 페이지 ──
  (@comp_id, 'resort', '행복캠프 (추첨제 숙박비 지원)', NULL, 'leisure',
   'est', NULL, TRUE, '재충전 기회 지원을 위해 추첨을 통해 국내외 지정 숙소의 숙박비를 전액 지원하는 행복캠프 운영 (2026 지속가능경영보고서 40쪽 복리후생 항목), 휴가 권장 Event 「행복캠프」 (공식 채용 페이지 라이프 항목, SKC Family 공통 문구) — 추첨 인원·이용 기간 미기재', 30),
  (@comp_id, 'club', 'SKC Family Crew', NULL, 'leisure',
   'est', NULL, TRUE, 'SKC Family Crew: 공통 관심사를 가진 구성원들이 모여 교류 및 네트워킹 (2026 지속가능경영보고서 18쪽 이해관계자 참여 구성원 항목) — 활동비 지원·운영 방식 미기재 (SKC · SK넥실리스 · SK피아이씨글로벌 · ISC 통합 보고 기준)', 31),

  -- ── 휴가 (time_off) — 라이프 페이지 · 보고서 40쪽 ──
  (@comp_id, 'summer_leave', '하기휴가', NULL, 'time_off',
   'est', NULL, TRUE, '하기휴가 (공식 채용 페이지 라이프 항목 휴가 지킴이 문단, SKC Family 공통 문구) — 휴가 일수·유급 여부 미기재', 40),
  (@comp_id, 'long_service_leave', '장기근속 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속 휴가 (2026 지속가능경영보고서 40쪽 유연근무제 항목) — 근속 기준·휴가 일수 미기재', 41),
  (@comp_id, 'leave_general', '휴가 셀프 승인 제도', NULL, 'time_off',
   'est', NULL, TRUE, '휴가 셀프 승인 제도를 통해 구성원이 자율적으로 휴가를 사용할 수 있도록 지원 (2026 지속가능경영보고서 40쪽 유연근무제 항목) — 적용 휴가 종류 미기재', 42),

  -- ── 근무 유연성 (flexibility) — 보고서 40쪽 · 반기 · 사업보고서 · 라이프 페이지 ──
  (@comp_id, 'flex_work', '유연근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '탄력적 근로시간제와 시차출퇴근제 운영, 조직별 업무 특성을 반영해 근무 방식을 스스로 설계하는 Self-Design 유연근무제 도입 (2026 지속가능경영보고서 40쪽 유연근무제 항목), 시차출퇴근제 사용자 수 2024년 188명·2025년 171명·2026년 상반기 100명 (2026 반기보고서·2025 사업보고서 유연근무제도 사용 현황 항목), Flexible한 출퇴근 시간 (공식 채용 페이지 라이프 항목, SKC Family 공통 문구) — 적용 대상·코어타임 미기재', 50),
  (@comp_id, 'remote_work', '원격근무제(재택근무 포함)', NULL, 'flexibility',
   'est', NULL, TRUE, '재택근무는 업무 특성과 조직 상황을 고려해 각 조직이 자율적으로 Ground Rule을 수립·운영 (2026 지속가능경영보고서 40쪽 유연근무제 항목), 원격근무제(재택근무 포함) 사용자 수 2024년 188명·2025년 171명·2026년 상반기 100명 (2026 반기보고서·2025 사업보고서 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 51),

  -- ── 성장 (growth) — 보고서 39쪽 · 18쪽 · 라이프 페이지 ──
  (@comp_id, 'lang', '사내 어학 프로그램 부지Learn·1 on 1 튜터링', NULL, 'growth',
   'est', NULL, TRUE, '글로벌 역량 강화를 위한 사내 어학 프로그램 부지Learn (2차수), Global 영역 1 on 1 튜터링 지원 (2026 지속가능경영보고서 39쪽 교육 프로그램 항목), 외국어 교육 지원 (공식 채용 페이지 라이프 항목, SKC Family 공통 문구) — 수강 대상·비용 지원 범위 미기재', 60),
  (@comp_id, 'self_development', '업무 관련 자격 취득 지원', NULL, 'growth',
   'est', NULL, TRUE, '구성원이 끊임없이 성장할 수 있도록 업무 관련 자격 취득 지원 (공식 채용 페이지 라이프 항목, SKC Family 공통 문구) — 지원 자격 종류·비용 지원 범위 미기재', 61),
  (@comp_id, 'edu_support', '인사이트 특강 인싸Learn·mySUNI', NULL, 'growth',
   'est', NULL, TRUE, '전사 인사이트 특강 인싸Learn (5차수), SK그룹 공통 교육 플랫폼 mySUNI를 활용해 구성원이 자발적으로 업무 역량을 개발할 수 있는 환경 조성 (2026 지속가능경영보고서 39쪽 교육 프로그램 항목), SK그룹 mySUNI 수강 등 자기개발을 위한 다양한 Event (공식 채용 페이지 라이프 항목, SKC Family 공통 문구) — 참여 대상·비용 지원 미기재', 62),

  -- ── 생활 (perks) — 보고서 40쪽 ──
  (@comp_id, 'welfare_point', '행복카드', NULL, 'perks',
   'est', NULL, TRUE, '자기개발과 건강관리 등 개인의 라이프 스타일에 맞춰 자유롭게 활용할 수 있는 행복카드 제공 (2026 지속가능경영보고서 40쪽 복리후생 항목) — 지급 금액 미기재', 70),

  -- ── 근무환경 (work_env) — 보고서 48쪽 ──
  (@comp_id, 'lounge', '사업장 휴게 공간', NULL, 'work_env',
   'est', NULL, TRUE, '사업장 내 휴게 환경 구축 (2026 지속가능경영보고서 48쪽 임직원 보건 지원 항목) — 휴게 시설 종류·운영 사업장 범위 미기재', 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
