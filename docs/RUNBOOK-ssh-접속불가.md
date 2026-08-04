# RUNBOOK — SSH 접속 불가 진단·복구 (Oracle Cloud)

> 대상: 운영자 1인. 호스트 `158.180.79.39`(`jobcho.wiki`) · 계정 `ubuntu`.
> 근거: SP-INFRA-8.1·8.2, 감사 2026-07-17(#8·#18), `docs/HANDOFF-2026-07-30.md` §5-b.
> 관련 파일: `infra/deploy/firewall.sh`, `infra/deploy/sshd-hardening.conf`, `infra/deploy/provision.sh`.

## 0. 먼저 알아야 할 실호스트 사실 — 리포 설정과 실서버가 다르다

진단을 헛짚지 않으려면 이 셋을 전제로 깔아야 한다. **리포에 있다고 서버에 적용된 게 아니다.**

| 사실 | 근거 | 진단상 의미 |
|---|---|---|
| **호스트 방화벽이 꺼져 있다** — `ufw inactive`, `nft list ruleset` 에 `loupit_filter` 부재. `firewall.sh` 는 이 호스트에 적용된 적이 **없다** | `docs/HANDOFF-2026-07-30.md` §5-b(2026-07-30 확인), 감사 #8 | **호스트 nftables 가 22 를 막는 시나리오는 배제**된다 |
| **리포의 sshd 하드닝도 적용된 적이 없다** — `provision.sh:49` 의 mysql cnf 복사가 `/etc/mysql/` 부재로 실패하고 `set -euo pipefail` 로 abort → 그 뒤의 sshd 하드닝 배치(`provision.sh:94`)·`firewall.sh`(`:122`)가 **조용히 누락** | 감사 #18 | `AllowUsers ubuntu`·`MaxAuthTries 3`·`LoginGraceTime 30` 은 **실서버에 없다**. 이걸 원인으로 의심하지 마라 |
| **22 를 거르는 계층은 OCI Security List / NSG 단 하나**다. `infra/terraform/` 은 비어 있어 콘솔에서 수동 관리된다 | SP-INFRA-8.1, `docs/SPEC/11-인프라-배포.md:846` | 네트워크 원인이면 **클라우드 계층 하나만 보면 된다** |

> ⚠ 이 문서가 기술한 "방화벽 꺼짐"은 **2026-07-30 시점 확인값**이다. 이후 `firewall.sh` 를
> 적용했다면(미결 항목이었다) 전제가 바뀐다 — §4 를 먼저 보라.

인스턴스 사양: `VM.Standard.A1.Flex`(Ampere ARM64) · **Always Free** · 춘천 · 1 OCPU / 6 GB
(`docs/SPEC/11-인프라-배포.md:52`~`59`, AS1).

## 1. 증상으로 갈라내기 — 에러 메시지가 원인을 결정한다

`ssh -vvv ubuntu@158.180.79.39` 를 실행하고 **어디서 멈추는지** 본다.

| 증상 | 원인 | 이동 |
|---|---|---|
| **타임아웃**(한참 멈췄다 끊김) | 패킷이 sshd 까지 못 간다 — 인스턴스 중지 또는 클라우드 계층 차단 | **§2** |
| `Permission denied (publickey)` | 네트워크는 열려 있다. 키·사용자 문제 | §3 |
| `Connection refused`(즉시 거부) | 네트워크는 닿는다. sshd 가 죽었다(디스크 풀 등) | §3 |
| `REMOTE HOST IDENTIFICATION HAS CHANGED` | 인스턴스 재생성 또는 IP 가 다른 호스트에 붙음 | §3 |

## 2. 타임아웃일 때 — 한 번의 확인으로 둘 중 하나

타임아웃이면 후보는 **딱 둘**이고, **사이트 생존 여부**가 그대로 판별식이다.

```bash
curl -sI https://jobcho.wiki | head -1   # 사이트 살아있나
curl -4 ifconfig.me                       # 내 현재 공인 IP
```

| | 원인 | 사이트 | 근거 |
|---|---|---|---|
| **A** | **인스턴스 중지 / Always Free 유휴 회수** | ❌ 같이 죽음 | §2-A |
| **B** | **OCI Security List 22/tcp 소스 CIDR ↔ 내 공인 IP 불일치** | ✅ 정상 | §2-B |

사이트가 살아있는데 SSH 만 타임아웃이면 **B 가 거의 확정**이다 — 80/443 은 `0.0.0.0/0`,
22 만 관리 CIDR 한정이라 **정확히 22 만 죽는 비대칭**이 나온다(SP-INFRA-8.1).

### 2-A. 인스턴스 중지 / Always Free 유휴 회수

Always Free 는 7일간 CPU·네트워크·메모리 사용률이 **모두 20% 미만**이면 Oracle 이 유휴로
판정해 회수·중지한다. 이 호스트는 **1 OCPU 에서 nginx 정적 서빙이 주 부하**이고 실트래픽이
**하루 고유 IP 2~10개**(`docs/HANDOFF-2026-07-31.md:33`)다 — **유휴 판정 조건에 그대로 들어맞는다.**
"트래픽이 없어서 서버가 꺼진다"는 이 프로젝트의 구조적 위험이지 우연이 아니다.

복구:

1. OCI 콘솔 → Compute → Instances → 인스턴스 상태 확인(`STOPPED` / `TERMINATED`).
2. `STOPPED` 면 **Start**. 부팅 후 서비스 자동 기동을 확인한다(전부 `enable` 돼 있다):
   `mysql` · `nginx` · `loupit-api` · `loupit-beta-api` · `loupit-backup.timer` ·
   `loupit-ops-digest.timer` · `loupit-restore-drill.timer` (`docs/HANDOFF-2026-07-31.md:29`).
3. `TERMINATED` 면 부트 볼륨이 남아 있는지 확인 — 남아 있으면 새 인스턴스에 붙여 복구한다.
   **부트 볼륨까지 사라졌다면 서버에만 존재하던 실행 상태는 전부 소실**이다
   (`docs/RESUME.md:24` — "배포된 실행 상태는 서버 호스트에만 존재·유지, 로컬 클론엔 없음").
   백업 경로는 `docs/OPS-backup.md`.

재발 방지: 유료 티어(Pay As You Go)로 업그레이드하면 유휴 회수 대상에서 빠진다. Always Free 를
유지하려면 사용률을 인위적으로 올리는 방법뿐인데, **이건 자원 낭비이자 AS1 의 취지에 반한다** —
회수를 감수하고 복구 절차를 갖추는 쪽이 이 프로젝트에 맞다.

### 2-B. OCI Security List 22/tcp 소스 CIDR 불일치

**가장 흔한 원인이고, 우리 문서가 이미 경고한 실패 모드다**:

> "IP 제한은 IP 가 바뀌면 **본인이 잠긴다**" — `docs/HANDOFF-2026-07-29-B.md:157`

국내 ISP 가정회선은 공인 IP 가 고정이 아니다. 공유기 재부팅·회선 점검·모뎀 교체로 바뀌고,
**집이 아닌 곳(회사·모바일 테더링·카페)에서 접속해도 당연히 다른 IP** 다.

확인:

1. `curl -4 ifconfig.me` 로 현재 공인 IP 를 얻는다.
2. OCI 콘솔 → Networking → VCN → Subnet → **Security List**(NSG 를 쓴다면 NSG)
   → Ingress Rules 에서 **22/tcp 규칙의 Source CIDR** 을 확인한다.
3. 1번 IP 가 2번 CIDR 에 포함되지 않으면 **원인 확정**이다.

복구 — Ingress 규칙의 22/tcp Source CIDR 을 현재 IP 로 갱신한다(`<현재IP>/32`).

> ⚠ **22 를 `0.0.0.0/0` 으로 열어 임시 해결하지 마라.** 실서버엔 §0 대로 sshd 하드닝이
> 적용돼 있지 않다 — `PasswordAuthentication no` 도, `AllowUsers ubuntu` 도, `MaxAuthTries 3` 도
> 없는 상태다. 전면 개방은 하드닝 없는 sshd 를 인터넷에 그대로 내놓는 것이다.
> 부득이 열었다면 접속 직후 §4 를 실행하고 CIDR 을 즉시 되돌려라.

**콘솔 잠금을 못 푸는 경우** — CIDR 을 고칠 권한·경로가 막혔다면 네트워크를 우회해 들어간다:

- **인스턴스 콘솔 연결(Serial Console)**: OCI 콘솔 → 인스턴스 → Console connection.
  **Security List 를 전혀 타지 않으므로** 네트워크 차단 상태에서도 붙는다. SSH 잠금의 정식 탈출구다.
- **Cloud Shell**: 브라우저 안에서 뜨는 셸이라 내 공인 IP 와 무관하다.

## 3. 타임아웃이 아닐 때

네트워크는 이미 통과한 상태다 — 클라우드 계층은 범인이 아니다.

| 증상 | 확인 | 조치 |
|---|---|---|
| `Permission denied (publickey)` | 사용자명이 **`ubuntu`** 인가(OCI Ubuntu 이미지 기준). `opc`·`root` 아니다. 키 경로(`-i`)와 권한(`600`) | 올바른 키로 재시도. 키 분실 시 §2-B 의 Serial Console 로 들어가 `~/.ssh/authorized_keys` 복구 |
| `Connection refused` | 사이트도 죽었나. 살아있다면 sshd 만 죽은 것 | Serial Console 로 진입 → `df -h`(디스크 풀 확인, 루트가 100% 면 sshd 가 fork 실패한다) → `systemctl status ssh` → `systemctl restart ssh` |
| `HOST IDENTIFICATION HAS CHANGED` | 인스턴스를 재생성했나 | 재생성이 사실이면 `ssh-keygen -R 158.180.79.39`. **재생성한 적이 없다면 조사부터 하라** |

디스크는 상시 여유가 넉넉하지 않다 — 루트 **62%**(2026-07-30 기준, `docs/HANDOFF-2026-07-30.md:32`).
`Connection refused` 에서 디스크 풀은 충분히 현실적인 후보다.

## 4. 접속 복구 후 — 남은 뿌리 원인을 닫아라

접속만 살리고 끝내면 §0 의 세 사실이 그대로 남는다.

1. **sshd 하드닝을 실제로 적용한다**(감사 #18 로 누락된 채다):

   ```bash
   sudo cp infra/deploy/sshd-hardening.conf /etc/ssh/sshd_config.d/loupit.conf
   sudo sshd -t && sudo systemctl reload ssh
   ```

   ⚠ `sshd -t` 가 통과한 뒤에만 reload 한다. **그리고 현재 세션은 끊지 말고**, 새 터미널로
   접속이 되는 것을 확인한 다음 닫아라 — 설정 오류로 자기를 잠그는 가장 흔한 경로다.

2. **호스트 방화벽을 켠다**(미결 항목, `-30` §5-b). 관리 CIDR 을 반드시 좁혀서 실행한다:

   ```bash
   sudo bash infra/deploy/firewall.sh <현재IP>/32
   ```

   ⚠ 이 스크립트는 `policy drop` 이다. **CIDR 을 틀리면 그 즉시 자기를 잠근다.**
   Serial Console 접속 경로를 먼저 확보해 두고 실행하라. 영속화는 스크립트 말미 안내대로.

3. **`provision.sh` 의 조용한 abort 를 고친다** — 이게 1·2 가 누락된 진짜 원인이다.
   `provision.sh:49` 의 mysql cnf 복사는 이 호스트(tarball 설치, `/etc/my.cnf` 사용)에서 반드시
   실패하고, `set -euo pipefail` 이 그 뒤 전부를 삼킨다. 보안 단계가 mysql 튜닝 실패에
   종속되지 않도록 분리해야 재발하지 않는다.
