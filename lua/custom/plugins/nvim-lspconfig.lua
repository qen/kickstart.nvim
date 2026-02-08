-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
-- NOTE: LSP Plugins
return { -- nvm-lsconfig: Main LSP Configuration, :LspStop to stop language server
  'neovim/nvim-lspconfig',
  dependencies = {
    -- Automatically install LSPs and related tools to stdpath for Neovim
    -- Mason must be loaded before its dependents so we need to set it up here.
    -- NOTE: `opts = {}` is the same as calling `require('mason').setup({})`
    { 'williamboman/mason.nvim', opts = {} },
    'williamboman/mason-lspconfig.nvim',
    'WhoIsSethDaniel/mason-tool-installer.nvim',

    -- Useful status updates for LSP.
    { 'j-hui/fidget.nvim', opts = {} },

    -- Allows extra capabilities provided by nvim-cmp
    'hrsh7th/cmp-nvim-lsp',
  },
  opts = {
    -- add any global capabilities here
    capabilities = {},
    -- Automatically format on save
    autoformat = false,
    -- options for vim.lsp.buf.format
    -- `bufnr` and `filter` is handled by the LazyVim formatter,
    -- but can be also overridden when specified
    format = {
      formatting_options = nil,
      timeout_ms = nil,
    },
  },
  config = function()
    -- === LspAttach helpers and keymaps (unchanged) ===
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
      callback = function(event)
        local map = function(keys, func, desc, mode)
          mode = mode or 'n'
          vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
        end

        map('gd', function() require('telescope.builtin').lsp_definitions { show_line = false } end, '[G]oto [D]efinition')
        map('gr', function() require('telescope.builtin').lsp_references  { show_line = false } end, '[G]oto [R]eferences')
        map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
        map('<leader>tc', vim.lsp.buf.code_action, '[T]oggle [C]ode Action', { 'n','x' })
        map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
        map('\\r', vim.lsp.buf.rename, '[R]ename')
        map('\\\\', require('telescope.builtin').lsp_document_symbols, 'Document [S]ymbols')
        map('\\<ENTER>', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'Workspace [S]ymbols')

        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
          local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
          vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, { buffer = event.buf, group = highlight_augroup, callback = vim.lsp.buf.document_highlight })
          vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, { buffer = event.buf, group = highlight_augroup, callback = vim.lsp.buf.clear_references })
          vim.api.nvim_create_autocmd('LspDetach', {
            group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
            callback = function(event2)
              vim.lsp.buf.clear_references()
              vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
            end,
          })
        end

        if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
          map('<leader>th', function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
          end, '[T]oggle Inlay [H]ints')
        end
      end,
    })

    -- === Capabilities (cmp) ===
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

    -- === Server definitions ===
    local servers = {
      lua_ls = {
        settings = {
          Lua = {
            completion = { callSnippet = 'Replace' },
            -- diagnostics = { disable = { 'missing-fields' } },
          },
        },
      },

      -- Emmet
      emmet_language_server = {
        enabled = vim.g.run_javascript_lsp,
        filetypes = { 'css','eruby','html','htmldjango','javascriptreact','less','pug','sass','scss','typescriptreact','htmlangular' },
      },

      -- Biome (JS/TS/etc)
      biome = {
        enabled = vim.g.run_javascript_lsp,
        cmd = { 'biome', 'lsp-proxy' },
        filetypes = { 'astro','css','graphql','javascript','javascriptreact','json','jsonc','svelte','typescript','typescript.tsx','typescriptreact','vue' },
      },

      -- TypeScript
      ts_ls = {
        enabled = vim.g.run_javascript_lsp,
        cmd = { 'typescript-language-server', '--stdio' },
        filetypes = { 'javascript','javascriptreact','typescript','typescript.tsx','typescriptreact','vue' },
      },
    }

    -- === ruby_lsp via project binstub or bundle exec ===

    vim.lsp.config('ruby_lsp', {
      enabled = vim.g.run_ruby_lsp,
      filetypes = { 'ruby' },
      root_markers = { 'Gemfile', '.git' },
      single_file_support = false,
      init_options = {
        formatter = "none",
        linters = {},               -- let rubocop-lsp or null-ls do it, or nothing
        enabledFeatures = {         -- only keep what you use
          "codeActions",
          "codeLens",
          "completion",
          "definition",
          "diagnostics",
          "documentHighlights",
          "documentLink",
          "documentSymbols",
          "foldingRanges",
          "formatting",
          "hover",
          "inlayHint",
          -- "onTypeFormatting",
          "selectionRanges",
          "semanticHighlighting",
          "signatureHelp",
          "typeHierarchy",
          "workspaceSymbol"
        },
      },
      on_new_config = function(config, root_dir)
        -- NOTE: to initialize .ruby-lsp/Gemfile
        -- rvm use
        -- gem install ruby-lsp
        -- ruby-lsp

        -- local bin = root_dir .. '/bin/ruby-lsp'
        -- if (vim.uv or vim.loop).fs_stat(bin) then
        --   config.cmd = { bin }
        --   config.cmd_env = nil
        -- else
        --   config.cmd = { 'bundle', 'exec', 'ruby-lsp' }
        --   config.cmd_env = { BUNDLE_GEMFILE = root_dir .. '/Gemfile' }
        -- end

        -- local ruby_lsp_gemfile = vim.fn.getenv("RUBY_LSP_GEMFILE")
        -- if ruby_lsp_gemfile == vim.NIL or ruby_lsp_gemfile == "" then
        --   -- bundle install --gemfile=~/.ruby-lsp/Gemfile
        --   ruby_lsp_gemfile = "~/.ruby-lsp/Gemfile"
        -- end

        local ruby_lsp_gemfile = root_dir .. '/.ruby-lsp/Gemfile'
        if (vim.uv or vim.loop).fs_stat(ruby_lsp_gemfile) then
          config.cmd_env = { BUNDLE_GEMFILE = ruby_lsp_gemfile }
        else
          config.cmd_env = { BUNDLE_GEMFILE = root_dir .. '/Gemfile' }
        end

        config.cmd = { 'bundle', 'exec', 'ruby-lsp' }
      end,
    })

    -- === Ensure tools via Mason (but never ruby-lsp) ===
    local ensure_installed = vim.tbl_keys(servers or {})
    ensure_installed = vim.tbl_filter(function(name) return name ~= 'ruby_lsp' end, ensure_installed)
    vim.list_extend(ensure_installed, { 'stylua' })
    require('mason-tool-installer').setup({ ensure_installed = ensure_installed })

    -- If you still use mason-lspconfig for registry, keep it minimal (no handlers calling lspconfig)
    require('mason-lspconfig').setup({})

    -- === Register & enable each server with the new API ===
    for name, cfg in pairs(servers) do
      -- honor `enabled = false/nil` pattern
      if cfg.enabled == nil or cfg.enabled then
        cfg.capabilities = vim.tbl_deep_extend('force', {}, capabilities, cfg.capabilities or {})
        vim.lsp.config(name, cfg)
        vim.lsp.enable(name)
      end
    end

    -- ruby_lsp is configured above; just enable it if requested
    if vim.g.run_ruby_lsp then
      vim.lsp.enable('ruby_lsp')
    end
  end
}

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
