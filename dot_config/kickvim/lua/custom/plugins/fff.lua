return {
  'dmtrKovalenko/fff',
  build = function()
    require('fff.download').download_or_build_binary()
  end,
  lazy = false,
  opts = {
    debug = {
      enabled = true,
      show_scores = true,
    },
  },
  keys = {
    {
      '<leader>sf',
      function() require('fff').find_files() end,
      desc = '[S]earch [F]iles (fff, frecency-ranked)',
    },
    {
      '<leader>sg',
      function() require('fff').live_grep() end,
      desc = '[S]earch by [G]rep (fff)',
    },
    {
      '<leader>sw',
      function() require('fff').live_grep_under_cursor() end,
      mode = { 'n', 'x' },
      desc = '[S]earch current [W]ord / selection (fff)',
    },
    {
      '<leader>gf',
      function() require('fff').find_files() end,
      desc = 'Search [G]it [F]iles (fff, git-aware)',
    },
    {
      '<Leader>tf',
      function() require('fff').find_files() end,
      desc = '[T]elescope-style [F]recency (now fff)',
    },
  },
}