return {
    "adalessa/laravel.nvim",
    dependencies = {
        "nvim-telescope/telescope.nvim",
        "tpope/vim-dotenv",
        "MunifTanjim/nui.nvim",
        "nvimtools/none-ls.nvim",
    },
    cmd = { "Sail", "Artisan", "Composer", "Npm", "Yarn", "Laravel" },
    keys = {
        { "<leader>lla", ":Laravel artisan<cr>" },
        { "<leader>llr", ":Laravel routes<cr>" },
        { "<leader>llm", ":Laravel related<cr>" },
    },
    event = { "VeryLazy" },
    config = true,
}
