-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 롯데하이마트 복리후생 데이터 (신규 회사 — 웨이브 12)
-- 출처: AI 파싱 (2026-10-18)
-- URL: https://recruit.himart.co.kr/commonAction.do?S_DSCLASS=biz.apply.Apply_index&S_DSMETHOD=goInitPage&S_FORWARD=/hr/weal.jsp&S_PAGE_NO=1
-- badge: est
--
-- 참고:
--   정본 = 법인 자기 도메인 인재채용 사이트(recruit.himart.co.kr) 인사제도 > 복리후생 페이지(SSR · GET 으로 열림 ·
--     급여제도 · 성과급 · 복리후생 8항목). 메뉴 링크는 폼 제출이지만 같은 주소를 GET 으로 열면 같은 본문이 온다.
--   보조 1 = 같은 인재채용 사이트 인사제도 > 인재육성 페이지(위탁사내대학 · 외부교육 지원 · LEP제도).
--   보조 2 = 롯데하이마트 발행 2025 지속가능경영보고서(company.himart.co.kr 지속가능경영 보고서 목록 ·
--     발행 2026년 6월 · 보고 기간 2025-01-01~2025-12-31 · 보고 범위 롯데하이마트 본사 및 전국 지사 · 지점 · 물류센터)
--     40 · 74 · 75 · 78 · 80 · 81 · 83 · 96 · 107쪽.
--   보조 3 = 2026 반기보고서(OpenDART 20260814002927) 직원 등 현황 유연근무제도 사용 현황 표 · 2025 사업보고서(20260311004061) 같은 표.
--   렌더 방식 = 원본 HTML · PDF 텍스트 · 공시 XML. 헤드리스 렌더 · 이미지 판독 없음.
--   귀속: 전부 롯데하이마트 자기 도메인 · 자기 발행 보고서 · 자기 공시 문장 — 그룹 각주 없음.
--     롯데 계열사 합동 행사 · 그룹사 간 이동 제도는 롯데하이마트가 주어인 보고서 문장이라 각주 없이 싣는다.
--   금액: 금액 행 0(원문 숫자는 휴가 횟수 · 숙박 박수 · 상담 통계 · 연도뿐 — 서술에만).
--   같은 제도를 채용 페이지와 보고서가 다르게 적은 곳(자녀 학자금)은 발행일 있는 보고서 문장을 따랐다.
--   제외: 법정(임신기 근로시간 단축 · 난임 치료 휴가 · 연장근무 보상 휴가 · 전직지원 재취업 프로그램 — 직원 3,776명) ·
--     업무 교육(입문 · 상품 · Curator · 상담스킬코치 · 승진 · 신임 직책자 · Meister 코칭 · 예비 점장 · 터치클래스 ·
--     아크로폴리스 · 하이포텐셜 · Lotte MBA 핵심 인재 과정) · 급여제도 · 직책수당(급여성) · 발탁승진 · 사우회(혜택 미기재) ·
--     임원 보수 칸 기타 근로소득 · 채용 페이지 HTML 주석 속 옛 승진제도 블록.
--   공고 근거 0행 / 전체 26행
--   SORT 섹션: compensation 10 · perks 20 · time_off 30 · family 40 · health 50(정본 페이지 순) ·
--     growth 60(보조 1) · flexibility 70 · leisure 80(보고서 · 공시에만)
-- 검증 · 감사 판정 반영(2026-10-18): 사우회를 경조제도 event 행에 병합 · 핵심 인재 경영 역량 향상 과정 Lotte MBA 를 위탁 사내대학 mba 서술에 병합(리드 판정 157) · 40쪽 온실가스 산정 범위의 사내 식당 meal 과 휴양소 resort 몫 유지(리드 판정 156) · 참고 블록 제외 줄의 사우회와 Lotte MBA 는 이 판정으로 뒤집힘 — 최종 26행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('lotte_himart', '롯데하이마트',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '유통', 'L', 'https://recruit.himart.co.kr/commonAction.do?S_DSCLASS=biz.apply.Apply_index&S_DSMETHOD=goInitPage&S_FORWARD=/hr/weal.jsp&S_PAGE_NO=1');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'lotte_himart');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://recruit.himart.co.kr/commonAction.do?S_DSCLASS=biz.apply.Apply_index&S_DSMETHOD=goInitPage&S_FORWARD=/hr/weal.jsp&S_PAGE_NO=1'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상 (compensation) — 채용 사이트 복리후생 성과급 · 보고서 81 · 83 · 107쪽 ──
  (@comp_id, 'incentive', '성과급', NULL, 'compensation',
   'est', NULL, TRUE, '급여와 복리후생 외에 구성원의 성과에 따라 차등적으로 성과급 지급 (공식 채용 페이지 복리후생 성과급 항목), 성과평가 결과와 연계한 성과급 차등 지급 (2025 지속가능경영보고서 81쪽 성과평가 및 보상 제도 항목) — 지급 기준·지급률 미기재', 10),
  (@comp_id, 'excellence_award', '포상 제도', NULL, 'compensation',
   'est', NULL, TRUE, '전략 수행 성과 포상, 전담별 목표 달성 인원 성과 우수 포상, 상시 포상·롯데하이마트人·Best 동료·현장소통 우수 등 기여자 포상 (2025 지속가능경영보고서 81쪽 롯데하이마트 포상 제도 항목), 혁신적인 리더를 선발 및 격려하기 위해 전 직원 모바일 설문과 심사 평가단 선발을 거쳐 시상하는 Fearless Leader 프로그램 (83쪽 상호 존중 조직문화 항목) — 포상 금액·포상 내용 미기재', 11),
  (@comp_id, 'stock_option', '우리사주조합', NULL, 'compensation',
   'est', NULL, TRUE, '종업원의 동기 부여를 위해 우리사주조합 운영 (2025 지속가능경영보고서 107쪽 주식 발행 및 의결권 현황 항목) — 회사 출연 여부·지원 내용 미기재', 12),
  -- ── 경제적 부가혜택 (perks) — 채용 사이트 복리후생 · 보고서 40 · 83쪽 ──
  (@comp_id, 'welfare_point', '선택적 복리후생 (복지카드)', NULL, 'perks',
   'est', NULL, TRUE, '개인별로 발급되는 복지카드를 통해 의료비, 자기계발비, 문화생활비 등 지원 (공식 채용 페이지 복리후생 선택적 복리후생 항목) — 배정 금액·사용처 범위 미기재', 20),
  (@comp_id, 'birthday_gift', '기념일 선물', NULL, 'perks',
   'est', NULL, TRUE, '본인 생일 및 배우자 생일, 결혼기념일에 선물 지급 (공식 채용 페이지 복리후생 기념일 지원 항목) — 선물 품목·금액 미기재', 21),
  (@comp_id, 'car_rental', '다자녀 가구 차량렌탈 지원', NULL, 'perks',
   'est', NULL, TRUE, '다자녀 가구 차량렌탈 지원 (2025 지속가능경영보고서 83쪽 임신·출산·육아 관련 제도 육아 항목) — 다자녀 기준·차종·지원 기간 미기재', 22),
  (@comp_id, 'meal', '사내 식당', NULL, 'perks',
   'est', NULL, TRUE, '사내 식당 운영 (2025 지속가능경영보고서 40쪽 온실가스 산정 범위 Scope 1 항목) — 운영 사업장·제공 끼니·식대 부담 미기재', 23),
  -- ── 휴가 (time_off) — 채용 사이트 복리후생 휴가제도 · 보고서 83쪽 ──
  (@comp_id, 'leave_general', '포상휴가', NULL, 'time_off',
   'est', NULL, TRUE, '근무성적이 우수한 자에 대한 포상휴가 지원 (공식 채용 페이지 복리후생 휴가제도 항목) — 휴가 일수·선정 기준 미기재', 30),
  (@comp_id, 'refresh_leave', '연 2회 휴가 (법정 휴가 외)', NULL, 'time_off',
   'est', NULL, TRUE, '법정 연차 외 연 2회 휴가 실시 (2025 지속가능경영보고서 83쪽 근무 시간 및 방식 관련 제도 항목) — 휴가 일수·부여 조건 미기재', 31),
  -- ── 가족 (family) — 채용 사이트 복리후생 경조제도 · 교육비 지원 · 보고서 83쪽 ──
  (@comp_id, 'event', '경조제도·사우회', NULL, 'family',
   'est', NULL, TRUE, '결혼, 조의, 출산 시 경조 휴가와 경조금 지원 (공식 채용 페이지 복리후생 경조제도 항목), 직원들의 상호부조와 복리증진을 위해 입사와 동시에 가입·운영되는 사우회 (같은 페이지 사우회 항목) — 경조 구분별 금액·휴가 일수·사우회 지원 내용 미기재', 40),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '미취학 자녀, 대학생 자녀 학자금 지원 (2025 지속가능경영보고서 83쪽 임신·출산·육아 관련 제도 육아 항목), 임직원 자녀 교육비 지원 (공식 채용 페이지 복리후생 교육비 지원 항목) — 지원 한도·지원 학기 수 미기재', 41),
  (@comp_id, 'parenting', '임신·출산·육아 지원', NULL, 'family',
   'est', NULL, TRUE, '출산 전후 선물 지급, 육아휴직 의무화(최대 2년), 남성 육아휴직 의무화(1개월 이상 의무적 사용), 자녀 초등학교 입학 시 자녀 돌봄 휴직 지원, 대입축하금 별도 지원 (2025 지속가능경영보고서 83쪽 임신·출산·육아 관련 제도 항목) — 선물 품목·축하금 금액·휴직 중 급여 보전 여부 미기재', 42),
  (@comp_id, 'fertility_support', '난임 시술비 지원', NULL, 'family',
   'est', NULL, TRUE, '난임 시술비 지원 (2025 지속가능경영보고서 83쪽 임신·출산·육아 관련 제도 임신 항목) — 지원 한도·지원 횟수 미기재', 43),
  -- ── 건강 (health) — 채용 사이트 복리후생 건강검진 · 단체보험 · 보고서 74 · 75 · 96쪽 ──
  (@comp_id, 'health_check', '종합건강검진·가족 건강검진', NULL, 'health',
   'est', NULL, TRUE, '임직원 대상 회사 전액 비용 부담 정밀 종합건강검진 매년 시행 (공식 채용 페이지 복리후생 건강검진 항목), 전 직원 대상 연 1회 종합건강검진, 점장급 이상 직책자 및 40세 이상 직원 대상 배우자 또는 직계가족 건강검진 지원 (2025 지속가능경영보고서 96쪽 임직원 보건 관리 항목) — 검진 항목·가족 검진 지원 범위 미기재', 50),
  (@comp_id, 'insurance', '단체보험 (상해·암)', NULL, 'health',
   'est', NULL, TRUE, '회사의 전액 비용 부담으로 상해 보험 및 암 보험 가입, 상해로 인한 병원 입원 시 입원비 지원, 암 진단 시 일정의 보험금 지원 (공식 채용 페이지 복리후생 단체보험 항목) — 보장 한도·가족 포함 여부 미기재', 51),
  (@comp_id, 'clinic', '건강관리실', NULL, 'health',
   'est', NULL, TRUE, '본사에 보건관리자가 상주하는 건강관리실 운영 (2025 지속가능경영보고서 96쪽 임직원 보건 관리 항목) — 운영 시간·이용 내용 미기재', 52),
  (@comp_id, 'mental', '사외 심리상담 서비스 (EAP)', NULL, 'health',
   'est', NULL, TRUE, '정신건강, 업무 및 생활상의 어려움, 직장 내 갈등, 심리·정서 문제, 가정문제, 법률문제 등 주제의 사외 심리상담 서비스 제공, 상담 비용 회사 전액 부담 (2025 지속가능경영보고서 75쪽 심리상담 서비스 제공 항목), EAP(근로자 지원 프로그램)을 통한 직원 스트레스 관리 (74쪽 주요 이슈별 개선 방안 항목) — 연간 이용 횟수 한도·가족 이용 여부 미기재', 53),
  -- ── 성장 (growth) — 채용 사이트 인재육성 · 보고서 78 · 80쪽 ──
  (@comp_id, 'mba', '위탁 사내대학 (학위 취득)', NULL, 'growth',
   'est', NULL, TRUE, '위탁 사내대학을 통해 직원의 자기계발 및 학위 취득 지원 (공식 채용 페이지 인재육성 위탁사내대학 항목), 명지전문대·영진전문대 전문학사과정과 경희대·충남대·동아대 학사과정 제휴 대학 협약을 통한 학비 할인 등 교육 지원 혜택 (2025 지속가능경영보고서 80쪽 위탁 사내대학 항목), 핵심 인재 경영 역량 향상 과정(Lotte MBA) (78쪽 인재육성체계 항목) — 선발 기준·회사 부담 비율 미기재', 60),
  (@comp_id, 'self_development', '자격증 취득 지원', NULL, 'growth',
   'est', NULL, TRUE, '직무에 필요한 자격증 취득 지원 (공식 채용 페이지 인재육성 외부교육 지원 항목) — 지원 범위·한도 미기재', 61),
  (@comp_id, 'edu_support', '외부기관 교육·온라인 자기주도학습 지원', NULL, 'growth',
   'est', NULL, TRUE, '각종 외부기관 교육 지원 (공식 채용 페이지 인재육성 외부교육 지원 항목), 직무 관련 개인의 역량 향상을 위한 온라인 자기주도학습 지원 LEP제도 (같은 페이지 LEP제도 항목) — 지원 범위·대상 과정 미기재', 62),
  (@comp_id, 'career', '사내 공모 잡 포스팅·그룹사 간 이동 인 커리어', NULL, 'growth',
   'est', NULL, TRUE, '조직 내 공석 발생 시 내부 직원의 지원을 통해 직무 이동을 시행하는 사내 공모 제도 잡 포스팅(Job Posting), 직원이 희망 직무 또는 계열사로 이동할 수 있도록 지원하는 그룹사 간 인재 이동 제도 인 커리어(In Career) (2025 지속가능경영보고서 78쪽 사내 인사이동 프로그램 운영 항목) — 지원 자격·공모 주기 미기재', 63),
  -- ── 근무 유연성 (flexibility) — 보고서 83쪽 · 2026 반기보고서 ──
  (@comp_id, 'flex_work', '유연근무제 (시차출퇴근)', NULL, 'flexibility',
   'est', NULL, TRUE, '출퇴근 시간을 6가지 유형 내 자유롭게 선택 (2025 지속가능경영보고서 83쪽 근무 시간 및 방식 관련 제도 유연근무 제도 항목), 시차출근제 2015년 11월 도입 적용, 시차출퇴근제 사용자 2026년 상반기 102명 (2026 반기보고서 직원 등 현황 유연근무제도 사용 현황 항목) — 대상 직무·사용 조건 미기재', 70),
  (@comp_id, 'pc_off', 'PC ON/OFF', NULL, 'flexibility',
   'est', NULL, TRUE, '유연근무제와 연동되어 근무시간에 맞도록 PC ON/OFF 적용, 근무 시작 10분 전 ON·종료 5분 후 OFF, 휴일·휴가 시 PC 사용 차단 (2025 지속가능경영보고서 83쪽 근무 시간 및 방식 관련 제도 항목) — 적용 대상 미기재', 71),
  (@comp_id, 'family_day', '하이파이브 (기념일 조기 퇴근)', NULL, 'flexibility',
   'est', NULL, TRUE, '본인·배우자 생일 및 결혼기념일 시 17시 조기 퇴근 하이파이브 (2025 지속가능경영보고서 83쪽 근무 시간 및 방식 관련 제도 항목) — 적용 대상 미기재', 72),
  -- ── 여가 (leisure) — 보고서 40 · 83쪽 ──
  (@comp_id, 'resort', 'Refresh 휴가 숙박비 지원·휴양소', NULL, 'leisure',
   'est', NULL, TRUE, '3일 이상 휴가 사용 Refresh 휴가 시 최대 2박 숙박비 지원 (2025 지속가능경영보고서 83쪽 근무 시간 및 방식 관련 제도 항목), 휴양소 (40쪽 온실가스 산정 범위 Scope 1 항목) — 숙박비 한도·휴양소 위치·이용 조건 미기재', 80),
  (@comp_id, 'company_event', '계열사 합동 가족 프로그램', NULL, 'leisure',
   'est', NULL, TRUE, '롯데 패밀리 스카이런과 롯데 러브 패밀리 페스티벌 등 계열사 합동 프로그램을 통해 임직원과 가족의 소속감 제고 (2025 지속가능경영보고서 83쪽 계열사 합동 프로그램 항목) — 개최 주기·참가 비용 지원 미기재', 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
