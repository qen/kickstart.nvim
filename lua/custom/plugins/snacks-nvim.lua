-- vim.keymap.set('t', '<A-Escape>', '<C-\\><C-N>', { desc = 'Escape terminal mode', noremap = true, silent = true })
vim.keymap.set('t', '<C-u>', '<C-\\><C-n><C-u>', { desc = 'Scroll up in terminal' })
vim.keymap.set('t', '<C-d>', '<C-\\><C-n><C-d>', { desc = 'Scroll down in terminal' })
local function toggle_terminal_focus()
  local cur_buf = vim.api.nvim_get_current_buf()
  local in_terminal = vim.bo[cur_buf].buftype == 'terminal'
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    local is_term = vim.bo[buf].buftype == 'terminal'
    if in_terminal and not is_term then
      vim.api.nvim_set_current_win(win)
      return
    elseif not in_terminal and is_term then
      vim.api.nvim_set_current_win(win)
      vim.cmd('startinsert')
      return
    end
  end
end
vim.keymap.set({ 'n' }, '<C-SPACE>', toggle_terminal_focus, { desc = 'Toggle focus between terminal and editor' })
vim.keymap.set({ 't' }, '<C-SPACE>', '<C-\\><C-n>', { desc = 'Escape to normal mode' })

-- vim.keymap.set('t', '<C-w>', '<C-\\><C-n><C-w>', { desc = 'Focus on up window' })

-- vim.keymap.set('t', '<D-v>', function()
--   local clip = vim.fn.getreg('+')
--   vim.api.nvim_chan_send(vim.b.terminal_job_id, clip)
-- end, { noremap = true })

-- vim.keymap.set('t', '<Escape-Escape>', "<C-\\><C-N>", { desc = 'Exit terminal mode', noremap = true, silent = true })
-- vim.keymap.set('t', '<A-`>', "<C-\\><C-N><C-w>h", { desc = 'move focus to window left', noremap = true, silent = true })
-- vim.keymap.set('t', '<A-\\>', "<C-\\><C-N><C-w>h<eader>ac", { desc = 'toggle claudecode in terminal', noremap = true, silent = true })

-- vim.keymap.set('n', '<A-1>', ':let @*=expand("%")..":"..line(".")<CR>', { desc = 'Copy file path line number to clipboard' })
local fidget = require('fidget')

local _a1_migrate_cycle = 0

vim.keymap.set('n', '<A-1>', function()
  local file = vim.fn.fnamemodify(vim.fn.expand("%"), ':.')
  local text

  if file:match('db/migrate/') then
    if _a1_migrate_cycle == 0 then
      text = file
      _a1_migrate_cycle = 1
    else
      text = vim.fn.fnamemodify(file, ':t'):match('^(%d+)') or file
      _a1_migrate_cycle = 0
    end
  else
    text = file
    _a1_migrate_cycle = 0
  end

  vim.fn.setreg("+", text)
  fidget.notify('', vim.log.levels.INFO, { annote = text })
end, { desc = 'Copy file path line number to clipboard' })

-- vim.keymap.set('n', '<A-2>', function()
--   local branch_name = vim.fn.system('git branch --show-current'):gsub("\n", "")
--   vim.fn.setreg("+", branch_name)
--   vim.notify('Copy to clipboard: '..branch_name, vim.log.levels.INFO)
-- end, { desc = 'Copy branch name to clipboard' })

local term_fullscreen = false

-- Track terminal shell cwd via OSC 7 and update winbar
-- vim.api.nvim_create_autocmd("TermRequest", {
--   callback = function(args)
--     if type(args.data) ~= "string" then return end
--     local dir = args.data:match("^]7;file://[^/]*(/.+)")
--     if dir then
--       dir = dir:gsub("%%(%x%x)", function(hex) return string.char(tonumber(hex, 16)) end)
--       vim.b[args.buf].term_cwd = dir
--       vim.cmd("redrawstatus!")
--     end
--   end,
-- })

return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
    bigfile = { enabled = true },
    dashboard = { enabled = false },
    explorer = { enabled = true },
    indent = { enabled = false },
    input = { enabled = true },
    picker = { enabled = true },
    notifier = { enabled = true },
    quickfile = { enabled = true },
    scope = { enabled = true },
    scroll = { enabled = false },
    -- scroll = {
    --   enabled = true,
    --   filter = function(buf)
    --     return vim.api.nvim_buf_line_count(buf) < 1000
    --   end,
    -- },
    statuscolumn = { enabled = true },
    image = { enabled = false },
    words = { enabled = true },
    terminal = {},
  },
  keys = {
    { "<A-`>", function()
      -- local git_branch_name = vim.fn.system('git branch --show-current'):gsub("\n", "")
      -- local git_branch_status = vim.fn.system('git status --porcelain'):gsub("\n", "")
      vim.g.snacks_git_summary = MiniStatusline.section_git { trunc_width = 70 }
      -- local snacks_git_summary = MiniStatusline.section_git { trunc_width = 70 }
      -- local title = branch ~= "" and ("  " .. branch .. " ") or " Terminal "

      -- local git_summary = MiniStatusline.section_git { trunc_width = 70 }
      -- -- Refresh snacks_git_summary on all terminal buffers
      -- for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      --   if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == 'terminal' and vim.b[buf].snacks_git_summary then
      --     vim.b[buf].snacks_git_summary = git_summary
      --   end
      -- end

      Snacks.terminal(nil, {
        env = { DRACULA_DISPLAY_GIT = "0" },
        win = {
          b = {
            -- snacks_term_title = '' .. title,
            snacks_git_summary = MiniStatusline.section_git { trunc_width = 70 }
          },
          -- term_title = title,
          keys = {
            hide = {
              "<A-`>",
              function(self) self:hide() end,
              mode = "t",
              desc = "Hide Terminal",
            },
            close = {
              "<A-ESC>",
              function(self) self:close() end,
              mode = "t",
              desc = "Close Terminal",
            },
            -- switch_to_editor = {
            --   -- "<C-\\>",
            --   "<C-SPACE>",
            --   '<C-\\><C-n>',
            --   mode = "t",
            --   desc = "switch to editor top window"
            -- },
            toggle_fullscreen = {
              "<A-z>",
              function(self)
                term_fullscreen = not term_fullscreen
                if term_fullscreen then
                  vim.api.nvim_win_set_config(self.win, {
                    relative = "editor",
                    width = vim.o.columns,
                    height = vim.o.lines - 1,
                    row = 0,
                    col = 0,
                  })
                else
                  local width = math.floor(vim.o.columns * 1)
                  local height = math.floor(vim.o.lines * 0.4)
                  vim.api.nvim_win_set_config(self.win, {
                    relative = "editor",
                    width = width,
                    height = height,
                    row = vim.o.lines - height - 2,
                    col = math.floor((vim.o.columns - width) / 2),
                  })
                end
              end,
              mode = "t",
              desc = "Toggle Terminal Fullscreen"
            },
            rspec_file_line = {
              "<A-1>",
              function(_self)
                local text = nil

                for _, win in ipairs(vim.api.nvim_list_wins()) do
                  local buf = vim.api.nvim_win_get_buf(win)
                  local buftype = vim.bo[buf].buftype
                  if buftype ~= 'terminal' then
                    local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ':.')
                    if name:match('_spec%.rb$') then
                      local cursor = vim.api.nvim_win_get_cursor(win)
                      text = 'bundle exec rspec ' .. name .. ':' .. cursor[1]
                    elseif name:match('test%.js$') then
                      text = 'yarn test ' .. name
                    else
                      text = name
                    end
                    break
                  end
                end

                vim.fn.setreg("+", text)
                fidget.notify('', vim.log.levels.INFO, { annote = text })
              end,
              mode = "t",
              desc = "Copy current file and line to clipboard"
            },
            current_git_branch = {
              "<A-2>",
              function(_self)
                local branch_name = vim.fn.system('git branch --show-current'):gsub("\n", "")
                vim.fn.setreg("+", branch_name)
                fidget.notify('', vim.log.levels.INFO, { annote = branch_name })
              end,
              mode = "t",
              desc = "Copy current branch to clipboard"
            }
          },
        },
      })
    end, desc = "Toggle Terminal" },
    -- { "<A-r>", function()
    --   Snacks.terminal(
    --     "bundle exec rails console",
    --     {
    --       env = { DRACULA_DISPLAY_GIT = "0" },
    --       win = {
    --         b = { snacks_term_title = 'bundle exec rails console' },
    --         position = "bottom",
    --         -- width = 0.4,
    --         height = 0.4,
    --         border = "rounded",
    --         title = " Rails Console ",
    --         title_pos = "center",
    --         keys = {
    --           hide = {
    --             "<A-r>",
    --             function(self) self:hide() end,
    --             mode = "t",
    --             desc = "Hide Rails Console",
    --           },
    --         },
    --       }
    --     }
    --   )
    -- end, desc = "Rails Console" }
  }
}
