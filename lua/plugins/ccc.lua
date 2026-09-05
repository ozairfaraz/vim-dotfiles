-- ccc.nvim: color picker & highlighter for CSS/JS/TS etc.
-- Docs: https://github.com/uga-rosa/ccc.nvim
return {
  "uga-rosa/ccc.nvim",
  cmd = { "CccPick", "CccHighlighterToggle", "CccConvert" },
  opts = {
    highlighter = {
      auto_enable = false, -- disabled for hipatterns (best highlighter) - keep ccc as picker only
      lsp = false,
    },
    highlight_mode = "virtual", -- small circles if you :CccHighlighterToggle
  },
  keys = {
    { "<leader>uC", "<cmd>CccPick<CR>", desc = "Pick color" },
    { "<leader>uH", "<cmd>CccHighlighterToggle<CR>", desc = "Toggle color highlighter" },
  },
}