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

    local devicons = require 'nvim-web-devicons'
    local colors = require 'onedark.colors'
    vim.api.nvim_set_hl(0, 'MiniStatuslinePathSeparator', {
      fg = colors.fg,
      bold = true,
    })

    -- Set filename highlight based on active/inactive
    vim.api.nvim_set_hl(0, 'WinbarFilenameActive', { fg = colors.yellow, bg = 'NONE', bold = true })
    vim.api.nvim_set_hl(0, 'WinbarFilenameInactive', { fg = colors.comment, bg = 'NONE', italic = true })

    -- Regular color for devinfo
    vim.api.nvim_set_hl(0, 'MiniStatuslineDevinfo', { fg = colors.white, bg = 'NONE' })

    -- Modified color for devinfo
    vim.api.nvim_set_hl(0, 'MiniStatuslineDevinfoModified', { fg = colors.red, bg = 'NONE', bold = true })

    -- Modified color for devinfo in git
    vim.api.nvim_set_hl(0, 'MiniStatuslineDevinfoModifiedGit', { fg = colors.orange, bg = 'NONE', bold = true })

    local function smart_colored_path(max_pct_width, sep_icon, filename_color)
      local filepath = vim.fn.expand '%'
      if filepath == '' then
        return ''
      end

      local relpath = vim.fn.fnamemodify(filepath, ':.')
      local parts = vim.split(relpath, '/')
      local sep = sep_icon
      local sep_color = '%#MiniStatuslinePathSeparator#'

      -- Apply highlight to separator
      local colored_sep = sep_color .. sep .. filename_color

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
      local folder = parts[#parts - 1] or ''
      local last = parts[#parts]
      return first .. colored_sep .. '…' .. colored_sep .. folder .. colored_sep .. last
    end

    -- Helper function to update winbar based on window activity
    local function set_winbar(is_active)
      local buftype = vim.bo.buftype
      local filetype = vim.bo.filetype

      if buftype ~= '' or vim.tbl_contains({ 'NvimTree', 'TelescopePrompt', 'neo-tree', 'Outline' }, filetype) then
        vim.wo.winbar = ''
        return
      end

      local hl_group = 'WinbarDevIcon'
      local filename_color = is_active and '%#WinbarFilenameActive#' or '%#WinbarFilenameInactive#'

      local filename = smart_colored_path(1, ' ', filename_color)
      local extension = vim.fn.expand '%:e'
      local icon, icon_color = devicons.get_icon_color(filename, extension, { default = true })

      -- Set icon color
      vim.api.nvim_set_hl(0, hl_group, { fg = icon_color, bg = 'NONE' })

      vim.wo.winbar = string.format('%%#%s#%s %s%s', hl_group, icon, filename_color, filename)
    end

    -- Autocommands to handle window focus
    vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWinEnter', 'WinEnter' }, {
      callback = function()
        set_winbar(true)
      end,
    })

    vim.api.nvim_create_autocmd({ 'WinLeave' }, {
      callback = function()
        set_winbar(false)
      end,
    })

    local function status_filename(hl)
      if vim.bo.buftype == 'terminal' then
        return '%t'
      end

      local filepath = vim.fn.expand '%'
      if filepath == '' then
        return ''
      end

      local filename = smart_colored_path(0.8, ' ', hl)
      local extension = vim.fn.expand '%:e'
      local icon, icon_hl = devicons.get_icon(filepath, extension, { default = true })

      -- return '%#' .. icon_hl .. '#' .. icon .. ' ' .. '%#MiniStatuslineFilename#' .. filename
      return '%#' .. icon_hl .. '#' .. icon .. ' ' .. hl .. filename
    end

    -- Simple and easy statusline.
    --  You could remove this setup call if you don't like it,
    --  and try some other statusline plugin
    local statusline = require 'mini.statusline'
    -- set use_icons to true if you have a Nerd Font
    statusline.setup {
      use_icons = true,
      set_vim_settings = true,
      content = {
        inactive = function()
          -- Return a string for the inactive window's statusline
          return status_filename '%#MiniStatuslineInactive#'
        end,
        active = function()
          local mode, mode_hl = MiniStatusline.section_mode { trunc_width = 120 }
          local git = MiniStatusline.section_git { trunc_width = 40 }
          local diff = MiniStatusline.section_diff { trunc_width = 75 }
          local diagnostics = MiniStatusline.section_diagnostics { trunc_width = 75 }
          local lsp = MiniStatusline.section_lsp { trunc_width = 75 }
          local fileinfo = MiniStatusline.section_fileinfo { trunc_width = 120 }
          local location = MiniStatusline.section_location { trunc_width = 75 }
          local search = MiniStatusline.section_searchcount { trunc_width = 75 }

          -- Pick devinfo highlight group based on modified status
          local devinfo_hl = vim.bo.modified and 'MiniStatuslineDevinfoModified' or 'MiniStatuslineDevinfo'
          local summary = vim.b.minigit_summary_string or vim.b.gitsigns_head

          if summary and summary:find '%( M%)' and not vim.bo.modified then
            devinfo_hl = 'MiniStatuslineDevinfoModifiedGit'
          end

          -- Usage of `MiniStatusline.combine_groups()` ensures highlighting and
          -- correct padding with spaces between groups (accounts for 'missing'
          -- sections, etc.)
          return MiniStatusline.combine_groups {
            { hl = mode_hl, strings = { mode } },
            { hl = devinfo_hl, strings = { git, diff, diagnostics, lsp } },
            '%<', -- Mark general truncate point
            '%=', -- End left alignment
            { hl = 'MiniStatuslineFileinfo', strings = { fileinfo } },
            { hl = mode_hl, strings = { search, location } },
          }
        end,
      },
    }

    -- You can configure sections in the statusline by overriding their
    -- default behavior. For example, here we set the section for
    -- cursor location to LINE:COLUMN
    ---@diagnostic disable-next-line: duplicate-set-field
    statusline.section_location = function()
      return '%2l:%-2v'
    end

    -- vim.api.nvim_set_hl(0, 'MiniStatuslineFilename', { fg = '#ffcc00', bg = '#303030', bold = true })
    -- ... and there is more!
    --  Check out: https://github.com/echasnovski/mini.nvim
  end,
}

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
