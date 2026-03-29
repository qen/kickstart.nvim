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
  '%$',
  '_controller$',
  '_service$',
  '_job$',
  '_worker$',
  '_policy$',
  '_spec$',
  '%.test$',
  '_input$',
  '_type$',
  '_fabricator$',
  '^app/views$',
}

local doc_dirs = {
  {
    name = ".gist",
    key = "<leader>smg",
    title = "Find Gist Files",
    prefix = " gist/",
    desc = "Search files in gist folder",
  },
  {
    name = "doc",
    key = "<leader>smd",
    title = "Find Doc Files",
    prefix = " doc/",
    desc = "Search files in doc folder",
  },
  -- {
  --   name = "~/master-notes",
  --   key = "<leader>msd",
  --   title = "Find Master Notes Files",
  --   prefix = "  master-notes/",
  --   desc = "Search files in master notes folder",
  -- },
}

-- NOTE: Helper function to similart document name
local function similar_document_name()
  -- local filepath = vim.fn.expand('%:r') -- Get current buffer's full relative path
  local filename = vim.fn.expand('%:t:r') -- Get current buffer's full relative path

  for _, suffix in ipairs(file_name_suffixes) do
    filename = filename:gsub(suffix, '')
  end

  return filename

  -- local parent_filename = filepath:match("^.-/(.+)") -- Remove the first folder (like "app/")
  -- Extract first parent directory and filename
  -- local parent, filename = filepath:match("([^/]+)/([^/]+)$") -- matches: "parent/filename"
  --
  -- if parent and filename then
  --   return parent .. "/" .. filename
  -- else
  --   return filepath -- fallback if pattern match fails
  -- end
end

-- NOTE: Helper function to check if a directory exists
local function dir_exists(path)
  local stat = vim.loop.fs_stat(path)
  return stat and stat.type == "directory"
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
    local action_state = require('telescope.actions.state')
    local actions = require('telescope.actions')
    local builtin = require('telescope.builtin')
    local fzy_sorter = require('telescope.sorters').get_fzy_sorter()
    local which_key = require('which-key')

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

    -- NOTE: find files normal and visual mode
    local function find_files_with_context(override_dir, override_query, suffix_priority)
      local query = override_query or ''
      if not override_query and vim.api.nvim_get_mode().mode == 'v' then
        query = get_visual_selection()
      end

      local current_file = vim.fn.expand '%'
      local current_dir = override_dir or vim.fn.fnamemodify(current_file, ':.:h')
      local current_ext = vim.fn.fnamemodify(current_file, ':e')
      local top_dir = current_dir ~= '.' and vim.split(current_dir, '/')[1] or nil
      -- local top_dirs = { 'app', 'packs' }
      local top_dirs = { 'app', 'db', 'spec', 'packs', 'jest' }
      -- local rails_dirs = { 'app', 'spec', 'db', 'config', 'packs' }

      -- Add top-level parent of current dir if not already in the list
      if top_dir then
        local exists = false
        for _, d in ipairs(top_dirs) do
          if d == top_dir then
            exists = true
            break
          end
        end
        if not exists then
          table.insert(top_dirs, top_dir)
        end
      end

      -- Highlight group for current directory files
      vim.api.nvim_set_hl(0, 'TelescopeCurrentDir', { fg = '#7aa2cc' })
      vim.api.nvim_set_hl(0, 'TelescopeSuffixMatch', { fg = '#c0976b' })
      vim.api.nvim_set_hl(0, 'TelescopeQueryBold', { fg = '#c0976b', bold = true })

      local make_entry = require('telescope.make_entry')
      local default_maker = make_entry.gen_from_file()

      local cwd = vim.fn.getcwd() .. '/'
      local oldfiles = {}
      local oldfile_count = 0
      for _, f in ipairs(vim.v.oldfiles) do
        local rel = f:find(cwd, 1, true) == 1 and f:sub(#cwd + 1) or nil
        if rel then
          oldfile_count = oldfile_count + 1
          oldfiles[rel] = oldfile_count
        end
      end

      local debug_scores = {}
      local score_suffix = false -- debug score for sorting
      local suffix_priority_scores = {}

      local find_command = nil
      if suffix_priority and query ~= '' then
        find_command = { 'rg', '--files', '--glob', '*' .. query .. '*' }
      end

      builtin.find_files {
        cwd = vim.fn.getcwd(),
        previewer = false,
        default_text = not suffix_priority and query or nil,
        find_command = find_command,
        prompt_prefix = ' ' .. current_dir .. '/',
        -- prompt_prefix = ' [project_dir]/',
        prompt_title = current_dir .. '/',
        search_dirs = top_dirs,
        attach_mappings = function(prompt_bufnr, map)
          map({ 'i', 'n' }, '<C-g>', function()
            local current_query = action_state.get_current_line()
            actions.close(prompt_bufnr)
            local parent = vim.fn.fnamemodify(current_dir, ':h')
            if parent == current_dir then return end
            find_files_with_context(parent, current_query, suffix_priority)
          end)
          map({ 'i', 'n' }, '<C-r>', function()
            actions.close(prompt_bufnr)
            builtin.live_grep {
              search_dirs = { current_dir },
              prompt_title = 'Live Grep in ' .. current_dir,
            }
          end)

          map({ 'i', 'n' }, '<C-d>', function()
            actions.close(prompt_bufnr)
            require('telescope').extensions.file_browser.file_browser {
              path = current_dir,
              select_buffer = true,
              -- theme = 'ivy',
              prompt_path = true,
            }
          end)

          return true
        end,
        entry_maker = function(line)
          local entry = default_maker(line)
          local original_display = entry.display

          entry.display = function(e)
            local text, highlights = original_display(e)
            if current_dir and (e.value:find('^' .. current_dir .. '/') or e.value:find('/' .. current_dir .. '/')) then
              highlights = highlights or {}
              local dir_start, dir_end = text:find(current_dir, 1, true)
              if dir_start then
                table.insert(highlights, { { dir_start - 1, dir_end }, 'TelescopeCurrentDir' })
              end
            end
            local score = debug_scores[e.value]
            if score and score_suffix then
              text = text .. '  [' .. string.format('%.9f', score) .. ']'
            end

            if suffix_priority then
              highlights = highlights or {}
              local dir = e.value:match('^(.*/)') or ''
              if dir ~= '' then
                local dir_start, dir_end = text:find(dir, 1, true)
                if dir_start then
                  table.insert(highlights, { { dir_start - 1, dir_end }, 'TelescopeSuffixMatch' })
                end
              end
              if query ~= '' then
                local q_lower = query:lower()
                local t_lower = text:lower()
                local q_start, q_end = t_lower:find(q_lower, 1, true)
                if q_start then
                  table.insert(highlights, { { q_start - 1, q_end }, 'TelescopeQueryBold' })
                end
              end
            end

            return text, highlights
          end

          return entry
        end,
        sorter = require('telescope.sorters').Sorter:new {
          scoring_function = function(self, prompt, line)
            local score = fzy_sorter:scoring_function(prompt, line)
            if score < 0 then return score end

            -- Exact filename match: strip extension + known suffixes, boost if base equals prompt
            if prompt ~= '' and line then
              local filename = line:match('[^/]+$')
              if filename then
                local name = filename:match('^(.+)%.') or filename
                local base = name
                for _, suffix in ipairs(file_name_suffixes) do
                  base = base:gsub(suffix, '')
                end
                if base:lower() == prompt:lower() then
                  score = score * 0.001
                end
              end
            end

            local in_current_dir = current_dir and line and line:find('^' .. current_dir .. '/')
            local in_line_dir = current_dir and line and current_dir:find('^' .. line .. '/')
            local oldfile_rank = line and oldfiles[line]
            local is_oldfile = oldfile_rank ~= nil
            local same_ext = current_ext and current_ext ~= '' and line and line:match('%.' .. current_ext .. '$')

            -- Recency factor: rank 1 → 0.1, last rank → 1.0
            local recency = is_oldfile and (0.1 + 0.9 * (oldfile_rank - 1) / math.max(oldfile_count - 1, 1)) or 1

            if in_current_dir and is_oldfile then
              score = score * 0.001 * recency
            elseif in_line_dir then
              score = score * 0.01
            elseif is_oldfile then
              score = score * 0.05
            end

            if not in_line_dir and line and (line:match('models/') or line:match('controllers/') or line:match('views/')) then
              score = score * 0.2 * recency
            end

            if same_ext then
              score = score * 0.1
            end

            if suffix_priority and line then
              local filename = line:match('[^/]+$')
              if filename then
                local name = filename:match('^(.+)%.')  or filename
                for i, suffix in ipairs(file_name_suffixes) do
                  if name:match(suffix) then
                    score = score * (0.0001 + 0.0009 * (i - 1) / math.max(#file_name_suffixes - 1, 1))
                    suffix_priority_scores[line] = score
                    break
                  end
                end
              end
            end

            if score_suffix then
              debug_scores[line] = score
            end

            return score
          end,
          highlighter = function(self, prompt, display)
            return fzy_sorter:highlighter(prompt, display)
          end,
        },
      }
    end

    local function find_files_current_folder(prompt_bufnr)
      local dir = prompt_dir(prompt_bufnr)
      actions.close(prompt_bufnr)
      find_files_with_context(dir)
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

    local prioritize_app_folder_sorter = function()
      local sorters = require('telescope.sorters')
      return sorters.Sorter:new {
        scoring_function = function(self, prompt, line)
          local score = fzy_sorter:scoring_function(prompt, line)
          if score < 0 then return score end

          -- If file path includes "app/", boost its score (lower = higher rank)
          if line:find '^app/' or line:find '/app/' then
            score = score * 0.1
          elseif line:find '^vendor/' or line:find '/vendor/' then
            score = score * 10
          end

          return score
        end,
        highlighter = function(self, prompt, display)
          return fzy_sorter:highlighter(prompt, display)
        end,
      }
    end

    local function dir_exists(path)
      local stat = vim.loop.fs_stat(path)
      return stat and stat.type == "directory"
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
        file_sorter = require('telescope.sorters').get_fzy_sorter(),
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
              ['<C-g>'] = find_files_cwd,
            },
            i = {
              ['<C-g>'] = find_files_cwd,
            },
          },
        },
        old_files = {
          file_sorter = require('telescope.sorters').fuzzy_with_index_bias,
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
        previewer = vim.o.columns >= 215,
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

    vim.keymap.set('n', '<TAB>o', function()
      builtin.buffers {
        prompt_title = 'Files opened',
        prompt_prefix = ' > ',
        previewer = vim.o.columns >= 215,
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

    vim.keymap.set({ 'n', 'v' }, '<leader>ss', find_files_with_context, { desc = 'Search [F]iles in app, packs, and current directories' })
    -- vim.keymap.set({ 'n', 'v' }, '<leader>sf', find_files_with_context, { desc = 'Search [F]iles in app, packs, and current directories' })
    vim.keymap.set('n', '<leader>sf', function()
      local query = similar_document_name()
      find_files_with_context(nil, query, true)
    end, { desc = 'Search similar [N]ame on app folders' })

    -- vim.keymap.set({ 'n', 'v' }, '<leader>sf', function()
    --   local query = ''
    --   if vim.api.nvim_get_mode().mode == 'v' then
    --     query = get_visual_selection()
    --   end
    --   local rails_dirs = { 'app', 'spec', 'db', 'config' }
    --   builtin.find_files {
    --     cwd = vim.fn.getcwd(),
    --     previewer = false,
    --     default_text = query,
    --     prompt_prefix = ' rails/',
    --     prompt_title = 'Find Rails Files',
    --     search_dirs = rails_dirs,
    --     sorter = prioritize_app_folder_sorter(),
    --   }
    -- end, { desc = 'Search Rails [F]iles' })

    -- NOTE: basic implementation of find_files with visual search
    -- vim.keymap.set({ 'n', 'v' }, '<leader>sf', function()
    --   local query = ''
    --   if vim.api.nvim_get_mode().mode == 'v' then
    --     query = get_visual_selection()
    --   end
    --   builtin.find_files {
    --     cwd = vim.fn.getcwd(),
    --     previewer = false,
    --     default_text = query,
    --     sorter = prioritize_app_folder_sorter(),
    --   }
    -- end, { desc = 'Search [F]iles in current working directory' })

    -- -- NOTE: find gist files
    -- vim.keymap.set({ 'n' }, '<leader>sg', function()
    --   builtin.find_files {
    --     cwd = vim.fn.getcwd(),
    --     previewer = false,
    --     prompt_prefix = ' gist/',
    --     prompt_title = 'Find Gist Files',
    --     search_dirs = { '.gist' },
    --   }
    -- end, { desc = 'Search [F]iles in .gist folder' })

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

    -- Get current working directory
    local cwd = vim.fn.getcwd()
    -- iterate to doc directories
    for _, dir in ipairs(doc_dirs) do
      local full_path = cwd .. "/" .. dir.name
      if dir_exists(full_path) then
        vim.keymap.set("n", dir.key, function()
          local actions = require('telescope.actions')
          builtin.find_files {
            cwd = cwd,
            previewer = false,
            prompt_prefix = dir.prefix,
            prompt_title = dir.title,
            search_dirs = { dir.name },
            attach_mappings = function(prompt_bufnr, map)
              local action_state = require('telescope.actions.state')
              actions.select_default:replace(function()
                local entry = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                local filepath = entry.path or entry.filename
                local tabs = vim.api.nvim_list_tabpages()
                if #tabs >= 2 then
                  -- Open in the second tab
                  vim.api.nvim_set_current_tabpage(tabs[2])
                  vim.cmd('edit ' .. vim.fn.fnameescape(filepath))
                else
                  -- Only one tab, create a new one
                  vim.cmd('tabnew ' .. vim.fn.fnameescape(filepath))
                end
              end)
              return true
            end,
          }
        end, { desc = dir.desc })
      end
    end

    -- NOTE: WHICH-KEY Config HERE
    which_key.add({
      { '<leader>p', group = '[P]eek Helper', icon = { icon = '󰸖', color = 'blue' } },
      { '<leader>pd', icon = { icon = '', color = 'red' } },
      { '<leader>pk', icon = { icon = '󰌌', color = 'blue' } },
      { '<leader>ph', icon = { icon = '', color = 'blue' } },
      { '<leader>pn', icon = { icon = '', color = 'yellow' } },
      { '<leader>pt', icon = { icon = 'w', color = 'blue' } },
      { '<TAB><TAB>', icon = { icon = '󱋢', color = 'orange' } },
      { '<TAB>o', icon = { icon = '', color = 'orange' } },
      { '<leader>s<TAB>', icon = { icon = '󱔗', color = 'red' } },
      { '<leader>`', icon = { icon = '', color = 'green' } },
      { '<leader>s', group = '[S]earch', icon = { icon = '󱎰', color = 'green' } },
      { '<leader> ', icon = { icon = '󱩾', color = 'red' } },
      { '<leader>sc', icon = { icon = '', color = 'blue' } },
      { '<leader>sd', icon = { icon = '󰝰', color = 'yellow' } },
      { '<leader>ss', icon = { icon = '', color = 'orange' } },
      { '<leader>sf', icon = { icon = '', color = 'orange' } },
      { '<leader>sf', icon = { icon = '', color = 'orange' } },
      { '<leader>sn', icon = { icon = '󰈞', color = 'blue' } },
      { '<leader>sr', icon = { icon = '󰺮', color = 'red' } },
      { '<leader>sw', icon = { icon = '', color = 'yellow' } },
      { '<leader>sm', group = '[S]earch Markdown directories', icon = { icon = '', color = 'white' } },
      { '<leader>smg', icon = { icon = '', color = 'red' } },
      { '<leader>smd', icon = { icon = '', color = 'white' } },
    })
  end,
}

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
