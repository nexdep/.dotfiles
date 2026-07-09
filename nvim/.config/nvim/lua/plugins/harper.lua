return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        harper_ls = {
          cmd = { "harper-ls", "--stdio" },

          -- Important: explicitly include TeX/LaTeX.
          filetypes = {
            "tex",
            "plaintex",
            "latex",
            "bib",
            "markdown",
            "text",
            "typst",
            "gitcommit",
            "mail",
          },

          settings = {
            ["harper-ls"] = {
              dialect = "American", -- "British", "Canadian", "Australian", "Indian"
              diagnosticSeverity = "hint",

              linters = {
                SpellCheck = true,
                SpelledNumbers = false,
                AnA = true,
                SentenceCapitalization = false,
                UnclosedQuotes = true,
                WrongApostrophe = false,
                LongSentences = true,
                RepeatedWords = true,
                Spaces = true,
                CorrectNumberSuffix = true,
              },

              markdown = {
                IgnoreLinkTitle = false,
              },

              codeActions = {
                ForceStable = false,
              },

              excludePatterns = {
                -- Add project-specific generated files here if needed.
                -- "build/**",
                -- "*.aux",
                -- "*.bbl",
              },
            },
          },
        },
      },
    },
  },

  -- Avoid duplicate diagnostics from Neovim's built-in spell checker.
  {
    "LazyVim/LazyVim",
    opts = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "tex", "plaintex", "latex", "bib" },
        callback = function()
          vim.opt_local.spell = false
        end,
      })
    end,
  },
}
