-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- CJ올리브네트웍스 복리후생 데이터
-- 출처: AI 파싱 (2026-10-01)
-- URL: https://career.cjolivenetworks.co.kr/742cd01d-8e31-4ba8-aef0-94a98ea15072
-- badge: est
--
-- 참고:
--   정본은 CJ올리브네트웍스 채용 사이트(career.cjolivenetworks.co.kr, 회사 자기 도메인 서브도메인 · 노션 기반 oopy 호스팅)의
--   복지혜택 페이지다. 5섹션 40항목(섹션 제목 그림 Life 8 · Work 9 · Refresh 7 · Family 9 · Career 7)이 서버 렌더 HTML 본문에 그대로 있다
--   (__NEXT_DATA__ recordMap 과 렌더 본문 대조 — 숨은 블록 없음, 헤드리스 렌더 없음).
--   귀속: 페이지 머리말이 CJ올리브네트웍스의 복지혜택이라고 밝히고, 꼬리말이 씨제이올리브네트웍스 · CJ OLIVENETWORKS 저작권이다.
--   CJ그룹 채용 사이트(recruit.cj.net) 메인의 CJ올리브네트웍스 카드가 이 채용 사이트로 이어진다. 그룹 통합 페이지가 아니라 각주 없음.
--   CJ제일제당 · CJ올리브영 · CJ프레시웨이 · CJ대한통운 · CJ ENM · CJ CGV 정본 문구는 쓰지 않았다.
--   robots: career.cjolivenetworks.co.kr 은 Allow / (/_private/ 만 Disallow) · 법인 홈 www.cjolivenetworks.co.kr 은
--   일반 UA 에 Disallow / 라 요청하지 않았다.
--   보조 출처: 같은 사이트 올네올래 복리후생편(복지혜택 페이지가 링크하는 카드 6장) · 오피스 소개 · 성장 커리어 페이지.
--   제외: 기술인증제 교육(회사 운영 교육 과정) · 입문교육 · OJT · 멘토링 · Tech Forum · 자율복장 · 휴가 사용 자체(법정) · 육아휴직 법정 기간분.
--   금액: 명시값 1행(welfare_point 연 100) · 승계 추정치 4행(health_check 100 · medical 100 · resort 50 · child_edu 200 —
--     NOTE 끝에 (추정)). event 50 은 경조금이라 승계하지 않았다. 보육수당 월 10만원은 만 5·6세 자녀 한정이라 금액 칸에 넣지 않았다.
--   구본에서 뺀 행: remote_work(재택근무 원문 없음) · childcare(CJ키즈빌 원문 없음).
--   재코딩: books → library (전자도서관 E-Book 서비스는 어휘표 library 뜻).
--   SORT 섹션 순서 = 정본 페이지에서 카테고리가 처음 나온 순서
--     (perks 10 · health 20 · flexibility 30 · work_env 40 · leisure 50 · time_off 60 · compensation 70 · family 80 · growth 90).
-- 재수집(2026-10-01): 구본(2026-04-15 AI 파싱, 근거 URL 없음)을 공식 출처로 다시 세웠다
-- 검증(2026-10-01, RV-3-3): 32행 원문 확인 · Creative Week 서술에서 개인 휴가를 붙인 최대 4주(법정 휴가분) 제거 · parenting 보육수당 자녀 1인 월 10만원을 연 120 환산으로 금액 칸에 · pc_off(조직문화편 카드 PC 자동 종료) · leisure_room(오피스 소개 오껨존) 2행 추가 · 직원 1,476명(DART 2026-06-01 대규모기업집단현황공시)이라 재취업지원 의무 대상이나 관련 행 없음 — 최종 34행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (기존 회사 — INSERT IGNORE 는 no-op)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('cj', 'CJ올리브네트웍스',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '식품/유통/엔터', 'C', 'https://career.cjolivenetworks.co.kr/742cd01d-8e31-4ba8-aef0-94a98ea15072');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'cj');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://career.cjolivenetworks.co.kr/742cd01d-8e31-4ba8-aef0-94a98ea15072'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 경제적 부가혜택 (perks) — Life · Work ──
  (@comp_id, 'discount', '임직원카드 CJ 계열사 40% 할인', NULL, 'perks',
   'est', NULL, TRUE, '임직원카드로 CJ 계열사 제품·서비스 40% 할인(공식 채용 사이트 복지혜택 페이지), 올리브영·뚜레쥬르·VIPS·CGV·몽중헌 등 계열사와 브랜드에서 40% 할인, 올영세일 기간에는 세일가에서 한 번 더 40% 할인(같은 사이트 올네올래 복리후생편)', 10),
  (@comp_id, 'welfare_point', '카페테리아 포인트 (연 100만원)', 100, 'perks',
   'est', '카페테리아 포인트(복지포인트) 연 100만원 (공식 채용 사이트 복지혜택 페이지)', FALSE, NULL, 11),
  (@comp_id, 'birthday_gift', '생일 쿠폰', NULL, 'perks',
   'est', NULL, TRUE, '생일 쿠폰 지급 (공식 채용 사이트 복지혜택 페이지 — 쿠폰 금액·사용처 미기재)', 12),
  (@comp_id, 'housing_loan', '주택대출 이자 지원', NULL, 'perks',
   'est', NULL, TRUE, '주택대출 2천만원에 대한 이자 지원 (공식 채용 사이트 복지혜택 페이지 — 지원 이율·자격 요건 미기재)', 13),
  (@comp_id, 'snack_bar', '사내 무료 카페 (O’Cafe)', NULL, 'perks',
   'est', NULL, TRUE, '사내 무료 카페 운영(공식 채용 사이트 복지혜택 페이지), 본사 O’Cafe(같은 사이트 오피스 소개 페이지) — 제공 품목·운영 시간 미기재', 14),
  (@comp_id, 'meal', '본사 케이터링 식비 지원', NULL, 'perks',
   'est', NULL, TRUE, '본사 케이터링 식비 지원 (공식 채용 사이트 복지혜택 페이지 — 지원 끼니·단가 미기재)', 15),
  (@comp_id, 'promotion_gift', '승진자 식사 바우처', NULL, 'perks',
   'est', NULL, TRUE, '승진자에게 40~100만원 상당 식사 바우처 지급(공식 채용 사이트 복지혜택 페이지), 가족과 축하 식사를 할 수 있는 파인다이닝 식사 바우처(같은 사이트 올네올래 복리후생편)', 16),
  (@comp_id, 'transport', '23시 이후 퇴근 택시비', NULL, 'perks',
   'est', NULL, TRUE, '23시 이후 퇴근 시 택시비 실비 지원 (공식 채용 사이트 복지혜택 페이지)', 17),

  -- ── 건강·의료 (health) — Life · Family ──
  (@comp_id, 'health_check', '종합건강검진·독감 예방접종', 100, 'health',
   'est', '종합건강검진(근속·직급별 상이), 독감 예방접종비 지원 (공식 채용 사이트 복지혜택 페이지) — 검진 비용 미기재 (추정)', FALSE, NULL, 20),
  (@comp_id, 'medical', '본인 의료비·선천성 심장병 진료비', 100, 'health',
   'est', '급여항목 본인부담금 10만원 초과 시 본인 의료비 지원, 본인·자녀 선천성 심장병 진료비 지원 (공식 채용 사이트 복지혜택 페이지) — 지원 한도 미기재 (추정)', FALSE, NULL, 21),
  (@comp_id, 'mental', '전문 심리상담 (연 8회)', NULL, 'health',
   'est', NULL, TRUE, '전문 심리상담서비스 연 8회 (공식 채용 사이트 복지혜택 페이지 — 본인 부담 여부·가족 이용 미기재)', 22),

  -- ── 근무유연성 (flexibility) — Work ──
  (@comp_id, 'flex_work', '선택근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '근무시간을 자유자재로 정하는 선택근무제 (공식 채용 사이트 복지혜택 페이지 — 의무 근무시간대·적용 대상 미기재)', 30),
  (@comp_id, 'satellite_office', '거점오피스 CJ Work ON', NULL, 'flexibility',
   'est', NULL, TRUE, '분당·일산·동대문·용산역·강남 거점오피스(공식 채용 사이트 복지혜택 페이지), 거점오피스 CJ Work ON(같은 사이트 오피스 소개 페이지) — 이용 조건 미기재', 31),
  (@comp_id, 'pc_off', 'PC-OFF 제도', NULL, 'flexibility',
   'est', NULL, TRUE, '선택근무제로 설정한 퇴근 시간이 되면 컴퓨터가 자동으로 꺼지는 강제 퇴근 운영 (공식 채용 사이트 올네올래 조직문화편 — 예외 절차 미기재)', 32),

  -- ── 근무환경 (work_env) — Work ──
  (@comp_id, 'free_seating', '자율좌석제', NULL, 'work_env',
   'est', NULL, TRUE, '자율좌석제 (공식 채용 사이트 복지혜택 페이지 — 적용 사업장 미기재)', 40),
  (@comp_id, 'lounge', '세라젬 Zone·휴게 공간', NULL, 'work_env',
   'est', NULL, TRUE, '세라젬 Zone(공식 채용 사이트 복지혜택 페이지), 본사 O’Cera·O’Terrace 공간(같은 사이트 오피스 소개 페이지) — 이용 시간 미기재', 41),
  (@comp_id, 'nap_room', '여사우 휴게실', NULL, 'work_env',
   'est', NULL, TRUE, '편안한 휴식을 위한 여사우 휴게실 (공식 채용 사이트 복지혜택 페이지 · 오피스 소개 페이지 — 설치 사업장 미기재)', 42),

  -- ── 여가·라이프 (leisure) — Work · Refresh · Career ──
  (@comp_id, 'welcome_kit', '웰컴키트', NULL, 'leisure',
   'est', NULL, TRUE, '웰컴키트 지급 (공식 채용 사이트 복지혜택 페이지 — 구성품 미기재)', 50),
  (@comp_id, 'resort', '국내 숙박·해외여행 지원', 50, 'leisure',
   'est', '국내 숙박 지원(콘도·호텔·리조트 등), 해외여행 지원(공식 채용 사이트 복지혜택 페이지), 국내외 호텔·리조트 제휴로 저렴한 숙박 이용(올네올래 복리후생편) — 지원 금액 미기재 (추정)', FALSE, NULL, 51),
  (@comp_id, 'leisure_ticket', 'CGV 영화예매권 (연 6매)', NULL, 'leisure',
   'est', NULL, TRUE, 'CGV 영화예매권 연 6매 지급 (공식 채용 사이트 복지혜택 페이지)', 52),
  (@comp_id, 'club', '사내 동호회 (20여 개)', NULL, 'leisure',
   'est', NULL, TRUE, '사내 동호회 20여 개 운영 및 활동비 지원 (공식 채용 사이트 복지혜택 페이지 — 지원 금액 미기재)', 53),
  (@comp_id, 'library', '전자도서관·미니도서관', NULL, 'leisure',
   'est', NULL, TRUE, '전자도서관(E-Book) 서비스 제공(공식 채용 사이트 복지혜택 페이지), 오카페 미니도서관(같은 사이트 오피스 소개 페이지)', 54),
  (@comp_id, 'leisure_room', '게임존 (오껨존)', NULL, 'leisure',
   'est', NULL, TRUE, '농구·다트 게임과 닌텐도 스위치·플스5를 즐길 수 있는 본사 게임 공간 오껨존 (공식 채용 사이트 오피스 소개 페이지)', 55),

  -- ── 시간·휴가 (time_off) — Refresh ──
  (@comp_id, 'leave_general', '시간 단위 휴가·자가결재', NULL, 'time_off',
   'est', NULL, TRUE, '2시간 단위와 시간 단위로 휴가를 나눠 쓰고 본인이 직접 결재하는 자유로운 휴가 사용 (공식 채용 사이트 복지혜택 페이지)', 60),
  (@comp_id, 'long_service_leave', 'Creative Week (근속 2주 유급휴가)', NULL, 'time_off',
   'est', NULL, TRUE, '근속 3·5·7·10년 차와 10년 차 이후 5년마다 2주 유급휴가 Creative Week (공식 채용 사이트 복지혜택 페이지 · 올네올래 복리후생편)', 61),

  -- ── 보상·금전 (compensation) — Refresh ──
  (@comp_id, 'long_service_bonus', '근속 10년 포상금', NULL, 'compensation',
   'est', NULL, TRUE, '근속 10년 포상금 지급 (공식 채용 사이트 복지혜택 페이지 — 포상 금액 미기재)', 70),

  -- ── 가족·돌봄 (family) — Family ──
  (@comp_id, 'event', '경조휴가·경조금·웨딩 지원', NULL, 'family',
   'est', NULL, TRUE, '경조휴가와 경조금 지원, 웨딩홀·웨딩카 지원 (공식 채용 사이트 복지혜택 페이지 — 경조 종류별 금액·휴가 일수 미기재)', 80),
  (@comp_id, 'parenting', '임신·출산 선물·자녀 돌봄·보육수당', 120, 'family',
   'est', '만 5·6세 자녀 보육수당 매월 1인당 10만원, 임신·출산 축하선물, 육아휴직 최대 2년, 초등 입학 자녀돌봄휴가 2주, 장애자녀 양육비, 급여 차감 없는 신생아 돌봄 하루 2시간 근로시간 단축 (공식 채용 사이트 복지혜택 · 올네올래 복리후생편) — 자녀 1인 월 10만원을 연 120만원으로 환산', FALSE, NULL, 81),
  (@comp_id, 'child_edu', '자녀 학자금 (실비)', 200, 'family',
   'est', '자녀 학자금 실비 지원 (공식 채용 사이트 복지혜택 페이지) — 지원 학년·한도 미기재 (추정)', FALSE, NULL, 82),
  (@comp_id, 'fertility_support', '난임 시술비·난임휴직', NULL, 'family',
   'est', NULL, TRUE, '난임부부 시술비 지원, 여성 본인 난임휴직 최대 6개월 (공식 채용 사이트 복지혜택 페이지 — 시술비 한도 미기재)', 83),

  -- ── 성장·커리어 (growth) — Career ──
  (@comp_id, 'lang', '외국어회화 시험비용', NULL, 'growth',
   'est', NULL, TRUE, '외국어회화 시험비용 연 2회 전액 지원 (공식 채용 사이트 복지혜택 페이지)', 90),
  (@comp_id, 'edu_support', '직무 교육비·러닝클럽', NULL, 'growth',
   'est', NULL, TRUE, '직무 관련 교육비 지원, 사내 스터디 비용과 컨설팅을 지원하는 자기주도 학습 모임 러닝클럽 (공식 채용 사이트 복지혜택 페이지 · 성장 커리어 페이지 — 지원 한도 미기재)', 91),
  (@comp_id, 'self_development', '기술자격증 취득비용', NULL, 'growth',
   'est', NULL, TRUE, '기술자격증 취득비용 지원 (공식 채용 사이트 복지혜택 페이지 — 지원 한도 미기재)', 92),
  (@comp_id, 'career', '사내공모제도 (분기별)', NULL, 'growth',
   'est', NULL, TRUE, '경력개발 동기부여와 새로운 직무 기회 제공을 위한 분기별 사내공모제도 (공식 채용 사이트 복지혜택 페이지 · 올네올래 복리후생편)', 93)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
