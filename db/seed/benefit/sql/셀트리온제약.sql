-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 셀트리온제약 복리후생 데이터 (신규 회사)
-- 출처: AI 파싱 (2026-09-05)
-- URL: https://www.celltrionph.com/ko-kr/career/welfare
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고: 근거는 전부 셀트리온제약 법인 자체 도메인(celltrionph.com) CAREER > 복지제도 페이지.
--       SSR HTML 이라 curl + 파서로 충분하다(JS 렌더 아님). 페이지 헤딩이
--       「셀트리온제약의 다양한 복지제도를 소개합니다」, 영문판이
--       「Here are welfare benefits for Celltrion Pharm employees」 라
--       법인 귀속이 본문에 박혀 있다 — 그룹 통합 페이지 차용이 아니다.
--       ⚠ 실도메인은 celltrionph.com 이다. 추정 도메인 celltrionph.co.kr /
--       celltrionpharm.com 은 443 이 타임아웃이고 80 포트에서 403 JSON 을 뱉는
--       meta refresh 껍데기다 — 봇 차단으로 오독하면 재수집이 통째로 실패한다.
--       ⚠ 파싱 범위를 .welfare_cont 로 좁혀야 17항목이다. 페이지 전체 dd 는
--       스킵내비 3개가 섞여 20개가 된다(실측 확인).
--       원문 17항목 / 4섹션(가족 5 · 건강 4 · 회사생활 4 · 여가활동 4) → 16행.
--       분리 1: 「포인트 지급 (생일포인트, 복지포인트)」 복합 라벨을
--               birthday_gift + welfare_point 로 분리(+1, 모회사 셀트리온.sql 과 동일 매핑).
--       병합 1: 「출퇴근 셔틀버스 지원」 + 「새벽 및 심야 출/퇴근 택시 지원」 →
--               commute_subsidy 1행(-1). 둘 다 출퇴근 이동수단 지원이고 코드는
--               회사당 UNIQUE 다. 모회사 셀트리온.sql 의 commute_subsidy
--               「셔틀버스/콜택시」 선례와 같은 처리.
--       항목별 설명 문장이 없고 라벨뿐이다. 금액 표기 0건 —
--       숫자는 「월 1회」 하나뿐이고 금액이 아니다. 따라서 16행 전부
--       BENEFIT_AMT NULL · QUAL_YN TRUE 이며, 신규 회사라 승계할 앵커도 없어
--       타사 금액을 끌어오지 않았다(금액 stated 0건).
--       법정 제도(4대보험·퇴직연금·연차·육아휴직)는 페이지에도 없고 수록도 하지 않는다.
--       ⚠ 모회사 셀트리온(celltrion.com)은 별개 법인·별개 도메인이다. 본문을
--       참조하지 않았고, 같은 제도명에 같은 코드를 쓰는 매핑 일관성만 맞췄다.
--       SORT 섹션 순서 = 각 카테고리가 원문에 처음 등장하는 순서
--       (가족 → 건강 → 회사생활 → 여가활동). perks 는 가족 섹션의 귀향비·포인트에서
--       처음 등장하므로 20 이다.
--       ⚠ 검증·감사 판정 반영(2026-09-05): 행 조치 없음(17행 그대로). SORT 21·22·23 의
--       사용자 노출 서술에서 행 분리·병합 사실을 걷어냈다. SORT 52 사내 문화체험
--       클래스는 company_event 로 유지한다 — 모회사 셀트리온이 같은 제도를 club 에
--       흡수해 두 파일이 갈리는데, 되돌릴 쪽은 모회사다(셀트리온 재수집 때 처리).
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('celltrion_pharm', '셀트리온제약',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '제약', 'C', 'https://www.celltrionph.com/ko-kr/career/welfare');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'celltrion_pharm');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.celltrionph.com/ko-kr/career/welfare'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 가족·돌봄 (family) ── 원문 섹션 1 가족
  (@comp_id, 'childcare', '공동 어린이집', NULL, 'family',
   'est', NULL, TRUE, '임직원 자녀 대상 공동 어린이집 운영 (공식 복지제도 페이지 가족 항목명 그대로 — 정원·대상 연령·위치 미기재)', 10),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀 학자금 지원 (공식 복지제도 페이지 가족 항목명 그대로 — 지원 학교급·한도·자녀 수 제한 미기재)', 11),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '가족 및 본인 경조사 지원 (공식 복지제도 페이지 가족 항목명 그대로 — 경조금·경조휴가 구분 및 금액 미기재)', 12),

  -- ── 경제적 부가혜택 (perks) ── 원문 섹션 1 가족 + 섹션 3 회사생활
  (@comp_id, 'transport', '타 지역 미혼사원 귀향비', NULL, 'perks',
   'est', NULL, TRUE, '타 지역 미혼사원 귀향비 지원 (공식 복지제도 페이지 가족 항목명 그대로 — 대상이 타 지역 미혼사원으로 한정되며 지원 주기·금액 미기재)', 20),
  (@comp_id, 'birthday_gift', '생일포인트', NULL, 'perks',
   'est', NULL, TRUE, '포인트 지급 (생일포인트, 복지포인트) 중 생일포인트 (공식 복지제도 페이지 가족 항목 — 포인트 금액·지급 시기 미기재)', 21),
  (@comp_id, 'welfare_point', '복지포인트', NULL, 'perks',
   'est', NULL, TRUE, '포인트 지급 (생일포인트, 복지포인트) 중 복지포인트 (공식 복지제도 페이지 가족 항목 — 연간 포인트 금액·사용처 미기재)', 22),
  (@comp_id, 'commute_subsidy', '출퇴근 셔틀버스·심야 택시', NULL, 'perks',
   'est', NULL, TRUE, '출퇴근 셔틀버스 지원 / 새벽 및 심야 출·퇴근 택시 지원 (공식 복지제도 페이지 회사생활 항목 — 노선·운행 지역·이용 조건·지원 한도 미기재)', 23),
  (@comp_id, 'meal', '식사 지원', NULL, 'perks',
   'est', NULL, TRUE, '식사 지원 (공식 복지제도 페이지 회사생활 항목명 그대로 — 제공 끼니·식대 단가·사업장별 운영 방식 미기재)', 24),

  -- ── 건강·의료 (health) ── 원문 섹션 2 건강
  (@comp_id, 'medical', '의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '의료비 지원 (공식 복지제도 페이지 건강 항목명 그대로 — 영문판은 상해·질병 대상 지원으로 표기, 지원 한도·대상 범위 미기재)', 30),
  (@comp_id, 'insurance', '단체상해보험', NULL, 'health',
   'est', NULL, TRUE, '단체상해보험 (공식 복지제도 페이지 건강 항목명 그대로 — 보장 범위·가입 대상·보험료 미기재)', 31),
  (@comp_id, 'clinic', '사내 보건실', NULL, 'health',
   'est', NULL, TRUE, '사내 보건실 운영 (공식 복지제도 페이지 건강 항목명 그대로 — 상주 인력·운영 시간·사업장 미기재)', 32),
  (@comp_id, 'health_check', '건강검진 지원', NULL, 'health',
   'est', NULL, TRUE, '건강검진 지원 (공식 복지제도 페이지 건강 항목명 그대로 — 주기·검진 항목·가족 포함 여부·금액 미기재)', 33),

  -- ── 보상·금전 (compensation) ── 원문 섹션 3 회사생활
  (@comp_id, 'long_service_bonus', '장기근속자 포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속자 포상 (공식 복지제도 페이지 회사생활 항목명 그대로 — 영문판이 reward 로 표기해 포상이며 휴가 부여는 언급 없음, 근속 연차·포상 내용·금액 미기재)', 40),

  -- ── 여가·라이프 (leisure) ── 원문 섹션 4 여가활동
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 운영 및 지원 (공식 복지제도 페이지 여가활동 항목명 그대로 — 활동비 지원 한도·동호회 수 미기재)', 50),
  (@comp_id, 'resort', '관광지 콘도 회원가 이용', NULL, 'leisure',
   'est', NULL, TRUE, '주요 관광지 콘도 회원가 이용 (공식 복지제도 페이지 여가활동 항목명 그대로 — 제휴처·이용 요금·연간 이용 일수 미기재)', 51),
  (@comp_id, 'company_event', '사내 문화체험 클래스', NULL, 'leisure',
   'est', NULL, TRUE, '월 1회 사내 문화체험 클래스 운영 (공식 복지제도 페이지 여가활동 항목명 그대로 — 운영 주기 월 1회만 명시되고 클래스 종류·참가비 부담 주체 미기재)', 52),
  (@comp_id, 'library', '전자도서관', NULL, 'leisure',
   'est', NULL, TRUE, '전자도서관 운영 (공식 복지제도 페이지 여가활동 항목명 그대로 — 장서 규모·이용 방식 미기재)', 53)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
