-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local herdr_send = require("herdr-send")

vim.keymap.set("n", "<leader>ts", herdr_send.send, { desc = "Send to herdr pane" })
vim.keymap.set("n", "<leader>tS", herdr_send.reset_target, { desc = "Reset herdr target pane" })
