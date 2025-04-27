-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information

local function get_visual_selection()
  local esc = vim.api.nvim_replace_termcodes('<esc>', true, false, true)
  vim.api.nvim_feedkeys(esc, 'x', false)
  local vstart = vim.fn.getpos "'<"
  local vend = vim.fn.getpos "'>"
  return table.concat(vim.fn.getregion(vstart, vend), '\n')
end

local file_name_suffixes = {
  '_controller$',
  '_spec$',
  '_service$',
  '_policy$',
  '_job$',
  '_worker$',
  '_input$',
  '_type$',
  '_fabricator$',
}

local function similar_document_name()
  local filename = string.gsub(vim.fn.expand '%:t:r:r:r:r', '^%W', '')
  local name = filename

  for _, suffix in ipairs(file_name_suffixes) do
    name = name:gsub(suffix, '')
  end

  return name
end

return { -- telescope: Fuzzy Finder (files, lsp, etc)
  'nvim-telescope/telescope.nvim',
  event = 'VimEnter',
  branch = '0.1.x',
  dependencies = {
    { -- plenary.nvim:
      'nvim-lua/plenary.nvim',
    },

    { -- telescope-fzf-native: If encountering errors, see telescope-fzf-native README for installation instructions
      'nvim-telescope/telescope-fzf-native.nvim',

      -- `build` is used to run some command when the plugin is installed/updated.
      -- This is only run then, not every time Neovim starts up.C-P
      build = 'make',

      -- `cond` is a condition used to determine whether this plugin should be
      -- installed and loaded.
      cond = function()
        return vim.fn.executable 'make' == 1
      end,
    },

    { -- telescope-ui-select.nvim
      'nvim-telescope/telescope-ui-select.nvim',
    },

    -- Useful for getting pretty icons, but requires a Nerd Font.
    { -- nvim-web-devicons
      'nvim-tree/nvim-web-devicons',
      enabled = vim.g.have_nerd_font,
      config = function()
        require('nvim-web-devicons').setup {
          -- your personal icons can go here (to override)
          -- you can specify color or cterm_color instead of specifying both of them
          -- DevIcon will be appended to `name`
          -- override = {
          --   ruby = {
          --     color = '#428850',
          --     cterm_color = '65',
          --     name = 'Ruby',
          --   },
          -- },

          -- globally enable different highlight colors per icon (default to true)
          -- if set to false all icons will have the default icon's color
          color_icons = true,

          -- globally enable default icons (default to false)
          -- will get overriden by `get_icons` option
          default = true,

          -- globally enable "strict" selection of icons - icon will be looked up in
          -- different tables, first by filename, and if not found by extension; this
          -- prevents cases when file doesn't have any extension but still gets some icon
          -- because its name happened to match some extension (default to false)
          strict = true,

          -- set the light or dark variant manually, instead of relying on `background`
          -- (default to nil)
          variant = 'dark',

          -- same as `override` but specifically for overrides by filename
          -- takes effect when `strict` is true
          -- override_by_filename = {
          --   ['.gitignore'] = {
          --     icon = ''
          --     color = '#f1502f',
          --     name = 'Gitignore',
          --   },
          -- },

          -- same as `override` but specifically for overrides by extension
          -- takes effect when `strict` is true
          -- override_by_extension = {
          --   ['rb'] = {
          --     color = '#CC3E44',
          --     cterm_color = '52',
          --     name = 'Rb',
          --   },
          -- },

          -- same as `override` but specifically for operating system
          -- takes effect when `strict` is true
          -- override_by_operating_system = {
          --   ['apple'] = {
          --     icon = '',
          --     color = '#A2AAAD',
          --     cterm_color = '248',
          --     name = 'Apple',
          --   },
          -- },
        }
      end,
    },

    { -- axkirillov/easypick.nvim:
      'axkirillov/easypick.nvim',
      config = function()
        local easypick = require 'easypick'

        -- only required for the example to work
        -- local get_default_branch = "git remote show origin | grep 'HEAD branch' | cut -d' ' -f5"
        -- local base_branch = vim.fn.system(get_default_branch) or 'master'
        local base_branch = 'master'

        easypick.setup {
          pickers = {
            -- add your custom pickers here
            -- below you can find some examples of what those can look like

            -- list files inside current folder with default previewer
            {
              -- name for your custom picker, that can be invoked using :Easypick <name> (supports tab completion)
              name = 'ls',
              -- the command to execute, output has to be a list of plain text entries
              command = 'ls',
              -- specify your custom previwer, or use one of the easypick.previewers
              previewer = easypick.previewers.default(),
            },

            -- diff current branch with base_branch and show files that changed with respective diffs in preview
            {
              name = 'changed_files',
              command = 'git diff --name-only $(git merge-base HEAD ' .. base_branch .. ' )',
              previewer = easypick.previewers.branch_diff { base_branch = base_branch },
              theme = 'ivy',
            },

            -- list files that have conflicts with diffs in preview
            {
              name = 'conflicts',
              command = 'git diff --name-only --diff-filter=U --relative',
              previewer = easypick.previewers.file_diff(),
            },
          },
        }
      end,
    },

    { -- telescope-file-browser.nvim
      'nvim-telescope/telescope-file-browser.nvim',
    },

    { -- telescope-ag
      'kelly-lin/telescope-ag',
      dependencies = { 'nvim-telescope/telescope.nvim' },
      config = function()
        local telescope_ag = require 'telescope-ag'
        telescope_ag.setup {
          cmd = telescope_ag.cmds.rg, -- defaults to telescope_ag.cmds.ag
        }
      end,
    },

    -- { -- neoscopes
    --   'smartpde/neoscopes',
    --   config = function()
    --     local scopes = require 'neoscopes'
    --
    --     scopes.setup {
    --       diff_branches_for_scopes = { 'master', 'origin/master' },
    --     }
    --     -- Helper functions to fetch the current scope and set `search_dirs`
    --     _G.find_files = function()
    --       require('telescope.builtin').find_files {
    --         search_dirs = scopes.get_current_dirs(),
    --       }
    --     end
    --     _G.live_grep = function()
    --       require('telescope.builtin').live_grep {
    --         search_dirs = scopes.get_current_dirs(),
    --       }
    --     end
    --
    --     vim.api.nvim_set_keymap('n', '<Leader>ff', ':lua find_files()<CR>', { noremap = true })
    --     vim.api.nvim_set_keymap('n', '<Leader>fg', ':lua live_grep()<CR>', { noremap = true })
    --   end,
    -- },
  },
  config = function()
    -- Telescope is a fuzzy finder that comes with a lot of different things that
    -- it can fuzzy find! It's more than just a "file finder", it can search
    -- many different aspects of Neovim, your workspace, LSP, and more!
    --
    -- The easiest way to use Telescope, is to start by doing something like:
    --  :Telescope help_tags
    --
    -- After running this command, a window will open up and you're able to
    -- type in the prompt window. You'll see a list of `help_tags` options and
    -- a corresponding preview of the help.
    --
    -- Two important keymaps to use while in Telescope are:
    --  - Insert mode: <c-/>
    --  - Normal mode: ?
    --
    -- This opens a window that shows you all of the keymaps for the current
    -- Telescope picker. This is really useful to discover what Telescope can
    -- do as well as how to actually do it!

    -- See `:help telescope.builtin`
    local action_state = require 'telescope.actions.state'
    local actions = require 'telescope.actions'
    local builtin = require 'telescope.builtin'

    -- live_grep on file browser current directory
    -- NOTE: need ripgrep
    local function prompt_dir(prompt_bufnr)
      local current_picker = action_state.get_current_picker(prompt_bufnr)
      local finder = current_picker.finder
      return vim.fn.fnamemodify(finder.path, ':~:.')
    end

    local function ripgrep_current_folder(prompt_bufnr)
      local dir = prompt_dir(prompt_bufnr)
      actions.close(prompt_bufnr)
      require('telescope.builtin').live_grep {
        prompt_prefix = '󰺮 > ',
        prompt_title = 'Live Grep in ' .. dir,
        search_dirs = { dir },
      }
    end

    local function find_files_current_folder(prompt_bufnr)
      local dir = prompt_dir(prompt_bufnr)
      actions.close(prompt_bufnr)
      builtin.find_files {
        cwd = vim.fn.getcwd(),
        previewer = false,
        prompt_prefix = ' ' .. dir .. '/',
        prompt_title = 'Find Files ' .. dir,
        search_dirs = { dir },
      }
    end

    local function find_files_cwd(prompt_bufnr)
      local dir = prompt_dir(prompt_bufnr)
      actions.close(prompt_bufnr)
      local cwd = vim.fn.getcwd()
      require('telescope.builtin').find_files {
        cwd = cwd,
        previewer = false,
        prompt_prefix = ' ' .. '/',
        prompt_title = 'Find Files',
      }
    end

    local function get_top_level_dir()
      local relpath = vim.fn.fnamemodify(vim.fn.expand '%', ':.')
      local parts = vim.split(relpath, '/')

      if #parts > 1 then
        return parts[1]
      else
        return nil
      end
    end

    -- [[ Configure Telescope ]]
    -- See `:help telescope` and `:help telescope.setup()`
    require('telescope').setup {
      -- You can put your default mappings / updates / etc. in here
      --  All the info you're looking for is in `:help telescope.setup()`
      --
      defaults = {
        --   mappings = {
        --     i = { ['<c-enter>'] = 'to_fuzzy_refine' },
        --   },
        -- file_ignore_patterns = {
        --   'node_modules',
        --   '.gist',
        --   '.git',
        --   'tmp',
        --   'public/assets',
        --   'public/packs',
        --   'public/packs-test',
        --   '.jpg',
        --   '.gif',
        --   '.zip',
        --   '.min.js',
        --   'log',
        --   'vendor/cache',
        --   'storage',
        -- },
        file_sorter = require('telescope.sorters').get_fzy_sorter,
        vimgrep_arguments = {
          'rg',
          '--color=never',
          '--no-heading',
          '--with-filename',
          '--line-number',
          '--column',
          '--smart-case',
          '--trim', -- add this value
        },
      },
      pickers = {
        -- buffers = {
        --   theme = 'ivy',
        -- },
        -- changed_files = {
        --   theme = 'ivy',
        -- },
        find_files = {
          mappings = {
            n = {
              ['<C-g>'] = find_files_cwd
            },
            i = {
              ['<C-g>'] = find_files_cwd
            },
          },
        },
        old_files = {
          file_sorter = require('telescope.sorters').fuzzy_with_index_bias
        }
        -- WARN: not working, can't figure out current direction
        -- live_grep = {
        --   mappings = {
        --     i = {
        --       ['<C-f>'] = find_files_current_folder,
        --     },
        --   },
        -- },
      },
      extensions = {
        ['ui-select'] = {
          require('telescope.themes').get_dropdown(),
        },
        file_browser = {
          -- theme = 'ivy',
          previewer = false,
          -- disables netrw and use telescope-file-browser in its place
          hijack_netrw = true,
          mappings = {
            ['i'] = {
              ['<C-r>'] = ripgrep_current_folder,
              ['<C-f>'] = find_files_current_folder,
            },
            ['n'] = {
              ['<C-r>'] = ripgrep_current_folder,
              ['<C-f>'] = find_files_current_folder,
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

    vim.keymap.set('n', '<leader>ph', builtin.help_tags, { desc = 'Peek [H]elp' })
    vim.keymap.set('n', '<leader>pk', builtin.keymaps, { desc = 'Peek [K]eymaps' })
    vim.keymap.set('n', '<leader>pt', builtin.builtin, { desc = 'Peek Select [T]elescope' })
    -- NOTE: Shortcut for searching your Neovim configuration files
    vim.keymap.set('n', '<leader>pn', function()
      builtin.find_files { cwd = vim.fn.stdpath 'config' }
    end, { desc = 'Peek [N]eovim files' })

    -- regroupd <leader>s shortcut keys
    vim.keymap.set('n', '<leader>pd', builtin.diagnostics, { desc = 'Peek [D]iagnostics' })

    local function show_opened_file_history()
      builtin.oldfiles {
        only_cwd = true,
        file_sorter = require('telescope.sorters').fuzzy_with_index_bias,
        prompt_title = 'Files opened history',
        prompt_prefix = '󱋢 > ',
      }
    end

    vim.keymap.set('n', '<TAB><TAB>', show_opened_file_history, { desc = 'Recent Files' })

    vim.keymap.set('n', '<leader>sd', function()
      require('telescope').extensions.file_browser.file_browser {
        path = '%:p:h',
        select_buffer = true,
        -- theme = 'ivy',
        prompt_path = true,
      }
    end, { desc = 'Search Browse buffer [D]irectory' })

    vim.keymap.set('n', '<leader>sw', function()
      -- vim.cmd 'Telescope file_browser'
      require('telescope').extensions.file_browser.file_browser {
        -- path = '%:p:h',
        -- select_buffer = true,
        -- theme = 'ivy',
        prompt_path = true,
      }
    end, { desc = 'Search Browse <c[w]d>irectory' })

    vim.keymap.set('n', '<leader>sn', function()
      local query = similar_document_name()
      builtin.find_files {
        cwd = vim.fn.getcwd(),
        previewer = false,
        search_file = query,
        prompt_title = '󰈞 similar name to > ' .. query,
        prompt_prefix = '󰈞 > ',
        search_dirs = { 'app', 'packs', 'spec', 'jest', 'test', 'features' },
      }
    end, { desc = 'Search similar [N]ame on app folders' })

    vim.keymap.set('n', '<TAB>o', function()
      builtin.buffers {
        prompt_title = 'Files opened',
        prompt_prefix = ' > ',
      }
    end, { desc = 'Find Opened Files' })

    vim.keymap.set('n', '<leader>sc', function()
      vim.cmd 'Easypick changed_files'
    end, { desc = 'Search Git [C]hanged files' })

    vim.keymap.set('n', '<leader>`', builtin.resume, { desc = 'Search again' })

    -- rg --type-list
    -- local rip_grep_file_type = {
    --   '--type=js',
    --   '--type=ruby',
    --   '--type=yaml',
    --   '--type=readme',
    --   '--type=haml',
    --   '--type=slim',
    --   '--type=json',
    --   '--type=jsonl',
    --   '--type=less',
    --   '--type=sass',
    --   '--type=sh',
    --   '--type=sql',
    --   '--type=svg',
    --   '--type=typescript',
    --   '--type=vue',
    -- }
    -- NOTE: live grep normal and visual mode
    vim.keymap.set({ 'n', 'v' }, '<leader>sr', function()
      -- local query = vim.fn.expand '<cword>'
      -- local ft = vim.bo.filetype
      -- local type = rip_grep_file_type[ft] or ft
      -- local additional_args = { '--type=' .. type }
      -- local additional_args = rip_grep_file_type
      local query = ''

      if vim.api.nvim_get_mode().mode == 'v' then
        query = get_visual_selection()
      end

      builtin.live_grep {
        default_text = query,
        prompt_prefix = '󰺮 > ',
      }
    end, { desc = 'Search [R]ipgrep Word selection' })

    -- NOTE: find files normal and visual mode
    vim.keymap.set({ 'n', 'v' }, '<leader>ss', function()
      local query = ''
      if vim.api.nvim_get_mode().mode == 'v' then
        query = get_visual_selection()
      end

      local top_dir = get_top_level_dir()

      builtin.find_files {
        cwd = vim.fn.getcwd(),
        previewer = false,
        default_text = query,
        prompt_prefix = top_dir and ' ' .. top_dir .. '/',
        prompt_title = top_dir and 'Find Files ' .. top_dir .. '/',
        search_dirs = top_dir and { top_dir },
      }
    end, { desc = 'Search [F]iles in current parent directory folder' })

    vim.keymap.set({ 'n', 'v' }, '<leader>sf', function()
      local query = ''
      if vim.api.nvim_get_mode().mode == 'v' then
        query = get_visual_selection()
      end

      local top_dir = get_top_level_dir()

      builtin.find_files {
        cwd = vim.fn.getcwd(),
        previewer = false,
        default_text = query
      }
    end, { desc = 'Search [F]iles in current parent directory folder' })

    -- NOTE: find gist files
    vim.keymap.set({ 'n' }, '<leader>sg', function()
      builtin.find_files {
        cwd = vim.fn.getcwd(),
        previewer = false,
        prompt_prefix = ' gist/',
        prompt_title = 'Find Gist Files',
        search_dirs = { '.gist' },
      }
    end, { desc = 'Search [F]iles in .gist folder' })

    -- Slightly advanced example of overriding default behavior and theme
    vim.keymap.set('n', '<leader><leader>', function()
      -- You can pass additional configuration to Telescope to change the theme, layout, etc.
      builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
        previewer = false,
        layout_config = {
          height = 0.7,
          width = 0.7,
        },
      })
    end, { desc = '[ ] Fuzzily search in current buffer' })

    -- It's also possible to pass additional configuration options.
    --  See `:help telescope.builtin.live_grep()` for information about particular keys
    vim.keymap.set('n', '<leader>s<TAB>', function()
      builtin.live_grep {
        grep_open_files = true,
        prompt_title = 'Live Grep in Open Files',
      }
    end, { desc = '[S]earch [/] in Open Files' })
  end,
}

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
