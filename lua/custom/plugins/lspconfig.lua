local M = {}

local attach_fun = function(client, bufnr)
    attach(client, bufnr)
    -- gopls capabilities
    if lsp == "gopls" then
        client.resolved_capabilities.document_formatting = true
        client.resolved_capabilities.document_range_formatting = true
    end
end

M.setup_lsp = function(attach, capabilities)
   local lspconfig = require "lspconfig"

   -- lspservers with default config
   local servers = { "html", "cssls", "gopls", "stylelint_lsp", "eslint" }

   for _, lsp in ipairs(servers) do
      lspconfig[lsp].setup {
         on_attach = function(client, bufnr)
            attach(client, bufnr)
            -- gopls capabilities
            if lsp == "gopls" then
                client.resolved_capabilities.document_formatting = true
                client.resolved_capabilities.document_range_formatting = true
            end
        end,
         capabilities = capabilities,
      }
   end
end

return M
