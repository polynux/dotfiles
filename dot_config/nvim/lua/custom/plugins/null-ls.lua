local null_ls = require "null-ls"
local b = null_ls.builtins

local sources = {

   b.formatting.prettierd.with { filetypes = { "html", "markdown", "css", "scss", "javascript", "json" } },

   b.formatting.phpcsfixer,
    b.diagnostics.stylelint.with {filetypes = { "css", "scss", "sass" }},

   -- Lua
   b.formatting.stylua,
   b.diagnostics.luacheck.with { extra_args = { "--global vim" } },

    b.diagnostics.golangci_lint,
    b.formatting.golangci_lint,

   -- Shell
   b.formatting.shfmt,
   b.diagnostics.shellcheck.with { diagnostics_format = "#{m} [#{c}]" },
}

local setup = {
   null_ls.setup {
      debug = true,
      sources = sources,

      -- format on save
      on_attach = function(client)
         if client.server_capabilities.document_formatting then
            vim.cmd "autocmd BufWritePre <buffer> lua vim.lsp.buf.format({async = true})"
         end
      end,
   }
}

return setup
