# ntfy CLI defaults for the self-hosted server.
#
# The server runs from the user unit omarchy/systemd/ntfy.service, which passes
# these same paths as flags. The CLI (`ntfy user`, `ntfy access`, `ntfy token`)
# has no --config for them and refuses to run without an auth file, so export
# the paths here. Requires the server to have started once so user.db exists.
export NTFY_CONFIG_FILE="${NTFY_CONFIG_FILE:-$HOME/Projects/dotfiles/config/ntfy/server.yml}"
export NTFY_AUTH_FILE="${NTFY_AUTH_FILE:-$HOME/.local/share/ntfy/user.db}"
export NTFY_CACHE_FILE="${NTFY_CACHE_FILE:-$HOME/.local/share/ntfy/cache.db}"
