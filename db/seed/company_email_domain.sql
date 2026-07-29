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
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'cj.net', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'cj';
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
