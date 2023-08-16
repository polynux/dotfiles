local config = {
    lsp = {
        formatting = { format_on_save = false },
    },
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
            -- autochdir = true,
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
            ["<leader>y"] = { "\"+y", desc = "System clipboard" },
            --- H for previous tab
            ["H"] = { "[b", desc = "Previous tab" },
            --- L for next tab
            ["L"] = { "]b", desc = "Next tab" },
            --- gt to go to next buffer
            ["gt"] = { ":bnext<CR>", desc = "Next buffer" },
            --- gT to go to previous buffer
            ["gT"] = { ":bprevious<CR>", desc = "Previous buffer" },
        },
        v = { ["<leader>y"] = { "\"+y", desc = "System clipboard" } }
    },
}

-- if filetype is php, set tabstop to 4
vim.api.nvim_create_autocmd( "FileType", {
    pattern = "php",
    callback = function()
        vim.bo.tabstop = 4
        vim.bo.shiftwidth = 4
        vim.bo.softtabstop = 4
    end
})

vim.keymap.set({"n", "o", "x"}, "w", "<cmd>lua require('spider').motion('w')<CR>", { desc = "Spider-w" })
vim.keymap.set({"n", "o", "x"}, "e", "<cmd>lua require('spider').motion('e')<CR>", { desc = "Spider-e" })
vim.keymap.set({"n", "o", "x"}, "b", "<cmd>lua require('spider').motion('b')<CR>", { desc = "Spider-b" })
vim.keymap.set({"n", "o", "x"}, "ge", "<cmd>lua require('spider').motion('ge')<CR>", { desc = "Spider-ge" })

return config
