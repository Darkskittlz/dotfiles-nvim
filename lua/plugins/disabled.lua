return {
   { "LazyVim/LazyVim",                             opts = { colorscheme = "solarized-osaka" } },
   -- Disable the textobjects plugin specifically to stop that line 103 crash
   { "nvim-treesitter/nvim-treesitter-textobjects", enabled = false },
}
