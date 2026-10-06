# AGENTS.md — LazyVim Neovim Config

## What this repo is

Personal Neovim configuration using [LazyVim](https://github.com/LazyVim/LazyVim).
This is **not a software project** — there are no tests, build steps, or CI. Changes are validated by opening Neovim and running `:checkhealth lazyvim`.

## Active vs dead code

- `lua/plugins/example.lua` returns `{}` on line 3 — it is **dead code**. Do not edit it.
- `lazyvim.json` shows `"extras": []` — no LazyVim extras are currently enabled.
- All actual customization lives in `lua/config/{options,keymaps,autocmds}.lua` and `lua/plugins/*.lua`.

## File structure

```
init.lua              → bootstrap entrypoint, requires config.lazy
lua/config/lazy.lua   → lazy.nvim bootstrap + plugin spec loading
lua/config/options.lua    → vim.opt overrides (loaded before plugins)
lua/config/keymaps.lua    → keymaps (loaded on VeryLazy event)
lua/config/autocmds.lua   → autocmds (loaded on VeryLazy event)
lua/plugins/*.lua     → custom plugin specs, auto-imported by lazy.nvim
```

## Adding plugins

Create a new file under `lua/plugins/` (e.g. `lua/plugins/my-plugin.lua`).
Each file should return a plugin spec table or list of tables.
Lazy.nvim auto-imports every `.lua` file in `lua/plugins/`.

## Formatting

Use **StyLua** with settings from `stylua.toml`:
- 2 spaces
- 120 column width
- `stylua .` from repo root

## Common pitfalls

- Do not commit `lazy-lock.json` changes unless you intentionally updated plugins.
- Plugin specs use `opts` for shallow merge and `opts = function(_, opts)` for extending defaults. Use `vim.list_extend` or `vim.tbl_deep_extend` where needed.
- To disable a LazyVim default plugin, add `enabled = false` to its spec.
- To override a default option that is a list (like `ensure_installed`), use a function with `vim.list_extend` — plain `opts` will overwrite the list.

## References

- LazyVim defaults: https://github.com/LazyVim/LazyVim/tree/main/lua/lazyvim/config
- lazy.nvim spec docs: https://lazy.folke.io/spec
