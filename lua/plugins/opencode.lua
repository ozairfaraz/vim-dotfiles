-- opencode.nvim: OpenCode AI inside Neovim.
-- Docs: https://github.com/nickjvandyke/opencode.nvim
-- NOTE: opencode v2 removed `--port` from top-level CLI (now `opencode serve --port`).
-- Use plain `opencode` for the TUI; it auto-connects to the background service at
-- ~/.local/state/opencode/service.json. Keep `--port` only if you downgrade to opencode v1.
local opencode_cmd = "opencode"
-- Pin cwd so snacks.terminal tid is stable (otherwise `cwd = vim.fn.getcwd(0)` per-window creates duplicate terms)
local _opencode_cwd = vim.uv.cwd()
---@type snacks.terminal.Opts
local opencode_term_opts = {
  win = { position = "right", enter = true },
  cwd = _opencode_cwd,
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

-- opencode v2 (2.0.8) is incompatible with opencode.nvim v1 API (expects /global/health etc).
-- Detect v2 and provide fallback that uses the TUI directly instead of the API, to avoid
-- "Failed to connect..." popup + duplicate `opencode` pane on <leader>aa etc.
local function is_opencode_v2()
  local v = vim.fn.system("opencode --version 2>/dev/null")
  return v:match("v2%.") ~= nil
end

local function fallback_send(text, opts)
  opts = opts or {}
  local focus = opts.focus ~= false -- default true, set {focus=false} to just ensure visible without stealing focus
  -- Reuse the single right-pane terminal (same tid as <leader>ao) - don't create second instance
  local prev_win = vim.api.nvim_get_current_win()
  local term = require("snacks.terminal").get(opencode_cmd, opencode_term_opts)
  -- Only show if hidden; if already visible, just focus/send
  local is_visible = false
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == term.buf then is_visible = true break end
  end
  if not is_visible then
    term:show()
    if not focus then
      -- show() with enter=true steals focus - restore so vim.ui.input stays focused
      vim.schedule(function()
        if vim.api.nvim_win_is_valid(prev_win) then
          pcall(vim.api.nvim_set_current_win, prev_win)
        end
      end)
    end
  end
  local attempts = 0
  local function try_send()
    attempts = attempts + 1
    local chan = term and term.buf and vim.b[term.buf] and vim.b[term.buf].terminal_job_id
    if chan and text and text ~= "" then
      pcall(vim.api.nvim_chan_send, chan, text)
      return
    end
    if attempts < 10 then
      vim.defer_fn(try_send, 100)
    end
  end
  vim.defer_fn(try_send, 100)
  if focus and term and term.buf and vim.api.nvim_win_get_buf(0) ~= term.buf then
    vim.schedule(function()
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(win) == term.buf then
          vim.api.nvim_set_current_win(win)
          vim.cmd("startinsert")
          break
        end
      end
    end)
  end
end

local _v2_warned = false
local function ask_or_fallback(default)
  if is_opencode_v2() then
    -- Only warn once per session to avoid stealing focus from the input box
    if not _v2_warned then
      _v2_warned = true
      vim.defer_fn(function()
        vim.notify(
          "opencode v2: using TUI fallback (opencode.nvim expects v1). Downgrade for full integration: curl -fsSL https://opencode.ai/install | bash -s -- --version 1.18.31",
          vim.log.levels.WARN,
          { title = "opencode" }
        )
      end, 500)
    end
    -- Expand minimal context without server API
    local ctx = default or ""
    if ctx:match("@this") or ctx:match("@buffer") then
      local buf = vim.api.nvim_get_current_buf()
      local fname = vim.api.nvim_buf_get_name(buf)
      local display = fname ~= "" and vim.fn.fnamemodify(fname, ":.") or "[No Name]"
      if ctx:match("@this") then
        local cur = vim.api.nvim_win_get_cursor(0)
        local range = nil
        local mode = vim.fn.mode()
        if mode:match("[vV\22]") then
          local s = vim.api.nvim_buf_get_mark(buf, "<")
          local e = vim.api.nvim_buf_get_mark(buf, ">")
          range = { from = s, to = e }
        end
        local formatted
        if range then
          formatted = require("opencode.context").format({
            buf = buf,
            from = range.from,
            to = range.to,
            rel = vim.fn.getcwd(),
          }) or display
        else
          local cur = vim.api.nvim_win_get_cursor(0)
          formatted = require("opencode.context").format({
            buf = buf,
            from = { cur[1], cur[2] + 1 },
            to = { cur[1], cur[2] + 1 },
            rel = vim.fn.getcwd(),
          }) or display
        end
        ctx = ctx:gsub("@this", formatted):gsub("@buffer", display)
      else
        local display2 = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":.")
        ctx = ctx:gsub("@buffer", display2 ~= "" and display2 or "[No Name]")
      end
    end
    -- Ensure TUI is visible but DON'T steal focus from the input box
    fallback_send("", { focus = false })
    vim.ui.input({ prompt = "Ask OpenCode: ", default = ctx }, function(input)
      if input and input ~= "" then
        fallback_send(input .. " ", { focus = true })
      end
    end)
    return
  end
  require("opencode").ask(default)
end

return {
  {
    "nickjvandyke/opencode.nvim",
    event = "VeryLazy",
    init = function()
      -- Read v2 background service URL/password dynamically (port is random per restart).
      -- Falls back to 40961 for opencode v1 compatibility.
      local function load_service()
        for _, p in ipairs({
          vim.fn.expand("~/.local/state/opencode/service.json"),
          vim.fn.expand("~/.config/opencode/service.json"),
        }) do
          local f = io.open(p, "r")
          if f then
            local ok, data = pcall(vim.json.decode, f:read("*a"))
            f:close()
            if ok and data and data.url then return data end
          end
        end
        return nil
      end
      local svc = load_service()
      local v2 = is_opencode_v2()
      if v2 then
        _v2_warned = true
        vim.defer_fn(function()
          vim.notify(
            "opencode v2.0.8 detected: opencode.nvim v1 API is incompatible. <leader>ao (TUI) works; <leader>aa/ax/ab/go use TUI fallback. Downgrade for full integration: curl -fsSL https://opencode.ai/install | bash -s -- --version 1.18.31",
            vim.log.levels.WARN,
            { title = "opencode" }
          )
        end, 800)
      end
      ---@type opencode.Opts
      vim.g.opencode_opts = {
        server = {
          -- For v2: connect to background service (dynamic port). For v1: fixed 40961 still works.
          url = svc and svc.url or "http://localhost:40961",
          password = svc and svc.password or nil,
          -- For v2, don't auto-start via discovery (would spawn duplicate TUI + still fail health),
          -- the toggle is managed by <leader>ao.
          start = v2 and false or opencode_start,
        },
      }
    end,
    keys = {
      { "<leader>ao", opencode_toggle, desc = "Toggle OpenCode pane", mode = { "n", "t" } },
      {
        "<leader>aa",
        function() ask_or_fallback("@this: ") end,
        desc = "Ask OpenCode (context)",
        mode = { "n", "x" },
      },
      {
        "<leader>ax",
        function()
          if is_opencode_v2() then
            if not _v2_warned then
              _v2_warned = true
              vim.defer_fn(function()
                vim.notify("opencode v2: select menu requires v1 API - use TUI via <leader>ao", vim.log.levels.WARN, { title = "opencode" })
              end, 300)
            end
            fallback_send("", { focus = true })
            return
          end
          require("opencode").select()
        end,
        desc = "OpenCode actions",
        mode = { "n", "x" },
      },
      {
        "<leader>ab",
        function() ask_or_fallback("@buffer: ") end,
        desc = "Ask about buffer",
        mode = { "n", "x" },
      },
      {
        "go",
        function()
          if is_opencode_v2() then
            _G.opencode_prompt_operator = function(kind)
              local s = vim.api.nvim_buf_get_mark(0, "[")
              local e = vim.api.nvim_buf_get_mark(0, "]")
              if s[1] > e[1] or (s[1] == e[1] and s[2] > e[2]) then s, e = e, s end
              local text = require("opencode.context").format({
                buf = vim.api.nvim_get_current_buf(),
                from = s,
                to = e,
                rel = vim.fn.getcwd(),
              }) or ""
              fallback_send(text .. " ")
            end
            vim.o.operatorfunc = "v:lua.opencode_prompt_operator"
            return "g@"
          end
          return require("opencode").operator("@this ")
        end,
        desc = "Append range to OpenCode",
        expr = true,
      },
      {
        "goo",
        function()
          if is_opencode_v2() then
            _G.opencode_prompt_operator = function()
              local lnum = vim.api.nvim_buf_get_mark(0, "[")[1]
              local text = require("opencode.context").format({
                buf = vim.api.nvim_get_current_buf(),
                from = { lnum, 1 },
                to = { lnum, 1 },
                rel = vim.fn.getcwd(),
              }) or ""
              fallback_send(text .. " ")
            end
            vim.o.operatorfunc = "v:lua.opencode_prompt_operator"
            return "g@_"
          end
          return require("opencode").operator("@this ") .. "_"
        end,
        desc = "Append line to OpenCode",
        expr = true,
      },
    },
  },
  -- Send snacks picker results to opencode with <A-a>
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.picker = vim.tbl_deep_extend("force", opts.picker or {}, {
        actions = {
          opencode_send = function(picker, ...)
            if is_opencode_v2() then
              local items = vim.tbl_map(function(item)
                return item.file
                    and require("opencode.context").format({
                      path = item.file,
                      from = item.pos,
                      to = item.end_pos,
                      rel = vim.fn.getcwd(),
                    })
                  or item.text
              end, picker:selected({ fallback = true }))
              fallback_send(table.concat(items, ", ") .. " ")
              return
            end
            return require("opencode").snacks_picker_send(picker, ...)
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
