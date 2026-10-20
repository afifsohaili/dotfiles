// Omarchy-only MCP injection. The shared opencode.json stays Mac-clean: this
// plugin no-ops everywhere except Linux with the CUA wrapper installed.
import { existsSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { Plugin } from "@opencode/plugin";

const WRAPPER = join(homedir(), ".local/bin/cua-driver-mcp");

export default Plugin.define({
  id: "cua-driver-omarchy",
  async setup(ctx) {
    if (process.platform !== "linux") return;
    if (!existsSync(WRAPPER)) return;

    await ctx.mcp.transform((mcp) => {
      mcp.set("cua-driver", {
        type: "local",
        command: [WRAPPER],
        timeout: {
          startup: 30000,
          catalog: 30000,
          execution: 180000,
        },
      });
    });
  },
});
