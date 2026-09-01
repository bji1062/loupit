# 웨이브 1 등록 데이터 (W-3 통합용)

## krx_sector.csv 추가 11행 (stock_cd,corp_nm,sector_nm,market)
010130,고려아연,금속,KOSPI
000720,현대건설,건설,KOSPI
010120,LS ELECTRIC,전기·전자,KOSPI
240810,원익IPS,기계·장비,KOSDAQ
064400,LG CNS,IT 서비스,KOSPI
066970,엘앤에프,전기·전자,KOSPI
067310,하나마이크론,전기·전자,KOSDAQ
222800,심텍,전기·전자,KOSDAQ
161390,한국타이어앤테크놀로지,화학,KOSPI
105560,KB금융,기타금융,KOSPI
267250,HD현대,기타금융,KOSPI
(선례: 반도체장비=기계·장비[주성·유진테크·테크윙], 패키징/기판/양극재=전기·전자[네패스·비에이치·에코프로비엠], 지주=기타금융[LG], 타이어=화학[한화 화학 선례])

## corp_code_map.csv 추가 11행 (comp_id는 힌트 — 이름 조인)
103,고려아연,auto,00102858,010130,
104,현대건설,auto,00164478,000720,
105,LS ELECTRIC,auto,00105855,010120,DART 명 엘에스일렉트릭
106,원익IPS,auto,01135941,240810,
107,LG CNS,auto,00139834,064400,DART 명 LG씨엔에스
108,엘앤에프,auto,00398701,066970,
109,하나마이크론,auto,00445054,067310,
110,심텍,auto,01095722,222800,
111,한국타이어앤테크놀로지,auto,00937324,161390,
112,KB금융,auto,00688996,105560,
113,HD현대,auto,01205709,267250,
(전부 종목코드 정확 매칭 — corpCode.xml 2026-09-01 스냅샷, 오매핑 0)

## FINANCIAL_COMPANIES 추가
'KB금융' (load_corp.py:34) + test_corp_load.py FINANCIAL_7 → 8 (이름도 FINANCIAL_8 로)

## 별칭 override 초안 (company_meta.py — WAVE1_ALIASES dict)
korea_zinc: [고려아연]
hyundai_enc: [현대건설, 현건]
ls_electric: [LS ELECTRIC, LS일렉트릭, 엘에스일렉트릭, LS산전]
wonik_ips: [원익IPS, 원익아이피에스]
lg_cns: [LG CNS, LG씨엔에스, 엘지씨엔에스]
landf: [엘앤에프, L&F]
hana_micron: [하나마이크론]
simmtech: [심텍, SIMMTECH]
hankook_tire: [한국타이어앤테크놀로지, 한국타이어, 한타]
kbfg: [KB금융, KB금융지주]
hd_hyundai: [HD현대, 에이치디현대]
(주의: 구명 LS산전 포함 — 검색 유입 보전. 최종은 수집기 evidence 의 관측 별칭과 병합)

## 테스트 핀 갱신 (통합 시)
SD-3/SI-8/SM-1: 102 → 113 · SD-4: 1553 + N(수집 결과) · FN-1: 101/100 → 112/111 · FINANCIAL_7 → 8
GC-2: "정확히 200 BuildError" → "복지 0행 회사 존재 시 BuildError" 로 교체 + SPEC INV-6 서술 개정
