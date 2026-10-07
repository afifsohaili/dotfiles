// V2 adapter for opencode-tasks 0.5.3, which is still a V1-API plugin
// (jdormit/opencode-tasks#2 tracks the upstream port). The bundled package
// provides all 8 tools and the loop runtime unchanged; this file adapts only
// the plugin surface:
//   - V1 tool objects (zod args, string results) -> V2 tool transforms
//   - V1 `command.execute.before` is gone; commands/loop*.md drive the tools
//   - V1 `event` hook -> ctx.event.subscribe(), with the V2 event shape
//     adapted back to the `properties` shape the bundle expects
//   - V1 ctx.client.session.promptAsync -> ctx.session.prompt
//   - V1 ctx.client.app.log -> console.error (shows in the server log)
// Delete this file (and the package.json deps) when upstream ships a V2
// release; nothing else in the config depends on it.

import { tool as v1tool } from "@opencode-ai/plugin";
import { Plugin } from "@opencode/plugin";
import ScheduledTasksPlugin from "opencode-tasks";

type LegacyTool = {
  description: string;
  args: Record<string, unknown>;
  execute: (args: unknown, context: unknown) => Promise<unknown>;
};

type LegacyHooks = {
  tool?: Record<string, LegacyTool>;
  event?: (input: { event: unknown }) => Promise<void> | void;
};

type LegacyLogInput = {
  body: {
    service: string;
    level: "debug" | "info" | "warn" | "error";
    message: string;
    extra?: Record<string, unknown>;
  };
};

type LegacyPromptAsyncInput = {
  path: { id: string };
  body: { parts: Array<{ type: string; text?: string }> };
};

export default Plugin.define({
  id: "opencode-tasks",
  async setup(ctx) {
    const directory = ctx.location?.directory ?? process.cwd();

    const legacy = (await (ScheduledTasksPlugin as unknown as (input: unknown) => Promise<LegacyHooks>)({
      client: {
        app: {
          log: async (input: LegacyLogInput) => {
            const { service, level, message } = input.body;
            console.error(`[${service}] ${level}: ${message}`);
          },
        },
        session: {
          promptAsync: async (input: LegacyPromptAsyncInput) => {
            const text = input.body.parts
              .map((part) => part.text ?? "")
              .filter(Boolean)
              .join("\n\n");
            await ctx.session.prompt({ sessionID: input.path.id, text });
          },
        },
      },
      directory,
    }));

    await ctx.tool.transform((editor) => {
      for (const [name, legacyTool] of Object.entries(legacy.tool ?? {})) {
        editor.add({
          name,
          description: legacyTool.description,
          input: toJsonSchema(legacyTool.args),
          execute: async (args, toolCtx) => {
            const result = await legacyTool.execute(args, {
              sessionID: toolCtx.sessionID,
              messageID: toolCtx.messageID,
              agent: toolCtx.agent,
              directory,
              worktree: directory,
            });
            return toResult(result);
          },
        } as Parameters<typeof editor.add>[0]);
      }
    });

    if (typeof legacy.event === "function") {
      const controller = new AbortController();
      void (async () => {
        try {
          for await (const event of ctx.event.subscribe({ signal: controller.signal })) {
            const data = ((event as { data?: Record<string, unknown> }).data ?? {}) as {
              sessionID?: string;
            };
            try {
              await legacy.event?.({
                event: {
                  ...(event as object),
                  properties: { sessionID: data.sessionID, info: data },
                },
              });
            } catch {
              // The V1 handler is failure-isolated; never break the stream.
            }
          }
        } catch {
          // Aborted on unload.
        }
      })();
      return () => controller.abort();
    }
  },
});

function toJsonSchema(args: Record<string, unknown>) {
  const schema = v1tool.schema.toJSONSchema(
    v1tool.schema.object(args as Parameters<typeof v1tool.schema.object>[0]),
  ) as Record<string, unknown>;
  const { $schema: _drop, ...rest } = schema;
  return rest;
}

function toResult(result: unknown) {
  if (typeof result === "string") return { content: result };
  if (result && typeof result === "object") {
    const record = result as { output?: unknown; metadata?: Record<string, unknown> };
    return {
      content: typeof record.output === "string" ? record.output : JSON.stringify(result),
      metadata: record.metadata,
    };
  }
  return { content: String(result) };
}
