-- ccc.nvim: color picker & highlighter for CSS/JS/TS etc.
-- Docs: https://github.com/uga-rosa/ccc.nvim
return {
  "uga-rosa/ccc.nvim",
  cmd = { "CccPick", "CccHighlighterToggle", "CccConvert" },
  opts = {
    highlighter = {
      auto_enable = true, -- enable highlight automatically
      lsp = true, -- highlight colors from LSP too
    },
    highlight_mode = "virtual", -- small circles next to the declaration
  },
  keys = {
    { "<leader>uC", "<cmd>CccPick<CR>", desc = "Pick color" },
    { "<leader>uH", "<cmd>CccHighlighterToggle<CR>", desc = "Toggle color highlighter" },
  },
}