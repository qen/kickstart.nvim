-- Stop all LSP clients after N minutes of inactivity.
-- Re-enable manually via :LspIdleStart (bind to a shortcut if desired).
return {
  dir = vim.fn.stdpath('config'),
  name = 'lsp-idle-stop',
  event = 'VeryLazy',
  config = function()
    local idle_ms = 30 * 60 * 1000
    local check_interval_ms = 60 * 1000

    local last_activity = vim.uv.now()
    local stopped = false

    local group = vim.api.nvim_create_augroup('lsp-idle-stop', { clear = true })

    -- vim.keymap.set('n', 'g\\', '<cmd>LspIdleStart<cr>', { desc = 'LSP: start' })
    vim.keymap.set('n', 'g\\', '<cmd>LspStart ruby_lsp<cr>', { desc = 'LSP: start' })

    vim.api.nvim_create_autocmd(
      { 'CursorMoved', 'CursorMovedI', 'TextChanged', 'TextChangedI', 'InsertEnter', 'BufEnter', 'FocusGained' },
      {
        group = group,
        callback = function()
          last_activity = vim.uv.now()
        end,
      }
    )

    local function stop_all_lsp()
      local clients = vim.lsp.get_clients()
      if #clients == 0 then return 0 end
      for _, c in ipairs(clients) do
        pcall(vim.lsp.stop_client, c.id, false)
      end
      return #clients
    end

    local function reattach_all_buffers()
      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if
          vim.api.nvim_buf_is_loaded(bufnr)
          and vim.bo[bufnr].buflisted
          and vim.bo[bufnr].filetype ~= ''
        then
          vim.api.nvim_exec_autocmds('FileType', { buffer = bufnr })
        end
      end
    end

    local timer = vim.uv.new_timer()
    timer:start(check_interval_ms, check_interval_ms, vim.schedule_wrap(function()
      if stopped then return end
      if (vim.uv.now() - last_activity) >= idle_ms then
        local n = stop_all_lsp()
        stopped = true
        if n > 0 then
          vim.notify(
            ('LSP: stopped %d client(s) after %d min idle'):format(n, math.floor(idle_ms / 60000)),
            vim.log.levels.INFO
          )
        end
      end
    end))

    vim.api.nvim_create_autocmd('VimLeavePre', {
      group = group,
      callback = function()
        if timer and not timer:is_closing() then
          timer:stop()
          timer:close()
        end
      end,
    })

    vim.api.nvim_create_user_command('LspIdleStopNow', function()
      local n = stop_all_lsp()
      stopped = true
      vim.notify(('LSP: stopped %d client(s)'):format(n))
    end, {})

    vim.api.nvim_create_user_command('LspIdleStart', function()
      stopped = false
      last_activity = vim.uv.now()
      reattach_all_buffers()
      vim.notify('LSP: reattaching clients')
    end, {})

    vim.api.nvim_create_user_command('LspIdleStatus', function()
      local idle_min = (vim.uv.now() - last_activity) / 60000
      vim.notify(('LSP idle: %.1f min, stopped=%s'):format(idle_min, tostring(stopped)))
    end, {})
  end,
}

-- vim: ts=2 sts=2 sw=2 et
