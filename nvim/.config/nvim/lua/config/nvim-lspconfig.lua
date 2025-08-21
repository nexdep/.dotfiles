return {
  "neovim/nvim-lspconfig",
  opts = function(_, opts)
    opts.servers = opts.servers or {}

    -- Make Pyright negotiate/use UTF-8 so it matches ruff
    opts.servers.pyright = vim.tbl_deep_extend("force", opts.servers.pyright or {}, {
      capabilities = {
        general = { positionEncodings = { "utf-8" } }, -- LSP 3.17
      },
      on_init = function(client)
        client.offset_encoding = "utf-8"
      end, -- belt & suspenders
    })

    -- (optional) keep ruff explicitly on UTF-8 too
    opts.servers.ruff = vim.tbl_deep_extend("force", opts.servers.ruff or {}, {
      on_init = function(client)
        client.offset_encoding = "utf-8"
      end,
    })
  end,
}
