-- ~/.config/nvim/lua/plugins/snacks-explorer-startup.lua

return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.explorer = opts.explorer or {}
      opts.explorer.enabled = true

      vim.api.nvim_create_autocmd("VimEnter", {
        group = vim.api.nvim_create_augroup("open_snacks_explorer", { clear = true }),
        callback = function()
          if vim.fn.argc() > 0 then
            return
          end

          vim.schedule(function()
            require("snacks").explorer({
              cwd = LazyVim.root(),
              enter = false,
            })
          end)
        end,
      })
    end,
  },
}
