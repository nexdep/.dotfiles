return {
  "okuuva/auto-save.nvim",
  event = { "InsertLeave", "TextChanged" }, -- lazy-load on first likely triggers
  cmd = "ASToggle",
  keys = {
    { "<leader>ua", "<cmd>ASToggle<cr>", desc = "Toggle Autosave" },
  },
  opts = {
    debounce_delay = 1000, -- 1s: gentle on watchers/formatters
    trigger_events = {
      immediate_save = { "BufLeave", "FocusLost", "QuitPre", "VimSuspend" },
      defer_save = { "InsertLeave", "TextChanged" },
      cancel_deferred_save = { "InsertEnter" },
    },
    -- Skip special/ephemeral buffers & UIs
    condition = function(buf)
      local bt = vim.bo[buf].buftype
      local ft = vim.bo[buf].filetype
      if bt ~= "" then return false end
      local excluded = {
        "gitcommit", "TelescopePrompt", "neo-tree", "lazy", "lazygit",
        "oil", "toggleterm", "alpha", "dashboard", "Outline", "prompt",
      }
      return not vim.tbl_contains(excluded, ft)
    end,
    -- Avoid extra autocmd noise when a formatter also runs on save:
    noautocmd = false,
  },
}

