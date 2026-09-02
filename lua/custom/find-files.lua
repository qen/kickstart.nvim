-- Context-aware file finding on top of snacks.picker.
--
-- Port of the former telescope-find-files.lua. The ranking rules are the same
-- (see `context_on_match`), and so are the in-picker keys:
--   <C-g>      re-run in the parent directory
--   <C-r>      live grep in the current directory
--   <C-d>      open the explorer in the current directory
--   <C-f>      with text typed: suffix-priority search for that text
--              without text: toggle restricting to the current directory
--   <C-Space>  (suffix mode) back to the normal fuzzy search
local M = {}

local function get_visual_selection()
  local esc = vim.api.nvim_replace_termcodes('<esc>', true, false, true)
  vim.api.nvim_feedkeys(esc, 'x', false)
  local vstart = vim.fn.getpos "'<"
  local vend = vim.fn.getpos "'>"
  return table.concat(vim.fn.getregion(vstart, vend), '\n')
end
M.get_visual_selection = get_visual_selection

function M.visual_selection_or_nil()
  local mode = vim.api.nvim_get_mode().mode
  if mode == 'v' or mode == 'V' then
    return get_visual_selection()
  end
  return nil
end

-- Rails-flavoured suffixes stripped when comparing "similar" file names.
-- Order matters for suffix-priority mode: earlier = ranked higher.
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

function M.similar_document_name()
  local filename = vim.fn.expand('%:t:r')
  for _, suffix in ipairs(M.file_name_suffixes) do
    filename = filename:gsub(suffix, '')
  end
  return filename
end

-- ---------------------------------------------------------------------------
-- path helpers
-- ---------------------------------------------------------------------------

local function starts_with(s, prefix)
  return s:sub(1, #prefix) == prefix
end

local function cwd_prefix()
  return vim.fn.getcwd() .. '/'
end

--- Path relative to cwd, without a leading "./". `cwd` (with trailing slash)
--- may be passed in by callers that run in a fast event context, where
--- `vim.fn.getcwd()` is not allowed.
function M.rel(path, cwd)
  if not path or path == '' then
    return ''
  end
  cwd = cwd or cwd_prefix()
  if starts_with(path, cwd) then
    path = path:sub(#cwd + 1)
  end
  return (path:gsub('^%./', ''))
end

function M.item_rel(item, cwd)
  return M.rel(Snacks.picker.util.path(item) or item.file or item.text, cwd)
end

local function dir_exists(path)
  local stat = (vim.uv or vim.loop).fs_stat(path)
  return stat ~= nil and stat.type == 'directory'
end

-- snacks reserves <C-r> as a prefix for register insertion; `nowait` lets a
-- plain <C-r> mapping fire immediately instead of waiting for a second key.
local function ikey(action)
  return { action, mode = { 'i', 'n' }, nowait = true }
end
M.ikey = ikey

local function reopen(fn)
  vim.schedule(fn)
end

-- ---------------------------------------------------------------------------
-- ranking
-- ---------------------------------------------------------------------------

--- Builds a matcher `on_match` hook that scales every match's fuzzy score by
--- the same multipliers the old Telescope sorter used (inverted, since snacks
--- ranks higher scores first). Preference, strongest first:
---   exact match of the file's base name (suffixes stripped) against the prompt
---   file in the current file's directory that was opened recently (by recency)
---   file in the current file's directory
---   file in an ancestor directory, recently opened / not
---   recently opened file anywhere
---   Rails models/controllers/views
--- plus a boost for files with the same extension as the current file, and, in
--- suffix-priority mode, ranking by position in `file_name_suffixes`.
---@return fun(matcher, item) on_match, fun(rel:string):table info
function M.context_on_match(opts)
  opts = opts or {}
  local current_file = vim.fn.expand '%'
  local current_dir = opts.current_dir or vim.fn.fnamemodify(current_file, ':.:h')
  local current_ext = opts.current_ext or vim.fn.fnamemodify(current_file, ':e')
  local suffix_priority = opts.suffix_priority or false
  local suffixes = M.file_name_suffixes

  local cwd = cwd_prefix()
  local oldfiles_rank, oldfile_count = {}, 0
  for _, f in ipairs(vim.v.oldfiles) do
    if starts_with(f, cwd) then
      oldfile_count = oldfile_count + 1
      oldfiles_rank[f:sub(#cwd + 1)] = oldfile_count
    end
  end

  local cache = {}
  local function info(rel)
    local c = cache[rel]
    if c then
      return c
    end
    local filename = rel:match('[^/]+$') or rel
    local name = filename:match('^(.+)%.') or filename
    local base = name
    for _, suffix in ipairs(suffixes) do
      base = base:gsub(suffix, '')
    end
    local file_dir = rel:match('^(.+)/[^/]+$') or ''
    local in_current_dir = current_dir ~= '' and current_dir ~= '.' and starts_with(rel, current_dir .. '/')
    local in_line_dir = file_dir ~= '' and starts_with(current_dir, file_dir .. '/')
    local rank = oldfiles_rank[rel]
    local recency = rank and (0.1 + 0.9 * (rank - 1) / math.max(oldfile_count - 1, 1)) or 1

    local m = 1
    if in_current_dir and rank then
      m = 0.001 * recency
    elseif in_current_dir then
      m = 0.01
    elseif in_line_dir and rank then
      m = 0.02 * recency
    elseif in_line_dir then
      m = 0.03
    elseif rank then
      m = 0.05
    elseif rel:match('models/') or rel:match('controllers/') or rel:match('views/') then
      m = 0.2
    end
    if current_ext and current_ext ~= '' and rel:sub(-(#current_ext + 1)) == '.' .. current_ext then
      m = m * 0.1
    end
    if suffix_priority then
      for i, suffix in ipairs(suffixes) do
        if name:match(suffix) then
          m = m * (0.0001 + 0.0009 * (i - 1) / math.max(#suffixes - 1, 1))
          break
        end
      end
    end

    c = { mul = 1 / m, base = base:lower(), in_current_dir = in_current_dir }
    cache[rel] = c
    return c
  end

  -- NOTE: runs inside the matcher's async loop (fast event context): no vim.fn.* here
  local function on_match(matcher, item)
    if item.score == 0 or not item.file then
      return
    end
    local c = info(M.item_rel(item, cwd))
    local mul = c.mul
    local pattern = matcher.pattern or ''
    if pattern ~= '' and c.base == pattern:lower() then
      mul = mul * 1000
    end
    item.score = item.score * mul
  end

  return on_match, info
end

--- Wraps the default file formatter: colours the directory part of files in the
--- current directory, and in suffix mode colours other directories and bolds
--- the query inside the file name.
function M.context_format(info, suffix_priority, query)
  local cwd = cwd_prefix()
  local function recolor(chunks, is_current)
    for i = #chunks, 1, -1 do
      local chunk = chunks[i]
      if chunk[2] == 'SnacksPickerDir' then
        chunk[2] = is_current and 'CustomPickerCurrentDir' or 'CustomPickerSuffixMatch'
      elseif not is_current and suffix_priority and query ~= '' and chunk[2] == 'SnacksPickerFile' then
        local text = chunk[1]
        local s, e = text:lower():find(query:lower(), 1, true)
        if s then
          table.remove(chunks, i)
          table.insert(chunks, i, { text:sub(e + 1), 'SnacksPickerFile', field = 'file' })
          table.insert(chunks, i, { text:sub(s, e), 'CustomPickerQueryBold', field = 'file' })
          table.insert(chunks, i, { text:sub(1, s - 1), 'SnacksPickerFile', field = 'file' })
        end
      end
    end
    return chunks
  end

  return function(item, picker)
    local ret = Snacks.picker.format.file(item, picker)
    local c = info(M.item_rel(item, cwd))
    if not c.in_current_dir and not suffix_priority then
      return ret
    end
    for _, chunk in ipairs(ret) do
      if type(chunk.resolve) == 'function' then
        local resolve = chunk.resolve
        chunk.resolve = function(max_width)
          return recolor(resolve(max_width), c.in_current_dir)
        end
      end
    end
    return recolor(ret, c.in_current_dir)
  end
end

-- ---------------------------------------------------------------------------
-- pickers
-- ---------------------------------------------------------------------------

--- Open the explorer rooted at `dir`, reusing an open explorer if there is one.
function M.explorer_at(dir)
  local abs = vim.fn.fnamemodify(dir or '.', ':p'):gsub('/$', '')
  local existing = Snacks.picker.get({ source = 'explorer' })[1]
  if existing then
    existing:set_cwd(abs)
    existing:find()
    existing:focus()
  else
    Snacks.explorer.open({ cwd = abs })
  end
end

--- Live grep, optionally restricted to `dir` (relative). <C-g> widens to the
--- parent directory, keeping the typed search.
function M.grep_in(dir, search)
  local dirs = dir and dir ~= '.' and dir ~= '' and { dir } or nil
  Snacks.picker.grep {
    dirs = dirs,
    search = search or '',
    title = dirs and ('Live Grep in ' .. dir) or 'Live Grep',
    prompt = '󰺮 > ',
    actions = {
      grep_parent = function(picker)
        local base = dirs and dir or vim.fn.fnamemodify(vim.fn.expand '%', ':.:h')
        local parent = vim.fn.fnamemodify(base, ':h')
        if parent == base then
          return
        end
        local q = picker.input:get()
        picker:close()
        reopen(function()
          M.grep_in(parent ~= '.' and parent or nil, q)
        end)
      end,
    },
    win = { input = { keys = { ['<C-g>'] = ikey 'grep_parent' } } },
  }
end

--- Actions shared by the buffers / recent pickers: act on the directory of the
--- item under the cursor.
M.cursor_dir_actions = {
  ctx_files_in_dir = function(picker)
    local dir = M.rel(picker:dir())
    picker:close()
    reopen(function()
      M.find_files_with_context(dir)
    end)
  end,
  ctx_files_top_dir = function(picker)
    local dir = M.rel(picker:dir())
    picker:close()
    reopen(function()
      M.find_files_with_context(nil, nil, nil, dir)
    end)
  end,
  ctx_explore_dir = function(picker)
    local dir = picker:dir()
    picker:close()
    reopen(function()
      M.explorer_at(dir)
    end)
  end,
}
M.cursor_dir_keys = {
  ['<C-Space>'] = ikey 'ctx_files_in_dir',
  ['<C-f>'] = ikey 'ctx_files_top_dir',
  ['<C-d>'] = ikey 'ctx_explore_dir',
}

---@param override_dir? string directory (relative) to treat as "current"
---@param override_query? string initial query
---@param suffix_priority? boolean rank by `file_name_suffixes`, filter files by the query as a glob
---@param override_top_dir? string restrict the search to this directory only
function M.find_files_with_context(override_dir, override_query, suffix_priority, override_top_dir)
  local vquery = M.visual_selection_or_nil()
  local query = override_query or vquery or ''

  local current_file = vim.fn.expand '%'
  local current_dir = override_dir or vim.fn.fnamemodify(current_file, ':.:h')
  local current_ext = vim.fn.fnamemodify(current_file, ':e')

  local top_dir = current_dir ~= '.' and vim.split(current_dir, '/')[1] or nil
  local top_dirs = (suffix_priority and query ~= '') and { 'app', 'db', 'spec', 'packs', 'jest' } or { 'app', 'packs' }
  if top_dir and not vim.tbl_contains(top_dirs, top_dir) then
    table.insert(top_dirs, top_dir)
  end

  local frontend_exts = { 'ts', 'tsx', 'js', 'jsx', 'html', 'htm', 'slim', 'haml', 'erb' }
  local include_styles = vim.tbl_contains(frontend_exts, current_ext)
  local exclude
  if include_styles then
    exclude = { '*.html', '*.htm', '*.slim', '*.haml', '*.erb' }
    top_dirs = { 'app', 'jest', 'packs' }
  else
    exclude = { '*.css', '*.scss' }
  end
  local glob = (suffix_priority and query ~= '') and ('*' .. query .. '*') or nil
  if override_top_dir then
    top_dirs = { override_top_dir }
  end
  -- rg fails on missing directories; fall back to the whole cwd when none exist
  top_dirs = vim.tbl_filter(dir_exists, top_dirs)

  local on_match, info = M.context_on_match {
    current_dir = current_dir,
    current_ext = current_ext,
    suffix_priority = suffix_priority,
  }

  local keys = {
    ['<C-g>'] = ikey 'ctx_parent_dir',
    ['<C-r>'] = ikey 'ctx_grep_here',
    ['<C-d>'] = ikey 'ctx_explore_here',
    ['<C-f>'] = ikey 'ctx_focus_dir',
  }
  if suffix_priority then
    keys['<C-Space>'] = ikey 'ctx_fuzzy_mode'
  end

  Snacks.picker.files {
    cwd = vim.fn.getcwd(),
    dirs = #top_dirs > 0 and top_dirs or nil,
    exclude = exclude,
    glob = glob,
    pattern = (not suffix_priority) and query or (vquery or ''),
    title = current_dir .. '/',
    prompt = ((suffix_priority and query ~= '') and ('[' .. query .. '] ') or ' ') .. current_dir .. '/ ',
    layout = { preview = false },
    matcher = { sort_empty = true, on_match = on_match },
    format = M.context_format(info, suffix_priority, query),
    actions = {
      ctx_parent_dir = function(picker)
        local parent = vim.fn.fnamemodify(current_dir, ':h')
        if parent == current_dir then
          return
        end
        picker:close()
        reopen(function()
          M.find_files_with_context(parent, override_query, suffix_priority, override_top_dir)
        end)
      end,
      ctx_grep_here = function(picker)
        picker:close()
        reopen(function()
          M.grep_in(current_dir)
        end)
      end,
      ctx_explore_here = function(picker)
        picker:close()
        reopen(function()
          M.explorer_at(current_dir)
        end)
      end,
      ctx_focus_dir = function(picker)
        local typed = picker.input:get()
        picker:close()
        reopen(function()
          if typed and typed ~= '' then
            M.find_files_with_context(current_dir, typed, true)
          elseif override_top_dir and override_top_dir ~= '' then
            M.find_files_with_context(current_dir, nil, nil, nil)
          else
            M.find_files_with_context(current_dir, nil, nil, current_dir)
          end
        end)
      end,
      ctx_fuzzy_mode = function(picker)
        picker:close()
        reopen(function()
          M.find_files_with_context(current_dir, query, false)
        end)
      end,
    },
    win = { input = { keys = keys } },
  }
end

--- Files added/changed on this branch compared to origin/HEAD, with the
--- branch diff as preview (replaces the Easypick `changed_files` picker).
function M.changed_files()
  local base = (vim.fn.systemlist('git rev-parse --abbrev-ref origin/HEAD')[1] or ''):gsub('^origin/', '')
  if vim.v.shell_error ~= 0 or base == '' then
    vim.notify('Could not resolve origin/HEAD', vim.log.levels.WARN)
    return
  end
  Snacks.picker {
    source = 'changed_files',
    title = 'Git changed files (vs ' .. base .. ')',
    layout = { preset = 'ivy' },
    format = 'file',
    finder = function(opts, ctx)
      return require('snacks.picker.source.proc').proc(
        ctx:opts {
          cmd = 'sh',
          args = {
            '-c',
            'git log --diff-filter=ACM --name-only --pretty=format: origin/HEAD..HEAD | sort -u | grep -v "^$"',
          },
          transform = function(item)
            item.file = item.text
          end,
        },
        ctx
      )
    end,
    preview = function(ctx)
      return Snacks.picker.preview.cmd({ 'git', 'diff', base .. '...HEAD', '--', ctx.item.file }, ctx, { ft = 'diff' })
    end,
  }
end

--- Files under `dir` (e.g. ".gist", "doc"); <CR> opens them in the second tab,
--- creating it when needed.
function M.doc_dir_files(dir, opts)
  Snacks.picker.files {
    dirs = { dir },
    title = opts.title,
    prompt = opts.prefix,
    layout = { preview = false },
    confirm = function(picker, item)
      picker:close()
      if not item then
        return
      end
      local filepath = Snacks.picker.util.path(item)
      reopen(function()
        local tabs = vim.api.nvim_list_tabpages()
        if #tabs >= 2 then
          vim.api.nvim_set_current_tabpage(tabs[2])
          vim.cmd('edit ' .. vim.fn.fnameescape(filepath))
        else
          vim.cmd('tabnew ' .. vim.fn.fnameescape(filepath))
        end
      end)
    end,
  }
end

return M
