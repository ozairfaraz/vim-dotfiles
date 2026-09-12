return {
  "jake-stewart/multicursor.nvim",
  branch = "1.0",
  lazy = false,
  config = function()
    local mc = require("multicursor-nvim")
    mc.setup()

    local set = vim.keymap.set

    -- Vertical: Kitty-safe S-Down / S-Up (and leader fallback for tmux)
    set({ "n", "x" }, "<S-Down>", function() mc.lineAddCursor(1) end, { desc = "Multicursor add below" })
    set({ "n", "x" }, "<S-Up>", function() mc.lineAddCursor(-1) end, { desc = "Multicursor add above" })
    set({ "n", "x" }, "<leader>j", function() mc.lineAddCursor(1) end, { desc = "Multicursor add below (leader)" })
    set({ "n", "x" }, "<leader>k", function() mc.lineAddCursor(-1) end, { desc = "Multicursor add above (leader)" })
    set({ "n", "x" }, "<leader><S-Down>", function() mc.lineSkipCursor(1) end, { desc = "Multicursor skip below" })
    set({ "n", "x" }, "<leader><S-Up>", function() mc.lineSkipCursor(-1) end, { desc = "Multicursor skip above" })
    set({ "n", "x" }, "ga", mc.addCursorOperator, { desc = "Multicursor add per line (operator)" })

    -- Anywhere: mouse + toggle
    set("n", "<C-LeftMouse>", mc.handleMouse, { desc = "Multicursor mouse add/remove" })
    set("n", "<C-LeftDrag>", mc.handleMouseDrag)
    set("n", "<C-LeftRelease>", mc.handleMouseRelease)
    set({ "n", "x" }, "<C-q>", mc.toggleCursor, { desc = "Multicursor toggle" })
    set({ "n", "x" }, "<leader><C-q>", mc.duplicateCursors, { desc = "Multicursor duplicate" })

    -- All similar words / incremental
    set({ "n", "x" }, "<leader>n", function() mc.matchAddCursor(1) end, { desc = "Multicursor next occurrence" })
    set({ "n", "x" }, "<leader>N", function() mc.matchAddCursor(-1) end, { desc = "Multicursor prev occurrence" })
    set({ "n", "x" }, "<leader>s", function() mc.matchSkipCursor(1) end, { desc = "Multicursor skip next" })
    set({ "n", "x" }, "<leader>S", function() mc.matchSkipCursor(-1) end, { desc = "Multicursor skip prev" })
    set({ "n", "x" }, "<leader>A", mc.matchAllAddCursors, { desc = "Multicursor all matches" })
    set("x", "M", mc.matchCursors, { desc = "Multicursor match regex in selection" })
    set("x", "S", mc.splitCursors, { desc = "Multicursor split by regex" })
    set("x", "I", mc.insertVisual, { desc = "Multicursor insert per line" })
    set("x", "A", mc.appendVisual, { desc = "Multicursor append per line" })
    set({ "n", "x" }, "<leader>m", mc.operator, { desc = "Multicursor operator" })

    set("n", "<leader>gv", mc.restoreCursors, { desc = "Multicursor restore" })
    set("n", "<leader>a", mc.alignCursors, { desc = "Multicursor align" })

    mc.addKeymapLayer(function(layerSet)
      layerSet({ "n", "x" }, "<left>", mc.prevCursor)
      layerSet({ "n", "x" }, "<right>", mc.nextCursor)
      layerSet({ "n", "x" }, "<leader>x", mc.deleteCursor)
      layerSet("n", "<esc>", function()
        if not mc.cursorsEnabled() then mc.enableCursors() else mc.clearCursors() end
      end)
    end)

    local hl = vim.api.nvim_set_hl
    hl(0, "MultiCursorCursor", { reverse = true })
    hl(0, "MultiCursorVisual", { link = "Visual" })
  end,
}
