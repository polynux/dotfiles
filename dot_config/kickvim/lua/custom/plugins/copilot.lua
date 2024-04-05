return {
    {
        "zbirenbaum/copilot.lua",
        cmd = "Copilot",
        event = {"VimEnter"},
        config = function()
            vim.defer_fn(function()
                require("copilot").setup({
                    suggestion = {enabled = true, auto_trigger = true}
                    -- suggestion = {enabled = false, auto_trigger = false}
                })
            end, 100)
        end
    }, {
        "CopilotC-Nvim/CopilotChat.nvim",
        branch = "canary",
        dependencies = {
            {"zbirenbaum/copilot.lua"}, -- or github/copilot.vim
            {"nvim-lua/plenary.nvim"}, -- for curl, log wrapper
            {"nvim-telescope/telescope.nvim"}, -- for telescope integration
        },
        opts = {
            debug = true, -- Enable debugging
            -- See Configuration section for rest
            window = {layout = 'float'}
        },
        keys = {
            {
                "<leader>ccq",
                function()
                    local input = vim.fn.input("Quick Chat: ")
                    if input ~= "" then
                        require("CopilotChat").ask(input, {
                            selection = require("CopilotChat.select").buffer
                        })
                    end
                end,
                desc = "CopilotChat - Quick chat"
            }, {
                '<leader>cct',
                function() require("CopilotChat").toggle() end,
                desc = "CopilotChat - Toggle"
            }, -- Show help actions with telescope
            {
                "<leader>cch",
                function()
                    local actions = require("CopilotChat.actions")
                    require("CopilotChat.integrations.telescope").pick(
                        actions.help_actions())
                end,
                desc = "CopilotChat - Help actions"
            }, -- Show prompts actions with telescope
            {
                "<leader>ccp",
                function()
                    local actions = require("CopilotChat.actions")
                    require("CopilotChat.integrations.telescope").pick(
                        actions.prompt_actions())
                end,
                desc = "CopilotChat - Prompt actions"
            }
        }
        -- See Commands section for default commands if you want to lazy load on them
    }
}
