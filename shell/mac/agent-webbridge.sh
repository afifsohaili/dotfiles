# agent-webbridge defaults (macOS)
#
# agent-webbridge's discovery helpers were written against Google Chrome, but
# every on-disk path is Chromium-shaped, so pointing them at Edge is enough for
# `awb connect`/`status`/`check`. Omarchy (Linux) keeps Chrome, so only the mac
# tree sets this. `awb up` itself still launches/searches for Google Chrome by
# name — on mac use `awb-edge` (bin/awb-edge) instead: it starts the fleet with
# --no-open and wakes the Edge extension.
export AWB_CHROME_DIR="$HOME/Library/Application Support/Microsoft Edge"
