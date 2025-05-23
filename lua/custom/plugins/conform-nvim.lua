-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
-- NOTE: LSP Plugins
return { -- conform: Autoformat
  'stevearc/conform.nvim',
  -- INFO: enabled plugin
  enabled = true,
  -- INFO: enabled plugin
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  keys = {
    {
      '\\f',
      function()
        require('conform').format { async = true, lsp_format = 'fallback' }
      end,
      mode = '',
      desc = '[F]ormat buffer',
    },
  },
  opts = {
    notify_on_error = false,
    format_on_save = false,
    -- format_on_save = function(bufnr)
    --   -- Disable "format_on_save lsp_fallback" for languages that don't
    --   -- have a well standardized coding style. You can add additional
    --   -- languages here or re-enable it for the disabled ones.
    --   local disable_filetypes = { c = true, cpp = true }
    --   local lsp_format_opt
    --
    --   if disable_filetypes[vim.bo[bufnr].filetype] then
    --     lsp_format_opt = 'never'
    --   else
    --     lsp_format_opt = 'fallback'
    --   end
    --   return {
    --     timeout_ms = 500,
    --     lsp_format = lsp_format_opt,
    --   }
    -- end,
    formatters_by_ft = {
      lua = { 'stylua' },
      ruby = { 'rubocop' },
      -- Conform can also run multiple formatters sequentially
      -- python = { "isort", "black" },
      --
      -- You can use 'stop_after_first' to run the first available formatter from the list
      javascript = { 'prettierd', 'prettier', stop_after_first = true },
      eruby = { 'prettier_html', stop_after_first = true },
      html = { 'prettier_html', stop_after_first = true },
      json = { 'jq' },
      jsonc = { 'prettier_jsonc' },
    },
    formatters = {
      prettier_html = {
        command = 'prettier',
        args = {
          '--stdin-filepath', '$FILENAME',
          '--parser', 'html',
          '--html-whitespace-sensitivity', 'ignore',
          '--tab-width', '2',
          '--trailing-comma', 'es5',
          '--bracket-same-line', 'false',
          '--single-attribute-per-line', 'true'
        },
        stdin = true,
      },
      jq = {
        command = 'jq',
        args = { '.' },
        stdin = true,
      },
      prettier_jsonc = {
        command = 'prettier',
        args = { '--stdin-filepath', '$FILENAME', '--parser', 'json' },
        stdin = true,
      },
      -- WARN: issue for globally installed prettier
      -- npm i -g prettier @prettier/plugin-ruby
      -- prettier_erb = {
      --   command = 'prettier',
      --   args = {
      --     '--stdin-filepath', '$FILENAME',
      --     '--html-whitespace-sensitivity', 'ignore',
      --     '--tab-width', '2',
      --     '--trailing-comma', 'es5',
      --     '--bracket-same-line', 'false',
      --     '--single-attribute-per-line', 'true'
      --   },
      --   stdin = true,
      -- },
      rubocop = {
        command = 'bundle',
        args = {
          'exec',
          'rubocop',
          '--auto-correct',
          '--except',
          'List/UselessAssignment',
          'List/UnusedMethodArgument',
          '--stdin',
          '$FILENAME',
          '--format',
          'files',
        },
        stdin = true,
      },
    },
  },
}

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
