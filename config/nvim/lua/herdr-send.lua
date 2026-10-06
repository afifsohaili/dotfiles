local M = {}

local state = {
  target_pane = nil,
  buf = nil,
  win = nil,
}

local function run_herdr(args)
  local result = vim.fn.system(args)
  if vim.v.shell_error ~= 0 then
    return nil
  end
  local ok, data = pcall(vim.json.decode, vim.trim(result))
  if not ok or not data or not data.result then
    return nil
  end
  return data.result
end

local function get_current_pane_id()
  if vim.env.HERDR_PANE_ID then
    return vim.env.HERDR_PANE_ID
  end
  local result = run_herdr({ "herdr", "pane", "current" })
  if result and result.pane and result.pane.pane_id then
    return result.pane.pane_id
  end
  return nil
end

local function get_current_tab_id()
  if vim.env.HERDR_TAB_ID then
    return vim.env.HERDR_TAB_ID
  end
  local result = run_herdr({ "herdr", "pane", "current" })
  if result and result.pane and result.pane.tab_id then
    return result.pane.tab_id
  end
  return nil
end

-- Returns panes in the same tab as the current pane (excluding nvim's own pane)
local function list_panes()
  local current_pane = get_current_pane_id()
  local tab_id = get_current_tab_id()
  local result = run_herdr({ "herdr", "pane", "list" })
  if not result or not result.panes then
    return {}
  end

  local panes = {}
  for _, pane in ipairs(result.panes) do
    if pane.pane_id ~= current_pane and pane.tab_id == tab_id then
      local label = pane.terminal_title_stripped or pane.terminal_title or ""
      if label == "" then
        label = pane.cwd or ""
      end
      if pane.agent then
        label = label .. " [agent: " .. pane.agent .. "]"
      end
      table.insert(panes, { id = pane.pane_id, label = label })
    end
  end
  return panes
end

local function is_pane_alive(pane_id)
  local result = run_herdr({ "herdr", "pane", "list" })
  if not result or not result.panes then
    return false
  end
  for _, pane in ipairs(result.panes) do
    if pane.pane_id == pane_id then
      return true
    end
  end
  return false
end

local function get_relative_path()
  local buf = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(buf)
  if path == "" then
    return ""
  end
  return vim.fn.fnamemodify(path, ":~:.") or path
end

local function get_prefill()
  local path = get_relative_path()
  if path == "" then
    return ""
  end
  local line = vim.api.nvim_win_get_cursor(0)[1]
  return path .. ":" .. line .. " "
end

function M.pick_target(on_done)
  if vim.env.HERDR_ENV ~= "1" then
    vim.notify("Not in a herdr session", vim.log.levels.ERROR)
    return
  end

  local panes = list_panes()

  if #panes == 0 then
    vim.notify("No other panes in this tab", vim.log.levels.WARN)
    return
  end

  local select_target = function(choice)
    state.target_pane = choice.id
    vim.notify("Target pane set to " .. choice.id, vim.log.levels.INFO)
    if on_done then
      on_done()
    end
  end

  if #panes == 1 then
    select_target(panes[1])
    return
  end

  vim.ui.select(panes, {
    prompt = "Select target pane: ",
    format_item = function(item)
      return item.id .. " (" .. item.label .. ")"
    end,
  }, function(choice)
    if not choice then
      return
    end
    select_target(choice)
  end)
end

local function close_float()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    vim.api.nvim_buf_delete(state.buf, { force = true })
  end
  state.win = nil
  state.buf = nil
end

local function send_text(text)
  if not state.target_pane or not is_pane_alive(state.target_pane) then
    state.target_pane = nil
    vim.notify("Target pane closed, please pick a new one", vim.log.levels.WARN)
    return
  end

  vim.fn.system({ "herdr", "pane", "send-text", state.target_pane, text })
  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to send text to herdr pane", vim.log.levels.ERROR)
  end
end

local function do_send()
  local lines = vim.api.nvim_buf_get_lines(state.buf, 0, -1, false)
  local text = table.concat(lines, "\n")
  close_float()
  send_text(text)
end

local function open_float()
  local prefill = get_prefill()

  local width = math.min(60, vim.o.columns - 4)
  local height = math.min(10, vim.o.lines - 4)
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)

  state.buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(state.buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(state.buf, "filetype", "herdrsend")

  -- Disable autocomplete in this buffer
  vim.api.nvim_buf_set_option(state.buf, "completeopt", "")
  vim.api.nvim_buf_set_option(state.buf, "omnifunc", "")
  vim.api.nvim_buf_set_option(state.buf, "complete", ".")

  -- Try to disable nvim-cmp in this buffer
  local ok_cmp, cmp = pcall(require, "cmp")
  if ok_cmp then
    cmp.setup.buffer({ enabled = false })
  end

  -- Try to disable blink.cmp in this buffer
  local ok_blink, blink = pcall(require, "blink.cmp")
  if ok_blink and blink.setup_buffer then
    blink.setup_buffer({ enabled = false })
  end

  local win_opts = {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
    title = " Send to herdr ",
    title_pos = "center",
  }

  state.win = vim.api.nvim_open_win(state.buf, true, win_opts)

  if prefill ~= "" then
    vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, { prefill })
  end

  local map_opts = { noremap = true, silent = true, buffer = state.buf }
  vim.keymap.set("n", "<C-s>", do_send, map_opts)
  vim.keymap.set("i", "<C-s>", do_send, map_opts)
  vim.keymap.set("n", "<C-CR>", do_send, map_opts)
  vim.keymap.set("i", "<C-CR>", do_send, map_opts)
  vim.keymap.set("n", "<Esc>", close_float, map_opts)
  vim.keymap.set("i", "<Esc>", close_float, map_opts)

  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = state.buf,
    once = true,
    callback = close_float,
  })

  vim.api.nvim_command("startinsert!")
end

function M.send()
  if vim.env.HERDR_ENV ~= "1" then
    vim.notify("Not in a herdr session", vim.log.levels.ERROR)
    return
  end

  if not state.target_pane or not is_pane_alive(state.target_pane) then
    state.target_pane = nil
    M.pick_target(function()
      M.send()
    end)
    return
  end

  open_float()
end

function M.reset_target()
  state.target_pane = nil
  vim.notify("Target pane reset", vim.log.levels.INFO)
end

function M.setup()
  -- zero-config
end

return M
