return {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = {"VimEnter"},
    config = function()
        vim.defer_fn(function()
            require("copilot").setup({
                suggestion = {enabled = true, auto_trigger = true},
                filetypes = {
                    yaml = true,
                    markdown = true
                }
            })
        end, 100)
    end
}
