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
            ["roobert/tailwindcss-colorizer-cmp.nvim"] = {}
        }
    },
    lsp = { formatting = { format_on_save = false } },
    options = {
        opt = {
            wrap = true,
            textwidth = 80,
            colorcolumn = "80",
            foldmethod = "expr",
            foldexpr = "nvim_treesitter#foldexpr()"
        }
    },
    mappings = {
        i = {
            -- ["<C>Enter"] = {
            --     function() require("copilot.suggestion").accept() end,
            --     desc = "Accept copilot suggestion"
            -- }
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
    highlights = {
        -- set highlights for all themes
        -- use a function override to let us use lua to retrieve colors from highlight group
        -- there is no default table so we don't need to put a parameter for this function
        init = function()
            -- get highlights from highlight groups
            local normal = astronvim.get_hlgroup "Normal"
            local fg, bg = normal.fg, normal.bg
            local bg_alt = astronvim.get_hlgroup("Visual").bg
            local green = astronvim.get_hlgroup("String").fg
            local red = astronvim.get_hlgroup("Error").fg
            -- return a table of highlights for telescope based on colors gotten from highlight groups
            return {
                TelescopeBorder = { fg = bg_alt, bg = bg },
                TelescopeNormal = { bg = bg },
                TelescopePreviewBorder = { fg = bg, bg = bg },
                TelescopePreviewNormal = { bg = bg },
                TelescopePreviewTitle = { fg = bg, bg = green },
                TelescopePromptBorder = { fg = bg_alt, bg = bg_alt },
                TelescopePromptNormal = { fg = fg, bg = bg_alt },
                TelescopePromptPrefix = { fg = red, bg = bg_alt },
                TelescopePromptTitle = { fg = bg, bg = red },
                TelescopeResultsBorder = { fg = bg, bg = bg },
                TelescopeResultsNormal = { bg = bg },
                TelescopeResultsTitle = { fg = bg, bg = bg }
            }
        end
    }
}

return config
