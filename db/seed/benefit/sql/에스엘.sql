-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 에스엘 복리후생 데이터 (신규 회사 — 웨이브 5)
-- 출처: AI 파싱 (2026-10-10)
-- URL: https://www.slworld.com/include/esg_report_2026_ko.pdf
-- badge: est
--
-- 참고:
--   정본은 상장 법인 에스엘 주식회사(SL Corporation · KOSPI 005850)가 자기 도메인 www.slworld.com 의
--   ESG > 지속가능경영보고서 게시판(/esg/esg_report.php)에 올린 2026 지속가능경영보고서 국문 PDF
--   65쪽 복리후생 및 가족친화제도(복리후생 제도 표 10행 + 조직문화 활성화 · 가족친화문화 조성 본문)다.
--   보조 출처는 같은 PDF 55쪽(근로자 건강검진 · 임직원 건강관리 프로그램) · 57쪽(SL 사내 카페 운영) ·
--   60쪽(노사협의회 4분기 안건) · 62쪽(주요 보상/포상제도 표 · 보상체계 및 포상제도) ·
--   63쪽(자기주도학습 지원 · 사내 공모 제도) · 43쪽(사내 통근버스 운영)이다. 인쇄 쪽 = PDF 쪽.
--   보고 기간 2025-01-01~2025-12-31, 발간일 2026-06-18. 원문은 웨이브 5 프로브가 2026-10-10 UTC 에
--   받은 사본(sha256 3a070459a3ca1af9…)을 다시 받지 않고 썼다. 렌더 방식 = PDF 텍스트 레이어(pypdf).
--   자기 도메인에 복리후생 HTML 페이지가 없고 채용 ATS(slworld.recruiter.co.kr)는 본문이
--   robots 금지 벤더 API 에만 있어 요청 · 렌더하지 않았다.
--   귀속: 보고 범위는 상장법인 에스엘 주식회사의 국내 사업장 전체이고 65쪽 표 주석은 적용 대상
--   정규직 및 계약직을 포함한 전체 임직원, 본문 주어는 전부 에스엘이다. 그룹 각주 없음.
--   같은 65쪽 Business Case CO-TALK 상자는 주어가 별도 법인 에스엘미러텍이라 쓰지 않았고,
--   57쪽 에스엘 멕시코 사례 · 124~134쪽 해외 사업장 · 관계사 지표도 쓰지 않았다.
--   금액: 원문 금액은 자격 시험 응시료 1회 기준 최대 10만 원 하나뿐이고 1회 한도라 금액 칸에 넣지
--   않았다. 24행 전부 BENEFIT_AMT NULL(정성) — stated 0 · 추정 0.
--   제외: 육아기 · 임신기 근로시간 단축(임금 공제 없는 임신기 단축 포함) · 일반 · 특수 건강진단 ·
--   유해인자 수시 건강검진 · 청력보존 프로그램 · 근골격계 유해요인 조사와 예방 프로그램 · 직무스트레스
--   예방 프로그램 · 퇴직연금 제도(법정) · SL 멘토링 · 학점이수제도 · 직무 아카데미 · 리더 아카데미 ·
--   신규 입사자 육성 로드맵 · 순환보직자 어학 교육 · 사내 강사 제도 · 이문화 교육 · 독서통신(업무 교육
--   또는 의무 이수) · 사내 추천 마일리지(채용 보상) · 천안공장 워크숍오락실(1회성 프로그램) ·
--   CO-TALK(에스엘미러텍) · 경조규정 개정 안건(제도 내용 없음 — 근거표 판단 요청).
--   공고 근거 0행 / 전체 24행.
--   SORT 섹션 순서(정본 65쪽에서 처음 나온 순서, 보조 쪽에만 있는 카테고리는 끝):
--   flexibility 10 · compensation 20 · leisure 30 · family 40 · health 50 · perks 60 · work_env 70 ·
--   growth 80.
-- 검증 · 감사 판정 반영(2026-10-10): 육아휴직 상회분 표기와 노사협의회 안건 표기 정리 · 건강검진 연 1회 반영 · 통신비 행 이름을 업무 통신비 지원으로 — 최종 24행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('sl_corp', '에스엘',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '자동차부품', 'S', 'https://www.slworld.com/include/esg_report_2026_ko.pdf');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'sl_corp');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.slworld.com/include/esg_report_2026_ko.pdf'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무 유연성 (flexibility) — 보고서 65쪽 조직문화 활성화 · 가족친화문화 조성, 43쪽 ──
  (@comp_id, 'flex_work', '유연근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '일과 삶의 균형을 지원하고 업무 효율성을 높이기 위해 유연근무제 시행, 출산과 양육 등으로 근무시간 조정이 필요한 임직원 대상 유연근무제도 운영 (2026 지속가능경영보고서 65쪽 조직문화 활성화 · 가족친화문화 조성) — 유연근무 방식·출퇴근 시간대 미기재', 10),
  (@comp_id, 'remote_work', '재택근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '일과 삶의 균형을 지원하고 업무 효율성을 높이기 위해 재택근무제 시행 (2026 지속가능경영보고서 65쪽 조직문화 활성화) — 재택 횟수·대상 직무 미기재', 11),

  -- ── 보상·금전 (compensation) — 보고서 65쪽 본문 · 표, 62쪽 주요 보상/포상제도 ──
  (@comp_id, 'excellence_award', 'GDS·우수 특허상 등 포상 제도', NULL, 'compensation',
   'est', NULL, TRUE, '동료 간 칭찬과 피드백 메시지를 상품권 등으로 교환할 수 있는 마일리지를 제공하는 쪽지문화 제도 (2026 지속가능경영보고서 65쪽 조직문화 활성화), 정기 인사 평가 우수 인원 중 조직장 추천 인원을 선발해 포상휴가비와 유급휴가를 주는 GDS 제도, 임직원 특허출원 내역 중 난이도와 특허 영향력을 고려한 우수 특허상, 각 부문별 최우수 인원 선정 회장·대표이사 격 상장 및 포상 (같은 보고서 62쪽 주요 보상/포상제도 표) — 포상 금액·선발 인원 미기재', 20),
  (@comp_id, 'long_service_bonus', '장기근속 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속 시 메달 수여 및 여행 자금 지원 (2026 지속가능경영보고서 65쪽 복리후생 제도 표 장기근속 포상 항목) — 근속 연수 기준·여행 자금 금액 미기재', 21),
  (@comp_id, 'profit_sharing', '성과급 (경영성과 기준)', NULL, 'compensation',
   'est', NULL, TRUE, '대상 전체, 경영성과에 따라 노사 합의 하에 성과급 결정 및 지급 (2026 지속가능경영보고서 62쪽 주요 보상/포상제도 표 성과급 항목) — 지급률·지급 시기 미기재', 22),

  -- ── 여가·문화 (leisure) — 보고서 65쪽 ──
  (@comp_id, 'culture_day', 'SL CULTURE DAY', NULL, 'leisure',
   'est', NULL, TRUE, '임직원이 공연과 전시 등 문화예술 활동을 경험할 수 있도록 매달 CULTURE DAY 프로그램을 통해 사내 밴드 공연, 캐리커처 행사 등 개최 (2026 지속가능경영보고서 65쪽 조직문화 활성화) — 참여 방식·근무시간 내 운영 여부 미기재', 30),
  (@comp_id, 'company_event', '임직원 가족초청 행사', NULL, 'leisure',
   'est', NULL, TRUE, '매년 가족의 달을 맞아 임직원 가족초청 행사 진행 (2026 지속가능경영보고서 65쪽 가족친화문화 조성), 2025년 가정의 달 지역 연고 구단 삼성라이온즈 경기 단체 관람 가족 참여 프로그램 Family On! 응원의 시간 운영 (같은 쪽 사례) — 초청 가족 범위·비용 지원 미기재', 31),
  (@comp_id, 'sports_ticket', '스포츠 관람 지원', NULL, 'leisure',
   'est', NULL, TRUE, '지역 연고 야구, 축구경기 관람 지원 (2026 지속가능경영보고서 65쪽 복리후생 제도 표 스포츠 관람 지원 항목) — 지원 횟수·지원 방식 미기재', 32),

  -- ── 가족 (family) — 보고서 65쪽 가족친화문화 조성 · 표, 60쪽 ──
  (@comp_id, 'parenting', '출산·양육 지원', NULL, 'family',
   'est', NULL, TRUE, '임산부 전용 주차구역, 출산 시 축하선물, 입학 축하금과 교복 구입비 등 양육 지원 제도 (2026 지속가능경영보고서 65쪽 가족친화문화 조성), 만 8세 이하 또는 초등학교 2학년 이하 자녀가 있는 임직원 대상 무급 육아휴직 최대 2년(법정 1년에 1년 추가) (같은 쪽 복리후생 제도 표 육아휴직 항목), 2025년 4분기 노사협의회 안건 입학축하금 및 교복구입비 인상 (같은 보고서 60쪽 노사협의회 운영 현황) — 선물 품목·축하금 금액 미기재', 40),
  (@comp_id, 'child_edu', '자녀 급식비·학자금', NULL, 'family',
   'est', NULL, TRUE, '자녀가 있는 임직원 대상 자녀의 연령에 따른 급식비 또는 학자금 지급 (2026 지속가능경영보고서 65쪽 가족친화문화 조성) — 연령 구간·지급액 미기재', 41),

  -- ── 건강 (health) — 보고서 65쪽 표, 55쪽 근로자 건강관리 ──
  (@comp_id, 'health_check', '종합 건강검진·추가 검진', NULL, 'health',
   'est', NULL, TRUE, '임직원 대상 연 1회 건강검진, 내원 또는 출장 검진 (2026 지속가능경영보고서 55쪽 근로자 건강검진), 종합 건강검진 지원 (같은 보고서 65쪽 복리후생 제도 표 건강검진 항목), 내시경 검사, 초음파 검사, 혈액 종양표지자 검사 등의 추가 검진 지원 (55쪽 근로자 건강검진) — 비용 지원 범위·가족 포함 여부 미기재', 50),
  (@comp_id, 'mental', '힐링서비스 (심리상담)', NULL, 'health',
   'est', NULL, TRUE, '정신건강을 위한 상담 프로그램 지원 (2026 지속가능경영보고서 65쪽 복리후생 제도 표 힐링서비스 항목), 전 임직원 대상 외부 심리전문가를 통한 온/오프라인 상담, 상담 비용 전액 회사 부담, 기본 1인당 연 8회까지 이용, 필요한 경우 요청을 통해 추가 이용 (같은 보고서 55쪽 임직원 건강관리 프로그램) — 가족 이용 여부 미기재', 51),
  (@comp_id, 'medical', '가족 치료비 지원', NULL, 'health',
   'est', NULL, TRUE, '중대 질환 및 중증장애 가족 치료비 지원 (2026 지속가능경영보고서 65쪽 복리후생 제도 표 가족 치료비 지원 항목) — 대상 가족 범위·지원 한도 미기재', 52),
  (@comp_id, 'fitness', '스트레칭룸·건강 증진 챌린지', NULL, 'health',
   'est', NULL, TRUE, '체력 증진을 위한 스트레칭룸 조성, 인바디 챌린지, 걷기 챌린지 등 건강 증진 프로그램 운영 (2026 지속가능경영보고서 55쪽 임직원 건강관리 프로그램) — 운영 사업장·이용 시간 미기재', 53),

  -- ── 경제적 부가혜택 (perks) — 보고서 65쪽 표, 43쪽 · 57쪽 ──
  (@comp_id, 'transport', '출퇴근 차량유지비 지원', NULL, 'perks',
   'est', NULL, TRUE, '출퇴근 차량유지비 지원 (2026 지속가능경영보고서 65쪽 복리후생 제도 표 차량/통신비 지원 항목) — 지원 금액·지급 대상 미기재', 60),
  (@comp_id, 'telecom', '업무 통신비 지원', NULL, 'perks',
   'est', NULL, TRUE, '업무 수행 통신비 지원 (2026 지속가능경영보고서 65쪽 복리후생 제도 표 차량/통신비 지원 항목) — 지원 금액·지급 대상 미기재', 61),
  (@comp_id, 'relocation', '초기 정착자금 지원 (신입·경력사원)', NULL, 'perks',
   'est', NULL, TRUE, '신입, 경력사원의 초기 정착자금 지원 (2026 지속가능경영보고서 65쪽 복리후생 제도 표 생활안정자금 지원 항목) — 지급액·지급 조건 미기재', 62),
  (@comp_id, 'commute_subsidy', '통근버스', NULL, 'perks',
   'est', NULL, TRUE, '유연근무제 및 사내 통근버스 운영을 통해 직원들의 개별 출퇴근 차량 이용 감축 (2026 지속가능경영보고서 43쪽 친환경 업무 차량 전환) — 운행 사업장·노선·이용 비용 미기재', 63),
  (@comp_id, 'snack_bar', '사내 카페', NULL, 'perks',
   'est', NULL, TRUE, '장애인 직원이 근무하는 사내 카페 운영 (2026 지속가능경영보고서 57쪽 SL 사내 카페 운영) — 이용 요금·운영 사업장 미기재', 64),

  -- ── 근무환경 (work_env) — 보고서 65쪽 표 ──
  (@comp_id, 'dormitory', '사택 제공', NULL, 'work_env',
   'est', NULL, TRUE, '사원주택 또는 사원 임대주택 지원 (2026 지속가능경영보고서 65쪽 복리후생 제도 표 사택 제공 항목) — 입주 자격·사업장별 운영 여부 미기재', 70),

  -- ── 성장·교육 (growth) — 보고서 63쪽 자기주도학습 지원 · 사내 공모 제도 ──
  (@comp_id, 'self_development', '자격증 보상제도', NULL, 'growth',
   'est', NULL, TRUE, '자격 시험 응시료 1회 기준 최대 10만 원까지 지원, 자격증의 직무 연관성, 업무 활용도 및 난이도 등을 종합 평가해 등급에 따른 포상과 마일리지 지급 (2026 지속가능경영보고서 63쪽 자기주도학습 지원) — 등급별 포상 금액·연간 응시 횟수 미기재', 80),
  (@comp_id, 'lang', '외국어 학습비 전액 지원', NULL, 'growth',
   'est', NULL, TRUE, '자율적인 학습 활동을 장려하기 위해 외국어 학습 비용 전액 지원 (2026 지속가능경영보고서 63쪽 자기주도학습 지원) — 대상 언어·연간 한도 미기재', 81),
  (@comp_id, 'edu_support', '학습 동아리 활동비 지원', NULL, 'growth',
   'est', NULL, TRUE, '자율적인 학습 활동을 장려하기 위해 학습 동아리의 활동비 전액 지원 (2026 지속가능경영보고서 63쪽 자기주도학습 지원) — 동아리 구성 요건·연간 한도 미기재', 82),
  (@comp_id, 'career', '사내 공모 제도', NULL, 'growth',
   'est', NULL, TRUE, '조직 내 충원 수요 발생 시 전사 공모, 임직원이 개인의 역량과 경력을 기반으로 희망 부서 및 직무에 지원, 서류 심사 및 면접을 거쳐 선발 (2026 지속가능경영보고서 63쪽 사내 공모 제도) — 지원 자격·공모 주기 미기재', 83)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
