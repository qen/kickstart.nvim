local M = {}

-- True when nvim is launched during an active merge:
--   - started in diff mode (`nvim -d`, `git mergetool`)
--   - cwd is inside a repo with .git/MERGE_HEAD present
function M.in_git_merge_mode()
  for _, arg in ipairs(vim.v.argv or {}) do
    if arg == '-d' then
      return true
    end
  end

  local git_dir = vim.fn.finddir('.git', vim.fn.getcwd() .. ';')
  if git_dir ~= '' then
    local uv = vim.uv or vim.loop
    if uv.fs_stat(git_dir .. '/MERGE_HEAD') then
      return true
    end
  end

  return false
end

return M
