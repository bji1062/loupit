# 웨이브 2 실사 프로브 계약 (W-0) — 2026-09-05

목적: 회사 1곳에 대해 **공식 1차 출처 기반 복지 수집이 가능한지**만 판정한다. 수집·SQL 작성은 범위 밖.
산출물: `docs/handoff/2026-09-05-evidence/probe/<회사명>.md` 한 파일(한국어). 형식은 웨이브 1 선례와 동일 —
먼저 `docs/handoff/2026-09-01-evidence/probe/심텍.md`(가능 판정)과 `하나금융지주.md`(불가 판정)를 읽고 같은 뼈대로 쓴다.

## 판정 기준 (전부 만족해야 「가능」)

1. **공식 출처만**: 회사 자기 도메인, 또는 회사명이 붙은 전용 채용 서브도메인(예 `hankooktire.recruiter.co.kr`, `careers.kbfg.com`).
   그룹 공통 채용사이트(예 samsungcareers·hanwhain·careers.lg.com)는 **해당 법인이 채용 주체로 식별되는 페이지**일 때만 인정하고,
   귀속 경로(어느 메뉴·필터에서 이 법인 이름이 나오는지)를 기록한다. 그룹 공통 복지만 있고 법인 구분이 없으면 「조건부」로 내리고 근거를 적는다.
   사람인·잡코리아·잡플래닛·캐치·인크루트·블라인드·크레딧잡 등 3자 사이트는 **출처가 아니다**(참고 인용도 금지).
2. **법인 일치**: 등록 대상은 상장 법인 그 자체. 지주 ≠ 자회사, 계열사 ≠ 그룹. 다른 법인 페이지를 갖다 붙이면 불가.
3. **복지 항목이 명시적**: 항목명이 나열돼 있어야 한다(가치관·인재상·교육 커리큘럼만 있으면 항목 0 취급).
   개수·카테고리·예시 2개를 적고, 텍스트(HTML)인지 이미지 안인지 JS 렌더인지 표시한다. 금액 명시가 있으면 따로 적는다.
4. **robots 허용**: `robots.txt` 를 `*` 와 AI 봇 UA(ClaudeBot·anthropic-ai·GPTBot·CCBot·Google-Extended) 각각에 대해 해당 경로 기준으로 판정. 404 = 허용. BOM 유무 기록.
   `*` 가 경로를 막으면 본문을 가져오지 말고 「불가(robots)」로 끝낸다.
5. **접근성**: HTTP 상태·본문 크기·응답시간, SSR/SPA(원본 HTML 에 복지 텍스트가 있는가 — 없으면 `__NEXT_DATA__`·JSON API·JS 번들 중 어디에 있는지),
   봇 차단(WAF·캡차·UA 차단), TLS(curl exit code·구형 TLS 여부), 인코딩(UTF-8/EUC-KR/cp949), www/apex 차이, HEAD/GET 차이.

## 알려진 함정 (반드시 점검)

- **차단이 200 으로 온다**: 본문 <2KB 또는 "접근 차단·Access Denied·deny·WAF·비정상 접근" 키워드면 차단으로 본다(웨이브 1: hdec.kr 939B·koreazinc EUC-KR 안내문).
- **soft-404**: 200 인데 오류/빈 페이지. HEAD 403/GET 200 사이트도 있다 — GET 로 판정.
- **DART hm_url 오염**: 추정 도메인이 NXDOMAIN 이거나 죽은 `.co.kr` 일 수 있다 — DNS·실응답으로 생존 확인 후 실제 도메인을 적는다.
- **apex 무응답**: `www.` 붙여 재시도.
- **SPA**: `curl` 원본에 항목이 없으면 Playwright 로 렌더해 확인(설치돼 있음: `python3 -c "from playwright.sync_api import sync_playwright"`).
  렌더 후에도 없으면 번들·API 를 찾아 경로를 적는다. 헤드리스라도 UA 는 일반 브라우저 문자열을 쓴다.
- **이미지 안 항목**: PNG/GIF 안에만 있으면 이미지 URL·크기·HTTP 200 을 적고 「조건부(이미지 판독)」.
- **HTML 주석 속 항목**: 주석 처리된 복지는 유령 — 태그 제거 파싱 전에 주석을 걷어내고 판정.
- **robots 의 AI 봇 명시 차단**(네패스 선례): `*` 는 허용이라도 AI 봇 UA 만 차단하면 그 사실을 판정문 첫 줄에 적는다(선발 단계에서 결정).

## 예절·한도

- UA 는 일반 브라우저(`Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0 Safari/537.36`), `--max-time 20`, 요청 간 ≥1초, 회사당 요청 ≤40회.
- 내려받은 파일은 `/tmp/claude-0/-home-ubuntu-loupit/bc404160-59bd-48dd-b2d7-94c4ce001a43/scratchpad/probe/<eng>/` 아래에만 둔다. 리포에는 프로브 .md 한 파일만 쓴다.
- 찾는 순서: 홈 → 채용/Careers/인재채용 메뉴 → 복리후생/복지/Benefits/Life/인사제도. 흔한 경로(`/recruit`, `/careers`, `/career/benefit`, `/kr/careers/benefits`)와 `sitemap.xml`(robots 의 Sitemap 지시 포함)도 본다.
- 판정문은 파일 상단에 굵게 한 줄: **판정: 가능 / 조건부(사유) / 불가(사유)**. 마지막에 「수집 설계 시 유의」 3~5줄.
