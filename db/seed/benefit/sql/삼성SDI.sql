-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 삼성SDI 복리후생 데이터
-- 출처: AI 파싱 (2026-10-02)
-- URL: https://www.samsungcareers.com/subsid/detail/C31
-- badge: est
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 참고:
--   정본 = 삼성 공식 채용사이트의 삼성SDI 법인 전용 페이지(/subsid/detail/C31). 귀속 경로 둘: samsungcareers.com
--     관계사 소개(/subsid/) 전자 묶음의 삼성SDI 링크 → C31, 그리고 법인 자기 도메인 www.samsungsdi.co.kr 헤더 메뉴의
--     CAREER 채용공고 · 지원하기 링크가 C31 을 가리킨다. C31 상세정보가 법인을 밝힌다(주소 경기도 용인시 기흥구 공세로
--     150-20 · 주요 업무 자동차배터리, 소형배터리, ESS 및 전자재료 · 홈페이지 www.samsungsdi.co.kr · 채용 문의
--     sdi.recruit@samsung.com). 복지 절 section id=a6 「삼성SDI의 근무 환경과 복지 제도」 3묶음 27항목(data-tip). 서버 렌더.
--     robots.txt 없음(302 → /sub/etc/error.html — 규칙 없음 = 허용).
--   법인 자기 도메인 헤더 메뉴의 CAREER 복리후생(/career/benefit.html)은 302 로 홈에 튕긴다(쿠키 · 리퍼러 재시도도 같음).
--     영문 사이트 CAREER 메뉴에는 복리후생이 없다. 그래서 정본은 C31 이다. 법인 전용 페이지라 그룹 통합 채용 기준 각주는 없다.
--   보조 출처 = 법인 자기 도메인의 지속가능경영보고서 2026(국문 PDF) 50쪽 출산 및 육아 지원 제도 · 52쪽 일과 삶의 균형과
--     사내 복리후생 제도 표. 같은 제도의 세부(대상 · 기간 · 월 최대 금액)와 시간 단위 휴가 · Family Day 2행이 여기서 왔다.
--   원문 27항목 → 27행: 회사 주도 교육 4항목 제외(외국어 생활관 · 사내어학교육 · SDI Edu park · 팀특화교육) · 자유로운
--     드레스 코드 제외(대응 코드 없음 — 자율복장 반증 유형) · 복합 라벨 분해(건강검진/의료비 · 어린이집/자녀학자금 ·
--     모성보호 · 장기근속휴가/포상 · 사내 인프라 3행) · 주재원 · 지역전문가는 사내 공모와 career 1행, MBA · 학술연수는 mba 1행.
--   법정 제외: 3회 분할 · 배우자 출산 휴가 20일 · 휴가 촉진 제도 · 전직지원 서비스(보고서가 고령자고용법에 따른다고 밝힘,
--     직원 12,826명 의무 대상) 문구는 행에도 서술에도 넣지 않았다.
--   금액: 원문 금액은 개인연금 월 최대 35만원 · 난임 의료비 연 100만원 둘뿐이고 둘 다 상한 · 실비 성격이라 AMT NULL.
--     구본 추정 승계 5(health_check 100 · medical 100 · child_edu 200 · welfare_point 200 · resort 100). event 50 미승계.
--   재코딩 0 · 신규 코드 0 · 구본에서 뺀 행 2(lang · edu_support — 회사 주도 교육 과정).
-- 재수집(2026-10-02): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-02, RV-3-4): Family Day(월 의무근무시간 충족 시 금요일 휴무)를 family_day 행에서 flex_work 서술로 옮김 · 모성보호실을 parenting 서술에서 nap_room 행으로 · 보고서의 가족초청행사(company_event)와 임직원 인센티브(incentive) 2행 추가 · 머리말 원문 항목 수 31 → 27 정정 — 최종 29행

-- 1) 회사 등록 (기존 회사 — no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('samsung_sdi', '삼성SDI',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '배터리/전자', 'S', 'https://www.samsungcareers.com/subsid/detail/C31');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'samsung_sdi');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.samsungcareers.com/subsid/detail/C31'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강·의료 (health) ── 가족, 의료 및 소득 지원 · 사내 문화 및 편의
  (@comp_id, 'health_check', '건강검진', 100, 'health',
   'est', '전 임직원 대상 정기 건강검진 지원 (공식 채용 페이지 건강검진/의료비 지원 항목 · 지속가능경영보고서 2026 — 검진 비용·가족 범위 미기재) (추정)', FALSE, NULL, 10),
  (@comp_id, 'medical', '의료비 지원', 100, 'health',
   'est', '질병, 부상, 출산 등의 경우 본인 및 배우자 의료비 지원 (공식 채용 페이지 건강검진/의료비 지원 항목 · 지속가능경영보고서 2026 — 지원 한도 미기재) (추정)', FALSE, NULL, 11),
  (@comp_id, 'mental', '마음건강 관리', NULL, 'health',
   'est', NULL, TRUE, '사내 열린 상담센터의 전문 심리 상담과 전문의 마음 건강 클리닉 운영 (공식 채용 페이지 마음건강 관리 항목), 연 1회 마음건강 정기진단(HCI)과 필요 시 전문상담사 1:1 Mind Care Service (지속가능경영보고서 2026 임직원 스트레스 관리 — 상담 횟수·가족 이용 여부 미기재)', 12),
  (@comp_id, 'clinic', '부속의원·물리치료실·근골격계센터', NULL, 'health',
   'est', NULL, TRUE, '임직원 건강을 위한 부속의원, 물리치료실, 약국, 근골격계센터 운영 (공식 채용 페이지 다양한 사내 인프라 항목 — 진료 과목·사업장 범위 미기재)', 13),
  (@comp_id, 'fitness', '피트니스 센터', NULL, 'health',
   'est', NULL, TRUE, '임직원 건강을 위한 피트니스 운영 (공식 채용 페이지 다양한 사내 인프라 항목 — 이용 조건·사업장 범위 미기재)', 14),

  -- ── 가족·돌봄 (family) ── 가족, 의료 및 소득 지원
  (@comp_id, 'childcare', '사내 어린이집', NULL, 'family',
   'est', NULL, TRUE, '업무와 육아를 병행할 수 있도록 각 사업장 사내 어린이집 운영 (공식 채용 페이지 사내 어린이집/자녀학자금 항목 · 지속가능경영보고서 2026 — 정원·이용 조건 미기재)', 20),
  (@comp_id, 'child_edu', '자녀학자금', 200, 'family',
   'est', '기준에 따라 유치원 및 중, 고등학교, 대학교 재학 중 자녀 학비 지원 (공식 채용 페이지 사내 어린이집/자녀학자금 항목 — 지원 한도·자녀 수 미기재) (추정)', FALSE, NULL, 21),
  (@comp_id, 'parenting', '추가 육아휴직 1년·임부휴직', NULL, 'family',
   'est', NULL, TRUE, '기본 기간 외 추가 1년 육아휴직, 대상 자녀 연령 12세까지 확대, 임부휴직 (공식 채용 페이지 가족, 의료 및 소득 지원 항목 · 지속가능경영보고서 2026 출산 및 육아 지원 제도 — 임부휴직 기간 미기재)', 22),
  (@comp_id, 'fertility_support', '난임휴직·난임 의료비 지원', NULL, 'family',
   'est', NULL, TRUE, '신청 직원에게 난임휴직 1년(3회 나눠 사용 가능), 난임 치료 휴가 유급 5일(법정 유급 2일에 3일 추가), 난임 의료비 연 100만원 지원 (공식 채용 페이지 가족, 의료 및 소득 지원 항목 · 지속가능경영보고서 2026 출산 및 육아 지원 제도)', 23),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '결혼, 조의, 출산 등 경조사 발생 시 경조 휴가, 경조금, 조사용품, 버스배차 등 지원 (공식 채용 페이지 경조사 지원 항목 — 경조 유형별 금액·휴가 일수 미기재)', 24),

  -- ── 경제적 부가혜택 (perks) ── 가족, 의료 및 소득 지원 · 사내 문화 및 편의
  (@comp_id, 'housing_loan', '주거안정지원', NULL, 'perks',
   'est', NULL, TRUE, '주택 구입 및 전세 자금 대출 시 일정 기간 이자 지원 (공식 채용 페이지 주거안정지원 항목), 무주택 사원 주택 구입 지원 대부 제도 (지속가능경영보고서 2026 — 지원 기간·한도·금리 미기재)', 30),
  (@comp_id, 'pension_support', '개인연금 지원', NULL, 'perks',
   'est', NULL, TRUE, '노후 복지생활 마련과 안정적인 소득 보장을 위해 매월 개인연금 지원, 월 최대 35만원 (공식 채용 페이지 개인연금 항목 · 지속가능경영보고서 2026 사내 복리후생 제도)', 31),
  (@comp_id, 'birthday_gift', '기념일 선물 지원', NULL, 'perks',
   'est', NULL, TRUE, '생일, 결혼기념일, 출산, 입학 등 기념일에 원하는 선물을 구매할 수 있는 기념일 포인트 지급 (공식 채용 페이지 기념일 선물 지원 항목 — 포인트 금액 미기재)', 32),
  (@comp_id, 'welfare_point', '선택적 복리후생', 200, 'perks',
   'est', '매년 복지 포인트를 제공해 건강, 여행, 공연, 도서 등 서비스를 스스로 선택해 사용 (공식 채용 페이지 선택적 복리후생 항목 — 연간 포인트 금액 미기재) (추정)', FALSE, NULL, 33),
  (@comp_id, 'meal', '사내 식사 제공', NULL, 'perks',
   'est', NULL, TRUE, '매 끼니 건강하고 맛있는 식사 제공 (공식 채용 페이지 다양한 사내 인프라 항목 — 제공 끼니 수·식대 부담 미기재)', 34),
  (@comp_id, 'commute_subsidy', '통근버스', NULL, 'perks',
   'est', NULL, TRUE, '각 사업장의 근거리부터 장거리까지 통근버스 운영 (공식 채용 페이지 통근버스 항목 — 노선 수·이용 요금 미기재)', 35),

  -- ── 시간·휴가 (time_off) ── 가족, 의료 및 소득 지원 · 지속가능경영보고서
  (@comp_id, 'long_service_leave', '장기근속휴가', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속한 임직원에게 재충전을 위한 장기근속휴가 지원 (공식 채용 페이지 장기근속휴가/장기근속포상 항목 — 근속 기준·휴가 일수 미기재)', 40),
  (@comp_id, 'leave_general', '시간 단위 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '휴가를 시간 단위로 나눠 쓰는 유연한 근무제도 운영 (지속가능경영보고서 2026 유연한 근무환경 조성 — 최소 사용 단위 미기재)', 41),

  -- ── 보상·금전 (compensation) ── 가족, 의료 및 소득 지원
  (@comp_id, 'long_service_bonus', '장기근속포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속한 임직원에게 감사를 표하는 시상금 지원 (공식 채용 페이지 장기근속휴가/장기근속포상 항목 — 근속 기준·시상금 금액 미기재)', 50),
  (@comp_id, 'incentive', '인센티브', NULL, 'compensation',
   'est', NULL, TRUE, '사업부 조직평가와 연계된 임직원 인센티브 (지속가능경영보고서 2026 윤리·준법경영 평가 및 포상 제도 — 지급 기준·지급률 미기재)', 51),

  -- ── 성장·커리어 (growth) ── 자기 개발 지원
  (@comp_id, 'career', '사내 공모·주재원·지역전문가', NULL, 'growth',
   'est', NULL, TRUE, '사내 공모 제도로 신설 조직이나 전략적 재배치가 필요한 부서로 직무 순환 기회 제공, 해외 현지 법인에 파견되는 주재원, 전략 국가 및 법인에 우수 인력을 파견하는 지역전문가/현장전문가 (공식 채용 페이지 자기 개발 지원 항목 — 선발 기준·인원 미기재)', 60),
  (@comp_id, 'mba', '삼성MBA/EMBA·학술연수', NULL, 'growth',
   'est', NULL, TRUE, '국내외 최우수 대학 MBA/EMBA 과정 경영학 석사 학위 취득 지원, 개발/기술 분야 우수 인력을 국내외 최우수 대학에 파견하는 이공계 석/박사 학술연수 (공식 채용 페이지 자기 개발 지원 항목 — 선발 기준·인원 미기재)', 61),

  -- ── 여가·라이프 (leisure) ── 자기 개발 지원 · 사내 문화 및 편의
  (@comp_id, 'library', '전자도서관', NULL, 'leisure',
   'est', NULL, TRUE, '교보문고와 제휴한 전자도서관에서 원하는 E-book과 오디오북을 언제 어디서든 이용 (공식 채용 페이지 전자도서관 항목 — 이용 권수 미기재)', 70),
  (@comp_id, 'leisure_ticket', '테마파크 지원', NULL, 'leisure',
   'est', NULL, TRUE, '에버랜드, 롯데월드, 캐리비안베이 등 테마파크 입장권을 임직원에게 저렴한 가격으로 제공 (공식 채용 페이지 테마파크 지원 항목 — 할인율·연간 매수 미기재)', 71),
  (@comp_id, 'resort', '리조트 지원', 100, 'leisure',
   'est', '전국 주요 리조트 제휴 임직원 할인 프로모션, 전국 콘도 및 리조트 회원권 지원 (공식 채용 페이지 리조트 지원 항목 · 지속가능경영보고서 2026 — 이용 횟수·할인율 미기재) (추정)', FALSE, NULL, 72),
  (@comp_id, 'company_event', '가족초청행사', NULL, 'leisure',
   'est', NULL, TRUE, '임직원과 가족이 함께 즐기는 테마파크 컨셉의 가족초청행사 매년 운영, 체험 프로그램과 나눔 플리마켓 등 (지속가능경영보고서 2026 임직원 긍정경험 제고 — 참가 선정 방식·비용 부담 미기재)', 73),

  -- ── 근무환경 (work_env) ── 사내 문화 및 편의
  (@comp_id, 'dormitory', '기숙사', NULL, 'work_env',
   'est', NULL, TRUE, '일부 사업장에서 출퇴근이 어려운 임직원을 위해 생활 시설을 갖춘 기숙사 운영 (공식 채용 페이지 기숙사 항목 — 입주 자격·비용 부담 미기재)', 80),
  (@comp_id, 'nap_room', '모성보호실', NULL, 'work_env',
   'est', NULL, TRUE, '전 사업장에 임신·수유기에 이용할 수 있는 모성보호실 운영 (공식 채용 페이지 모성보호 항목 · 지속가능경영보고서 2026 출산 및 육아 지원 제도 — 시설 구성 미기재)', 81),

  -- ── 근무유연성 (flexibility) ── 사내 문화 및 편의 · 지속가능경영보고서
  (@comp_id, 'flex_work', '유연근무제·Family Day', NULL, 'flexibility',
   'est', NULL, TRUE, '자율적으로 근무 시간을 조정해 업무를 수행하는 유연근무제 (공식 채용 페이지 유연근무제 항목), 선택적 근로시간제 운영과 월 의무근무시간을 채우면 매월 급여일이 속한 주 금요일에 휴무하는 Family Day (지속가능경영보고서 2026 일과 삶의 균형 항목 — 의무 근무 시간대 미기재)', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
