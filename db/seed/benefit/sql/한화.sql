-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 한화 복리후생 데이터
-- 출처: AI 파싱 (2026-10-02)
-- URL: https://www.hanwhacorp.co.kr/hanwha/hrmanagement/hrsystem.jsp
-- badge: est
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 참고:
--   ㈜한화는 글로벌부문 · 건설부문 2개 부문의 자체사업과 자회사를 둔 지주 겸 사업회사다(공식 홈 회사소개 intro.jsp).
--     출처 = 법인 공식 홈 인재경영 인사제도 페이지(hanwhacorp.co.kr — 복지제도 절, 문장은 한화그룹 주어) +
--     글로벌부문 자기 도메인 회사생활 페이지(hanwhaglobal.co.kr/ko/hr-management/company-life) +
--     건설부문 자기 도메인 인사제도 · 인재양성 페이지(hwenc.co.kr/recruit/system_system.do · system_training.do).
--     전부 서버 렌더 HTML, 헤드리스 없음, 사이트 JS 키 사용 없음.
--   정본 = 법인 공식 홈의 회사 공통 인사제도 페이지(복지제도 절). 행이 가장 많은 단일 페이지는 건설부문 인사제도 페이지다.
--   부문 표기: 한 부문 페이지에만 있고 법인 인사제도 페이지에 없는 제도는 항목명 끝 괄호에 부문을 적었다.
--     법인 인사제도 페이지 문장은 한화그룹 주어라 그 문장에 기댄 부분은 서술에 그룹 공통 문구라고 적었다.
--     그 페이지의 워킹맘 문단은 계열사별로 상이할 수 있다고 밝혀, 부문 페이지가 확인한 제도만 실었다.
--   형제 법인(한화생명 · 한화에어로스페이스 · 한화시스템 · 한화오션 등) 문구 0.
--   원문 4쪽 → 39행. 재코딩 1(long_service_bonus → long_service_leave) · 신규 코드 0.
--   법정 제외: 육아휴직 · 배우자 출산휴가(아빠휴가) · 가족돌봄 휴가 및 휴직 · 태아검진 휴가. Refresh 휴가(최대 10일 연속 사용 장려)는 2026-10-04 기준 23 개정(이름만 있어도 연차 외 휴가)으로 refresh_leave 서술에 되살렸다.
--   금액: 원문 원 단위 금액은 유학 사전 학습 지원금 한도뿐(금액 칸 아님). 구본 추정 승계 3(welfare_point 200 · resort 50 ·
--     commute_subsidy 120 — 전부 틀 값, NOTE 끝 추정 표기). medical 100 은 원문 근거가 없어 뺐다.
-- 재수집(2026-10-02): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-02, RV-3-5): 39행 전부 원문 확인(부문 표기 · 그룹 귀속 포함) · 행 조치 없음 — 최종 39행
-- 후속 정리 2(2026-10-04, R-3): 사용자가 정한 복지 범위 규칙 개정(규칙 8 · 기준 13 · 기준 18 · 기준 20 · 기준 23)과 코퍼스 판정을 반영 — 서술 · 이름 수정 3(refresh_leave · lang · edu_support) — 최종 39행

-- 1) 회사 등록 (기존 회사 — no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hanwha', '한화',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '지주/방산', 'H', 'https://www.hanwhacorp.co.kr/hanwha/hrmanagement/hrsystem.jsp');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hanwha');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.hanwhacorp.co.kr/hanwha/hrmanagement/hrsystem.jsp'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 보상·금전 (compensation) ── 보상체계 · 보상제도 · 포상제도
  (@comp_id, 'incentive', '성과급', NULL, 'compensation',
   'est', NULL, TRUE, '회사의 경영성과와 조직·개인 성과에 따라 지급하는 성과급 — 글로벌부문(회사의 경영성과, 조직, 개인 성과를 고려하여 지급), 건설부문(매년 회사의 경영실적과 개인의 성과에 따라 차등 지급) (2개 부문 공식 회사생활 · 인사제도 페이지 보상 항목 — 지급률·지급 시기 미기재)', 10),
  (@comp_id, 'excellence_award', '준공 포상·건설부문인의 상 (건설부문)', NULL, 'compensation',
   'est', NULL, TRUE, '건설부문 준공 포상, ㈜한화 건설부문인의 상 등 임직원 동기부여를 위한 포상제도 운영 (건설부문 공식 인사제도 페이지 포상제도 항목 — 포상 내용·금액·선정 기준 미기재)', 11),
  (@comp_id, 'holiday_gift', '설날 차례비 지원 (건설부문)', NULL, 'compensation',
   'est', NULL, TRUE, '건설부문 전통 명절인 설날 차례비 지원 (건설부문 공식 인사제도 페이지 복리후생 행복한 가정 항목 — 지원 금액 미기재)', 12),

  -- ── 시간·휴가 (time_off) ── 복리후생 휴가 항목
  (@comp_id, 'refresh_leave', '정기휴가 (글로벌부문)·Refresh 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '글로벌부문 매년 4일의 정기휴가 추가 제공 (글로벌부문 공식 회사생활 페이지 복리후생 정기휴가제공 항목), Refresh 휴가 최대 영업일 기준 10일 이어 쓰도록 권장·연속 사용 장려 (㈜한화 인사제도 · 글로벌부문 회사생활 · 건설부문 인사제도 페이지 Refresh 휴가 항목) — 유급 여부·사용 시기·Refresh 휴가 별도 부여 여부 미기재', 20),
  (@comp_id, 'long_service_leave', '장기근속 포상·휴가 (휴가는 건설부문)', NULL, 'time_off',
   'est', NULL, TRUE, '10년·20년·30년 장기근속 포상 — 글로벌부문 포상 및 해외여행 상품권 지급, 건설부문 장기근속자 포상·휴가 및 여행상품권 지원 (2개 부문 공식 회사생활 · 인사제도 페이지 장기근속 항목 — 포상 금액·휴가 일수 미기재)', 21),
  (@comp_id, 'leave_general', '채움휴직·승진자 안식월 (건설부문)', NULL, 'time_off',
   'est', NULL, TRUE, '건설부문 자기개발을 위한 최대 2년간의 채움휴직 제도, 과장 이상 승진자 대상 4주 안식월 제도 (건설부문 공식 인사제도 페이지 복리후생 자기개발/Refresh 항목 — 유급 여부 미기재)', 22),

  -- ── 가족·돌봄 (family) ── 복리후생 · 행복한 가정 · 여성이 다니기 좋은 회사
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '글로벌부문 경조사 관련 휴가 및 경조금 지원, 건설부문 경조사비 지급·경조휴가 부여·경조물품 지원 (2개 부문 공식 회사생활 · 인사제도 페이지 경조 항목 — 경조 유형별 금액·휴가 일수 미기재)', 30),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '글로벌부문 중학교~대학교 자녀 학비 지원, 건설부문 미취학 자녀와 초/중/고교 및 대학교 학자금 지원 (2개 부문 공식 회사생활 · 인사제도 페이지 학자금 항목 — 지원 한도·자녀 수 제한 미기재)', 31),
  (@comp_id, 'childcare', '직장 어린이집', NULL, 'family',
   'est', NULL, TRUE, '글로벌부문 사내 임직원 어린이집 운영, 건설부문 한화그룹 직장어린이집 지원 (2개 부문 공식 회사생활 · 인사제도 페이지 어린이집 항목 — 위치·정원 미기재)', 32),
  (@comp_id, 'parenting', '임신·출산 축하선물·수능 격려품', NULL, 'family',
   'est', NULL, TRUE, '글로벌부문 Mom’s Package(임신 출산 축하선물세트), 건설부문 임신축하 기념품 지원과 대학 입시 자녀를 위한 수능 격려품 제공 (2개 부문 공식 회사생활 · 인사제도 페이지 — 선물 구성·금액 미기재)', 33),
  (@comp_id, 'fertility_support', '난임 지원', NULL, 'family',
   'est', NULL, TRUE, '글로벌부문 난임 시술 지원, 건설부문 난임 지원금 제도 (2개 부문 공식 회사생활 · 인사제도 페이지 — 지원 금액·횟수 미기재)', 34),

  -- ── 경제적 부가혜택 (perks) ── 복리후생 · 즐거운 회사
  (@comp_id, 'welfare_point', '복지포인트', 200, 'perks',
   'est', '건설부문 Refresh 휴가와 함께 복지포인트 제공, ㈜한화 인사제도 페이지 복지포인트 지급(그룹 공통 문구) — 연간 금액 미기재 (추정)', FALSE, NULL, 40),
  (@comp_id, 'discount', '갤러리아 직원 할인', NULL, 'perks',
   'est', NULL, TRUE, '갤러리아몰, 갤러리아 백화점 직원 할인 — 글로벌부문 (글로벌부문 공식 회사생활 페이지 · ㈜한화 인사제도 페이지 갤러리아 온라인몰, 오프라인 매장 할인 항목 — 할인율 미기재)', 41),
  (@comp_id, 'commute_subsidy', '셔틀버스·통근버스', 120, 'perks',
   'est', '글로벌부문 그룹 본사(장교동)·여의도 셔틀버스 운영, 건설부문 서울 본사 통근버스 운행 (2개 부문 공식 페이지) — 노선 수·이용 요금 미기재 (추정)', FALSE, NULL, 42),
  (@comp_id, 'meal', '중식비 보조·사원식당 (건설부문)', NULL, 'perks',
   'est', NULL, TRUE, '건설부문 중식비 보조 및 사원식당 운영 (건설부문 공식 인사제도 페이지 복리후생 즐거운 회사 항목 — 제공 끼니·식대 단가 미기재)', 43),
  (@comp_id, 'transport', '현장 근무자 교통비 보조 (건설부문)', NULL, 'perks',
   'est', NULL, TRUE, '건설부문 현장 근무자 교통비 보조 (건설부문 공식 인사제도 페이지 복리후생 즐거운 회사 항목 — 지급액·지급 주기 미기재)', 44),
  (@comp_id, 'telecom', '현장 근무자 통신비 보조 (건설부문)', NULL, 'perks',
   'est', NULL, TRUE, '건설부문 현장 근무자 통신비 보조 (건설부문 공식 인사제도 페이지 복리후생 즐거운 회사 항목 — 지급액·지급 주기 미기재)', 45),
  (@comp_id, 'relocation', '현장 부임 이사비·부임비 (건설부문)', NULL, 'perks',
   'est', NULL, TRUE, '건설부문 국내·해외 현장 부임 시 이사비용 및 부임비 지원 (건설부문 공식 인사제도 페이지 복리후생 즐거운 회사 항목 — 지원 금액 미기재)', 46),
  (@comp_id, 'birthday_gift', '기념일 선물', NULL, 'perks',
   'est', NULL, TRUE, '글로벌부문 생일·결혼기념일·창립기념일 등 각종 기념일 선물 지급, 건설부문 창립기념일·임직원 기념일 등 기념품 증정 (2개 부문 공식 회사생활 · 인사제도 페이지 — 선물 내용·금액 미기재)', 47),

  -- ── 건강·의료 (health) ── 복리후생 · 건강한 회사
  (@comp_id, 'health_check', '본인·배우자 건강검진', NULL, 'health',
   'est', NULL, TRUE, '글로벌부문 본인 및 배우자 건강검진 실시, 건설부문 본인 및 배우자 정기 종합건강검진 (2개 부문 공식 회사생활 · 인사제도 페이지 건강검진 항목 — 검진 주기·비용 한도 미기재)', 50),
  (@comp_id, 'insurance', '단체상해보험', NULL, 'health',
   'est', NULL, TRUE, '글로벌부문 단체상해보험 가입(임직원 질병·상해 보장), 건설부문 임직원 단체상해보험 가입을 통한 의료비 지원 (2개 부문 공식 회사생활 · 인사제도 페이지 — 보장 범위·보험료 미기재)', 51),
  (@comp_id, 'fitness', '임직원 전용 피트니스클럽 (건설부문)', NULL, 'health',
   'est', NULL, TRUE, '건설부문 서울 본사 임직원 전용 피트니스클럽 이용 지원 (건설부문 공식 인사제도 페이지 복리후생 건강한 회사 항목 — 지원 금액·이용 조건 미기재)', 52),
  (@comp_id, 'clinic', '건설현장 의무실 (건설부문)', NULL, 'health',
   'est', NULL, TRUE, '건설부문 건설현장 의무실 운영 (건설부문 공식 인사제도 페이지 복리후생 건강한 회사 항목 — 운영 현장·의료 인력 미기재)', 53),

  -- ── 근무유연성 (flexibility) ── 조직문화 유연한 근무 환경 · 복리후생
  (@comp_id, 'flex_work', '유연근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '글로벌부문 탄력근무제·시차출퇴근제 운영, 건설부문 출근시간을 선택하는 유연근무제도와 육아기 탄력적 근로시간 제도 (2개 부문 공식 회사생활 · 인사제도 페이지 — 코어타임·적용 대상 미기재)', 60),
  (@comp_id, 'remote_work', '재택근무 (글로벌부문)', NULL, 'flexibility',
   'est', NULL, TRUE, '글로벌부문 언제 어디서나 효율적으로 일하기 위한 재택근무 운영 (글로벌부문 공식 회사생활 페이지 조직문화 유연한 근무 환경 항목 — 횟수·대상 미기재)', 61),
  (@comp_id, 'pc_off', 'PC-OFF 제도 (건설부문)', NULL, 'flexibility',
   'est', NULL, TRUE, '건설부문 저녁이 있는 삶을 위한 PC-OFF 제도 (건설부문 공식 인사제도 페이지 복리후생 행복한 가정 항목 — 적용 시각 미기재)', 62),

  -- ── 근무환경 (work_env) ── 조직문화 · 즐거운 회사 · 여성이 다니기 좋은 회사
  (@comp_id, 'free_seating', '자율좌석제 (글로벌부문)', NULL, 'work_env',
   'est', NULL, TRUE, '글로벌부문 자율좌석제 운영 (글로벌부문 공식 회사생활 페이지 조직문화 유연한 근무 환경 항목 — 적용 사업장 미기재)', 70),
  (@comp_id, 'dormitory', '현장 근무자 공동 숙소 (건설부문)', NULL, 'work_env',
   'est', NULL, TRUE, '건설부문 현장 근무자 공동 숙소 지원 (건설부문 공식 인사제도 페이지 복리후생 즐거운 회사 항목 — 입주 조건·본인 부담 미기재)', 71),
  (@comp_id, 'uniform', '현장 근무복 (건설부문)', NULL, 'work_env',
   'est', NULL, TRUE, '건설부문 현장 근무자 하계·동계 근무복 지급 (건설부문 공식 인사제도 페이지 복리후생 즐거운 회사 항목 — 지급 수량 미기재)', 72),
  (@comp_id, 'nap_room', '맘스룸 (건설부문)', NULL, 'work_env',
   'est', NULL, TRUE, '건설부문 맘스룸(모유수유공간) 운영 (건설부문 공식 인사제도 페이지 복리후생 여성이 다니기 좋은 회사 항목 — 설치 사업장 미기재)', 73),

  -- ── 성장·커리어 (growth) ── 교육제도 · 인재양성 · 회사생활
  (@comp_id, 'lang', '어학 교육·시험 비용 지원', NULL, 'growth',
   'est', NULL, TRUE, '글로벌부문 글로벌 역량 향상을 위한 어학 교육과 시험응시 비용 지원, 건설부문 외국어학습 지원·어학 교육비 지원·어학시험비 지원(OPIC), 글로벌부문 다양한 사내/외 어학 과정 지원 (2개 부문 공식 회사생활 · 인사제도 · 인재양성 페이지, 글로벌부문 인재육성 페이지 Global 항목 — 지원 한도 미기재)', 80),
  (@comp_id, 'self_development', '자격증 취득 지원 (글로벌부문)', NULL, 'growth',
   'est', NULL, TRUE, '글로벌부문 회사와 개인의 동반 성장을 위한 자격증 취득 지원 (글로벌부문 공식 회사생활 페이지 자기개발 지원 항목 — 지원 금액·대상 자격 미기재)', 81),
  (@comp_id, 'edu_support', '학습모임·온라인 학습 채널·인문 교육 (건설부문)', NULL, 'growth',
   'est', NULL, TRUE, '27~29 를 합친 전문: 「건설부문 직원들의 자발적 학습모임에 장소 제공 및 교육비용 지원, 국내외 연수·사내 스터디 등 각종 교육 지원, 어학·기술·경영지식·리더십·인문&교양 강의 등 온라인 학습 채널(채널H), 인문학·경영특강·건강 관리 등 인문 교육, 학회/자격증반 운영 (건설부문 공식 인사제도 · 인재양성 페이지 — 지원 한도 미기재)」', 82),
  (@comp_id, 'conference', '외부 교육·세미나 참석 지원 (건설부문)', NULL, 'growth',
   'est', NULL, TRUE, '건설부문 직무 관련 외부 교육비 지원과 세미나·학회·포럼 참석 지원 (건설부문 공식 인재양성 페이지 외부교육 지원 항목 — 지원 한도 미기재)', 83),
  (@comp_id, 'career', 'Global Talent Program·지역 전문가', NULL, 'growth',
   'est', NULL, TRUE, 'Global Talent Program — 우수 직원을 해외 법인 및 지사에 파견해 1~2년 해외 주재 근무(건설부문 인재양성 페이지는 2년), 대리급 중심으로 해외에 파견해 현지 문화와 비즈니스 환경을 파악하는 지역 전문가 제도 (건설부문 공식 인재양성 페이지 · ㈜한화 인사제도 페이지 교육제도 항목, 그룹 공통 문구 — 선발 기준·인원 미기재)', 84),
  (@comp_id, 'mba', '해외 유학 연수(MBA·석박사)·EMBA', NULL, 'growth',
   'est', NULL, TRUE, '대리~팀장 직급 대상 Global Top 대학 석/박사 유학 프로그램(MBA, Sloan 등) — 최대 3개월 Job Off, 교육비·시험 응시료·원서비 등 사전 학습 지원금 최대 2천만 원, 유학기간 중 급여와 생활 지원금·학비 등 비용 일체 지원, 팀장급 EMBA (㈜한화 인사제도 페이지 교육제도 항목, 그룹 공통 문구 — 선발 기준·인원 미기재). 건설부문 차세대 리더 국내·외 학위 과정 (건설부문 공식 인재양성 페이지)', 85),

  -- ── 여가·라이프 (leisure) ── 복리후생 · 자기개발/Refresh
  (@comp_id, 'resort', '한화리조트 회원가 이용', 50, 'leisure',
   'est', '건설부문 전국 한화리조트 회원가 이용, ㈜한화 인사제도 페이지 한화리조트 등 그룹 내 서비스/레저 시설 임직원가 제공(그룹 공통 문구) — 이용 횟수·비용 부담 미기재 (추정)', FALSE, NULL, 90),
  (@comp_id, 'club', '동호회 활동 지원', NULL, 'leisure',
   'est', NULL, TRUE, '건설부문 각종 사내 동호회 활동 지원, ㈜한화 인사제도 페이지 계열사별 임직원 동호회 활동 비용 지원(그룹 공통 문구) (지원 금액·동호회 수 미기재)', 91),
  (@comp_id, 'library', '사내도서관·전자책 도서관 (건설부문)', NULL, 'leisure',
   'est', NULL, TRUE, '건설부문 사내도서관 및 FORENA 전자책 도서관 운영 (건설부문 공식 인사제도 페이지 복리후생 자기개발/Refresh 항목 — 대여 한도 미기재)', 92)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
