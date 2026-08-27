# 함정 인덱스 (자동 생성 — `python3 docs/tools/pitfalls.py`)

기존 ①~(66)의 **정본은 각 HANDOFF 원문**이다(상호참조 보존을 위해 이동 금지). 이 파일은 찾아가는 지도일 뿐이다. 새 함정은 번호 없이 `_incoming/` 에 쓰고, 머지 후 `--assign` 으로 번호를 받는다 — 그래서 병렬 세션끼리 번호가 겹칠 수 없다.

| # | 요약 | 위치 |
|--:|---|---|
| 1 | ✅ 라이브 리밋 회귀 검증 — 완료(2026-07-28). smoke.sh 에 SM-21·SM-22 배선. | HANDOFF-2026-07-27-B.md §5 |
| 2 | .env.beta 가 자기 메일 모드를 소유하지 않는다 | HANDOFF-2026-07-27-B.md §5 |
| 3 | beta 16경로·자산·API 검증 ④ 심링크 2개를 명시적으로 먼저 제거하고 대상 무결 확인 | HANDOFF-2026-07-27-B.md §5 |
| 4 | logrotate size 상한 없음 — daily+rotate 14+compress 뿐. limit_req_log_level 기본이 | HANDOFF-2026-07-27-B.md §5 |
| 5 | git worktree remove --force ⑥ deploy-beta.sh 주석 현행화(가드 로직은 유지). | HANDOFF-2026-07-27-B.md §5 |
| 6 | 이메일 정규화는 두 종류다 — 섞지 마라. | HANDOFF-2026-07-27-B.md §5 |
| 7 | server/.env 는 bash source 로도 읽힌다(release.sh:39). | HANDOFF-2026-07-27-B.md §5 |
| 8 | 이 머신은 코어가 2개다. Workflow 툴의 동시 상한이 min(16, 코어수-2) 라 사실상 직렬로 | HANDOFF-2026-07-27-B.md §5 |
| 9 | 메일 엔드포인트를 안전하게 시험하는 법 — @ 가 없는 문자열을 보내라. | HANDOFF-2026-07-27-B.md §5 |
| 10 | §2 의 diff \| grep -c '^<' = 0 가드는 공백 정렬 변경에 위양성을 낸다 — diff -w 로 재확인하라. | HANDOFF-2026-07-27-B.md §5 |
| 11 | vhost 를 건드렸으면 sudo certbot renew --dry-run 을 돌려라 — 인증서 갱신은 90일간 조용하다. | HANDOFF-2026-07-27-B.md §5 |
| 12 | 격리 하네스는 "대조군이 200 을 내는지" 먼저 확인하고 판정하라 — 아니면 전부 404 인 걸 성공으로 읽는다. | HANDOFF-2026-07-27-B.md §5 |
| 13 | git merge-tree --write-tree 는 git 2.34 에 없다(이 호스트 2.34.1). | HANDOFF-2026-07-27-B.md §5 |
| 14 | release.sh 는 nginx conf 를 배포하지 않는다 — [6/7] 은 nginx -t && reload 뿐이다. | HANDOFF-2026-07-28.md §4 |
| 15 | add_header 는 always 없이는 4xx/5xx 에 안 붙고, 값이 빈 문자열이면 헤더 자체가 생략된다. | HANDOFF-2026-07-28.md §4 |
| 16 | limit_req 거부(429)는 excess 를 올리지 않는다 — nginx 는 NGX_BUSY 에서 커밋하지 않는다. | HANDOFF-2026-07-28.md §4 |
| 17 | 스모크 전량이 약 1.8초다. "직전 실행이 버킷을 비웠으니 다음 실행은 다르겠지"를 기대하지 마라 — | HANDOFF-2026-07-28.md §4 |
| 18 | nginx limit_req 에 burst=0 은 문법 오류다 — 버스트 없음은 burst 를 생략한다. | HANDOFF-2026-07-28.md §4 |
| 19 | web/assets 는 라이브다(기존 함정의 재확인). 이번엔 red 검증조차 원본을 못 건드려 | HANDOFF-2026-07-28.md §4 |
| 20 | 정적 문안만 바꿀 때 release.sh 를 쓰지 마라. 테스트 게이트가 서빙 스키마를 | HANDOFF-2026-07-29.md §4 |
| 21 | .gz 는 gzip mtime 때문에 항상 다르게 보인다. 압축 해제해서 비교해야 실차이를 안다 | HANDOFF-2026-07-29.md §4 |
| 22 | monkeypatch 스텁은 실제 드라이버 동작을 검증하지 않는다. ops list-suppressed 가 | HANDOFF-2026-07-29.md §4 |
| 23 | 서명 검증을 시험할 땐 "서명 대상"과 "전송 대상"이 갈라져 있는지부터 확인하라. | HANDOFF-2026-07-29.md §4 |
| 24 | pytest.raises(같은 예외) 로는 두 실패 원인을 구분할 수 없다. 잘못된 시크릿도 결국 | HANDOFF-2026-07-29.md §4 |
| 25 | 메일 테스트 전에는 수신 도메인의 MX 를 먼저 확인하라. bji1062@gamil.com 은 실재하는 | HANDOFF-2026-07-29.md §4 |
| 26 | Resend 는 평판을 해치지 않는 시뮬레이터 주소를 제공한다: bounced@resend.dev · | HANDOFF-2026-07-29.md §4 |
| 27 | DB 테이블을 추가하면 세 곳을 같이 봐라: db/schema.sql · conftest.TABLE_CREATE_ORDER · | HANDOFF-2026-07-29.md §4 |
| 28 | 커버리지를 넓히면 그 기능의 실패 경로도 함께 넓어진다. 도메인을 등록하면 그 회사는 | HANDOFF-2026-07-29-B.md §4 |
| 29 | "위반이 없다"만 주장하는 가드는 스스로 초록일 수 있다. 파서가 아무것도 못 읽으면 빈 | HANDOFF-2026-07-29-B.md §4 |
| 30 | 회사명·사이트 주소로 메일 도메인을 유추하지 마라. 이번 조사 64사에서 "사이트 ≠ 메일" | HANDOFF-2026-07-29-B.md §4 |
| 31 | 게시 위치가 아니라 소속을 봐라. 현대제철 개인정보처리방침의 "기술책임자" 2인은 | HANDOFF-2026-07-29-B.md §4 |
| 32 | 도메인 소유 확증에는 회사가 통제하는 인프라 증거가 3자 사이트보다 강하다. | HANDOFF-2026-07-29-B.md §4 |
| 33 | INSERT ... SELECT ... WHERE COMP_ENG_NM = 'slug' 는 오타 시 에러 없이 0행을 넣는다. | HANDOFF-2026-07-29-B.md §4 |
| 34 | 미러·2차 사본은 1차가 확정된 뒤에만 손대라. 순서를 뒤집으면 2차를 늘리려다 1차까지 | HANDOFF-2026-07-29-B.md §4 |
| 35 | 로테이션 글롭이 남의 파일을 지운다. MIRROR_DIR 을 /db/backups 직하로 뒀다면 7일 | HANDOFF-2026-07-29-B.md §4 |
| 36 | bash EXIT 트랩의 마지막 명령이 종료코드를 뒤집는다. [ -n "$VAR" ] && rm -f "$VAR" 를 | HANDOFF-2026-07-29-B.md §4 |
| 37 | 케어젠 공식 사이트는 현재 전 세계에서 403 이다(아임웹 호스팅 에러 페이지, 우리 IP | HANDOFF-2026-07-29-B.md §4 |
| 38 | 표현할 수 없는 계약은 지켜지지 않는다. verify_mail.py 는 server/.env 만 읽고 | HANDOFF-2026-07-29-B.md §4 |
| 39 | conftest 가 MAILER_MODE=console 을 강제하므로 pytest 안에서는 메일 모드 상속 결함을 | HANDOFF-2026-07-29-B.md §4 |
| 40 | 모드에 따라 뜻이 달라지는 값을 하한으로 재지 마라. load.py 의 verify_counts 가 | HANDOFF-2026-07-29-B.md §4 |
| 41 | 가드의 문구가 의도보다 넓으면 옳은 변경을 막는다. SI-1 이 COMP_NM='CJ ENM' 부재를 | HANDOFF-2026-07-29-B.md §4 |
| 42 | .env 에 키를 추가하면 "그 키가 없다"를 전제한 테스트가 그 순간 깨진다. 함정 ①과 같은 | HANDOFF-2026-07-29-B.md §4 |
| 43 | 재벌 계열사는 복지 항목 목록으로 구분되지 않는다. CJ 는 그룹이 복지를 중앙에서 정하고 | HANDOFF-2026-07-29-B.md §4 |
| 44 | lsof 는 아무것도 못 찾아도 종료코드 1이다. set -o pipefail 과 함께 쓰면 가드가 | HANDOFF-2026-07-30.md §4 |
| 45 | 글롭으로 읽히는 설정 디렉터리 안에 백업을 두지 마라. /etc/logrotate.d/nginx. | HANDOFF-2026-07-30.md §4 |
| 46 | 폭탄을 막으려다 잠금을 만들지 마라. 하드 상한은 제3자가 피해자의 예산을 태워 | HANDOFF-2026-07-30.md §4 |
| 47 | 퍼지되는 행 위에 세운 판정은 그 행의 TTL 보다 긴 시간 규모를 표현할 수 없다. | HANDOFF-2026-07-30.md §4 |
| 48 | 시점이 다른 두 값을 비교하지 마라(함정 ㊵ 재발 — 그 함정을 주석으로 경계해 놓고 | HANDOFF-2026-07-30.md §4 |
| 49 | 뒷정리 트랩을 락 획득 전에 걸지 마라. 락 경합으로 건너뛰는 경로에서 그 트랩이 | HANDOFF-2026-07-30.md §4 |
| 50 | /var/lock 은 크로스 유저 락 파일에 쓸 수 없다. 이 커널은 | HANDOFF-2026-07-30.md §4 |
| 51 | 대역이 모르는 SQL 을 만나 예외를 던지는데 호출부가 fail-open 이면 거짓 초록이다. | HANDOFF-2026-07-30.md §4 |
| 52 | INSERT IGNORE 는 중복키뿐 아니라 모든 오류를 경고로 낮춘다. 데이터 절단·타입 | HANDOFF-2026-07-30.md §4 |
| 53 | 메일 경로를 메일을 태워서 검증하지 마라. 배선 확인이랍시고 prod | HANDOFF-2026-07-30.md §4 |
| 54 | 테스트가 결함을 고정하고 있을 수 있다 — 목업이 실제 응답과 다르면 특히 그렇다. | HANDOFF-2026-07-30.md §4 |
| 55 | Pydantic 응답 모델은 모르는 필드를 조용히 떨어뜨린다. 번들 빌더에 edit_origin | HANDOFF-2026-07-30.md §4 |
| 56 | Jinja 템플릿의 <!-- --> 는 생성물에 그대로 실린다. 파비콘 선언에 개발자용 설명을 | HANDOFF-2026-07-30.md §4 |
| 57 | "데이터가 없으면 숨는다"는 UI 는 언젠가 반드시 사라지고, 사라져도 아무 신호가 없다. | HANDOFF-2026-07-31.md §4 |
| 58 | GET / 로 트래픽을 세면 10~100배 과대평가한다. nginx 는 하루 300~800건을 | HANDOFF-2026-07-31.md §4 |
| 59 | 기록 문턱을 낮추면 중복 제거가 같은 커밋에 와야 한다. 시점을 앞당기면 같은 쌍이 | HANDOFF-2026-07-31.md §4 |
| 60 | 봇이 밟는 URL 경로에 집계 로그를 걸지 마라. /compare/?a=<slug> 는 GoogleOther 가 | HANDOFF-2026-07-31.md §4 |
| 61 | 수집 시점을 바꾸면 개인정보 처리방침이 그 순간 허위가 된다. P2 가 "비교 실행 시" | HANDOFF-2026-07-31.md §4 |
| 62 | 우리 봇 방어가 우리 자동 검증을 막는다. 라이브를 헤드리스로 열면 403 이다 — | HANDOFF-2026-07-31.md §4 |
| 63 | "렌더러가 셋"이라고 센 순간 넷째가 생긴다 — 판정을 복사하면 반드시 갈라진다. | HANDOFF-2026-07-31.md §4 |
| 64 | 화이트리스트 정규화는 서버의 Pydantic 과 똑같이 필드를 조용히 떨군다(함정 (55)의 | HANDOFF-2026-07-31.md §4 |
| 65 | 상태를 되살리는 장치에 화면까지 정하게 하면 랜딩이 사라진다. 입력 초안을 넣자 | HANDOFF-2026-07-31.md §4 |
| 66 | "복원하지 않는다"와 "지운다"는 다른 약속이다. 대문에서 초안을 복원만 생략하고 | HANDOFF-2026-07-31.md §4 |
| 67 | "배선이 멀쩡한데 안 된다"가 셋 겹치면 원인은 배선이 아니라 데이터다. | HANDOFF-2026-08-21.md §4 |
| 68 | DART 재무를 sj_div 로 거르면 회사마다 조용히 빈다. 지표는 반드시 | HANDOFF-2026-08-21.md §4 |
| 69 | 회사와 법인은 같은 것이 아니다 — 재무를 회사에 매달면 갈라진다. | HANDOFF-2026-08-21.md §4 |
| 70 | 표시명(COMP_NM)을 바꾸면 별칭이 통째로 사라진다. | HANDOFF-2026-08-21.md §4 |
| 71 | 봇이 Googlebot 을 사칭한다 — UA 로 진단하면 오진한다. | HANDOFF-2026-08-21.md §4 |
| 72 | 회사명의 정본은 복지 SQL 의 자기등록 INSERT 다 — db/seed/benefit/sql/*.sql 의 | HANDOFF-2026-08-21.md §4 |
| 73 | 메모리·문서의 "도구 기보유"가 이 레포에 있다는 뜻은 아니다. | HANDOFF-2026-08-21.md §4 |
| 74 | 🚨 생성물 무시 패턴이 소스까지 먹으면, 그 파일은 서버에만 존재하는 유령이 된다 | PITFALLS/0074-gitignore-generated-pattern-ate-source-template.md |
| 75 | 격리한 것은 피호출자뿐 — 호출자가 env 로 계약을 무효화한다 | PITFALLS/0075-isolated-callee-defeated-by-caller-env.md |
| 76 | 🚨 jsdom 에는 matchMedia 가 없다 — 기기 분기는 "테스트가 있어도 없는 것"이 된다 | PITFALLS/0076-jsdom-matchmedia-absent-device-branch-untested.md |
| 77 | 🚨 "게시된 이메일 0건"은 회사 사이트만 봤다는 뜻일 수 있다 — 그리고 찾아낸 도메인이 곧 등록 근거는 아니다 | PITFALLS/0077-mail-domain-not-on-company-site-and-may-be-group-wide.md |
| 78 | _head_meta.html 에 SEO 태그를 "한 페이지만" 추가하는 방법은 없다 | PITFALLS/0078-shared-head-meta-partial-is-site-wide.md |
| 79 | 임포트 시점에 굳는 env 기본값 — 그 위에 세운 단정은 CI 에서만 초록이다 | PITFALLS/0079-import-time-env-default-makes-tests-ci-only-green.md |

**번호 대기(_incoming): 0건**
