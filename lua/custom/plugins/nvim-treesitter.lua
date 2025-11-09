-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return { -- nvim-treesitter: Highlight, edit, and navigate code
  'nvim-treesitter/nvim-treesitter',
  dependencies = { 'nvim-treesitter/nvim-treesitter-refactor' },
  build = ':TSUpdate',
  main = 'nvim-treesitter.configs', -- Sets main module to use for opts
  enabled = true,
  -- [[ Configure Treesitter ]] See `:help nvim-treesitter`
  opts = {
    ensure_installed = { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc', 'sql' },
    -- Autoinstall languages that are not installed
    auto_install = true,
    highlight = {
      enable = true,
      -- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
      --  If you are experiencing weird indenting issues, add the language to
      --  the list of additional_vim_regex_highlighting and disabled languages for indent.
      additional_vim_regex_highlighting = { 'ruby' },
    },
    indent = { enable = true, disable = { 'ruby' } },
    refactor = {
      highlight_definitions = {
        enable = false,
        -- Set to false if you have an `updatetime` of ~100.
        clear_on_cursor_move = true,
      },
      highlight_current_scope = { enable = false },
      smart_rename = {
        enable = true,
        keymaps = {
          smart_rename = 'gR',
        },
      },
      navigation = {
        enable = true,
        keymaps = {
          goto_definition = 'gd',
          list_definitions = 'gD',
          list_definitions_toc = 'gO',
          goto_next_usage = 'gn',
          goto_previous_usage = 'gp',
        },
      },
    },
  },
  config = function(_, opts)
    require("nvim-treesitter.configs").setup(opts)
    -- -- >>> Force comment color (TS + legacy), and re-apply after theme/TS reloads
    -- local COLOR = "#ff0000" -- change me
    --
    -- local function apply_comment_color()
    --   -- Tree-sitter (all langs)
    --   vim.api.nvim_set_hl(0, "@comment", { fg = COLOR, italic = false })
    --   -- Tree-sitter (ruby-specific)
    --   vim.api.nvim_set_hl(0, "@comment.ruby", { fg = COLOR, italic = false })
    --   -- Legacy/fallback
    --   vim.api.nvim_set_hl(0, "Comment", { fg = COLOR, italic = false })
    -- end
    --
    -- -- apply once now
    -- apply_comment_color()
    --
    -- -- (re)apply after any colorscheme load
    -- local grp = vim.api.nvim_create_augroup("ForceRubyCommentColor", { clear = true })
    -- vim.api.nvim_create_autocmd("ColorScheme", {
    --   group = grp,
    --   callback = apply_comment_color,
    -- })
    --
    -- -- also reassert ruby-specific highlight on buffer/filetype switches
    -- vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
    --   group = grp,
    --   pattern = "ruby",
    --   callback = function()
    --     vim.api.nvim_set_hl(0, "@comment.ruby", { fg = COLOR, italic = false })
    --   end,
    -- })
    -- -- <<< end force color
  end

  --
  -- There are additional nvim-treesitter modules that you can use to interact
  -- with nvim-treesitter. You should go explore a few and see what interests you:
  --
  --    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
  --    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
  --    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
}

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
