-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 두산테스나 복리후생 데이터 (신규 회사 — 웨이브 7)
-- 출처: AI 파싱 (2026-10-14)
-- URL: http://www.tesna.co.kr/boad/bd_news/3/egoread_doosan.asp?bd=3&seq=109
-- badge: est
--
-- 참고:
--   정본 = 법인 자기 도메인(www.tesna.co.kr, DART 홈 주소) 공지/뉴스 게시판의 「2025 두산테스나 지속가능경영 정보공개」 게시물
--     (게시 2026-06-30). 행 근거는 그 게시물 첨부 PDF(34쪽, PowerPoint 작성, 보고 대상 2025년)의 사회 인재경영 절
--     16쪽 일과 생활의 균형 · 17쪽 가족친화경영이다. 19쪽 인권경영 중장기목표 2025 성과 칸이 같은 제도(출산 경조금 신설 ·
--     배우자 출산휴가 유급일수 추가 · 선택적 근로시간제 · 심리 상담 프로그램 마음e 신설)를 받친다.
--   보조 출처 = OpenDART 2026 반기보고서(접수 20260814002891) 직원 등 현황 유연근무제도 표(선택근무제 · 원격근무제 사용자 수).
--   렌더 = 정적 ASP(UTF-8) · HTTPS 는 인증서 불일치(호스팅 와일드카드)로 열리지 않아 http 주소가 정본이다.
--   귀속 = 법인 자기 도메인에 법인이 올린 자기 보고서라 각주 없음. 두산 그룹 채용 사이트 복리후생 · 출산육아지원 페이지는
--     계열사 별 상이 면책이 붙은 그룹 공통 서술이고 두산테스나 공고에는 복리후생 절이 없어 행 근거로 쓰지 않았다.
--     두산에너빌리티 parenting 행과 제도 구성(보육지원금 · 서포터즈 지원금 · 배우자 출산휴가 5일 추가)이 같지만 근거 문장은 이 법인 보고서다.
--   금액 = 환산 1행(parenting 보육지원금 월 20만 원 → 연 240, 추정치). 그 밖 8행 정성(학자금 한도 · 실비 · 1회성 축하금은 금액 칸에 넣지 않음).
--   제외 = 법정(육아휴직 · 배우자 출산휴가 법정분 · 주 52시간 한도) · 직무 · 직급 · 리더십 교육 전부 · 직장 내 어린이집(2030 목표, 현행 아님) ·
--     직장협의회 안건(휴게공간 개선 · DP사업부 통근버스 교체) · 사회공헌 매칭 기부 · 옛 테스나 시절 채용 페이지(헤더 메뉴 · 사이트맵 밖).
--   공고 근거 0행 / 전체 9행 · SORT 섹션 순서 = 보고서 등장 순(flexibility 10 · health 20 · family 30).
-- 검증 · 감사 판정 반영(2026-10-14): 행 조치 없음 · 원격근무 행 항목 페이지 예외 1(통합 밖 리드 집행) — 최종 9행
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- 1) 회사 등록 (신규 — 이 INSERT 가 실제 등록을 수행한다)
INSERT IGNORE INTO TCOMPANY (COMP_ENG_NM, COMP_NM, COMP_TP_ID, INDUSTRY_NM, LOGO_NM, CAREERS_BENEFIT_URL)
VALUES ('doosan_tesna', '두산테스나',
        (SELECT COMP_TP_ID FROM TCOMPANY_TYPE WHERE COMP_TP_CD = 'mid'),
        '반도체후공정', 'D', 'http://www.tesna.co.kr/boad/bd_news/3/egoread_doosan.asp?bd=3&seq=109');

-- 2) COMP_ID 조회
SET @comp_id = (SELECT COMP_ID FROM TCOMPANY WHERE COMP_ENG_NM = 'doosan_tesna');

-- 3) CAREERS_BENEFIT_URL 갱신 (이미 행이 있으면 INSERT IGNORE 로는 안 바뀐다)
UPDATE TCOMPANY SET CAREERS_BENEFIT_URL = 'http://www.tesna.co.kr/boad/bd_news/3/egoread_doosan.asp?bd=3&seq=109'
 WHERE COMP_ID = @comp_id;

-- 4) 기존 추정 데이터 삭제 (official 보존)
DELETE FROM TCOMPANY_BENEFIT WHERE COMP_ID = @comp_id AND BADGE_CD = 'est';

-- 5) 복리후생 INSERT
INSERT INTO TCOMPANY_BENEFIT
  (COMP_ID, BENEFIT_CD, BENEFIT_NM, BENEFIT_AMT, BENEFIT_CTGR_CD,
   BADGE_CD, NOTE_CTNT, QUAL_YN, QUAL_DESC_CTNT, SORT_ORDER_NO)
VALUES
  -- ── 근무 유연성 (flexibility) — 보고서 16쪽 일과 생활의 균형 · 반기보고서 유연근무제도 표 ──
  (@comp_id, 'flex_work', '선택적 근로시간제', NULL, 'flexibility',
   'est', NULL, TRUE, '월 단위 필요 근무시간 안에서 임직원이 스스로 근무 일정을 설계하는 선택적 근로시간제 운영 (2025 지속가능경영 정보공개 16쪽 초과근로 제한 및 유연근무 안착 항목), 선택근무제 사용자 187명 (2026 반기보고서 유연근무제도 항목) — 적용 대상 직무 미기재', 10),
  (@comp_id, 'pc_off', 'PC-OFF 프로그램', NULL, 'flexibility',
   'est', NULL, TRUE, '선택적 근로시간제와 연동해 스스로 설계한 근무 일정이 끝나면 시스템 접속이 자동 차단되는 PC-OFF 프로그램 운영 (2025 지속가능경영 정보공개 16쪽 초과근로 제한 및 유연근무 안착 항목)', 11),
  (@comp_id, 'remote_work', '재택 및 원격근무제', NULL, 'flexibility',
   'est', NULL, TRUE, '소속장 승인 하에 자택과 사내 타 사업장(리모트 오피스)에서 원격 업무를 허용해 임직원이 최적의 환경을 스스로 선택하도록 지원 (2025 지속가능경영 정보공개 16쪽 근무 공간의 자율성 확대 항목), 원격근무제(재택근무 포함) 사용자 5명 (2026 반기보고서 유연근무제도 항목) — 사용 횟수·대상 직무 미기재', 12),

  -- ── 건강 (health) — 보고서 16쪽 맞춤형 의료 지원 · 심리 케어 · 17쪽 의료비 지원 ──
  (@comp_id, 'health_check', '종합건강검진 (만 35세 이상 배우자 포함)', NULL, 'health',
   'est', NULL, TRUE, '전 임직원 대상 매년 종합건강검진 지원, 만 35세 이상 직원은 본인과 배우자까지 매년 1회 같은 혜택 (2025 지속가능경영 정보공개 16쪽 임직원 및 가족 건강 증진을 위한 맞춤형 의료 지원 항목) — 검진 항목·비용 지원 범위 미기재', 20),
  (@comp_id, 'mental', '심리상담 프로그램 마음e', NULL, 'health',
   'est', NULL, TRUE, '맞춤형 심리상담 프로그램 「마음e」 운영, 직무 스트레스와 개인적인 심리적 고충까지 다루는 전문 상담 채널 제공 (2025 지속가능경영 정보공개 16쪽 임직원 심리 케어 프로그램 항목) — 상담 횟수·가족 이용 여부 미기재', 21),
  (@comp_id, 'medical', '입원 의료비 지원', NULL, 'health',
   'est', NULL, TRUE, '임직원 본인 및 그 가족이 1박2일 이상 입원 치료 시 본인 부담분 중 일정 금액을 회사가 보조, 지원 내용에 임신·출산·제왕절개 포함 (2025 지속가능경영 정보공개 17쪽 의료비 지원 항목) — 보조 비율·한도·가족 범위 미기재', 22),

  -- ── 가족 (family) — 보고서 17쪽 가족친화경영 ──
  (@comp_id, 'parenting', '임신·출산·육아 지원', 240, 'family',
   'est', '만 1~2세 자녀 보육지원금 월 20만원, 본인·배우자 임신 시 50만원 상당 축하 선물, 출생 순서별 최대 1,000만원 출산경조금, 배우자 출산휴가 회사 유급 5일 추가, 만 12세 이하 자녀 법정 육아휴직 뒤 최대 1년 추가, 휴직 기간 첫 1개월 급여 차액 보전 (2025 지속가능경영 정보공개 17쪽 항목) — 월 20만원을 연 240만원으로 환산', FALSE, NULL, 30),
  (@comp_id, 'child_edu', '자녀 학자금 지원', NULL, 'family',
   'est', NULL, TRUE, '유치원 및 어린이집 분기당 10만 원, 중·고등학교 연 최대 500만 원 실비, 대학교 총 8학기 실비 학자금 지원 (2025 지속가능경영 정보공개 17쪽 생애주기별 자녀 보육 및 학자금 지원 항목) — 초등학교 지원 여부·대학교 학기당 한도 미기재', 31),
  (@comp_id, 'fertility_support', '난임 시술비·검사비 지원', NULL, 'family',
   'est', NULL, TRUE, '1박2일 이상 입원 치료 시 본인 부담분 일부를 보조하는 의료비 지원 제도의 지원 내용에 난임 시술비용·난임 검사비 포함 (2025 지속가능경영 정보공개 17쪽 의료비 지원 항목) — 지원 한도·횟수 미기재', 32)
ON DUPLICATE KEY UPDATE
  BENEFIT_NM=VALUES(BENEFIT_NM), BENEFIT_AMT=VALUES(BENEFIT_AMT),
  BENEFIT_CTGR_CD=VALUES(BENEFIT_CTGR_CD), BADGE_CD=VALUES(BADGE_CD),
  NOTE_CTNT=VALUES(NOTE_CTNT), QUAL_YN=VALUES(QUAL_YN),
  QUAL_DESC_CTNT=VALUES(QUAL_DESC_CTNT), SORT_ORDER_NO=VALUES(SORT_ORDER_NO);
