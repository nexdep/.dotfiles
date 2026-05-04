-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- in insert mode, Ctrl+Right to jump forward by one word
vim.keymap.set("i", "<C-l>", "<C-o>e", {
  noremap = true,
  silent = true,
  desc = "Insert: next word",
})

-- in insert mode, Ctrl+Left to jump backward by one word
vim.keymap.set("i", "<C-h>", "<C-o>b", {
  noremap = true,
  silent = true,
  desc = "Insert: previous word",
})

-- CodeCompanion keymaps (LazyVim)
vim.keymap.set(
  { "n", "v" },
  "<leader>a",
  "<cmd>CodeCompanionActions<cr>",
  { noremap = true, silent = true, desc = "AI Actions" }
)
vim.keymap.set(
  { "n", "v" },
  "<leader>aa",
  "<cmd>CodeCompanionChat Toggle<cr>",
  { noremap = true, silent = true, desc = "AI Chat Toggle" }
)
vim.keymap.set(
  "v",
  "ga",
  "<cmd>CodeCompanionChat Add<cr>",
  { noremap = true, silent = true, desc = "AI Add Selection" }
)

vim.cmd([[cab cc CodeCompanion]])

-- yank all files in the same folder as the current buffer (with headers) to system clipboard
vim.keymap.set("n", "<leader>fy", function()
  -- directory of the current file
  local dir = vim.fn.expand("%:p:h")
  -- if the buffer has no file (e.g. [No Name]), fall back to cwd
  if dir == "" then
    dir = vim.fn.getcwd()
  end

  local files = vim.fn.readdir(dir)
  local out = {}

  for _, name in ipairs(files) do
    local path = dir .. "/" .. name
    if vim.fn.isdirectory(path) == 0 then
      table.insert(out, "=== " .. name .. " ===")
      for _, line in ipairs(vim.fn.readfile(path)) do
        table.insert(out, line)
      end
      table.insert(out, "")
    end
  end

  vim.fn.setreg("+", table.concat(out, "\n"))
  print("📋 Yanked " .. #out .. " lines from " .. #files .. " files in: " .. dir)
end, { desc = "fy: Yank all files in buffer’s folder to + register" })

-- Append the first diagnostic on the current line to the system clipboard
vim.keymap.set("n", "<leader>xa", function()
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local diags = vim.diagnostic.get(0, { lnum = row })
  if #diags > 0 then
    local msg = (diags[1].message or ""):gsub("%s+", " ")
    local current_clipboard = vim.fn.getreg("+")
    local new_clipboard = current_clipboard ~= "" and (current_clipboard .. "\n" .. msg) or msg
    vim.fn.setreg("+", new_clipboard) -- append to clipboard (+)
    vim.notify("Appended diagnostic: " .. msg, vim.log.levels.INFO)
  else
    vim.notify("No diagnostics on this line", vim.log.levels.WARN)
  end
end, { desc = "Append diagnostic on line to clipboard" })

-- Send current line + diagnostics on that line to system clipboard
vim.keymap.set("n", "<leader>xy", function()
  local bufnr = 0
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1

  -- current line text
  local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
  line = line:gsub("%s+$", "")

  -- diagnostics on the line
  local diags = vim.diagnostic.get(bufnr, { lnum = row })
  if #diags == 0 then
    vim.notify("No diagnostics on this line", vim.log.levels.WARN)
    return
  end

  -- collect all diagnostics
  local parts = {}
  for _, d in ipairs(diags) do
    local msg = (d.message or ""):gsub("%s+", " ")
    if msg ~= "" then
      table.insert(parts, msg)
    end
  end

  local combined = line .. "\n" .. table.concat(parts, "\n")

  -- overwrite clipboard (+)
  vim.fn.setreg("+", combined)

  vim.notify("Copied line + diagnostics to clipboard", vim.log.levels.INFO)
end, { desc = "Copy current line + diagnostics to clipboard" })

-- local last = { cmd = nil, opts = nil }
--
-- local function toggle_and_remember(cmd, opts)
--   last.cmd = cmd
--   last.opts = opts
--   Snacks.terminal.toggle(cmd, opts)
-- end
--
-- -- horizontal (default id: cmd=nil)
-- vim.keymap.set("n", "<leader>tt", function()
--   toggle_and_remember(nil, nil)
-- end, { desc = "Toggle terminal" })
--
-- -- vertical (different id because cmd is vim.o.shell)
-- vim.keymap.set("n", "<leader>tv", function()
--   toggle_and_remember(vim.o.shell, {
--     win = {
--       style = "terminal",
--       position = "right",
--       width = 0.2,
--     },
--   })
-- end, { desc = "Vertical terminal (right)" })
--
-- -- Ctrl-/ (usually <C-_>) toggles the most recently used terminal
-- vim.keymap.set({ "n", "t" }, "<C-_>", function()
--   Snacks.terminal.toggle(last.cmd, last.opts)
-- end, { desc = "Toggle last terminal" })

-- Disable LazyVim defaults first
pcall(vim.keymap.del, { "n", "t" }, "<C-/>")
pcall(vim.keymap.del, { "n", "t" }, "<C-_>")

local terminals = {
  horizontal = {
    kind = "snacks",
    cmd = nil,
    opts = {
      env = { SNACKS_TERM_ID = "horizontal" },
    },
  },

  vertical = {
    kind = "snacks",
    cmd = nil,
    opts = {
      env = { SNACKS_TERM_ID = "vertical" },
      win = {
        style = "terminal",
        position = "right",
        width = 0.2,
      },
    },
  },

  tab = {
    kind = "tab",
  },
  buffer = {
    kind = "buffer",
  },
}

local last = terminals.horizontal

local tab_term = {
  buf = nil,
}
local buf_term = {
  buf = nil,
}

local function buf_valid(buf)
  return buf and vim.api.nvim_buf_is_valid(buf)
end

local function find_buf_window(buf)
  if not buf_valid(buf) then
    return nil, nil
  end

  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
      if vim.api.nvim_win_get_buf(win) == buf then
        return tab, win
      end
    end
  end

  return nil, nil
end

local function open_explorer_if_available()
  if not (Snacks and Snacks.explorer) then
    return
  end

  local current_win = vim.api.nvim_get_current_win()

  Snacks.explorer.open()

  if vim.api.nvim_win_is_valid(current_win) then
    vim.api.nvim_set_current_win(current_win)
  end
end

local function open_tab_terminal()
  last = terminals.tab

  local tab, win = find_buf_window(tab_term.buf)

  -- If the tab terminal is currently focused, hide/close it.
  if tab and win and vim.api.nvim_get_current_tabpage() == tab then
    if #vim.api.nvim_list_tabpages() > 1 then
      vim.cmd.tabclose()
    else
      vim.cmd.hide()
    end
    return
  end

  -- Terminal buffer is already visible somewhere: jump to it.
  if tab and win then
    vim.api.nvim_set_current_tabpage(tab)
    vim.api.nvim_set_current_win(win)
    open_explorer_if_available()
    vim.cmd.startinsert()
    return
  end

  -- Terminal buffer exists but is hidden: open it directly in a new tab.
  if buf_valid(tab_term.buf) then
    vim.cmd("tab sbuffer " .. tab_term.buf)
    open_explorer_if_available()
    vim.cmd.startinsert()
    return
  end

  -- Create a new terminal in a real Neovim tab.
  vim.cmd.tabnew()
  tab_term.buf = vim.api.nvim_get_current_buf()

  vim.bo[tab_term.buf].bufhidden = "hide"

  vim.fn.jobstart(vim.o.shell, { term = true })

  vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>]], {
    buffer = tab_term.buf,
    desc = "Exit terminal mode",
  })

  open_explorer_if_available()
  vim.cmd.startinsert()
end

local function open_buffer_terminal()
  last = terminals.buffer

  local tab, win = find_buf_window(buf_term.buf)

  -- If the buffer terminal is currently focused, hide/switch away from it.
  if tab and win and vim.api.nvim_get_current_tabpage() == tab and vim.api.nvim_get_current_win() == win then
    vim.cmd.stopinsert()

    -- If there is an alternate buffer, go back to it.
    local alt = vim.fn.bufnr("#")
    if alt > 0 and alt ~= buf_term.buf and vim.api.nvim_buf_is_valid(alt) then
      vim.api.nvim_win_set_buf(0, alt)
    else
      vim.cmd.enew()
    end

    return
  end

  -- If terminal buffer is already visible elsewhere, jump to it.
  if tab and win then
    vim.api.nvim_set_current_tabpage(tab)
    vim.api.nvim_set_current_win(win)
    vim.cmd.startinsert()
    return
  end

  -- If terminal buffer exists but is hidden, open it in current window.
  if buf_valid(buf_term.buf) then
    vim.api.nvim_win_set_buf(0, buf_term.buf)
    vim.cmd.startinsert()
    return
  end

  -- Create a normal listed terminal buffer in the current window.
  vim.cmd.enew()
  buf_term.buf = vim.api.nvim_get_current_buf()

  vim.bo[buf_term.buf].bufhidden = "hide"
  vim.bo[buf_term.buf].buflisted = true

  vim.fn.jobstart(vim.o.shell, { term = true })

  vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>]], {
    buffer = buf_term.buf,
    desc = "Exit terminal mode",
  })

  vim.cmd.startinsert()
end

local function toggle_term(term)
  last = term

  if term.kind == "tab" then
    open_tab_terminal()
  elseif term.kind == "buffer" then
    open_buffer_terminal()
  else
    Snacks.terminal.toggle(term.cmd, term.opts)
  end
end

-- Horizontal terminal
vim.keymap.set("n", "<leader>tt", function()
  toggle_term(terminals.horizontal)
end, { desc = "Toggle horizontal terminal" })

-- Vertical terminal
vim.keymap.set("n", "<leader>tv", function()
  toggle_term(terminals.vertical)
end, { desc = "Toggle vertical terminal" })

-- Real Neovim tab terminal
vim.keymap.set("n", "<leader>tb", function()
  toggle_term(terminals.buffer)
end, { desc = "Terminal buffer" })

-- Toggle most recently used terminal
local function toggle_last()
  if last.kind == "tab" then
    open_tab_terminal()
  elseif last.kind == "buffer" then
    open_buffer_terminal()
  else
    Snacks.terminal.toggle(last.cmd, last.opts)
  end
end

vim.keymap.set({ "n", "t" }, "<C-/>", toggle_last, { desc = "Toggle last terminal" })
vim.keymap.set({ "n", "t" }, "<C-_>", toggle_last, { desc = "Toggle last terminal" })
