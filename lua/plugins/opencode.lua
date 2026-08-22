-- opencode.nvim: OpenCode AI inside Neovim.
-- Docs: https://github.com/nickjvandyke/opencode.nvim
local opencode_cmd = "opencode --port 40961"
---@type snacks.terminal.Opts
local opencode_term_opts = {
  win = { position = "right", enter = true },
}

local function opencode_start()
  local terminal = require("snacks.terminal").get(opencode_cmd, opencode_term_opts)
  terminal:show()
end

local function opencode_toggle()
  local snacks_terminal = require("snacks.terminal")
  local terminal = snacks_terminal.toggle(opencode_cmd, opencode_term_opts)
  if terminal and terminal.buf and not vim.b[terminal.buf]._opencode_autoinsert then
    vim.b[terminal.buf]._opencode_autoinsert = true
    vim.api.nvim_create_autocmd("WinEnter", {
      buffer = terminal.buf,
      callback = function()
        if vim.bo.buftype == "terminal" and not vim.api.nvim_get_mode().mode:match("^t") then
          vim.schedule(function()
            if vim.bo.buftype == "terminal" then
              vim.cmd("startinsert")
            end
          end)
        end
      end,
    })
  end
end

return {
  {
    "nickjvandyke/opencode.nvim",
    event = "VeryLazy",
    init = function()
      ---@type opencode.Opts
      vim.g.opencode_opts = {
        server = {
          -- Always talk to the single pane managed below, never the server picker.
          url = "http://localhost:40961",
          start = opencode_start,
        },
      }
    end,
    keys = {
      { "<leader>ao", opencode_toggle, desc = "Toggle OpenCode pane", mode = { "n", "t" } },
      { "<leader>aa", function() require("opencode").ask("@this: ") end, desc = "Ask OpenCode (context)", mode = { "n", "x" } },
      { "<leader>ax", function() require("opencode").select() end, desc = "OpenCode actions", mode = { "n", "x" } },
      { "<leader>ab", function() require("opencode").ask("@buffer: ") end, desc = "Ask about buffer", mode = { "n", "x" } },
      { "go", function() return require("opencode").operator("@this ") end, desc = "Append range to OpenCode", expr = true },
      { "goo", function() return require("opencode").operator("@this ") .. "_" end, desc = "Append line to OpenCode", expr = true },
    },
  },
  -- Send snacks picker results to opencode with <A-a>
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.picker = vim.tbl_deep_extend("force", opts.picker or {}, {
        actions = {
          opencode_send = function(...)
            return require("opencode").snacks_picker_send(...)
          end,
        },
        win = {
          input = {
            keys = {
              ["<a-a>"] = { "opencode_send", mode = { "n", "i" } },
            },
          },
        },
      })
    end,
  },
}
