local M = {}
local opt = vim.opt

M.ui = {
   theme = "chadracula",
}

M.options = {
   user = function ()
      opt.relativenumber = true
      opt.shiftwidth = 4
      opt.scrolloff = 5
      opt.sidescroll = 5
      opt.listchars = {tab = ">─", eol = "¬", trail = " ", nbsp = "¤"}
      opt.list = true
      vim.wo.wrap = true
      opt.wrap = true
      opt.textwidth = 119
      opt.colorcolumn = "120"
   end
}

return M
