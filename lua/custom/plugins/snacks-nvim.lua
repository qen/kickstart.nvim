vim.keymap.set('t', '<A-Escape>', "<C-\\><C-N><C-w>k", { desc = 'Exit terminal and move focus top', noremap = true, silent = true })
-- vim.keymap.set('t', '<Escape-Escape>', "<C-\\><C-N>", { desc = 'Exit terminal mode', noremap = true, silent = true })
-- vim.keymap.set('t', '<A-`>', "<C-\\><C-N><C-w>h", { desc = 'move focus to window left', noremap = true, silent = true })
-- vim.keymap.set('t', '<A-\\>', "<C-\\><C-N><C-w>h<eader>ac", { desc = 'toggle claudecode in terminal', noremap = true, silent = true })

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
      Snacks.terminal(nil, {
        win = {
          keys = {
            hide = {
              "<A-`>",
              function(self) self:hide() end,
              mode = "t",
              desc = "Hide Terminal",
            },
          },
        },
      })
    end, desc = "Toggle Terminal" },
    { "<A-r>", function()
      Snacks.terminal(
        "bundle exec rails console",
        {
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
    end, desc = "Rails Console" },
  },
}
