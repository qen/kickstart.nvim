-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return { -- vim-rspec
  'thoughtbot/vim-rspec',
  dependencies = {
    'tpope/vim-dispatch',
  },
  config = function()
    -- vim.g.rspec_command = 'Dispatch! bundle exec rspec -I . {spec}'
    vim.g.rspec_command = 'Dispatch! bundle exec rspec -I . {spec}'
    vim.g.rspec_runner = 'os_x_iterm2'
    vim.g.dispatch_tmux_height = '50%'
    vim.g.dispatch_quickfix_height = 15

    -- local rspec = require 'vim-rspec'

    vim.keymap.set('n', '\\tt', function()
      -- vim.cmd.execute [[":w\<CR>"]]
      vim.fn.RunNearestSpec()
      -- vim.cmd 'Copen'
      -- vim.cmd.execute [["normal \<s-G>zb<CR>"]]
    end, { desc = 'run neares[T] spec' })

    vim.keymap.set('n', '\\tl', function()
      -- vim.cmd.execute [[":w\<CR>"]]
      vim.fn.RunLastSpec()
      -- vim.cmd 'Copen'
      -- vim.cmd.execute [["normal \<s-G>zb<CR>"]]
    end, { desc = 'run [L]ast spec' })

    vim.keymap.set('n', '\\d', function()
      vim.cmd.execute [["normal \<s-O>binding.pry\<ESC>:w\<CR>"]]
    end, { desc = 'Insert [D]ebug `binding.pry`' })

    vim.keymap.set('n', '\\mm', function()
      vim.cmd 'Start specg dbmigrate'
    end, { desc = 'run spec db:migrate' })

    vim.keymap.set('n', '\\ml', function()
      vim.cmd 'Start specg dbload'
    end, { desc = 'run spec db:schema:load' })
  end,
}

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
