return {
    ["p00f/nvim-ts-rainbow"] = {},
    ["jose-elias-alvarez/null-ls.nvim"] = {
        after = "nvim-lspconfig",
        config = function()
            require("custom.plugins.null-ls").setup()
        end,
    }
}
