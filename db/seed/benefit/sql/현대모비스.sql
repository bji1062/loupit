-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 현대모비스 복리후생 데이터
-- 출처: AI 파싱 (2026-09-27)
-- URL: https://careers.mobis.com/life
-- badge: est
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 참고:
--   정본 = 현대모비스 채용 사이트 LIFE 페이지 (careers.mobis.com/life). 공식 홈 www.mobis.com/kr/index.do 의
--     인재채용 링크가 가리키는 법인 자기 채용 사이트다(옛 careers.mobis.co.kr 는 NXDOMAIN, www.mobis.co.kr 는
--     www.mobis.com 으로 301 — 회사가 도메인을 mobis.com 으로 옮겼다). 서버 렌더 HTML 본문에 WORK 7카드 ·
--     WELLBEING 14카드 · CAREER 10항목이 들어 있다(헤드리스 불필요). WELLBEING 머리의 주석 속 빈 템플릿은 쓰지 않았다.
--     robots.txt = User-agent: * / Allow: / (Disallow 는 /jobs_private 두 경로뿐, 2026-09-27 확인). 본문 sha256 5b74b7b0…e35b88d.
--   보조 = 현대모비스 지속가능성보고서 2026(PDF 194쪽, 2026-08-11 작성) p.49·50·79·80·81·85·86
--     www.mobis.com/upload/202608210422145310.pdf sha256 e6715206…f6d5559. p.80 복리후생 표가 채용 페이지보다 자세하다.
--   계열사(현대자동차·기아 등) 복지는 섞지 않았다. 그룹 통합 채용 페이지가 아니라 법인 자기 채용 사이트라 각주 없음.
--   법정 제도 제외: 임신기·육아기 근로시간 단축 · 출산전후휴가 · 배우자 출산휴가 · 태아검진 · 가족돌봄휴직 ·
--     퇴직연금 · 법정 일반검진 · 퇴직 예정자 진로설계·생애설계 교육(재취업지원서비스)은 행이 아니다.
--   금액: 원문 연액 1(welfare_point 연간 100만 포인트, 1포인트 1원 환산) · 월액 환산 1(pension_support 월 2만 원) ·
--     구본 추정 승계 4 · 미승계 4(event 경조금 · discount 비율 · club 값의 전제 없음 · welfare_point 200 은 원문값으로 교체).
--   구본 18개 코드 전부 유지(재코딩 0) · 기존 어휘 코드 15개 추가 · 신규 코드 0.
-- 재수집(2026-09-27): 구본(2026-03-31 AI 파싱)의 근거 URL 이 끊겨(404 / NXDOMAIN — 2026-09-27 출처 주간 점검) 공식 출처로 다시 세웠다
-- 검증(2026-09-28, RV-2): profit_sharing 행 추가 — OpenDART 자기주식처분결정 2건(2025-10-31·12-12) 처분 목적 2025년 단체교섭에 따른 회사주식 지급 · medical 행에 상병휴직 흡수(포스코퓨처엠 선례) — 최종 34행
-- 후속 정리 2(2026-10-04, R-3): 사용자가 정한 복지 범위 규칙 개정(규칙 8 · 기준 13 · 기준 18 · 기준 20 · 기준 23)과 코퍼스 판정을 반영 — 새 행 1(lang) · 서술 · 이름 수정 1(edu_support) — 최종 35행

-- 1) 회사 등록 (기존 회사 — no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('hyundai_mobis', '현대모비스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '자동차부품', 'H', 'https://careers.mobis.com/life');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_mobis');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://careers.mobis.com/life'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무유연성 (flexibility) ── 채용 페이지 WORK 카드 1·2·5·6 · 보고서 p.79
  (@comp_id, 'flex_work', '선택적 근로시간제', NULL, 'flexibility',
   'est', NULL, TRUE, '월 단위 최대 근무 가능 시간 안에서 정해진 근로시간을 각자의 일정과 상황에 맞춰 스스로 계획하고 유동적으로 조정하는 선택적 근로시간제 운영', 10),
  (@comp_id, 'remote_work', '재택근무', NULL, 'flexibility',
   'est', NULL, TRUE, '재택근무를 공식 제도로 두고 출퇴근 부담 없이 업무에 집중하도록 지원', 11),
  (@comp_id, 'pc_off', 'PC-OFF', NULL, 'flexibility',
   'est', NULL, TRUE, '계획된 근무시간을 넘기면 PC가 자동으로 종료되는 PC-OFF 프로그램 운영', 12),
  (@comp_id, 'satellite_office', '거점오피스', NULL, 'flexibility',
   'est', NULL, TRUE, '집과 가까운 곳에서 근무할 수 있도록 수도권 5곳에 거점 오피스 운영', 13),

  -- ── 경제적 부가혜택 (perks) ── WORK 카드 3 · WELLBEING 카드 2·9·11·13 · 보고서 p.79·80
  (@comp_id, 'commute_subsidy', '셔틀버스', 120, 'perks',
   'est', '서울·경기 각 지역에서 약 81개 노선의 출근 셔틀버스 운영(마북연구소 기준) (추정)', FALSE, NULL, 20),
  (@comp_id, 'relocation', '부임이사 지원', NULL, 'perks',
   'est', NULL, TRUE, '장거리 부임 등 근무지를 옮기는 직원에게 부임비·이사비와 휴가 지원', 21),
  (@comp_id, 'discount', '차량 구입 지원·제휴 할인', NULL, 'perks',
   'est', NULL, TRUE, '현대·기아차 구매 시 차량 할인과 구입비 최대 30% 지원, 신입사원 첫 차 구매 20% 할인, 공임비·부품비 30% 할인과 타이어·수리비 할인, 파워스폰서 제휴로 호텔·금융·웨딩·상조·테마파크·피트니스 등 프로모션 제공', 22),
  (@comp_id, 'welfare_point', '종합포인트', 100, 'perks',
   'est', '임직원 전용몰과 오프라인 가맹점에서 쓰는 여가생활·일상복지용 종합포인트 연간 100만 포인트 상당 지급 (1포인트 1원 기준 환산)', FALSE, NULL, 23),
  (@comp_id, 'housing_support', '새내기 정착·주거지원금', NULL, 'perks',
   'est', NULL, TRUE, '재직 기간 중 1회, 주택 구입·임차에 관계없이 새내기 정착지원금·주거지원금 지원', 24),
  (@comp_id, 'meal', '건강 식사 제공', NULL, 'perks',
   'est', NULL, TRUE, '건강 식사 제공 (2026 지속가능성보고서 복리후생 건강 케어의 건강 먹거리 제공 항목 — 끼니·단가 미기재)', 25),
  (@comp_id, 'pension_support', '개인연금 지원', 24, 'perks',
   'est', '재직 중 월 2만 원 개인연금 지원 (연 24만 원 환산)', FALSE, NULL, 26),

  -- ── 가족·돌봄 (family) ── WELLBEING 카드 1·6·8·12 · 보고서 p.80
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '임직원과 가족의 경조사 시 경조휴가와 경조금 지원', 30),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '임직원 자녀의 유아교육비와 고등학교·대학교 학자금 지원', 31),
  (@comp_id, 'parenting', '임신·출산·육아 지원', NULL, 'family',
   'est', NULL, TRUE, '한 자녀당 육아휴직 최대 2년, 임신·출산 임직원 특급 호텔 이용 지원(우리아이 행복여행), 본사·마북 연구소·의왕 연구소·진천 공장 수유실과 임산부 휴게실(유축기·리클라이너·냉장고), 임산부 주차 지원, 축하 꽃다발과 포인트, 출산과 자녀 초등학교 입학 때 아이사랑 바우처(첫만남·첫등교), 경남 창원 사업장 대상자에게 만 0~5세 위탁보육료 지원', 32),
  (@comp_id, 'childcare', '직장어린이집', NULL, 'family',
   'est', NULL, TRUE, '서울 역삼·경기 용인·경기 의왕·충북 진천 사업장에서 직장어린이집 운영', 33),

  -- ── 여가·라이프 (leisure) ── WELLBEING 카드 3·5 · 보고서 p.80
  (@comp_id, 'club', '동호회', NULL, 'leisure',
   'est', NULL, TRUE, '임직원 동호회에 매월 활동비 지원', 40),
  (@comp_id, 'resort', '휴양시설', 100, 'leisure',
   'est', '전국 각지 사계절 휴양소(콘도) 회원가 숙박과 하계 휴양소 운영 (추정)', FALSE, NULL, 41),
  (@comp_id, 'summer_vacation_subsidy', '롱스테이 휴가 포인트', NULL, 'leisure',
   'est', NULL, TRUE, '휴가를 연속 5일 쓰면 30만 포인트, 연속 10일 쓰면 60만 포인트 지급 — 연간 지급 횟수 미기재', 42),

  -- ── 시간·휴가 (time_off) ── WELLBEING 카드 4·10 · 보고서 p.80
  (@comp_id, 'long_service_leave', '장기근속자 포상', NULL, 'time_off',
   'est', NULL, TRUE, '근속연수에 따른 해외여행 등 포상, 근속 10년부터 35년까지 5년 단위로 휴가·휴가비·기념품 지원', 50),
  (@comp_id, 'leave_general', '월차·Step-Up 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '월차 휴가(부여 방식·일수 미기재), 당해 승진한 책임급에게 근무일 기준 15일의 리프레시 휴가인 Step-Up 휴가 지원', 51),
  (@comp_id, 'summer_leave', '하기휴가', NULL, 'time_off',
   'est', NULL, TRUE, '5일의 하기휴가를 연중 원하는 일정에 맞춰 탄력적으로 사용 (일부 사업장 예외)', 52),

  -- ── 건강·의료 (health) ── WELLBEING 카드 7·14 · 보고서 p.49·50·80
  (@comp_id, 'health_check', '건강검진', 100, 'health',
   'est', '임직원과 가족 1인(배우자·부모·배우자 부모 중) 연 1회 종합검진(임직원 비용 50%, 만 32세 이상 임직원은 3년마다 전액), 전 직원 추가 검진(복부초음파·이상지질혈증·갑상선초음파), 40세 이상 추가 검진(종양표지자검사·갑상선초음파), 여성 임직원 자궁경부암 세포검진 매년과 여성검진 4개 항목 2년 1회, 독감 예방접종 (추정)', FALSE, NULL, 60),
  (@comp_id, 'medical', '진료비 지원·상병휴직', 100, 'health',
   'est', '임직원과 부양가족의 외래·약제·입원 진료비 중 건강보험 급여 항목 본인부담금 전액 지원, 진료비 자동 정산·지급. 질병·부상으로 15일 이상 근무하기 어려울 때 상병휴직 신청 가능(급여 여부 미기재) (추정)', FALSE, NULL, 61),
  (@comp_id, 'clinic', '건강관리실', NULL, 'health',
   'est', NULL, TRUE, '사업장별 건강관리실에 간호사가 상주해 일반 의약품 제공, 외상 처치 등 기본 의료 지원과 건강 상담 제공', 62),
  (@comp_id, 'mental', '심리상담실 힐링샘', NULL, 'health',
   'est', NULL, TRUE, '2014년부터 사내 심리상담실 힐링샘에서 대면·비대면 상담과 치료, 온라인 자가진단, 해외 주재원 화상 상담 제공', 63),

  -- ── 성장·커리어 (growth) ── WELLBEING 카드 11 · CAREER 4·5·6·7·9·10 · 보고서 p.85·86
  (@comp_id, 'retirement_support', '정년퇴직자 여행포인트', NULL, 'growth',
   'est', NULL, TRUE, '정년퇴직자에게 여행포인트 지원 (공식 채용 페이지 WELLBEING 포인트 항목 — 지급액 미기재)', 70),
  (@comp_id, 'self_development', '직무자격증 취득 지원', NULL, 'growth',
   'est', NULL, TRUE, '계약직을 포함한 모든 임직원에게 직무 연계 자격증 약 290여 종의 수강료·교재비·응시료 50% 지원', 71),
  (@comp_id, 'career', '커리어 마켓·사내 스타트업·해외 파견', NULL, 'growth',
   'est', NULL, TRUE, '사내 모집 공고에 직접 지원해 원하는 직무로 옮기는 커리어 마켓, 전사 공모로 아이디어를 제안해 사업개발 육성과 창업을 지원받는 사내 스타트업, 우수 인재 대상 미주·유럽·중국·아시아태평양 해외 법인 파견 기회 제공', 72),
  (@comp_id, 'edu_support', '교육·학습 지원', NULL, 'growth',
   'est', NULL, TRUE, '임직원 3인 이상 학습동아리의 활동비와 외부 전문가 초청 강사비·관련 도서 지원, 업무시간 중 주당 최대 2시간 학습시간 활용(러닝타임제), 본인 대학교 학자금 대출이자 지원, 직무·기술·리더십·어학·북러닝 등 다양한 교육을 수강하는 스마트러닝, 기간·차수·강의 수 제한 없이 어학·경영·인문·교양·자기계발 등 콘텐츠를 이용하는 이러닝 플랫폼 Ubob, 임직원 특강 (공식 채용 페이지 CAREER 항목 · 2026 지속가능성보고서 84·85쪽 — 특강 주제·개최 주기 미기재)', 73),
  (@comp_id, 'mba', '재직자 석사학위 지원', NULL, 'growth',
   'est', NULL, TRUE, '서울대학교 공학전문대학원·경영전문대학원(Executive MBA, 2025년 4명 선발) 전문석사과정 등록금·해외단기연수 전액과 학회 참가 비용 지원, 계약직을 포함한 모든 임직원의 사이버대학교 신·편입학 등록금·수업료 감면 혜택 제공', 74),
  (@comp_id, 'lang', '어학 교육', NULL, 'growth',
   'est', NULL, TRUE, '임직원의 글로벌 어학 역량과 글로벌 마인드셋 강화를 위한 어학 교육 확대, 2025년 2,137명 이수. 스마트러닝과 이러닝 플랫폼 Ubob에서도 어학 과정 수강 (2026 지속가능성보고서 85·86쪽 · 공식 채용 페이지 CAREER 스마트러닝 / 러닝타임제 항목 — 대상 언어·비용 부담 미기재)', 75),

  -- ── 근무환경 (work_env) ── 보고서 p.80
  (@comp_id, 'dormitory', '공동숙소', NULL, 'work_env',
   'est', NULL, TRUE, '신입사원, 미혼 경력사원, 단신부임·파견 직원에게 숙소 지원', 80),

  -- ── 보상·금전 (compensation) ── 보고서 p.81
  (@comp_id, 'stock_option', '우리사주제도', NULL, 'compensation',
   'est', NULL, TRUE, '2025년 노사합의에 따라 우리사주 132,799주를 모든 조합원에게 배정·예탁하는 등 임직원의 자사 주식 취득·보유를 돕는 우리사주조합 운영', 90),
  (@comp_id, 'excellence_award', 'M.V.P 포상', NULL, 'compensation',
   'est', NULL, TRUE, '유기적 협업·선도기술 확보·사업영역 확대에 기여한 과제를 선정해 M.V.P(Mobis Value&Vision Performer)를 수여하고 포상금과 포상휴가 지급(2025년 207명) — 포상금액 미기재', 91),
  (@comp_id, 'profit_sharing', '경영성과급 (2025년 회사주식 지급)', NULL, 'compensation',
   'est', NULL, TRUE, '2025년 단체교섭에 따른 회사주식 지급을 위해 자기주식 205,989주(2025년 10월 31일 이사회 결의)와 46,898주(2025년 12월 12일 이사회 결의)를 처분 — 이사회 안건명은 자기주식 처분 승인의 건, 경영성과급 지급 (현대모비스 주요사항보고서 자기주식처분결정 2건 · 2026 지속가능성보고서 17쪽 이사회 결의 사항 — 지급 기준·인당 지급 규모 미공개)', 92)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
