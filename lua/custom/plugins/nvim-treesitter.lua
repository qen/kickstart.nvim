-- nvim-treesitter on the maintained `main` branch. The old `master` branch was
-- archived in May 2025 and no longer receives parser or query updates.
--
-- `main` has no `configs` module, no `ensure_installed` and no `auto_install`:
-- highlighting/indent are enabled per buffer from a FileType autocmd below,
-- and missing parsers are installed on first use.

-- Parsers that were installed under `master`, carried over. Not available on
-- `main` and therefore dropped: jsonc (json parser handles it), norg, robots, tmux.
local parsers = {
  'asm', 'bash', 'c', 'css', 'csv', 'diff', 'dockerfile', 'embedded_template',
  'git_config', 'git_rebase', 'gitcommit', 'gitignore', 'html', 'ini',
  'javascript', 'json', 'lua', 'luadoc', 'markdown', 'markdown_inline',
  'nginx', 'pem', 'perl', 'python', 'query', 'ruby', 'scss',
  'slim', 'sql', 'ssh_config', 'toml', 'tsx', 'typescript', 'vim',
  'vimdoc', 'xml', 'yaml',
}

-- Filetypes that keep Vim regex highlighting on top of treesitter
-- (was `highlight.additional_vim_regex_highlighting = { 'ruby' }`).
local regex_highlight = { ruby = true }

-- Filetypes that keep Vim's own indent rules (was `indent.disable = { 'ruby' }`).
local no_ts_indent = { ruby = true }

-- Checks the `main` install dir (stdpath('data')/site/parser), not the runtime
-- path, so stale parsers left behind by `master` are never mistaken for installed.
local function parser_installed(lang)
  return vim.tbl_contains(require('nvim-treesitter').get_installed(), lang)
end

return {
  'nvim-treesitter/nvim-treesitter',
  branch = 'main',
  lazy = false,
  build = ':TSUpdate',
  config = function()
    local ts = require 'nvim-treesitter'
    ts.setup {}

    local available = {}
    for _, lang in ipairs(ts.get_available()) do
      available[lang] = true
    end

    -- ensure_installed: install anything from the list that is missing
    local missing = vim.tbl_filter(function(lang)
      return available[lang] and not parser_installed(lang)
    end, parsers)
    if #missing > 0 then
      ts.install(missing)
    end

    local function enable(buf, lang)
      if not vim.api.nvim_buf_is_valid(buf) then
        return
      end
      local ok = pcall(vim.treesitter.start, buf, lang)
      if not ok then
        return
      end
      local ft = vim.bo[buf].filetype
      if regex_highlight[ft] then
        vim.bo[buf].syntax = ft
      end
      if not no_ts_indent[ft] then
        vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end
    end

    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('custom-treesitter', { clear = true }),
      desc = 'Enable treesitter highlight/indent, auto-installing the parser',
      callback = function(ev)
        local lang = vim.treesitter.language.get_lang(ev.match)
        if not lang or not available[lang] then
          return
        end
        if parser_installed(lang) then
          enable(ev.buf, lang)
        else
          -- auto_install
          ts.install({ lang }):await(function()
            enable(ev.buf, lang)
          end)
        end
      end,
    })
  end,
}
