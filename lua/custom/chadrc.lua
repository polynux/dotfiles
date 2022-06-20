local M = {}
local opt = vim.opt
local configs = require "custom.plugins.configs"

M.ui = {
   theme = "tokyonight",
}

M.options = {
   user = function ()
      opt.relativenumber = true
      opt.shiftwidth = 4
      opt.scrolloff = 5
      opt.sidescroll = 5
      opt.listchars = {tab = ">─", eol = "¬", trail = " ", nbsp = "¤"}
      opt.list = true
      opt.wrap = true
      opt.textwidth = 119
      opt.colorcolumn = "120"
   end
}

M.plugins = {
   user = require "custom.plugins",
   override = {
      ["nvim-treesitter/nvim-treesitter"] = configs.treesitter,
      ["kyazdani42/nvim-tree.lua"] = configs.tree
   },
   options = {
        lspconfig = {
            setup_lspconf = "custom.plugins.lspconfig"
        }
    }
}

return M
