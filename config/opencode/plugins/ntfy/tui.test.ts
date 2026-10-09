import { beforeEach, describe, expect, mock, test } from "bun:test"

mock.module("@opencode/plugin/tui", () => ({
  Plugin: { define: (plugin: unknown) => plugin },
}))

process.env.OPENCODE_NTFY_TOPIC = "test-topic"
process.env.OPENCODE_NTFY_SERVER = "http://ntfy.test"
process.env.OPENCODE_NTFY_URL = "http://127.0.0.1:15001"
delete process.env.OPENCODE_NTFY_TOKEN

const { default: plugin } = await import("./tui")

type Publish = {
  url: string
  body: string
  headers: Record<string, string>
}

type Session = { id: string; projectID?: string; parentID?: string }
type Project = { id: string; canonical: string; name?: string }

function createHarness(input: {
  sessions?: Record<string, Session>
  projects?: Record<string, Project>
  directory?: string
} = {}) {
  const handlers = new Map<string, Array<(event: unknown) => void>>()
  const attention: Array<Record<string, unknown>> = []

  const context = {
    location: input.directory ? { directory: input.directory } : undefined,
    attention: {
      notify: async (options: Record<string, unknown>) => {
        attention.push(options)
        return { ok: true, notification: true, sound: true }
      },
    },
    data: {
      on: (type: string, handler: (event: unknown) => void) => {
        const list = handlers.get(type) ?? []
        list.push(handler)
        handlers.set(type, list)
        return () => {
          handlers.set(
            type,
            (handlers.get(type) ?? []).filter((item) => item !== handler),
          )
        }
      },
      session: { get: (id: string) => input.sessions?.[id] },
      project: { get: (id: string) => input.projects?.[id] },
    },
  }

  return {
    context,
    attention,
    emit(type: string, event: unknown) {
      for (const handler of handlers.get(type) ?? []) handler(event)
    },
  }
}

const DOTFILES = { id: "proj_1", canonical: "/Users/afifsohaili/Projects/dotfiles" }

function execution(type: string, sessionID: string, error?: { message: string }) {
  return {
    id: `evt_${type}`,
    created: 0,
    type,
    location: { directory: "/Users/afifsohaili/Projects/dotfiles" },
    data: error ? { sessionID, error } : { sessionID },
  }
}

function flush() {
  return new Promise((resolve) => setTimeout(resolve, 10))
}

describe("ntfy plugin", () => {
  let publishes: Publish[]

  beforeEach(async () => {
    publishes = []
    globalThis.fetch = (async (url: string | URL, init?: RequestInit) => {
      publishes.push({
        url: String(url),
        body: String(init?.body ?? ""),
        headers: (init?.headers ?? {}) as Record<string, string>,
      })
      return new Response("", { status: 200 })
    }) as typeof fetch
  })

  test("session.execution.succeeded publishes a completion with project name", async () => {
    const harness = createHarness({
      sessions: { ses_1: { id: "ses_1", projectID: "proj_1" } },
      projects: { proj_1: DOTFILES },
    })
    await plugin.setup(harness.context)

    harness.emit("session.execution.succeeded", execution("session.execution.succeeded", "ses_1"))
    await flush()

    expect(publishes).toHaveLength(1)
    expect(publishes[0].url).toBe("http://ntfy.test/test-topic")
    expect(publishes[0].headers.Title).toBe("Opencode")
    expect(publishes[0].body).toBe("Your task in dotfiles has been completed")
    expect(publishes[0].headers.Tags).toBe("white_check_mark")
    expect(publishes[0].headers.Priority).toBe("default")
  })

  test("completion falls back to the event directory when project data is missing", async () => {
    const harness = createHarness()
    await plugin.setup(harness.context)

    harness.emit(
      "session.execution.succeeded",
      execution("session.execution.succeeded", "ses_1"),
    )
    await flush()

    expect(publishes).toHaveLength(1)
    expect(publishes[0].body).toBe("Your task in dotfiles has been completed")
  })

  test("completion notifies once per execution and again after a new start", async () => {
    const harness = createHarness({
      sessions: { ses_1: { id: "ses_1", projectID: "proj_1" } },
      projects: { proj_1: DOTFILES },
    })
    await plugin.setup(harness.context)

    harness.emit("session.execution.succeeded", execution("session.execution.succeeded", "ses_1"))
    harness.emit("session.execution.succeeded", execution("session.execution.succeeded", "ses_1"))
    await flush()
    expect(publishes).toHaveLength(1)

    harness.emit("session.execution.started", execution("session.execution.started", "ses_1"))
    harness.emit("session.execution.succeeded", execution("session.execution.succeeded", "ses_1"))
    await flush()
    expect(publishes).toHaveLength(2)
  })

  test("session.execution.failed publishes the error and stays silent on interrupt", async () => {
    const harness = createHarness({
      sessions: { ses_1: { id: "ses_1", projectID: "proj_1" } },
      projects: { proj_1: DOTFILES },
    })
    await plugin.setup(harness.context)

    harness.emit("session.execution.interrupted", execution("session.execution.interrupted", "ses_1"))
    await flush()
    expect(publishes).toHaveLength(0)

    harness.emit("session.execution.started", execution("session.execution.started", "ses_1"))
    harness.emit(
      "session.execution.failed",
      execution("session.execution.failed", "ses_1", { message: "provider exploded" }),
    )
    await flush()

    expect(publishes).toHaveLength(1)
    expect(publishes[0].headers.Title).toBe("Opencode")
    expect(publishes[0].body).toBe("Your task in dotfiles has failed: provider exploded")
    expect(publishes[0].headers.Tags).toBe("warning")
  })

  test("permission.asked publishes the action and resource details", async () => {
    const harness = createHarness({
      sessions: { ses_1: { id: "ses_1", projectID: "proj_1" } },
      projects: { proj_1: DOTFILES },
    })
    await plugin.setup(harness.context)

    harness.emit("permission.asked", {
      id: "evt_perm",
      created: 0,
      type: "permission.asked",
      location: { directory: "/Users/afifsohaili/Projects/dotfiles" },
      data: {
        id: "per_1",
        sessionID: "ses_1",
        action: "shell",
        resources: ["git push origin main"],
      },
    })
    await flush()

    expect(publishes).toHaveLength(1)
    expect(publishes[0].headers.Title).toBe("Permission needed in dotfiles")
    expect(publishes[0].body).toBe("shell: git push origin main")
    expect(publishes[0].headers.Tags).toBe("warning")
    expect(publishes[0].headers.Priority).toBe("high")
  })

  test("form.created only notifies for the question kind", async () => {
    const harness = createHarness({
      sessions: { ses_1: { id: "ses_1", projectID: "proj_1" } },
      projects: { proj_1: DOTFILES },
    })
    await plugin.setup(harness.context)

    harness.emit("form.created", {
      id: "evt_form_1",
      created: 0,
      type: "form.created",
      location: { directory: "/Users/afifsohaili/Projects/dotfiles" },
      data: {
        form: { id: "frm_1", sessionID: "ses_1", title: "Questions", metadata: { kind: "elicitation" }, fields: [] },
      },
    })
    await flush()
    expect(publishes).toHaveLength(0)

    harness.emit("form.created", {
      id: "evt_form_2",
      created: 0,
      type: "form.created",
      location: { directory: "/Users/afifsohaili/Projects/dotfiles" },
      data: {
        form: { id: "frm_2", sessionID: "ses_1", title: "Questions", metadata: { kind: "question" }, fields: [] },
      },
    })
    await flush()

    expect(publishes).toHaveLength(1)
    expect(publishes[0].headers.Title).toBe("Question from dotfiles")
    expect(publishes[0].body).toBe("Waiting for your input")
    expect(publishes[0].headers.Tags).toBe("warning")
  })

  test("custom project names are lowercased", async () => {
    const harness = createHarness({
      sessions: { ses_1: { id: "ses_1", projectID: "proj_2" } },
      projects: { proj_2: { id: "proj_2", canonical: "/Users/afifsohaili/Projects/Peekaboo", name: "Peek A Boo" } },
    })
    await plugin.setup(harness.context)

    harness.emit("session.execution.succeeded", execution("session.execution.succeeded", "ses_1"))
    await flush()

    expect(publishes[0].body).toBe("Your task in peek a boo has been completed")
  })
})
