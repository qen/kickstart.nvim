-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
local group = vim.api.nvim_create_augroup('autosave', {})
vim.api.nvim_create_autocmd('User', {
  pattern = 'AutoSaveWritePost',
  group = group,
  callback = function(opts)
    if opts.data.saved_buffer ~= nil then
      local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(opts.data.saved_buffer), ':~:.')
      require('fidget').notify(' Autosave at ' .. vim.fn.strftime '%H:%M:%S', vim.log.levels.INFO, { group = group, annote = filename })
    end
  end,
})

-- vim.api.nvim_create_autocmd('ModeChanged', {
--   pattern = '*:[vV]', -- When entering any Visual mode
--   callback = function()
--     -- local bufnr = vim.api.nvim_get_current_buf()
--     -- require('auto-save').cancel_timer(bufnr)
--     -- require('auto-save').cancel_timer(vim.api.nvim_get_current_buf())
--     -- require('auto-save').off()
--   end,
-- })
--
-- vim.api.nvim_create_autocmd('ModeChanged', {
--   pattern = '[vV]:*', -- When exiting any Visual mode
--   callback = function()
--     -- local bufnr = vim.api.nvim_get_current_buf()
--     -- require('auto-save').defer_save(bufnr)
--     -- require('auto-save').on()
--   end,
-- })

return {
  'qen/auto-save.nvim',
  dependencies = {
    'j-hui/fidget.nvim',
    opts = {
      notification = {
        override_vim_notify = false,
      },
    },
  },
  cmd = 'ASToggle', -- optional for lazy loading on command
  event = { 'InsertLeave', 'TextChanged' }, -- optional for lazy loading on trigger events
  opts = {
    --
    -- All of these are just the defaults
    --
    enabled = false, -- start auto-save when the plugin is loaded (i.e. when your package manager loads it)
    trigger_events = { -- See :h events
      immediate_save = { 'BufLeave', 'FocusLost' }, -- vim events that trigger an immediate save
      defer_save = { 'InsertLeave', 'TextChanged', 'CursorMoved' }, -- vim events that trigger a deferred save (saves after `debounce_delay`)
      cancel_deferred_save = { 'InsertEnter' }, -- vim events that cancel a pending deferred save
    },
    -- function that takes the buffer handle and determines whether to save the current buffer or not
    -- return true: if buffer is ok to be saved
    -- return false: if it's not ok to be saved
    -- if set to `nil` then no specific condition is applied
    condition = function(buf)
      -- don't save for special-buffers
      if vim.fn.getbufvar(buf, '&buftype') ~= '' then
        return false
      end
      -- -- don't save if in visual mode
      -- local mode = vim.api.nvim_get_mode().mode
      -- if mode == 'v' or mode == 'V' or mode == '\22' then
      --   return false
      -- end
      return true
    end,
    write_all_buffers = false, -- write all buffers when the current one meets `condition`
    -- Do not execute autocmds when saving
    -- This is what fixed the issues with undo/redo that I had
    -- https://github.com/okuuva/auto-save.nvim/issues/55
    noautocmd = false,
    lockmarks = false, -- lock marks when saving, see `:h lockmarks` for more details
    -- delay after which a pending save is executed (default 1000)
    debounce_delay = 3000,
    -- log debug messages to 'auto-save.log' file in neovim cache directory, set to `true` to enable
    debug = false,
  },
}
