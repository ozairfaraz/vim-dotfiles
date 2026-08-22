-- smart-splits.nvim: move across tmux panes and nvim windows with <C-h/j/k/l>
-- Docs: https://github.com/mrjones2014/smart-splits.nvim
return {
  {
    "mrjones2014/smart-splits.nvim",
    lazy = false,
    config = function()
      require("smart-splits").setup({
        tmux = { enabled = true }, -- seamless tmux pane navigation
      })
      local ss = require("smart-splits")
      local map = vim.keymap.set
      local function move(fn)
        return function()
          fn({ passthrough = false })
        end
      end
      map("n", "<C-h>", move(ss.move_cursor_left), { desc = "Move to left window/pane" })
      map("n", "<C-j>", move(ss.move_cursor_down), { desc = "Move to bottom window/pane" })
      map("n", "<C-k>", move(ss.move_cursor_up), { desc = "Move to top window/pane" })
      map("n", "<C-l>", move(ss.move_cursor_right), { desc = "Move to right window/pane" })
      map("n", "<C-S-h>", ss.resize_left, { desc = "Resize window/pane left" })
      map("n", "<C-S-j>", ss.resize_down, { desc = "Resize window/pane down" })
      map("n", "<C-S-k>", ss.resize_up, { desc = "Resize window/pane up" })
      map("n", "<C-S-l>", ss.resize_right, { desc = "Resize window/pane right" })
    end,
  },
}