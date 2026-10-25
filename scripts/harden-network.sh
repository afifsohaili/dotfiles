#!/bin/bash
set -euo pipefail

# Lock this machine down so the only way in is Tailscale.
# LAN keeps LocalSend only. Docker published ports stop bypassing ufw.
#
#   ./scripts/harden-network.sh --check

#   sudo ./scripts/harden-network.sh --apply
#   sudo ./scripts/harden-network.sh --apply --rebind-redis

TAILSCALE_IF="${TAILSCALE_IF:-tailscale0}"
LAN_IF="${LAN_IF:-$(ip -4 route show default 2>/dev/null | awk '{print $5; exit}')}"
LAN_CIDR="${LAN_CIDR:-$(ip -4 -o addr show "$LAN_IF" 2>/dev/null | awk '{print $4; exit}')}"
BACKUP_ROOT="/var/backups/ufw-hardening"
SYSCTL_FILE="/etc/sysctl.d/99-network-hardening.conf"
UFW_FILES=(before.rules before6.rules after.rules after6.rules user.rules user6.rules ufw.conf)

APPLY=0
REBIND_REDIS=0

for arg in "$@"; do
  case "$arg" in
    --check) APPLY=0 ;;
    --apply) APPLY=1 ;;
    --rebind-redis) REBIND_REDIS=1 ;;
    -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
    *) echo "Unknown argument: $arg" >&2; exit 2 ;;
  esac
done

say() { printf '%s\n' "$*"; }
ok()  { printf '  ok    %s\n' "$*"; }
bad() { printf '  RISK  %s\n' "$*"; }
act() { printf '  apply %s\n' "$*"; }

need_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "This step needs root: sudo $0 --apply" >&2
    exit 1
  fi
}

preflight() {
  command -v ufw >/dev/null || { echo "ufw missing" >&2; exit 1; }
  systemctl is-active --quiet tailscaled || { echo "tailscaled is not running; refusing to lock the door with no way back in" >&2; exit 1; }
  tailscale ip -4 >/dev/null 2>&1 || { echo "tailscale has no IPv4 address; refusing" >&2; exit 1; }
  [[ -n "$LAN_IF" ]] || { echo "no default route; cannot detect LAN interface" >&2; exit 1; }
}

can_read_ufw() {
  [[ -r /etc/ufw/user.rules ]]
}

show_state() {
  say ""
  say "== State =="

  if ! can_read_ufw; then
    say "  note  /etc/ufw/* and iptables are root-only; run 'sudo $0 --check' for the full picture"
  fi

  if systemctl is-active --quiet ufw; then
    ok "ufw active"
  else
    bad "ufw inactive"
  fi

  local in_pol fw_pol
  in_pol=$(grep -oP '^DEFAULT_INPUT_POLICY="\K[^"]+' /etc/default/ufw 2>/dev/null || echo unknown)
  fw_pol=$(grep -oP '^DEFAULT_FORWARD_POLICY="\K[^"]+' /etc/default/ufw 2>/dev/null || echo unknown)
  [[ "$in_pol" == DROP ]] && ok "default incoming: DROP" || bad "default incoming: $in_pol"
  [[ "$fw_pol" == DROP ]] && ok "default forward: DROP" || bad "default forward: $fw_pol"

  if can_read_ufw; then
    if grep -qE '^### tuple ### allow (tcp|udp) 53317 0\.0\.0\.0/0' /etc/ufw/user.rules; then
      bad "LocalSend 53317 open to 0.0.0.0/0"
    else
      ok "LocalSend scoped to LAN interface, not 0.0.0.0/0"
    fi

    if grep -q '^-A ufw-user-forward -i '"$TAILSCALE_IF"' ' /etc/ufw/user.rules; then
      ok "tailnet traffic allowed into containers"
    else
      bad "no tailnet forward rule; published containers unreachable over Tailscale"
    fi

    if grep -qE '^-A DOCKER-USER -j RETURN -s (192\.168\.0\.0/16|10\.0\.0\.0/8)$' /etc/ufw/after.rules; then
      bad "DOCKER-USER lets LAN and 10/8 bypass ufw"
    else
      ok "DOCKER-USER no longer exempts LAN"
    fi

    if grep -q '^-A DOCKER-USER -j RETURN -s 172\.16\.0\.0/12$' /etc/ufw/after.rules; then
      ok "container-to-container traffic preserved (172.16/12)"
    else
      bad "172.16/12 exemption removed; cross-bridge containers will break"
    fi
  fi

  local exposed
  exposed=$(ss -tulpnH 2>/dev/null | awk '$5 ~ /^(0\.0\.0\.0|\*|\[::\]):/ {n=split($5,a,":"); if (a[n] == "53317" || a[n] == "41641") next; print $1, $5, $7}' | sort -u || true)
  if [[ -n "$exposed" ]]; then
    bad "listeners bound to all interfaces (ufw blocks LAN, tailnet still reaches them):"
    while IFS= read -r line; do printf '        %s\n' "$line"; done <<< "$exposed"
  else
    ok "no unexpected wildcard listeners"
  fi

  if ss -tulpnH 2>/dev/null | grep -qE ':6379\s'; then
    if ss -tulpnH 2>/dev/null | awk '$5 ~ /^(0\.0\.0\.0|\*|\[::\]):6379$/ {found=1} END {exit !found}'; then
      bad "redis on all interfaces, no auth; any tailnet device can reach it"
    else
      ok "redis bound to loopback"
    fi
  fi

  if systemctl is-enabled --quiet sshd 2>/dev/null; then bad "sshd enabled"; else ok "sshd disabled"; fi
  if systemctl is-active --quiet avahi-daemon; then bad "avahi advertising on Wi-Fi"; else ok "avahi off"; fi

  local kptr
  kptr=$(sysctl -n kernel.kptr_restrict 2>/dev/null || echo 0)
  if [[ "$kptr" =~ ^[0-9]+$ ]] && (( kptr >= 2 )); then
    ok "kernel.kptr_restrict=$kptr"
  else
    bad "kernel.kptr_restrict=$kptr (want 2)"
  fi
}

backup() {
  local dir="$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)"
  install -d -m 700 "$dir"
  local f
  for f in "${UFW_FILES[@]}"; do
    [[ -f "/etc/ufw/$f" ]] && cp -a "/etc/ufw/$f" "$dir/"
  done
  cp -a /etc/default/ufw "$dir/" 2>/dev/null || true
  say "backup: $dir"
}

patch_docker_exemptions() {
  local file=/etc/ufw/after.rules
  local tmp
  tmp=$(mktemp)
  grep -vE '^-A DOCKER-USER -j RETURN -s (192\.168\.0\.0/16|10\.0\.0\.0/8)$' "$file" >"$tmp"
  if cmp -s "$file" "$tmp"; then
    rm -f "$tmp"
    say "after.rules already drops LAN exemptions"
  else
    cat "$tmp" >"$file"
    rm -f "$tmp"
    act "removed DOCKER-USER RETURN for 192.168.0.0/16 and 10.0.0.0/8"
  fi
}

add_rule() {
  local cmd="$*"
  if ufw show added 2>/dev/null | grep -qxF "ufw $cmd"; then
    say "  ok    ufw $cmd"
  else
    ufw $cmd >/dev/null
    act "ufw $cmd"
  fi
}

apply_ufw() {
  ufw default deny incoming >/dev/null
  ufw default allow outgoing >/dev/null
  ufw default deny routed >/dev/null
  ufw logging low >/dev/null

  local proto
  for proto in tcp udp; do
    while ufw --force delete allow 53317/"$proto" >/dev/null 2>&1; do
      act "removed old 53317/$proto allow (was 0.0.0.0/0)"
    done
  done

  add_rule allow in on "$TAILSCALE_IF"
  add_rule route allow in on "$TAILSCALE_IF"
  add_rule allow in on "$LAN_IF" to any port 53317 proto udp
  add_rule allow in on "$LAN_IF" to any port 53317 proto tcp
  add_rule allow from 172.16.0.0/12 to 172.17.0.1 port 53 proto udp
  add_rule allow from 192.168.0.0/16 to 172.17.0.1 port 53 proto udp

  ufw --force enable >/dev/null
  act "ufw enabled, default deny incoming and routed"
}

apply_sysctl() {
  printf '# managed by dotfiles/scripts/harden-network.sh\nkernel.kptr_restrict = 2\n' >"$SYSCTL_FILE"
  sysctl --system >/dev/null
  act "kernel.kptr_restrict=2 in $SYSCTL_FILE"
}

disable_avahi() {
  if systemctl is-enabled --quiet avahi-daemon 2>/dev/null; then
    systemctl disable --now avahi-daemon.service >/dev/null 2>&1 || true
    systemctl disable --now avahi-daemon.socket >/dev/null 2>&1 || true
    act "avahi-daemon disabled (printing outbound unaffected)"
  else
    say "avahi already disabled"
  fi
}

restore_docker_hook() {
  if iptables -C FORWARD -j DOCKER-USER 2>/dev/null; then
    ok "FORWARD -> DOCKER-USER hook present"
  else
    iptables -I FORWARD 1 -j DOCKER-USER
    act "reinserted FORWARD -> DOCKER-USER (ufw reload drops docker's hook)"
  fi
}

rebind_redis() {
  if ! ss -tulpnH 2>/dev/null | grep -q ':6379'; then
    say "redis not running"
    return
  fi
  if ss -tulpnH 2>/dev/null | awk '$5 ~ /^127\.0\.0\.1:6379$/ {found=1} END {exit !found}'; then
    ok "redis already on loopback"
    return
  fi
  say ""
  say "redis is running on all interfaces from a terminal session:"
  ss -tulpnH 2>/dev/null | grep ':6379' | sed 's/^/    /'
  if [[ $REBIND_REDIS -eq 1 ]]; then
    redis-cli -h 127.0.0.1 shutdown nosave 2>/dev/null || pkill -f 'redis-server \*:6379' || true
    sleep 1
    act "redis stopped; restart it with: redis-server --bind 127.0.0.1 --protected-mode yes"
  else
    say "    re-run with --rebind-redis to stop it, or restart manually with:"
    say "    redis-cli shutdown nosave && redis-server --bind 127.0.0.1 --protected-mode yes"
  fi
}

verify() {
  say ""
  say "== Verify =="
  ufw status verbose | sed 's/^/  /'
  say ""
  say "  DOCKER-USER:"
  iptables -S DOCKER-USER 2>/dev/null | sed 's/^/    /' || bad "cannot read DOCKER-USER"
  say ""
  say "  Test from a Wi-Fi device without Tailscale (expect connection refused/timeout):"
  say "    curl -m 3 http://${LAN_CIDR%/*}:4000/healthz"
  say "  Test from a tailnet device (expect 200):"
  say "    curl -m 3 http://$(tailscale ip -4):4000/healthz"
  say ""
  say "  Container egress check:"
  if docker ps --format '{{.Names}}' 2>/dev/null | grep -qx leapmotor-mate-leapmotor-mate-1; then
    if docker exec leapmotor-mate-leapmotor-mate-1 python3 -c "import urllib.request; urllib.request.urlopen('https://example.com', timeout=8)" >/dev/null 2>&1; then
      ok "container can still reach the internet"
    else
      bad "container egress broken; run: sudo systemctl restart docker"
    fi
  fi
}

if [[ $APPLY -eq 1 ]]; then
  need_root
  preflight
  backup
  patch_docker_exemptions
  apply_ufw
  apply_sysctl
  disable_avahi
  ufw reload >/dev/null
  restore_docker_hook
  rebind_redis
  verify
  say ""
  say "Done."
else
  show_state
  say ""
  say "Apply with: sudo $0 --apply"
fi
