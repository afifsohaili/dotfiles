---
description: Say hi — daily at 9 am
schedule: "0 9 * * *"
cwd: ~/Projects/dotfiles
timeout: 5m
session_name: daily-hello
permission:
  bash:
    "*": allow
  edit: deny
---

Say hi to the user via ntfy. Post a short friendly one-line greeting:

```
set -a; . "$HOME/Projects/dotfiles/shell/shared/opencode.env"; set +a
curl -s -d "Hi! Have a great day." -H "Title: Good morning" -H "Tags: wave" "https://ntfy.sh/$OPENCODE_NTFY_TOPIC"
```

Do not print the topic value. Then finish.
