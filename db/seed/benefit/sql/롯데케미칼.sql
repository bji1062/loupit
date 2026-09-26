-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 롯데케미칼 복리후생 데이터
-- 출처: AI 파싱 (2026-09-26)
-- URL: https://www.lotte.co.kr/upload/report/chemical/lottechemical_SR_kor_2025.pdf
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
--
-- 참고:
--   재수집(2026-09-26): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다 — 대조 보고서 2026-09-25-official-compare
-- 감사(RA-1 2026-09-26) 반영: 사내 카페 케미스토리 snack_bar · 인커리어 career 추가 · 힐링휴가·하계휴가 문안의 연차 낱말 제거 · W카드는 혜택 미기재라 싣지 않음
--   정본 A = 롯데케미칼 발행 2025 ESG Report(지속가능경영보고서, 2026-06 발행, 149쪽, sha256 d8dd4f3e…5a52).
--     롯데지주 www.lotte.co.kr 그룹 보고서 목록에 LOTTE Chemical 로 게시된 파일이다. 발행처 롯데케미칼 ESG경영팀,
--     보고 범위는 별도법인 롯데케미칼 국내 사업장(p.2) — 그룹 공통이 아니라 이 법인 기준이라 그룹 각주를 달지 않았다.
--     복리후생 p.75(스마트 워크 · 가족친화경영 · LIFE CYCLE 복지제도 표 20항목) · p.76(Family Day · 심리상담실 · 개인연금)
--     · p.79(근로자 생활 안정 보장) · p.80(육아휴직) · 교육 p.70~71.
--   보조 B = 2022 ESG Report(www.lotte.co.kr/upload/report/chemical/HPC_2022_kor.pdf, 2023-07 발행, sha256 15a97668…87d0) p.68~70.
--     A 가 라벨만 둔 제도의 뜻을 정할 때만 썼다(힐링휴가·워라밸데이). A 에서 사라진 제도(안식월·Special Day·
--     스마트오피스·재택·자율복장·남성 육아휴직 첫 달 기본급)는 행으로 만들지 않았다.
--   CAREERS_BENEFIT_URL 을 정본 A 의 PDF 로 둔다. 회사 채용 복리후생 페이지 www.lottechem.com/ko/recruit/personnel/welfare.do 는
--     robots.txt 가 루트 말고 전부 막아(Allow: /$ · Disallow: /) 받지 않았고 읽지 않은 페이지를 근거 URL 로 적을 수 없다.
--     www.lotte.co.kr 은 robots 가 Yeti 그룹만 있어 허용. 원문 사본은 2026-09-25 대조 때 받은 것을 재사용(요청 0회).
--   금액: 명시값 0건. 구본 추정치 3행 승계(health_check 100 · insurance 30 · resort 50, NOTE 에 추정 표기).
--     구본 medical 50 은 근거 문안(보험과 별개 현금 지급)이 원문(단체 상해보험으로 보장)과 어긋나 승계하지 않았다.
--   재코딩 2: refresh_leave → leave_general(힐링휴가 = 연차 사용 시 휴가비, 조건 없는 추가 휴가 아님) ·
--     edu_support → self_development(남는 제도는 직무 자격증 취득 비용 지원뿐). 신규 코드 0.
--   행 18 → 25. SORT 섹션은 원문 쪽 순서(growth p.70 · leisure p.71 · flexibility·family·health·work_env·perks·compensation·time_off p.75~).
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op, 아래 UPDATE 가 URL 을 채운다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('lotte_chem', '롯데케미칼',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '화학', 'L', 'https://www.lotte.co.kr/upload/report/chemical/lottechemical_SR_kor_2025.pdf');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'lotte_chem');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.lotte.co.kr/upload/report/chemical/lottechemical_SR_kor_2025.pdf'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 성장·교육 (growth) ──
  (@comp_id, 'self_development', '직무 자격증 취득 지원', NULL, 'growth',
   'est', NULL, TRUE, '생산·기술·안전·환경·경영·DT 등 업무상 자격증 취득이 필요한 임직원을 대상으로 자격증 취득 및 유지 프로그램과 비용 제공 (공식 2025 ESG 보고서 인재육성 프로그램 자격증 취득 지원 항목 — 지원 한도·대상 자격증 목록 미기재)', 10),
  (@comp_id, 'mba', '롯데/사외 MBA·학술연수', NULL, 'growth',
   'est', NULL, TRUE, '롯데/사외 MBA 지원, 학술연수 및 전문대학원 지원. 예비 리더의 경영역량 강화를 위한 대내외 MBA 과정 지원 (공식 2025 ESG 보고서 인재육성 체계 전문 교육 지원 항목 — 선발 기준·인원·비용 부담 범위 미기재)', 11),
  (@comp_id, 'lang', '사외 어학학습비·어학 과정 지원', NULL, 'growth',
   'est', NULL, TRUE, '사외 어학학습비 지원. 사외 어학원·온라인 어학수업·마이크로러닝 콘텐츠 지원과 사내 어학 과정(영어·중국어·일본어·인도네시아어·러시아어·스페인어·프랑스어 등) 운영 (공식 2025 ESG 보고서 LIFE CYCLE 복지제도 표 자기계발/여가지원 항목·인재육성 프로그램 어학과정 항목 — 지원 한도 미기재)', 12),
  (@comp_id, 'career', '인커리어 (사내 직무 이동)', NULL, 'growth',
   'est', NULL, TRUE, '원하는 직무나 그룹사로 직접 지원해 이동하는 자기주도형 경력개발 제도 인커리어(IN Career), 그룹사 인력 소요가 생기면 수시 실시 (공식 2025 ESG 보고서 자기주도형 경력개발제도 항목 — 지원 자격·선발 방식 미기재)', 13),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'library', '전자책 구독 (밀리의서재·교보문고 E-BOOK)', NULL, 'leisure',
   'est', NULL, TRUE, '임직원의 독서 소양 함양을 위한 밀리의서재, 교보문고 E-BOOK 플랫폼 구독 서비스 제공 (공식 2025 ESG 보고서 인재육성 프로그램 항목 — 이용 대상·이용 한도 미기재)', 20),
  (@comp_id, 'company_event', '가족초청 Family Day·가족 문화 체험활동', NULL, 'leisure',
   'est', NULL, TRUE, '5월 가정의 달 임직원 가족(자녀) 대상 사업장 초청 행사와 10월 부모초청 Parents Day 개최, 임직원 가족 문화 체험활동 (공식 2025 ESG 보고서 가족친화 프로그램 항목·LIFE CYCLE 복지제도 표 육아/교육 지원 항목 — 참가 비용·체험활동 내용 미기재)', 21),
  (@comp_id, 'club', '사내동호회 활동 지원', NULL, 'leisure',
   'est', NULL, TRUE, '사내동호회 활동 지원, 취미생활을 위한 사내 동호회 지원 (공식 2025 ESG 보고서 LIFE CYCLE 복지제도 표 자기계발/여가지원 항목·근로자 생활 안정 보장 서술 — 지원 금액·동호회 종류 미기재)', 22),
  (@comp_id, 'resort', '콘도/리조트·숙박시설 이용 지원', 50, 'leisure',
   'est', '콘도/리조트 예약 지원, 워터파크 및 숙박시설 이용 지원 (공식 2025 ESG 보고서 LIFE CYCLE 복지제도 표 자기계발/여가지원 항목·근로자 생활 안정 보장 서술 — 지원 금액 미기재) (추정)', FALSE, NULL, 23),

  -- ── 근무유연성 (flexibility) ──
  (@comp_id, 'flex_work', '선택적 근로시간제', NULL, 'flexibility',
   'est', NULL, TRUE, '매월 정해진 총 근로시간 범위 안에서 업무 시작/종료 시각과 1일 근로시간을 구성원이 직접 계획해 실행하는 선택적 근로시간제 운영 (공식 2025 ESG 보고서 복리후생 스마트 워크 항목 — 정산 기간·적용 대상 미기재)', 30),
  (@comp_id, 'pc_off', 'PC OFF 제', NULL, 'flexibility',
   'est', NULL, TRUE, '개인이 설정한 근무 종료시각이 되면 알람 메시지가 게시된 뒤 PC 가 종료되는 PC OFF 제로 선택적 근로시간제와 연계한 정시 퇴근 문화 (공식 2025 ESG 보고서 복리후생 스마트 워크 항목)', 31),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'parenting', '출산·육아 지원 (여성 육아휴직 최대 2년 6개월·남성 육아휴직 의무)', NULL, 'family',
   'est', NULL, TRUE, '여성 구성원은 출산 후 별도 신청 없이 육아휴직으로 자동 전환되고 육아휴직 기간을 최대 2년 6개월로 확대 운영, 남성 육아휴직 1개월 이상 의무 사용, 임부 휴직 10개월, 자녀 초등학교 입학 시 자녀돌봄 휴직, 임신 및 출산 시 선물 지원 (공식 2025 ESG 보고서 복리후생 가족친화경영 항목 — 휴직 중 급여 보전 여부·선물 품목 미기재)', 40),
  (@comp_id, 'child_edu', '자녀 학자금 (미취학·대학생)', NULL, 'family',
   'est', NULL, TRUE, '미취학 자녀 학자금(만 3세~취학 전)과 대학생 자녀 학자금 지원 (공식 2025 ESG 보고서 복리후생 가족친화경영 항목. 공식 2022 ESG 보고서에는 미취학자녀 지원금 매월 10만 원, 2년 한도로 기재 — 대학생 자녀 학자금 지원 한도 미기재)', 41),
  (@comp_id, 'childcare', '직장 어린이집', NULL, 'family',
   'est', NULL, TRUE, '양질의 교사진과 시설을 갖춘 직장 어린이집 운영 (공식 2025 ESG 보고서 복리후생 가족친화경영 항목. 공식 2022 ESG 보고서에는 서울 본사 재직 임직원의 만 1세~만 4세 자녀 대상 사내 어린이집으로 기재 — 사업장별 설치 여부·정원 미기재)', 42),
  (@comp_id, 'fertility_support', '난임 직원 지원 (난임휴직 1년·치료비)', NULL, 'family',
   'est', NULL, TRUE, '난임 직원 지원(휴직 및 치료비), 난임휴직 1년 (공식 2025 ESG 보고서 복리후생 가족친화경영 항목·LIFE CYCLE 복지제도 표 건강관리 항목 — 치료비 지원 한도·휴직 중 급여 미기재)', 43),
  (@comp_id, 'event', '경조사 지원 (경조금·경조휴가·상조서비스)', NULL, 'family',
   'est', NULL, TRUE, '가족의 경사를 축하하는 경조금 및 경조휴가 지원, 결혼·출산·고희·사망 경조와 상조서비스 지원 (공식 2025 ESG 보고서 복리후생 가족친화경영 항목 — 경조금액·휴가 일수 미기재)', 44),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'medical', '가족 의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '단체 상해보험 가입으로 본인과 배우자, 부모, 자녀의 의료비 보장 (공식 2025 ESG 보고서 복리후생 가족 의료비 지원 항목·LIFE CYCLE 복지제도 표 건강관리 항목 — 보장 한도·본인 부담률 미기재)', 50),
  (@comp_id, 'insurance', '단체 상해보험', 30, 'health',
   'est', '단체 상해보험 가입 (공식 2025 ESG 보고서 복리후생 가족 의료비 지원 항목 — 보험료·보장 금액 미기재) (추정)', FALSE, NULL, 51),
  (@comp_id, 'health_check', '종합건강검진 (배우자·부모 포함)', 100, 'health',
   'est', '임직원 및 가족(배우자, 부모) 종합건강검진비 제공 (공식 2025 ESG 보고서 복리후생 가족 의료비 지원 항목 — 검진 금액·주기 미기재) (추정)', FALSE, NULL, 52),
  (@comp_id, 'mental', '사내 심리상담실', NULL, 'health',
   'est', NULL, TRUE, '전문 상담사가 상주하는 사내 심리상담실에서 회사·개인 생활 고민과 대인관계 갈등 상담 제공, 타 사업장 근무자·해외 주재원 화상·유선 상담, 부서단위 심리검사 워크숍과 마음챙김 명상 프로그램 운영 (공식 2025 ESG 보고서 마음건강관리 항목 — 이용 횟수 제한·가족 이용 여부 미기재)', 53),

  -- ── 근무환경 (work_env) ──
  (@comp_id, 'dormitory', '사택·독신자숙소', NULL, 'work_env',
   'est', NULL, TRUE, '사업장별 사택 지원, 사택/독신자숙소 지원 (공식 2025 ESG 보고서 복리후생 생활 지원 항목 — 입주 자격·본인 부담 비용 미기재)', 60),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'housing_loan', '주택자금 융자 (최대 1억 원·이자 지원)', NULL, 'perks',
   'est', NULL, TRUE, '주택 마련을 위한 대출 지원(최대 1억 원), 주택자금대출 및 이자 지원 (공식 2025 ESG 보고서 복리후생 생활 지원 항목·근로자 생활 안정 보장 서술 — 이자 지원 비율·상환 조건 미기재)', 70),
  (@comp_id, 'pension_support', '개인연금 1:1 매칭 지원', NULL, 'perks',
   'est', NULL, TRUE, '개인연금보험에 가입해 매월 구성원 납입분만큼 회사도 동일 금액을 1:1 매칭 그랜트 방식으로 납입 (공식 2025 ESG 보고서 개인연금제도 항목 — 월 납입 한도 미기재)', 71),
  (@comp_id, 'welfare_point', '복지포인트', NULL, 'perks',
   'est', NULL, TRUE, '복지포인트 지원 (공식 2025 ESG 보고서 LIFE CYCLE 복지제도 표 자기계발/여가지원 항목 — 연간 포인트 금액·사용처 미기재)', 72),
  (@comp_id, 'snack_bar', '사내 카페 케미스토리', NULL, 'perks',
   'est', NULL, TRUE, '서울 본사와 대전 R&D본부의 사내 카페 케미스토리 운영, 장애인 바리스타가 직접 식음료 제조 (공식 2025 ESG 보고서 장애인 바리스타 사내카페 운영 항목 — 이용 요금·다른 사업장 설치 여부 미기재)', 73),

  -- ── 보상 (compensation) ──
  (@comp_id, 'stock_option', '우리사주제도', NULL, 'compensation',
   'est', NULL, TRUE, '구성원 주식 소유 제도인 우리사주제도(ESOP) 운영 (공식 2025 ESG 보고서 복리후생 우리사주 항목 — 배정 조건·회사 지원 여부 미기재)', 80),

  -- ── 시간·휴가 (time_off) ──
  (@comp_id, 'leave_general', '힐링휴가·워라밸데이', NULL, 'time_off',
   'est', NULL, TRUE, '힐링휴가 운영 (공식 2025 ESG 보고서 LIFE CYCLE 복지제도 표 자기계발/여가지원 항목). 공식 2022 ESG 보고서에는 힐링 휴가를 5일 이상 휴가 사용 시 휴가비 지원(연 2회), 워라밸데이를 전사 의무 휴무일로 기재 — 휴가비 금액·워라밸데이 일수 미기재', 90),
  (@comp_id, 'summer_leave', '하계휴가', NULL, 'time_off',
   'est', NULL, TRUE, '하계휴가 (공식 2025 ESG 보고서 LIFE CYCLE 복지제도 표 자기계발/여가지원 항목 — 부여 일수·별도 부여 여부 미기재)', 91)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
