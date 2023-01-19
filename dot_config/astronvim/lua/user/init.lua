local config = {
    plugins = {
        init = {
            ["zbirenbaum/copilot.lua"] = {
                cmd = "Copilot",
                event = { "VimEnter" },
                config = function()
                    vim.defer_fn(function()
                        require("copilot").setup({
                            suggestion = { enabled = true, auto_trigger = true },
                            panel = { enabled = false },
                            -- suggestion = { enabled = false },
                        })
                    end, 100)
                end
            },
            ["zbirenbaum/copilot-cmp"] = {
                after = { "copilot.lua", "nvim-cmp" },
                config = function()
                    require("copilot_cmp").setup({
                        method = "getPanelCompletions",
                    })
                    astronvim.add_user_cmp_source ("copilot", 800)
                end
            },
            ["catppuccin/nvim"] = { as = "catppuccin" },
            ["nelsyeung/twig.vim"] = {},
            ["blueyed/smarty.vim"] = {}
        }
    },
    lsp = { formatting = { format_on_save = false } },
    options = { opt = { wrap = true, textwidth = 80 } },
    mappings = {
        i = {
            -- ["<C>Enter"] = {
            --     function() require("copilot.suggestion").accept() end,
            --     desc = "Accept copilot suggestion"
            -- }
        }
    }
}

return config
