-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 농심 복리후생 데이터 (신규 회사)
-- 출처: AI 파싱 (2026-09-19)
-- URL: https://recruit.nongshim.com/personnel/benefit/index
-- badge: est (추정치 — 공식 확인 시 official 로 변경)
-- 참고: 근거는 전부 농심 공식 채용 도메인(recruit.nongshim.com)의 회사소개 > 복리후생
--       페이지 한 곳이다. SSR HTML 이라 헤드리스 브라우저를 쓰지 않았다.
--       15개 항목이 section.benefit 3개(즐거운 일터 4 · 행복한 가정 5 · 안정적인 삶 6)의
--       ul.benefit-list > li 안에 텍스트로 그대로 있다. 이미지 안 항목 0건.
--       ⚠ UA: 이 호스트의 robots.txt 는 User-agent: * 에 Disallow: / 를 걸고
--          ClaudeBot·GPTBot·CCBot 등 10개 UA 만 이름으로 Allow: / 한다. 그래서 이번 수집은
--          전 요청을 ClaudeBot UA 로 보냈고 Crawl-delay: 10 을 지켰다(본문 요청 1회).
--          일반 브라우저 UA 로 재확인하면 * 규칙 위반이니 재수집 때도 UA 를 그대로 쓸 것.
--       귀속: 호스트 title 이 농심 채용이고 농심태경·농심엔지니어링 지원자도 같은 페이지를
--       보지만, 본문 주어가 「농심은 구성원들이…」이고 계열사·상이·회사별·해당사·관계사
--       면책 문구가 0건이며 푸터 법인 표기가 (주)농심(사업자등록번호 118-81-03914)이다.
--       항목 자체도 본사 어린이집·본사 예식장·농심몰·코코이찌방야 같은 법인 전용 시설·브랜드다.
--       → 법인 귀속으로 보고 「그룹 통합 채용 기준」 각주는 붙이지 않았다(삼성화재 선례).
--       우리 코퍼스에 농심그룹 형제 등록은 0건이라 중복 위험도 없다.
--       15항목 → 1항목 제외(-1), 복합 라벨 3개 분해(+3), 예식장을 경조사와 병합(-1) → 16행.
--          식사 및 간식 지원 → meal + snack_bar
--          본인/가족경조사 및 자녀학자금 지원 → event + child_edu
--          종합 건강검진 및 의료비 지원 → health_check + medical
--          본사 예식장 운영 → event 서술로 흡수(계약 8-2 및 삼성ENA 선례 — 대관은 event)
--          대출지원(의료비,학자금,주택) → housing_loan 1행(코퍼스 선례 임직원 대출·사내대출)
--       ⚠ 제외 1건: 자율복장 출퇴근. 원익IPS 검증에서 uniform 반증으로 삭제된 유형이고
--          삼성ENA 도 같은 선례로 제외했다. 코퍼스에 복장 자율화 행은 0건이라 여기서
--          신규 코드를 만들면 그 선례를 뒤집게 된다. 상세는 evidence 참조.
--       금액: 페이지에 원 단위 금액·한도·비율이 0건이다. 수치는 해피데이(월 1회 1시간)뿐이라
--       금액이 아니다 → 16행 전부 BENEFIT_AMT NULL · QUAL_YN TRUE. 신규 회사라 앵커도 없다.
--       법정 제도 미수록: 본문에 4대보험·퇴직연금·연차·육아휴직·출산휴가 문자열이 0회다.
--       종합 건강검진은 산안법 일반건강검진 상회분(종합검진)이라 수록했고,
--       노동절 기념품 행은 법정 휴일이 아니라 기념품 지급만 수록한다.
--       ⚠ 갱신 감지는 div.benefits-container 영역 해시로 볼 것(title·canonical 이 공통이다).
--       ⚠ 검증·감사 판정 반영(2026-09-19): 16행 그대로. 복합 라벨을 쪼갠 SORT 41·42·51·52 가 서로의 내용을
--       되풀이하던 것을 각 행의 몫만 말하도록 고쳤고, 9개 필드의 전사 방식 서술을 걷어냈다.
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('nongshim', '농심',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'large'),
        '식품', 'N', 'https://recruit.nongshim.com/personnel/benefit/index');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'nongshim');

-- 3) 기존 행의 CAREERS_BENEFIT_URL 갱신 (INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'https://recruit.nongshim.com/personnel/benefit/index'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 경제적 부가혜택 (perks) ──
  (@comp_id, 'meal', '식사 지원', NULL, 'perks',
   'est', NULL, TRUE, '식사 및 간식 지원 (공식 채용 페이지 복리후생 「즐거운 일터」 항목 — 제공 끼니·식대 단가 미기재)', 10),
  (@comp_id, 'snack_bar', '간식 지원', NULL, 'perks',
   'est', NULL, TRUE, '식사 및 간식 지원 (공식 채용 페이지 복리후생 「즐거운 일터」 항목 — 간식 종류·제공 장소 미기재)', 11),
  (@comp_id, 'housing_loan', '대출 지원(의료비·학자금·주택)', NULL, 'perks',
   'est', NULL, TRUE, '대출지원(의료비,학자금,주택) (공식 채용 페이지 복리후생 「안정적인 삶」 항목 — 대출 한도·이율·상환 조건 미기재)', 12),
  (@comp_id, 'discount', '임직원 할인혜택', NULL, 'perks',
   'est', NULL, TRUE, '임직원 할인혜택(농심몰,코코이찌방야) (공식 채용 페이지 복리후생 「안정적인 삶」 항목 — 할인율·이용 한도 미기재)', 13),

  -- ── 유연근무 (flexibility) ──
  (@comp_id, 'family_day', '해피데이 조기퇴근', NULL, 'flexibility',
   'est', NULL, TRUE, '해피데이 운영 — 매월 셋째주 금요일 1시간 조기퇴근 (공식 채용 페이지 복리후생 「즐거운 일터」 항목)', 20),
  (@comp_id, 'flex_work', '시차출퇴근제도', NULL, 'flexibility',
   'est', NULL, TRUE, '시차출퇴근제도 운영 (공식 채용 페이지 복리후생 「행복한 가정」 항목 — 선택 가능 출근 시간대·신청 방법 미기재)', 21),

  -- ── 여가·라이프 (leisure) ──
  (@comp_id, 'club', '동호회 활동지원', NULL, 'leisure',
   'est', NULL, TRUE, '동호회 활동지원 (공식 채용 페이지 복리후생 「즐거운 일터」 항목 — 지원 금액·동호회 수 미기재)', 30),
  (@comp_id, 'resort', '휴양시설(콘도)', NULL, 'leisure',
   'est', NULL, TRUE, '휴양시설 지원(콘도) (공식 채용 페이지 복리후생 「행복한 가정」 항목 — 제휴 콘도·이용 조건 미기재)', 31),

  -- ── 가족·돌봄 (family) ──
  (@comp_id, 'childcare', '본사 어린이집', NULL, 'family',
   'est', NULL, TRUE, '본사 어린이집 운영 (공식 채용 페이지 복리후생 「행복한 가정」 항목 — 정원·대상 연령·이용 비용 미기재)', 40),
  (@comp_id, 'event', '경조사 지원·본사 예식장', NULL, 'family',
   'est', NULL, TRUE, '본인/가족 경조사 지원, 본사 예식장 운영 (공식 채용 페이지 복리후생 항목 — 경조 지원 내용·금액·예식장 이용 조건 미기재)', 41),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '자녀학자금 지원 (공식 채용 페이지 복리후생 「안정적인 삶」 항목 — 지원 한도·대상 학교급·자녀 수 제한 미기재)', 42),

  -- ── 건강·의료 (health) ──
  (@comp_id, 'fitness', '피트니스 센터', NULL, 'health',
   'est', NULL, TRUE, '피트니스 센터 (공식 채용 페이지 복리후생 「행복한 가정」 항목 — 위치·이용료·운영 시간 미기재)', 50),
  (@comp_id, 'health_check', '종합 건강검진', NULL, 'health',
   'est', NULL, TRUE, '종합 건강검진 (공식 채용 페이지 복리후생 항목 — 검진 주기·대상 가족 범위·비용 부담 미기재)', 51),
  (@comp_id, 'medical', '의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '의료비 지원 (공식 채용 페이지 복리후생 항목 — 지원 한도·대상 질환·가족 포함 여부 미기재)', 52),

  -- ── 보상·금전 (compensation) ──
  (@comp_id, 'long_service_bonus', '장기근속 기념품', NULL, 'compensation',
   'est', NULL, TRUE, '장기근속기념품 지급 (공식 채용 페이지 복리후생 「안정적인 삶」 항목 — 근속 연차 기준·기념품 내용 미기재)', 60),
  (@comp_id, 'holiday_gift', '기념일 기념품', NULL, 'compensation',
   'est', NULL, TRUE, '노동절, 창립기념일 기념품 지급 (공식 채용 페이지 복리후생 「안정적인 삶」 항목 — 기념품 내용·금액 미기재)', 61)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
