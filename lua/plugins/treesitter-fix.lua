return {
   {
      "nvim-treesitter/nvim-treesitter",
      -- Override the broken init from LazyVim
      init = function() end,
      opts = {
         ensure_installed = { "tsx", "javascript", "typescript", "lua", "markdown" },
         highlight = { enable = true },
      },
   },
}
