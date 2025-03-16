-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return { -- vim-haml:
  'rcarriga/nvim-notify',
  config = function()
    notify = require 'notify'
    notify.setup {
      render = 'wrapped-compact',
      stages = 'fade',
      top_down = false,
    }
    vim.notify = notify
  end,
}

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
