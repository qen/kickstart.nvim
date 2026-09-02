return { -- blink.cmp: Autocompletion (replaces nvim-cmp + LuaSnip)
  'saghen/blink.cmp',
  version = '1.*', -- pulls the prebuilt fuzzy-matcher binary
  event = 'InsertEnter',
  opts = {
    keymap = {
      -- 'default' already gives: <C-n>/<C-p> select, <C-y> accept, <C-Space> show,
      -- <C-e> hide, <C-b>/<C-f> scroll docs, <C-k> signature
      preset = 'default',
      ['<C-l>'] = { 'snippet_forward', 'fallback' },
      ['<C-h>'] = { 'snippet_backward', 'fallback' },
    },
    appearance = {
      nerd_font_variant = 'mono',
    },
    completion = {
      -- matches the old nvim-cmp `completeopt = menu,menuone,noinsert`:
      -- first item preselected, nothing inserted until <C-y>
      list = { selection = { preselect = true, auto_insert = false } },
      documentation = { auto_show = true, auto_show_delay_ms = 200 },
      -- adds `(` after accepting a function, replaces the nvim-autopairs cmp hook
      accept = { auto_brackets = { enabled = true } },
    },
    sources = {
      default = { 'lazydev', 'lsp', 'path', 'snippets' },
      providers = {
        lazydev = {
          name = 'LazyDev',
          module = 'lazydev.integrations.blink',
          score_offset = 100, -- was group_index = 0 in nvim-cmp
        },
      },
    },
    snippets = { preset = 'default' }, -- native vim.snippet, no LuaSnip needed
    signature = { enabled = false },
    fuzzy = { implementation = 'prefer_rust_with_warning' },
  },
  opts_extend = { 'sources.default' },
}
