-- mini.surround with default `s`-prefixed mappings.
-- Overrides the LazyVim extra's `gs` prefix so `saiw"`, `sd`, `sr` work,
-- coexisting with flash search (flash fires only on pause after `s`).
return {
  {
    "nvim-mini/mini.surround",
    opts = {
      mappings = {
        add = "sa",
        delete = "sd",
        find = "sf",
        find_left = "sF",
        highlight = "sh",
        replace = "sr",
        update_n_lines = "sn",
      },
    },
  },
}
