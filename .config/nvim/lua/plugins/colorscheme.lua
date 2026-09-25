-- habamax is built into Neovim, so no plugin is needed.
-- We only tell LazyVim to use it, then recolor its editor chrome to match Ghostty.

local BG = "#010409"
local FG = "#e6edf3"
local SEL = "#264f78"

-- Ghostty's 16 ANSI colors, applied to the embedded :terminal.
local TERM = {
  "#484f58",
  "#ff7b72",
  "#3fb950",
  "#d29922",
  "#58a6ff",
  "#bc8cff",
  "#39c5cf",
  "#b1bac4",
  "#6e7681",
  "#ffa198",
  "#56d364",
  "#e3b341",
  "#79c0ff",
  "#d2a8ff",
  "#56d4dd",
  "#ffffff",
}

local function apply()
  if vim.g.colors_name ~= "habamax" then
    return
  end

  local set = vim.api.nvim_set_hl
  -- editor chrome -> terminal-dark
  set(0, "Normal", { bg = BG, fg = FG })
  set(0, "NormalNC", { bg = BG })
  set(0, "NormalFloat", { bg = BG })
  set(0, "FloatBorder", { bg = BG })
  set(0, "SignColumn", { bg = BG })
  set(0, "FoldColumn", { bg = BG })
  set(0, "LineNr", { bg = BG })
  set(0, "CursorLineNr", { bg = BG })
  set(0, "EndOfBuffer", { bg = BG, fg = BG })
  -- selection + cursor
  set(0, "Visual", { bg = SEL })
  set(0, "Cursor", { fg = BG, bg = FG })
  set(0, "TermCursor", { fg = BG, bg = FG })

  for i, c in ipairs(TERM) do
    vim.g["terminal_color_" .. (i - 1)] = c
  end
end

-- Registered at spec-collection time (before LazyVim applies the colorscheme),
-- so it catches the initial :colorscheme habamax and every later switch.
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "habamax",
  callback = apply,
})

return {
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "habamax" },
  },
}
