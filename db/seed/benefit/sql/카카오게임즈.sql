-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 카카오게임즈 복리후생 데이터
-- 출처: AI 파싱 (2026-10-01)
-- URL: https://recruit.kakaogames.com/ko/benefitskr
-- badge: est
--
-- 참고:
--   정본은 카카오게임즈 자사 채용 사이트(recruit.kakaogames.com, 그리팅 ATS 호스팅 — 기업 사이트
--   www.kakaogamescorp.com 상단 메뉴 채용 → 채용공고 링크)의 Benefits 페이지 카카오게임즈 복지 혜택이다.
--   5섹션 33항목(근무환경 8 · 간식과 음료 4 · 건강하고 안정된 생활 12 · 편안한 휴식과 즐거운 여가 6 · 함께 성장하는 기회 3).
--   본문은 원본 HTML 에 서버 렌더돼 있고 __NEXT_DATA__ 페이지 블록 74개 문자열이
--   전부 화면에 렌더된다(숨은 블록 없음) — 헤드리스 렌더 없음. 페이지 머리말: 오피스에 따라 제공되는 혜택이 다를 수 있음.
--   robots: recruit.kakaogames.com 은 Allow: / (지원서 경로만 Disallow) · www.kakaogamescorp.com robots 404(허용).
--   보조 출처: 기업 사이트 보도자료 2건(2026-02-24 시기별 맞춤 복지 · 2025-11-06 여가친화인증) — 정본 항목을 확인하고
--   임신 · 출산 · 입학 선물 내용을 보탰다. 영문판 benefitsen 은 대조용(행 근거 아님).
--   귀속: 페이지 저작권 Kakao Games Corp. · 기업 사이트 메뉴가 이 ATS 로 연결 · 항목 본문이 카카오게임즈 크루를 주어로 쓴다.
--   카카오 · 카카오뱅크 · 카카오페이 페이지는 근거로 쓰지 않았다. 그룹 통합 기준 문구가 없어 각주 없음.
--   금액: 명시값 2행(welfare_point 연 360 · birthday_gift 5) · 환산 1행(meal 월 20만원 → 240) ·
--     승계 추정치 4행(health_check 100 · insurance 30 · resort 50 · commute_subsidy 120 — NOTE 끝에 (추정)).
--     snack_bar 144 는 승계하지 않았다(회사 고유값, 전제가 원문에 없음). 명절 선물은 설과 추석 30만원 상당이
--     명절별인지 연 합계인지 원문이 밝히지 않아 금액 NULL.
--   구본에서 뺀 행: fitness (공식 원문에 피트니스센터 없음).
--   재코딩: self_development → welfare_point (원문이 복지 포인트 카드).
--   SORT 섹션 순서 = 정본 페이지에서 카테고리가 처음 나온 순서
--     (flexibility 10 · perks 20 · work_env 30 · health 40 · leisure 50 · family 60 · compensation 70).
-- 재수집(2026-10-01): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-01, RV-3-2): commute_subsidy 120 승계 취소(원문이 임직원 할인가 유료 버스 — 틀 값의 무상 운행 전제와 다른 구조) · holiday_gift 서술에서 썸머 패키지 제거 · family_day 에 조기 퇴근 제도 보강 · office_furniture(모션 데스크) · nap_room(수유시설) · incentive(성과급) 3행 추가 — 카카오게임즈 ESG 보고서 2025(kakaogamescorp.com ESG 자료실 PDF p.67·70·71) 확인 — 최종 27행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('kakao_games', '카카오게임즈',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '게임', 'K', 'https://recruit.kakaogames.com/ko/benefitskr');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'kakao_games');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://recruit.kakaogames.com/ko/benefitskr'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무유연성 (flexibility) — 근무환경 ──
  (@comp_id, 'flex_work', '놀금 (격주 주 4일제)·시차출퇴근제', NULL, 'flexibility',
   'est', NULL, TRUE, '격주 금요일에는 모든 크루가 휴무하는 격주 주 4일제 운영(공식 채용 사이트 카카오게임즈 복지 혜택 근무환경 놀금 항목), 생활 패턴과 업무 스타일에 맞춰 9시 출근과 10시 출근 중 선택하는 시차출퇴근제(같은 섹션 시차출퇴근제 항목) — 시차출퇴근제 적용 대상 미기재', 10),
  (@comp_id, 'family_day', '해피 아워 (월요일 늦은 출근·금요일 조기 퇴근)', NULL, 'flexibility',
   'est', NULL, TRUE, '매주 월요일 아침 30분 늦게 출근, 놀금 없는 주 금요일 오후 1시간 30분 일찍 퇴근 (공식 채용 사이트 카카오게임즈 복지 혜택 근무환경 해피 아워 항목 · ESG 보고서 2025 격주 놀금 제도 항목), 명절(설, 추석) 전날과 12월 24일·31일 오후 3시 퇴근 (ESG 보고서 2025 조기 퇴근 제도 항목)', 11),

  -- ── 경제적 부가혜택 (perks) — 근무환경 · 간식과 음료 · 건강하고 안정된 생활 · 여가 · 성장 ──
  (@comp_id, 'meal', '점심 식대 월 20만원·사내식당 춘식도락', 240, 'perks',
   'est', '점심 시간 1시간 30분, 매월 급여 외 20만원의 식대 지원(공식 채용 사이트 카카오게임즈 복지 혜택 근무환경 여유로운 점심 시간과 식대 항목), 사내식당 춘식도락의 한식·양식·분식·샐러드 등 약 8개 메뉴를 임직원 할인가에 제공(같은 페이지 간식과 음료 사내 식당 항목) — 월 20만원을 연 240만원으로 환산', FALSE, NULL, 20),
  (@comp_id, 'commute_subsidy', '통근버스 (서울/경기 15개 노선)', NULL, 'perks',
   'est', NULL, TRUE, '편안한 출퇴근을 위해 서울/경기 15개 노선의 통근버스를 임직원 할인가에 지원 (공식 채용 사이트 카카오게임즈 복지 혜택 근무환경 통근 버스 지원 항목 — 본인 부담 요금 미기재)', 21),
  (@comp_id, 'snack_bar', '스낵바·사내카페 카페 포션', NULL, 'perks',
   'est', NULL, TRUE, '샌드위치·김밥·과일 등 조식과 빵·라면·시리얼·우유·견과류·커피·차 등 간식 무료 제공(공식 채용 사이트 카카오게임즈 복지 혜택 간식과 음료 스낵바 항목), 사내카페 카페 포션의 바리스타 커피와 시즌 음료를 임직원 할인가에 제공(같은 섹션 사내카페 항목) — 설치 오피스 미기재', 22),
  (@comp_id, 'housing_loan', '대출 이자 지원', NULL, 'perks',
   'est', NULL, TRUE, '주택 및 생활 자금에 도움이 되도록 최대 3억원의 대출금에 대해 2.0% 초과분 이자 지원 (공식 채용 사이트 카카오게임즈 복지 혜택 건강하고 안정된 생활 대출 이자 지원 항목 — 연계 금융기관·자격 요건 미기재)', 23),
  (@comp_id, 'birthday_gift', '생일 선물 (신세계 상품권)', 5, 'perks',
   'est', '크루의 생일에 5만원 상당의 신세계 상품권 지급 (공식 채용 사이트 카카오게임즈 복지 혜택 건강하고 안정된 생활 명절/생일 선물 항목)', FALSE, NULL, 24),
  (@comp_id, 'car_rental', '캠핑카·캠핑 용품 무료 대여', NULL, 'perks',
   'est', NULL, TRUE, '캠핑을 떠나는 크루에게 캠핑카 및 캠핑 용품 무료 대여 (공식 채용 사이트 카카오게임즈 복지 혜택 편안한 휴식과 즐거운 여가 캠핑 항목 — 대여 횟수·기간 미기재)', 25),
  (@comp_id, 'discount', '카카오프렌즈 제품 임직원 할인', NULL, 'perks',
   'est', NULL, TRUE, '카카오 공동체 카드 소지 시 카카오프렌즈 물품을 임직원 할인가에 제공 (공식 채용 사이트 카카오게임즈 복지 혜택 편안한 휴식과 즐거운 여가 카카오 프렌즈 제품 할인 항목 — 할인율 미기재)', 26),
  (@comp_id, 'welfare_point', '복지 포인트 카드 (연 360만원)', 360, 'perks',
   'est', '자기계발, 여행, 문화 생활 등 원하는 곳에 자유롭게 사용 가능한 연 360만원 복지 포인트 카드 제공 (공식 채용 사이트 카카오게임즈 복지 혜택 함께 성장하는 기회 복지 포인트 항목)', FALSE, NULL, 27),

  -- ── 근무환경 (work_env) — 근무환경 ──
  (@comp_id, 'work_tools', '업무 기기·장비', NULL, 'work_env',
   'est', NULL, TRUE, '노트북, 모니터, 태블릿 등 업무에 필요한 최적의 기기와 장비 제공 (공식 채용 사이트 카카오게임즈 복지 혜택 근무환경 최적의 장비와 모션 데스크 항목)', 30),
  (@comp_id, 'lounge', '안마 의자·수면실', NULL, 'work_env',
   'est', NULL, TRUE, '업무 중 피로가 몰려올 때 잠시 쉬어갈 수 있는 안마 의자와 수면실 운영 (공식 채용 사이트 카카오게임즈 복지 혜택 근무환경 안마 의자와 수면실 항목 — 설치 오피스·이용 시간 미기재)', 31),
  (@comp_id, 'office_furniture', '모션 데스크', NULL, 'work_env',
   'est', NULL, TRUE, '업무 공간 모션 데스크 제공 (공식 채용 사이트 카카오게임즈 복지 혜택 근무환경 최적의 장비와 모션 데스크 항목 — 제공 범위 미기재)', 32),
  (@comp_id, 'nap_room', '수유시설 모자유친룸', NULL, 'work_env',
   'est', NULL, TRUE, '출산 후 복직한 임직원의 모유 수유를 돕는 오피스 내 수유시설 모자유친룸 운영 (카카오게임즈 ESG 보고서 2025 가족친화적 복지제도 운영 항목 — 설치 오피스 미기재)', 33),

  -- ── 건강·의료 (health) — 근무환경 · 건강하고 안정된 생활 ──
  (@comp_id, 'massage', '사이다룸 (헬스키퍼 마사지)', NULL, 'health',
   'est', NULL, TRUE, '오피스 내 건식 마사지 전문 헬스키퍼 상주, 월 2회 마사지 제공 (공식 채용 사이트 카카오게임즈 복지 혜택 근무환경 사이다룸 항목 — 본인 부담 여부 미기재)', 40),
  (@comp_id, 'health_check', '종합 건강 검진·예방접종', 100, 'health',
   'est', '매년 종합 건강 검진 지원, 격해로 배우자 및 부모님에게 양도 가능(공식 채용 사이트 카카오게임즈 복지 혜택 건강하고 안정된 생활 종합 건강 검진 항목), 환절기 예방접종 지원(같은 섹션 예방접종 지원 항목) — 검진 비용·접종 종류 미기재 (추정)', FALSE, NULL, 41),
  (@comp_id, 'insurance', '단체 상해 보험·치과 보험·가족 사랑 지원', 30, 'health',
   'est', '본인 및 배우자의 부모님까지 진단비, 정액 지급, 실손의료비를 보장하는 상해보험, 크루 본인·배우자·자녀 치과 보험, 크루 사망 시 유가족에게 사망 보험금 2억원(공식 채용 사이트 복지 혜택 건강하고 안정된 생활 섹션) — 보험료 지원 한도 미기재 (추정)', FALSE, NULL, 42),
  (@comp_id, 'mental', '심리·재무·부채·법률 전문 상담 (연 8회)', NULL, 'health',
   'est', NULL, TRUE, '마음 건강, 재무 고민, 법률 자문, 형사 합의 문제 등 각 분야 전문가 상담을 연 8회 무료 지원 (공식 채용 사이트 카카오게임즈 복지 혜택 건강하고 안정된 생활 심리/재무/부채/법률 전문 상담 항목)', 43),

  -- ── 여가·라이프 (leisure) — 간식과 음료 · 편안한 휴식과 즐거운 여가 · 성장 ──
  (@comp_id, 'library', '만화책·보드게임', NULL, 'leisure',
   'est', NULL, TRUE, '사무실 안 만화책, 보드 게임 등 즐길 거리 제공, 보드게임 대여 가능 (공식 채용 사이트 카카오게임즈 복지 혜택 간식과 음료 만화책과 보드게임 항목 — 비치 규모 미기재)', 50),
  (@comp_id, 'resort', '카카오게임즈 소유 휴양시설·리조트 회원권', 50, 'leisure',
   'est', '제주도 힐리우스, 부산 팔레드 시즈, 강원도 오크밸리 등 회사 소유 휴양시설의 프라이빗 숙소와 특별 휴가 지원, 전국 프리미엄 리조트 숙박권 회원가 제공(공식 채용 사이트 복지 혜택 편안한 휴식과 즐거운 여가 섹션) — 이용 횟수·특별 휴가 일수 미기재 (추정)', FALSE, NULL, 51),
  (@comp_id, 'leisure_ticket', '카카오 공동체 서비스 이용권', NULL, 'leisure',
   'est', NULL, TRUE, '멜론 스트리밍, 카카오 이모티콘 플러스, 카카오페이지 캐시 등 이용권 지원 (공식 채용 사이트 카카오게임즈 복지 혜택 편안한 휴식과 즐거운 여가 카카오 공동체 서비스 이용권 항목 — 지급 주기 미기재)', 52),
  (@comp_id, 'club', '사내 동호회 지원', NULL, 'leisure',
   'est', NULL, TRUE, '건전한 여가 활동과 활발한 소통을 위한 사내 동호회 활동비 지원 (공식 채용 사이트 카카오게임즈 복지 혜택 함께 성장하는 기회 사내 동호회 지원 항목 — 지원 금액 미기재)', 53),

  -- ── 가족·돌봄 (family) — 건강하고 안정된 생활 ──
  (@comp_id, 'childcare', '사내 어린이집 (판교 3곳)', NULL, 'family',
   'est', NULL, TRUE, '늦은 시간까지 안전하게 맡길 수 있는 사내 어린이집을 판교 지역 내 3곳 운영 (공식 채용 사이트 카카오게임즈 복지 혜택 건강하고 안정된 생활 사내 어린이집 항목 — 입소 기준·정원 미기재)', 60),
  (@comp_id, 'event', '경조사 지원', NULL, 'family',
   'est', NULL, TRUE, '결혼, 환갑, 출산, 장례 등 경조사에 축하와 조의를 전하고 경조휴가와 경조비 지원 (공식 채용 사이트 카카오게임즈 복지 혜택 건강하고 안정된 생활 경조사 지원 항목 — 경조 종류별 금액·휴가 일수 미기재)', 61),
  (@comp_id, 'parenting', '임신·출산 선물·자녀 입학 선물', NULL, 'family',
   'est', NULL, TRUE, '임신·출산 선물(공식 채용 사이트 카카오게임즈 복지 혜택 건강하고 안정된 생활 워킹맘 워킹대디 지원 항목), 입학을 앞둔 크루 자녀에게 학용품 세트와 상품권 등 입학 선물(같은 섹션 자녀 입학 선물 항목). 2026-02-24 공식 보도자료 기준 임산부 또는 배우자가 임산부인 임직원에게 스킨·헤어 케어세트와 임신·출산 도서 패키지, 출산 후 기저귀·의류 세트, 예비 초등학생 자녀에게 책가방·손목시계 등, 중·고등학교·대학교 입학 자녀에게 백화점 상품권 증정', 62),

  -- ── 보상·금전 (compensation) — 건강하고 안정된 생활 · 여가 ──
  (@comp_id, 'holiday_gift', '명절 선물 (카카오페이 머니)', NULL, 'compensation',
   'est', NULL, TRUE, '매년 설과 추석에 30만원 상당의 카카오페이 머니 지급 (공식 채용 사이트 카카오게임즈 복지 혜택 건강하고 안정된 생활 명절/생일 선물 항목 — 명절별 금액인지 연 합계인지 미기재)', 70),
  (@comp_id, 'incentive', '성과급 (조직 배분·개인 기여)', NULL, 'compensation',
   'est', NULL, TRUE, '조직 성과평가 결과에 따라 성과급 예산을 조직에 배분해 구성원 월 급여에 비례해 일괄 지급하는 조직 배분 성과급과 개인별 역할·기여도에 따라 차등 지급하는 개인 기여 성과급 (카카오게임즈 ESG 보고서 2025 평가 및 보상체계 항목 — 지급 수준 미기재)', 71)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
