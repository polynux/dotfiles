local config = {
    lsp = { formatting = { format_on_save = false } },
    options = {
        opt = {
            wrap = true,
            -- textwidth = 120,
            colorcolumn = "120",
            foldmethod = "expr",
            foldexpr = "nvim_treesitter#foldexpr()",
            foldenable = false,
            showbreak = "↪ ",
            list = true,
            listchars = {
                tab = "» ",
                trail = "·",
                extends = "»",
                precedes = "«",
                eol = "↲",
                nbsp = "␣",
            },
        }
    },
    colorscheme = "catppuccin-mocha",
    mappings = {
        i = {
            ["<Tab>"] = {
                function()
                    if require("copilot.suggestion").is_visible() then
                        require("copilot.suggestion").accept()
                    else
                        -- send tab
                        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, true, true), "n", true)
                    end
                end,
                desc = "Accept copilot suggestion"
            }
        },
        n = {
            ["<leader>sf"] = {
                function()
                    require("telescope.builtin").find_files()
                end,
                desc = "Search files"
            },
            ["<leader>sw"] = {
                function()
                    require("telescope.builtin").live_grep()
                end,
                desc = "Search words"
            },
            ["<leader>y"] = { "\"+y", desc = "System clipboard" }
        },
        v = { ["<leader>y"] = { "\"+y", desc = "System clipboard" } }
    },
}

return config
