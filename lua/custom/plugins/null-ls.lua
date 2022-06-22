local null_ls = require("null-ls")
local b = null_ls.builtins
local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

local sources = {

	b.formatting.prettierd.with({ filetypes = { "html", "markdown", "css", "scss", "javascript", "json" } }),

	b.formatting.phpcsfixer,
	b.diagnostics.stylelint.with({ filetypes = { "css", "scss", "sass" } }),

	-- Lua
	b.formatting.stylua,
	b.diagnostics.luacheck.with({ extra_args = { "--global vim" } }),

	b.diagnostics.golangci_lint,
	-- b.formatting.golangci_lint,

	-- Shell
	b.formatting.shfmt,
	b.diagnostics.shellcheck.with({ diagnostics_format = "#{m} [#{c}]" }),
}

local M = {}

M.setup = function()
	null_ls.setup({
		debug = true,
		sources = sources,

		-- format on save
		on_attach = function(client, bufnr)
			if client.supports_method("textDocument/formatting") then
				vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
				vim.api.nvim_create_autocmd("BufWritePre", {
					group = augroup,
					buffer = bufnr,
					callback = function()
						vim.lsp.buf.formatting_sync()
					end,
				})
			end
		end,
	})
end

return M
