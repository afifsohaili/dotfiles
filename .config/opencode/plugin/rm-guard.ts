import type { Plugin } from "@opencode-ai/plugin";
import path from "node:path";
import os from "node:os";

const ALLOWED_ROOTS = [
  path.join(os.homedir(), "Tiga"),
  path.join(os.homedir(), "Projects"),
];

// Match rm invocations: rm, rm -rf, rm -i, rm --, etc.
const RM_RE = /^rm(\s+-\S+)*\s+/;

// Split a shell command into tokens, honoring single/double quotes.
function tokenize(cmd: string): string[] {
  const tokens: string[] = [];
  const re = /"([^"]*)"|'([^']*)'|(\S+)/g;
  let m: RegExpExecArray | null;
  while ((m = re.exec(cmd)) !== null) {
    tokens.push(m[1] ?? m[2] ?? m[3]);
  }
  return tokens;
}

function isInside(target: string, root: string): boolean {
  const resolved = path.resolve(target);
  return resolved === root || resolved.startsWith(root + path.sep);
}

export default (async () => {
  const currentDir = process.cwd();

  return {
    "tool.execute.before": async (input, output) => {
      if (input.tool !== "bash" || !input.args?.command) return;

      const cmd = input.args.command.trim();
      if (!RM_RE.test(cmd)) return;

      const workdir = input.args.workdir || currentDir;
      const tokens = tokenize(cmd);
      const targets = tokens.slice(1).filter((t) => !t.startsWith("-"));

      if (targets.length === 0) return;

      // Resolve every target against the bash workdir.
      const resolved = targets.map((t) =>
        path.isAbsolute(t) ? t : path.resolve(workdir, t),
      );

      // If any target is outside the allowed roots, leave the command
      // untouched so the config's "rm *": "ask" rule handles it.
      const allInside = resolved.every((t) =>
        ALLOWED_ROOTS.some((root) => isInside(t, root)),
      );
      if (!allInside) return;

      // Rewrite targets to absolute paths so the config allow rule
      // "rm * ~/Tiga/*" matches deterministically.
      // Replace each target token in place, preserving order and flags.
      let targetIdx = 0;
      const rewritten = tokens.map((t) => {
        if (targetIdx < targets.length && t === targets[targetIdx]) {
          return resolved[targetIdx++];
        }
        return t;
      });
      output.args.command = rewritten.join(" ");
    },
  };
}) satisfies Plugin;
