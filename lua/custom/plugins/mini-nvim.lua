-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information

return { -- mini-nvim: Collection of various small independent plugins/modules
  'echasnovski/mini.nvim',
  config = function()
    -- Better Around/Inside textobjects
    --
    -- Examples:
    --  - va)  - [V]isually select [A]round [)]paren
    --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
    --  - ci'  - [C]hange [I]nside [']quote
    require('mini.ai').setup { n_lines = 500 }

    -- Add/delete/replace surroundings (brackets, quotes, etc.)
    --
    -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
    -- - sd'   - [S]urround [D]elete [']quotes
    -- - sr)'  - [S]urround [R]eplace [)] [']
    require('mini.surround').setup()

    require('mini.jump').setup()
    require('mini.icons').setup {
      -- brew install font-hack-nerd-font
      -- setup iterm2 Profile font
      style = 'glyph',
    }
    require('mini.git').setup()
    require('mini.diff').setup()
    -- require('mini.tabline').setup()

    -- Simple and easy statusline.
    --  You could remove this setup call if you don't like it,
    --  and try some other statusline plugin
    local statusline = require 'mini.statusline'
    local devicons = require 'nvim-web-devicons'
    -- set use_icons to true if you have a Nerd Font
    statusline.setup {
      use_icons = true,
      set_vim_settings = true,
    }

    -- You can configure sections in the statusline by overriding their
    -- default behavior. For example, here we set the section for
    -- cursor location to LINE:COLUMN
    ---@diagnostic disable-next-line: duplicate-set-field
    statusline.section_location = function()
      return '%2l:%-2v'
    end

    local colors = require 'onedark.colors'
    vim.api.nvim_set_hl(0, 'MiniStatuslinePathSeparator', {
      fg = colors.fg,
      bold = true,
    })

    local function smart_colored_path(max_pct_width, sep_icon)
      local filepath = vim.fn.expand '%'
      if filepath == '' then
        return ''
      end

      local relpath = vim.fn.fnamemodify(filepath, ':.')
      local parts = vim.split(relpath, '/')
      local sep = sep_icon or ''
      local sep_color = '%#MiniStatuslinePathSeparator#'

      -- Apply highlight to separator
      local colored_sep = sep_color .. sep .. '%#MiniStatuslineFilename#'

      local win_width = vim.api.nvim_win_get_width(0)
      local full_path = table.concat(parts, colored_sep)
      local max_len = math.floor(win_width * (max_pct_width or 0.4))

      if #full_path <= max_len then
        return full_path
      end

      if #parts <= 2 then
        return full_path
      end

      local first = parts[1]
      local last = parts[#parts]
      return first .. colored_sep .. '…' .. colored_sep .. last
    end

    ---@diagnostic disable-next-line: duplicate-set-field
    statusline.section_filename = function()
      if vim.bo.buftype == 'terminal' then
        return '%t'
      end

      local filepath = vim.fn.expand '%'
      if filepath == '' then
        return ''
      end

      local filename = smart_colored_path(0.8, ' ')
      local extension = vim.fn.expand '%:e'
      local icon, icon_hl = devicons.get_icon(filepath, extension, { default = true })

      return '%#' .. icon_hl .. '#' .. icon .. ' ' .. '%#MiniStatuslineFilename#' .. filename
    end
    -- vim.api.nvim_set_hl(0, 'MiniStatuslineFilename', { fg = '#ffcc00', bg = '#303030', bold = true })
    -- ... and there is more!
    --  Check out: https://github.com/echasnovski/mini.nvim
  end,
}

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
