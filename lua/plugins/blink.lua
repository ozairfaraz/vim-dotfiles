return {
  "saghen/blink.cmp",
  keys = {
    { "<C-space>", false },
  },
  opts = {
    keymap = {
      preset = "enter",
      ["<CR>"] = { "select_and_accept", "fallback" },
      ["<C-l>"] = { "show", "show_documentation", "hide_documentation" },
    },
  },
}
