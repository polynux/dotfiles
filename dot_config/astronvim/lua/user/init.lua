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
                            panel = { enabled = false }
                            -- suggestion = { enabled = false },
                        })
                    end, 100)
                end
            },
            ["zbirenbaum/copilot-cmp"] = {
                after = { "copilot.lua", "nvim-cmp" },
                config = function()
                    require("copilot_cmp").setup({
                        method = "getPanelCompletions"
                    })
                    astronvim.add_user_cmp_source("copilot", 800)
                end
            },
            ["catppuccin/nvim"] = { as = "catppuccin" },
            ["nelsyeung/twig.vim"] = {},
            ["blueyed/smarty.vim"] = {},
            ["kylechui/nvim-surround"] = {
                tag = "*", -- Use for stability; omit to use `main` branch for the latest features
                config = function()
                    require("nvim-surround").setup({
                        -- Configuration here, or leave empty to use defaults
                    })
                end
            },
            ["roobert/tailwindcss-colorizer-cmp.nvim"] = {},
        }
    },
    lsp = { formatting = { format_on_save = false } },
    options = { opt = { wrap = true, textwidth = 80, colorcolumn = "80" } },
    mappings = {
        i = {
            -- ["<C>Enter"] = {
            --     function() require("copilot.suggestion").accept() end,
            --     desc = "Accept copilot suggestion"
            -- }
        },
        n = {
            ["<leader>sf"] = { function() require("telescope.builtin").find_files() end, desc = "Search files" },
            ["<leader>sw"] = { function() require("telescope.builtin").live_grep() end, desc = "Search words" },
        }
    }
}

return config
