return {
  "ggandor/leap.nvim",
  event = "VimEnter",
  config = function ()
    require('leap').setup({})
    require('leap').add_default_mappings()
  end
}
