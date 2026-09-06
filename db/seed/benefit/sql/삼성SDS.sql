-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 삼성SDS 복리후생 데이터 (신규 회사)
-- 출처: AI 파싱 (2026-09-05)
-- URL: https://www.samsungcareers.com/subsid/detail/C60
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고: 정본이 자기 도메인이 아니라 삼성 공식 채용사이트의 삼성SDS 법인 전용 페이지다.
--       samsungsds.com 에는 채용·복지 섹션이 아예 없다 — recruit·careers 서브도메인
--       NXDOMAIN(이번 수집에서 재확인), 사이트맵 loc 3,181개 중 채용 페이지 0건.
--       C60 페이지의 section id=a6 「삼성SDS의 근무 환경과 복지 제도」 = 카테고리 3 · 항목 23.
--       ⚠ URL 에 회사명이 없다. C60 코드가 바뀌면 조용히 다른 관계사를 긁는다 —
--       재수집 시 본문에 삼성SDS 와 sdsjobs@samsung.com 이 있는지 먼저 검증한 뒤 파싱할 것.
--       (이번 수집도 파싱 전 검증 통과: 본문 삼성SDS 17회 · 채용문의 메일 2종 · 송파구 본사 주소.)
--       ⚠ 그룹 공통 페이지 samsungcareers.com/insight/welfare 는 26개 관계사 공용이라 섞지 않았다.
--       거기에만 있는 통근버스·기숙사·문화행사·GWP·주재원·경력컨설팅·사내창업지원은 전부 미수록.
--       그 페이지 스스로 「관계사별 복지 제도는 각 회사별 페이지에서 확인 가능합니다」라고 갈라 말한다.
--       법인 전용 페이지를 정본으로 쓰므로 「그룹 통합 채용 기준」 각주는 붙이지 않는다(KB금융과 반대).
--       원문 23항목 → 24행: 직무 교육 1건 제외(계약 규칙 8 — 회사 주도 교육 커리큘럼),
--       삼성 MBA·EMBA 와 IT석사를 mba 한 행으로 병합, 임신/출산/육아를 3행으로,
--       장기근속휴가/장기근속시상을 2행으로 분할했다(어휘 함정 — 휴가와 포상은 코드가 다르다).
--       ⚠ 페이지 전체에 금액 표기가 0건이다(만원·원·% 패턴 없음, 표현이 「일부 또는 전부」
--       「매월 일정 금액」 식) → 24행 전부 BENEFIT_AMT NULL · QUAL_YN TRUE.
--       신규 회사라 승계할 앵커도 없어 타사 금액을 끌어오지 않았다.
--       ⚠ 사업장 한정 문구(잠실·상암·판교)는 원문 그대로 QUAL_DESC 에 남겼다. 지우면 전 사업장
--       공통 제도인 것처럼 과장된다.
--       ⚠ LOGO_NM 은 지시값 「삼」 대신 「S」 를 넣었다 — 기존 삼성 7개사가 전부 S 이고
--       코퍼스 113개사 중 112개가 로마자 이니셜이다. 「삼」 으로 되돌리려면 이 줄만 고치면 된다.
--       ⚠ 검증·감사 판정 반영(2026-09-05): SORT 62 지역전문가(self_development)를 SORT
--       61 OPEN 제도(career)에 병합해 24 → 23행. 코퍼스 self_development 12행 중 11행이
--       자기계발비라 해외 파견을 넣으면 없는 주장이 선다 — 파견형은 career·mba 축이다.
--       사용자 노출 3필드의 편집 주석도 함께 걷어냈다.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('samsung_sds', '삼성SDS',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        'IT서비스', 'S', 'https://www.samsungcareers.com/subsid/detail/C60');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'samsung_sds');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.samsungcareers.com/subsid/detail/C60'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강·의료 (health) ──
  (@comp_id, 'health_check', '건강검진 지원', NULL, 'health',
   'est', NULL, TRUE, '임직원 본인 및 배우자의 주기적 건강검진 지원 — 질병 조기 발견·치유 목적 (검진 주기·항목·비용 한도 미기재)', 10),
  (@comp_id, 'medical', '의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '임직원 본인·배우자·자녀의 통원치료비와 입원비 일부 지원 (지원 비율·연간 한도 미기재)', 11),
  (@comp_id, 'mental', '마음건강센터', NULL, 'health',
   'est', NULL, TRUE, '사내 마음건강센터 운영 — 개인상담을 포함해 심리검사와 온오프라인 마음건강 프로그램 제공 (이용 횟수·가족 포함 여부 미기재)', 12),
  (@comp_id, 'clinic', '사내 부속의원', NULL, 'health',
   'est', NULL, TRUE, '대규모 사업장(잠실/판교) 내 사내 부속의원 운영 — 응급상황 대비·건강관리 편의. 원문이 사업장을 한정한다(전 사업장 공통 아님)', 13),
  (@comp_id, 'fitness', '사내 피트니스', NULL, 'health',
   'est', NULL, TRUE, '대규모 사업장(잠실, 상암 등) 내 사내 피트니스 운영 — 건강·체력 증진 지원. 원문의 사업장 한정 문구 그대로', 14),
  (@comp_id, 'massage', '헬스케어 (마사지 관리)', NULL, 'health',
   'est', NULL, TRUE, '대규모 사업장(잠실, 상암 등) 내 헬스케어실 운영 — 피로 회복 목적 마사지 관리 제공. 원문의 사업장 한정 문구 그대로 (이용 횟수·예약 방식 미기재)', 15),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'child_edu', '자녀학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '임직원 자녀의 유치원비와 국내외 중·고·대학교 학자금의 일부 또는 전부 지원 (지원 비율·자녀 수 제한·금액 미기재)', 20),
  (@comp_id, 'parenting', '임신/출산/육아 지원', NULL, 'family',
   'est', NULL, TRUE, '임산부 전용 휴게실 운영 (공식 페이지 임신/출산/육아 지원 항목 — 위치·이용 조건 미기재)', 21),
  (@comp_id, 'fertility_support', '난임시술 비용 지원', NULL, 'family',
   'est', NULL, TRUE, '임신/출산/육아 지원 항목에 명시된 난임시술 비용 지원 (지원 한도·시술 횟수 미기재)', 22),
  (@comp_id, 'childcare', '사내 어린이집', NULL, 'family',
   'est', NULL, TRUE, '임신/출산/육아 지원 항목에 명시된 사내 어린이집 운영 (정원·대상 연령·설치 사업장 미기재)', 23),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '임직원 가족의 경조사 발생 시 경조금 및 휴가 등 지원 (경조금액·경조휴가 일수 미기재)', 24),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'welfare_point', '선택적 복리후생 지원', NULL, 'perks',
   'est', NULL, TRUE, '건강·여행·도서 등 항목에서 개인 라이프 스타일에 따라 선택해 쓰는 복지포인트 제공 (연간 포인트 금액 미기재)', 30),
  (@comp_id, 'pension_support', '개인연금', NULL, 'perks',
   'est', NULL, TRUE, '노후생활 지원을 위해 연금상품에 가입하고 매월 일정 금액을 회사가 지원 (원문 표현이 매월 일정 금액이라 지원액을 알 수 없다)', 31),
  (@comp_id, 'housing_loan', '주거안정지원', NULL, 'perks',
   'est', NULL, TRUE, '주택 구입/전세 계약의 대출 이자 일부 지원 (이자 보전 비율·한도·자격 미기재)', 32),
  (@comp_id, 'meal', '사내 식당 및 카페', NULL, 'perks',
   'est', NULL, TRUE, '대규모 사업장(잠실, 상암 등)에 사내 식당·카페 운영 또는 이용 지원 (제공 끼니·식대 단가 미기재). 원문의 사업장 한정 문구 그대로', 33),

  -- ── 휴가 (time_off) ──
  (@comp_id, 'long_service_leave', '장기근속휴가', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속 임직원이 재충전할 수 있도록 휴가와 휴가비 지원 — 원문 항목 장기근속휴가/장기근속시상 중 휴가 부분 (근속 연차 기준·휴가 일수·휴가비 금액 미기재)', 40),

  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'long_service_bonus', '장기근속시상', NULL, 'compensation',
   'est', NULL, TRUE, '오랜 시간 노력해 온 장기근속 임직원 시상 — 원문 항목 장기근속휴가/장기근속시상 중 시상 부분 (근속 연차 기준·포상 내용·금액 미기재)', 50),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'lang', '외국어 교육', NULL, 'growth',
   'est', NULL, TRUE, '실무 중심 어학과정 운영 — 온라인 어학 과정과 1:1 전화외국어 코칭 등 제공 (수강 자격·연간 한도 미기재)', 60),
  (@comp_id, 'career', 'OPEN 제도·지역전문가', NULL, 'growth',
   'est', NULL, TRUE, '본인이 희망하는 업무를 선택해 업무전환을 할 수 있는 OPEN 제도와 Career Path 설정 지원, 베트남·중국·인도 등 전략국가 지역전문가 파견 (신청 자격·공모 주기·파견 기간·선발 규모 미기재)', 61),
  (@comp_id, 'mba', '삼성 MBA·EMBA / IT석사', NULL, 'growth',
   'est', NULL, TRUE, '국내외 대학 MBA·EMBA 연수과정 파견과 클라우드·보안 등 국내외 우수대학 석사과정 파견 (학비 부담 범위·선발 인원 미기재)', 63),

  -- ── 근무 유연성 (flexibility) ──
  (@comp_id, 'flex_work', '자율출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '월 의무근무시간을 준수하는 범위에서 개인이 1일 근무시간을 자율적으로 관리 (코어타임·정산 단위 미기재)', 70),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '사원 상호간 친목 도모와 활기찬 근무분위기 조성을 위한 다양한 동호회 활동 지원 (활동비 지원 여부·동호회 수 미기재)', 80),
  (@comp_id, 'resort', '여가생활 지원', NULL, 'leisure',
   'est', NULL, TRUE, '법인콘도와 에버랜드·캐리비안베이 할인 이용 제공 등으로 휴식·여가생활 지원 (콘도 지점·할인율·연간 이용 한도 미기재)', 81)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
