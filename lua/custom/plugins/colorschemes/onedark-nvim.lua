-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information

-- { -- You can easily change to a different colorscheme.
--   -- Change the name of the colorscheme plugin below, and then
--   -- change the command in the config to whatever the name of that colorscheme is.
--   --
--   -- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`.
--   'folke/tokyonight.nvim',
--   priority = 1000, -- Make sure to load this before all the other start plugins.
--   init = function()
--     -- Load the colorscheme here.
--     -- Like many other themes, this one has different styles, and you could load
--     -- any other, such as 'tokyonight-storm', 'tokyonight-moon', or 'tokyonight-day'.
--     vim.cmd.colorscheme 'tokyonight-moon'
--
--     -- You can configure highlights by doing something like:
--     -- vim.cmd.hi 'Comment gui=none'
--   end,
-- },

-- {
--   'pwntester/octo.nvim',
--   dependencies = {
--     'nvim-lua/plenary.nvim',
--     'nvim-telescope/telescope.nvim',
--     'ibhagwan/fzf-lua',
--     'folke/snacks.nvim',
--     'nvim-tree/nvim-web-devicons',
--   },
--   config = function()
--     require('octo').setup()
--   end,
-- },
-- {
--   'ldelossa/gh.nvim',
--   dependencies = {
--     {
--       'ldelossa/litee.nvim',
--       config = function()
--         require('litee.lib').setup()
--       end,
--     },
--   },
--   config = function()
--     require('litee.gh').setup()
--   end,
-- },

-- {
--   'ribru17/bamboo.nvim',
--   lazy = false,
--   priority = 1000,
--   config = function()
--     require('bamboo').setup {
--       -- optional configuration here
--     }
--     require('bamboo').load()
--     vim.cmd.colorscheme 'bamboo'
--   end,
-- },
-- { -- kanagawa-paper.nvim
--   'thesimonho/kanagawa-paper.nvim',
--   lazy = false,
--   priority = 1000,
--   config = function()
--     require('kanagawa-paper').setup {
--       undercurl = true,
--       transparent = false,
--       gutter = false,
--       dimInactive = true, -- disabled when transparent
--       terminalColors = true,
--       commentStyle = { italic = true },
--       functionStyle = { italic = false },
--       keywordStyle = { italic = false, bold = false },
--       statementStyle = { italic = false, bold = false },
--       typeStyle = { italic = false },
--       colors = { theme = {}, palette = {} }, -- override default palette and theme colors
--       overrides = function() -- override highlight groups
--         return {}
--       end,
--     }
--     vim.cmd.colorscheme 'kanagawa-paper'
--   end,
-- },
-- { -- melange-nvim colorsche
--   'savq/melange-nvim',
--   config = function()
--     vim.opt.termguicolors = true
--     vim.cmd.colorscheme 'melange'
--   end,
-- },
-- { -- gruvbox-material
--   'sainnhe/gruvbox-material',
--   lazy = false,
--   priority = 1000,
--   config = function()
--     -- Optionally configure and load the colorscheme
--     -- directly inside the plugin declaration.
--     vim.g.gruvbox_material_enable_italic = false
--     vim.g.gruvbox_material_background = 'soft'
--     vim.cmd.colorscheme 'gruvbox-material'
--   end,
-- },
-- { -- makurai color theme
--   'Skardyy/makurai-nvim',
--   config = function()
--     vim.cmd.colorscheme 'makurai'
--   end,
-- },
-- { -- tairiki.nvim
--   'deparr/tairiki.nvim',
--   lazy = false,
--   priority = 1000, -- only necessary if you use tairiki as default theme
--   config = function()
--     require('tairiki').setup {
--       -- optional configuration here
--       style = 'light',
--     }
--     require('tairiki').load() -- only necessary to use as default theme, has same behavior as ':colorscheme tairiki'
--   end,
-- },

return { -- theme onedark
  'navarasu/onedark.nvim',
  priority = 1000,
  config = function()
    local colors = require 'onedark.palette'
    require('onedark').setup {
      -- Main options --
      style = 'warmer', -- Default theme style. Choose between 'dark', 'darker', 'cool', 'deep', 'warm', 'warmer' and 'light'
      -- transparent = true, -- Show/hide background
      -- term_colors = true, -- Change terminal color as per the selected theme style
      -- ending_tildes = false, -- Show the end-of-buffer tildes. By default they are hidden
      -- cmp_itemkind_reverse = false, -- reverse item kind highlights in cmp menu
      --
      -- -- toggle theme style ---
      -- toggle_style_key = nil, -- keybind to toggle theme style. Leave it nil to disable it, or set it to a string, for example "<leader>ts"
      -- toggle_style_list = { 'dark', 'darker', 'cool', 'deep', 'warm', 'warmer', 'light' }, -- List of styles to toggle between
      --
      -- -- Change code style ---
      -- -- Options are italic, bold, underline, none
      -- -- You can configure multiple style with comma separated, For e.g., keywords = 'italic,bold'
      code_style = {
        comments = 'none',
        -- keywords = 'none',
        -- functions = 'none',
        -- strings = 'none',
        -- variables = 'none',
      },
      --
      -- -- Lualine options --
      -- lualine = {
      --   transparent = false, -- lualine center bar transparency
      -- },
      --
      -- -- Custom Highlights --
      -- colors = {}, -- Override default colors
      highlights = { -- Override highlight groups
        Folded = {
          fg = colors.dark.grey,
          bg = 'none',
        },
        MiniStatuslineFilename = { fg = '$yellow', bg = '$bg1', fmt = 'bold' },
        -- Comment = { italic = false },
        -- ["@comment.ruby"] = { italic = false },
        -- Comment = { fg = "#ff0000", italic = false },
        -- ["@comment"] = { fg = "#ff0000", italic = false },
        ["@comment.ruby"] = { fg = colors.dark.grey, italic = false },
      },
      --
      -- -- Plugins Config --
      -- diagnostics = {
      --   -- darker = true, -- darker colors for diagnostic
      --   -- undercurl = true, -- use undercurl instead of underline for diagnostics
      --   -- background = true, -- use background color for virtual text
      -- },
    }
    require('onedark').load()
  end,
}

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
