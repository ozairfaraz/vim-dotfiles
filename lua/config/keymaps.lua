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

-- Git quick actions (add / commit / push) - best fix for missing workflow
-- Keeps lazygit as primary UI (<leader>gg), adds direct keys for the 3 most common ops
-- Robust git_root: prefers buffer's git root (Snacks) then LazyVim root then cwd
-- Fixes space+g+d Command failed (exit 129 Not a git repo) when nvim started outside repo
local function git_root()
  -- 1. try Snacks git root from current buffer file (most reliable)
  local buf = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(buf)
  if file ~= "" then
    local ok, r = pcall(function() return Snacks.git.get_root(file) end)
    if ok and r and r ~= "" then return r end
    -- fallback: fs.find .git upward from file
    local git = vim.fs.find(".git", { path = file, upward = true })[1]
    if git then return vim.fn.fnamemodify(git, ":h") end
  end
  -- 2. LazyVim root (handles lsp + pattern + cwd)
  local ok, r = pcall(function() return LazyVim.root.git() end)
  if ok and r and r ~= "" then
    -- verify it's actually a git repo, else continue
    if vim.fn.isdirectory(r .. "/.git") == 1 or Snacks.git.get_root(r) then return r end
  end
  -- 3. Snacks git root from cwd
  do
    local cwd = vim.fn.getcwd()
    local ok2, r2 = pcall(function() return Snacks.git.get_root(cwd) end)
    if ok2 and r2 and r2 ~= "" then return r2 end
  end
  return vim.fn.getcwd()
end

-- <leader>ga - git add . (stage all)
map("n", "<leader>ga", function()
  local root = git_root()
  local out = vim.fn.system({ "git", "-C", root, "add", "." })
  if vim.v.shell_error == 0 then
    vim.notify("Git: staged all (git add .)", vim.log.levels.INFO)
    pcall(function() require("gitsigns").refresh() end)
  else
    vim.notify("Git add failed: " .. out, vim.log.levels.ERROR)
  end
end, { desc = "Git Add All (.)" })

-- <leader>gA - git add current file
map("n", "<leader>gA", function()
  local root = git_root()
  local file = vim.fn.expand("%:p")
  if file == "" then return vim.notify("No file to add", vim.log.levels.WARN) end
  local out = vim.fn.system({ "git", "-C", root, "add", "--", file })
  if vim.v.shell_error == 0 then
    vim.notify("Git: staged " .. vim.fn.expand("%:t"), vim.log.levels.INFO)
    pcall(function() require("gitsigns").refresh() end)
  else
    vim.notify("Git add failed: " .. out, vim.log.levels.ERROR)
  end
end, { desc = "Git Add Current File" })

-- <leader>gc - git commit with prompt (quick), <leader>gC - amend
map("n", "<leader>gc", function()
  vim.ui.input({ prompt = "Commit message: " }, function(msg)
    if not msg or msg == "" then return end
    local root = git_root()
    local out = vim.fn.system({ "git", "-C", root, "commit", "-m", msg })
    if vim.v.shell_error == 0 then
      vim.notify(out, vim.log.levels.INFO)
      pcall(function() require("gitsigns").refresh() end)
    else
      vim.notify(out, vim.log.levels.ERROR)
    end
  end)
end, { desc = "Git Commit" })

map("n", "<leader>gC", function()
  local root = git_root()
  -- open terminal for amend (shows editor if needed, handles long messages)
  Snacks.terminal({ "git", "commit", "--amend" }, { cwd = root })
end, { desc = "Git Commit Amend" })

-- <leader>gP - git push (overrides snacks GH PR all; PR open stays on <leader>gp)
-- Push is far more frequent than "PRs (all)" - original PR all available via :lua Snacks.picker.gh_pr({state="all"})
map("n", "<leader>gP", function()
  local root = git_root()
  Snacks.terminal({ "git", "push" }, { cwd = root })
end, { desc = "Git Push" })

-- <leader>gpu - git pull (bonus, free key), <leader>gf is already git log file
map("n", "<leader>gpu", function()
  local root = git_root()
  Snacks.terminal({ "git", "pull" }, { cwd = root })
end, { desc = "Git Pull" })

-- Fix Snacks git pickers: ensure they use git root not vim cwd (fixes `space+g+d` Command failed when nvim started outside repo)
-- Overrides LazyVim snacks_picker.lua:75-78 which uses vim cwd and fails with `Not a git repository` (exit 129)
-- Best practice minimal stack: gitsigns + snacks picker + lazygit (no diffview/neogit needed for light usage)
local function with_git_root(picker, extra)
  return function()
    local root = git_root()
    if vim.fn.isdirectory(root .. "/.git") ~= 1 and Snacks.git.get_root(root) == nil then
      vim.notify("Not in a git repository (git_root=" .. root .. ", cwd=" .. vim.fn.getcwd() .. ")", vim.log.levels.WARN)
      return
    end
    extra = extra or {}
    -- clone to avoid mutating shared table across calls (fix for gL which passed cwd=git_root() at define time)
    local opts = vim.tbl_deep_extend("force", {}, extra)
    opts.cwd = root
    Snacks.picker[picker](opts)
  end
end

-- hunk/status pickers (most used)
map("n", "<leader>gd", with_git_root("git_diff"), { desc = "Git Diff (hunks) [fix cwd]" })
map("n", "<leader>gs", with_git_root("git_status"), { desc = "Git Status [fix cwd]" })
map("n", "<leader>gS", with_git_root("git_stash"), { desc = "Git Stash [fix cwd]" })
-- origin diff (grouped)
map("n", "<leader>gD", function()
  local root = git_root()
  if vim.fn.isdirectory(root .. "/.git") ~= 1 and Snacks.git.get_root(root) == nil then
    vim.notify("Not in a git repository", vim.log.levels.WARN)
    return
  end
  Snacks.picker.git_diff({ cwd = root, base = "origin", group = true })
end, { desc = "Git Diff (origin) [fix cwd]" })
-- log pickers
map("n", "<leader>gl", with_git_root("git_log"), { desc = "Git Log [fix cwd]" })
map("n", "<leader>gL", with_git_root("git_log"), { desc = "Git Log (cwd) [fix cwd]" })
map("n", "<leader>gf", with_git_root("git_log_file"), { desc = "Git Current File History [fix cwd]" })
map("n", "<leader>gb", with_git_root("git_log_line"), { desc = "Git Blame Line [fix cwd]" })
-- Recommended: keep <leader>gP as push (more frequent than gh_pr all), gp stays gh_pr open, gi stays gh_issue
-- gh_pr(all) still via :lua Snacks.picker.gh_pr({state="all"}) if needed

-- Manual cwd helpers (complement AutoRootCwd - useful when you want file dir instead of root)
map("n", "<leader>cr", function()
  local root = LazyVim.root.get()
  vim.fn.chdir(root)
  vim.notify("cwd -> " .. root, vim.log.levels.INFO)
end, { desc = "cd to root" })
map("n", "<leader>cfd", function()
  local dir = vim.fn.expand("%:p:h")
  if dir ~= "" then
    vim.cmd.lcd(dir)
    vim.notify("lcd -> " .. dir, vim.log.levels.INFO)
  end
end, { desc = "lcd to file dir" })
