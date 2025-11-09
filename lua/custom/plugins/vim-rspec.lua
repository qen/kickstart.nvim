-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  "thoughtbot/vim-rspec",
  dependencies = { "tpope/vim-dispatch" },
  ft = "ruby",                              -- ⬅ only load for Ruby buffers
  config = function()
    vim.g.rspec_command = "Dispatch! bundle exec rspec -I . {spec}"
    vim.g.rspec_runner = "os_x_iterm2"
    vim.g.dispatch_tmux_height = "50%"
    vim.g.dispatch_quickfix_height = 15

    -- normal mode mappings
    local opts = { desc = "", buffer = 0 }  -- buffer-local when config runs
    -- vim.keymap.set("n", "\\tt", vim.fn.RunNearestSpec, vim.tbl_extend("force", opts, { desc = "Run neares[T] spec" }))
    -- vim.keymap.set("n", "\\tl", vim.fn.RunLastSpec,   vim.tbl_extend("force", opts, { desc = "Run [L]ast spec" }))
    vim.keymap.set("n", "\\d",
      function() vim.cmd.execute [["normal \<s-O>binding.pry if $pry\<ESC>:w\<CR>"]] end,
      vim.tbl_extend("force", opts, { desc = "Insert [D]ebug binding.pry" })
    )
    vim.keymap.set("n", "\\b",
      function() vim.cmd.execute [["normal \<s-O>$pry=1\<ESC>:w\<CR>"]] end,
      vim.tbl_extend("force", opts, { desc = "Insert $pry=1" })
    )
    -- vim.keymap.set("n", "\\mm", function() vim.cmd "Start specg dbmigrate" end, { desc = "Run db:migrate" })
    -- vim.keymap.set("n", "\\ml", function() vim.cmd "Start specg dbload" end,   { desc = "Run db:schema:load" })

    --
    -- -- which-key groups/icons
    -- local wk = require("which-key")
    -- wk.add({
    --   { "\\t", group = "Rspec [T]est", icon = { icon = "", color = "red" } },
    --   { "\\m", group = "Rails [M]igration", icon = { icon = "󰫏", color = "red" } },
    --   { "\\d", icon = { icon = "󰙨", color = "yellow" } },
    --   { "\\b", icon = { icon = "󰙨", color = "yellow" } },
    -- }, { buffer = vim.api.nvim_get_current_buf() });

    -- -- Re-register on each Ruby buffer so everything is buffer-local
    -- vim.api.nvim_create_autocmd("FileType", {
    --   pattern = "ruby",
    --   callback = function(args)
    --     local bufnr = args.buf
    --     local wk = require("which-key")
    --
    --     -- buffer-local which-key groups/labels
    --     wk.add({
    --       { "\\t", group = "Rspec [T]est", mode = "n" },
    --       { "\\m", group = "Rails [M]igration", mode = "n" },
    --       { "\\d", desc  = "Insert binding.pry", mode = "n" },
    --       { "\\b", desc  = "Insert $pry=1",     mode = "n" },
    --     }, { buffer = bufnr })
    --
    --     -- buffer-local keymaps
    --     local map = function(lhs, rhs, desc)
    --       vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc })
    --     end
    --
    --     map("\\tt", vim.fn.RunNearestSpec, "Run neares[T] spec")
    --     map("\\tl", vim.fn.RunLastSpec,    "Run [L]ast spec")
    --     map("\\d",  function() vim.cmd.execute [["normal \<s-O>binding.pry if $pry\<ESC>:w\<CR>"]] end, "Insert binding.pry")
    --     map("\\b",  function() vim.cmd.execute [["normal \<s-O>$pry=1\<ESC>:w\<CR>"]] end, "Insert $pry=1")
    --     map("\\mm", function() vim.cmd "Start specg dbmigrate"  end, "Run db:migrate")
    --     map("\\ml", function() vim.cmd "Start specg dbload"     end, "Run db:schema:load")
    --   end,
    -- })
  end,
}

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
