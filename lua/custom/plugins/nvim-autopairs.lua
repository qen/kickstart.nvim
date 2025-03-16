-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return { -- nvim-autopairs
  'windwp/nvim-autopairs',
  event = 'InsertEnter',
  -- Optional dependency
  dependencies = { 'hrsh7th/nvim-cmp' },
  config = function()
    -- If you want to automatically add `(` after selecting a function or method
    local cmp_autopairs = require 'nvim-autopairs.completion.cmp'
    local cmp = require 'cmp'
    cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())

    local npairs = require 'nvim-autopairs'
    npairs.setup { map_cr = true }

    -- npairs.add_rules(require('nvim-autopairs.rules.endwise-elixir'))
    npairs.add_rules(require 'nvim-autopairs.rules.endwise-lua')
    npairs.add_rules(require 'nvim-autopairs.rules.endwise-ruby')
  end,
}

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
