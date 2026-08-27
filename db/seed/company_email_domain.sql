-- SP-AUTH-7 / T-13.8.4 회사↔이메일 도메인 화이트리스트 시드 (DG-5, 2026-07-23 확정)
--
-- 재직 인증(자동)의 근거 테이블. 입력 회사 이메일의 도메인이 해당 회사에 등록돼 있으면
-- 도메인 인증 경로로 코드를 발송한다. 미등록 회사는 수동 승인(ops.py) 폴백.
--
-- 조사 방식: 근거 기반 워크플로우(공식 IR·개인정보처리방침·회사 공지 등 1차 출처)로 24개
-- 대기업 도메인을 확증하고, 개인 이메일 등 PII는 폐기·미보존(도메인만 사용).
--
-- ⚠️ 그룹 공용 도메인 결정(사용자 2026-07-23): 삼성 계열은 모두 @samsung.com, SK 계열은
--    모두 @sk.com 을 공유한다. 이는 **그룹 단위 재직 인증**을 의미한다 — 예: @samsung.com
--    보유자는 어느 삼성 계열사로든 인증할 수 있다(계열사 세밀 구분 없음). 편집 이력이 공개라
--    추적 가능하다는 전제의 트레이드오프. uq_company_domain 이 (COMP_ID, 도메인) 복합이라
--    한 도메인을 다수 계열사에 매핑한다. (COMP_EMAIL_HASH_VAL UNIQUE 로 한 이메일=한 계정은 유지)
--
-- 멱등: INSERT IGNORE + (COMP_ID, EMAIL_DOMAIN_NM) 복합 UNIQUE 로 재적용 안전. 미등록 slug 는 no-op.

-- ── 회사 전용 도메인 (계열 혼선 없음) ─────────────────────────────────────────
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'kt.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'kt';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'lge.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'lg_elec';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'lgchem.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'lg_chem';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'lgensol.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'lg_energy';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'lguplus.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'lg_uplus';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'navercorp.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'naver';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'hyundai.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_motor';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'mobis.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_mobis';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'kia.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'kia';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'koreanair.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'korean_air';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'hanmi.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'hanmi_pharm';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'kakaocorp.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'kakao';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'kakaobank.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'kakao_bank';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'kakaogames.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'kakao_games';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'krafton.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'krafton';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'ncsoft.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'ncsoft';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'pearlabyss.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'pearl_abyss';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'wemade.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'wemade';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'hybecorp.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'hybe';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'celltrion.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'celltrion';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'amorepacific.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'amorepacific';

-- ── 삼성 그룹 공용 도메인 samsung.com → 전 계열사(그룹단위 인증) ─────────────────
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'samsung.com', TRUE FROM TCOMPANY
   WHERE COMP_ENG_NM IN ('samsung_elec','samsung_sdi','samsung_ct','samsung_bio',
                         'samsung_life','samsung_electro','samsung_card');

-- ── SK 그룹 공용 도메인 sk.com → 전 계열사(그룹단위 인증) ─────────────────────────
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'sk.com', TRUE FROM TCOMPANY
   WHERE COMP_ENG_NM IN ('sk_hynix','skt','sk_innovation');

-- ═══════════════════════════════════════════════════════════════════════════════
-- 2026-07-29 추가분 — 62개사(도메인 등록 31 → 93/95, 커버리지 33% → 98%)
--
-- 조사 방식은 위와 같다: **회사가 소유한 공식 사이트(또는 DART 공시)에 실제로 게시된
-- 이메일 주소**만 근거로 삼았다. 회사명·사이트 주소에서 메일 도메인을 유추한 건은 하나도
-- 없다 — 이번 조사에서만 "사이트 도메인 ≠ 메일 도메인" 반례가 9건 나왔다(실리콘투
-- siliconii.com→siliconii.net · 리노공업 leeno.com→leeno.co.kr · 엔켐 enchem.net→enchem.kr
-- · 아이센스 .co.kr→.com · 파마리서치 .com→.co.kr 등). 유추했다면 그만큼 오매핑이 났다.
--
-- 채택하지 않은 것들(기록해 둔다 — 다시 조사하지 않기 위해):
--   · HPSP(thehpsp.com) · 덕산네오룩스(dsnl.co.kr) — 도메인 소유·자체 MX 는 확인됐으나
--     전 사이트에 **게시된 이메일이 0건**이다(문의가 웹폼·전화뿐). 증거 기준 미달 → 보류.
--   · 현대제철 partners-steel.kr — 처리방침의 "기술책임자"가 외주 SI(지니시스템즈) 직원이다.
--     회사 공식 페이지 게시물이지만 임직원 도메인이 아니다. 넣었으면 SI 직원이 현대제철
--     재직자가 됐다. **게시 위치가 아니라 소속을 봐야 한다.**
--   · ecoprobm.co.kr — 검색엔진이 계속 노출하지만 **DNS 자체가 없다**(NXDOMAIN).
--   · 미게시 도메인들: jseng.com(주성) · bhflex.co.kr(비에이치) · ecoprobm.com(에코프로비엠)
--     · techwing.com · leeno.com · classys.co.kr · enchem.net(MX 없음) — 회사 소유이거나
--     MX 는 있으나 게시된 이메일이 없어 제외.
--
-- 위 문단의 기계가독 사본 — SED-7 가드가 이 줄들을 읽어 "보류로 적어 둔 도메인이 실제로
-- INSERT 돼 있지 않은지" 검사한다. 사유는 바로 위 산문이 정본이고 여기엔 한 줄 요약만 둔다.
-- ⚠ 특히 아래 5건은 **채택된 형제 도메인과 한 글자 차이**다(techwing.co.kr · leeno.co.kr ·
--    classys.com · enchem.kr · jusung.com). 다음 사람이 .com/.co.kr 을 헷갈리는 것이 이
--    파일에서 가장 일어나기 쉬운 사고이고, SED-7 은 그것을 잡으라고 있다.
-- @rejected: thehpsp.com — HPSP. 게시된 이메일 0건(2026-07-29 · 2026-08-27 재확인)
-- @rejected: dsnl.co.kr — 덕산네오룩스. 자체 MX 는 있으나 게시된 이메일 0건
-- @rejected: partners-steel.kr — 현대제철. 게시자가 외주 SI 직원이라 임직원 도메인이 아니다
-- @rejected: ecoprobm.co.kr — 에코프로비엠. DNS 부재(NXDOMAIN)
-- @rejected: ecoprobm.com — 에코프로비엠. 게시된 이메일 없음
-- @rejected: jseng.com — 주성엔지니어링. 게시된 이메일 없음(채택본은 jusung.com)
-- @rejected: bhflex.co.kr — 비에이치. 게시된 이메일 없음(채택본은 bhe.co.kr)
-- @rejected: techwing.com — 테크윙. 게시된 이메일 없음(채택본은 techwing.co.kr)
-- @rejected: leeno.com — 리노공업. 게시된 이메일 없음(채택본은 leeno.co.kr)
-- @rejected: classys.co.kr — 클래시스. 게시된 이메일 없음(채택본은 classys.com)
-- @rejected: enchem.net — 엔켐. MX 없음(채택본은 enchem.kr)
-- ═══════════════════════════════════════════════════════════════════════════════


-- ═══════════════════════════════════════════════════════════════════════════════
-- 2026-08-27 재조사 — 잔여 2사(HPSP · 덕산네오룩스). 결론: **둘 다 계속 보류**(100/102 유지)
--
-- ⚠ 이 세션의 조사 한계를 먼저 밝힌다: 실행 환경의 외부 egress 가 전면 차단돼(모든 호스트
--   CONNECT 403 — 회사 사이트·DART·PDF 모두) **1차 출처를 직접 열지 못했다.** 아래 근거는
--   전부 검색엔진(Naver 웹검색·웹검색) 스니펫이고, 스니펫은 1차 출처가 아니다. 그래서
--   "등록한다" 쪽으로는 한 건도 쓰지 않았다 — 이 파일의 증거 기준(게시된 주소를 눈으로
--   확인)에 미달하기 때문이다. 반대로 "등록하지 않는다"는 판단에는 충분히 쓸 수 있다.
--
-- ── HPSP — 변화 없음. 게시 이메일 0건 ────────────────────────────────────────────
-- 회사 사이트(thehpsp.com)·채용공고(사람인·KB굿잡)·영문 보도자료(PRNewswire/imec)·IR 어디
-- 에서도 @thehpsp.com 주소가 노출되지 않는다. 2026-07-29 판단이 그대로 유효하다.
-- ⚠ 다음 사람을 위한 경고 — 이 사이트에는 **함정이 하나 있다.** 그누보드 게시판
--    `bbs/board.php?bo_table=contact` 는 회사 연락처 페이지가 아니라 **외부인이 글을 쓰는
--    문의 게시판**이다(실제 글 제목: "[키움증권 리서치센터] 컨퍼런스 콜 요청 안내").
--    거기서 이메일을 발견하더라도 그건 증권사 애널리스트 주소지 HPSP 임직원 주소가 아니다.
--    현대제철 partners-steel.kr 과 **정확히 같은 부류**다 — 게시 위치가 아니라 소속을 봐라.
--
-- ── 덕산네오룩스 — 메일 도메인을 찾았다. 그리고 그게 등록하지 말아야 할 이유다 ──────────
-- 실제 사내 메일 도메인은 자사 웹 도메인(dsnl.co.kr)이 아니라 **oneduksan.com** 이다.
-- 근거(둘 다 회사가 만든 문서를 제3자가 재게시한 것 — 회사 사이트에는 없다):
--   · 호서대 반도체공학과 게시 PDF — 덕산네오룩스㈜ 대표이사 명의 채용 인재추천 요청 공문.
--     "당사 이력서(첨부) 작성 및 이메일 접수(제출처: *******@oneduksan.com)", 첨부파일명
--     `DSNL_입사지원서_연구직`, 발신 주소가 천안 본사(충남 천안시 서북구 입장면 쑥골길 21-32).
--   · DART 대량보유상황보고서(덕산네오룩스 등기임원 이수훈) 보고자 이메일 `******@oneduksan.com`,
--     전화 041-59** (천안 지역번호).
--
-- ⚠ 그러나 oneduksan.com 은 **덕산그룹 공용 도메인이다** — 덕산네오룩스 전용이 아니다:
--   · `gw.oneduksan.com` = 덕산 **그룹웨어** 메일(`/Mail/Default.aspx`)
--   · `recruit.oneduksan.com` 개인정보 수집동의문이 "**덕산홀딩스㈜ 및 덕산계열사**"라고
--     명시하고, 그 채용공고 목록에 솔더 조성·전해도금·미립자 도금 등 **덕산하이메탈 직무**가
--     섞여 있다(덕산네오룩스는 OLED 유기소재라 업무가 겹치지 않는다)
--   · `sd.oneduksan.com` = **덕산하이메탈** 보안파일 관리
--
-- 우리 목록의 덕산 계열은 **덕산네오룩스 한 곳뿐**이다. 지금 넣으면 덕산홀딩스·덕산하이메탈·
-- 덕산테코피아·덕산에테르씨티·현대중공업터보기계 임직원이 **전원 덕산네오룩스 재직자로 자동
-- 인증된다.** 이건 위 cj.net 주석이 "가장 심한 사례"로 기록해 둔 구조(계열사가 목록에 하나뿐인
-- 그룹 공용 도메인)와 동일하다. 삼성·SK·한화·CJ·LG 때 이 트레이드오프는 전부 **사용자 결정**
-- 으로 처리됐으므로(2026-07-23 · 2026-07-29), 이 세션에서 임의로 넣지 않았다.
--
-- ⓘ 넣기로 결정하면 아래 한 줄이면 된다(SED-5 통과 — 이 도메인은 파일 내 유일):
--     INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
--       SELECT COMP_ID, 'oneduksan.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'duksan_neolux';
--   그리고 덕산 계열사를 추가하는 날 IN (...) 으로 합쳐야 한다(위 "1사짜리 그룹 도메인" 문단).
--   ⚠ 등록 전에 egress 가 열린 환경에서 위 두 근거를 **직접 열어 재확인**하라. 스니펫만 보고
--     넣으면 이 파일이 지금까지 지켜 온 기준을 우리 손으로 깨는 것이다.
--
-- ⓘ dsnl.co.kr 은 계속 채택 불가다. 자체 MX 는 있으나 게시된 주소가 0건이고, 임직원 메일이
--   oneduksan.com 에 있다는 위 정황은 오히려 **반증 쪽 근거**다(채용 접수함마저 그쪽이다).
-- ═══════════════════════════════════════════════════════════════════════════════


-- ── 회사 전용 도메인 — 대기업 계열 ───────────────────────────────────────
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'hyundai-rotem.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_rotem';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'doosanenerbility.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'doosan_enerbility';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'hyundai-autoever.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_autoever';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'hyundai-steel.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_steel';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'hyundaimovex.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_muvex';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'glovis.net', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_glovis';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 's-oil.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 's_oil';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'lottechem.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'lotte_chem';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'lgdisplay.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'lg_display';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'lsholdings.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'ls';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'hmm21.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'hmm';
-- LIG넥스원은 2026-03-31 주총에서 **LIG 디펜스&에어로스페이스(LIG D&A)** 로 사명이 바뀌었다.
-- ⚠ 구 도메인 `lignex1.com` 은 **일부러 넣지 않았다**(사용자 결정 2026-07-29). MX 가 ligdna.com 과
--    완전히 동일(sniper01/02.ligdefenseaerospace.com)해 회사 소유는 확실하지만, 게시된 이메일이
--    0건이라 "게시된 주소만 채택" 기준을 지켰다. 사명변경 4개월차라 구 주소 사용자는 422 →
--    수동 승인으로 간다. 인증 실패 문의가 쌓이면 재검토 1순위다.
-- @rejected: lignex1.com — LIG D&A 구 도메인. 회사 소유는 확실하나 게시된 이메일 0건
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'ligdna.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'lig_nex1';

-- ── 회사 전용 도메인 — 금융 ──────────────────────────────────────────────
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'dbins.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'db_insurance';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'nhqv.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'nh_invest';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'ibk.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'ibk';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'kakaopaycorp.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'kakao_pay';

-- ── 회사 전용 도메인 — 게임·소비재 ───────────────────────────────────────
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'neowiz.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'neowiz';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'doubleugames.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'wgames';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  -- ⚠ com2us.com 은 **컴투스홀딩스(별개 법인)도 함께 쓴다** — 적대검증 실측:
  --    컴투스홀딩스 정책에 `C2Sholdings_privacy@com2us.com` 이 있다(로컬파트 접두사만 다름).
  --    홀딩스는 아직 우리 목록에 없어 지금은 전부 컴투스로 인증된다. 추가하면 IN(...) 으로 합칠 것.
  SELECT COMP_ID, 'com2us.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'com2us';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'coway.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'coway';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'siliconii.net', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'silicon2';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'apr-in.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'apr';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'ifamilysc.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'ifamilysc';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'rainbow-robotics.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'rainbow_robotics';

-- ── 회사 전용 도메인 — 반도체 장비·계측 ──────────────────────────────────
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'leeno.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'lino';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'eugenetech.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'eugenetech';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'jusung.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'jusung';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'techwing.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'techwing';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'hanmisemi.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'hanmi_semi';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'parksystems.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'park_systems';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'eotechnics.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'eo_technics';

-- ── 회사 전용 도메인 — 반도체·디스플레이 소재·부품 ───────────────────────
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'nepes.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'nepes';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'soulbrain.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'soulbrain';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'tck.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'tck';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'bhe.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'bh';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'mcnex.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'mcnex';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'telechips.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'telechips';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'enchem.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'enchem';

-- ── 회사 전용 도메인 — 바이오·제약·의료기기 ──────────────────────────────
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'alteogen.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'alteogen';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'voronoi.io', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'voronoi';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'oscotec.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'oscotec';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'olixpharma.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'olix';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'genomecom.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'genome_company';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'jlkgroup.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'jlk';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'yuhan.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'yuhan';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'scd.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'samchundang';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'i-sens.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'isens';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'remed.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'remed';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'classys.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'classys';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'pharmaresearch.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'pharma_research';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'hugel-inc.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'hugel';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'caregen.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'caregen';

-- ── 한화 그룹 공용 도메인 hanwha.com → 계열 4사(그룹단위 인증) ──────────────────
-- ㈜한화·시스템·에어로스페이스·오션이 각각 다른 웹사이트(hanwhacorp.co.kr /
-- hanwhasystems.com / hanwhaaerospace.com / hanwhaocean.com)를 쓰면서 게시된 이메일은
-- 전부 @hanwha.com 이었다. 삼성·SK 와 동일한 그룹단위 매핑이다(사용자 결정 2026-07-29).
-- ⚠ 도메인만으로는 계열사를 구분할 수 없다 — "한화 계열 재직자"까지만 판별된다.
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'hanwha.com', TRUE FROM TCOMPANY
   WHERE COMP_ENG_NM IN ('hanwha','hanwha_systems','hanwha_aerospace','hanwha_ocean');

-- ── 에코프로 그룹 공용 도메인 ecopro.co.kr → 지주·비엠(그룹단위 인증) ────────────
-- 지주 개인정보처리방침이 10개 계열사 CPO 를 각각 이름·직책과 함께 나열하는데 **이메일은
-- 전부 security@ecopro.co.kr** 이다. 에코프로비엠 자체 도메인(ecoprobm.com)은 전 페이지에
-- 게시 이메일이 0건이라 채택하지 않았다.
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'ecopro.co.kr', TRUE FROM TCOMPANY
   WHERE COMP_ENG_NM IN ('ecopro','ecopro_bm');

-- ── 그룹 공용 도메인 — 우리 목록엔 계열사가 1곳뿐인 경우 ─────────────────────────
-- 아래 5건은 그룹 전체가 쓰는 도메인인데 그 그룹에서 우리가 다루는 회사가 하나뿐이다.
-- 즉 **그 그룹의 다른 계열사 직원도 이 회사로 인증될 수 있다.** 삼성·SK·한화와 같은
-- 트레이드오프를 감수한 사용자 결정(2026-07-29)이다.
-- 완화: uq_employ_email 이 **전역 유니크**라 한 회사 이메일 주소는 평생 한 회사만 인증할 수
-- 있고, 편집 이력은 공개된다.
--
-- ⚠ cj.net 은 적대검증에서 **가장 심한 사례로 실측됐다**(다시 조사하지 마라):
--    CJ제일제당 theprivacy@ · CJ대한통운 건설부문 cjenc@ + 실명 개인 메일박스
--    jaiwoong.lee@ · CJ올리브영 oliveweb@ · 그룹 통합채용(18개 계열사) sangyoon.kim@ 등
--    **최소 5개 법인이 공유**하고 타 계열사 임직원의 개인 계정이 여기 있다.
--    CJ올리브네트웍스 전용 메일 도메인은 없다(cjolivenetworks.co.kr 은 MX 부재).
--    → 지금은 목록에 CJ 계열이 이 회사뿐이라 @cj.net 인증이 **전부 여기로 온다**.
--      CJ 계열사가 추가되면 IN(...) 으로 합쳐 삼성·SK 와 같은 그룹단위 인증이 된다.
--
-- ⚠ 해당 그룹의 다른 계열사를 나중에 추가하면 이 줄들을 IN(...) 으로 합쳐야 한다
--    (SED-5 가드가 단일 선언 도메인의 중복 매핑을 막는다).
--
-- 참고 — lg.com 은 반증검증을 통과했다: LG 정도경영 사이트가 계열사 연락처를 전수 열거하는데
-- 15개 계열사가 전부 자기 도메인(LG전자 ethics@lge.com 등)이고 @lg.com 은 지주 그룹조직
-- 1건뿐이다. lg.com 과 lge.com 은 메일 인프라(MX·SPF 대역)도 완전히 분리돼 있다.
-- ⚠ 단 lg.com 은 **"웹" 도메인으로는 그룹 공용**이다(www.lg.com = LG전자 글로벌 브랜드
--    사이트, careers.lg.com = 통합채용). 웹 근거만 보면 판단이 뒤집힌다 — 메일 인프라로 판단하라.
-- cj.net → CJ 계열 8개사(2026-07-30 병합). 그전엔 CJ올리브네트웍스 1개사뿐이라 **@cj.net 인증이
-- 전부 그 회사로 갔다** — 목록에 선택지가 없었기 때문이다. CJ 계열사를 추가하면서 IN(...) 으로
-- 합쳐, 이제 삼성(samsung.com 7사)·SK(sk.com 3사)와 같은 그룹단위 인증이 된다.
-- 오매핑 비율이 18사 중 1사 → 18사 중 8사로 개선됐다(여전히 완전하지 않다는 점은 위 주석 참조).
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'cj.net', TRUE FROM TCOMPANY
   WHERE COMP_ENG_NM IN ('cj','cj_enm_ent','cj_enm_com','cj_freshway',
                         'cj_oliveyoung','cj_logistics','cj_cheiljedang','cj_cgv');
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'lg.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'lg';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'hyosung.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'hyosung_heavy';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'doosan.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'doosan';
-- 롯데케미칼은 자체 도메인(lottechem.com, 위)과 그룹 도메인을 **병행**한다 — 대외 역할주소는
-- @lottechem.com, 임직원 실계정은 @lotte.net 에 있다(자사 e-Sales 처리방침 게시).
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'lotte.net', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'lotte_chem';
