return {
   {
      "nvim-treesitter/nvim-treesitter",
      version = false,
      build = ":TSUpdate",
      event = { "BufReadPost", "BufNewFile" },
      init = function()
         -- Keep this blank to kill the crashing LazyVim init
      end,
      config = function()
         -- 0.12 Native activation
         vim.api.nvim_create_autocmd({ "FileType" }, {
            pattern = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
            callback = function()
               vim.treesitter.start()
            end,
         })
      end,
   },
}
