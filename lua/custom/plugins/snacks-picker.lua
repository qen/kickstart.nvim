-- snacks.picker: replaces telescope.nvim (+ fzf-native, ui-select, file-browser,
-- easypick). Keys are unchanged; the context-aware ranking lives in
-- lua/custom/find-files.lua. This spec is merged by lazy.nvim with the main
-- snacks spec in snacks-nvim.lua.
local ff = require 'custom.find-files'

local doc_dirs = {
  { name = '.gist', key = '<leader>smg', title = 'Find Gist Files', prefix = ' gist/', desc = 'Search files in gist folder' },
  { name = 'doc', key = '<leader>smd', title = 'Find Doc Files', prefix = ' doc/', desc = 'Search files in doc folder' },
}

local function wide()
  return vim.o.columns >= 215
end

local keys = {
  -- Peek helpers
  { '<leader>ph', function() Snacks.picker.help() end, desc = 'Peek [H]elp' },
  { '<leader>pk', function() Snacks.picker.keymaps() end, desc = 'Peek [K]eymaps' },
  { '<leader>pt', function() Snacks.picker.pickers() end, desc = 'Peek Select [T]elescope' },
  { '<leader>pn', function() Snacks.picker.files { cwd = vim.fn.stdpath 'config' } end, desc = 'Peek [N]eovim files' },
  { '<leader>pd', function() Snacks.picker.diagnostics() end, desc = 'Peek [D]iagnostics' },

  -- File navigation
  {
    '<TAB><TAB>',
    function()
      local on_match, _ = ff.context_on_match()
      Snacks.picker.recent {
        filter = { cwd = true },
        title = 'Files opened history',
        prompt = '󱋢 > ',
        layout = not wide() and { preview = false } or nil,
        matcher = { sort_empty = true, on_match = on_match },
        actions = ff.cursor_dir_actions,
        win = { input = { keys = ff.cursor_dir_keys } },
      }
    end,
    desc = 'Recent Files',
  },
  {
    '<TAB>o',
    function()
      Snacks.picker.buffers {
        title = 'Files opened',
        prompt = ' > ',
        sort_lastused = true,
        layout = not wide() and { preview = false } or nil,
        actions = ff.cursor_dir_actions,
        win = { input = { keys = ff.cursor_dir_keys } },
      }
    end,
    desc = 'Find Opened Files',
  },
  { '<leader>sd', function() ff.explorer_at(vim.fn.expand '%:p:h') end, desc = 'Search Browse buffer [D]irectory' },
  { '<leader>sw', function() ff.explorer_at(vim.fn.getcwd()) end, desc = 'Search Browse <c[w]d>irectory' },
  { '<leader>sc', ff.changed_files, desc = 'Search Git [C]hanged files' },
  { '<leader>`', function() Snacks.picker.resume() end, desc = 'Search again' },

  -- Search
  {
    '<leader>sr',
    function() ff.grep_in(nil, ff.visual_selection_or_nil()) end,
    mode = { 'n', 'v' },
    desc = 'Search [R]ipgrep Word selection',
  },
  {
    '<leader><leader>',
    function() ff.find_files_with_context() end,
    mode = { 'n', 'v' },
    desc = 'Search [F]iles in app, packs, and current directories',
  },
  {
    '<leader>sf',
    function() ff.find_files_with_context(nil, ff.similar_document_name(), true) end,
    mode = { 'n', 'v' },
    desc = 'Search similar [N]ame on app folders',
  },
  { '<leader>ss', function() Snacks.picker.lines() end, desc = '[ ] Fuzzily search in current buffer' },
  { '<leader>s<TAB>', function() Snacks.picker.grep_buffers { title = 'Live Grep in Open Files' } end, desc = '[S]earch [/] in Open Files' },
}

for _, dir in ipairs(doc_dirs) do
  local stat = (vim.uv or vim.loop).fs_stat(vim.fn.getcwd() .. '/' .. dir.name)
  if stat and stat.type == 'directory' then
    table.insert(keys, { dir.key, function() ff.doc_dir_files(dir.name, dir) end, desc = dir.desc })
  end
end

return {
  'folke/snacks.nvim',
  opts = {
    picker = {
      ui_select = true, -- replaces telescope-ui-select
      -- The custom context ranking (recent + current-dir + Rails-aware) is applied
      -- per picker via `matcher.on_match`; snacks' own bonuses stay off so the two
      -- don't double-weight. Flip these on if you ever drop the custom ranking.
      matcher = { frecency = false, cwd_bonus = false, history_bonus = false },
      sources = {
        explorer = {
          -- same keys the telescope file browser had, acting on the directory
          -- of the entry under the cursor
          actions = {
            explorer_grep_here = function(picker)
              local dir = ff.rel(picker:dir())
              picker:close()
              vim.schedule(function() ff.grep_in(dir) end)
            end,
            explorer_files_here = function(picker)
              local dir = ff.rel(picker:dir())
              picker:close()
              vim.schedule(function() ff.find_files_with_context(dir) end)
            end,
            explorer_files_top = function(picker)
              local dir = ff.rel(picker:dir())
              picker:close()
              vim.schedule(function() ff.find_files_with_context(nil, nil, nil, dir) end)
            end,
          },
          win = {
            list = {
              keys = {
                ['<C-r>'] = { 'explorer_grep_here', mode = { 'n', 'i' }, nowait = true },
                ['<C-Space>'] = { 'explorer_files_here', mode = { 'n', 'i' } },
                ['<C-f>'] = { 'explorer_files_top', mode = { 'n', 'i' } },
              },
            },
            input = {
              keys = {
                ['<C-r>'] = { 'explorer_grep_here', mode = { 'n', 'i' }, nowait = true },
                ['<C-Space>'] = { 'explorer_files_here', mode = { 'n', 'i' } },
                ['<C-f>'] = { 'explorer_files_top', mode = { 'n', 'i' } },
              },
            },
          },
        },
      },
    },
  },
  keys = keys,
  config = function(_, opts)
    require('snacks').setup(opts)

    -- highlight groups used by custom.find-files (same colours as before)
    vim.api.nvim_set_hl(0, 'CustomPickerCurrentDir', { fg = '#7aa2cc' })
    vim.api.nvim_set_hl(0, 'CustomPickerSuffixMatch', { fg = '#c0976b' })
    vim.api.nvim_set_hl(0, 'CustomPickerQueryBold', { fg = '#c0976b', bold = true })

    require('which-key').add {
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
      { '<leader>sr', icon = { icon = '󰺮', color = 'red' } },
      { '<leader>sw', icon = { icon = '', color = 'yellow' } },
      { '<leader>sm', group = '[S]earch Markdown directories', icon = { icon = '', color = 'white' } },
      { '<leader>smg', icon = { icon = '', color = 'red' } },
      { '<leader>smd', icon = { icon = '', color = 'white' } },
    }
  end,
}
