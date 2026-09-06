local function toggle_all()
  if vim.fn.exists(":ToggleTermToggleAll") == 2 then
    vim.cmd("ToggleTermToggleAll")
    return
  end
  local ok, terminal = pcall(require, "snacks.terminal")
  if not ok then
    vim.notify("snacks.terminal not available", vim.log.levels.ERROR)
    return
  end
  local terms = terminal.list()
  if #terms == 0 then
    terminal.toggle()
    return
  end
  local any_visible = false
  for _, t in ipairs(terms) do
    if t:valid() then
      any_visible = true
      break
    end
  end
  if any_visible then
    for _, t in ipairs(terms) do
      if t:valid() then
        t:hide()
      end
    end
  else
    for _, t in ipairs(terms) do
      if not t:valid() then
        t:show()
      end
    end
  end
end

return {
  {
    "snacks.nvim",
    keys = {
      { "<leader>ta", toggle_all, desc = "Toggle All Terminals" },
    },
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        callback = function()
          vim.api.nvim_create_user_command("ToggleAllTerminals", toggle_all, {
            desc = "Toggle all snacks terminals (or ToggleTermToggleAll if toggleterm installed)",
          })
        end,
      })
    end,
  },
}
