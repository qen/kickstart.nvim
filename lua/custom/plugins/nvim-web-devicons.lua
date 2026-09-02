-- Was a telescope dependency; still used by the mini.statusline winbar and snacks.
return {
  'nvim-tree/nvim-web-devicons',
  enabled = vim.g.have_nerd_font,
  lazy = false,
  opts = {
    color_icons = true,
    default = true,
    strict = true,
    variant = 'dark',
  },
}
