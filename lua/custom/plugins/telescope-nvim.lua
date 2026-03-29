local function get_visual_selection()
  local esc = vim.api.nvim_replace_termcodes('<esc>', true, false, true)
  vim.api.nvim_feedkeys(esc, 'x', false)
  local vstart = vim.fn.getpos "'<"
  local vend = vim.fn.getpos "'>"
  return table.concat(vim.fn.getregion(vstart, vend), '\n')
end

-- NOTE: Order matters for suffix_priority scoring — earlier entries get stronger boost (lower score = higher rank)
-- Used for: 1) stripping suffixes to find base name (e.g. order_spec -> order)
--           2) scoring files by suffix type when suffix_priority is true
local file_name_suffixes = {
  '%$',
  '_controller$',
  '_service$',
  '_job$',
  '_worker$',
  '_agent$',
  '_tool$',
  '_sub_agent_tool$',
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

-- NOTE: Strips known suffixes from current filename to find related files
-- e.g. "orders_controller" -> "orders", "order_spec" -> "order"
local function similar_document_name()
  local filename = vim.fn.expand('%:t:r')
  for _, suffix in ipairs(file_name_suffixes) do
    filename = filename:gsub(suffix, '')
  end
  return filename
end

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
    local action_state = require('telescope.actions.state')
    local actions = require('telescope.actions')
    local builtin = require('telescope.builtin')
    local fzy_sorter = require('telescope.sorters').get_fzy_sorter()
    local which_key = require('which-key')

    -- Helper: get directory from file browser prompt
    local function prompt_dir(prompt_bufnr)
      local current_picker = action_state.get_current_picker(prompt_bufnr)
      local finder = current_picker.finder
      return vim.fn.fnamemodify(finder.path, ':~:.')
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

    -- NOTE: Main find_files function with custom scoring
    -- override_dir: restrict search to a specific directory
    -- override_query: pre-fill the search query
    -- suffix_priority: when true, pre-filters files via rg glob, scores by file_name_suffixes order,
    --                  highlights directories and bolds the query match in results
    local function find_files_with_context(override_dir, override_query, suffix_priority)
      local query = override_query or ''
      if not override_query and vim.api.nvim_get_mode().mode == 'v' then
        query = get_visual_selection()
      end

      local current_file = vim.fn.expand '%'
      local current_dir = override_dir or vim.fn.fnamemodify(current_file, ':.:h')
      local current_ext = vim.fn.fnamemodify(current_file, ':e')
      local top_dir = current_dir ~= '.' and vim.split(current_dir, '/')[1] or nil
      local top_dirs = { 'app', 'db', 'spec', 'packs', 'jest' }

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

      local make_entry = require('telescope.make_entry')
      local default_maker = make_entry.gen_from_file()

      local cwd = vim.fn.getcwd() .. '/'
      -- NOTE: Build oldfiles lookup with recency rank (1 = most recent) for scoring
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
      local score_suffix = false
      local suffix_priority_scores = {}

      -- NOTE: When suffix_priority, pre-filter results via rg glob so only files
      -- containing the query in their filename are returned
      local find_command = nil
      if suffix_priority and query ~= '' then
        find_command = { 'rg', '--files', '--glob', '*' .. query .. '*' }
      end

      builtin.find_files {
        cwd = vim.fn.getcwd(),
        previewer = false,
        default_text = not suffix_priority and query or nil,
        find_command = find_command,
        prompt_prefix = (suffix_priority and query and '['..query..'] ' or ' ') .. current_dir .. '/',
        prompt_title = current_dir .. '/',
        search_dirs = top_dirs,
        attach_mappings = function(prompt_bufnr, map)
          -- NOTE: C-g navigates up to parent dir, C-r switches to live_grep, C-d opens file browser
          map({ 'i', 'n' }, '<C-g>', function()
            local current_query = action_state.get_current_line()
            actions.close(prompt_bufnr)
            local parent = vim.fn.fnamemodify(current_dir, ':h')
            if parent == current_dir then return end
            find_files_with_context(parent, suffix_priority and query or current_query, suffix_priority)
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
              prompt_path = true,
            }
          end)
          if suffix_priority then
            map({ 'i', 'n' }, '<C-s>', function()
              local current_query = action_state.get_current_line()
              find_files_with_context(current_dir, current_query, false)
            end)
          end
          return true
        end,
        entry_maker = function(line)
          local entry = default_maker(line)
          local original_display = entry.display

          entry.display = function(e)
            local text, highlights = original_display(e)

            local in_current_dir = (e.value:find('^' .. current_dir .. '/') or e.value:find('/' .. current_dir .. '/'))
            -- Highlight current directory matches
            if current_dir and in_current_dir then
              highlights = highlights or {}
              local dir_start, dir_end = text:find(current_dir, 1, true)
              if dir_start then
                table.insert(highlights, { { dir_start - 1, dir_end }, 'TelescopeCurrentDir' })
              end
            end

            -- Debug score display
            local score = debug_scores[e.value]
            if score and score_suffix then
              text = text .. '  [' .. string.format('%.9f', score) .. ']'
            end

            -- Suffix priority: highlight directory and bold the query match
            if suffix_priority and not in_current_dir then
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
        -- NOTE: Custom sorter — lower score = higher rank. Boosts are multiplicative:
        -- 1. Exact base name match (after suffix stripping): * 0.001
        -- 2. Current dir + oldfile: * 0.001 * recency | current dir: * 0.01
        --    Ancestor dir + oldfile: * 0.02 * recency | ancestor dir: * 0.03 | oldfile only: * 0.05
        -- 3. Rails key dirs (models/controllers/views), only un-visited non-dir files: * 0.2
        -- 4. Same file extension: * 0.1
        -- 5. Suffix priority (index-based): * 0.0001 to * 0.001
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
            local file_dir = line and line:match('^(.+)/[^/]+$') or ''
            local in_line_dir = file_dir ~= '' and current_dir and current_dir:find('^' .. file_dir .. '/') ~= nil
            local oldfile_rank = line and oldfiles[line]
            local is_oldfile = oldfile_rank ~= nil
            local same_ext = current_ext and current_ext ~= '' and line and line:match('%.' .. current_ext .. '$')

            -- Recency factor: rank 1 -> 0.1, last rank -> 1.0
            local recency = is_oldfile and (0.1 + 0.9 * (oldfile_rank - 1) / math.max(oldfile_count - 1, 1)) or 1

            if in_current_dir and is_oldfile then
              score = score * 0.001 * recency
            elseif in_current_dir then
              score = score * 0.01
            elseif in_line_dir and is_oldfile then
              score = score * 0.02 * recency
            elseif in_line_dir then
              score = score * 0.03
            elseif is_oldfile then
              score = score * 0.05
            end

            if not in_current_dir and not in_line_dir and not is_oldfile
                and line and (line:match('models/') or line:match('controllers/') or line:match('views/')) then
              score = score * 0.2
            end

            if same_ext then
              score = score * 0.1
            end

            if suffix_priority and line then
              local filename = line:match('[^/]+$')
              if filename then
                local name = filename:match('^(.+)%.') or filename
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
      actions.close(prompt_bufnr)
      local cwd = vim.fn.getcwd()
      builtin.find_files {
        cwd = cwd,
        previewer = false,
        prompt_prefix = ' /',
        prompt_title = 'Find Files',
      }
    end

    -- [[ Configure Telescope ]]
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
          mappings = {
            n = { ['<C-g>'] = find_files_cwd },
            i = { ['<C-g>'] = find_files_cwd },
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
          previewer = false,
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
        file_sorter = require('telescope.sorters').fuzzy_with_index_bias,
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
      }
    end, { desc = 'Find Opened Files' })

    -- Keymaps: Search
    vim.keymap.set('n', '<leader>sd', function()
      require('telescope').extensions.file_browser.file_browser {
        path = '%:p:h',
        select_buffer = true,
        prompt_path = true,
      }
    end, { desc = 'Search Browse buffer [D]irectory' })

    vim.keymap.set('n', '<leader>sw', function()
      require('telescope').extensions.file_browser.file_browser {
        prompt_path = true,
      }
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

    vim.keymap.set('n', '<leader>sf', function()
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
