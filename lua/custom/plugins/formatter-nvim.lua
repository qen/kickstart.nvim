-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  'mhartington/formatter.nvim',
  enabled = false,
  config = function()
    -- local util = require 'formatter.util'

    require('formatter').setup {
      logging = true,
      log_level = vim.log.levels.WARN,

      filetype = {
        lua = {
          require('formatter.filetypes.lua').stylua,
        },
        ruby = {
          require('formatter.filetypes.ruby').rubocop,
        },
        ['*'] = {
          require('formatter.filetypes.any').remove_trailing_whitespace,
        },
      },
    }

    vim.api.nvim_create_autocmd('BufWritePost', {
      desc = 'Auto format on save',
      group = vim.api.nvim_create_augroup('_local_auto_format', { clear = true }),
      pattern = '*',
      command = ':FormatWrite',
    })
  end,
}

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
