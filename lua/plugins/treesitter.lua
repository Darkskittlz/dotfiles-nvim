return {
  "nvim-treesitter/nvim-treesitter",
  opts = function(_, opts)
    -- Add your languages to the existing list provided by LazyVim
    if type(opts.ensure_installed) == "table" then
      vim.list_extend(opts.ensure_installed, {
        "gitcommit", "astro", "cmake", "cpp", "css", "fish",
        "javascript", "typescript", "gitignore", "go", "graphql",
        "http", "java", "php", "rust", "scss", "sql", "svelte",
        "tsx", "html", "markdown", "markdown_inline", "lua", "vim", "vimdoc",
      })
    end
  end,
  config = function(_, opts)
    -- We DON'T call require("nvim-treesitter.configs").setup(opts) here anymore.
    -- LazyVim's new core handles the setup internally.
    
    -- Keep your custom MDX logic here:
    vim.filetype.add({ extension = { mdx = "mdx" } })
    vim.treesitter.language.register("markdown", "mdx")
  end,
}
