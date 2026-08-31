return {
  "saghen/blink.cmp",
  keys = {
    { "<C-space>", false },
  },
  opts = {
    keymap = {
      preset = "enter",
      ["<C-l>"] = { "show", "show_documentation", "hide_documentation" },
    },
  },
}
