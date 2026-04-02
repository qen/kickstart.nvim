local doc_dirs = {
  {
    name = ".gist",
    key = "<leader>smg",
    title = "Find Gist Files",
    prefix = " gist/",
    desc = "Search files in gist folder",
  },
  {
    name = "doc",
    key = "<leader>smd",
    title = "Find Doc Files",
    prefix = " doc/",
    desc = "Search files in doc folder",
  },
}

local function dir_exists(path)
  local stat = vim.loop.fs_stat(path)
  return stat and stat.type == "directory"
end

return {
  'nvim-telescope/telescope.nvim',
  event = 'VimEnter',
  branch = '0.1.x',
  dependencies = {
    { 'nvim-lua/plenary.nvim' },
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = 'make',
      cond = function()
        return vim.fn.executable 'make' == 1
      end,
    },
    { 'nvim-telescope/telescope-ui-select.nvim' },
    {
      'nvim-tree/nvim-web-devicons',
      enabled = vim.g.have_nerd_font,
      config = function()
        require('nvim-web-devicons').setup {
          color_icons = true,
          default = true,
          strict = true,
          variant = 'dark',
        }
      end,
    },
    {
      'axkirillov/easypick.nvim',
      config = function()
        local easypick = require 'easypick'
        local base_branch = 'master'

        easypick.setup {
          pickers = {
            {
              name = 'ls',
              command = 'ls',
              previewer = easypick.previewers.default(),
            },
            {
              name = 'changed_files',
              command = 'git diff --name-only $(git merge-base HEAD ' .. base_branch .. ' )',
              previewer = easypick.previewers.branch_diff { base_branch = base_branch },
              theme = 'ivy',
            },
            {
              name = 'conflicts',
              command = 'git diff --name-only --diff-filter=U --relative',
              previewer = easypick.previewers.file_diff(),
            },
          },
        }
      end,
    },
    { 'nvim-telescope/telescope-file-browser.nvim' },
    {
      'kelly-lin/telescope-ag',
      dependencies = { 'nvim-telescope/telescope.nvim' },
      config = function()
        local telescope_ag = require 'telescope-ag'
        telescope_ag.setup {
          cmd = telescope_ag.cmds.rg,
        }
      end,
    },
  },
  config = function()
    local find_files_mod = require('custom.telescope-find-files')
    local get_visual_selection = find_files_mod.get_visual_selection
    local file_name_suffixes = find_files_mod.file_name_suffixes
    local make_context_sorter = find_files_mod.make_context_sorter
    local find_files_with_context = find_files_mod.find_files_with_context

    local action_state = require('telescope.actions.state')
    local actions = require('telescope.actions')
    local builtin = require('telescope.builtin')
    local which_key = require('which-key')

    local function similar_document_name()
      local filename = vim.fn.expand('%:t:r')
      for _, suffix in ipairs(file_name_suffixes) do
        filename = filename:gsub(suffix, '')
      end
      return filename
    end

    -- Helper: get directory from file browser prompt
    local function prompt_dir(prompt_bufnr)
      local current_picker = action_state.get_current_picker(prompt_bufnr)
      local finder = current_picker.finder
      return vim.fn.fnamemodify(finder.path, ':~:.')
    end

    local function prompt_cursor_dir()
      local entrydir
      local entry = action_state.get_selected_entry()
      if entry then
        local path = entry.filename or entry.path or entry[1]
        if path then
          entrydir = vim.fn.fnamemodify(path, ':h')
        end
      end
      -- find_files_with_context(dir)
      -- print(entrydir)
      -- print(vim.inspect(action_state.get_selected_entry().filename))
      return entrydir
    end

    local function ripgrep_current_folder(prompt_bufnr)
      local dir = prompt_dir(prompt_bufnr)
      actions.close(prompt_bufnr)
      builtin.live_grep {
        prompt_prefix = '󰺮 > ',
        prompt_title = 'Live Grep in ' .. dir,
        search_dirs = { dir },
      }
    end

    -- Highlight groups for custom telescope displays
    vim.api.nvim_set_hl(0, 'TelescopeCurrentDir', { fg = '#7aa2cc' })
    vim.api.nvim_set_hl(0, 'TelescopeSuffixMatch', { fg = '#c0976b' })
    vim.api.nvim_set_hl(0, 'TelescopeQueryBold', { fg = '#c0976b', bold = true })

    local function find_files_current_folder(prompt_bufnr)
      local dir = prompt_dir(prompt_bufnr)
      actions.close(prompt_bufnr)
      find_files_with_context(dir)
    end

    local cursor_dir_mappings = {
      ['i'] = {
        ['<C-Space>'] = function(prompt_bufnr)
          actions.close(prompt_bufnr)
          find_files_with_context(prompt_cursor_dir())
        end,
        ['<C-f>'] = function(prompt_bufnr)
          actions.close(prompt_bufnr)
          find_files_with_context(nil, nil, nil, prompt_cursor_dir())
        end,
        ['<C-d>'] = function(prompt_bufnr)
          actions.close(prompt_bufnr)
          require('telescope').extensions.file_browser.file_browser {
            path = prompt_cursor_dir(),
            select_buffer = true,
            prompt_path = true,
          }
        end
      }
    }

    -- NOTE: [[ Configure Telescope ]]
    require('telescope').setup {
      defaults = {
        file_sorter = require('telescope.sorters').get_fzy_sorter(),
        vimgrep_arguments = {
          'rg',
          '--color=never',
          '--no-heading',
          '--with-filename',
          '--line-number',
          '--column',
          '--smart-case',
          '--trim',
        },
      },
      pickers = {
        find_files = {
          -- mappings = {
          --   n = { ['<C-g>'] = find_files_parent_dir },
          --   i = {
          --     ['<C-g>'] = find_files_parent_dir,
          --     ['<C-Space>'] = find_files_current_folder,
          --   },
          -- },
        },
        buffers = { mappings = cursor_dir_mappings },
        oldfiles = {
          file_sorter = require('telescope.sorters').fuzzy_with_index_bias,
          mappings = cursor_dir_mappings,
        },
        live_grep = {
          mappings = {
            i = {
              ['<C-g>'] = function(prompt_bufnr)
                local current_query = action_state.get_current_line()
                local picker = action_state.get_current_picker(prompt_bufnr)
                local title = picker.prompt_title or ''
                local dir = title:match('^Live Grep in (.+)$') or vim.fn.fnamemodify(vim.fn.expand '%', ':.:h')
                actions.close(prompt_bufnr)
                local parent = vim.fn.fnamemodify(dir, ':h')
                if parent == dir or parent == '.' then return end
                builtin.live_grep {
                  search_dirs = { parent },
                  default_text = current_query,
                  prompt_title = 'Live Grep in ' .. parent,
                }
              end,
            },
          },
        },
      },
      extensions = {
        ['ui-select'] = {
          require('telescope.themes').get_dropdown(),
        },
        file_browser = {
          previewer = false,
          hijack_netrw = true,
          respect_gitignore = false,
          select_buffer = true,
          prompt_path = true,
          mappings = {
            ['i'] = {
              ['<C-r>'] = ripgrep_current_folder,
              ['<C-Space>'] = find_files_current_folder,
              ['<C-f>'] = function(prompt_bufnr)
                local dir = prompt_dir(prompt_bufnr)
                actions.close(prompt_bufnr)
                find_files_with_context(nil, nil, nil, dir)
              end
            },
            ['n'] = {
              ['<C-r>'] = ripgrep_current_folder,
              ['<C-Space>'] = find_files_current_folder,
            },
          },
        },
      },
    }

    -- Enable Telescope extensions if they are installed
    pcall(require('telescope').load_extension, 'fzf')
    pcall(require('telescope').load_extension, 'ui-select')
    pcall(require('telescope').load_extension, 'ag')
    pcall(require('telescope').load_extension, 'file_browser')

    -- Keymaps: Peek helpers
    vim.keymap.set('n', '<leader>ph', builtin.help_tags, { desc = 'Peek [H]elp' })
    vim.keymap.set('n', '<leader>pk', builtin.keymaps, { desc = 'Peek [K]eymaps' })
    vim.keymap.set('n', '<leader>pt', builtin.builtin, { desc = 'Peek Select [T]elescope' })
    vim.keymap.set('n', '<leader>pn', function()
      builtin.find_files { cwd = vim.fn.stdpath 'config' }
    end, { desc = 'Peek [N]eovim files' })
    vim.keymap.set('n', '<leader>pd', builtin.diagnostics, { desc = 'Peek [D]iagnostics' })

    -- Keymaps: File navigation
    local function show_opened_file_history()
      builtin.oldfiles {
        only_cwd = true,
        previewer = vim.o.columns >= 215,
        sorter = make_context_sorter(),
        prompt_title = 'Files opened history',
        prompt_prefix = '󱋢 > ',
      }
    end

    vim.keymap.set('n', '<TAB><TAB>', show_opened_file_history, { desc = 'Recent Files' })

    vim.keymap.set('n', '<TAB>o', function()
      builtin.buffers {
        prompt_title = 'Files opened',
        prompt_prefix = ' > ',
        previewer = vim.o.columns >= 215,
        sort_lastused = true,
        sort_mru = true,
      }
    end, { desc = 'Find Opened Files' })

    -- Keymaps: Search
    vim.keymap.set('n', '<leader>sd', function()
      require('telescope').extensions.file_browser.file_browser {
        path = '%:p:h'
      }
    end, { desc = 'Search Browse buffer [D]irectory' })

    vim.keymap.set('n', '<leader>sw', function()
      require('telescope').extensions.file_browser.file_browser()
    end, { desc = 'Search Browse <c[w]d>irectory' })

    vim.keymap.set('n', '<leader>sc', function()
      vim.cmd 'Easypick changed_files'
    end, { desc = 'Search Git [C]hanged files' })

    vim.keymap.set('n', '<leader>`', builtin.resume, { desc = 'Search again' })

    vim.keymap.set({ 'n', 'v' }, '<leader>sr', function()
      local query = ''
      if vim.api.nvim_get_mode().mode == 'v' then
        query = get_visual_selection()
      end
      builtin.live_grep {
        default_text = query,
        prompt_prefix = '󰺮 > ',
      }
    end, { desc = 'Search [R]ipgrep Word selection' })

    vim.keymap.set({ 'n', 'v' }, '<leader><leader>', find_files_with_context, { desc = 'Search [F]iles in app, packs, and current directories' })

    vim.keymap.set({ 'n', 'v' }, '<leader>sf', function()
      -- local query = vim.api.nvim_get_mode().mode == 'v' and get_visual_selection() or similar_document_name()
      local query = similar_document_name()

      find_files_with_context(nil, query, true)
    end, { desc = 'Search similar [N]ame on app folders' })

    vim.keymap.set('n', '<leader>ss', function()
      builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
        previewer = false,
        layout_config = {
          height = 0.7,
          width = 0.7,
        },
      })
    end, { desc = '[ ] Fuzzily search in current buffer' })

    vim.keymap.set('n', '<leader>s<TAB>', function()
      builtin.live_grep {
        grep_open_files = true,
        prompt_title = 'Live Grep in Open Files',
      }
    end, { desc = '[S]earch [/] in Open Files' })

    -- NOTE: Doc directory keymaps — opens files in second tab if available, else creates new tab
    local cwd = vim.fn.getcwd()
    for _, dir in ipairs(doc_dirs) do
      local full_path = cwd .. "/" .. dir.name
      if dir_exists(full_path) then
        vim.keymap.set("n", dir.key, function()
          builtin.find_files {
            cwd = cwd,
            previewer = false,
            prompt_prefix = dir.prefix,
            prompt_title = dir.title,
            search_dirs = { dir.name },
            attach_mappings = function(prompt_bufnr, map)
              actions.select_default:replace(function()
                local entry = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                local filepath = entry.path or entry.filename
                local tabs = vim.api.nvim_list_tabpages()
                if #tabs >= 2 then
                  vim.api.nvim_set_current_tabpage(tabs[2])
                  vim.cmd('edit ' .. vim.fn.fnameescape(filepath))
                else
                  vim.cmd('tabnew ' .. vim.fn.fnameescape(filepath))
                end
              end)
              return true
            end,
          }
        end, { desc = dir.desc })
      end
    end

    -- Which-Key icons
    which_key.add({
      { '<leader>p', group = '[P]eek Helper', icon = { icon = '󰸖', color = 'blue' } },
      { '<leader>pd', icon = { icon = '', color = 'red' } },
      { '<leader>pk', icon = { icon = '󰌌', color = 'blue' } },
      { '<leader>ph', icon = { icon = '', color = 'blue' } },
      { '<leader>pn', icon = { icon = '', color = 'yellow' } },
      { '<leader>pt', icon = { icon = 'w', color = 'blue' } },
      { '<TAB><TAB>', icon = { icon = '󱋢', color = 'orange' } },
      { '<TAB>o', icon = { icon = '', color = 'orange' } },
      { '<leader>s<TAB>', icon = { icon = '󱔗', color = 'red' } },
      { '<leader>`', icon = { icon = '', color = 'green' } },
      { '<leader>s', group = '[S]earch', icon = { icon = '󱎰', color = 'green' } },
      { '<leader> ', icon = { icon = '󱩾', color = 'red' } },
      { '<leader>sc', icon = { icon = '', color = 'blue' } },
      { '<leader>sd', icon = { icon = '󰝰', color = 'yellow' } },
      { '<leader>ss', icon = { icon = '', color = 'orange' } },
      { '<leader>sf', icon = { icon = '', color = 'orange' } },
      { '<leader>sn', icon = { icon = '󰈞', color = 'blue' } },
      { '<leader>sr', icon = { icon = '󰺮', color = 'red' } },
      { '<leader>sw', icon = { icon = '', color = 'yellow' } },
      { '<leader>sm', group = '[S]earch Markdown directories', icon = { icon = '', color = 'white' } },
      { '<leader>smg', icon = { icon = '', color = 'red' } },
      { '<leader>smd', icon = { icon = '', color = 'white' } },
    })
  end,
}
