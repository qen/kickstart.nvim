local M = {}

local function get_visual_selection()
  local esc = vim.api.nvim_replace_termcodes('<esc>', true, false, true)
  vim.api.nvim_feedkeys(esc, 'x', false)
  local vstart = vim.fn.getpos "'<"
  local vend = vim.fn.getpos "'>"
  return table.concat(vim.fn.getregion(vstart, vend), '\n')
end

M.get_visual_selection = get_visual_selection

-- NOTE: Order matters for suffix_priority scoring — earlier entries get stronger boost (lower score = higher rank)
-- Used for: 1) stripping suffixes to find base name (e.g. order_spec -> order)
--           2) scoring files by suffix type when suffix_priority is true
M.file_name_suffixes = {
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

-- NOTE: Factory for context-aware sorter — lower score = higher rank. Boosts are multiplicative:
-- 1. Exact base name match (after suffix stripping): * 0.001
-- 2. Current dir + oldfile: * 0.001 * recency | current dir: * 0.01
--    Ancestor dir + oldfile: * 0.02 * recency | ancestor dir: * 0.03 | oldfile only: * 0.05
-- 3. Rails key dirs (models/controllers/views), only un-visited non-dir files: * 0.2
-- 4. Same file extension: * 0.1
-- 5. Suffix priority (index-based): * 0.0001 to * 0.001
function M.make_context_sorter(opts)
  local fzy_sorter = require('telescope.sorters').get_fzy_sorter()
  local file_name_suffixes = M.file_name_suffixes

  opts = opts or {}
  local current_file = vim.fn.expand '%'
  local current_dir = opts.current_dir or vim.fn.fnamemodify(current_file, ':.:h')
  local current_ext = opts.current_ext or vim.fn.fnamemodify(current_file, ':e')
  local suffix_priority = opts.suffix_priority or false

  local cwd = vim.fn.getcwd() .. '/'
  local oldfiles_map = {}
  local oldfile_count = 0
  for _, f in ipairs(vim.v.oldfiles) do
    local rel = f:find(cwd, 1, true) == 1 and f:sub(#cwd + 1) or nil
    if rel then
      oldfile_count = oldfile_count + 1
      oldfiles_map[rel] = oldfile_count
    end
  end

  local debug_scores = {}
  local score_suffix = false
  local suffix_priority_scores = {}

  local sorter = require('telescope.sorters').Sorter:new {
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
      local oldfile_rank = line and oldfiles_map[line]
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
  }

  return sorter, debug_scores, score_suffix, suffix_priority_scores
end

-- NOTE: Main find_files function with custom scoring
-- override_dir: restrict search to a specific directory
-- override_query: pre-fill the search query
-- suffix_priority: when true, pre-filters files via rg glob, scores by file_name_suffixes order,
--                  highlights directories and bolds the query match in results
function M.find_files_with_context(override_dir, override_query, suffix_priority, override_top_dir)
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')
  local builtin = require('telescope.builtin')
  local make_entry = require('telescope.make_entry')
  local file_name_suffixes = M.file_name_suffixes

  local query = override_query or ''

  if not override_query and vim.api.nvim_get_mode().mode == 'v' then
    query = get_visual_selection()
  end

  local vquery = vim.api.nvim_get_mode().mode == 'v' and get_visual_selection() or nil

  local current_file = vim.fn.expand '%'
  local current_dir = override_dir or vim.fn.fnamemodify(current_file, ':.:h')
  local current_ext = vim.fn.fnamemodify(current_file, ':e')
  local top_dir = current_dir ~= '.' and vim.split(current_dir, '/')[1] or nil
  local top_dirs = (suffix_priority and query ~= '') and { 'app', 'db', 'spec', 'packs', 'jest' } or { 'app', 'packs' }

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

  local default_maker = make_entry.gen_from_file()

  -- NOTE: When suffix_priority, pre-filter results via rg glob so only files
  -- containing the query in their filename are returned
  -- NOTE: Exclude CSS/SCSS unless current file is a frontend file type
  local frontend_exts = { 'ts', 'tsx', 'js', 'jsx', 'html', 'htm', 'slim', 'haml', 'erb' }
  local include_styles = vim.tbl_contains(frontend_exts, current_ext)

  local find_command = nil
  if suffix_priority and query ~= '' then
    find_command = { 'rg', '--files', '--glob', '*' .. query .. '*' }
  end
  if not include_styles then
    find_command = find_command or { 'rg', '--files' }
    vim.list_extend(find_command, { '--glob', '!*.css', '--glob', '!*.scss' })
  else
    find_command = find_command or { 'rg', '--files' }
    vim.list_extend(find_command, { '--glob', '!*.html', '--glob', '!*.htm', '--glob', '!*.slim', '--glob', '!*.haml', '--glob', '!*.erb' })
  end

  -- NOTE: Restrict search to frontend dirs when in a frontend file
  if include_styles then
    top_dirs = { 'app', 'jest', 'packs' }
  end

  local sorter, debug_scores, score_suffix, suffix_priority_scores = M.make_context_sorter({
    current_dir = current_dir,
    current_ext = current_ext,
    suffix_priority = suffix_priority,
  })

  if override_top_dir then
    top_dirs = { override_top_dir }
  end

  builtin.find_files {
    cwd = vim.fn.getcwd(),
    previewer = false,
    default_text = not suffix_priority and query or vquery,
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
        M.find_files_with_context(parent, suffix_priority and query or current_query, suffix_priority, current_dir)
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
        -- M.find_files_with_context(nil, nil, nil, current_dir)
      end)
      if suffix_priority then
        map({ 'i', 'n' }, '<C-Space>', function()
          -- local current_query = action_state.get_current_line()
          M.find_files_with_context(current_dir, query, false)
        end)
      else
        map({ 'i', 'n' }, '<C-f>', function()
          local current_query = action_state.get_current_line()
          if current_query and current_query ~= '' then
            M.find_files_with_context(current_dir, current_query, true)
          end
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
    sorter = sorter,
  }
end

-- local function find_files_cwd(prompt_bufnr)
--   actions.close(prompt_bufnr)
--   local cwd = vim.fn.getcwd()
--   builtin.find_files {
--     cwd = cwd,
--     previewer = false,
--     prompt_prefix = ' /',
--     prompt_title = 'Find Files',
--   }
-- end

-- local function find_files_parent_dir(current_dir)
--   builtin.find_files {
--     cwd = current_dir,
--     previewer = false,
--     prompt_prefix = './' .. current_dir .. '/',
--     prompt_title = current_dir,
--     attach_mappings = function(prompt_bufnr, map)
--       -- C-g navigates up to parent dir
--       map({ 'i', 'n' }, '<C-g>', function()
--         actions.close(prompt_bufnr)
--         local parent = vim.fn.fnamemodify(current_dir, ':h')
--         if parent == current_dir then return end
--         find_files_with_context(parent)
--       end)
--       return true
--     end
--   }
-- end

return M
