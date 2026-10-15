# hop: copy files between this machine and the other one over Tailscale.
#
#   hop push <src> [dst]   send to the other machine
#   hop pull <src> [dst]   fetch from the other machine
#
# Peer: Darwin <-> afifsohailig4, Linux <-> afifs-macbook-pro (HOP_HOST
# overrides). Both directions cross the tailnet only; magicDNS names, no LAN
# exposure, no serve mappings.
#
# Paths:
#   ~/x or $HOME/x  ->  x under the home dir of whichever machine holds the
#                       file (g4 /home/afifsohaili, macOS /Users/afifsohaili)
#   /abs            ->  the same absolute path on both sides
#   no dst          ->  mirror: the copy lands at the path it came from
#   relative dst    ->  rsync's rule: cwd locally, home dir on the peer
#
# Auth: Mac -> g4 rides Tailscale SSH (tailnet identity, no keys). g4 -> Mac
# rides macOS's OpenSSH with ~/.ssh/id_ed25519; install it once with
# `ssh-copy-id afifs-macbook-pro`.

_hop_err() { printf 'hop: %s\n' "$1" >&2; }

_hop_peer() {
  case "$(uname -s)" in
    Darwin) printf '%s' "${HOP_HOST:-afifsohailig4}" ;;
    Linux)  printf '%s' "${HOP_HOST:-afifs-macbook-pro}" ;;
    *) return 1 ;;
  esac
}

# How the peer should address the path: home-relative inside $HOME, else as-is.
_hop_remote_path() {
  case "$1" in
    "$HOME")   printf '.' ;;
    "$HOME"/*) printf '%s' "${1#"$HOME"/}" ;;
    *)         printf '%s' "$1" ;;
  esac
}

# Where a copy lands when no dst is given: the same path on this machine.
_hop_mirror_path() {
  case "$1" in
    /*) printf '%s' "$1" ;;
    *)  printf '%s/%s' "$HOME" "$1" ;;
  esac
}

hop() {
  command -v rsync >/dev/null 2>&1 || { _hop_err "rsync is not installed"; return 1; }

  local cmd=${1:-}
  case "$cmd" in
    push|pull) shift ;;
    help|-h|--help)
      cat <<'EOF' >&2
usage: hop push <src> [dst]   send to the other machine
       hop pull <src> [dst]   fetch from the other machine

~/x means "x under the home dir" of whichever machine holds the file.
Without [dst] the copy lands at the same path. HOP_HOST overrides the peer.
EOF
      return 0 ;;
    *) _hop_err "usage: hop push|pull <src> [dst]"; return 2 ;;
  esac

  local peer src=${1:-} dst=${2:-} rpath kind
  peer=$(_hop_peer) || { _hop_err "unsupported OS"; return 1; }
  if [ -z "$src" ]; then _hop_err "missing source path"; return 2; fi

  if [ "$cmd" = pull ]; then
    rpath=$(_hop_remote_path "$src")
    [ -n "$dst" ] || dst=$(_hop_mirror_path "$src")
    kind=$(ssh -o BatchMode=yes -o ConnectTimeout=10 "$peer" "test -d \"$rpath\" && echo d || echo f" 2>/dev/null) || true
    mkdir -p "$(dirname "$dst")" 2>/dev/null || true
    if [ "$kind" = d ]; then
      rsync -az "$peer:$rpath/" "$dst/" || { _hop_err "rsync failed"; return 1; }
    else
      rsync -az "$peer:$rpath" "$dst" || { _hop_err "rsync failed"; return 1; }
    fi
    printf 'hop: pulled %s:%s -> %s\n' "$peer" "$rpath" "$dst"
  else
    rpath=$(_hop_remote_path "${dst:-$src}")
    ssh -o BatchMode=yes -o ConnectTimeout=10 "$peer" "mkdir -p \"$(dirname "$rpath")\"" 2>/dev/null || true
    if [ -d "$src" ]; then
      rsync -az "$src/" "$peer:$rpath/" || { _hop_err "rsync failed"; return 1; }
    else
      rsync -az "$src" "$peer:$rpath" || { _hop_err "rsync failed"; return 1; }
    fi
    printf 'hop: pushed %s -> %s:%s\n' "$src" "$peer" "$rpath"
  fi
}
