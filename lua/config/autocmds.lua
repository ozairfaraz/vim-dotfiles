-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Auto cd to project root when opening a file via `nvim <path>` outside root
-- Fixes: terminal `pwd` showing `~` instead of project root, without using `autochdir` (which breaks LazyVim root/LSP)
-- Keeps your git fix intact: git_root() in keymaps.lua still wins via Snacks.git.get_root(file)
local auto_root = vim.api.nvim_create_augroup("AutoRootCwd", { clear = true })
vim.api.nvim_create_autocmd({ "VimEnter", "BufEnter" }, {
  group = auto_root,
  callback = function(ev)
    local buf = ev.buf
    -- ignore non-file buffers (terminal, help, etc.)
    if vim.bo[buf].buftype ~= "" then return end
    local file = vim.api.nvim_buf_get_name(buf)
    if file == "" then return end
    -- skip special buffers like gitcommit, etc. but still allow normal files
    if vim.bo[buf].filetype == "gitcommit" then return end
    -- only act if file exists (handles new files gracefully - use cwd fallback)
    -- even for new files we still want root detection via upward .git search
    local root
    -- 1) try LazyVim.root (lsp + .git + cwd) - most accurate for project
    local ok, r = pcall(function() return LazyVim.root.get({ buf = buf }) end)
    if ok and r and r ~= "" and vim.fn.isdirectory(r) == 1 then
      root = r
    end
    -- 2) fallback: Snacks git root from file (same as your git_root fix)
    if not root then
      local ok2, r2 = pcall(function() return Snacks.git.get_root(file) end)
      if ok2 and r2 and r2 ~= "" then root = r2 end
    end
    -- 3) fallback: fs.find .git upward from file
    if not root then
      local git = vim.fs.find(".git", { path = file, upward = true })[1]
      if git then root = vim.fn.fnamemodify(git, ":h") end
    end
    -- If LazyVim.root fell back to cwd (no git/lsp) and file is NOT inside cwd,
    -- treat as no root so we can fallback to file's dir. This handles `nvim /tmp/foo` from ~.
    if root then
      local cwd_now = vim.fn.getcwd()
      local norm_root_now = vim.fs.normalize(root)
      local norm_cwd_now = vim.fs.normalize(cwd_now)
      if norm_root_now == norm_cwd_now then
        local has_git = vim.fs.find(".git", { path = file, upward = true })[1] ~= nil
        if not has_git then
          local real_file = vim.uv.fs_realpath(file) or file
          real_file = vim.fs.normalize(real_file)
          if real_file:find(norm_root_now, 1, true) ~= 1 then
            root = nil -- force fallback to file's parent
          end
        end
      end
    end
    -- 4) fallback for non-git single files: use file's parent dir (fixes nvim /tmp/foo.txt -> terminal pwd = /tmp)
    if not root then
      local parent = vim.fn.fnamemodify(file, ":p:h")
      if parent ~= "" and vim.fn.isdirectory(parent) == 1 then
        root = parent
      end
    end
    if not root or root == "" or vim.fn.isdirectory(root) ~= 1 then return end
    local cwd = vim.fn.getcwd()
    -- normalize for comparison
    local norm_root = vim.fs.normalize(root)
    local norm_cwd = vim.fs.normalize(cwd)
    if norm_root == norm_cwd then return end
    -- only cd if file is inside root (prevents jumping when editing /tmp/foo outside repo)
    local real = vim.uv.fs_realpath(file) or file
    real = vim.fs.normalize(real)
    if real:find(norm_root, 1, true) ~= 1 then return end
    vim.fn.chdir(root)
  end,
})

-- Auto-reload files changed outside nvim (pairs with vim.opt.autoread = true in options.lua:88)
-- Fixes: old buffer when `npm install` / `git` / `prettier` changes file on disk
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI", "TermClose", "TermLeave" }, {
  group = vim.api.nvim_create_augroup("AutoChecktime", { clear = true }),
  callback = function()
    if vim.fn.getcmdwintype() == "" then
      vim.cmd("checktime")
    end
  end,
  desc = "Auto checktime when file changed externally",
})

-- Custom options for text/markdown files
local markdown_options = vim.api.nvim_create_augroup("MarkdownOptions", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = markdown_options,
  pattern = { "markdown", "text", "gitcommit" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.relativenumber = false
    vim.opt_local.number = false
    vim.opt_local.cursorline = false
    vim.opt_local.colorcolumn = ""
    vim.opt_local.signcolumn = "no"
  end,
})