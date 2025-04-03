-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  'chrisgrieser/nvim-early-retirement',
  event = 'VeryLazy',
  config = function()
    require('early-retirement').setup {
      retirementAgeMins = 20,
      minimumBufferNum = 8,
    }
  end,
}

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
