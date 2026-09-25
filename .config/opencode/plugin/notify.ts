import { Plugin } from "@opencode-ai/plugin";

const SERVER_URL = process.env.OPENCODE_NTFY_URL ?? "http://afifs-macbook-pro.taila5c1b8.ts.net:15001";
const NTFY_TOPIC = process.env.OPENCODE_NTFY_TOPIC;

// Dedupe keys (e.g. permission id) -> last notification timestamp
const notifiedAt = new Map<string, number>();

const base64UrlPart = (url: string) => btoa(url).replace(/=+$/, "");

const sessionUrl = (sessionID: string) =>
  `${SERVER_URL}/server/${base64UrlPart(SERVER_URL)}/session/${sessionID}`;

const sendNtfy = async ({
  title,
  body,
  priority,
  tags,
  clickUrl,
}: {
  title: string;
  body: string;
  priority?: string;
  tags?: string;
  clickUrl?: string;
}) => {
  if (!NTFY_TOPIC) {
    console.warn("[notify] OPENCODE_NTFY_TOPIC is not set; skipping ntfy notification");
    return;
  }

  await fetch(`https://ntfy.sh/${NTFY_TOPIC}`, {
    method: "POST",
    body,
    headers: {
      Title: title,
      ...(priority ? { Priority: priority } : {}),
      ...(tags ? { Tags: tags } : {}),
      ...(clickUrl ? { Click: clickUrl } : {}),
    },
  });
};

const notifyOnce = (key: string, ttlMs: number, fn: () => Promise<void>) => {
  const now = Date.now();
  for (const [k, t] of notifiedAt) if (now - t > ttlMs) notifiedAt.delete(k);
  const last = notifiedAt.get(key);
  if (last && now - last < ttlMs) return;
  notifiedAt.set(key, now);
  return fn();
};

export default (async ({ $, directory }) => {
  const projectName = directory.split("/").pop() || "unknown project";

  const notifyDesktop = async ({
    title,
    subtitle,
    message = title,
  }: {
    title: string;
    subtitle: string;
    message?: string;
  }) => {
    // Pass content as argv so Bun shell-escapes each argument; AppleScript
    // never sees quotes/backslashes in the content, so it can't break the
    // string literal (fixes syntax error -2740 on details containing ").
    await $`osascript -e 'on run argv' -e 'display notification (item 1 of argv) with title (item 2 of argv) subtitle (item 3 of argv) sound name "Purr"' -e 'end run' -- ${message} ${title} ${subtitle}`;
  };

  return {
    event: async ({ event }) => {
      const type = (event as { type: string }).type;

      if (event.type === "session.idle") {
        const title = "Opencode";
        const subtitle = `Your task in ${projectName} has been completed.`;

        // Desktop notification
        await notifyDesktop({ title, subtitle });

        // Ntfy notification
        await sendNtfy({
          title,
          body: subtitle,
          clickUrl: sessionUrl(event.properties.sessionID),
        });
      }

      // question.asked / permission.asked are bridged through the EventV2
      // stream but are not yet in the SDK's typed Event union, so narrow via
      // casts. permission.updated is the older name for permission.asked.

      if (type === "question.asked") {
        const props = (event as unknown as { properties: { sessionID: string } }).properties;
        const title = `Question from ${projectName}`;
        const subtitle = "Waiting for your input";

        // Desktop notification
        await notifyDesktop({ title, subtitle, message: "Question!" });

        // High-priority ntfy notification
        await sendNtfy({
          title,
          body: subtitle,
          priority: "high",
          tags: "warning",
          clickUrl: sessionUrl(props.sessionID),
        });
      }

      if (type === "permission.asked" || type === "permission.updated") {
        const props = (event as unknown as {
          properties: {
            id?: string;
            sessionID: string;
            permission?: string;
            patterns?: string[];
            title?: string;
            pattern?: string | string[];
          };
        }).properties;

        const tool = props.permission ?? props.title ?? "tool";
        const patternList =
          props.patterns ?? (typeof props.pattern === "string" ? [props.pattern] : props.pattern) ?? [];
        const detail = patternList.length > 0 ? `${tool}: ${patternList.join(", ")}` : `Permission requested (${tool})`;
        const title = `Permission needed in ${projectName}`;
        const subtitle = detail.slice(0, 80);

        const notify = async () => {
          // Desktop notification
          await notifyDesktop({ title, subtitle, message: "Permission needed!" });

          // High-priority ntfy notification
          await sendNtfy({
            title,
            body: detail,
            priority: "high",
            tags: "warning",
            clickUrl: sessionUrl(props.sessionID),
          });
        };

        // Guard against both event names firing for the same permission request
        await (props.id ? notifyOnce(`perm-${props.id}`, 3_000, notify) : notify());
      }
    },
  };
}) satisfies Plugin;
