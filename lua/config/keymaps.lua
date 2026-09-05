-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

local function jj_to_esc()
  local key = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
  vim.api.nvim_feedkeys(key, "i", false)
end

-- jj to escape in insert mode (300ms timeout)
map("i", "jj", jj_to_esc, { desc = "Exit insert mode with jj" })
vim.opt.timeoutlen = 300

-- Quick config editing
map("n", "<leader>rc", "<Cmd>e ~/.config/nvim/init.lua<CR>", { desc = "Edit config" })

-- Center screen when jumping (mini.animate compatible)
map("n", "n", function()
  local ok, animate = pcall(require, "mini.animate")
  if ok and not vim.g.minianimate_disable and not vim.b.minianimate_disable then
    pcall(animate.execute_after, "cursor", "normal! zz")
    pcall(animate.execute_after, "cursor", "normal! zv")
    return "n"
  end
  return "nzzzv"
end, { expr = true, desc = "Next search result (centered)" })
map("n", "N", function()
  local ok, animate = pcall(require, "mini.animate")
  if ok and not vim.g.minianimate_disable and not vim.b.minianimate_disable then
    pcall(animate.execute_after, "cursor", "normal! zz")
    pcall(animate.execute_after, "cursor", "normal! zv")
    return "N"
  end
  return "Nzzzv"
end, { expr = true, desc = "Previous search result (centered)" })
map("n", "<C-d>", function()
  local ok, animate = pcall(require, "mini.animate")
  if ok and not vim.g.minianimate_disable and not vim.b.minianimate_disable then
    pcall(animate.execute_after, "scroll", "normal! zz")
    return vim.api.nvim_replace_termcodes("<C-d>", true, false, true)
  end
  return vim.api.nvim_replace_termcodes("<C-d>zz", true, false, true)
end, { expr = true, desc = "Half page down (centered)" })
map("n", "<C-u>", function()
  local ok, animate = pcall(require, "mini.animate")
  if ok and not vim.g.minianimate_disable and not vim.b.minianimate_disable then
    pcall(animate.execute_after, "scroll", "normal! zz")
    return vim.api.nvim_replace_termcodes("<C-u>", true, false, true)
  end
  return vim.api.nvim_replace_termcodes("<C-u>zz", true, false, true)
end, { expr = true, desc = "Half page up (centered)" })

-- Clear search highlights
map("n", "<leader>c", ":nohlsearch<CR>", { desc = "Clear search highlights" })

-- Paste / delete without yanking
map("x", "<leader>p", '"_dP', { desc = "Paste without yanking" })

-- Buffer navigation
map("n", "<leader>bn", ":bnext<CR>", { desc = "Next buffer" })
map("n", "<leader>bp", ":bprevious<CR>", { desc = "Previous buffer" })

-- Splitting
map("n", "<leader>sv", ":vsplit<CR>", { desc = "Split window vertically" })
map("n", "<leader>sh", ":split<CR>", { desc = "Split window horizontally" })

-- Better J behaviour
map("n", "J", "mzJ`z", { desc = "Join lines and keep cursor position" })

-- Copy full file path
map("n", "<leader>pa", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  print("file:", path)
end, { desc = "Copy full file path" })
