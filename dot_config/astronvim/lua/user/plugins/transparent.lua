return {
    "xiyaowong/transparent.nvim",
    event = "BufRead",
    config = function()
        return require("transparent").setup({
        })
    end
}
