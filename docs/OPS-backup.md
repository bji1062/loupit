# OPS — MySQL 백업·복원 운영 가이드

> 대상: 운영자 1인. 근거: SP-INFRA-10.2, 감사 2026-07-17(#5·#16·#18).
> 관련 파일: `infra/deploy/backup.sh`, `infra/deploy/restore.sh`,
> `infra/systemd/loupit-backup.{service,timer}`, `infra/env/backup.env.example`.

## 0. 무엇을·왜 백업하나

- 서빙 DB **`LOUPIT`**(대문자) 전체를 매일 03:00 `mysqldump`로 gzip 백업(`/var/backups/loupit`, 기본 14일 보관).
- 참조 5테이블(TCOMPANY 등)은 시드에서 재현 가능하지만, **`TCOMPARE_LOG`**(익명 비교 로그 = '실시간 비교 TOP 10' 트렌딩의 원천)는 시드로 재현 불가하다. 이 데이터의 **유일한 복구 수단이 이 백업**이다.
- `run_tests.sh`/`release.sh`가 서빙 테이블을 드랍·재시드하는 구조이므로, 백업 없이는 사고·오조작 시 복구 불능이다.

## 1. 설치(호스트 1회)

⚠ 아래 3단계는 **순서가 중요**하다. env 파일이 없으면 타이머 첫 실행이 실패한다.

### 1-1. 크레덴셜 env 파일 생성(미커밋)

```bash
cd /home/ubuntu/loupit
cp infra/env/backup.env.example infra/env/backup.env
# DB_PASSWORD 등 실값을 채운다. 실계정은 APP_LOUPIT(ALL ON LOUPIT.*).
$EDITOR infra/env/backup.env
chmod 600 infra/env/backup.env
chown ubuntu:ubuntu infra/env/backup.env
```

`backup.env`는 `.gitignore`로 커밋에서 제외된다(템플릿 `backup.env.example`만 커밋). 키:

| 키 | 기본값 | 비고 |
|---|---|---|
| `DB_HOST` | `127.0.0.1` | |
| `DB_PORT` | `3306` | |
| `DB_USER` | `APP_LOUPIT` | 실계정. 덤프는 SELECT만 필요 |
| `DB_PASSWORD` | (필수) | 미설정 시 스크립트가 명확히 실패 |
| `DB_NAME` | `LOUPIT` | **대문자**(서빙 스키마) |
| `BACKUP_DIR` | `/var/backups/loupit` | 1차 사본(루트 디스크) |
| `RETENTION_DAYS` | `14` | |
| `MIRROR_DIR` | (없음) | 2차 사본 경로. 비면 미러 없음 |
| `MIRROR_RETENTION_DAYS` | `7` | 1차와 **독립** 보관 주기 |

### 1-1b. 2차 사본(미러) — 디바이스 장애 대비 (2026-07-29)

1차는 루트 디스크(`/`)에, 2차는 **별도 iSCSI 볼륨**(`/db`)에 둔다. 한쪽 디바이스가 죽어도
다른 쪽이 남는다:

| 잃는 것 | 남는 것 |
|---|---|
| 루트 디스크 | `/db/backups/loupit` 미러(7일분) + 살아 있는 DB |
| `/db` 볼륨 (DB 데이터 + 미러 동시 손실) | `/var/backups/loupit` 1차(14일분) |
| **머신 전체** | **없음 — 미해결 위험** |

> ⚠ **이건 서버 밖 사본이 아니다.** 머신을 잃으면 두 사본을 함께 잃는다. 실회원·재직인증·
> 편집이력은 시드로 재현할 수 없으므로 서버 밖 사본은 여전히 남은 과제다.

동작 규칙 — `backup.sh` 는 **1차를 확정한 뒤에만** 미러를 만진다. 미러가 실패해도 1차는
그대로 남고, 종료코드만 비0으로 올려 systemd 가 실패로 표시한다(조용한 미러 실패는 미러가
없는 것보다 나쁘다 — 있다고 믿게 만들기 때문이다). 사본은 복사 후 `gunzip -t` 로 독립
검증하고, 임시 파일을 미러 파일시스템 안에서 만들어 `mv` 가 원자적 rename 이 되게 한다.

⚠ **`MIRROR_DIR` 은 전용 하위 디렉터리여야 한다.** 로테이션이 `loupit-*.sql.gz` 글롭으로
지우므로, 다른 덤프가 섞인 디렉터리를 가리키면 그것까지 삭제된다(`/db/backups` 직하에
`loupit-3db-premigrate-20260727.sql.gz` 가 있다 — 그래서 `/db/backups/loupit` 을 쓴다).

계약은 `server/tests/test_backup_mirror.py`(BK-1~BK-5)가 소유한다.

### 1-2. 디렉토리·유닛 배치 (provision.sh 해당 단계)

`provision.sh` [3/6]가 `/var/backups/loupit`를 생성·`chown ubuntu`·`chmod 750`하고, [4/6]가
`loupit-backup.service`/`.timer`를 `/etc/systemd/system/`에 복사한다. 전체 재프로비저닝이 부담되면 해당 단계만 수동 실행:

```bash
sudo mkdir -p /var/backups/loupit
sudo chown ubuntu:ubuntu /var/backups/loupit
sudo chmod 750 /var/backups/loupit
sudo install -d -o ubuntu -g ubuntu -m 750 /db/backups/loupit   # 2차 사본(미러)
sudo cp infra/systemd/loupit-backup.service /etc/systemd/system/
sudo cp infra/systemd/loupit-backup.timer   /etc/systemd/system/
sudo systemctl daemon-reload
```

### 1-3. 타이머 가동

```bash
sudo systemctl enable --now loupit-backup.timer
systemctl list-timers loupit-backup.timer   # NEXT 시각이 다음 03:00 인지 확인
```

`provision.sh`는 위 `enable --now`를 [4/6] 끝에 포함한다(단, 1-1 env가 선행돼야 첫 실행 성공).

### 1-4. 첫 백업 즉시 실행(검증)

```bash
sudo systemctl start loupit-backup.service
journalctl -u loupit-backup -n 20 --no-pager     # "backup done: ..." 확인
ls -lh /var/backups/loupit/                        # loupit-YYYYMMDD.sql.gz 생성 확인
```

## 2. 정상 동작 확인

```bash
systemctl list-timers loupit-backup.timer          # 다음 실행 시각
journalctl -u loupit-backup --since today           # 마지막 실행 로그
ls -lh /var/backups/loupit/                         # 파일 존재·크기(>0)
gunzip -t /var/backups/loupit/loupit-*.sql.gz && echo "gz OK"   # 무결성
```

정상 백업은 gzip 무결성 통과 + 내부에 `-- Dump completed` 트레일러를 갖는다(backup.sh가 이 둘을 검증 후에만 최종 파일로 확정하므로, `loupit-*.sql.gz`로 남은 파일은 검증 통과분이다). 검증 실패분은 `.partial.<pid>`로 남았다가 정리된다.

### 2-1. 복원 훈련 — "온전한가"와 "되살릴 수 있는가"는 다른 질문이다 (2026-07-30)

위 검사는 전부 **파일이 온전한가**를 본다. 그 사이에 스키마 변경·권한·문자셋·FK 순서·덤프
옵션이 조용히 끼어든다. **복원해 본 적 없는 백업은 백업이 아니라 백업이라는 믿음이다.**

`loupit-restore-drill.timer` 가 **주 1회 일요일 03:30 UTC(12:30 KST)** 최신 백업을
`loupit_test` 로 실제 복원해 검증하고 다시 비운다.

```bash
systemctl list-timers loupit-restore-drill.timer
journalctl -u loupit-restore-drill -n 30
cat /var/backups/loupit/restore-drill.json      # 마지막 결과(일일 요약 메일이 이걸 읽는다)
sudo systemctl start loupit-restore-drill.service          # 즉시 1회
DRILL_SRC=/var/backups/loupit/loupit-20260728.sql.gz \
  bash infra/deploy/restore-drill.sh                        # 특정 파일로
```

검증 항목 — "에러가 없었다"가 아니라 **쓸 수 있는 상태인가**를 본다:

| # | 검사 | 잡는 것 |
|---|---|---|
| 0 | 드롭 직후 테이블 0개(**양성 대조군**) | 드롭이 조용히 실패해 **낡은 데이터로 통과**하는 것 |
| 1 | 덤프의 `CREATE TABLE` 이 전부 실제로 생성됨 | 부분 복원·중간 중단 |
| 2 | `TCOMPANY`·`TCOMPANY_BENEFIT`·`TCOMPANY_TYPE`·`TBENEFIT_PRESET` 비어 있지 않음 | 구조만 남고 데이터를 잃은 덤프 |
| 3 | 복지 → 회사 고아 행 0 | 덤프 주입이 FK 검사를 끄고 돌아 생긴 순서 파손 |

⚠ **왜 `loupit_test` 인가**: DB 계정(`APP_LOUPIT`)은 `LOUPIT`·`loupit_beta`·`loupit_test`
세 곳에만 권한이 있고 **CREATE DATABASE 권한이 없다**. 앞의 둘은 라이브라 스크립트가 이름으로
거부한다. 그래서 훈련 중 **프로덕션 데이터가 잠시 테스트 DB 에 존재**하며, 종료 트랩이 무조건
전 테이블을 지우고 비었는지 다시 확인한다.

⚠ **pytest 와 같은 DB 를 쓴다** → 양쪽이 `/run/lock/loupit-testdb.lock` 을 flock 한다. 훈련은
잠겨 있으면 건너뛰고(상태 파일은 **건드리지 않는다** — 건너뜀을 실패로 기록하면 직전 성공을
덮어 오보가 된다), pytest 는 최대 180초 기다린 뒤 이유를 말하고 중단한다.
락 파일은 `/etc/tmpfiles.d/loupit.conf` 가 **0666 으로 선언**한다 — 한쪽이 0644 로 먼저 만들면
다른 쪽이 열지 못해 훈련이 죽는다(2026-07-30 실발현).

**관측은 일일 요약 메일이 한다.** 훈련이 실패해도 아무도 안 보면 훈련이 아니다. 새 발송 경로를
만드는 대신 배달까지 실증된 채널에 얹었다. 요약은 **실패·낡음(10일 초과)·상태를 못 읽음** 셋 다
🔴 로 띄우고 제목에도 표시하며, `--only-if-pending` 이어도 훈련 알람은 뚫고 나간다.

> ⓘ 백업 이후 스키마를 추가한 날에는 "서빙에는 있으나 이 백업에는 없는 테이블" 경고가 뜬다.
> 그날 하루는 정상이고 다음 03:00 백업이 해소한다. **며칠 지속되면 백업 경로를 의심하라.**

## 3. 복원

⚠ 파괴적 작업. `restore.sh`가 대상 DB를 출력하고 `yes` 확인을 요구한다(`RESTORE_CONFIRM=1`로 생략 가능).
`restore.sh`는 `infra/env/backup.env`를 자동 로드한다.

### 3-1. 전체 복원

```bash
cd /home/ubuntu/loupit
infra/deploy/restore.sh /var/backups/loupit/loupit-20260718.sql.gz
# 복원 후 안내대로 API 재시작(참조 캐시 갱신):
sudo systemctl restart loupit-api loupit-beta-api
```

### 3-2. 부분 복원(테이블 단위) — 예: TCOMPARE_LOG만

테스트 게이트 등으로 비교 로그만 유실됐고 참조 테이블은 온전할 때:

```bash
infra/deploy/restore.sh /var/backups/loupit/loupit-20260718.sql.gz TCOMPARE_LOG
sudo systemctl restart loupit-api loupit-beta-api
```

부분 복원은 대상 테이블의 부모(FK 참조 대상, `TCOMPARE_LOG`→`TCOMPANY`)가 **이미 존재**한다고 가정한다.
전 테이블 섹션을 임시 파일에 조립·검증한 뒤 일괄 주입하므로, 지정 테이블 중 하나라도 덤프에 없으면 아무것도 반영하지 않고 실패한다.

## 4. 보관 정책

- 매일 03:00 1개 파일, 파일명 `loupit-YYYYMMDD.sql.gz`(같은 날 재실행 시 덮어씀).
- `RETENTION_DAYS`(기본 14)일 초과 파일은 backup.sh가 자동 삭제. `.partial.*` 잔여물은 1일 후 청소.

## 5. 함정 (감사에서 확인 — 설계에 반영됨)

1. **`--protocol=TCP` 필수**: DB 그랜트가 `@127.0.0.1` 한정이라 소켓 접속(`localhost`)은 *Access denied*. backup.sh/restore.sh는 defaults 파일에 `protocol=TCP`를 넣는다.
2. **`LOUPIT`는 대문자**: 실호스트 `lower_case_table_names=0`이라 소문자 `loupit`는 **별개(존재하지 않는) DB**. `DB_NAME` 기본을 `LOUPIT`로 고정.
3. **PROCESS 권한 회피**: mysqldump 8.0.21+는 `--no-tablespaces` 없으면 전역 PROCESS 권한 필요. DB 계정엔 없으므로 `--no-tablespaces` 필수(적용됨).
4. **크레덴셜은 프로세스 목록에 노출 금지**: `-pXXXX` 대신 mode 600 임시 defaults 파일로 전달.
5. **원자성**: 임시 파일에 덤프→gzip·트레일러 검증 통과 후에만 최종 이름으로 `mv`. 잘린 백업이 정상처럼 남지 않는다.
6. **MySQL cnf(tarball 함정, #18)**: 실호스트 MySQL은 tarball 설치(`/data/mysql`)로 `/etc/my.cnf`만 읽고 `/etc/mysql/`은 부재. `infra/mysql/loupit.cnf`는 apt 설치 경로에서만 자동 적용되며, 이 호스트에는 항목을 `/etc/my.cnf`에 수동 병합해야 한다(백업 자체와는 무관, provision.sh는 부재 시 스킵·경고).

## 6. 트러블슈팅

| 증상 | 원인·조치 |
|---|---|
| `DB_PASSWORD 미설정` | `infra/env/backup.env` 부재/미주입 — 1-1 수행 |
| `Access denied ... using password` | 소켓 접속(그랜트 `@127.0.0.1`) 또는 비번 오류 — `protocol=TCP` 확인, 비번 재확인 |
| `Unknown database 'loupit'` | `DB_NAME`이 소문자 — `LOUPIT`로 |
| `you need ... PROCESS privilege` | `--no-tablespaces` 누락(구버전 스크립트) — 최신 backup.sh 확인 |
| 백업 파일이 안 생김 | `systemctl status loupit-backup.timer`, `journalctl -u loupit-backup`, `/var/backups/loupit` 소유권(ubuntu) 확인 |
