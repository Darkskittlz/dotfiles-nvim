local on_attach = function(client, bufnr)
  -- Set up keymaps for LSP functionality
  local opts = { noremap = true, silent = true }
  vim.api.nvim_buf_set_keymap(
    bufnr,
    "n",
    "gd",
    "<Cmd>lua vim.lsp.buf.definition()<CR>",
    opts
  )

  -- Autoformatting for supported file types
  local filetype = vim.bo[bufnr].filetype
  local supported_filetypes = {
    "javascript", "javascriptreact", "jsx", "typescript", "typescriptreact", "vue", "lua"
  }

  if vim.tbl_contains(supported_filetypes, filetype) then
    if client.server_capabilities.documentFormattingProvider then
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = vim.api.nvim_create_augroup("LspFormatting", { clear = true }),
        buffer = bufnr,
        callback = function()
          vim.lsp.buf.format({ bufnr = bufnr })
        end,
      })
    end
  end
end

return {
  {
    "neovim/nvim-lspconfig",
    config = function()
      -- TypeScript/JavaScript LSP configuration
      require("lspconfig").tsserver.setup({
        on_attach = on_attach,
      })

      -- Vue LSP configuration
      require("lspconfig").vuels.setup({
        on_attach = function(client, bufnr)
          -- Enable auto-formatting for vuels
          client.resolved_capabilities.document_formatting = true
          client.resolved_capabilities.document_range_formatting = true

          -- Call the same on_attach function to set up auto-formatting
          on_attach(client, bufnr)
        end,
      })

      -- Lua LSP configuration
      require("lspconfig").lua_ls.setup({
        on_attach = on_attach,
      })
    end,
  },
}

