-- Set up keymaps for LSP functionality
local opts = { noremap = true, silent = true }
local bufnr = vim.api.nvim_get_current_buf() -- Get the current buffer number

vim.api.nvim_buf_set_keymap(
  bufnr,
  "n",
  "gd",
  "<Cmd>lua vim.lsp.buf.definition()<CR>",
  opts
)

-- Other LSP key mappings...

-- LSP Formatting Command
return {
  {
    "neovim/nvim-lspconfig",
    config = function()
      require("lspconfig").tsserver.setup({})
    end,
  },
}
