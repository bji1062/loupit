-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 메가스터디교육 복리후생 데이터 (신규 회사 — 웨이브 12)
-- 출처: AI 파싱 (2026-10-18)
-- URL: https://megastudyedu.career.greetinghr.com/ko/culture
-- badge: est
--
-- 참고:
--   정본 = 회사 계정 그리팅 채용 사이트 Life 페이지 WELFARE 절(SSR 텍스트 블록 · 워크스페이스 이름 메가스터디교육 ·
--   www.megastudy.net 꼬리말 인재채용 링크 · 같은 꼬리말 운영 법인 메가스터디교육(주)).
--   보조 = 같은 사이트 구내식당 · 사내카페 · 동호회 소개 페이지, 게시 중 채용 공고 2건(o/240193 · o/238836)의
--   복리후생 블록(공고 본문이 이미지 — 판독 사본), 2026 반기보고서(20260814004117) 유연근무제도 사용현황 표
--   (2025 사업보고서 20260318000849 표와 대조).
--   귀속: 법인 자기 채용 사이트 · 자기 공고 · 자기 공시 — 각주 없음. 메가스터디(주)(지주 성격 별개 법인) 자료 미사용.
--   강사 모집 페이지(corp.megastudy.net 강사모집 — 위탁 강사 대상 출강 안내)는 직원 제도가 아니라 미사용.
--   금액: 금액 행 0 — 원문에 숫자 금액 없음. 사내 식당은 할인만 밝혀 식대 식 미적용(금액 NULL).
--   제외: 임신기 단축근로 · 산전후 휴가 · 육아휴직 · 배우자 출산 휴가 · 자유로운 휴가 사용(법정) · 자유로운 복장(대응 코드 없음) ·
--   역 도보 2분 위치(제도 아님) · 마케팅 전문가 특강 · AI 활용 교육(직무 역량 강화 업무 교육) · 선택근무제(공시 전 기간 사용자 없음).
--   공고 근거 3행(SORT 24 · 52 · 71) / 전체 19행 — 나머지 행의 공고 인용은 보조.
--   SORT 섹션 순서 = Life 페이지 첫 등장 순 growth · perks · leisure · health · family · time_off · compensation, 공시만 flexibility 끝.
-- 검증 · 감사 판정 반영(2026-10-18): 사내 카페·메가스낵존 snack_bar 이름과 서술에 원문 매점 낱말 살림 · 지하2층 사내 공간 소개 페이지 라운지 lounge 를 work_env 새 섹션으로 추가(리드 판정 154) · 참고 블록의 공고 근거 3행 / 전체 19행은 전체 20행 · 보조 출처와 SORT 섹션 순서 줄에 사내 공간 소개가 없는 것과 제외 줄의 사옥 시설 소개는 이 판정으로 뒤집힘 · 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 20행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('megastudy_edu', '메가스터디교육',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '교육', 'M', 'https://megastudyedu.career.greetinghr.com/ko/culture');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'megastudy_edu');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://megastudyedu.career.greetinghr.com/ko/culture'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 성장 (growth) — 채용 사이트 Life 페이지 · 채용 공고 ──
  (@comp_id, 'edu_support', '자사 강좌 수강료 지원', NULL, 'growth',
   'est', NULL, TRUE, '자사 강좌 수강료 지원 (공식 채용 사이트 Life 페이지 WELFARE 항목), 자사 강좌 수강료 지원 (채용 공고 복리후생 항목) — 지원 범위·대상 강좌 미기재', 10),
  -- ── 생활 · 편의 (perks) — 채용 사이트 Life · 구내식당 · 사내카페 페이지 · 채용 공고 ──
  (@comp_id, 'discount', '인강·학원 할인 · 그룹사 브랜드 할인 · 가족 강좌 수강료 지원', NULL, 'perks',
   'est', NULL, TRUE, '인강/학원 할인 혜택, 그룹사 브랜드 할인 혜택, 가족/친인척 강좌 수강료 지원 (공식 채용 사이트 Life 페이지 WELFARE 항목), 자사 강좌 할인혜택 (채용 공고 복리후생 항목) — 할인율·대상 브랜드·지원 범위 미기재', 20),
  (@comp_id, 'meal', '사내 식당 할인 (구내식당 메가키친)', NULL, 'perks',
   'est', NULL, TRUE, '사내 식당 할인 제공 (공식 채용 사이트 Life 페이지 WELFARE 항목), 구내식당 메가키친 점심에 한 번 · 저녁에 한 번 운영, 저녁 샐러드 도시락 · 일반 도시락 (구내식당 소개 페이지 항목) — 식대 부담 범위·할인율 미기재', 21),
  (@comp_id, 'snack_bar', '사내 카페 할인 (온엠오프) · 매점 메가스낵존', NULL, 'perks',
   'est', NULL, TRUE, '사내 카페 할인 제공 (공식 채용 사이트 Life 페이지 WELFARE 항목), 사내 카페 온엠오프 구성원 메뉴 할인 (사내카페 소개 페이지 항목), 오피스 매점 메가스낵존 다양한 신제품이나 간식 제공 (구내식당 소개 페이지 항목) — 할인율·매점 이용 비용 미기재', 22),
  (@comp_id, 'birthday_gift', '생일 상품권 · 케이크 교환권', NULL, 'perks',
   'est', NULL, TRUE, '생일 신세계 상품권 지급, 생일 케익 교환권 지급 (공식 채용 사이트 Life 페이지 WELFARE 항목), 생일/기념일 축하 선물 제공 (채용 공고 복리후생 항목) — 상품권 금액 미기재', 23),
  (@comp_id, 'welfare_fund_loan', '생활안정 대출 지원', NULL, 'perks',
   'est', NULL, TRUE, '생활안정 대출 지원 (채용 공고 복리후생 우리도 누려요 항목) — 대출 한도·이율 미기재', 24),
  -- ── 여가 (leisure) — 채용 사이트 Life · 동호회 페이지 · 채용 공고 ──
  (@comp_id, 'resort', '법인 콘도 지원', NULL, 'leisure',
   'est', NULL, TRUE, '법인 콘도 지원(대명, 한화, 휘닉스파크) (공식 채용 사이트 Life 페이지 WELFARE 항목, 채용 공고 복리후생 항목) — 이용 횟수·비용 지원 범위 미기재', 30),
  (@comp_id, 'welcome_kit', '웰컴키트', NULL, 'leisure',
   'est', NULL, TRUE, '합류를 축하하는 의미의 웰컴키트 지급 (공식 채용 사이트 Life 페이지 WELFARE 항목), 신규 입사자 웰컴키트 지급 (채용 공고 복리후생 항목) — 구성품 미기재', 31),
  (@comp_id, 'club', '사내 동호회 지원', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 지원 (공식 채용 사이트 Life 페이지 WELFARE 항목), 동호회 지원 (채용 공고 복리후생 항목), 사내 동호회 소개 (동호회 소개 페이지 항목) — 지원 금액·동호회 종류 미기재', 32),
  -- ── 건강 (health) — 채용 사이트 Life 페이지 · 채용 공고 ──
  (@comp_id, 'health_check', '종합검진 추가 검진 지원', NULL, 'health',
   'est', NULL, TRUE, '종합검진 시 제휴병원 추가 검진 지원 (공식 채용 사이트 Life 페이지 WELFARE 항목), 개인종합검진 지원 (채용 공고 복리후생 항목) — 검진 주기·비용 지원 범위 미기재', 40),
  (@comp_id, 'medical', '본인·가족 의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '본인 및 배우자/자녀/부모 의료비 지원 (공식 채용 사이트 Life 페이지 WELFARE 항목), 가족 의료비 지원 (채용 공고 복리후생 항목) — 지원 한도·지원 비율 미기재', 41),
  -- ── 가족 (family) — 채용 사이트 Life 페이지 · 채용 공고 ──
  (@comp_id, 'child_edu', '유치원비 · 유/초/중/고 교육비 지원', NULL, 'family',
   'est', NULL, TRUE, '유치원비 지원 (공식 채용 사이트 Life 페이지 WELFARE 항목), 유/초/중/고 교육비 지원 (채용 공고 복리후생 항목) — 지원 금액·지원 대상 인원 미기재', 50),
  (@comp_id, 'event', '경조 지원 (경조휴가·경조금·화환·경조물품)', NULL, 'family',
   'est', NULL, TRUE, '경조휴가, 경조금, 화환, 경조물품 지원 (공식 채용 사이트 Life 페이지 WELFARE 항목), 경조 지원(휴가, 화환, 경조금) (채용 공고 복리후생 항목) — 경조금 금액·휴가 일수 미기재', 51),
  (@comp_id, 'parenting', '어린이집 위탁보육 지원', NULL, 'family',
   'est', NULL, TRUE, '어린이집 위탁보육 지원 (채용 공고 복리후생 가족을 생각해요 항목) — 지원 금액·대상 연령 미기재', 52),
  -- ── 휴가 (time_off) — 채용 사이트 Life 페이지 ──
  (@comp_id, 'long_service_leave', '근속 Refresh 휴가·휴가비', NULL, 'time_off',
   'est', NULL, TRUE, '5년, 10년 근속 시 Refresh 휴가와 휴가비 지급 (공식 채용 사이트 Life 페이지 WELFARE 항목) — 휴가 일수·휴가비 금액 미기재', 60),
  -- ── 보상 (compensation) — 채용 사이트 Life 페이지 · 채용 공고 ──
  (@comp_id, 'holiday_gift', '설·추석 선물', NULL, 'compensation',
   'est', NULL, TRUE, '설/추석 선물 제공 (공식 채용 사이트 Life 페이지 WELFARE 항목) — 선물 품목·금액 미기재', 70),
  (@comp_id, 'long_service_bonus', '장기근속포상', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속포상 (채용 공고 복리후생 우리도 누려요 항목) — 근속 기준·포상 내용 미기재', 71),
  -- ── 근무 유연성 (flexibility) — 2026 반기보고서 ──
  (@comp_id, 'flex_work', '시차출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '시차출퇴근제 사용자 수 382명 (2026 반기보고서 유연근무제도 사용현황 항목, 제12기 반기 기준) — 대상 직무·사용 조건 미기재', 80),
  (@comp_id, 'remote_work', '원격근무제(재택근무 포함)', NULL, 'flexibility',
   'est', NULL, TRUE, '원격근무제(재택근무 포함) 사용자 수 22명 (2026 반기보고서 유연근무제도 사용현황 항목, 제12기 반기 기준) — 대상 직무·사용 조건 미기재', 81),
  -- ── 근무 환경 (work_env) — 채용 사이트 지하2층 사내 공간 소개 페이지 ──
  (@comp_id, 'lounge', '라운지 (지하 2층 사내 공간)', NULL, 'work_env',
   'est', NULL, TRUE, '업무 중 재충전은 물론, 동료들과 가볍게 소통하며 일상의 활력을 더할 수 있는 라운지를 조성 (공식 채용 사이트 지하2층 사내 공간 소개 페이지 잠시 쉬어가는 공간 항목) — 이용 시간·편의 시설 미기재', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
