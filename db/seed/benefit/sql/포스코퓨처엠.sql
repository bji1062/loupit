-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 포스코퓨처엠 복리후생 데이터 (신규 회사)
-- 출처: AI 파싱 (2026-09-14)
-- URL: https://www.poscofuturem.com/recruitment/personnel.do
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고: 근거는 전부 법인 자기 도메인 poscofuturem.com 의 인재채용 > 인사제도 페이지 한 곳이다.
--       서버렌더 HTML(JSP .do) 이라 헤드리스 브라우저 불필요. 원본 HTML 에 항목이 전부 텍스트로 있다.
--       한 페이지에 인사제도 → 교육제도 → 복리후생 세 블록이 차례로 있고 복리후생 블록이 정본이다.
--       페이지 리드 「포스코퓨처엠의 인사제도, 교육제도, 복리후생에 대해 소개합니다」, 본문 주어도
--       포스코퓨처엠이고 계열사·상이 면책 0건 → 법인 항목이다. 그룹 통합 채용 각주는 붙이지 않았다.
--       ⚠ 복리후생 블록의 h3 는 인사제도 블록 문구를 복사한 오기다(복리후생 제목 검색 0건).
--         앵커는 세 번째 h3 이후 h4 3개. 한 대분류가 형제 컨테이너 2개로 나뉘어 있어
--         h4 다음 div 하나만 읽으면 24개로 준다 — 38항목 전부 읽었다.
--       ⚠ 첫 대분류명(가족 출산친화제도)의 가운데 점은 U+00B7 가 아니라 U+119E(한글 아래아)다. 사용자 노출 필드에는
--         대분류명을 쓰지 않고 소분류명(결혼·임신·출산·육아·가족 등)만 적었다.
--       ⚠ 첫 TLS 연결이 리셋될 수 있다(curl exit 35, 이번에도 1회) — 재시도하면 된다.
--         없는 경로는 HTTP 200 soft-404(1,083B, 제목 에러페이지) — 상태코드로 판정 불가.
--       ⚠ 그룹 채용사이트 recruit.posco.com 은 robots 전면 차단이라 요청하지 않았다.
--       그룹 시설 이름이 붙은 4항목(포스코 센터 작은 결혼식·포스코그룹 공동운영 어린이집·
--         포스코 새마을 금고·포스코그룹 사내수련원)은 면책 없이 이 법인 페이지에 있어
--         이 법인 항목으로 두고 문안은 원문 그대로 적었다.
--       복리후생 38항목 → 법정 제도 5항목 통째 제외(임신기 근로시간 단축·출산 전후 휴가와 유산 사산 휴가·
--         배우자 출산휴가·육아기 근로시간 단축·가족돌봄 단축 휴직 휴가) → 33항목 사용
--         (난임 휴가·육아휴직 법정 1년은 같은 라벨 안에서 문구만 뺐다) → 같은 코드 병합(16항목 → 6행)·
--         복합 라벨 분해(근속휴가/포상금 1항목 → 2행)·1:1(16항목 → 16행) → 24행.
--         여기에 인사제도 블록의 성장지원제도(대학원·MBA·지역전문가 유학 프로그램)를
--         학위 파견형 mba 1행으로 더해 **25행**. 성과급·초과이익 배분·직무발명보상·
--         교육제도 커리큘럼은 제외(사유는 evidence).
--       신규 코드 1개: disability_family_support(장애인 가족 지원금) — 어휘 86종에 대응 없음.
--       금액: 페이지 전체에 원 단위 금액 0건 → 25행 전부 BENEFIT_AMT NULL · QUAL_YN TRUE.
--       SORT 섹션 순서는 이 페이지에서 카테고리가 처음 나온 순서다
--         (growth 10 · family 20 · flexibility 30 · health 40 · perks 50 · leisure 60 ·
--          time_off 70 · compensation 80). growth 가 맨 앞인 것은 성장지원제도가 첫 블록에 있어서다.
--       인증서 만료 2026-11-07 — 그 뒤 재수집 시 TLS 검증 실패 여부를 다시 확인할 것.
--       ⚠ 검증·감사 판정 반영(2026-09-15): 행 수 25 그대로. SORT 22 에서 본인 태아 검진 휴가(법정)를 빼고
--       배우자 태아 검진 휴가만 남겼다. 신규 코드 disability_family_support 는 채택.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ⚠ 법정 제도 문구 정리(2026-09-20): SORT 70 문안 교체 — 법정 제도 서술을 걷고 회사 상회분만 남겼다. 행 수 변동 없음.

-- ⚠ 데이터 정리 2차(2026-09-21): SORT 71·80 문안 교체. db/migrations/20260921_data_cleanup_2.sql 동봉.
-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('posco_futurem', '포스코퓨처엠',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '배터리소재', 'P', 'https://www.poscofuturem.com/recruitment/personnel.do');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'posco_futurem');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (구본이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.poscofuturem.com/recruitment/personnel.do'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 성장·커리어 (growth) — 인사제도 블록 성장지원제도 + 복리후생 블록 자기개발 ──
  (@comp_id, 'mba', '직원 유학 프로그램(대학원·MBA)', NULL, 'growth',
   'est', NULL, TRUE, '포스텍 철강·에너지소재대학원, 에너지소재 최우수 대학원(UNIST, DGIST, 한양대, 전남대), A.I/Smart Factory 석사과정, 글로벌 지역 전문가 과정(중국/인니/미주), 국내 MBA(경영일반, 금융, ESG 등), 포스코기술대학 배터리/에너지 전문과정(전문학사) 등 직원 유학 프로그램 운영 (공식 인사제도 페이지 성장지원제도 항목 — 선발 기준·인원, 학비 지원 범위, 의무 근무 조건 미기재)', 10),
  (@comp_id, 'self_development', '전문자격증 취득 축하금', NULL, 'growth',
   'est', NULL, TRUE, '전문자격증 취득 축하금 지원 (공식 인사제도 페이지 복리후생 자기개발 항목 — 대상 자격증·축하금 액수 미기재)', 11),
  (@comp_id, 'lang', '어학학습·사내어학검정 지원', NULL, 'growth',
   'est', NULL, TRUE, '대면/비대면 어학학습 지원, 사내어학검정 지원 (공식 인사제도 페이지 복리후생 자기개발 항목 — 지원 방식·비용 한도 미기재)', 12),

  -- ── 가족·돌봄 (family) — 복리후생 블록 결혼·임신·출산·육아·가족 ──
  (@comp_id, 'event', '경조사 지원·작은 결혼식', NULL, 'family',
   'est', NULL, TRUE, '포스코 센터 작은 결혼식, 결혼 경조지원, 신혼여행 지원금, 가족 경조사 지원 (공식 인사제도 페이지 복리후생 결혼·가족 항목 — 경조금·신혼여행 지원금 액수, 경조휴가 일수, 결혼식장 이용 조건 미기재)', 20),
  (@comp_id, 'fertility_support', '난임 치료 시술비', NULL, 'family',
   'est', NULL, TRUE, '난임 치료 시술비 (공식 인사제도 페이지 복리후생 임신 항목 — 지원 한도·횟수 미기재)', 21),
  (@comp_id, 'parenting', '임신·출산·육아 지원', NULL, 'family',
   'est', NULL, TRUE, '배우자 태아 검진 휴가, 출산 장려금, 아기 첫만남 선물, 육아휴직 자녀당 최대 2년 중 회사지원 추가 1년 (공식 인사제도 페이지 복리후생 임신·출산·육아 항목 — 검진 휴가 일수, 장려금 액수, 선물 내용 미기재)', 22),
  (@comp_id, 'childcare', '사내어린이집', NULL, 'family',
   'est', NULL, TRUE, '사내어린이집 운영 (자체운영+포스코그룹 공동운영) (공식 인사제도 페이지 복리후생 육아 항목 — 정원·대상 연령·사업장 미기재)', 23),
  (@comp_id, 'disability_family_support', '장애인 가족 지원금', NULL, 'family',
   'est', NULL, TRUE, '장애인 가족 지원금 (공식 인사제도 페이지 복리후생 가족 항목 — 대상 가족 범위·지원 금액·지급 주기 미기재)', 24),
  (@comp_id, 'child_edu', '자녀학자금', NULL, 'family',
   'est', NULL, TRUE, '자녀학자금 지원 (미취학자녀 ~ 대학교) (공식 인사제도 페이지 복리후생 가족 항목 — 지원 한도·자녀 수 제한 미기재)', 25),

  -- ── 근무 유연성 (flexibility) — 복리후생 블록 육아 ──
  (@comp_id, 'remote_work', '육아기 재택근무', NULL, 'flexibility',
   'est', NULL, TRUE, '육아기 재택근무 (육아휴직 外 최대 2년 육아기 재택근무 가능) (공식 인사제도 페이지 복리후생 육아 항목 — 대상 자녀 연령·주당 재택 일수 미기재)', 30),

  -- ── 건강·의료 (health) — 복리후생 블록 건강 ──
  (@comp_id, 'medical', '의료비·상병휴직 급여·진료예약 대행', NULL, 'health',
   'est', NULL, TRUE, '상급종합병원 진료예약 대행 서비스 : 임직원 및 직계가족 대상 『건강상담』 및 『상급병원 진료예약』 대행, 의료비 및 상병휴직 급여 지급 (공식 인사제도 페이지 복리후생 건강 항목 — 의료비 지원 한도, 상병휴직 급여 수준·기간 미기재)', 40),
  (@comp_id, 'mental', '심리상담 지원', NULL, 'health',
   'est', NULL, TRUE, '심리상담 지원 프로그램 : 임직원 대상 대면/비대면 심리상담 지원 (공식 인사제도 페이지 복리후생 건강 항목 — 상담 횟수·운영 기관 미기재)', 41),
  (@comp_id, 'health_check', '종합건강검진', NULL, 'health',
   'est', NULL, TRUE, '종합건강검진 지원 (본인, 가족) (공식 인사제도 페이지 복리후생 건강 항목 — 검진 주기·가족 범위·검진 금액 미기재)', 42),
  (@comp_id, 'insurance', '단체상해보험', NULL, 'health',
   'est', NULL, TRUE, '단체상해보험 지원 (본인, 가족) (공식 인사제도 페이지 복리후생 건강 항목 — 보장 범위·보험료 미기재)', 43),
  (@comp_id, 'fitness', '사내 피트니스 센터', NULL, 'health',
   'est', NULL, TRUE, '사내 피트니스 센터 운영 (공식 인사제도 페이지 복리후생 건강 항목 — 사업장·이용 조건 미기재)', 44),

  -- ── 경제적 부가혜택 (perks) — 복리후생 블록 생활안정·여가생활 ──
  (@comp_id, 'housing_support', '숙소지원금', NULL, 'perks',
   'est', NULL, TRUE, '숙소지원금 (신규입사자, 전근자) *서울근무 신규입사자 제외 (공식 인사제도 페이지 복리후생 생활안정 항목 — 지원 금액·지원 기간 미기재)', 50),
  (@comp_id, 'housing_loan', '생활안정·주택자금 대부', NULL, 'perks',
   'est', NULL, TRUE, '생활안정자금/주택자금 대부, 포스코 새마을 금고 대출 및 예/적금 지원 (공식 인사제도 페이지 복리후생 생활안정 항목 — 대부 한도·이율·자격 요건 미기재)', 51),
  (@comp_id, 'welfare_point', '현금성 복지포인트', NULL, 'perks',
   'est', NULL, TRUE, '현금성 복지포인트 지급 (공식 인사제도 페이지 복리후생 여가생활 항목 — 연간 포인트 금액 미기재)', 52),
  (@comp_id, 'birthday_gift', '기념일 영화티켓', NULL, 'perks',
   'est', NULL, TRUE, '본인 기념일 영화티켓 지원(생일, 결혼기념일) (공식 인사제도 페이지 복리후생 여가생활 항목 — 지급 매수 미기재)', 53),
  (@comp_id, 'discount', '제휴 할인', NULL, 'perks',
   'est', NULL, TRUE, '호텔, 영화관, 병원 등 제휴 할인 (공식 인사제도 페이지 복리후생 여가생활 항목 — 제휴처 목록·할인율 미기재)', 54),

  -- ── 여가·라이프 (leisure) — 복리후생 블록 여가생활 ──
  (@comp_id, 'club', '사내동호회', NULL, 'leisure',
   'est', NULL, TRUE, '사내동호회 지원 (1인 2개까지 가입 가능, 활동비 지원) (공식 인사제도 페이지 복리후생 여가생활 항목 — 활동비 한도 미기재)', 60),
  (@comp_id, 'resort', '휴양시설', NULL, 'leisure',
   'est', NULL, TRUE, '휴양시설 운영 (법인콘도, 포스코그룹 사내수련원) (공식 인사제도 페이지 복리후생 여가생활 항목 — 이용 한도·본인 부담 미기재)', 61),

  -- ── 휴가 (time_off) — 복리후생 블록 휴가제도 ──
  (@comp_id, 'leave_general', '권장휴가·저축휴가·연차 조기사용', NULL, 'time_off',
   'est', NULL, TRUE, '권장휴가와 저축휴가 제도, 4시간 이내 시간 단위 휴가 사용, 연차 조기사용 제도 운영 (공식 인사제도 페이지 복리후생 휴가제도 항목 — 권장휴가 일수·저축 한도 미기재)', 70),
  (@comp_id, 'long_service_leave', '근속휴가', NULL, 'time_off',
   'est', NULL, TRUE, '장기근속자를 위한 근속휴가 (공식 인사제도 페이지 복리후생 휴가제도 항목 — 근속 연수 기준·휴가 일수 미기재)', 71),

  -- ── 보상·금전 (compensation) — 복리후생 블록 휴가제도 ──
  (@comp_id, 'long_service_bonus', '장기근속 포상금', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속자를 위한 포상금 지급 (공식 인사제도 페이지 복리후생 휴가제도 항목 — 근속 연수 기준·포상금 액수 미기재)', 80)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
