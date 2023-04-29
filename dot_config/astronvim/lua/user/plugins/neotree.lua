return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = function(_, opts)
    opts.filesystem = {
      filtered_items = {
        hide_dotfiles = false,
        hide_gitignored = false,
        hide_by_name = {
          ".cache",
          ".git",
          ".github",
          "node_modules",
        },
      }
    }

    return opts
  end
}
