vim.keymap.set('t', '<A-Escape>', "<C-\\><C-N><C-w>k", { desc = 'Exit terminal and move focus top', noremap = true, silent = true })
-- vim.keymap.set('t', '<Escape-Escape>', "<C-\\><C-N>", { desc = 'Exit terminal mode', noremap = true, silent = true })
-- vim.keymap.set('t', '<A-`>', "<C-\\><C-N><C-w>h", { desc = 'move focus to window left', noremap = true, silent = true })
-- vim.keymap.set('t', '<A-\\>', "<C-\\><C-N><C-w>h<eader>ac", { desc = 'toggle claudecode in terminal', noremap = true, silent = true })

-- vim.keymap.set('n', '<A-1>', ':let @*=expand("%")..":"..line(".")<CR>', { desc = 'Copy file path line number to clipboard' })

vim.keymap.set('n', '<A-1>', function()
  local file = vim.fn.expand('%:t')
  vim.fn.setreg("+", file)
  vim.notify('Copy to clipboard: '..file, vim.log.levels.INFO)
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
    dashboard = { enabled = true },
    explorer = { enabled = true },
    indent = { enabled = true },
    input = { enabled = true },
    picker = { enabled = true },
    notifier = { enabled = true },
    quickfile = { enabled = true },
    scope = { enabled = true },
    scroll = { enabled = true },
    statuscolumn = { enabled = true },
    words = { enabled = true },
    terminal = {},
  },
  keys = {
    { "<A-`>", function()
      local branch = vim.fn.system('git branch --show-current'):gsub("\n", "")
      local title = branch ~= "" and ("  " .. branch .. " ") or " Terminal "
      Snacks.terminal(nil, {
        env = { DRACULA_DISPLAY_GIT = "0" },
        win = {
          title = title,
          wo = {
            statusline = "" .. (branch ~= "" and " "..branch or "terminal"),
            -- winbar = ' %{fnamemodify(get(b:, "term_cwd", getcwd()), ":t")}',
          },
          keys = {
            hide = {
              "<A-`>",
              function(self) self:hide() end,
              mode = "t",
              desc = "Hide Terminal",
            },
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
                local file = vim.fn.expand('%:p')
                local line = vim.fn.line('.')

                local file_line = vim.fn.shellescape(file) .. ":" .. line
                for _, win in ipairs(vim.api.nvim_list_wins()) do
                  local buf = vim.api.nvim_win_get_buf(win)
                  local buftype = vim.bo[buf].buftype
                  if buftype ~= 'terminal' then
                    local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ':.')
                    local cursor = vim.api.nvim_win_get_cursor(win)
                    file_line = name .. ':' .. cursor[1]
                    break
                  end
                end

                local text = "bundle exec rspec " .. file_line
                vim.fn.setreg("+", text)
                vim.notify('Copy to clipboard: '..text, vim.log.levels.INFO)
              end,
              mode = "t",
              desc = "Copy current file and line to clipboard"
            },
            current_git_branch = {
              "<A-2>",
              function(_self)
                local branch_name = vim.fn.system('git branch --show-current'):gsub("\n", "")
                vim.fn.setreg("+", branch_name)
                vim.notify('Copy to clipboard: '..branch_name, vim.log.levels.INFO)
              end,
              mode = "t",
              desc = "Copy current branch to clipboard"
            }
          },
        },
      })
    end, desc = "Toggle Terminal" },
    { "<A-r>", function()
      Snacks.terminal(
        "bundle exec rails console",
        {
          env = { DRACULA_DISPLAY_GIT = "0" },
          win = {
            position = "bottom",
            -- width = 0.4,
            height = 0.4,
            border = "rounded",
            title = " Rails Console ",
            title_pos = "center",
            keys = {
              hide = {
                "<A-r>",
                function(self) self:hide() end,
                mode = "t",
                desc = "Hide Rails Console",
              },
            },
          }
        }
      )
    end, desc = "Rails Console" }
  }
}
