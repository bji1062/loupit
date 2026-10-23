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
                         'samsung_life','samsung_electro','samsung_card',
                         -- 확장 웨이브 2(2026-09-05): 관측 주소가 전부 @samsung.com
                         -- (shi.is@ · 그룹 채용문의 · sdsjobs@/joinsds@ · recruit.sena@)
                         'samsung_heavy','samsung_fire','samsung_sds','samsung_ena',
                         -- 확장 웨이브 3(2026-09-14): 삼성증권 관측 주소 ss.recruit@samsung.com(자기 도메인 경력채용·samsungcareers E40)
                         'samsung_sec',
                         -- 확장 웨이브 6(2026-10-17): 에스원 관측 주소가 전부 @samsung.com(samsungcareers E80 채용 문의 · 2025 보고서 IR 문의 — 역할 주소)
                         's1',
                         -- 확장 웨이브 7(2026-10-17): 제일기획 — 사용자 그룹 단위 인증 결정(삼성 계열 전부 samsung.com). 전용 도메인 cheil.com 은 아래 단일 줄
                         'cheil_worldwide',
                         -- 확장 웨이브 9(2026-10-31): 호텔신라 — samsungcareers E50 채용 문의 주소가 @samsung.com(삼성 그룹 단위 인증). 자기 메일 도메인 관측 0
                         'hotel_shilla',
                         -- 확장 웨이브 15(2026-11-03): 세메스(채용 사이트 개인정보 안내 @semes.com · MX mailin.samsung.com) · 멀티캠퍼스(채용 사이트 꼬리말 @multicampus.com · MX mailin.samsung.com) — 삼성 그룹 단위 인증 · 전용 도메인은 아래 단일 줄
                         'semes','multicampus');

-- ── SK 그룹 공용 도메인 sk.com → 전 계열사(그룹단위 인증) ─────────────────────────
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'sk.com', TRUE FROM TCOMPANY
   WHERE COMP_ENG_NM IN ('sk_hynix','skt','sk_innovation',
                         -- 확장 웨이브 3(2026-09-14): SK바이오팜 관측 주소 skbp_comm@sk.com(skbp.com 푸터, MX spmail.sk.com)
                         'sk_biopharm',
                         -- 확장 웨이브 6(2026-10-17): SK케미칼 2025 지속가능경영보고서 문의처 @sk.com(자기 도메인 skchemicals.com 의 MX 도 spmail.sk.com)
                         'sk_chemicals',
                         -- 확장 웨이브 7(2026-10-17): SK바이오사이언스 — 사용자 그룹 단위 인증 결정. 자기 웹 도메인 skbioscience.com 은 MX 가 없다(메일 미수신)
                         'sk_bioscience',
                         -- 확장 웨이브 8(2026-10-24): SK가스 2025 지속가능경영보고서 문의처 @sk.com · 자기 웹 도메인 skgas.co.kr 의 MX 도 spmail.sk.com
                         'sk_gas',
                         -- 확장 웨이브 9(2026-10-31): SK네트웍스 개인정보처리방침 · 보고서 문의처 @sk.com · 자기 웹 도메인 sknetworks.co.kr 의 MX 도 spmail.sk.com
                         'sk_networks',
                         -- 확장 웨이브 10(2026-11-07): SKC 2026 지속가능경영보고서 문의처 @sk.com · 자기 웹 도메인 skc.kr · skc.co.kr 의 MX 도 spmail.sk.com
                         'skc',
                         -- 확장 웨이브 13(2026-10-20): SK온 공식 홈 개인정보 관련 담당자 표 관측 주소 @sk.com · 자기 웹 도메인 sk-on.com 의 MX 도 spmail.sk.com
                         'sk_on',
                         -- 확장 웨이브 15(2026-11-03): SK에코플랜트 · SK실트론 보고서 문의처 @sk.com · SK에너지는 게시 주소 0 이나 웹 skenergy.com 의 MX 가 spmail.sk.com(그룹 단위 인증 · SK바이오사이언스 선례) · skecoplant.com MX 도 spmail.sk.com
                         'sk_ecoplant','sk_siltron','sk_energy');

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
  SELECT COMP_ID, 'hmm21.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'hmm';
-- LIG넥스원은 2026-03-31 주총에서 **LIG 디펜스&에어로스페이스(LIG D&A)** 로 사명이 바뀌었다.
-- 도메인 2개(사용자 결정 2026-09-27 — 2026-07-29 의 lignex1.com 보류를 뒤집는다):
--   · ligdna.com — 기존 등록(게시된 이메일 기준으로 채택).
--   · lignex1.com — 사명 변경 전 도메인. MX 가 ligdna.com 과 완전히 같다(sniper01/02.ligdefenseaerospace.com)
--     — 회사 소유가 확실하다. 옛 보류 사유는 게시된 이메일 0건이었다. 구 주소를 아직 쓰는 임직원이
--     422 → 수동 승인으로 빠지던 것을 도메인 인증으로 돌린다.
-- ⚠ ligdefenseaerospace.com 은 회사 소유(NS prmns/secns.lg.co.kr · SPF 가 ligdna.com 과 글자까지 같다 · 공식
--    홈페이지 도메인)지만 MX 가 도메인 없는 sniper01. · sniper02. 로 잘못 설정돼 지금 인터넷 메일을 받지 못한다
--    (2026-09-27 dig 실측). 등록하면 인증 코드가 반송되고 그 주소가 발송 차단에 올라 막힌다 — 지금처럼 422 →
--    수동 승인이 낫다. MX 가 고쳐지면 다시 본다(사용자 결정 2026-09-27).
-- @rejected: ligdefenseaerospace.com — LIG D&A 소유 도메인이나 MX 가 도메인 없는 sniper01./sniper02. 로 잘못 설정돼 메일 수신 불가
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'ligdna.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'lig_nex1';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'lignex1.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'lig_nex1';

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
   WHERE COMP_ENG_NM IN ('hanwha','hanwha_systems','hanwha_aerospace','hanwha_ocean',
                         'hanwha_life',  -- 웨이브 2(2026-09-05): 관측 hli_IR@hanwha.com
                         -- 확장 웨이브 8(2026-10-24): 한화투자증권 인사제도 페이지 관련문의 · 2026 보고서 문의처 @hanwha.com · 웹 도메인 hanwhawm.com 의 MX 도 mx1.hanwha.com
                         'hanwha_inv_sec');

-- ── 에코프로 그룹 공용 도메인 ecopro.co.kr → 지주·비엠(그룹단위 인증) ────────────
-- 지주 개인정보처리방침이 10개 계열사 CPO 를 각각 이름·직책과 함께 나열하는데 **이메일은
-- 전부 security@ecopro.co.kr** 이다. 에코프로비엠 자체 도메인(ecoprobm.com)은 전 페이지에
-- 게시 이메일이 0건이라 채택하지 않았다.
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'ecopro.co.kr', TRUE FROM TCOMPANY
   WHERE COMP_ENG_NM IN ('ecopro','ecopro_bm',
                         -- 확장 웨이브 10(2026-11-07): 에코프로머티리얼즈 — 그룹 채용 사이트 문의처 @ecopro.co.kr · 자기 웹 도메인 ecopromaterials.com 의 MX 도 smf.ecoproep.com(ecopro.co.kr 과 같은 메일 서버) · 법인 자기 도메인 게시 주소 0
                         'ecopro_materials');

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
-- ⚠ 2026-10-01 LG 지주 회사 등록 해제(공식 복지 원문 없음)로 lg.com 매핑 줄도 함께 내렸다 — db/migrations/20261001_unregister_lg_holding.sql.
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'cj.net', TRUE FROM TCOMPANY
   WHERE COMP_ENG_NM IN ('cj','cj_enm_ent','cj_enm_com','cj_freshway',
                         'cj_oliveyoung','cj_logistics','cj_cheiljedang','cj_cgv');
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'hyosung.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'hyosung_heavy';
-- doosan.com → 두산 4사 그룹 단위 인증(사용자 2026-10-14 · 확장 웨이브 8 두산퓨얼셀 2026-10-24). @doosan.com 보유자는 두산 4사 어디로든 인증된다.
-- 두산에너빌리티는 전용 doosanenerbility.com 도 그대로 둔다.
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'doosan.com', TRUE FROM TCOMPANY
   WHERE COMP_ENG_NM IN ('doosan','doosan_enerbility','doosan_tesna','doosan_fuelcell');
-- 롯데케미칼은 자체 도메인(lottechem.com, 위)과 그룹 도메인을 **병행**한다 — 대외 역할주소는
-- @lottechem.com, 임직원 실계정은 @lotte.net 에 있다(자사 e-Sales 처리방침 게시).
-- 그룹 단위 인증(사용자 2026-10-14) · ⚠ 롯데렌탈은 최대주주 지분 매각 계약(2026-08-11 · 종결 전) — 종결되면 이 IN 목록에서 뺀다.
-- 확장 웨이브 9(2026-10-31): 롯데쇼핑(채용 FAQ · 보고서 문의처) · 롯데에너지머티리얼즈(보고서 제보 메일) 관측 주소가 @lotte.net. 롯데관광개발은 롯데그룹이 아니다 — 이 줄에 넣지 않는다.
-- 확장 웨이브 12(2026-10-18): 롯데하이마트(2025 지속가능경영보고서 문의처) 관측 주소가 @lotte.net · 웹 himart.co.kr 의 MX 도 antispam.lotte.net.
-- 확장 웨이브 14(2026-10-27): 호텔롯데(2025 지속가능성 보고서 ESG 문의처) · 롯데이노베이트(보고서 문의처 · 채용 문의 대표 주소) · 코리아세븐(개인정보처리방침 보호 책임자 · 담당 부서) 관측 주소가 @lotte.net.
-- 확장 웨이브 15(2026-11-03): 롯데건설(2026 지속가능경영보고서 문의처) · 롯데글로벌로지스(2025 지속가능경영보고서 문의처) 관측 주소가 @lotte.net.
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'lotte.net', TRUE FROM TCOMPANY
   WHERE COMP_ENG_NM IN ('lotte_chem','lotte_fine_chem','lotte_chilsung','lotte_rental','lotte_wellfood','lotte_shopping','lotte_energy_materials','lotte_himart','hotel_lotte','lotte_innovate','korea_seven','lotte_enc','lotte_glogis');

-- ── 확장 웨이브 1 (2026-09-01, 11개사 신규 등록 중 관측 6사) ─────────────────────
-- 근거: 각사 공식 페이지 실관측(docs/handoff/2026-09-01-evidence/wave1/ 각 evidence).
-- @rejected: wonik.com — 원익그룹 계열 공용 개연(관측 1건, ips.esg@wonik.com). 단독 등록 시
--            원익 계열사 추가에서 SED-5(같은 도메인 이중 선언) 충돌 — IN(...) 병합으로만 재검토.
-- @rejected: hankookn.com — 한국앤컴퍼니 그룹 공용(recruit@hankookn.com). 위와 동일 사유.
-- 미관측 3사(현대건설·LS ELECTRIC·하나마이크론): 공식 페이지 전수 스캔에서 이메일 0건 — 보류.
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'koreazinc.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'korea_zinc';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'lgcns.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'lg_cns';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'kbfg.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'kbfg';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'simmtech.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'simmtech';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'landf.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'landf';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'hd.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'hd_hyundai';

-- ═══════════════════════════════════════════════════════════════════════════════
-- 2026-09-05 확장 웨이브 2 — 신규 13개사 중 회사 전용 도메인 8 (삼성 4사·한화생명은 위 그룹 줄에 병합)
-- 근거는 각사 evidence(docs/handoff/2026-09-05-evidence/wave2/) 의 「이메일 도메인 관측」 절.
-- @rejected: lginnotek.co.kr — LG이노텍 구 도메인. 웹 호스트 사망·403, 메일 별칭만 문서에 잔존
-- @rejected: roundsquare.ai — 삼양식품. 삼양라운드스퀘어 그룹 주소(csteam@·information@)
-- @rejected: isu.co.kr — 이수페타시스. 이수그룹 공용 도메인(계열사 전 직원 사용 가능)
-- @rejected: nm-neo.com — 넷마블. 넷마블네오(자회사) 도메인 — nm-n2.com·nm-nexus.com 등 자회사 도메인 전부 동일 사유
-- ⚠ isupetasys.com 은 웹 호스트가 죽어 있으나(HTTP 타임아웃) MX 는 Google Workspace 로 살아 있고
--    Contact Us 에 주소 5건이 게시돼 있다 — CAREERS_BENEFIT_URL(petasys.com)과 혼동 금지.
-- ═══════════════════════════════════════════════════════════════════════════════
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'lginnotek.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'lg_innotek';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'daeduck.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'daeduck';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'isupetasys.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'isu_petasys';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'celltrionph.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'celltrion_pharm';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'netmarble.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'netmarble';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'dongjin.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'dongjin_semichem';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'samyangfoods.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'samyang_foods';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'koreaaero.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'kai';

-- ═══════════════════════════════════════════════════════════════════════════════
-- 2026-09-14 확장 웨이브 3 — 신규 12개사 중 회사 전용 도메인 8 (삼성증권·SK바이오팜은 위 그룹 줄에 병합)
-- 근거는 각사 evidence(docs/handoff/2026-09-14-evidence/wave3/) 의 「이메일 도메인 관측」 절 — 공식 사이트에 게시된 주소만.
-- 미관측 2: 포스코인터내셔널(poscointl.com MX 는 있으나 게시 주소 0) · 대한전선(taihan.com MX 는 있으나 게시 주소 0) → 수동 승인 폴백.
-- @rejected: ihoban.co.kr — 대한전선. 호반그룹 메일 게이트웨이(taihan.com MX) — 그룹 전 계열사가 인증될 수 있음
-- @rejected: posco.com — 포스코퓨처엠·포스코인터내셔널. POSCO 그룹 도메인(MX antispam.posco.net 공용)
-- @rejected: donga.co.kr — 에스티팜. 동아쏘시오그룹 메일 게이트웨이(stpharm.co.kr MX mailgw.donga.co.kr)
-- @rejected: lsworkplace.com — 가온전선. LS 그룹 공용 메일 게이트웨이(gaoncable.com·ls-electric.com·lsholdings.com MX 공통)
-- ⚠ douzone.com 은 채용 포털이 계열사(키컴·더존비앤씨티·더존에듀캠) 공고도 받는 구조라 계열사 직원 사용 여부 미확인 ·
--    lunit.io·seegene.com 은 해외 자회사 직원도 같은 도메인을 쓸 수 있음 · kiwoom.com 은 형제 법인 사용 여부 미확인.
-- ═══════════════════════════════════════════════════════════════════════════════
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'kiwoom.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'kiwoom';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'poscofuturem.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'posco_futurem';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'stpharm.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'stpharm';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'seegene.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'seegene';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'douzone.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'douzone';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'robotis.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'robotis';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'lunit.io', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'lunit';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'gaoncable.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'gaon_cable';

-- ── 확장 웨이브 4 (2026-09-20 서빙 반영, 12개사 중 10사) ────────────────────
-- 미등록 2사: GC녹십자(6페이지 전수 mailto 0건) · 농심(페이지가 이메일주소 무단수집 거부로 주소 미게재)
--             — 관측 0건이라 추정 등록하지 않는다(수동 승인 폴백).
-- ⚠ 웹 도메인과 메일 도메인이 다른 회사 3곳: 파두 fadu.io → fadutec.com ·
--    HL만도 hlmando.com(MX 없음) → hlcompany.com · 현대백화점 ehyundai.com → thehyundai.com
-- @rejected: innitent.com — JYP 채용 처리방침에 함께 있으나 INNIT Entertainment(별개 법인)
-- @rejected: pskholding.com — 피에스케이홀딩스(지주, 다른 법인)
-- @rejected: hlmando.com — HL만도 웹 도메인, MX 레코드 없음
-- @rejected: fadu.io — 파두 웹 도메인, 회사가 공표한 채용 주소는 fadutec.com
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'jype.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'jyp';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'dkpharm.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'dongkook_pharm';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'tse21.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'tse';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'jeju-semi.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'jeju_semi';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'fadutec.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'fadu';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'hlcompany.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'hl_mando';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'thehyundai.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_dept';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'emart.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'emart';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'pskinc.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'psk';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'poongsan.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'poongsan';

-- ═══════════════════════════════════════════════════════════════════════════════
-- 확장 웨이브 5 (2026-10-10 서빙 반영, 13개사 중 9사)
-- 근거는 각사 evidence(loupit-evidence/2026-10-10-wave5/collect/ 의 이메일 도메인 관측 절) — 공식 페이지 · 보고서에 게시된 주소만.
-- 미등록 4사: 현대해상(주소 관측 0 — MX hi.co.kr 만) · ISC(ISC 주소 관측 0 — MX isc21.kr 만) ·
--             한솔케미칼 · 코오롱인더스트리(관측 주소가 그룹 공용 도메인뿐) — 수동 승인 폴백.
-- @rejected: hansol.com — 한솔케미칼. 한솔그룹 공용 도메인(지주 문의처도 같은 도메인) — 계열사 전 직원이 인증될 수 있음
-- @rejected: kolon.com — 코오롱인더스트리. 코오롱그룹 공용 도메인(웹 도메인 kolonindustries.com · kolonfnc.com 과 다름)
-- ISC 는 위 SK 그룹 줄(sk.com)에 넣지 않는다 — 관측 주소 skc.ethics@sk.com 은 모회사 SKC 감사실이라 ISC 직원 도메인 근거가 아니다
-- ⚠ orionworld.com · kolmar.co.kr · cosmax.com 은 법인 자기 사이트 도메인이지만 지주 · 형제 법인(오리온홀딩스 ·
--    콜마홀딩스 · 코스맥스비티아이 등)도 쓸 수 있다 — 형제가 코퍼스에 들어오면 다시 본다.
-- ⚠ gsenc.com 의 MX 에 옛 도메인 gsconst.co.kr 게이트웨이가 함께 있다 — 재직 인증 도메인은 gsenc.com.
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'otoki.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'ottogi';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'kccworld.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'kcc';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'orionworld.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'orion';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'gsenc.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'gs_enc';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'hanonsystems.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'hanon_systems';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'slworld.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'sl_corp';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'sanil.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'sanil_electric';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'kolmar.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'kolmar_korea';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'cosmax.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'cosmax';

-- ═══════════════════════════════════════════════════════════════════════════════
-- 확장 웨이브 6 (2026-10-17 서빙 반영, 13개사 중 전용 9사 + 그룹 줄 병합 2사)
-- 근거는 각사 evidence(docs/handoff/2026-10-14-evidence/wave6/ 의 이메일 도메인 관측 절) — 공식 페이지 · 보고서에 게시된 주소만.
-- 그룹 줄 병합: 에스원 → 위 삼성 그룹 줄(samsung.com) · SK케미칼 → 위 SK 그룹 줄(sk.com).
-- 미등록 2사: 이수스페셜티케미컬(게시 주소 0) · BGF리테일(관측 주소가 그룹 공용 도메인뿐 — 웹 도메인 bgfretail.com 은 MX 없음) — 수동 승인 폴백.
-- @rejected: bgf.co.kr — BGF리테일. BGF그룹 지주 · 공용 도메인(보고서 ESG팀 주소) — 계열사 전 직원이 BGF리테일 재직자로 인증될 수 있음
-- ⚠ daewoong.co.kr · paradian.com · kkpc.com 은 법인이 게시한 주소지만 지주 · 형제 법인(㈜대웅 · 대웅바이오 / 파라다이스시티 · 호텔 부산 /
--    금호석유화학 계열사)도 쓸 수 있다 — 형제가 코퍼스에 들어오면 다시 본다(웨이브 5 orionworld.com · kolmar.co.kr 주석과 같은 처리).
-- ⓘ s1.co.kr(에스원) · skchemicals.com(SK케미칼)은 MX 가 있으나 게시된 주소가 0이라 넣지 않았다.
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'hyundai-wia.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_wia';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'daewoong.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'daewoong_pharm';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'bing.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'binggrae';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'hjsc.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'hj_heavy';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'sfasemicon.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'sfa_semicon';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'gbattery.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'sebang_battery';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'paradian.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'paradise';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'kkpc.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'kumho_petrochemical';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'gsretail.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'gs_retail';

-- ═══════════════════════════════════════════════════════════════════════════════
-- 확장 웨이브 7 (2026-10-17 서빙 반영, 22개사 중 전용 16사 + 그룹 줄 병합 2사)
-- 근거는 각사 evidence(loupit-evidence/2026-10-14-wave7/collect/ 의 이메일 도메인 관측 절) — 공식 페이지 · 보고서에 게시된 주소의 도메인만.
-- 그룹 줄 병합: 제일기획 → 위 삼성 그룹 줄(samsung.com) · SK바이오사이언스 → 위 SK 그룹 줄(sk.com) ·
--   롯데 3사(롯데정밀화학 · 롯데칠성음료 · 롯데렌탈) → 위 롯데 그룹 줄(lotte.net) · 두산테스나 → 위 두산 그룹 줄(doosan.com) (사용자 2026-10-14).
-- 미등록 1사(수동 승인 폴백): F&F(관측 주소가 지주 F&F홀딩스 명의 fnfcorp.com 뿐).
-- @rejected: fnfcorp.com — F&F. 지주 F&F홀딩스 명의 보고서 문의처 도메인 — 지주 · 계열 공용으로 보여 계열 전 직원이 F&F 재직자로 인증될 수 있음
-- @rejected: kct.co.kr — 케이씨텍. KC 그룹 · 분할 존속 지주 쪽 Family Site 도메인(채택본은 kctech.co.kr)
-- ⓘ fnf.co.kr(F&F) · tesna.co.kr(두산테스나) · lottechilsung.co.kr(롯데칠성음료)은 MX 가 있으나 게시된 주소가 0이라 넣지 않았다.
-- ⚠ kdiwin.com(경동나비엔)은 법인 웹 도메인 kdnavien.co.kr 의 메일도 받는 인프라 도메인이고 법인 팀이 게시한 주소다 — 경동 계열(경동원 등)과
--    공용일 수 있다. boryung.co.kr 도 지주 보령홀딩스와 같은 apex 일 수 있다. 형제가 코퍼스에 들어오면 다시 본다(웨이브 6 daewoong.co.kr 주석과 같은 처리).
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'boryung.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'boryung';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'inno-n.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'hk_inno_n';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'kctech.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'kctech';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'innocean.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'innocean';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'hyundaielevator.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_elevator';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'iprovest.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'kyobo_securities';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'kdiwin.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'kyungdong_navien';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'ahnlab.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'ahnlab';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'cheil.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'cheil_worldwide';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'hanamts.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'hana_materials';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'cosmecca.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'cosmecca_korea';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'hanssem.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'hanssem';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'koreanre.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'korean_re';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'lxintl.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'lx_international';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'kumhotire.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'kumho_tire';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'komico.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'komico';

-- ═══════════════════════════════════════════════════════════════════════════════
-- 확장 웨이브 8 (2026-10-24 서빙 반영, 23개사 중 전용 9사 10도메인 + 그룹 줄 병합 4사)
-- 근거는 각사 evidence(loupit-evidence/2026-10-15-wave8/collect/ 의 이메일 도메인 관측 절) — 공식 페이지 · 보고서에 게시된 주소의 도메인만.
-- 그룹 줄 병합: SK가스 → 위 SK 그룹 줄(sk.com) · 두산퓨얼셀 → 위 두산 그룹 줄(doosan.com) · 롯데웰푸드 → 위 롯데 그룹 줄(lotte.net) ·
--   한화투자증권 → 위 한화 그룹 줄(hanwha.com).
-- 미등록 10사(수동 승인 폴백): STX엔진 · 한국카본 · 신영증권 · DL이앤씨(게시된 주소 0 — MX 만 있음) ·
--   한일시멘트 · 미래에셋생명 · 일진전기 · 삼화콘덴서공업 · NICE평가정보 · 후성(관측 주소가 그룹 · 지주 공용 도메인뿐 — 코퍼스에 그 그룹 계열이 하나뿐).
-- @rejected: hanil.com — 한일시멘트. 지주 한일홀딩스 웹 도메인(그룹 · 지주 공용) — 코퍼스 한일 계열 1사라 그룹 줄을 만들지 않는다
-- @rejected: miraeasset.com — 미래에셋생명. 미래에셋 그룹 apex 공용 도메인 — 코퍼스 미래에셋 계열 1사라 그룹 줄을 만들지 않는다
-- @rejected: iljin.co.kr — 일진전기. 일진 그룹(일진홀딩스) 공용 도메인 · 자기 웹 iljinelectric.co.kr 은 MX 없음 — 코퍼스 일진 계열 1사
-- @rejected: samwha.com — 삼화콘덴서공업. 삼화 그룹 공용 웹 · 메일 도메인(계열 /capacitor · /electric · /electronics) — 코퍼스 삼화 계열 1사
-- @rejected: nice.co.kr — NICE평가정보. NICE 그룹 정도경영실이 같은 도메인을 쓰는 그룹 공용 도메인 — 코퍼스 NICE 계열 1사
-- @rejected: foosung.com — 후성. 후성그룹 사이트 도메인(그룹 공용 메일로 보임) · 자기 웹 foosungchem.com 은 MX 없음 — 코퍼스 후성 계열 1사
-- ⓘ stxengine.co.kr · hcarbon.com · shinyoung.com · dlenc.co.kr · niceinfo.co.kr 은 MX 가 있으나 게시된 주소가 0이라 넣지 않았다.
-- ⓘ poscodx.com 은 포스코 그룹 메일 게이트웨이(antispam.posco.net)를 거치지만 주소 도메인은 법인 고유다(웨이브 7 inno-n.com 과 같은 처리).
-- ⓘ 달바글로벌은 같은 법인이 dalbaglobal.com(채용) · dalba.com(공식 홈 문의) 두 도메인을 쓴다 — 둘 다 같은 네이버웍스 MX.
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'daou.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'daou_tech';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'dalbaglobal.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'dalba_global';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'dalba.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'dalba_global';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'poscodx.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'posco_dx';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'sntmotiv.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'snt_motiv';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'inbody.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'inbody';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'haesungds.net', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'haesung_ds';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'sdbiosensor.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'sd_biosensor';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'shiftup.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'shift_up';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'sfa.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'sfa';

-- ═══════════════════════════════════════════════════════════════════════════════
-- 확장 웨이브 9 (2026-10-31 서빙 반영, 22개사 중 전용 12사 12도메인 + 그룹 줄 병합 4사)
-- 근거는 각사 evidence(loupit-evidence/2026-10-15-wave9/collect/ 의 이메일 도메인 관측 절) — 공식 페이지 · 보고서 · 공고에 게시된 주소의 도메인만.
-- 그룹 줄 병합: 호텔신라 → 위 삼성 그룹 줄(samsung.com) · SK네트웍스 → 위 SK 그룹 줄(sk.com) ·
--   롯데쇼핑 · 롯데에너지머티리얼즈 → 위 롯데 그룹 줄(lotte.net).
-- 미등록 6사(수동 승인 폴백): DN오토모티브(게시된 주소 0) ·
--   HS효성첨단소재 · 영원무역 · 대신증권 · 차바이오텍 · 삼표시멘트(관측 주소가 그룹 · 지주 공용 도메인뿐 — 코퍼스에 그 그룹 계열이 하나뿐).
-- @rejected: hshyosung.com — HS효성첨단소재. 지주 HS효성 그룹 도메인(보고서 문의처) · 법인 웹 도메인 메일 주소 관측 0 — 코퍼스 HS효성 계열 1사
-- @rejected: youngone.com — 영원무역. 지주 영원무역홀딩스와 함께 쓰는 도메인(개인정보 제보처가 홀딩스 IT팀) — 코퍼스 영원 계열 1사
-- @rejected: daishin.com — 대신증권. 대신파이낸셜그룹 계열 사이트가 함께 쓰는 apex 도메인(company.daishin.com/group) — 코퍼스 대신 계열 1사
-- @rejected: chamc.co.kr — 차바이오텍. 차병원 그룹 도메인(개인정보처리방침) · 법인 고유 주소 관측 0 — 코퍼스 차 계열 1사
-- @rejected: sampyo.co.kr — 삼표시멘트. 삼표그룹 홈 도메인(보고서 문의처) · 법인 웹 sampyocement.co.kr 은 MX 없음 — 코퍼스 삼표 계열 1사
-- ⓘ chabio.com 은 MX 가 있으나 게시된 주소가 0이라 넣지 않았다. dnautomotive.com 은 DN 그룹 메일 서버를 쓰고 게시된 주소가 0이다.
-- ⓘ 웹 도메인 ≠ 메일 도메인: IPARK현대산업개발(ipark-dvp.com 웹 · hdc-dvp.com 메일 — 2025 사명 변경 전 이름) · 와이지엔터테인먼트(ygfamily.com 웹 · ygmail.net 메일) ·
--   LS마린솔루션(lsmarinesolution.co.kr 웹 MX 없음 · lsms.co.kr 메일 — LS 그룹 메일 호스팅 lsworkplace.com 을 거치지만 주소 도메인은 법인 고유) ·
--   롯데관광개발(lottetour.edk.ai 보고서 · jejudreamtower.com 메일).
-- ⚠ ygmail.net — 와이지엔터테인먼트 보고서 문의처. YG 계열(YG PLUS 등)과 함께 쓰는지 확인하지 못했다 — 계열 직원도 이 회사로 인증될 수 있다.
-- ⚠ hisnt.com — SNT에너지 공고 제출처 · 자기 웹 도메인. SNT 형제는 각자 도메인(sntmotiv.com · hisntd.com)이나 지주 쪽 사용 여부는 확인하지 못했다.
-- ⚠ jejudreamtower.com — 롯데관광개발 보고서 문의처(ESG팀). 제주 드림타워를 함께 운영하는 자회사 엘티엔터테인먼트(미등록) 직원도 같은 도메인을 쓸 수 있다.
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'taekwang.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'taekwang_ind';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'panocean.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'pan_ocean';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'daehanship.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'daehan_shipbuilding';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'ypzinc.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'youngpoong';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'hdc-dvp.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'ipark_hdc';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'ygmail.net', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'yg_entertainment';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'nexongames.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'nexon_games';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'robostar.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'robostar';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'lsms.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'ls_marine_solution';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'hisnt.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'snt_energy';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'hisntd.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'snt_dynamics';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'jejudreamtower.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'lotte_tour';

-- ═══════════════════════════════════════════════════════════════════════════════
-- 확장 웨이브 10 (2026-11-07 서빙 반영, 12개사 중 전용 4사 4도메인 + 그룹 줄 병합 2사)
-- 근거는 각사 evidence(loupit-evidence/2026-10-15-wave10/collect/ 의 이메일 도메인 관측 절) — 공식 페이지 · 보고서에 게시된 주소의 도메인만.
-- 그룹 줄 병합: SKC → 위 SK 그룹 줄(sk.com) · 에코프로머티리얼즈 → 위 에코프로 그룹 줄(ecopro.co.kr).
-- 미등록 6사(수동 승인 폴백): 동원산업 · 코스모신소재 · 씨에스윈드(게시된 주소 0) · SGC에너지(관측 주소가 그룹 공용 도메인뿐 — 코퍼스 SGC 계열 1사) ·
--   원익QnC(관측 주소가 원익 계열 공용 wonik.com 뿐 — 위 확장 웨이브 1 보류 줄 그대로) · 효성티앤씨(관측 주소가 hyosung.com 뿐 — 위 효성중공업 줄의 도메인).
-- @rejected: sgc.co.kr — SGC에너지. SGC그룹 홈 도메인(보고서 문의처 · MX ocigw.net) · 법인 웹 sgcenergy.co.kr 은 MX 없음 — 코퍼스 SGC 계열 1사
-- ⓘ wonik.com(원익QnC 개인정보처리방침 관측 · 웹 wonikqnc.com 의 MX 도 mail.wonik.com)은 위 확장 웨이브 1 보류 줄(원익IPS 관측)과 같은 도메인이다.
--   원익 계열이 코퍼스에 둘(원익IPS · 원익QnC)이 됐지만 그룹 단위 인증은 사용자 결정 전이라 넣지 않는다(넣으려면 보류 줄을 지우고 IN 한 문장으로).
-- ⓘ hyosung.com(효성티앤씨 보고서 문의처 · 웹 hyosungtnc.com 의 MX 도 smtpi.hyosung.com)은 위 효성중공업 단일 줄의 도메인이다 — 효성 계열 공용으로 보이나
--   그룹 단위 인증은 사용자 결정 전이라 이 회사를 넣지 않는다(지금 hyosung.com 보유자는 효성중공업으로만 자동 인증된다 · 넣으려면 그 줄을 IN 한 문장으로).
-- ⓘ dongwon.com · cswind.com · cosmoamt.com 은 MX 가 있으나 게시된 주소가 0이라 넣지 않았다. 한올바이오파마 웹 도메인 hanall.com 도 게시 주소 0 — 채택본은 보고서 문의처 hanall.co.kr.
-- ⓘ lsmaterials.co.kr 은 LS 그룹 메일 호스팅 lsworkplace.com 을 거치지만 주소 도메인은 법인 고유다(웨이브 9 lsms.co.kr 과 같은 처리).
-- ⚠ gst-in.com — GST 개인정보처리방침 · 자기 웹 도메인. 사이트에 그룹 계열사 메뉴가 있으나 계열사가 같은 메일 도메인을 쓰는지는 확인하지 못했다.
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'daejoo.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'daejoo_electronic';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'hanall.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'hanall_biopharma';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'gst-in.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'gst';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'lsmaterials.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'ls_materials';

-- ═══════════════════════════════════════════════════════════════════════════════
-- 확장 웨이브 11 붙여넣기 1차 (2026-10-16 서빙 반영, 5개사 중 전용 3사 3도메인 · 그룹 줄 병합 0)
-- 근거는 각사 evidence(loupit-evidence/2026-10-16-paste1/collect/ 의 이메일 도메인 관측 절 · 앞 웨이브 근거표) — 공식 페이지 · 보고서에 게시된 주소의 도메인만.
-- 미등록 2사(수동 승인 폴백): 케이뱅크(게시된 주소 0 — 웹 kbanknow.com 은 MX 가 있으나 관측 0) · 한화손해보험(게시된 주소 0 — 웹 hwgeneralins.com 의 MX 는 자체 smtp.hwgeneralins.com).
-- ⓘ 한화손해보험 · 쎄트렉아이는 한화 계열이지만 위 한화 그룹 줄(hanwha.com)에 넣지 않았다 — 두 회사 모두 hanwha.com 관측 0 · 쎄트렉아이 관측 주소는 자기 도메인 satreci.com(MX gw2023.satreci.com).
-- ⓘ lghnh.com 은 LG 그룹 채용 사이트 개인정보 문의처 표의 LG생활건강 줄(부서 공용 메일함)에서 관측 · MX shield.lgcare.co.kr(lg.com 의 spam.lg.com 과 다른 메일 서버).
-- ⚠ lghnh.com — LG생활건강 종속회사(코카콜라음료 등)가 같은 메일 도메인을 쓰는지는 확인하지 못했다.
-- ⓘ ckdpharm.com 은 종근당 개인정보처리방침 관측 · MX sniper.ckdpharm.com(지주 종근당홀딩스 ckd-holdings.com 의 sniper.ckd-holdings.com 과 다른 메일 서버).
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'ckdpharm.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'chongkundang';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'lghnh.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'lg_hnh';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'satreci.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'satrec_i';

-- ═══════════════════════════════════════════════════════════════════════════════
-- 확장 웨이브 12 (2026-10-18 서빙 반영, 18개사 중 전용 14사 14도메인 + 그룹 줄 병합 1사)
-- 근거는 각사 evidence(loupit-evidence/2026-10-18-wave12/collect/ 의 이메일 도메인 관측 절) — 공식 페이지 · 보고서 · 공고에 게시된 주소의 도메인만.
-- 그룹 줄 병합: 롯데하이마트 → 위 롯데 그룹 줄(lotte.net — 2025 지속가능경영보고서 문의처 관측 · 웹 himart.co.kr 의 MX 도 antispam.lotte.net 을 거친다).
-- 미등록 3사(수동 승인 폴백): 매일유업 · 트리니티항공(게시된 주소 0 — maeil.com · trinityairways.com · twayair.com 은 MX 만 있음) ·
--   동아에스티(관측 주소가 위 확장 웨이브 3 보류 줄의 donga.co.kr 뿐 — 동아쏘시오그룹 메일 게이트웨이 mailgw.donga.co.kr 를 donga-st.com · stpharm.co.kr 도 함께 쓴다).
-- ⓘ 웹 도메인과 메일 도메인이 다른 곳: 하나투어(웹 hanatourcompany.com · 메일 hanatour.com) · SM엔터테인먼트(웹 smentertainment.com · 메일 smtown.com) ·
--   대교(웹 daekyo.com 의 MX 는 Microsoft 365 · 관측 주소는 daekyo.co.kr) · LX하우시스(국문 웹 lxhausys.co.kr · 메일 lxhausys.com).
-- ⓘ megastudy.net(메가스터디교육 채용 FAQ 관측)은 넣지 않았다 — megastudyedu.com 과 다른 메일 계통(spam.megastudy.net)이고 별개 법인 메가스터디(주)와 공용인지 확인하지 못했다.
-- ⓘ daesang.co.kr(DART 홈)도 MX 가 sniper.daesang.com 으로 같으나 관측 주소는 daesang.com 뿐이라 그것만 넣었다.
-- ⚠ aekyung.kr — 애경산업 채용 사이트 문의처 · 웹 aekyung.co.kr 의 MX 도 aekyung.kr 계통. 애경그룹 다른 계열사(코퍼스 제주항공은 jejuair.net)가 같은 메일 도메인을 쓰는지는 확인하지 못했다.
-- ⚠ daekyo.co.kr · smtown.com — 대교 · SM엔터테인먼트 계열사(대교홀딩스 계열 · SM 종속회사)가 같은 메일 도메인을 쓰는지는 확인하지 못했다.
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'hanatour.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'hanatour';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'smtown.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'sm_entertainment';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'wjthinkbig.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'woongjin_thinkbig';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'kg-mobility.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'kg_mobility';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'namyangi.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'namyang_dairy';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'daekyo.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'daekyo';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'megastudyedu.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'megastudy_edu';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'lxhausys.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'lx_hausys';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'jejuair.net', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'jeju_air';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'aekyung.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'aekyung_industrial';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'nexentire.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'nexen_tire';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'sikorea.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'shinsegae_intl';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'dbhitek.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'db_hitek';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'daesang.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'daesang';

-- ═══════════════════════════════════════════════════════════════════════════════
-- 확장 웨이브 13 (2026-10-20 서빙 반영, 11개사 중 전용 10사 10도메인 + 그룹 줄 병합 1사)
-- 근거는 각사 evidence(loupit-evidence/2026-10-20-wave13/collect/ 의 이메일 도메인 관측 절) — 공식 페이지 · 보고서 · 공고에 게시된 주소의 도메인만.
-- 그룹 줄 병합: SK온 → 위 SK 그룹 줄(sk.com — 공식 홈 개인정보 관련 담당자 표 관측 · 자기 웹 sk-on.com 의 MX 도 spmail.sk.com).
-- 미등록 0.
-- ⓘ 웹 도메인과 메일 도메인이 다른 곳: 컬리(웹 kurly.com · 메일 kurlycorp.com) · 한섬(웹 handsome.co.kr · 메일 thehandsome.com — handsome.co.kr 도 MX 는 있으나 게시된 주소 0).
-- ⓘ gscaltex.co.kr(DART 홈 칸 도메인)도 MX 가 있으나 게시된 주소는 gscaltex.com 뿐이라 그것만 넣었다.
-- ⓘ halim.com — 하림 개인정보처리방침의 옛 개정본 담당자 · 수탁업체 줄에만 보인다(지금 담당 부서 · 보고서 문의처는 harim.com) — 넣지 않았다.
-- ⓘ oci.co.kr 의 MX 는 OCI 그룹 메일 게이트웨이(ocigw.net)로 지주 OCI홀딩스 웹 도메인 oci-holdings.co.kr 와 같은 게이트웨이다. 도메인은 OCI 법인 웹 · 보고서 문의처 도메인이고 지주는 도메인이 따로라 그대로 넣었다.
-- ⚠ toss.im · musinsa.com · kurlycorp.com — 같은 브랜드 아래 계열 법인(토스 커뮤니티 · 무신사 종속회사 · 컬리 자회사)이 같은 메일 도메인을 쓰는지는 확인하지 못했다.
-- ⚠ hyundaigreenfood.com · oci.co.kr — 분할 전 옛 법인(지금 지주 현대지에프홀딩스 · OCI홀딩스)이 쓰던 도메인이라 지주 직원이 같은 도메인을 쓰는지는 확인하지 못했다.
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'toss.im', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'toss';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'musinsa.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'musinsa';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'kurlycorp.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'kurly';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'gscaltex.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'gs_caltex';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'lxsemicon.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'lx_semicon';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'thehandsome.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'handsome';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'hyundaigreenfood.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_greenfood';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'harim.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'harim';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'oci.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'oci';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'visang.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'visang_edu';

-- ═══════════════════════════════════════════════════════════════════════════════
-- 확장 웨이브 14 (2026-10-27 서빙 반영, 18개사 중 전용 5사 5도메인 + 롯데 그룹 줄 병합 3사)
-- 근거는 각사 evidence(loupit-evidence/2026-10-22-wave14/collect/ 의 이메일 도메인 관측 절) — 공식 페이지 · 보고서 · 처리방침에 게시된 주소의 도메인만.
-- 그룹 줄 병합: 호텔롯데 · 롯데이노베이트 · 코리아세븐 → 위 롯데 그룹 줄(lotte.net — 보고서 문의처 · 처리방침 관측).
-- 미등록 10: 포스코(posco.com 은 위 보류 목록 — 그룹 도메인이라 등록 안 함) · SK쉴더스(게시 주소 0 · MX spmail.sk.com 이지만 SK 기업집단 계열제외라 SK 그룹 줄에 넣지 않음) ·
--   동원F&B · 이랜드월드 · 신세계푸드 · 신세계 I&C · 삼립 · 동국제강(아래 보류 — 그룹 공용) · 코오롱글로벌 · 한솔제지(kolon.com · hansol.com 은 위 보류 목록) → 수동 승인 폴백.
-- ⓘ poscoenc.com 은 포스코 그룹 메일 게이트웨이(antispam.posco.net)를 거치지만 주소 도메인은 법인 고유다(웨이브 7 poscodx.com 과 같은 처리).
-- ⓘ lscns.com 은 LS 그룹 메일 호스팅(smtp.lsworkplace.com)을 거치지만 주소 도메인은 법인 고유다(웨이브 9 lsms.co.kr 과 같은 처리) · 웹 lscns.co.kr 은 MX 없음.
-- ⓘ hanjin.com 은 웹 도메인과 같다(MX 구글 호스팅) · 형제 대한항공은 koreanair.com 이라 겹치지 않는다.
-- ⓘ 코오롱글로벌 웹 kolonglobal.com · 한솔제지 웹 hansolpaper.co.kr · 동국제강 웹 dongkuksteel.com · 신세계 두 곳 웹 도메인은 게시 주소 0(MX 도 없음) — 넣지 않았다.
-- @rejected: dongwon.com — 동원F&B. 동원그룹 공용 도메인(형제 동원산업 웹 도메인 · 보고서 문의처) — 동원 계열 전 직원이 동원F&B 재직자로 인증될 수 있음
-- @rejected: eland.co.kr — 이랜드월드. 이랜드 그룹 공용 도메인(이랜드리테일 공고 문의처도 같은 도메인) — 코퍼스 이랜드 계열 1사
-- @rejected: shinsegae.com — 신세계푸드 · 신세계 I&C. 신세계그룹 공용 메일 도메인(처리방침 · 보고서 문의처 · 두 법인 웹 도메인은 MX 없음) — 그룹 단위 인증 결정 없음
-- @rejected: spc.co.kr — 삼립. SPC 그룹 공용 도메인(보고서 ESG 문의처 · 웹 spcsamlip.co.kr 은 MX 없음) — 코퍼스 SPC 계열 1사
-- @rejected: dongkuk.com — 동국제강. 동국제강그룹 공용 도메인(보고서 문의처 · 그룹 윤리경영 신고 도메인 · 웹 dongkuksteel.com 은 MX 없음) — 코퍼스 동국제강 계열 1사
-- 코오롱글로벌(kolon.com) · 한솔제지(hansol.com) 는 위 기존 보류 줄과 같은 사유(그룹 공용)라 새 보류 줄을 더하지 않는다.
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'poscoenc.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'posco_enc';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'hyundai-transys.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'hyundai_transys';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'osstem.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'osstem';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'lscns.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'ls_cable';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'hanjin.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'hanjin';

-- ═══════════════════════════════════════════════════════════════════════════════
-- 확장 웨이브 15 (2026-11-03 서빙 반영, 17개사 중 전용 7사 7도메인 + 그룹 줄 병합 SK 3 · 롯데 2 · 삼성 2)
-- 근거는 각사 evidence(loupit-evidence/2026-10-23-wave15/collect/ 의 이메일 도메인 관측 절) — 공식 페이지 · 보고서 · 처리방침에 게시된 주소의 도메인만 · MX 는 감사 dig 실측(2026-10-23).
-- 그룹 줄 병합: SK에코플랜트 · SK실트론 · SK에너지 → SK 그룹 줄 · 롯데건설 · 롯데글로벌로지스 → 롯데 그룹 줄 · 세메스 · 멀티캠퍼스 → 삼성 그룹 줄(전용 도메인은 아래 단일 줄 — 제일기획 선례).
-- 미등록 5: 우리은행 · 한국스탠다드차타드은행 · 현대카드(게시 주소 0) · 메리츠화재 · JW중외제약(아래 보류 — 그룹 공용) → 수동 승인 폴백.
-- ⓘ lghv.net 은 LG헬로비전 보고서 문의처 도메인(웹 lghellovision.net 과 다름 · MX outlook) · 모회사 LG유플러스는 lguplus.co.kr 로 겹치지 않는다.
-- ⓘ homecc.com 은 KCC글라스 인테리어 사업(홈씨씨) 도메인이자 ESG 보고서 대표 문의 주소 · 형제 KCC 는 kccworld.co.kr 로 겹치지 않는다 — KCC 계열 다른 법인 주소로 관측되면 다시 본다.
-- ⓘ semes.com · multicampus.com 은 삼성 그룹 메일 인프라(mailin.samsung.com)를 거치지만 주소 도메인은 법인 고유다.
-- @rejected: meritz.co.kr — 메리츠화재. 메리츠금융그룹 공용 도메인(채용 사이트 meta author 메리츠금융그룹) — 그룹 단위 인증 결정 없음 · 코퍼스 메리츠 계열 1사
-- @rejected: jw-group.co.kr — JW중외제약. JW그룹 공용 도메인(개인정보처리방침 문의처) — 그룹 단위 인증 결정 없음 · 코퍼스 JW 계열 1사
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'semes.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'semes';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'lfcorp.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'lf';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'cafe24corp.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'cafe24';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'lghv.net', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'lg_hellovision';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'homecc.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'kcc_glass';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'dohwa.co.kr', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'dohwa';
INSERT IGNORE INTO TCOMPANY_EMAIL_DOMAIN (COMP_ID, EMAIL_DOMAIN_NM, ACTIVE_YN)
  SELECT COMP_ID, 'multicampus.com', TRUE FROM TCOMPANY WHERE COMP_ENG_NM = 'multicampus';
