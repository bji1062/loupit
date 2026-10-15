-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 다우기술 복리후생 데이터 (신규 회사 — 웨이브 8)
-- 출처: AI 파싱 (2026-10-15)
-- URL: https://www.daou.co.kr/ko/recruit/hr
-- badge: est
--
-- 참고:
--   정본 = 다우기술 자기 도메인 채용 > 복지 페이지(SSR · 항목 29개 라벨 + 설명).
--   보조 = 같은 도메인 채용 > 교육 페이지 · 채용 > 다우스토리 페이지 ·
--          자기 채용 사이트 recruit.daou.co.kr 복지 화면(Vite SPA · 화면 문구가 WelfareView 청크에 정적 문자열로 있음) ·
--          자기 도메인 2025 지속가능경영보고서 PDF(보고 기간 2025-01-01~12-31 · 2026-06 작성 · 보고 범위 다우기술 단독) 35 · 39 · 42쪽 ·
--          2026 반기보고서(접수 20260814003900) 유연근무제도 사용 현황 표.
--   렌더 = 정본 · 교육 · 다우스토리는 원본 HTML · 채용 사이트는 번들 청크 문자열(헤드리스 없음 · 사이트 키 사용 없음).
--   귀속 = 전 행 다우기술 자기 도메인 · 자기 보고서 · 자기 공시 문장. 그룹 주어 문장 없음 → 각주 없음.
--          기등록 형제 키움증권(kiwoom.com 복지제도 페이지)과 문장 대조 — 글자까지 같은 문장 없음.
--   금액 = 금액 행 0. 주택자금대출 최대 5,000만원은 원금 한도라 NULL, 복지포인트 · 자기계발비는 액수 미기재.
--   제외 = 법정(4대 보험 · 퇴직연금 · 육아휴직) · 업무 교육(직무 · 리더십 · 신입 · 승진자 · Refresh교육 · 온보딩 · 사내세미나) ·
--          사내추천 수당(인재추천 포상금) · 팀/부서별 워크숍(조직개발 · 업무 계획) · 야간 · 주말 근로 대체 휴일 · 연봉 문구 · 임원 보수 칸.
--   공고 근거 0행 / 전체 31행.
--   SORT 섹션 순서 = family · health · compensation · perks · growth · leisure · flexibility · work_env · time_off(정본 첫 등장 순).
-- 검증 · 감사 판정 반영(2026-10-15): 팀/부서별 워크숍 비용 지원을 팀 커뮤니케이션 제도 행에 병합(참고 블록 제외 줄의 워크숍은 이 판정으로 뒤집힘) · 항목 페이지 예외 6(통합 밖 리드 집행) — 최종 31행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('daou_tech', '다우기술',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        'IT서비스', 'D', 'https://www.daou.co.kr/ko/recruit/hr');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'daou_tech');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.daou.co.kr/ko/recruit/hr'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 가족 (family) — 채용 페이지 복지 · 채용 사이트 복지 ──
  (@comp_id, 'child_edu', '자녀 교육비 지원', NULL, 'family',
   'est', NULL, TRUE, '임직원 자녀 교육비 지원, 영유아~중학생 자녀는 인원 제한 없이 지원, 고등학생 · 대학생 자녀는 최대 2명까지 지원 (공식 채용 페이지 복지 자녀 교육비지원 항목) — 학교급별 지원 한도 미기재', 10),
  (@comp_id, 'event', '경조금 지원', NULL, 'family',
   'est', NULL, TRUE, '경조휴가 및 경조금, 경조화환, 결혼 선물, 상조용품 지원 (공식 채용 페이지 복지 경조금 지원 항목) — 경조 사유별 휴가 일수 · 경조금 액수 미기재', 11),
  (@comp_id, 'parenting', '임신축하선물 · 자녀 입학 축하 및 수능 합격 기원 선물', NULL, 'family',
   'est', NULL, TRUE, '임신을 축하하는 마음을 담아 예비맘에게 필요한 물품을 선택하여 제공, 초중고교 입학 자녀에게 입학 축하 선물 지급 (공식 채용 페이지 복지 임신축하선물 · 입학 축하 및 수능 합격 기원 선물 항목) — 선물 품목 · 금액 미기재', 12),
  (@comp_id, 'disability_family_support', '장애자녀 양육비 지원', NULL, 'family',
   'est', NULL, TRUE, '장애 자녀 양육 시 양육비 지원 (공식 채용 페이지 복지 장애자녀 양육비 지원 항목) — 지원 금액 · 지급 주기 미기재', 13),

  -- ── 건강 (health) — 채용 페이지 복지 · 2025 지속가능경영보고서 ──
  (@comp_id, 'health_check', '정밀종합건강검진', NULL, 'health',
   'est', NULL, TRUE, '매 2년마다 전직원을 대상으로 정밀종합건강검진 실시 (공식 채용 페이지 복지 건강검진 항목) — 검진 항목 · 가족 포함 여부 미기재', 20),
  (@comp_id, 'insurance', '여행자 보험 (워크숍 · 해외 출장 시)', NULL, 'health',
   'est', NULL, TRUE, '워크샵, 해외 출장 시 만일의 사고에 대비하여 여행자 보험에 가입 (공식 채용 페이지 복지 안전기원 항목) — 보장 범위 · 보험금 미기재', 21),
  (@comp_id, 'mental', 'DAOU.M 센터', NULL, 'health',
   'est', NULL, TRUE, '팀 또는 개인의 이슈를 해결할 수 있게 도와주는 센터, 성격검사 · 직무 스트레스 검사 · 코칭 및 상담 · 워크숍 등 운영 (공식 채용 페이지 복지 DAOU.M 센터 항목), 정신 건강 지원 프로그램 운영 (2025 지속가능경영보고서 42쪽 안전보건 경영방침 항목) — 상담 횟수 · 가족 이용 여부 미기재', 22),

  -- ── 보상 (compensation) — 채용 페이지 복지 · 채용 사이트 복지 ──
  (@comp_id, 'holiday_gift', '가정의 달 · 복날 보양식 · 명절 선물', NULL, 'compensation',
   'est', NULL, TRUE, '부모님께 감사의 마음을 전할 수 있는 가정의 달 5월 Family Day 이벤트 실시 (공식 채용 페이지 복지 Family Day 항목), 가정의 달 선물 (공식 채용 사이트 복지 Family Day 항목), 더운 여름 원기회복을 위한 보양식 선물 세트 지급 (공식 채용 페이지 복지 복맞이 삼계탕 항목), 설과 추석에는 임직원에게 여러 옵션 제공 (공식 채용 페이지 복지 명절선물 항목) — 선물 품목 · 금액 미기재', 30),
  (@comp_id, 'long_service_bonus', '장기근속 포상금', NULL, 'compensation',
   'est', NULL, TRUE, '입사 후 첫 3년 근속 및 5년 단위 장기근속 직원에게 포상금 지급 (공식 채용 페이지 복지 장기근속 포상 및 리프레시휴가 부여 항목, 공식 채용 사이트 복지 장기근속 포상 항목) — 근속 연수별 포상금 액수 미기재', 31),

  -- ── 생활 · 금융 (perks) — 채용 페이지 복지 · 2025 지속가능경영보고서 · 채용 사이트 복지 ──
  (@comp_id, 'housing_loan', '주택자금대출', NULL, 'perks',
   'est', NULL, TRUE, '무주택 임직원의 주거안정을 위해 자택 마련을 위한 자금 최대 5,000만원 대출 지원, 저렴한 이자 (공식 채용 페이지 복지 주택자금대출 항목), 입사 직후부터 지원 (공식 채용 사이트 복지 주택 자금 대출 항목), 계약기간 요건에 따라 비정규직 근로자는 대상 제외 (2025 지속가능경영보고서 39쪽 비정규직 복리후생 항목) — 이율 미기재', 40),
  (@comp_id, 'welfare_point', '선택적 복리후생 제도', NULL, 'perks',
   'est', NULL, TRUE, '개개인이 필요에 맞게 복지를 선택할 수 있도록 반기마다 복지포인트 제공 (공식 채용 페이지 복지 선택적 복리후생 제도 항목) — 포인트 액수 · 사용처 미기재', 41),
  (@comp_id, 'welfare_fund_loan', '긴급자금 대출', NULL, 'perks',
   'est', NULL, TRUE, '긴급자금 대출 운영, 계약기간 요건에 따라 비정규직 근로자는 대상 제외 (2025 지속가능경영보고서 39쪽 비정규직 복리후생 항목) — 대출 한도 · 이율 · 자격 요건 미기재', 42),
  (@comp_id, 'team_dinner', '팀 커뮤니케이션 제도 · 팀/부서별 워크숍', NULL, 'perks',
   'est', NULL, TRUE, '단순한 회식이 아닌 팀원과의 소통 및 교류를 위해 다양한 주제로 활동하는 회식 제도 (공식 채용 페이지 복지 팀 커뮤니케이션 제도 항목), 반기마다 부서별로 조직개발을 할 수 있는 워크숍 비용 지원 (공식 채용 페이지 복지 팀/부서별 워크숍 항목) — 지원 금액 · 팀 커뮤니케이션 횟수 미기재', 43),
  (@comp_id, 'snack_bar', '사내 카페', NULL, 'perks',
   'est', NULL, TRUE, '본사 2층 사내 카페에서 커피, 차, 다양한 음료를 저렴한 가격에 제공 (공식 채용 페이지 복지 사내 카페 항목) — 회사 부담 수준 미기재', 44),
  (@comp_id, 'commute_subsidy', '통근버스', NULL, 'perks',
   'est', NULL, TRUE, '출퇴근 시간대 판교역과 본사를 오가는 셔틀버스 운영 (공식 채용 페이지 복지 통근버스 항목), 임직원 무료 탑승 (공식 채용 페이지 다우스토리 셔틀버스 항목) — 운행 횟수 미기재', 45),
  (@comp_id, 'meal', '구내식당 · 1시간 30분 점심시간', NULL, 'perks',
   'est', NULL, TRUE, '구내식당 운영, 사옥 안에서 저렴한 식사 제공, 1시간 30분 점심시간 (공식 채용 사이트 복지 구내식당과 사내 카페 운영 · 1시간 30분 점심시간 항목) — 제공 끼니 · 식대 회사 부담 수준 미기재', 46),

  -- ── 성장 (growth) — 채용 페이지 복지 · 교육 · 다우스토리 · 채용 사이트 복지 ──
  (@comp_id, 'self_development', '자기계발비 · 자격증 취득/갱신 지원', NULL, 'growth',
   'est', NULL, TRUE, '임직원 역량 증진을 위해 반기마다 자기계발비를 지원, 교육수강 · 운동 · 문화활동 등 다양한 목적으로 활용 가능 (공식 채용 페이지 복지 자기계발비 지급 항목), 자격증 응시료 및 갱신 비용 지원 (공식 채용 페이지 교육제도 자격증 취득/갱신 지원 항목) — 자기계발비 액수 · 자격증 지원 범위 미기재', 50),
  (@comp_id, 'edu_support', '다우 아카데미 · 학습동호회 · 온라인교육', NULL, 'growth',
   'est', NULL, TRUE, '자율적으로 신청하는 과정 다우 아카데미에서 공통 업무스킬 교육 · 트렌드 및 생활 · 문화 특강 운영 (공식 채용 페이지 교육제도 다우 아카데미 항목), 점심 런치 아카데미와 저녁 생활 · 문화 특강 블루밍 아카데미 운영 (공식 채용 페이지 다우스토리 특강 항목), 학습동호회 CoP 운영 최소 3명 · 정기모임 일부 비용 매달 지원, 매월 독서통신교육 및 온라인 교육 운영 (공식 채용 페이지 교육제도 공통교육 항목) — 과정 목록 · 지원 한도 미기재', 51),
  (@comp_id, 'books', '도서스터디 도서 제공', NULL, 'growth',
   'est', NULL, TRUE, '직원 개개인으로부터 신청 받은 직무 관련 도서를 제공하고 일정기간 후 서평 제출 (공식 채용 페이지 교육제도 도서스터디 항목) — 지원 권수 · 한도 미기재', 52),
  (@comp_id, 'conference', '외부교육 지원', NULL, 'growth',
   'est', NULL, TRUE, '전문성을 강화할 수 있도록 외부 교육비 전액 지원 (공식 채용 사이트 복지 외부교육 지원 항목) — 대상 교육 범위 · 연간 한도 미기재', 53),

  -- ── 여가 (leisure) — 채용 페이지 복지 · 채용 사이트 복지 ──
  (@comp_id, 'resort', '콘도미니엄 · 연수원 운영', NULL, 'leisure',
   'est', NULL, TRUE, '회사와 연계된 휴양지 시설 콘도 · 연수원을 회원가로 제공, 이용가능시설 오스윗리버 · 대명리조트 · 한화리조트 · 켄싱턴리조트 · 클럽ES리조트 · 리솜리조트 · 오크밸리리조트 (공식 채용 페이지 복지 콘도미니엄 운영 항목) — 이용 횟수 · 회사 부담 수준 미기재', 60),
  (@comp_id, 'club', '취미동호회', NULL, 'leisure',
   'est', NULL, TRUE, '공통의 관심사를 가진 직원들간의 친목과 화합을 위한 취미동호회 지원 (공식 채용 페이지 복지 취미동호회 항목, 공식 채용 사이트 복지 취미/학습 동호회 지원 항목) — 동호회 수 · 활동비 지원 액수 미기재', 61),
  (@comp_id, 'library', '사내 도서관', NULL, 'leisure',
   'est', NULL, TRUE, '본사 1층 개방형 나눔도서관 운영 (공식 채용 페이지 복지 사내 도서관 운영 항목) — 장서 규모 · 이용 시간 미기재', 62),

  -- ── 근무 유연성 (flexibility) — 채용 페이지 복지 · 2025 지속가능경영보고서 · 채용 사이트 복지 · 2026 반기보고서 ──
  (@comp_id, 'family_day', '하프데이', NULL, 'flexibility',
   'est', NULL, TRUE, '월 1회 금요일을 선택하여 오전근무 후 퇴근하는 하프데이 운영 (공식 채용 페이지 복지 하프데이 항목) — 대상 · 급여 공제 여부 미기재', 70),
  (@comp_id, 'flex_work', '유연근무제 · 선택적 근로시간제', NULL, 'flexibility',
   'est', NULL, TRUE, '나의 리듬에 맞게 일할 수 있는 유연근무제 (공식 채용 사이트 복지 유연근무제 항목), 선택적 근로시간제 도입 및 유연한 출퇴근 문화 장려 (2025 지속가능경영보고서 35쪽 조직문화 개선 항목), 선택근무제 사용자 2026년 반기 376명 (2026 반기보고서 유연근무제도 사용 현황 항목) — 의무 근무시간대 · 정산기간 미기재', 71),
  (@comp_id, 'remote_work', '원격근무제(재택근무 포함)', NULL, 'flexibility',
   'est', NULL, TRUE, '원격근무제 재택근무 포함 사용자 2026년 반기 2명, 2025년 2명 (2026 반기보고서 유연근무제도 사용 현황 항목) — 대상 직무 · 사용 조건 미기재', 72),

  -- ── 근무 환경 (work_env) — 채용 페이지 복지 · 채용 사이트 복지 ──
  (@comp_id, 'lounge', 'Relax Zone 안마의자', NULL, 'work_env',
   'est', NULL, TRUE, '본사 층별 1~2개의 안마의자 설치 운영 (공식 채용 페이지 복지 Relax Zone 항목) — 이용 시간 미기재', 80),
  (@comp_id, 'nap_room', 'MOM.편한 라운지', NULL, 'work_env',
   'est', NULL, TRUE, '본사 10층에 편안한 수유 의자를 마련한 라운지 (공식 채용 페이지 복지 MOM.편한 라운지 항목) — 공간 규모 · 이용 대상 미기재', 81),
  (@comp_id, 'work_tools', 'IT 장비 지급', NULL, 'work_env',
   'est', NULL, TRUE, '최고의 IT장비 지급 (공식 채용 사이트 복지 최고의 IT장비 지급 항목) — 장비 종류 · 교체 주기 미기재', 82),

  -- ── 휴가 (time_off) — 채용 페이지 복지 · 채용 사이트 복지 · 2025 지속가능경영보고서 ──
  (@comp_id, 'long_service_leave', '장기근속 리프레시휴가', NULL, 'time_off',
   'est', NULL, TRUE, '입사 후 첫 3년 근속 및 5년 단위 장기근속 직원에게 리프레시휴가 부여 (공식 채용 페이지 복지 장기근속 포상 및 리프레시휴가 부여 항목, 공식 채용 사이트 복지 Refresh 휴가 항목) — 휴가 일수 · 유급 여부 미기재', 90),
  (@comp_id, 'leave_general', '2시간 단위 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '2시간 단위 휴가 등 다양한 휴가 제도 활용 (2025 지속가능경영보고서 35쪽 조직문화 개선 항목) — 사용 한도 · 신청 절차 미기재', 91)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
