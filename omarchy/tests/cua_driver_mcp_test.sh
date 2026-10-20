#!/bin/bash
# shellcheck shell=bash
#
# Covers omarchy/bin/cua-driver-mcp: the wrapper must force native Wayland,
# bounded permissions, and the repo manifest before exec'ing the driver.
source "$(dirname "$0")/lib.sh"

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/bin/cua-driver-mcp"
FIXTURE_BIN="$(make_fixture_dir)"
FAKE_DRIVER="$FIXTURE_BIN/cua-driver"

cat > "$FAKE_DRIVER" <<'SHIM'
#!/bin/bash
printf 'ARG=%s\n' "$*"
printf 'WAYLAND_DISPLAY=%s\n' "${WAYLAND_DISPLAY:-}"
printf 'HYPRLAND_INSTANCE_SIGNATURE=%s\n' "${HYPRLAND_INSTANCE_SIGNATURE:-}"
printf 'CUA_DRIVER_RS_ENABLE_WAYLAND=%s\n' "${CUA_DRIVER_RS_ENABLE_WAYLAND:-}"
printf 'CUA_DRIVER_PERMISSION_MODE=%s\n' "${CUA_DRIVER_PERMISSION_MODE:-}"
printf 'CUA_DRIVER_CAPABILITY_MANIFEST_FILE=%s\n' "${CUA_DRIVER_CAPABILITY_MANIFEST_FILE:-}"
printf 'CUA_DRIVER_CAPABILITY_MANIFEST_APPROVED=%s\n' "${CUA_DRIVER_CAPABILITY_MANIFEST_APPROVED:-}"
SHIM
chmod +x "$FAKE_DRIVER"

run_wrapper() {
  env -i \
    PATH="/usr/bin:/bin" \
    HOME="$HOME" \
    WAYLAND_DISPLAY="wayland-test" \
    HYPRLAND_INSTANCE_SIGNATURE="signature-test" \
    XDG_RUNTIME_DIR="/run/user/1000" \
    DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/1000/bus" \
    XDG_SESSION_TYPE="wayland" \
    XDG_CURRENT_DESKTOP="Hyprland" \
    DISPLAY=":0" \
    CUA_DRIVER_BIN="$FAKE_DRIVER" \
    bash "$SCRIPT"
}

assert_eq "true" "$([[ -x $SCRIPT ]] && printf true || printf false)" "wrapper is executable"

out="$(run_wrapper)"
assert_contains "$out" "ARG=mcp" "starts the stdio MCP server"
assert_eq "wayland-test" "$(sed -n 's/^WAYLAND_DISPLAY=//p' <<<"$out")" "inherits Wayland display"
assert_eq "signature-test" "$(sed -n 's/^HYPRLAND_INSTANCE_SIGNATURE=//p' <<<"$out")" "inherits Hyprland signature"
assert_eq "1" "$(sed -n 's/^CUA_DRIVER_RS_ENABLE_WAYLAND=//p' <<<"$out")" "enables native Wayland"
assert_eq "bounded" "$(sed -n 's/^CUA_DRIVER_PERMISSION_MODE=//p' <<<"$out")" "selects bounded mode"
assert_contains "$out" "/omarchy/cua/capability-manifest.yaml" "points at the repo manifest"
assert_eq "1" "$(sed -n 's/^CUA_DRIVER_CAPABILITY_MANIFEST_APPROVED=//p' <<<"$out")" "approves the manifest"

out="$(env -i \
  PATH="/usr/bin:/bin" \
  HOME="$HOME" \
  WAYLAND_DISPLAY="wayland-test" \
  HYPRLAND_INSTANCE_SIGNATURE="signature-test" \
  CUA_DRIVER_BIN="$FIXTURE_BIN/missing" \
  bash "$SCRIPT" 2>&1)"
status=$?
assert_status 1 "$status" "missing driver fails"
assert_contains "$out" "driver not executable" "missing driver names the next action"
