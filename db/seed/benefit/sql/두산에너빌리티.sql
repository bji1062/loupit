-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 두산에너빌리티 복리후생 데이터
-- 출처: AI 파싱 (2026-10-02)
-- URL: https://www.doosanenerbility.com/kr/employment/welfare
-- badge: est
--
-- 참고:
--   정본은 법인 자기 도메인 기업 사이트 헤더 메뉴 채용 아래 복리후생 페이지 /kr/employment/welfare 다.
--   서버 렌더 정적 HTML(robots.txt 없음 404), 6개 절 28개 항목. 주석 속 블록 · 숨김 블록 없음.
--   보조 출처: 같은 법인 기업 사이트 지속가능경영 성과 페이지의 2026 통합보고서 국문 PDF
--     (heavy_file/management/data/overview_result/report/2026_report_kr_v4.pdf)
--     47쪽 임직원 보건 증진 프로그램 · 54쪽 인재 육성 · 55쪽 보상체계 · 56쪽 학습 제도 · 57쪽 임직원 주요 복지 제도.
--     보고서 근거 구절은 서술 괄호에 보고서 이름과 쪽을 적어 구분했다.
--   귀속: 법인 자기 도메인 · 법인 발행 보고서라 그룹 각주 없음. 두산 · 두산밥캣 · 두산로보틱스 등 형제 법인 문장은 쓰지 않았다.
--   직군: 두 출처 모두 생산직 · 사무직으로 제도를 가르지 않는다. 원문이 밝힌 대상(계약직 · 파견직 포함 여부,
--     분당 · 동탄 근무자, 비수도권 근무 임직원 자녀)만 서술에 적었다. 단체협약 수당은 원문에 복지 문장 없음.
--   금액: 월액 환산 2(parenting 보육지원금 월 20만원 → 240 · disability_family_support 월 20만원 → 240, NOTE 에 환산) ·
--     구본 추정 승계 5(health_check 100 · medical 100 · insurance 30 · child_edu 300 · resort 50 — 전부 틀 값, NOTE 끝에 (추정)).
--     medical 은 원문 한도 2,000만원 · 500만원을 NOTE 에 적고 틀 값을 승계했다. 경조금 추정치는 승계하지 않았다.
--   제외: 하계 연차휴가 · 연말 집중휴가 권장 기간(본인 연차 사용 — 「연중 상시 리프레시 휴가」는 2026-10-04 기준 23 개정으로 refresh_leave 행으로 되살림, SORT 92) · 교육 연수 시설(회사 주도 교육) ·
--     자격수당(급여성 수당) · 해외 파견 예정자 어학 지원(특정 대상 교육) · 재취업 교육 · 알선(1,000인 이상 법정) ·
--     법정 모성보호 · 가족돌봄 · 난임치료휴가.
--   구본에서 뺀 행: refresh_leave(2026-10-04 연중 상시 리프레시 휴가로 되살림 — 하계 휴가비 · 문화체험은 새 행으로) · edu_support(연수원 · 교육 시설).
--   재코딩: 없음. 구본 한 행에 묶였던 제도는 어휘표 뜻대로 새 행으로 나눴다(company_event · travel_support · library ·
--     dormitory · relocation · retirement_support · fertility_support).
--   SORT 섹션 순서 = 복리후생 페이지에서 카테고리가 처음 나온 순서, 보고서 근거 행은 해당 섹션 끝
--     (leisure 10 · compensation 20 · family 30 · flexibility 40 · work_env 50 · health 60 · perks 70 · growth 80 · time_off 90).
-- 재수집(2026-10-02): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-02, RV-3-5): 34행 전부 원문 확인 · 시드 조치 없음 · 리프레시 휴가 권장 문장 제외 유지 · 장기근속 표는 칸 배치 그대로 · 월 20만원 2행 연 240 환산 유지 · 구본 refresh_leave · edu_support 표적 삭제 — 최종 34행
-- 후속 정리 2(2026-10-04, R-3): 사용자가 정한 복지 범위 규칙 개정(규칙 8 · 기준 13 · 기준 18 · 기준 20 · 기준 23)과 코퍼스 판정을 반영 — 새 행 2(edu_support · refresh_leave) — 최종 36행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('doosan_enerbility', '두산에너빌리티',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '에너지/발전', 'D', 'https://www.doosanenerbility.com/kr/employment/welfare');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'doosan_enerbility');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.doosanenerbility.com/kr/employment/welfare'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 여가·라이프 (leisure) — 복리후생 휴가 및 여가 지원 · 자기계발 지원 ──
  (@comp_id, 'summer_vacation_subsidy', '하계 휴가비', NULL, 'leisure',
   'est', NULL, TRUE, '임직원의 리프레시를 위하여 하계 휴가 시작 시 별도의 휴가비 지원 (공식 홈페이지 채용 복리후생 하계 휴가비 항목) — 지급액 미기재', 10),
  (@comp_id, 'resort', '콘도', 50, 'leisure',
   'est', '회사가 보유한 콘도 객실을 임직원이 신청하여 사용할 수 있도록 지원 (공식 홈페이지 채용 복리후생 콘도 신청 항목) — 이용 횟수·본인 부담 미기재 (추정)', FALSE, NULL, 11),
  (@comp_id, 'company_event', '어린이날 행사·체육대회', NULL, 'leisure',
   'est', NULL, TRUE, '직장 동료는 물론 가족 간의 유대 강화를 위해 어린이날 행사, 체육대회 등 다채로운 행사 운영 (공식 홈페이지 채용 복리후생 사내 행사 운영 항목) — 개최 주기 미기재', 12),
  (@comp_id, 'club', '사내 동아리', NULL, 'leisure',
   'est', NULL, TRUE, '임직원의 Work & Life Balance를 위한 사내 동아리 활동 지원 (공식 홈페이지 채용 복리후생 사내 동아리 항목) — 지원 금액 미기재', 13),
  (@comp_id, 'travel_support', 'Global 문화체험 (해외 배낭여행 지원)', NULL, 'leisure',
   'est', NULL, TRUE, '이문화 체험을 통해 글로벌 마인드를 함양하고 견문을 넓힐 수 있도록 만 1년 이상 근무 직원을 대상으로 미국·캐나다·유럽 배낭여행을 위한 항공료 및 현지 교통비 등 제공 (공식 홈페이지 채용 복리후생 Global 문화체험 항목, 2026 통합보고서 56쪽 글로벌 문화 체험 제도) — 대상 인원·지원 주기 미기재', 14),
  (@comp_id, 'library', '전자 도서관', NULL, 'leisure',
   'est', NULL, TRUE, '15,000여권 리더십/직무 도서 보유 및 매월 신간 도서/오디오북 구비 (공식 홈페이지 채용 복리후생 전자 도서관 항목), 온라인 오디오북과 전자 도서관 전 임직원 제공 (2026 통합보고서 56쪽)', 15),

  -- ── 보상·금전 (compensation) — 복리후생 명절 지원 · 장기근속포상 / 2026 보고서 보상체계 ──
  (@comp_id, 'holiday_gift', '명절 상품권·귀성여비', NULL, 'compensation',
   'est', NULL, TRUE, '임직원의 사기 진작과 따뜻한 명절 분위기 조성을 위해 설·추석 명절에 상품권 및 귀성여비 지급 (공식 홈페이지 채용 복리후생 명절 지원 항목) — 지급액 미기재', 20),
  (@comp_id, 'long_service_bonus', '장기근속 금 포상', NULL, 'compensation',
   'est', NULL, TRUE, '근속년수에 따라 금 포상 지급 (공식 홈페이지 채용 복리후생 장기근속포상 항목). 매년 9월 20일 기준 10년~40년(5년 단위) 장기근속 시 포상, 근속년수별 금 돈수(10년 8돈 · 15년 11돈 · 20년 14돈 · 25년 17돈 · 30년 20돈)에 해당하는 금코인 또는 국민관광상품권 또는 현금 중 개인 선택, 35년 해외여행 경비, 40년 300만 원(2025년 신설), 계약직 및 파견직 제외 (2026 통합보고서 57쪽 장기근속포상)', 21),
  (@comp_id, 'incentive', '단기성과금·격려금·특별 Incentive', NULL, 'compensation',
   'est', NULL, TRUE, '전체 임직원 대상 조직/개인의 성과평가(MBO) 결과 기반 단기성과금/격려금(변동급), 특별 성과 발생 시 개별 검토하는 특별 Incentive(변동급) (2026 통합보고서 55쪽 보상체계) — 지급 기준·지급률 미기재', 22),

  -- ── 가족·돌봄 (family) — 복리후생 일·가정 양립 지원 · 의료비 지원 · 경조 / 2026 보고서 57쪽 ──
  (@comp_id, 'parenting', '임신·출산·육아 지원', 240, 'family',
   'est', '만 1~2세 자녀 보육지원금 매월 20만원(사내 어린이집 미입소 자녀), 임신 축하 선물·출산경조금·육아휴직 장려금·서포터즈 지원금, 육아휴직 회사 지원 1년, 배우자 출산휴가 회사 유급휴가 5일 추가 (복리후생 페이지 · 2026 통합보고서 56·57쪽) — 월 20만원을 연 240만원으로 환산', FALSE, NULL, 30),
  (@comp_id, 'childcare', '직장 보육시설', NULL, 'family',
   'est', NULL, TRUE, '아동발달 및 교육 전문가 선생님과 연령별 특성화된 보육프로그램, 각종 특별활동을 갖춘 어린이집 운영 (공식 홈페이지 채용 복리후생 직장 보육 시설 항목), 창원/분당에 직장 보육시설 운영 (2026 통합보고서 57쪽) — 정원·입소 조건 미기재', 31),
  (@comp_id, 'child_edu', '자녀 학자금', 300, 'family',
   'est', '초등학생 이하·초중고교생·대학생 자녀 학자금 지원 (공식 홈페이지 채용 복리후생 자녀 학자금 항목), 만 3세 이상 초등학생 정액, 중·고교 입학금·수업료·육성회비 전액, 대학생 입학금·수업료 등 3인 이내 (2026 통합보고서 57쪽) (추정)', FALSE, NULL, 32),
  (@comp_id, 'fertility_support', '난임 시술비 지원', NULL, 'family',
   'est', NULL, TRUE, '난임 시술 비용 지원 (공식 홈페이지 채용 복리후생 의료비 지원 항목), 난임(불임) 시술 시 정부 지원 비용 이외에 100만 원 범위 내 비용 지원, 횟수 제한 없음 (2026 통합보고서 57쪽 난임/불임시술 비용 지원)', 33),
  (@comp_id, 'event', '경조휴가·경조금', NULL, 'family',
   'est', NULL, TRUE, '임직원 및 가족 경조사 발생 시 경조휴가와 경조금 지급, 상조 발생 시 장례 Total Service 제공 (공식 홈페이지 채용 복리후생 경조휴가 및 경조금 항목) — 경조금 액수·휴가 일수 미기재', 34),
  (@comp_id, 'disability_family_support', '장애 자녀 치료비', 240, 'family',
   'est', '3등급 이상의 장애 등급을 받은 만 20세 미만 임직원 자녀에 대해 매월 20만 원의 치료비 지원 (2026 통합보고서 57쪽 의료비 지원) — 월 20만원을 연 240만원으로 환산', FALSE, NULL, 35),

  -- ── 근무 유연성 (flexibility) — 복리후생 선택적 근로시간 제도 / 2026 보고서 유연근무제 ──
  (@comp_id, 'flex_work', '선택적 근로시간제·시차 출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '근무시간을 자율적으로 설계할 수 있는 선택적 근로시간 제도 운영 (공식 홈페이지 채용 복리후생 선택적 근로시간 제도 항목), 월 필요근무시간 내 자율 설계와 일 4시간 코어 타임(10~15시), 시차 출퇴근제로 기본 출퇴근 시간 일정 기간 변경 가능(7 to 4, 8 to 5, 9 to 6 등) (2026 통합보고서 57쪽 유연근무제) — 적용 직군 미기재', 40),
  (@comp_id, 'satellite_office', 'Remote Office (동대문 두산타워)', NULL, 'flexibility',
   'est', NULL, TRUE, '이동으로 인한 업무 시간 손실 예방 등을 위해 수도권 근무자(분당/동탄) 대상 동대문 두산 타워 내 Remote Office 운영 (2026 통합보고서 57쪽 유연근무제)', 41),
  (@comp_id, 'remote_work', '재택근무 (필요 시)', NULL, 'flexibility',
   'est', NULL, TRUE, 'EHS 가이드에 따라 질병 예방 목적 또는 해외 출장 전/후 업무 효율성 확보 목적, 기타 긴급 상황 발생 등 필요 시 재택 근무 가능 (2026 통합보고서 57쪽 재택근무제도) — 사용 일수 미기재', 42),
  (@comp_id, 'pc_off', 'PC-On/Off Agent', NULL, 'flexibility',
   'est', NULL, TRUE, '유연한 근무 환경 조성을 위해 PC-On/Off Agent 적용 (2026 통합보고서 56쪽 일과 가정의 양립을 위한 활동) — 운영 방식 미기재', 43),

  -- ── 근무환경 (work_env) — 복리후생 두산 Dormitory · 기숙사 및 사택 / 2026 보고서 모성보호제도 ──
  (@comp_id, 'dormitory', '기숙사·사택·자녀 기숙사(두산 Dormitory)', NULL, 'work_env',
   'est', NULL, TRUE, '무주택 또는 독신 직원의 안정적 주거생활을 위해 기숙사 및 사택 제공 (공식 홈페이지 채용 복리후생 기숙사 및 사택 항목), 수도권 소재 대학에 진학한 임직원 자녀를 위한 서울 지역 아파트 기숙사 두산 Dormitory 운영 (같은 페이지 두산 Dormitory 항목), 비수도권 근무 임직원 자녀 대상 최대 2년 지원 (2026 통합보고서 57쪽)', 50),
  (@comp_id, 'nap_room', '임산부 휴게실·수유실', NULL, 'work_env',
   'est', NULL, TRUE, '임산부 휴게실 및 수유실 제공 (2026 통합보고서 57쪽 임직원 주요 복지 제도) — 운영 사업장 미기재', 51),

  -- ── 건강·의료 (health) — 복리후생 의료 및 건강증진 지원 · 법률 상담 / 2026 보고서 47·57쪽 ──
  (@comp_id, 'clinic', '사내 부속의원·예방접종', NULL, 'health',
   'est', NULL, TRUE, '의사, 간호사, 물리치료사, 운동처방사가 상주하는 사내의원 운영 (공식 홈페이지 채용 복리후생 사내 부속의원 항목), 임직원 및 가족의 계절독감 및 신종플루 예방접종 지원 (같은 페이지 예방 접종 항목), 해외 파견·출장 시 건강 상담과 지역별 풍토병 예방 접종 지원 (2026 통합보고서 47쪽)', 60),
  (@comp_id, 'mental', '심리상담센터 미소담·법률 상담', NULL, 'health',
   'est', NULL, TRUE, '임직원과 그 가족의 스트레스·고충 해소를 위해 심리상담센터 미소담(미소를 담는 공간) 운영 (공식 홈페이지 채용 복리후생 심리상담센터 항목), 파견/계약직을 포함한 전 직원 대상, 가족은 사외 상담 센터 방문 상담 (2026 통합보고서 57쪽), 직원 법률 관련 고충처리를 위한 무료 법률 상담 서비스 (공식 홈페이지 채용 복리후생 법률 상담 항목)', 61),
  (@comp_id, 'health_check', '종합건강검진', 100, 'health',
   'est', '매년 전 직원과 배우자 종합건강검진 (공식 홈페이지 채용 복리후생), 만 1년 이상 근무 직원 및 배우자(2025년 11월 변경), 만 20년 이상 근속 또는 만 45세 이상 PET-CT 또는 뇌·심혈관 MRA (2026 통합보고서 47·57쪽) — 검진 비용 미기재 (추정)', FALSE, NULL, 62),
  (@comp_id, 'medical', '수술·의료비 지원', 100, 'health',
   'est', '임직원 및 배우자·부모·자녀 수술과 제반 의료비 지원 (공식 홈페이지 채용 복리후생), 본인·배우자·자녀 각 2,000만 원 · 부모 각 500만 원 한도, 협약 병원 진료 편의 (2026 통합보고서 47·57쪽) (추정)', FALSE, NULL, 63),
  (@comp_id, 'insurance', '저축보험·단체정기보험', 30, 'health',
   'est', '노후 대비 및 재해 시 임직원과 가족들의 생활 안정을 위해 저축보험과 단체정기보험 가입 (공식 홈페이지 채용 복리후생 보험 항목) — 보장 내용·보험료 미기재 (추정)', FALSE, NULL, 64),
  (@comp_id, 'fitness', 'Fitness Center (헬스장·탁구장·당구장)', NULL, 'health',
   'est', NULL, TRUE, '임직원 건강 증진을 위해 사내 헬스장·탁구장·당구장 운영 (공식 홈페이지 채용 복리후생 Fitness Center 항목) — 운영 사업장 미기재', 65),

  -- ── 경제적 부가혜택 (perks) — 복리후생 주거 지원 ──
  (@comp_id, 'relocation', '가재이전비·전지지원금', NULL, 'perks',
   'est', NULL, TRUE, '새로운 근무지로 부임 시 이사비용과 주택마련 대출이자 등을 지원 (공식 홈페이지 채용 복리후생 가재이전비 및 전지지원금 항목) — 지원 금액 미기재', 70),
  (@comp_id, 'housing_loan', '사내 근로복지기금 대출 (주택구입·전세·생활안정)', NULL, 'perks',
   'est', NULL, TRUE, '사내 근로복지기금을 조성하여 주택구입 및 전세자금, 생활안정자금을 무이자 또는 저금리로 대출, 회사 내 신용협동조합 운영 (공식 홈페이지 채용 복리후생 사내 근로복지기금 항목) — 대출 한도·금리 미기재', 71),

  -- ── 성장·교육 (growth) — 복리후생 정년퇴직포상 / 2026 보고서 54·56쪽 ──
  (@comp_id, 'retirement_support', '정년퇴직 포상', NULL, 'growth',
   'est', NULL, TRUE, '만 60세로 정년 퇴직하는 직원에게 기념패 및 금 열쇠 등 포상 지급 (공식 홈페이지 채용 복리후생 정년퇴직포상 항목)', 80),
  (@comp_id, 'mba', '석·박사 학위 과정 지원', NULL, 'growth',
   'est', NULL, TRUE, '석·박사 학위 과정 지원 제도 운영 (2026 통합보고서 54쪽 리더십 및 직무 역량 강화 프로그램) — 지원 대상·범위 미기재', 81),
  (@comp_id, 'self_development', '자격증 취득 지원·취득 장려금', NULL, 'growth',
   'est', NULL, TRUE, '직무 관련 자격증 취득을 지원하는 제도 운영, 회사가 지정한 고급 기술 자격증을 신규 취득한 경우 계약직을 포함한 모든 임직원에게 축하금(취득 장려금, 정액·일시불) 지급 (2026 통합보고서 54·56·57쪽) — 장려금 액수 미기재', 82),
  (@comp_id, 'edu_support', '상시학습 온라인 콘텐츠·특강', NULL, 'growth',
   'est', NULL, TRUE, '정규·계약·파견직 전 직원 대상 리더십·경영·어학 관련 상시학습 온라인 콘텐츠로 자기주도학습 및 자기개발 지원 (2026 통합보고서 55쪽 Online 리더십 과정), 온라인 오디오북·특강 등 상시 학습 콘텐츠 전 임직원 제공 (2026 통합보고서 56쪽) — 과정 수·비용 부담 미기재', 83),

  -- ── 시간·휴가 (time_off) — 2026 보고서 47 · 57쪽 ──
  (@comp_id, 'leave_general', '독감 유급휴가 2일', NULL, 'time_off',
   'est', NULL, TRUE, '독감 감염 시 2일간의 유급 휴가 부여 (2026 통합보고서 47쪽 임직원 보건 증진 프로그램)', 90),
  (@comp_id, 'long_service_leave', '근속 35년 해외여행 경비·유급휴가 5일', NULL, 'time_off',
   'est', NULL, TRUE, '근속 35년인 직원 대상 해외여행 시 여행경비 300만 원 및 유급휴가 5일 지원 (2026 통합보고서 57쪽 장기근속포상)', 91),
  (@comp_id, 'refresh_leave', '연중 상시 리프레시 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '충분한 휴식과 재충전 시간을 보장하기 위한 연중 상시 리프레시 휴가 운영 (공식 홈페이지 채용 복리후생 리프레시 휴가 항목) — 휴가 일수·유급 여부·사용 조건 미기재', 92)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
