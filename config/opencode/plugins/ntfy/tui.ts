// ntfy + desktop notifications for OpenCode v2.
//
// V1 had this as a server plugin (`plugin/notify.ts`). V2 plugin implementations
// changed shape, and the server plugin API has no execution lifecycle stream,
// so this is a CLI (TUI) plugin instead: OpenCode discovers it from
// `<global-config>/plugins/<name>/tui.ts` and runs it in the terminal process.
// That also means `fetch` and `process.env` work here, unlike the sandboxed
// server plugin context.
//
// V2 emits `session.execution.succeeded` when a turn settles. `session.idle`
// is a legacy event no V2 server publishes — core maps execution outcomes to
// idle markers internally — so completion notifications listen on the
// execution events. Subagent sessions settle too and are notified like any
// other session. `session.execution.failed` notifies with the error message;
// `session.execution.interrupted` (user cancel, shutdown) stays silent.
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
//   OPENCODE_NTFY_URL     OpenCode server URL for the notification click-through.
//                         Set per machine to a URL reachable from the device that
//                         taps the notification (this machine's tailnet MagicDNS
//                         URL, e.g. http://<machine>.<tailnet>.ts.net:15001).
//                         Unset => no click action, so a phone never opens 127.0.0.1.
//
// Desktop notifications and sounds go through the native `attention` API, which
// only fires while the terminal is blurred. ntfy always fires.

import path from "node:path"
import { Plugin } from "@opencode/plugin/tui"

const NTFY_TOPIC = process.env.OPENCODE_NTFY_TOPIC
// Defaults to the public ntfy.sh. Point OPENCODE_NTFY_SERVER at a self-hosted
// server to keep notification bodies off a third party.
const NTFY_SERVER = (process.env.OPENCODE_NTFY_SERVER ?? "https://ntfy.sh").replace(/\/+$/, "")
const NTFY_TOKEN = process.env.OPENCODE_NTFY_TOKEN
// Trailing slashes are stripped to match the web app's own URL normalization
// (`(url).replace(/\/+$/, "")`), so the deep link encodes the exact string the
// client stores for the server.
const NTFY_SERVER_URL = process.env.OPENCODE_NTFY_URL?.replace(/\/+$/, "")
// V2 web sessions live at /server/<base64url(server URL)>/session/<id>. The v1
// /session/<id> path no longer exists and rendered the web app's 404 page.
const NTFY_SERVER_KEY = NTFY_SERVER_URL ? Buffer.from(NTFY_SERVER_URL).toString("base64url") : ""

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

    // Titles stay ASCII because HTTP header values reject non-ASCII; ntfy
    // renders the ⚠️/✔️ prefix from the warning/white_check_mark tags instead.
    const projectName = (sessionID: string | undefined, fallbackDirectory?: string): string => {
      const session = sessionID ? context.data.session.get(sessionID) : undefined
      const project = session?.projectID ? context.data.project.get(session.projectID) : undefined
      const canonical = project?.canonical || fallbackDirectory || context.location?.directory
      const name = project?.name || (canonical ? path.basename(canonical) : "") || "opencode"
      return name.toLowerCase()
    }

    const alert = async (input: {
      title: string
      message: string
      sound: "question" | "permission" | "done" | "error"
      priority: string
      tags?: string
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
        ...(input.tags ? { tags: input.tags } : {}),
        ...(NTFY_SERVER_URL && input.sessionID
          ? { click: `${NTFY_SERVER_URL}/server/${NTFY_SERVER_KEY}/session/${input.sessionID}` }
          : {}),
      })
    }

    // A new execution clears the previous turn's settled keys, so back-to-back
    // turns each notify even when they settle inside the dedupe window.
    const stopStarted = context.data.on("session.execution.started", (event) => {
      const sessionID = event.data?.sessionID
      if (!sessionID) return
      notified.delete(`done-${sessionID}`)
      notified.delete(`fail-${sessionID}`)
    })

    const stopSucceeded = context.data.on("session.execution.succeeded", (event) => {
      const sessionID = event.data?.sessionID
      if (!sessionID) return
      void once(`done-${sessionID}`, () =>
        alert({
          title: "Opencode",
          message: `Your task in ${projectName(sessionID, event.location?.directory)} has been completed`,
          sound: "done",
          priority: "default",
          tags: "white_check_mark",
          sessionID,
        }),
      )
    })

    const stopFailed = context.data.on("session.execution.failed", (event) => {
      const sessionID = event.data?.sessionID
      if (!sessionID) return
      const error = event.data?.error?.message
      void once(`fail-${sessionID}`, () =>
        alert({
          title: "Opencode",
          message: `Your task in ${projectName(sessionID, event.location?.directory)} has failed: ${error ?? "unknown error"}`,
          sound: "error",
          priority: "high",
          tags: "warning",
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
          title: `Permission needed in ${projectName(data?.sessionID, event.location?.directory)}`,
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
          title: `Question from ${projectName(form.sessionID, event.location?.directory)}`,
          message: "Waiting for your input",
          sound: "question",
          priority: "high",
          tags: "warning",
          sessionID: form.sessionID,
        }),
      )
    })

    return () => {
      stopStarted()
      stopSucceeded()
      stopFailed()
      stopPermission()
      stopForm()
      notified.clear()
    }
  },
})
