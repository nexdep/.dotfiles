return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        texlab = {
          settings = {
            texlab = {
              diagnostics = {
                ignoredPatterns = {
                  "Unused label",
                },
              },
            },
          },
        },
      },
    },
  },
}
