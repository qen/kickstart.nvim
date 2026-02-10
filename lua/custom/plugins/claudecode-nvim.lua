-- vim.keymap.set('t', '<A-l>', "<C-\\><C-N><C-w>l", { desc = 'terminal window move focus to window right', noremap = true, silent = true })
-- vim.keymap.set('t', '<A-k>', "<C-\\><C-N><C-w>k", { desc = 'terminal window move focus to window top', noremap = true, silent = true })
-- vim.keymap.set('t', '<A-j>', "<C-\\><C-N><C-w>j", { desc = 'terminal window move focus to window bottom', noremap = true, silent = true })

-- vim.api.nvim_create_autocmd("OptionSet", {
--   pattern = "diff",
--   callback = function()
--     if vim.bo.buftype == "terminal" then
--       vim.opt_local.list = false
--       vim.opt.fillchars:append({ diff = " " })
--     end
--   end,
-- })

-- vim.api.nvim_create_autocmd("TermOpen", {
--   callback = function()
--     vim.opt_local.list = false
--     vim.opt.fillchars:append({ diff = " " })
--   end,
-- })

-- vim.api.nvim_create_autocmd("BufEnter", {
--   pattern = "term://*",
--   callback = function()
--     vim.opt_local.list = false
--   end,
-- })

-- local term_fullscreen = false
local toggle_key = "<A-\\>"  -- Alt/Meta + comma
return {
  "coder/claudecode.nvim",
  enabled = true,
  event = 'VeryLazy',
  dependencies = { "folke/snacks.nvim" },
  opts = {
    terminal_cmd = "claude", -- Point to local installation
    diff_opts = {
      -- enabled = false,
      -- open_in_new_tab = true,
      -- hide_terminal_in_new_tab = true,
    },
    terminal = {
      provider = "external",
      provider_opts = {
        external_terminal_cmd = "tmux split-window -h -l 40%% %s",
        -- external_terminal_cmd = "tmux split-window %s",
      },
      snacks_win_opts = {
        -- position = "float",
        -- width = 0.4,
        -- height = 0.9,
        -- b = { snacks_term_title = 'Claude' },
        keys = {
          claude_hide = {
            toggle_key,
            function(self)
              self:hide()
            end,
            mode = "t",
            desc = "Hide",
          },
          -- toggle_fullscreen = {
          --   "<A-z>",
          --   function(self)
          --     term_fullscreen = not term_fullscreen
          --     if term_fullscreen then
          --       vim.api.nvim_win_set_config(self.win, {
          --         relative = "editor",
          --         width = vim.o.columns,
          --         height = vim.o.lines - 1,
          --         row = 0,
          --         col = 0,
          --       })
          --     else
          --       local width = math.floor(vim.o.columns * 0.4)
          --       local height = vim.o.lines - 1
          --       vim.api.nvim_win_set_config(self.win, {
          --         relative = "editor",
          --         width = width,
          --         height = height,
          --         row = 0,
          --         col = vim.o.columns - width,
          --       })
          --     end
          --     vim.defer_fn(function()
          --       vim.cmd('redraw!')
          --     end, 10)
          --   end,
          --   mode = "t",
          --   desc = "Toggle Terminal Fullscreen"
          -- },
        },
      },
    },
  },
  config = true,
  keys = {
    { "<leader>a", nil, desc = "AI/Claude Code" },
    { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
    { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
    { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
    { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
    { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
    { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
    {
      "<leader>as",
      "<cmd>ClaudeCodeTreeAdd<cr>",
      desc = "Add file",
      ft = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw" },
    },
    -- Diff management
    { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
    { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
    {
      toggle_key,
      function()
        if require('claudecode').is_claude_connected() then
          vim.fn.system("tmux select-pane -t :.+")
        else
          vim.cmd("ClaudeCode")
        end

        -- local panes = vim.fn.system("tmux list-panes -F '#{pane_id} #{pane_current_command}'")
        -- local claude_pane = nil
        -- for line in panes:gmatch("[^\n]+") do
        --   local pane_id, cmd = line:match("(%%%d+)%s+(.+)")
        --   if cmd and cmd:match("^claude") then
        --     claude_pane = pane_id
        --     break
        --   end
        -- end
        --
        -- if claude_pane then
        --   vim.fn.system("tmux select-pane -t " .. claude_pane)
        -- else
        --   vim.cmd("ClaudeCode")
        -- end

      end,
      desc = "Claude Code",
      mode = { "n", "x" },
    }
    -- { "<A-`>", "<C-\\><C-N><C-w>h", mode = "t", desc = "move focus to window left" },
    -- { "<A-`>", "<C-\\><C-N><leader>ac", mode = "t", desc = "toggle claudecode in terminal" },
  },
}
