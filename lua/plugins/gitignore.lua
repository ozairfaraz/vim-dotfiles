-- gitignore.nvim: generate a .gitignore from github/gitignore templates.
-- Upstream resolves the output path with `vim.fs.abspath()`, which resolves
-- against `vim.uv.cwd()` rather than the current buffer. Launching nvim from
-- ~ therefore wrote ~/.gitignore. Here we resolve it against the buffer's
-- directory instead, and still honour an explicit `--path`/`-p`.
-- Docs: https://github.com/bwpge/gitignore.nvim
return {
  {
    "bwpge/gitignore.nvim",
    -- eager (no `cmd`) so :Gitignore and the <leader>i keymap in
    -- lua/config/keymaps.lua always exist. lazy's `keys` handler does not
    -- fire in this config because defaults.lazy = false in lua/config/lazy.lua
    config = function(_, opts)
      require("gitignore").setup(opts)

      local C = require("gitignore.cli")

      vim.api.nvim_create_user_command("Gitignore", function(ctx)
        local explicit_path = false
        for _, v in ipairs(ctx.fargs) do
          if v == "--path" or v == "-p" then
            explicit_path = true
            break
          end
        end

        if not explicit_path then
          local bufname = vim.api.nvim_buf_get_name(0)
          local dir = bufname ~= "" and vim.fs.dirname(bufname) or vim.uv.cwd()
          table.insert(ctx.fargs, 1, "--path")
          table.insert(ctx.fargs, 2, vim.fs.joinpath(dir, ".gitignore"))
        end

        -- upstream cli.lua has a leftover `vim.print(ctx.fargs)` on the
        -- --path route; silence it so it doesn't spam the message area
        local print_ = vim.print
        vim.print = function() end
        local ok, err = pcall(C.command, ctx)
        vim.print = print_

        if not ok then
          vim.notify(err, vim.log.levels.ERROR, { title = "gitignore.nvim" })
        end
      end, C.cmd_opts)
    end,
  },
}
