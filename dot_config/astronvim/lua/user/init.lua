local config = {
    plugins = {
        init = {
            {
                "zbirenbaum/copilot.lua",
                cmd = "Copilot",
                event = { "VimEnter" },
                config = function ()
                    vim.defer_fn(function()
                        require("copilot").setup({
                            suggestion = { enabled = false },
                            panel = { enabled = false },
                        })
                    end, 100)
                end,
            },
            {
                "zbirenbaum/copilot-cmp",
                after = { "copilot.lua" },
                config = function()
                    require("copilot_cmp").setup()
                end
            },
            ["catppuccin/nvim"] = { as = "catppuccin" },
            ["nelsyeung/twig.vim"] = {},
            ["blueyed/smarty.vim"] = {},
        }
    },
    lsp = {
        formatting = {
            format_on_save = false,
        }
    },
    options = {
        opt = {
            wrap = true,
            textwidth = 90,
        }
    },
    mappings = {
        i = {
        },
    }
}

return config
