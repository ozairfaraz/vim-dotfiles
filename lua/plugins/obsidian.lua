-- Obsidian vault integration. Your vault: ~/obsidianVault/obsidianVault
-- Docs: https://github.com/obsidian-nvim/obsidian.nvim
return {
  "obsidian-nvim/obsidian.nvim",
  version = "*",
  lazy = true,
  event = {
    "BufReadPre " .. vim.fn.expand("~") .. "/obsidianVault/obsidianVault/*.md",
    "BufNewFile " .. vim.fn.expand("~") .. "/obsidianVault/obsidianVault/*.md",
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  opts = {
    legacy_commands = false,
    workspaces = {
      {
        name = "obsidianVault",
        path = "~/obsidianVault/obsidianVault",
      },
    },
    picker = { name = "snacks" },
    completion = {
      blink_cmp = true,
      min_chars = 2,
    },
    ui = { enable = true },
  },
  keys = {
    { "<leader>on", "<cmd>Obsidian new<CR>", desc = "New note" },
    { "<leader>os", "<cmd>Obsidian search<CR>", desc = "Search notes" },
    { "<leader>of", "<cmd>Obsidian quick_switch<CR>", desc = "Quick switch" },
    { "<leader>ot", "<cmd>Obsidian today<CR>", desc = "Today's daily note" },
    { "<leader>ob", "<cmd>Obsidian backlinks<CR>", desc = "Backlinks" },
  },
}