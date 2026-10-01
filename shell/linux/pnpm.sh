# pnpm global installs (Linux/Omarchy). pnpm v11 puts global package data in
# $PNPM_HOME/global/v11/<hash>/ and links bins into $PNPM_HOME/bin. Putting
# $PNPM_HOME/bin ahead of ~/.local/bin makes `pen`/`pencil` resolve to the
# @pen.dev/cli rather than the desktop AppImage at ~/.local/bin/pen. The desktop
# launcher uses an absolute Exec= path, so its GUI is unaffected.
export PNPM_HOME="${PNPM_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/pnpm}"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
