-- nvim-ufo: folds that survive edits (replaces the TextChanged/BufWritePost
-- foldmethod toggling that used to live in init.lua). Provider is treesitter
-- with indent fallback, i.e. the same folds as before, just not recomputed on
-- every auto-save. Switch to { 'lsp', 'treesitter' } to use ruby-lsp folding ranges.
return {
  'kevinhwang91/nvim-ufo',
  dependencies = { 'kevinhwang91/promise-async' },
  lazy = false,
  keys = {
    -- zR/zM must go through ufo, otherwise they reset foldlevel under it
    { 'zR', function() require('ufo').openAllFolds() end, desc = 'Open all folds' },
    { 'zM', function() require('ufo').closeAllFolds() end, desc = 'Close all folds' },
  },
  opts = {
    provider_selector = function(_bufnr, _filetype, _buftype)
      return { 'treesitter', 'indent' }
    end,
    -- Reproduces the old custom_fold_text: "<line>: ⚡ N lines", but keeps the
    -- line's syntax highlighting instead of a flat Folded colour.
    fold_virt_text_handler = function(virt_text, lnum, end_lnum, width, truncate)
      local result = {}
      local suffix = (': ⚡ %d lines'):format(end_lnum - lnum + 1)
      local suffix_width = vim.fn.strdisplaywidth(suffix)
      local target_width = width - suffix_width
      local cur_width = 0
      for _, chunk in ipairs(virt_text) do
        local chunk_text = chunk[1]
        local chunk_width = vim.fn.strdisplaywidth(chunk_text)
        if target_width > cur_width + chunk_width then
          table.insert(result, chunk)
        else
          chunk_text = truncate(chunk_text, target_width - cur_width)
          table.insert(result, { chunk_text, chunk[2] })
          chunk_width = vim.fn.strdisplaywidth(chunk_text)
          if cur_width + chunk_width < target_width then
            suffix = suffix .. (' '):rep(target_width - cur_width - chunk_width)
          end
          break
        end
        cur_width = cur_width + chunk_width
      end
      table.insert(result, { suffix, 'Folded' })
      return result
    end,
  },
}
