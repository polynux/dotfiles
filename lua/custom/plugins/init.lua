return {
	["p00f/nvim-ts-rainbow"] = {},
	["jose-elias-alvarez/null-ls.nvim"] = {
		after = "nvim-lspconfig",
		config = function()
			require("custom.plugins.null-ls").setup()
		end,
	},
	["blueyed/smarty.vim"] = {},
	["alker0/chezmoi.vim"] = {},
	["dag/vim-fish"] = {},
	["elkowar/yuck.vim"] = {},
	["neoclide/coc.nvim"] = { branch = "release" },
}
