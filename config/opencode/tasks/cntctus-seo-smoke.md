---
description: One-shot smoke test for the cntctus-seo-daily task (report only, no file changes)
schedule: "*/2 * * * *"
cwd: ~/Projects/cntctus
timeout: 12m
model: ollama-cloud/glm-5.3
agent: ollama-glm53f
session_name: cntctus-seo-smoke
permission:
  bash:
    "*": allow
  edit: deny
  webfetch: allow
  websearch: allow
  external_directory:
    "~/Projects/cntctus/*": allow
    "~/Projects/agent-webbridge/*": allow
    "~/.agent-webbridge/*": allow
    "~/.local/share/opencode-tasks/*": allow
    "~/.config/opencode/*": allow
    "~/Projects/dotfiles/*": allow
    "/tmp/*": allow
enabled: false
---

SMOKE TEST for the cntctus-seo-daily task. Report only — do not modify, commit, or push anything.

Do exactly this:

1. `node ~/Projects/agent-webbridge/bin/awb.mjs status`. If the daemon is not up for the Default profile, run `node ~/Projects/agent-webbridge/bin/awb.mjs up "Default"`.
2. Using the router at `http://127.0.0.1:10086/command` with session `cntctus-seo-smoke`, navigate to `https://search.google.com/search-console?resource_id=sc-domain:cntct.us` and snapshot the page.
3. Report the clicks / indexed / not-indexed numbers you can see, and whether the browser chain worked, via ntfy:

```
set -a; . ~/.config/opencode/opencode.env; set +a
curl -s -d "<one-line summary>" -H "Title: cntct.us SEO smoke" -H "Tags: test_tube" "https://ntfy.sh/$OPENCODE_NTFY_TOPIC"
```

If anything in the chain fails, report the exact error string instead. Leave the tab open.
