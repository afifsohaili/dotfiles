// ntfy + desktop notifications for OpenCode v2.
//
// V1 had this as a server plugin (`plugin/notify.ts`). V2 plugin implementations
// changed shape, and the server plugin API has no session.idle / permission.asked
// stream, so this is a CLI (TUI) plugin instead: OpenCode discovers it from
// `<global-config>/plugins/<name>/tui.ts` and runs it in the terminal process.
// That also means `fetch` and `process.env` work here, unlike the sandboxed
// server plugin context.
//
// Events differ from V2's docs in one important way: the question tool does not
// emit `question.asked`. It creates a form (`form.created`) whose
// `metadata.kind` is `"question"`. Permission prompts still emit
// `permission.asked`.
//
// Env (read from the TUI process environment):
//   OPENCODE_NTFY_TOPIC   ntfy topic to publish to. Unset => ntfy is skipped.
//   OPENCODE_NTFY_SERVER  ntfy base URL. Defaults to https://ntfy.sh; set to a
//                         self-hosted server (e.g. http://host:15002).
//   OPENCODE_NTFY_TOKEN   Optional bearer token for a server with auth enabled.
//   OPENCODE_NTFY_URL     OpenCode server URL, used for the notification click-through.
//
// Desktop notifications and sounds go through the native `attention` API, which
// only fires while the terminal is blurred. ntfy always fires.

import { Plugin } from "@opencode/plugin/tui"

const NTFY_TOPIC = process.env.OPENCODE_NTFY_TOPIC
// Defaults to the public ntfy.sh. Point OPENCODE_NTFY_SERVER at a self-hosted
// server to keep notification bodies off a third party.
const NTFY_SERVER = (process.env.OPENCODE_NTFY_SERVER ?? "https://ntfy.sh").replace(/\/+$/, "")
const NTFY_TOKEN = process.env.OPENCODE_NTFY_TOKEN
// Trailing slashes are stripped to match the web app's own URL normalization
// (`(url).replace(/\/+$/, "")`), so the deep link encodes the exact string the
// client stores for the server.
const NTFY_SERVER_URL = (process.env.OPENCODE_NTFY_URL ?? "http://127.0.0.1:15001").replace(/\/+$/, "")
// V2 web sessions live at /server/<base64url(server URL)>/session/<id>. The v1
// /session/<id> path no longer exists and rendered the web app's 404 page.
const NTFY_SERVER_KEY = Buffer.from(NTFY_SERVER_URL).toString("base64url")

// Dedupe window per request id. A hot reload can replay the same event.
const DEDUPE_MS = 3_000

async function sendNtfy(input: {
  title: string
  body: string
  priority?: string
  tags?: string
  click?: string
}): Promise<void> {
  if (!NTFY_TOPIC) return
  try {
    await fetch(`${NTFY_SERVER}/${NTFY_TOPIC}`, {
      method: "POST",
      body: input.body,
      headers: {
        ...(NTFY_TOKEN ? { Authorization: `Bearer ${NTFY_TOKEN}` } : {}),
        Title: input.title,
        ...(input.priority ? { Priority: input.priority } : {}),
        ...(input.tags ? { Tags: input.tags } : {}),
        ...(input.click ? { Click: input.click } : {}),
      },
    })
  } catch (error) {
    console.warn("[ntfy] publish failed:", error)
  }
}

export default Plugin.define({
  id: "ntfy",
  setup(context) {
    const notified = new Map<string, number>()

    const once = (key: string, fn: () => Promise<void>) => {
      const now = Date.now()
      for (const [k, t] of notified) if (now - t > DEDUPE_MS) notified.delete(k)
      if (notified.has(key)) return
      notified.set(key, now)
      return fn()
    }

    const alert = async (input: {
      title: string
      message: string
      sound: "question" | "permission" | "done"
      priority: string
      tags: string
      sessionID?: string
    }) => {
      await context.attention.notify({
        title: input.title,
        message: input.message,
        notification: { when: "blurred" },
        sound: { name: input.sound, when: "blurred" },
      })
      await sendNtfy({
        title: input.title,
        body: input.message,
        priority: input.priority,
        tags: input.tags,
        ...(input.sessionID
          ? { click: `${NTFY_SERVER_URL}/server/${NTFY_SERVER_KEY}/session/${input.sessionID}` }
          : {}),
      })
    }

    const stopIdle = context.data.on("session.idle", (event) => {
      const sessionID = event.data?.sessionID
      if (!sessionID) return
      void once(`idle-${sessionID}`, () =>
        alert({
          title: "Opencode",
          message: "Your task has been completed.",
          sound: "done",
          priority: "default",
          tags: "white_check_mark",
          sessionID,
        }),
      )
    })

    const stopPermission = context.data.on("permission.asked", (event) => {
      const data = event.data as
        | { id?: string; sessionID?: string; action?: string; resources?: readonly string[] }
        | undefined
      const key = `permission-${data?.id ?? data?.sessionID ?? "unknown"}`
      const detail = data?.action
        ? `${data.action}${data.resources?.length ? `: ${data.resources.join(", ")}` : ""}`.slice(0, 120)
        : "Waiting for your approval"
      void once(key, () =>
        alert({
          title: "Permission needed in OpenCode",
          message: detail,
          sound: "permission",
          priority: "high",
          tags: "warning",
          sessionID: data?.sessionID,
        }),
      )
    })

    const stopForm = context.data.on("form.created", (event) => {
      const form = event.data?.form as
        | { id?: string; sessionID?: string; title?: string; metadata?: { kind?: string; tool?: unknown } }
        | undefined
      // Only the question tool. MCP elicitations and other forms are not
      // interactive user prompts in the same sense.
      if (form?.metadata?.kind !== "question") return
      const key = `question-${form.id ?? form.sessionID ?? "unknown"}`
      void once(key, () =>
        alert({
          title: "Question from OpenCode",
          message: form.title ?? "Waiting for your input",
          sound: "question",
          priority: "high",
          tags: "warning",
          sessionID: form.sessionID,
        }),
      )
    })

    return () => {
      stopIdle()
      stopPermission()
      stopForm()
      notified.clear()
    }
  },
})
