-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Language / spell
vim.opt.spelllang = { "en", "de" } -- English + German spellcheck

-- Editing comfort
vim.opt.scrolloff = 10 -- Keep 10 lines above/below cursor
vim.opt.sidescrolloff = 8 -- Keep 8 columns left/right of cursor
vim.opt.matchtime = 2 -- How long to show matching bracket
vim.opt.showmatch = true -- Highlight matching brackets
vim.opt.iskeyword:append("-") -- Treat dash as part of a word
vim.opt.path:append("**") -- Search into subfolders with `gf`

-- Search
vim.opt.hlsearch = false -- Don't highlight search results
vim.opt.incsearch = true -- Show matches as you type

-- Popup / floating windows
vim.opt.pumheight = 10 -- Popup menu height
vim.opt.pumblend = 10 -- Popup menu transparency
vim.opt.winblend = 0 -- Floating window transparency

-- Markdown / Obsidian
vim.opt.conceallevel = 2 -- Hide markup (Obsidian requirement)
vim.opt.concealcursor = "" -- Show markup even on cursor line

-- Large files
vim.opt.redrawtime = 10000 -- Timeout for syntax highlighting redraw
vim.opt.maxmempattern = 20000 -- Max memory for pattern matching
vim.opt.synmaxcol = 300 -- Syntax highlighting column limit

-- Undo directory
vim.opt.undofile = true -- Persistent undo
local undodir = vim.fn.stdpath("state") .. "/undodir"
vim.opt.undodir = undodir
vim.fn.mkdir(undodir, "p") -- Create if not exists

-- Put mason binaries on PATH (gopls, vtsls, prettierd, etc.)
local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
if vim.fn.isdirectory(mason_bin) == 1 then
  vim.env.PATH = mason_bin .. ":" .. vim.env.PATH
end

-- Local Go toolchain (installed at ~/.local/go, used by gopls)
local go_bin = vim.fn.expand("~") .. "/.local/go/bin"
if vim.fn.isdirectory(go_bin) == 1 then
  vim.env.PATH = go_bin .. ":" .. vim.env.PATH
end

-- Cursor
vim.opt.guicursor = {
  "n-v-c:block", -- Normal, Visual, Command-line
  "i-ci-ve:ver25", -- Insert, Command-line Insert, Visual-exclusive
  "r-cr:hor20", -- Replace, Command-line Replace
  "o:hor50", -- Operator-pending
  "a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor", -- All modes: blinking & highlight groups
  "sm:block-blinkwait175-blinkoff150-blinkon175", -- Showmatch mode
}

-- Folding
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevel = 99 -- Keep all folds open by default

-- Splits
vim.opt.splitbelow = true -- Horizontal splits open below
vim.opt.splitright = true -- Vertical splits open to the right

-- Diff
vim.opt.diffopt:append("vertical") -- Vertical diff splits
vim.opt.diffopt:append("algorithm:patience") -- Better diff algorithm
vim.opt.diffopt:append("linematch:60") -- Better diff highlighting (smart line matching)

-- Behavior
vim.opt.autoread = true -- Auto-reload file if changed outside
vim.opt.autowrite = false -- Don't auto-save on some events
vim.opt.errorbells = false -- Disable error sounds
vim.opt.modifiable = true -- Allow editing buffers

-- Misc
vim.opt.timeoutlen = 500 -- Time in ms to wait for mapped sequence
vim.opt.colorcolumn = "120" -- Show column at 120 characters
vim.opt.wildignorecase = true -- Case-insensitive tab completion in commands