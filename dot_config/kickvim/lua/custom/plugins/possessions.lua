return {
  'jedrzejboczar/possession.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  config = function()
    require('possession').setup {
      commands = {
        save = 'SSave',
        load = 'SLoad',
        delete = 'SDelete',
        list = 'SList',
      },
      autosave = { current = true },
    }

    vim.keymap.set('n', '<leader>Ss', function()
      vim.cmd('SSave' .. ' ' .. vim.fn.input 'Session name: ')
    end, { desc = 'Save session' })
    vim.keymap.set('n', '<leader>Sl', function()
      vim.cmd 'SLoad'
    end, { desc = 'Load session' })
    vim.keymap.set('n', '<leader>Sd', function()
      vim.cmd 'SDelete'
    end, { desc = 'Delete session' })
    vim.keymap.set('n', '<leader>Sf', function()
      vim.cmd 'Telescope possession list'
    end, { desc = 'List sessions' })
  end,
}