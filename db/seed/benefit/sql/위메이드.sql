-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 위메이드 복리후생 데이터
-- 출처: AI 파싱 (2026-10-01)
-- URL: https://www.wemade.com/kr/workwithus/joinourteam
-- badge: est
--
-- 참고:
--   정본은 위메이드 공식 홈페이지(wemade.com · 꼬리말 WEMADE Co., Ltd.) 헤더 메뉴 Work with Us 의 JOIN OUR TEAM 탭이다.
--   이 탭은 workwithus 의 선택 경로 /kr/workwithus/joinourteam 으로 서버가 바로 그려 준다(SSR) — Benefits 절 6항목이 서버 응답 HTML 본문에 있다.
--   robots: www.wemade.com/robots.txt 는 Allow / 하나 — 전 경로 허용.
--   보조: 같은 탭의 영문판 /workwithus/joinourteam(같은 6항목의 영문 문장 — 서술 대조용).
--   귀속: 회사 자기 도메인의 위메이드 법인 페이지다. 계열사(위메이드맥스 · 위메이드플레이 · 매드엔진 등)는 꼬리말 Family Site 의 별도 사이트라 보지 않았다.
--   제외: 체계적인 학습 및 성장 기회(교육 및 트레이닝 프로그램 — 회사 주도 교육 과정).
--   금액: 식사 포인트 월 28만은 연 336 으로 환산(추정치) · 복지포인트 연 200만은 원문 연액 그대로.
--   구본 폐기: 구본 17행은 다른 법인(위메이드플레이) 데이터였다 — 전부 버리고 위메이드 공식 원문으로 다시 세웠다. 추정치 승계 없음.
--   SORT 섹션 순서 = 정본 Benefits 절에서 카테고리가 처음 나온 순서
--     (health 10 · work_env 20 · perks 30 · family 40 · time_off 50).
-- 재수집(2026-10-01): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-01, RV-3-3): 수집 11행 원문 확인 · 공식 홈 ESG 보고서 메뉴의 위메이드 지속가능경영보고서 2025(국문 PDF p.56 복리후생제도 운영 현황)로 8행 서술 보강 · resort · conference · holiday_gift · long_service_bonus 4행 추가 · leave_general 이름을 홈데이로 · 보고서 전체 판독(p.52~58 · 66 · 75)으로 5행 서술 보강 · flex_work · club · transport 3행 추가 — 최종 18행
-- 코퍼스 정리(2026-10-11 · 수면실 휴게실 경계): 수면실·샤워실 lounge 재코딩 · 수유실 nap_room 새 행 1 — 최종 19행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('wemade', '위메이드',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '게임', 'W', 'https://www.wemade.com/kr/workwithus/joinourteam');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'wemade');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://www.wemade.com/kr/workwithus/joinourteam'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 건강·의료 (health) — Benefits 사내 편의 시설 · 종합 건강 복지 항목 ──
  (@comp_id, 'fitness', '피트니스 센터', NULL, 'health',
   'est', NULL, TRUE, '피트니스 센터, 수면실, 샤워실 등 다양한 편의 시설 제공 중 피트니스 센터 (공식 홈페이지 JOIN OUR TEAM Benefits 사내 편의 시설 항목), 사옥 내 스포츠센터(헬스, 골프연습장 등) 이용 금액 지원 (위메이드 지속가능경영보고서 2025 복리후생제도 운영 현황), 580평 규모·최신 운동 기구 100여 종을 갖춘 스포츠센터 이용 지원 (같은 보고서 안전보건 임직원 건강증진 항목) — 지원 금액·운영 시간 미기재', 10),
  (@comp_id, 'insurance', '본인 및 가족 단체상해보험', NULL, 'health',
   'est', NULL, TRUE, '본인 및 가족 단체상해보험 (공식 홈페이지 JOIN OUR TEAM Benefits 종합 건강 복지 항목), 배우자, 자녀, 양가 부모 등 가족 대상 단체상해보험 가입 지원 (위메이드 지속가능경영보고서 2025 복리후생제도 운영 현황), 임직원과 가족 모두에게 상해·중증 질환 대비 단체 상해보험 제공 (같은 보고서 안전보건 임직원 건강증진 항목) — 보장 한도·보험료 미기재', 11),
  (@comp_id, 'health_check', '매년 종합건강검진·검진휴가·독감 예방접종', NULL, 'health',
   'est', NULL, TRUE, '매년 종합건강검진과 검진휴가 (공식 홈페이지 JOIN OUR TEAM Benefits 종합 건강 복지 항목), 매년 임직원과 가족 대상 종합건강검진 및 검진일 휴가 지원 (위메이드 지속가능경영보고서 2025 복리후생제도 운영 현황), 본인 생애주기·건강 특성에 맞춰 항목을 고르는 맞춤형 검진·검진 결과에 따른 추가 혈액검사·정기 독감 예방접종 지원 (같은 보고서 안전보건 임직원 건강증진 항목) — 검진 비용·가족 범위 미기재', 12),

  -- ── 근무환경 (work_env) — Benefits 사내 편의 시설 항목 ──
  (@comp_id, 'lounge', '수면실·샤워실', NULL, 'work_env',
   'est', NULL, TRUE, '피트니스 센터, 수면실, 샤워실 등 다양한 편의 시설 제공 중 수면실과 샤워실 (공식 홈페이지 JOIN OUR TEAM Benefits 사내 편의 시설 항목), 사내 수면실·샤워룸 자유 이용 (위메이드 지속가능경영보고서 2025 복리후생제도 운영 현황) — 이용 시간 미기재', 20),
  (@comp_id, 'nap_room', '수유실', NULL, 'work_env',
   'est', NULL, TRUE, '사내 수유실 자유 이용 (위메이드 지속가능경영보고서 2025 복리후생제도 운영 현황) — 설치 위치·이용 시간 미기재', 21),

  -- ── 경제적 부가혜택 (perks) — Benefits 식대 지원 · 생활안정 항목 · 지속가능경영보고서 2025 p.66 ──
  (@comp_id, 'meal', '식사 포인트 월 28만', 336, 'perks',
   'est', '식대 지원 제도 운영, 월 28만 식사 포인트 (공식 홈페이지 JOIN OUR TEAM Benefits 식대 지원 항목) — 월 28만을 연 336만으로 환산', FALSE, NULL, 30),
  (@comp_id, 'snack_bar', '무료 사내 카페 음료', NULL, 'perks',
   'est', NULL, TRUE, '무료 사내 카페 음료 (공식 홈페이지 JOIN OUR TEAM Benefits 식대 지원 항목 — 카페 위치·운영 시간 미기재)', 31),
  (@comp_id, 'welfare_point', '복지포인트 연 200만', 200, 'perks',
   'est', '연 200만 복지포인트 (공식 홈페이지 JOIN OUR TEAM Benefits 생활안정 항목)', FALSE, NULL, 32),
  (@comp_id, 'transport', '야근·긴급 출근 교통비 지원', NULL, 'perks',
   'est', NULL, TRUE, '야근 및 긴급 출근 교통비 지원 규정 제정 (위메이드 지속가능경영보고서 2025 인권경영 노사협의회 개최 현황 2025년 6월 항목) — 지원 금액·대상 시간 기준 미기재', 33),

  -- ── 가족·돌봄 (family) — Benefits 자녀 양육 및 교육 지원 · 생활안정 항목 ──
  (@comp_id, 'child_edu', '자녀 대학 등록금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀 양육 및 교육 지원 중 대학 등록금 지원 (공식 홈페이지 JOIN OUR TEAM Benefits 자녀 양육 및 교육 지원 항목), 자녀 전 학기 대학등록금 실비 지원 (위메이드 지속가능경영보고서 2025 복리후생제도 운영 현황) — 자녀 수 한도 미기재', 40),
  (@comp_id, 'parenting', '보육료·입학 축하금', NULL, 'family',
   'est', NULL, TRUE, '보육료 지원, 유치원·초등·중·고 입학 축하금 등 제공 (공식 홈페이지 JOIN OUR TEAM Benefits 자녀 양육 및 교육 지원 항목), 자녀가 다니는 어린이집 위탁보육료 지원 · 초·중·고 입학 시 최대 200만 원 입학 축하금 (위메이드 지속가능경영보고서 2025 복리후생제도 운영 현황), 법적 의무를 넘어 출산휴가 전체 기간 동안 출산휴가 급여 전액 지원 (같은 보고서 일·가정 양립지원 항목) — 보육료 금액 미기재', 41),
  (@comp_id, 'event', '경조금·경조휴가·상조서비스', NULL, 'family',
   'est', NULL, TRUE, '경조금 및 가족 관련 유급 휴가 지원 (공식 홈페이지 JOIN OUR TEAM Benefits 생활안정 항목), 경조금·경조휴가·상조서비스 등 경조사 지원 (위메이드 지속가능경영보고서 2025 복리후생제도 운영 현황) — 경조금 금액·휴가 일수 미기재', 42),

  -- ── 시간·휴가 (time_off) — Benefits 종합 건강 복지 항목 ──
  (@comp_id, 'leave_general', '홈데이 (설·추석 연휴 전날·마지막 근무일 휴무)', NULL, 'time_off',
   'est', NULL, TRUE, '설/추석 연휴 전날과 마지막 근무일 휴무 (공식 홈페이지 JOIN OUR TEAM Benefits 종합 건강 복지 항목), 홈데이 — 명절(설, 추석)·연말 연휴 추가 휴가 제공 (위메이드 지속가능경영보고서 2025 복리후생제도 운영 현황)', 50),

  -- ── 여가·라이프 (leisure) · 성장 (growth) · 보상 (compensation) — 지속가능경영보고서 2025 p.54 · 56 · 58 ──
  (@comp_id, 'resort', '휴양시설 (리조트 무료·회원가)', NULL, 'leisure',
   'est', NULL, TRUE, '전국 각지의 리조트를 무료 또는 회원가로 이용 (위메이드 지속가능경영보고서 2025 복리후생제도 운영 현황 휴양시설 항목) — 이용 횟수·숙박 일수 미기재', 60),
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 제도 운영 지원(3개 이상 부서, 7명 이상 임직원이 참여하는 동호회) (위메이드 지속가능경영보고서 2025 일과 삶의 균형 사내 동호회 운영 지원 항목) — 지원 금액·지원 내용 미기재', 61),
  (@comp_id, 'conference', '외부 직무교육·세미나 수강 지원', NULL, 'growth',
   'est', NULL, TRUE, '자기계발을 위한 외부 직무교육, 세미나 수강 등 지원 (위메이드 지속가능경영보고서 2025 복리후생제도 운영 현황 직무교육 항목), 외부 교육 희망 시 조직장 승인으로 교육비 지원·교육 시간 근무시간 인정, 외부 콘퍼런스·세미나 초대권 배포, 인턴·파견직·계약직 포함 전 직원 대상 (같은 보고서 인재경영 교육 지원제도 항목) — 지원 한도 미기재', 70),
  (@comp_id, 'holiday_gift', '명절·정기 선물', NULL, 'compensation',
   'est', NULL, TRUE, '주요 명절을 포함해 정기·비정기 선물 증정 (위메이드 지속가능경영보고서 2025 복리후생제도 운영 현황 선물 항목) — 선물 내용·금액 미기재', 80),
  (@comp_id, 'long_service_bonus', '장기근속축하금', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속 임직원 대상 축하금 지급 (위메이드 지속가능경영보고서 2025 복리후생제도 운영 현황 장기근속축하금 항목) — 근속 연수 기준·금액 미기재', 81),

  -- ── 유연근무 (flexibility) — 지속가능경영보고서 2025 p.58 · 74 ──
  (@comp_id, 'flex_work', '유연근무제 (출퇴근 시간 자율 조정)', NULL, 'flexibility',
   'est', NULL, TRUE, '2025년부터 전사 도입한 유연근무제 — 부서별 근무기준 시간대 안에서 임직원이 출퇴근 시간을 자율 조정, 매주 근무 계획 제출, 근태 앱으로 근무 중 개인 용무 시 실시간 근무 중지 후 자율 조정, 1개월 단위 근무시간 정산(주 평균 40시간) (위메이드 지속가능경영보고서 2025 일과 삶의 균형 유연근무제 항목)', 90)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
