local M = {}

M.treesitter = {
    indent = {
        enable = { "php" },
        disable = true,
    },
    rainbow = {
        enable = true,
        extended_mode = true, -- Also highlight non-bracket delimiters like html tags, boolean or table: lang -> boolean
        max_file_lines = nil, -- Do not enable for files with more than n lines, int
        -- colors = {}, -- table of hex strings
        -- termcolors = {} -- table of colour name strings
  }
}

M.tree = {
    view = {
        width = 30
    }
}

return M
