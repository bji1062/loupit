-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 빙그레 복리후생 데이터 (신규 회사 — 웨이브 6)
-- 출처: AI 파싱 (2026-10-14)
-- URL: https://recruit.bing.co.kr/app/web/about/benefit.html
-- badge: est
--
-- 참고:
--   정본은 주식회사 빙그레 자기 도메인 채용 서브도메인 recruit.bing.co.kr 의 About 빙그레 > 복리후생 페이지다.
--   기업 홈 www.bing.co.kr 메뉴 인재채용이 이곳으로 연결된다. SSR — 원본 HTML 표 table.benefittb 에
--   4카테고리 40항목이 텍스트로 있고 카테고리 이름 4개만 이미지(Pay · Benefits · Environments ·
--   Learning and Development — 판독함). 헤드리스 렌더 없음.
--   보조 출처 (a) 법인 직접 발행 2026 지속가능경영보고서(2026년 6월 발행 · 보고 범위 빙그레 별도 국내 전 사업장)
--     63~67쪽 · 75쪽 · 79쪽 — 67쪽 복리후생 제도 표가 정본과 같은 4카테고리를 거의 같은 문장으로 받친다.
--     (b) 자기 도메인 보도자료 anno_idx=247 가족친화인증 재획득(2024-12-09) — 유연근무 · PC-OFF ·
--     특별휴가 8일 · 자녀 학자금 · 종합검진 · 하계휴양소 · 기념일 기프트 카드 설명.
--     (c) 같은 채용 사이트 인재상/인재육성 · 인사제도 보상 체계 페이지 — 교육 · 성과 인센티브 설명.
--   귀속: 빙그레 단독 채용 사이트 · 자기 발행 보고서 · 자기 도메인 보도자료라 그룹 각주 없음.
--     원문에 해태 · 계열 · 그룹 · 상이 0회. 해태아이스크림은 2026-04 소규모합병으로 흡수돼 별도 법인이 아니다.
--   금액: 금액 행 1 — meal 288 추정(중식 1끼 × 12,000원 × 240일). 원 단위 금액 명시 0건이라 stated 0.
--   제외: 법정(4대 보험 · 주 5일 근무 · 연차수당 · 연차와 반차 · 가족친화 법정 제도 · 공휴일 대체) ·
--     급여성(자격 면허 및 직책 수당 · 성과연봉제) · 업무 교육(신입사원 입문과정 · 마케팅대학 ·
--     직무 전문가 과정 · 리더십 교육 · 국제 심포지엄 리더쉽 교육) · 팀빌딩 프로그램(판단 요청) ·
--     권장(9일 연속 휴가 사용 독려 자체).
--   공고 근거 0행 / 전체 27행. 신규 코드 0.
--   SORT 섹션 순서 = 정본 페이지에서 카테고리가 처음 나온 순서:
--     compensation 10 · perks 20 · family 30 · leisure 40 · health 50 · flexibility 60 ·
--     work_env 70 · time_off 80 · growth 90
-- 검증 · 감사 판정 반영(2026-10-14): 기념일 선물을 holiday_gift 에서 갈라 birthday_gift 추가 · Culture Class 를 동우회 행에서 edu_support 행으로 · 건강검진 전 직원 단언 걷기 · 휴양소 출처 괄호 정리 · 이동희망 신청 career 추가 · Mobile Office work_tools 유지 — 최종 29행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('binggrae', '빙그레',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '식품', 'B', 'https://recruit.bing.co.kr/app/web/about/benefit.html');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'binggrae');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://recruit.bing.co.kr/app/web/about/benefit.html'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상 (compensation) — 정본 Pay · Benefits · Environments, 인사제도 보상 체계, 보고서 67쪽 ──
  (@comp_id, 'incentive', '성과 Incentive (전사)·Binggrae Sales Incentive (영업)', NULL, 'compensation',
   'est', NULL, TRUE, '성과 Incentive (전사), Binggrae Sales Incentive (영업) (공식 채용 페이지 복리후생 Pay 항목, 2026 지속가능경영보고서 67쪽 복리후생 제도 표), Performance Incentive 회사 전체 성과에 따라 지급 여부 및 지급률을 결정하고 개인 성과에 따라 차등 지급하는 전사 인센티브 제도 (공식 채용 페이지 인사제도 보상 체계 항목) — 지급률·영업 인센티브 지급 기준 미기재', 10),
  (@comp_id, 'holiday_gift', '명절조 지급', NULL, 'compensation',
   'est', NULL, TRUE, '명절조 지급 (공식 채용 페이지 복리후생 Pay 항목, 2026 지속가능경영보고서 67쪽 복리후생 제도 표) — 지급 내용·금액 미기재', 11),
  (@comp_id, 'long_service_bonus', '장기근속자 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속자 포상 (공식 채용 페이지 복리후생 Benefits 항목, 2026 지속가능경영보고서 67쪽 복리후생 제도 표, 2024년 12월 가족친화인증 재획득 보도자료) — 포상 근속 연수·포상 내용 미기재', 12),
  (@comp_id, 'excellence_award', '우수사원 표창·보상', NULL, 'compensation',
   'est', NULL, TRUE, '우수사원 표창 / 보상 (공식 채용 페이지 복리후생 Benefits 항목, 2026 지속가능경영보고서 67쪽 복리후생 제도 표) — 선정 기준·보상 내용 미기재', 13),

  -- ── 경제적 부가혜택 (perks) — 정본 Pay · Environments, 보고서 67쪽 ──
  (@comp_id, 'meal', '중식대 지원', 288, 'perks',
   'est', '중식대 지원 (공식 채용 페이지 복리후생 Pay 항목, 2026 지속가능경영보고서 67쪽 복리후생 제도 표) — 지원 금액·지급 방식 미기재 (하루 1끼 × 1끼 12,000원 × 연 240일 추정)', FALSE, NULL, 20),
  (@comp_id, 'transport', '유류비 전액 지원 (영업)', NULL, 'perks',
   'est', NULL, TRUE, '유류비 전액 지원 (영업) (공식 채용 페이지 복리후생 Pay 항목, 2026 지속가능경영보고서 67쪽 복리후생 제도 표) — 영업 직군 대상, 지원 범위·정산 방식 미기재', 21),
  (@comp_id, 'telecom', '휴대폰 사용료 지원 (영업)', NULL, 'perks',
   'est', NULL, TRUE, '휴대폰 사용료 지원 (영업) (공식 채용 페이지 복리후생 Pay 항목, 2026 지속가능경영보고서 67쪽 복리후생 제도 표) — 영업 직군 대상, 지원 한도 미기재', 22),
  (@comp_id, 'commute_subsidy', '통근버스 운행 (공장)', NULL, 'perks',
   'est', NULL, TRUE, '통근버스 운행 (공장) (공식 채용 페이지 복리후생 Environments 항목, 2026 지속가능경영보고서 67쪽 복리후생 제도 표) — 공장 근무자 대상, 노선·이용료 미기재', 23),
  (@comp_id, 'relocation', '발령 임직원 주거 복지 지원', NULL, 'perks',
   'est', NULL, TRUE, '발령 임직원 주거 복지 지원 (2026 지속가능경영보고서 67쪽 복리후생 제도 표 Environments 항목) — 지원 형태·금액·대상 발령 범위 미기재', 24),
  (@comp_id, 'birthday_gift', '기념일 선물', NULL, 'perks',
   'est', NULL, TRUE, '각종 기념일 선물 지급 (공식 채용 페이지 복리후생 Environments 항목, 2026 지속가능경영보고서 67쪽 복리후생 제도 표), 임직원 기념일 기프트 카드 지급 (2024년 12월 보도자료) — 기념일 종류·선물 금액 미기재', 25),

  -- ── 가족 (family) — 정본 Pay · Environments, 보고서 67 · 79쪽, 보도자료 ──
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금 지원 (공식 채용 페이지 복리후생 Pay 항목, 2026 지속가능경영보고서 67쪽 복리후생 제도 표), 대학까지 자녀 학자금 지원 (2024년 12월 가족친화인증 재획득 보도자료), 유아교육비 확대 (2026 지속가능경영보고서 79쪽 인권경영 2025년 성과) — 학년별 지원 한도·대상 자녀 수 미기재', 30),
  (@comp_id, 'event', '경조금·경조휴가', NULL, 'family',
   'est', NULL, TRUE, '각종 경조금 지원 (공식 채용 페이지 복리후생 Pay 항목), 경조휴가 (같은 페이지 Environments 항목, 2026 지속가능경영보고서 67쪽 복리후생 제도 표) — 경조 사유별 금액·휴가 일수 미기재', 31),
  (@comp_id, 'parenting', '출산지원금', NULL, 'family',
   'est', NULL, TRUE, '출산지원금 신설 (2026 지속가능경영보고서 79쪽 인권경영 중장기 로드맵 2025년 성과) — 지급 금액·지급 조건 미기재', 32),

  -- ── 여가 (leisure) — 정본 Benefits, 보고서 67쪽, 보도자료 ──
  (@comp_id, 'resort', '전국 주요 콘도 이용·하계휴양소', NULL, 'leisure',
   'est', NULL, TRUE, '전국 주요콘도 이용 (공식 채용 페이지 복리후생 Benefits 항목, 2026 지속가능경영보고서 67쪽 복리후생 제도 표), 하계휴양소 운영 (2024년 12월 보도자료) — 이용 일수·본인 부담 미기재', 40),
  (@comp_id, 'club', '사내 동우회', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동우회 (공식 채용 페이지 복리후생 Benefits 항목, 2026 지속가능경영보고서 67쪽 복리후생 제도 표), 동우회를 통해 임직원 간 소통과 취미 활동 지원 (같은 보고서 67쪽 노사관리 및 소통), 직원 동우회 활동 (2024년 12월 가족친화인증 재획득 보도자료) — 동우회 지원 금액·동우회 종류 미기재', 41),

  -- ── 건강 (health) — 정본 Benefits, 보고서 67 · 75쪽, 보도자료 ──
  (@comp_id, 'insurance', '단체 상해보험', NULL, 'health',
   'est', NULL, TRUE, '단체 상해보험 (공식 채용 페이지 복리후생 Benefits 항목, 2026 지속가능경영보고서 67쪽 복리후생 제도 표) — 보장 범위·가족 포함 여부 미기재', 50),
  (@comp_id, 'health_check', '정기 건강검진·배우자 종합검진', NULL, 'health',
   'est', NULL, TRUE, '정기 건강검진, 배우자 종합검진 (공식 채용 페이지 복리후생 Benefits 항목), 종합 건강검진 실시, 일정 연령 이상 임직원의 배우자 대상 건강검진(격년) (2026 지속가능경영보고서 75쪽 보건 관리), 본인 및 배우자 종합검진 (2024년 12월 가족친화인증 재획득 보도자료) — 종합검진 대상 범위·검진 항목·배우자 대상 연령 미기재', 51),

  -- ── 근무 유연성 (flexibility) — 정본 Environments, 보고서 66쪽, 보도자료 ──
  (@comp_id, 'flex_work', '4주 단위 자율근로제 (Flexible time)', NULL, 'flexibility',
   'est', NULL, TRUE, '4주 단위 자율근로제 (Flexible time) (공식 채용 페이지 복리후생 Environments 항목), 온라인 인프라를 활용하여 전 임직원이 4주 단위 자율 근로제 운영, 출퇴근 시간 조정 (2026 지속가능경영보고서 66쪽 자율 근로제), 1개월 160시간의 근무 시간을 개인이 자유롭게 조정할 수 있는 유연근무제 (2024년 12월 가족친화인증 재획득 보도자료) — 의무 근무 시간대 미기재', 60),
  (@comp_id, 'pc_off', 'PC-OFF 제도', NULL, 'flexibility',
   'est', NULL, TRUE, '근무시간 외 PC 강제 OFF (2026 지속가능경영보고서 66쪽 Smart Work), 근무시간이 지나면 PC 전원이 꺼지는 PC-OFF 제도 (2024년 12월 가족친화인증 재획득 보도자료) — 적용 시각·예외 신청 절차 미기재', 61),

  -- ── 근무환경 (work_env) — 정본 Environments, 보고서 67쪽 ──
  (@comp_id, 'work_tools', 'Mobile Office 지원', NULL, 'work_env',
   'est', NULL, TRUE, 'Mobile Office 지원 (공식 채용 페이지 복리후생 Environments 항목, 2026 지속가능경영보고서 67쪽 복리후생 제도 표) — 지원 내용·대상 미기재', 70),
  (@comp_id, 'dormitory', '기숙사 운영 (공장)', NULL, 'work_env',
   'est', NULL, TRUE, '사원아파트 운영 (공장) (공식 채용 페이지 복리후생 Environments 항목), 기숙사 운영 (공장) (2026 지속가능경영보고서 67쪽 복리후생 제도 표) — 공장 근무자 대상, 입주 자격·본인 부담 미기재', 71),

  -- ── 휴가 (time_off) — 정본 Environments, 보고서 66쪽, 보도자료 ──
  (@comp_id, 'refresh_leave', '休 Nine 제도 (연차 외 추가 휴가 8일)', NULL, 'time_off',
   'est', NULL, TRUE, '休 Nine 제도 (9일 연속휴가) (공식 채용 페이지 복리후생 Environments 항목), 법적 연차 외 추가 휴일 8일 부여 (2026 지속가능경영보고서 66쪽 休Nine제도), 8일의 특별휴가 추가 부여, 5일간의 휴가기간 전후로 주말을 포함하여 총 9일간 장기 휴가 (2024년 12월 가족친화인증 재획득 보도자료) — 특별휴가 사용 시기·유급 여부 미기재', 80),
  (@comp_id, 'leave_general', '2시간 단위 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '2시간 단위 휴가제 도입 (공식 채용 페이지 복리후생 Environments 항목, 2026 지속가능경영보고서 66쪽 休Nine제도) — 사용 한도·신청 절차 미기재', 81),

  -- ── 성장 (growth) — 정본 Learning and Development, 인재육성 페이지, 보고서 63~65 · 67쪽 ──
  (@comp_id, 'conference', '해외 테마 연수·해외 세미나', NULL, 'growth',
   'est', NULL, TRUE, '해외 테마 연수, 해외 세미나 (공식 채용 페이지 복리후생 Learning & Development 항목, 2026 지속가능경영보고서 67쪽 복리후생 제도 표), 해외연수 및 세미나 실시 (공식 채용 페이지 인재육성 Global Business 교육 및 해외연수 항목), 평가 결과를 해외연수자 선발에 반영 (2026 지속가능경영보고서 65쪽 공정한 평가와 보상) — 연수 기간·선발 인원·비용 지원 범위 미기재', 90),
  (@comp_id, 'lang', '외국어 강좌', NULL, 'growth',
   'est', NULL, TRUE, '외국어 강좌 (공식 채용 페이지 복리후생 Learning & Development 항목, 2026 지속가능경영보고서 67쪽 복리후생 제도 표), 어학교육 (공식 채용 페이지 인재육성 Global Business 교육 및 해외연수 항목), 어학프로그램 (2026 지속가능경영보고서 63쪽 자기주도·동료학습) — 강좌 언어·수강료 지원 범위 미기재', 91),
  (@comp_id, 'mba', 'MBA 학위과정', NULL, 'growth',
   'est', NULL, TRUE, 'MBA 학위과정 (공식 채용 페이지 복리후생 Learning & Development 항목), 국내 및 해외 대학원 위탁과정 시행 (공식 채용 페이지 인재육성 MBA 학위과정 항목), 대학 위탁과정(MBA·R&D석/박사·글로벌) (2026 지속가능경영보고서 63쪽 인재육성체계) — 선발 기준·학비 지원 범위 미기재', 92),
  (@comp_id, 'edu_support', '스마트러닝·학습조직 (Study Group)·자기주도·동료학습·Culture Class', NULL, 'growth',
   'est', NULL, TRUE, '스마트러닝, 학습조직 (Study Group), 자기주도·동료학습 (공식 채용 페이지 복리후생 Learning & Development 항목), Smart Learning(역량개발 도서학습), 자율적 학습조직(Study Group) (2026 지속가능경영보고서 63쪽 자기주도·동료학습), 필요한 교육과 학습자원을 자유롭게 활용하고 동료와 함께 배우는 자기주도·동료학습 (같은 보고서 64쪽), Culture Class를 통한 임직원 취미 활동 지원 (같은 보고서 67쪽 노사관리 및 소통), 다양한 문화 강좌 운영 (2024년 12월 가족친화인증 재획득 보도자료) — 학습조직 지원 금액·학습 플랫폼·강좌 종류 미기재', 93),
  (@comp_id, 'retirement_support', '퇴직자 지원 프로그램 (BC Outplacement)', NULL, 'growth',
   'est', NULL, TRUE, '희망퇴직, 명예퇴직 2단계로 운영, 챌린지 휴가, 대학 학자금 선지급, 종합건강검진 지원 등 포함 (2026 지속가능경영보고서 64쪽 퇴직자 지원 프로그램 BC Outplacement) — 대상 요건·휴가 일수·지원 금액 미기재', 94),
  (@comp_id, 'career', '이동희망 신청 (연중 상시)', NULL, 'growth',
   'est', NULL, TRUE, '연중 상시로 이동희망 신청 접수 (2026 지속가능경영보고서 61쪽 공정한 채용과 기회 제공) — 이동 가능 부서·선발 기준 미기재', 95)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
