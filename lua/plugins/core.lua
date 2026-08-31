return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        fish = {},
        sql = { "sql_formatter" },
      },
      formatters = {
        sql_formatter = {
          prepend_args = { "--language", "postgresql" },
        },
      },
    },
  },
}