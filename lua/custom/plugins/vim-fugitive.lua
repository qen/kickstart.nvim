-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return { -- vim-fugitive
  'tpope/vim-fugitive',
  dependencies = {
    'tpope/vim-rhubarb',
    {
      'FabijanZulj/blame.nvim',
      lazy = false,
      config = function()
        require('blame').setup {}
        vim.api.nvim_set_keymap('n', '\\gh', ':BlameToggle<CR>', { desc = 'Explore commit [H]istory', noremap = true, silent = true })
        vim.api.nvim_set_keymap('n', '\\gt', ':BlameToggle virtual<CR>', { desc = '[T]oggle virtual [B]lame', noremap = true, silent = true })
      end,
      opts = {
        blame_options = { '-w' },
      },
    },
  },
  config = function()
    vim.keymap.set('n', '\\go', function()
      vim.cmd 'Git blame'
      vim.cmd.execute [["normal o"]]
      vim.cmd 'GB'
      vim.cmd.execute [["normal \<C-W>q"]]
      vim.cmd.execute [["normal \<C-W>q"]]
    end, { desc = '[O]pen commit in browser' })

    vim.keymap.set('n', '<BS>1', ':diffget 1<CR>', { desc = 'diff get 1' })
    vim.keymap.set('n', '<BS>2', ':diffget 2<CR>', { desc = 'diff get 2' })
    vim.keymap.set('n', '<BS>3', ':diffget 3<CR>', { desc = 'diff get 3' })
    vim.keymap.set('n', '<BS>R', ':%diffget REMOTE<CR>', { desc = 'diff get all remote, the branch merging' })
    vim.keymap.set('n', '<BS>L', ':%diffget LOCAL<CR>', { desc = 'diff get all local, current checkout branch' })
  end,
}

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
