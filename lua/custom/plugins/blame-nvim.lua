-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return { -- vim-fugitive
  'FabijanZulj/blame.nvim',
  lazy = false,
  opts = {
    blame_options = { '-w' },
  },
  config = function()
    local function open_commit_in_browser()
      -- Get current file and cursor line
      local filepath = vim.api.nvim_buf_get_name(0)
      local linenr = vim.api.nvim_win_get_cursor(0)[1]

      if filepath == '' then
        vim.notify('No file open', vim.log.levels.WARN)
        return
      end

      -- Run git blame
      local blame_cmd = string.format('git blame -L %d,+1 --porcelain %q', linenr, filepath)
      local handle = io.popen(blame_cmd)
      if not handle then
        vim.notify('Failed to run git blame', vim.log.levels.ERROR)
        return
      end

      local output = handle:read '*a'
      handle:close()

      if not output or output == '' then
        vim.notify('No blame info found', vim.log.levels.WARN)
        return
      end

      -- Extract commit SHA
      local commit_sha = output:match '^(%w+)'
      if not commit_sha or commit_sha == '0000000000000000000000000000000000000000' then
        vim.notify('Line not committed yet', vim.log.levels.INFO)
        return
      end

      -- Get remote origin URL
      local remote_handle = io.popen 'git config --get remote.origin.url'
      if not remote_handle then
        vim.notify('Failed to get git remote URL', vim.log.levels.ERROR)
        return
      end

      local remote_url = remote_handle:read '*a'
      remote_handle:close()

      if not remote_url or remote_url == '' then
        vim.notify('Git remote origin URL not found', vim.log.levels.WARN)
        return
      end

      remote_url = remote_url:gsub('\n', '')

      -- Normalize GitHub URL
      local repo_url = remote_url:gsub('git@github.com:', 'https://github.com/'):gsub('%.git$', '')

      -- Compose commit URL
      local commit_url = string.format('%s/commit/%s', repo_url, commit_sha)

      -- Open in browser (use 'open' for macOS, 'xdg-open' for Linux, 'start ""' for Windows)
      print('Opening:', commit_url)
      os.execute(string.format("open '%s' &", commit_url))
    end

    -- Set up keymap
    vim.keymap.set('n', '\\go', open_commit_in_browser, { desc = '[O]pen commit in browser' })

    require('blame').setup()
    vim.api.nvim_set_keymap('n', '\\gh', ':BlameToggle<CR>', { desc = 'Explore commit [H]istory', noremap = true, silent = true })
    vim.api.nvim_set_keymap('n', '\\gv', ':BlameToggle virtual<CR>', { desc = '[V]irtual Blame', noremap = true, silent = true })

    vim.keymap.set('n', '<BS>1', ':diffget 1<CR>', { desc = 'diff get 1' })
    vim.keymap.set('n', '<BS>2', ':diffget 2<CR>', { desc = 'diff get 2' })
    vim.keymap.set('n', '<BS>3', ':diffget 3<CR>', { desc = 'diff get 3' })
    vim.keymap.set('n', '<BS>R', ':%diffget REMOTE<CR>', { desc = 'diff get all remote, the branch merging' })
    vim.keymap.set('n', '<BS>L', ':%diffget LOCAL<CR>', { desc = 'diff get all local, current checkout branch' })
  end,
}

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
