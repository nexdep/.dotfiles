-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Tell % to also match quotes
vim.opt.matchpairs:append({ ['"'] = '"', ["'"] = "'" })

-- In Insert mode, press <C-]> to do: Normal %, then go back to Insert
-- Combo to skip outside of brackets and quotes in insert mode
vim.keymap.set("i", "<C-]>", [[<C-c>%%a]], { silent = true })
vim.keymap.set("i", "<C-l>", [[<C-c>wa]], { silent = true })
vim.keymap.set("i", "<C-h>", [[<C-c>bi]], { silent = true })
