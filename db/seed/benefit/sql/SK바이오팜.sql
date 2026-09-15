-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- SK바이오팜 복리후생 데이터 (신규 회사)
-- 출처: AI 파싱 (2026-09-14)
-- URL: https://www.skbp.com/kor/sustainability/talent.do
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고: 근거는 전부 법인 자기 도메인 www.skbp.com 한 페이지다(DART 정식명 에스케이바이오팜,
--       KOSPI 326030). 경로 = 지속가능경영 > ESG 성과 > Human Capital Management 의
--       h4 복리후생 아래 ul.m_list.n2, 4카테고리 16줄(회사 생활 6 · 자녀 양육 3 · 건강 관리 3 ·
--       주거 및 여가 활동 4). JSP 서버렌더라 최초 HTML 텍스트로 전부 있다 — 헤드리스 불필요.
--       ⚠ 복지는 채용 메뉴(/kor/recruit/careers.do)가 아니라 ESG 메뉴 아래에 있다. 채용 페이지는
--         절차만 있고 복지 0건이다.
--       ⚠ 반드시 www 를 붙인다(apex skbp.com 은 타임아웃). 국문판만 쓴다 — 영문판은 항목 대응이
--         어긋난다(프로브 대조).
--       귀속: 법인 자기 도메인이라 그룹 통합 각주는 붙이지 않았다. SK Careers(skcareers.com)
--         Culture 페이지의 그룹 공통 서술(사내 어린이집·승인 없는 휴가 등)은 한 건도 섞지 않았고,
--         기등록 SK 3사 시드도 참고하지 않았다.
--       16줄 → 법정 제도 2줄 제외(태아 검진·난임 치료 시 휴가 / 출산휴가·육아휴직 제도 운영) → 14줄.
--         복합 줄 4개 분해(근로 시간제·재택근무제 / 근속자 포상·휴가 / 출근버스·차량 보조금 /
--         여름 휴가·해피프라이데이) +4, 같은 코드 병합 2건 -2 → 16행. 신규 코드 0.
--         병합: 해피프라이데이(1달에 1회 주 4일 근무) → flex_work(카카오 월 1회 금요일 휴무 ·
--         카카오게임즈 격주 4일제 선례, family_day 는 조기퇴근이라 회피) ·
--         독감예방접종 → health_check(셀트리온·현대모비스 선례).
--       금액: 원문에 금액 0건 → 16행 전부 BENEFIT_AMT NULL · QUAL_YN TRUE. 앵커 없음.
--       제외(교육 커리큘럼): 같은 페이지 구성원 역량 개발 표의 New Comer·SKMS 워크숍·Self Learning 등 회사 주도 교육.
--         단 같은 표 학위 항목 「우수 구성원 선발을 통한 국내 MBA 과정 지원」은 규칙 8-1 로 mba 1행(SORT 71, 감사 지시).
--       SORT 섹션 순서는 원문 16줄에서 각 카테고리가 처음 나온 순서
--         (flexibility 10 · compensation 20 · time_off 30 · perks 40 · family 50 · health 60 ·
--          growth 70 · leisure 80).
--       ⚠ 검증·감사 판정 반영(2026-09-15): 16행 그대로(병합 −1 · 추가 +1). SORT 42 차량 보조금(transport)은 용도 미기재라
--       원문 한 줄대로 SORT 41 출근버스(commute_subsidy)에 병합 · SORT 71 mba(국내 MBA 과정 지원) 추가.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('sk_biopharm', 'SK바이오팜',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '제약', 'S', 'https://www.skbp.com/kor/sustainability/talent.do');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'sk_biopharm');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.skbp.com/kor/sustainability/talent.do'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무 유연성 (flexibility) — 원문 회사 생활 ──
  (@comp_id, 'flex_work', '선택적 근로 시간제·해피프라이데이', NULL, 'flexibility',
   'est', NULL, TRUE, '선택적 근로 시간제 시행, 해피프라이데이 1달에 1회 주 4일 근무 (공식 홈페이지 지속가능경영 복리후생 회사 생활 항목 — 정산 기간·의무 근무시간대·해피프라이데이 적용 요일 미기재)', 10),
  (@comp_id, 'remote_work', '재택근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '재택근무제 시행 (공식 홈페이지 지속가능경영 복리후생 회사 생활 항목 — 사용 가능 일수·적용 대상 미기재)', 11),

  -- ── 보상·금전 (compensation) — 원문 회사 생활 ──
  (@comp_id, 'long_service_bonus', '장기 근속자 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기 근속자 포상 지급 (공식 홈페이지 지속가능경영 복리후생 회사 생활 항목 — 근속 기간 기준·포상 내용·금액 미기재)', 20),

  -- ── 휴가 (time_off) — 원문 회사 생활 ──
  (@comp_id, 'long_service_leave', '장기 근속자 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '장기 근속자 휴가 지급 (공식 홈페이지 지속가능경영 복리후생 회사 생활 항목 — 근속 기간 기준·휴가 일수 미기재)', 30),
  (@comp_id, 'summer_leave', '여름 휴가', NULL, 'time_off',
   'est', NULL, TRUE, '여름 휴가 (공식 홈페이지 지속가능경영 복리후생 회사 생활 항목 — 휴가 일수·휴가비 지급 여부 미기재)', 31),

  -- ── 경제적 부가혜택 (perks) — 원문 회사 생활 + 주거 및 여가 활동 ──
  (@comp_id, 'meal', '사내 식당 (중·석식)', NULL, 'perks',
   'est', NULL, TRUE, '사내 식당 운영, 중식·석식 제공 (공식 홈페이지 지속가능경영 복리후생 회사 생활 항목 — 식대 단가·본인 부담 여부 미기재)', 40),
  (@comp_id, 'commute_subsidy', '출근버스·차량 보조금', NULL, 'perks',
   'est', NULL, TRUE, '출근버스 및 차량 보조금 지원 (공식 홈페이지 지속가능경영 복리후생 회사 생활 항목 — 노선·보조금 용도·지급 대상·금액 미기재)', 41),
  (@comp_id, 'housing_loan', '주택 구입·임차 대출 지원', NULL, 'perks',
   'est', NULL, TRUE, '주택 구입·임차 시 대출 지원 (공식 홈페이지 지속가능경영 복리후생 주거 및 여가 활동 항목 — 대출 한도·이율·자격 요건 미기재)', 43),
  (@comp_id, 'welfare_point', '선택적 복리후생 (복지 포인트)', NULL, 'perks',
   'est', NULL, TRUE, '선택적 복리후생(복지 포인트) 지급 (공식 홈페이지 지속가능경영 복리후생 주거 및 여가 활동 항목 — 연간 포인트 금액 미기재)', 44),

  -- ── 가족·돌봄 (family) — 원문 회사 생활 + 자녀 양육 ──
  (@comp_id, 'event', '경조 휴가·경조금', NULL, 'family',
   'est', NULL, TRUE, '경조사 발생 시 휴가·경조금 지급 (공식 홈페이지 지속가능경영 복리후생 회사 생활 항목 — 경조 사유별 휴가 일수·경조금액 미기재)', 50),
  (@comp_id, 'child_edu', '자녀 교육비 지원 (유치원~대학교)', NULL, 'family',
   'est', NULL, TRUE, '유치원~대학교 교육비 지원 (공식 홈페이지 지속가능경영 복리후생 자녀 양육 항목 — 지원 한도·자녀 수 제한·금액 미기재)', 51),

  -- ── 건강·의료 (health) — 원문 건강 관리 ──
  (@comp_id, 'health_check', '건강검진 (직원·배우자)·독감예방접종', NULL, 'health',
   'est', NULL, TRUE, '직원 및 배우자 대상 건강검진, 독감예방접종 진행 (공식 홈페이지 지속가능경영 복리후생 건강 관리 항목 — 검진 주기·검진 비용·접종 대상 범위 미기재)', 60),
  (@comp_id, 'medical', '의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '의료비 지원 (공식 홈페이지 지속가능경영 복리후생 건강 관리 항목 — 지원 대상 가족 범위·한도·금액 미기재)', 61),

  -- ── 성장·커리어 (growth) — 원문 주거 및 여가 활동 ──
  (@comp_id, 'edu_support', '교육 기회 및 지원금', NULL, 'growth',
   'est', NULL, TRUE, '다양한 교육 기회 및 지원금 제공 (공식 홈페이지 지속가능경영 복리후생 주거 및 여가 활동 항목 — 지원 대상 교육 종류·지원금 한도 미기재)', 70),
  (@comp_id, 'mba', '국내 MBA 과정 지원', NULL, 'growth',
   'est', NULL, TRUE, '우수 구성원 선발을 통한 국내 MBA 과정 지원 (공식 홈페이지 지속가능경영 구성원 역량 개발 표 학위 항목 — 선발 기준·인원, 학비 지원 범위, 의무 근속 조건 미기재)', 71),

  -- ── 여가·라이프 (leisure) — 원문 주거 및 여가 활동 ──
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 활동 지원 (공식 홈페이지 지속가능경영 복리후생 주거 및 여가 활동 항목 — 활동비 지원액·동호회 수 미기재)', 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
