# RUNBOOK — jobcho.wiki 도메인 오픈 (DNS → TLS → 배포 → 서치콘솔)

> 대상: 운영자 1인. 소요 약 30분(+ DNS 전파·색인 대기).
> 리포 코드·설정은 이미 jobcho.wiki 기준으로 커밋돼 있다(2026-07-16). 이 문서는
> **리포 밖에서 사람이 직접 해야 하는 작업**의 순서와 명령을 정리한 것이다.
> 막히면 해당 단계의 명령 출력 전체를 복사해 Claude 세션에 붙여넣고 진행한다.

## 0. 사전 조건

- [ ] **jobcho.wiki 도메인 구매 완료** (미구매 시 등록기관에서 먼저 구매 — .wiki TLD 취급처: Cloudflare Registrar, 가비아, Namecheap 등)
- [ ] 운영 서버(Oracle Cloud) SSH 접속 가능: `ssh ubuntu@<서버IP>`
- [ ] **리포 소유권 정리(1회, 중요)**: 현 서버의 `/home/ubuntu/loupit`는 root 소유라
  `ubuntu`로는 `git pull`이 'dubious ownership'으로, 정적 스왑(`web/dist` 쓰기)이
  권한 부족으로 실패한다. API(loupit-api)가 `User=ubuntu`로 도는 설계와 맞추려면
  소유권을 ubuntu로 정규화한다(sudo로 전부 도는 우회는 root 소유를 고착시키므로 지양):
  ```bash
  sudo chown -R ubuntu:ubuntu /home/ubuntu/loupit
  git config --global --add safe.directory /home/ubuntu/loupit
  ```
- [ ] 위 정리 후 리포를 최신으로: `cd /home/ubuntu/loupit && git pull`
- [ ] **백업 선행**: 배포 전 서빙 DB 백업을 확보한다(트렌딩 로그 등 비재현 데이터 보호).
  절차·복원은 `docs/OPS-backup.md` 참조.
- 참고: 현재 서버는 레거시 `job_change`가 별도 vhost로 서비스 중이어도 무방하다 —
  jobcho.wiki는 `server_name` 기준으로 분리된 새 vhost라 기존 사이트에 영향이 없다.

## 1. DNS 연결 (등록기관 관리 화면)

| 타입 | 호스트 | 값 | 비고 |
| --- | --- | --- | --- |
| A | `@` | `<서버 공인 IP>` | apex(jobcho.wiki) |
| A | `www` | `<서버 공인 IP>` | www → apex는 nginx가 301 처리 |
| TXT | `@` | (3단계에서 서치콘솔이 알려주는 값) | 소유권 확인 — 지금은 비워둠 |

확인(전파까지 수 분~수 시간):

```bash
dig +short jobcho.wiki A
dig +short www.jobcho.wiki A   # 둘 다 서버 IP가 나오면 통과
```

## 2. TLS 인증서 발급 + nginx 컷오버 (서버에서)

### 2-1. 부트스트랩: :80 ACME 통로 열기

`infra/nginx/loupit.conf`의 :443 블록은 인증서 파일을 참조하므로, **인증서가 없는 최초 1회**는
:80 전용 임시 conf로 ACME 챌린지 통로부터 연다:

```bash
sudo tee /etc/nginx/sites-available/jobcho-bootstrap.conf >/dev/null <<'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name jobcho.wiki www.jobcho.wiki;
    location ^~ /.well-known/acme-challenge/ {
        root /home/ubuntu/loupit/web;
        default_type "text/plain";
    }
    location / { return 404; }
}
EOF
sudo ln -sf /etc/nginx/sites-available/jobcho-bootstrap.conf /etc/nginx/sites-enabled/jobcho-bootstrap.conf
sudo nginx -t && sudo systemctl reload nginx
```

### 2-2. 인증서 발급 (Let's Encrypt, webroot 방식 — SP-INFRA-4.1)

```bash
sudo certbot certonly --webroot -w /home/ubuntu/loupit/web \
  -d jobcho.wiki -d www.jobcho.wiki \
  --agree-tos -m <운영자 이메일> --no-eff-email
# 성공 시: /etc/letsencrypt/live/jobcho.wiki/{fullchain.pem,privkey.pem}
```

### 2-3. 정식 conf 배치 (부트스트랩 제거)

```bash
cd /home/ubuntu/loupit
sudo cp infra/nginx/loupit.conf /etc/nginx/sites-available/loupit.conf
sudo cp infra/nginx/snippets/loupit-security.conf /etc/nginx/snippets/loupit-security.conf
sudo ln -sf /etc/nginx/sites-available/loupit.conf /etc/nginx/sites-enabled/loupit.conf
sudo rm -f /etc/nginx/sites-enabled/jobcho-bootstrap.conf
sudo nginx -t && sudo systemctl reload nginx
```

### 2-4. 환경변수 확인 (env가 코드 기본값을 덮어쓰므로 필수)

`server/.env`(와 베타를 쓰면 `server/.env.beta`)에 예전 도메인이 남아있으면 갱신:

```bash
grep -n 'CORS_ALLOW_ORIGINS\|SITE_ORIGIN\|POLICY_CONTACT' server/.env server/.env.beta 2>/dev/null
# CORS_ALLOW_ORIGINS=https://jobcho.wiki,https://www.jobcho.wiki 로 수정.
# SITE_ORIGIN 줄이 있다면 https://jobcho.wiki 로(없으면 코드 기본값이 이미 jobcho.wiki).
```

## 3. 배포 파이프라인 실행 (정적 생성물에 새 도메인 반영)

canonical·OG·sitemap의 절대 URL은 빌드타임에 박히므로 **정적 생성을 반드시 재실행**한다:

```bash
cd /home/ubuntu/loupit
bash infra/deploy/release.sh   # 대화형 [y/N] 확인 후 진행(비대화형은 RELEASE_CONFIRM=1)
# 순서: 테스트 게이트 → schema(멱등) → 서빙 적재 검증 → generate/스왑
#       → API 재시작(loupit-api + loupit-beta-api) → nginx reload → 스모크
```

> ⚠ **다운타임 창(정직 서술)**: 이 서버는 서빙 스키마 LOUPIT을 테스트에도 재사용하므로,
> 첫 단계 테스트 게이트의 백엔드 구간에서 참조 5테이블이 일시 DROP/CREATE되었다가
> 게이트 종료 시 재시드로 복원된다 — **약 10초 내외의 서빙 다운타임 창**이 매 릴리스마다
> 있다(공유 스키마 구조상 불가피). 게이트가 통과하면 그 시점에 서빙 DB가 최신 시드로 이미
> 복원돼 있어, 이후 단계는 재시드하지 않고 COUNT로 적재만 검증한다.

빠른 부분 배포만 원하면(스키마·시드 무변경 시 — 정적만 재생성):

```bash
/usr/bin/python3 -m generator.build --out web/dist   # venv 미프로비저닝 → 시스템 python3
sudo systemctl restart loupit-api loupit-beta-api     # 양쪽 참조 캐시 무효화(동일 서빙 DB)
sudo systemctl reload nginx
```

스모크(전 케이스 종료코드 판정):

```bash
BASE=https://jobcho.wiki bash infra/deploy/smoke.sh   # SMOKE PASS 확인
```

## 4. 검색엔진 등록 (색인 기반 만들기)

### Google Search Console — https://search.google.com/search-console

1. "속성 추가" → **도메인** 속성으로 `jobcho.wiki` 입력
2. 안내되는 **TXT 레코드**를 1단계 DNS에 추가 → 확인 버튼(전파 대기 수 분)
3. 색인 → **Sitemaps** → `https://jobcho.wiki/sitemap.xml` 제출
4. "URL 검사"에 대표 회사 페이지 몇 개(`https://jobcho.wiki/company/<slug>`)를 넣고 **색인 생성 요청**

### 네이버 서치어드바이저 — https://searchadvisor.naver.com

1. 웹마스터 도구 → 사이트 등록 `https://jobcho.wiki`
2. 소유 확인(HTML 태그 방식보다 **DNS TXT** 권장 — 셸 수정 불필요)
3. 요청 → **사이트맵 제출**: `https://jobcho.wiki/sitemap.xml`
4. 웹 페이지 수집 요청으로 대문·대표 회사 페이지 수집 유도

## 5. (선택) 기존 loupit.co 301 승계

loupit.co 도메인을 계속 보유한다면, 해당 vhost에서 전량 301을 걸어 기존 색인 평가를 승계:

```nginx
server {  # loupit.co vhost에 추가/교체
    listen 443 ssl; server_name loupit.co www.loupit.co;
    ssl_certificate     /etc/letsencrypt/live/loupit.co/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/loupit.co/privkey.pem;
    return 301 https://jobcho.wiki$request_uri;
}
```

Search Console의 기존 loupit.co 속성에서 "주소 변경" 도구까지 쓰면 승계가 가장 확실하다.

## 6. 완료 체크리스트

- [ ] `https://jobcho.wiki/` 200 + 자물쇠(TLS 유효)
- [ ] `http://jobcho.wiki/` → 301 → https
- [ ] `https://www.jobcho.wiki/` → 301 → apex
- [ ] `https://jobcho.wiki/sitemap.xml` · `/robots.txt` 200, 내부 URL이 전부 jobcho.wiki
- [ ] `https://jobcho.wiki/company/<slug>` 아무거나 200 + `<title>…| jobcho.wiki`
- [ ] `https://jobcho.wiki/assets/og-default.png` 200 (공유 미리보기 이미지)
- [ ] Search Console sitemap 상태 "성공" (제출 후 수 일 내)

## 롤백

- nginx만 되돌리기: `sudo rm /etc/nginx/sites-enabled/loupit.conf && sudo nginx -t && sudo systemctl reload nginx` (기존 vhost 무영향)
- `release.sh`는 재구조화(2026-07-18) 후 **테스트 게이트가 [1/7]로 맨 앞**이라, 게이트 실패 시
  정적 생성(build/스왑)은 아예 실행되지 않으므로 **정적 산출물(web/dist)은 이전본 그대로**다.
  단, 게이트 자체가 백엔드 구간에 참조 테이블을 일시 비웠다 복원하므로(위 다운타임 창) 게이트가
  중간에 죽으면 서빙 DB가 비어 있을 수 있다 — run_tests.sh의 trap이 종료 시 재시드를 '시도'하되,
  실패 시 큰 경고와 함께 수동 복구를 안내한다(`LOUPIT_ALLOW_FRESH=1 python3 db/seed/load.py --fresh`
  + `sudo systemctl restart loupit-api loupit-beta-api`). build/스왑([4/7]) 이후 단계 실패는 새 정적물이
  이미 라이브이므로, 되돌리려면 `web/dist.prev` 존재를 확인해 수동 스왑한다.

## 검색 노출에 대한 솔직한 기대치

색인(위 4단계)은 우리가 통제하지만 **순위는 통제 대상이 아니다**. "회사명 + 복지" 류 쿼리에서
상위 노출될 조건은 이미 갖춰져 있다(회사별 고유 title·description·JSON-LD Organization·
canonical·sitemap, JS 없이 읽히는 본문). 신규 도메인은 통상 수 주간 색인·평가 기간을 거치므로,
Search Console의 "실적" 리포트로 노출 추이를 관찰하면서 콘텐츠(회사 수·조합 페이지)를 늘리는
것이 가장 효과 있는 레버다.
