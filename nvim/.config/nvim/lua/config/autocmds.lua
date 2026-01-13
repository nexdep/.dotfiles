-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Terminal buffer-only keymaps:
--   Terminal-mode: <C-k> -> Terminal-Normal mode
--   Terminal-Normal mode: <C-j> -> back to Terminal-mode (insert)

vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "*",
  callback = function(ev)
    local opts = { buffer = ev.buf, silent = true, noremap = true }

    -- When you're typing in the terminal (Terminal-mode), go to normal mode
    vim.keymap.set(
      "t",
      "<C-k>",
      [[<C-\><C-n>]],
      vim.tbl_extend("force", opts, {
        desc = "Terminal: to normal mode",
      })
    )

    -- When you're in normal mode inside the terminal buffer, go back to typing
    vim.keymap.set(
      "n",
      "<C-j>",
      "i",
      vim.tbl_extend("force", opts, {
        desc = "Terminal: to terminal mode",
      })
    )
  end,
})
