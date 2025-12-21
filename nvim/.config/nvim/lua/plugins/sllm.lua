return {
  "mozanunal/sllm.nvim",
  dependencies = {
    "nvim-mini/mini.notify",
    "nvim-mini/mini.pick",
  },
  config = function()
    -- Disable all built-in keymaps
    require("sllm").setup({
      keymaps = false,
    })

    -- Define your own mappings
    local sllm = require("sllm")

    vim.keymap.set({ "n", "v" }, "<leader>a", sllm.ask_llm, { desc = "Ask LLM [custom]" })
  end,
}
