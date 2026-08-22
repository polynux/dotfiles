return {
  'nvim-neorg/neorg',
  lazy = false,
  version = '*',
  build = false,
  config = function()
    -- Add luarocks-installed tree-sitter parser paths to runtimepath
    local rocks_base = vim.fn.stdpath('data') .. '/lazy-rocks'
    local parser_paths = {
      rocks_base .. '/tree-sitter-norg/lib/lua/5.1',
      rocks_base .. '/tree-sitter-norg-meta/lib/lua/5.1',
    }
    for _, path in ipairs(parser_paths) do
      if vim.fn.isdirectory(path) == 1 then
        vim.opt.rtp:append(path)
      end
    end

    require('neorg').setup {
      load = {
        ['core.defaults'] = {},
        ['core.concealer'] = {},
        ['core.dirman'] = {
          config = {
            workspaces = {
              notes = '~/notes',
            },
            default_workspace = 'notes',
          },
        },
      },
    }

    vim.wo.foldlevel = 99
    vim.wo.conceallevel = 2
  end,
}