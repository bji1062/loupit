#!/usr/bin/env bash
# infra/deploy/firewall.sh — SP-INFRA-8.1 호스트 계층 방화벽(nftables). 2계층 차단의 두 번째
# 방어선(첫 번째는 OCI Security List/NSG — 클라우드 콘솔에서 별도 설정, 아래 문서 참고).
#
# ── 클라우드 계층(OCI Security List / NSG) — 본 스크립트가 다루지 않음, 콘솔/Terraform로 설정 ──
#   인바운드 허용: 22/tcp(관리 CIDR 한정) · 80/tcp(0.0.0.0/0) · 443/tcp(0.0.0.0/0)
#   3306·8000 규칙 부재(암묵 차단) — 신규 포트는 OCI·호스트 양쪽 개방 필요.
#
# ── 호스트 계층(nftables) — 본 스크립트가 적용 ──
#   22(관리 IP)·80·443 allow, established/related 유지, 그 외 drop.
#   최종 방어선은 loopback 바인딩(mysql 3306, uvicorn 8000 = 127.0.0.1, SP-INFRA-5·6)이며
#   방화벽은 defense-in-depth 계층이다(INV-7·NFR22).
#
# 사용: sudo bash infra/deploy/firewall.sh [관리_CIDR]  (기본 관리_CIDR=0.0.0.0/0 — 배포 시 반드시 좁힐 것)
set -euo pipefail
MGMT_CIDR="${1:-0.0.0.0/0}"

echo "관리 CIDR: ${MGMT_CIDR} (SSH 22/tcp 허용 대상 — 배포 시 실제 관리 IP로 좁혀서 재실행 권장)"

sudo nft -f - <<EOF
table inet loupit_filter {
  chain input {
    type filter hook input priority 0; policy drop;

    ct state established,related accept
    iif lo accept
    ip protocol icmp accept
    # IPv6 필수 ICMPv6 허용(policy drop 하에서 NDP·PMTUD·MLD가 막히면 IPv6 전면 불통 — 감사 low #13).
    # icmpv6 매치는 nft가 자동으로 nfproto ipv6 로 한정한다. NDP는 MLD(Hop-by-Hop) 때문에 nexthdr 미사용.
    icmpv6 type { destination-unreachable, packet-too-big, time-exceeded, parameter-problem, echo-request, echo-reply, nd-router-solicit, nd-router-advert, nd-neighbor-solicit, nd-neighbor-advert, mld-listener-query, mld-listener-report, mld-listener-done } accept

    tcp dport 22 ip saddr ${MGMT_CIDR} accept
    tcp dport { 80, 443 } accept

    # 3306(mysql)·8000(uvicorn)은 의도적으로 허용 규칙 부재(암묵 차단, INV-7)
  }
  chain forward { type filter hook forward priority 0; policy drop; }
  chain output  { type filter hook output priority 0; policy accept; }
}
EOF

echo "nftables 규칙 적용 완료 — 'sudo nft list ruleset'으로 확인"
echo "영속화: sudo nft list ruleset | sudo tee /etc/nftables.conf && sudo systemctl enable nftables"
