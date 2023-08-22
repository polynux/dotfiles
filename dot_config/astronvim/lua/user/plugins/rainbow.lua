return {
    "HiPhish/rainbow-delimiters.nvim",
    config = function()
        local rainbow_delimiters = require("rainbow-delimiters")
        require("rainbow-delimiters.setup")({
            strategy = {
                [''] = rainbow_delimiters.strategy['global'],
                vim = rainbow_delimiters.strategy['local']
            },
            query = {[''] = 'rainbow-delimiters', lua = 'rainbow-blocks'},
            highlight = {
                'RainbowDelimiterRed', 'RainbowDelimiterYellow',
                'RainbowDelimiterBlue', 'RainbowDelimiterOrange',
                'RainbowDelimiterGreen', 'RainbowDelimiterViolet',
                'RainbowDelimiterCyan'
            }
        })
        vim.cmd("hi RainbowDelimiterRed guifg=#ed8796")
        vim.cmd("hi RainbowDelimiterYellow guifg=#eed49f")
        vim.cmd("hi RainbowDelimiterBlue guifg=#8aadf4")
        vim.cmd("hi RainbowDelimiterOrange guifg=#f5a97f")
        vim.cmd("hi RainbowDelimiterGreen guifg=#a6da95")
        vim.cmd("hi RainbowDelimiterViolet guifg=#c6a0f6")
        vim.cmd("hi RainbowDelimiterCyan guifg=#91d7e3")
    end,
    event = {"BufReadPre", "BufNewFile"}
}
