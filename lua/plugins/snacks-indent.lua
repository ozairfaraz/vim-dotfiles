return {
  {
    "folke/snacks.nvim",
    opts = {
      indent = {
        indent = {
          char = "│",
          hl = {
            "SnacksIndent1",
            "SnacksIndent2",
            "SnacksIndent3",
            "SnacksIndent4",
            "SnacksIndent5",
            "SnacksIndent6",
            "SnacksIndent7",
            "SnacksIndent8",
          },
        },
        animate = {
          enabled = true,
          style = "out",
          easing = "linear",
          duration = { step = 20, total = 500 },
        },
        scope = {
          enabled = true,
          char = "│",
          hl = "SnacksIndentScope",
          underline = false,
        },
        chunk = {
          enabled = true,
          char = {
            corner_top = "╭",
            corner_bottom = "╰",
            horizontal = "─",
            vertical = "│",
            arrow = ">",
          },
          hl = "SnacksIndentChunk",
        },
      },
      scope = { enabled = true },
    },
  },
}
