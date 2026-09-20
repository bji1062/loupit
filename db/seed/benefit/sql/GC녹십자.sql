-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- GC녹십자 복리후생 데이터 (신규 회사)
-- 출처: AI 파싱 (2026-09-19)
-- URL: https://recruit.gccorp.com/kor/culture/benefits/gc-biopharma
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
--
-- 참고:
--   정본은 GC 그룹 채용사이트 recruit.gccorp.com 의 **GC녹십자 법인 전용 복리후생 탭**이다.
--   22항목 4카테고리가 서버렌더 HTML 의 ol.description-list 안에 텍스트로 있다(헤드리스 불필요).
--   보조 정본은 같은 사이트의 GC녹십자 인사제도 탭 /kor/culture/hr/gc-biopharma 다 —
--   거점오피스·PC-OFF·보상 휴가제·사외 석박사 학위과정이 여기서만 나온다.
--
--   ⚠ 가장 큰 함정: recruit.gccorp.com 은 GC녹십자 도메인이 아니라 지주
--     (주)녹십자홀딩스(KOSPI 005250, 사업자등록번호 135-81-05009) 도메인이다.
--     푸터 운영 주체가 전 페이지 공통으로 (주)녹십자홀딩스이고, GC녹십자 법인은
--     303-81-17108 로 별개다. 같은 사이트의 /kor/culture/benefits/gc 는 **지주 복지 25항목**이라
--     슬러그 한 토막(gc 대 gc-biopharma) 차이로 다른 법인 복지가 붙는다.
--   ⚠ 법인 식별을 title 로 하면 안 된다 — 16개 가족사 탭의 title 이 전부
--     GC녹십자그룹 채용사이트로 같다. 이번 수집은 응답마다 두 값을 확인했다:
--       (1) main 클래스에 benefits-gc-biopharma-main 포함
--       (2) h2.company-title 텍스트가 GC녹십자
--     가족사 탭 a.family-company-item.active 도 GC녹십자로 일치한다.
--   ⚠ 자기 도메인 www.gcbiopharma.com 에는 복지 페이지가 없다(사이트맵 24 URL 중 채용 0건,
--     홈의 유일한 채용 링크가 recruit.gccorp.com 으로 나간다). 삼성화재형 출처 구조다.
--   ⚠ 변경 감지 해시를 페이지 전체로 뜨면 매번 오탐이다 — 응답마다 meta name=_csrf 값이 바뀐다.
--     2회 요청 실측: 전체 해시는 달랐고 ol.description-list 구간 해시는 동일했다.
--     ol.description-list sha256 = 12dcdbf136899729a10768069d6a53d0d1dfeb6d5af9d588089f2526f27e2772
--
--   그룹 공통 각주 미부착: 형제 탭과 대조한 결과 법인별로 따로 쓴 블록이다
--     (지주 gc 25항목 라벨형 · GC셀 18항목 라벨형 · GC녹십자 22항목 서술문형으로
--      항목 수·문구·마크업이 전부 다르다). 페이지에 계열사별 상이 면책도 없고
--      상단 안내문이 가족사별 분리를 직접 선언한다. 삼성화재 방식과 같다.
--   기등록 형제 0건: 리포 138개 시드에 GC 계열 파일이 없다.
--
--   원문 22항목 → 재코딩. 항목이 라벨이 아니라 수식어가 붙은 서술문이라
--     제도명을 뽑아내야 했다(예 매일 새로운 생각을 불러일으키는 Creative한 회의실 및 사무실).
--     한 p 안에 제도 2개인 항목 2건을 분할(+2):
--       사내 카페, 남성/여성 휴게실 → snack_bar + lounge
--       출퇴근 셔틀버스 및 전 직원 무상 주차 → commute_subsidy + parking
--     같은 코드로 귀결돼 병합한 항목 1건(-1): 배우자 포함 건강검진 + 백신접종 지원 → health_check
--       (SK바이오팜·셀트리온·현대모비스 선례대로 예방접종은 health_check).
--     → 정본 23행 + 보조 정본 3행(거점오피스·PC-OFF·사외 석박사) = **26행**.
--     보상 휴가제는 leave_general 이 회사당 UNIQUE 라 휴직/병가 행에 합쳤다.
--   신규 코드 0. 26행 전부 기존 어휘 87종 안에서 해결했다.
--
--   금액: 원문에 원 단위 금액이 0건이다. 정량 표현은 기간·빈도뿐이고
--     (연 2회 · 1주일 간 · 매월) 금액이 아니다 → 26행 전부 BENEFIT_AMT NULL · QUAL_YN TRUE.
--     신규 회사라 승계할 앵커도 없다.
--   영문판 보조: /eng/culture/benefits/gc-biopharma 가 사내 식당에
--     lunch/dinner provided, free 를 명시한다(국문에는 없는 조건). meal 행 서술에 반영했다.
--     ⚠ 개수 검증은 영문으로 하면 안 된다 — 첫 카테고리 6항목이 한 문단으로 합쳐져 17개로 세진다.
--
--   법정 제도 미수록: 4대보험·퇴직연금·연차·육아휴직류는 두 페이지에 아예 없다.
--     인사제도 페이지의 시차출퇴근제·선택적근로시간제는 리드 지시로 제외했다.
--     ⚠ 다만 이 둘은 근로기준법이 강제하는 제도가 아니라 사용자가 도입을 선택하는 제도이고,
--       generator/data/legal_baseline.json 의 법정 15항목에도 flex_work 가 없으며
--       코퍼스 64개사가 flex_work 행을 갖고 있다(어휘표 대표 명칭에 선택적 근로시간제가 있다).
--       근거표 「판단이 갈리는 곳」 절에 즉시 투입 가능한 flex_work 행을 적어 두었다.
--   제외: 자율복장제도(원익IPS·삼성ENA 반증 선례) · 목표성과급/경영성과급/기타인센티브
--     (임금 체계 서술) · 절대평가/다면평가 · 님 호칭 · 역할 중심 직급제도 · 직무순환 ·
--     온오프라인 학습지원(회사 주도 교육) · 교육 페이지 전체(온보딩·리더십 Journey·CoP·어학 교육).
--       ⚠ 검증·감사 판정 반영(2026-09-19): 26 → 25행(삭제 1 · 병합 1 · 추가 1). SORT 10 smart_office(회의실·사무실)
--       삭제 · SORT 23 복지몰(discount)을 SORT 24 welfare_point 에 병합 · SORT 50 refresh_leave → summer_leave
--       재코딩 · SORT 52 에서 보상 휴가제 구절 삭제 · SORT 80 flex_work 복원(기존 80·81 을 81·82 로 밀었다).
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('gc_biopharma', 'GC녹십자',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '제약', 'G', 'https://recruit.gccorp.com/kor/culture/benefits/gc-biopharma');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'gc_biopharma');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://recruit.gccorp.com/kor/culture/benefits/gc-biopharma'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무 환경 (work_env) ──
  (@comp_id, 'lounge', '남성/여성 휴게실', NULL, 'work_env',
   'est', NULL, TRUE, '잠깐의 휴식을 위한 남성·여성 휴게실 운영 (공식 채용사이트 GC녹십자 복리후생 페이지 근무환경 항목 — 설치 사업장·이용 시간 미기재)', 11),
  (@comp_id, 'parking', '전 직원 무상 주차', NULL, 'work_env',
   'est', NULL, TRUE, '전 직원 대상 무상 주차 제공 (공식 채용사이트 GC녹십자 복리후생 페이지 근무환경 항목 — 주차 가능 사업장·주차 대수 미기재)', 12),

  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'snack_bar', '사내 카페', NULL, 'perks',
   'est', NULL, TRUE, '잠깐의 휴식을 위한 사내 카페 운영 (공식 채용사이트 GC녹십자 복리후생 페이지 근무환경 항목 — 이용료 부담 여부·운영 사업장 미기재)', 20),
  (@comp_id, 'commute_subsidy', '출퇴근 셔틀버스', NULL, 'perks',
   'est', NULL, TRUE, '편리한 출퇴근을 위한 출퇴근 셔틀버스 운행 (공식 채용사이트 GC녹십자 복리후생 페이지 근무환경 항목 — 노선·운행 지역·이용료 미기재)', 21),
  (@comp_id, 'meal', '사내 식당', NULL, 'perks',
   'est', NULL, TRUE, '건강한 식습관을 위한 사내 식당 운영, 공식 채용사이트 GC녹십자 영문 복리후생 페이지는 중식·석식 무료 제공으로 명시 (국문 페이지에는 무료 여부·식대 단가 미기재)', 22),
  (@comp_id, 'welfare_point', '복지포인트', NULL, 'perks',
   'est', NULL, TRUE, '개인의 기호에 맞게 Self-선물을 하는 복지포인트를 명절·근로자의날·창립기념일에 지급, GC녹십자 및 가족사 건강 상품 구매용 복지몰 운영 (공식 채용사이트 GC녹십자 복리후생 페이지 GC Life 항목 — 연간 포인트 금액·사용처·복지몰 가격 조건 미기재)', 24),
  (@comp_id, 'housing_loan', '사내 대출 제도', NULL, 'perks',
   'est', NULL, TRUE, '내 집 마련에 도움을 주는 사내 대출 제도 운영 (공식 채용사이트 GC녹십자 복리후생 페이지 GC Life 항목 — 대출 한도·이율·상환 조건 미기재)', 25),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'childcare', '직장어린이집', NULL, 'family',
   'est', NULL, TRUE, '아이와 함께 출근하고 퇴근하는 직장어린이집 운영 (공식 채용사이트 GC녹십자 복리후생 페이지 근무환경 항목 — 정원·대상 연령·운영 사업장 미기재)', 30),
  (@comp_id, 'event', '경조휴가·경조지원', NULL, 'family',
   'est', NULL, TRUE, '직원의 생애주기에 맞는 경조휴가제도를 운영하고 경조지원을 포함 (공식 채용사이트 GC녹십자 복리후생 페이지 휴식 항목 — 경조금 액수·경조휴가 일수 미기재)', 31),
  (@comp_id, 'child_edu', '자녀 학자금 지원제도', NULL, 'family',
   'est', NULL, TRUE, '학비 부담을 덜어주는 자녀 학자금 지원제도 운영 (공식 채용사이트 GC녹십자 복리후생 페이지 GC Life 항목 — 지원 한도·대상 학교급·자녀 수 제한 미기재)', 32),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'fitness', '피트니스센터', NULL, 'health',
   'est', NULL, TRUE, '집으로 돌아가기 전 건강을 챙길 수 있는 피트니스센터 운영 (공식 채용사이트 GC녹십자 복리후생 페이지 근무환경 항목 — 이용료·운영 사업장·이용 시간 미기재)', 40),
  (@comp_id, 'clinic', '전문의 상주 사내 병원', NULL, 'health',
   'est', NULL, TRUE, '전문의가 상주하는 사내 병원 운영 (공식 채용사이트 GC녹십자 복리후생 페이지 근무환경 항목 — 진료 과목·이용 대상·진료비 부담 미기재)', 41),
  (@comp_id, 'insurance', '단체 상해보험', NULL, 'health',
   'est', NULL, TRUE, '개인의 건강을 위한 단체 상해보험 가입 (공식 채용사이트 GC녹십자 복리후생 페이지 건강 항목 — 보장 범위·보장 한도·보험료 부담 미기재)', 42),
  (@comp_id, 'health_check', '건강검진(배우자 포함)·백신접종', NULL, 'health',
   'est', NULL, TRUE, '건강한 가정을 위해 배우자를 포함한 건강검진 지원, 질병 예방을 위한 백신접종 지원 (공식 채용사이트 GC녹십자 복리후생 페이지 건강 항목 — 검진 주기·검진 비용·접종 백신 종류 미기재)', 43),
  (@comp_id, 'mental', '심리상담 프로그램(EAP)', NULL, 'health',
   'est', NULL, TRUE, '스트레스 관리를 위한 심리상담 프로그램 지원(EAP) (공식 채용사이트 GC녹십자 복리후생 페이지 건강 항목 — 상담 횟수·가족 포함 여부·비용 부담 미기재)', 44),

  -- ── 휴가 (time_off) ──
  (@comp_id, 'summer_leave', '하계·동계 장기휴가(연 2회, 각 1주)', NULL, 'time_off',
   'est', NULL, TRUE, '충분한 휴식을 위해 여름과 겨울 연 2회, 각 1주일 간 장기 휴가 부여 (공식 채용사이트 GC녹십자 복리후생 페이지 휴식 항목 — 사용 시기 지정 여부·부여 대상 미기재)', 50),
  (@comp_id, 'long_service_leave', 'Amazing Holiday(장기근속 휴가)', NULL, 'time_off',
   'est', NULL, TRUE, '장기 근속자에 대한 Amazing Holiday 부여 (공식 채용사이트 GC녹십자 복리후생 페이지 휴식 항목 — 기준 근속 연차·휴가 일수 미기재)', 51),
  (@comp_id, 'leave_general', '휴직·병가 제도', NULL, 'time_off',
   'est', NULL, TRUE, '가정 내 어려움을 지원하는 휴직·병가 제도 운영 (공식 채용사이트 GC녹십자 복리후생 페이지 휴식 항목 — 휴직 사유·기간·급여 보전 여부 미기재)', 52),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'resort', '콘도·리조트 회원가 이용', NULL, 'leisure',
   'est', NULL, TRUE, '휴가를 즐겁게 보낼 수 있는 콘도 및 리조트 회원가 이용 (공식 채용사이트 GC녹십자 복리후생 페이지 휴식 항목 — 제휴처 목록·이용 한도·본인 부담 미기재)', 60),
  (@comp_id, 'club', '사내 동호회', NULL, 'leisure',
   'est', NULL, TRUE, '다양한 취미활동을 지원하는 사내 동호회 운영 (공식 채용사이트 GC녹십자 복리후생 페이지 GC Life 항목 — 활동비 지원 한도·동호회 수 미기재)', 61),

  -- ── 성장·커리어 (growth) ──
  (@comp_id, 'books', '사내 도서관', NULL, 'growth',
   'est', NULL, TRUE, '매월 신규 도서가 추가되는 사내 도서관 운영 (공식 채용사이트 GC녹십자 복리후생 페이지 GC Life 항목 — 장서 규모·대출 조건·운영 사업장 미기재)', 70),
  (@comp_id, 'mba', '사외 석박사 학위과정 지원', NULL, 'growth',
   'est', NULL, TRUE, '사외 석박사 학위과정 지원 (공식 채용사이트 GC녹십자 인사제도 페이지 성장 항목 — 선발 인원·지원 금액·의무 복무 조건 미기재)', 71),

  -- ── 근무 유연성 (flexibility) ──
  (@comp_id, 'flex_work', '시차출퇴근제·선택적근로시간제', NULL, 'flexibility',
   'est', NULL, TRUE, '보다 집중적으로 일하기 위한 시차출퇴근제와 선택적근로시간제 운영 (공식 채용사이트 GC녹십자 인사제도 페이지 근무 제도 항목 — 코어타임·정산 기간·신청 절차 미기재)', 80),
  (@comp_id, 'satellite_office', '거점오피스 제도', NULL, 'flexibility',
   'est', NULL, TRUE, '보다 집중적으로 일하기 위한 거점오피스 제도 운영 (공식 채용사이트 GC녹십자 인사제도 페이지 근무 제도 항목 — 거점 위치·이용 자격·이용 일수 미기재)', 81),
  (@comp_id, 'pc_off', 'PC-OFF 제도', NULL, 'flexibility',
   'est', NULL, TRUE, '근무시간이 종료되는 시점에 PC 화면이 꺼지는 PC-OFF 제도 운영 (공식 채용사이트 GC녹십자 인사제도 페이지 근무 제도 항목 — 예외 승인 절차·적용 대상 미기재)', 82)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
