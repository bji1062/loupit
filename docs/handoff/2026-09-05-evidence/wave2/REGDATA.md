# 웨이브 2 등록 데이터 (W-3 통합용) — 확정 2026-09-05 (검증·감사 반영: 277행 · SD-4=2032 · 브랜치 적용 완료)

## krx_sector.csv 추가 13행 (stock_cd,corp_nm,sector_nm,market)
010140,삼성중공업,운송장비·부품,KOSPI
011070,LG이노텍,전기·전자,KOSPI
353200,대덕전자,전기·전자,KOSPI
000810,삼성화재,보험,KOSPI
018260,삼성SDS,IT 서비스,KOSPI
028050,삼성E&A,건설,KOSPI
007660,이수페타시스,전기·전자,KOSPI
068760,셀트리온제약,제약,KOSDAQ
251270,넷마블,IT 서비스,KOSPI
005290,동진쎄미켐,화학,KOSDAQ
088350,한화생명,보험,KOSPI
003230,삼양식품,음식료·담배,KOSPI
047810,한국항공우주산업,운송장비·부품,KOSPI
(선례: 조선·항공=운송장비·부품[한화오션·한화에어로스페이스], PCB·전자부품=전기·전자[삼성전기·비에이치], 보험=보험[삼성생명·DB손보],
 IT·게임=IT 서비스[크래프톤·카카오게임즈·LG CNS], 식품=음식료·담배[CJ제일제당], 반도체소재=화학[솔브레인], 플랜트=건설[현대건설], 제약=제약[셀트리온])

## corp_code_map.csv 추가 13행 (comp_id 는 힌트 — 이름 조인, 이름 = COMP_NM)
115,삼성중공업,auto,00126478,010140,
116,LG이노텍,auto,00105961,011070,
117,대덕전자,auto,01478712,353200,
118,삼성화재,auto,00139214,000810,DART 명 삼성화재해상보험
119,삼성SDS,auto,00126186,018260,DART 명 삼성에스디에스
120,삼성E&A,auto,00126308,028050,
121,이수페타시스,auto,00107613,007660,
122,셀트리온제약,auto,00541349,068760,
123,넷마블,auto,00904672,251270,
124,동진쎄미켐,auto,00118804,005290,
125,한화생명,auto,00113058,088350,
126,삼양식품,auto,00126955,003230,
127,한국항공우주산업,auto,00309503,047810,DART 명 한국항공우주
(전부 종목코드 정확 매칭 — CORPCODE.xml 2026-09-01 스냅샷, 오매핑 0)

## FINANCIAL_COMPANIES 추가
'삼성화재', '한화생명' (load_corp.py) + test_corp_load.py FINANCIAL_7 집합 +2 (이름은 역사적 이유로 유지)

## 별칭 override 초안 (company_meta.py — WAVE2_ALIASES dict)
samsung_heavy: [삼성중공업, 삼중, Samsung Heavy Industries, SHI]
lg_innotek: [LG이노텍, 엘지이노텍, LG Innotek]
daeduck: [대덕전자, Daeduck Electronics]            ← 지주 ㈜대덕은 별도 법인, 넣지 않는다
samsung_fire: [삼성화재, 삼성화재해상보험, Samsung Fire]
samsung_sds: [삼성SDS, 삼성에스디에스, Samsung SDS]
samsung_ena: [삼성E&A, 삼성이앤에이, 삼성엔지니어링, Samsung E&A]   ← 구명 유입 자산
isu_petasys: [이수페타시스, 페타시스, ISU Petasys]
celltrion_pharm: [셀트리온제약, Celltrion Pharm]       ← 모회사 셀트리온은 별도 법인
netmarble: [넷마블, Netmarble, 넷마블게임즈]           ← 구명(2018 이전)
dongjin_semichem: [동진쎄미켐, 동진세미켐, Dongjin Semichem]
hanwha_life: [한화생명, 한화생명보험, Hanwha Life, 대한생명]   ← 구명(2012 이전) 유입 자산
samyang_foods: [삼양식품, Samyang Foods]               ← 삼양사·삼양홀딩스·삼양라운드스퀘어는 타 법인
kai: [한국항공우주산업, 한국항공우주, KAI, 카이, Korea Aerospace Industries]

## 테스트 핀 갱신 (통합 시)
SD-3/SI-8/SM-1: 113 → 126 · SD-4: 1755 + 277 = 2032 · FN-1: 112/111 → 125/124 · FINANCIAL 8 → 10 · SB-10 +13 eng
(samsung_heavy lg_innotek daeduck samsung_fire samsung_sds samsung_ena isu_petasys celltrion_pharm netmarble dongjin_semichem hanwha_life samyang_foods kai)

## LOGO_NM 교정표 (통합 시 sed — 수집기 지시가 한글 초성으로 잘못 나감)
samsung_heavy S · lg_innotek L · daeduck D · samsung_fire S · samsung_sds S · samsung_ena S · isu_petasys I · celltrion_pharm C · netmarble N · dongjin_semichem D · hanwha_life H · samyang_foods S · kai K

## 이메일 도메인 (evidence 관측 결과 — 기존 그룹 단위 인증 정책 그대로)
- **그룹 줄 병합(SED-5)**: `samsung.com` IN(...) 에 samsung_heavy·samsung_fire·samsung_sds·samsung_ena 추가(관측: shi.is@·recruit.sena@·sdsjobs@·그룹 채용문의 — 전부 @samsung.com, 사용자 결정 2026-07-23 그룹단위) · `hanwha.com` IN(...) 에 hanwha_life 추가(관측 hli_IR@hanwha.com, 사용자 결정 2026-07-29 그룹단위)
- **회사 전용 신규 7**: lg_innotek `lginnotek.com`(개인정보처리방침; `.co.kr` 은 사망 → 미등록) · daeduck `daeduck.com`(채용 접수처 swlim@) · dongjin_semichem `dongjin.com`(푸터 recruit@) · samyang_foods `samyangfoods.com`(처리방침 부서별 4건; 그룹 roundsquare.ai 는 미등록) · celltrion_pharm `celltrionph.com`(처리방침 IT@) · netmarble `netmarble.com`(privacy-help@; 자회사 nm-*.com 은 타 법인 — 미등록) · isu_petasys **`isupetasys.com`**(Contact Us 5건, MX=Google Workspace — 웹 호스트는 죽었지만 메일은 살아 있음; 그룹 isu.co.kr 미등록; ⚠ CAREERS_BENEFIT_URL 과 혼동 금지)
- kai `koreaaero.com`(고객 문의 페이지 6건 관측) — 확정
- @rejected 목록과 충돌 0 (전부 신규 도메인)
