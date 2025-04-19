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
    vim.api.nvim_set_hl(0, 'MiniStatusFilenameInactive', { fg = colors.comment, bg = 'NONE', italic = true })

    vim.api.nvim_set_hl(0, 'MiniStatuslineFilename', { fg = colors.yellow, bg = 'NONE', bold = true })

    vim.api.nvim_set_hl(0, 'MiniStatuslineFilenameModified', { fg = colors.red, bg = 'NONE', bold = true })

    vim.api.nvim_set_hl(0, 'WinbarGitClean', { fg = colors.yellow, bg = 'NONE', bold = true })

    vim.api.nvim_set_hl(0, 'WinbarGitDirty', { fg = colors.dark_red, bg = 'NONE', bold = true })

    local function smart_colored_path(max_pct_width, sep_icon, filename_color)
      local filepath = vim.fn.expand '%'
      if filepath == '' then
        return ''
      end

      local relpath = vim.fn.fnamemodify(filepath, ':.')
      local parts = vim.split(relpath, '/')
      local sep = sep_icon
      local sep_color = '%#MiniStatuslinePathSeparator#'
      local colored_sep = sep_color .. sep .. '%#' .. filename_color .. '#'

      -- Apply filename_color to the first part explicitly
      parts[1] = '%#' .. filename_color .. '#' .. parts[1]

      local win_width = vim.api.nvim_win_get_width(0)
      local full_path = table.concat(parts, colored_sep)
      local max_len = math.floor(win_width * (max_pct_width or 0.4))

      if #full_path <= max_len or #parts <= 2 then
        return full_path
      end

      local first = parts[1]
      local folder = parts[#parts - 1] or ''
      local last = parts[#parts]

      return first .. colored_sep .. '…' .. colored_sep .. folder .. colored_sep .. last
    end

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

      return '%#' .. icon_hl .. '#' .. icon .. ' %#' .. hl .. '#' .. filename
    end

    local function get_git_dirty_state()
      local summary = vim.b.minigit_summary_string or ''
      if summary:find '%( M%)' or summary:find '%(A%)' or summary:find '%(D%)' then
        return true
      end
      return false
    end

    local function status_git_branch(hl)
      local git = MiniStatusline.section_git { trunc_width = 40 } or ''
      local diff = MiniStatusline.section_diff { trunc_width = 75 } or ''
      local diagnostics = MiniStatusline.section_diagnostics { trunc_width = 75 } or ''
      local lsp = MiniStatusline.section_lsp { trunc_width = 75 } or ''

      -- -- Determine highlight based on git + buffer status
      -- local is_dirty = get_git_dirty_state()
      -- local hl_group = is_dirty and 'WinbarGitDirty' or 'WinbarGitClean'
      -- if not is_active then
      --   hl_group = hl_group .. 'Inactive'
      -- end

      return string.format(
        '%%#%s#%s',
        hl,
        table.concat {
          ' ' .. git,
          diff ~= '' and (' ' .. diff) or '',
          diagnostics ~= '' and (' ' .. diagnostics) or '',
          lsp ~= '' and (' LSP:' .. lsp) or '',
        }
      )
    end

    local function build_winbar(is_active)
      if vim.bo.buftype ~= '' then
        vim.wo.winbar = ''
        return
      end

      -- -- Determine highlight based on git + buffer status
      -- local is_dirty = get_git_dirty_state()
      -- local hl_group = is_dirty and 'WinbarGitDirty' or 'WinbarGitClean'
      -- if not is_active then
      --   hl_group = hl_group .. 'Inactive'
      -- end
      -- vim.wo.winbar = status_git_branch(hl_group)

      local filename_color
      if vim.bo.modified then
        filename_color = 'MiniStatuslineFilenameModified'
      else
        filename_color = 'MiniStatuslineFilename'
      end
      vim.wo.winbar = status_filename(filename_color)
    end

    -- Autocommands to handle window focus
    vim.api.nvim_create_autocmd({ 'WinEnter', 'VimEnter' }, {
      callback = function()
        vim.defer_fn(function()
          local is_active = vim.api.nvim_get_current_win() == tonumber(vim.fn.win_getid())
          build_winbar(is_active)
        end, 200) -- wait 100ms
      end,
    })

    vim.api.nvim_create_autocmd({ 'WinLeave', 'BufEnter', 'BufWinEnter', 'BufModifiedSet', 'TextChanged', 'BufWritePost' }, {
      callback = function()
        local is_active = vim.api.nvim_get_current_win() == tonumber(vim.fn.win_getid())
        build_winbar(is_active)
      end,
    })

    vim.api.nvim_create_autocmd('User', {
      pattern = { 'MiniGitUpdate', 'GitIndexChanged' },
      callback = function()
        local is_active = vim.api.nvim_get_current_win() == tonumber(vim.fn.win_getid())
        build_winbar(is_active)
      end,
    })

    vim.api.nvim_create_autocmd('DiagnosticChanged', {
      callback = function()
        local is_active = vim.api.nvim_get_current_win() == tonumber(vim.fn.win_getid())
        build_winbar(is_active)
      end,
    })

    vim.api.nvim_create_autocmd('BufModifiedSet', {
      callback = function()
        build_winbar(vim.fn.win_getid() == vim.fn.win_getid(vim.api.nvim_get_current_win()))
      end,
    })

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
          local is_dirty = get_git_dirty_state()
          local hl_group = is_dirty and 'WinbarGitDirty' or 'WinbarGitClean'
          return status_git_branch(hl_group)

          -- Return a string for the inactive window's statusline
          -- return status_filename '%#MiniStatusFilenameInactive#'
        end,
        active = function()
          local mode, mode_hl = MiniStatusline.section_mode { trunc_width = 120 }
          -- local filename = MiniStatusline.section_filename { trunc_width = 140 }
          local fileinfo = MiniStatusline.section_fileinfo { trunc_width = 120 }
          local location = MiniStatusline.section_location { trunc_width = 75 }
          local search = MiniStatusline.section_searchcount { trunc_width = 75 }

          -- local filename_color
          -- if vim.bo.modified then
          --   filename_color = '%#MiniStatuslineFilenameModified#'
          -- else
          --   filename_color = '%#MiniStatuslineFilename#'
          -- end
          -- local filename = status_filename(filename_color)

          -- Determine highlight based on git + buffer status
          local is_dirty = get_git_dirty_state()
          local hl_group = is_dirty and 'WinbarGitDirty' or 'WinbarGitClean'

          if vim.bo.modified then
            hl_group = 'MiniStatuslineFilenameModified'
          end

          -- Usage of `MiniStatusline.combine_groups()` ensures highlighting and
          -- correct padding with spaces between groups (accounts for 'missing'
          -- sections, etc.)
          return MiniStatusline.combine_groups {
            { hl = mode_hl, strings = { mode } },
            '%<', -- Mark general truncate point
            status_git_branch(hl_group),
            -- { hl = 'MiniStatuslineFilename', strings = { filename } },
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
