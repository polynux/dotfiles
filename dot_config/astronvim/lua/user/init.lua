local config = {
  plugins = {
    init = {
      ["github/copilot.vim"] = {},
      ["catppuccin/nvim"] = { as = "catppuccin" },
    }
  },
  lsp = {
    formatting = {
      format_on_save = false,
    }
  }
}

return config
