-- 1. SET LEADERS FIRST (Crucial for LazyVim)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
vim.g.sqlite_clib_path = '/home/linuxbrew/.linuxbrew/lib/libsqlite3.so'

-- 2. BOOTSTRAP LAZY
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable",
    lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- 3. SETUP PLUGINS
require("lazy").setup({
  spec = {
    -- Import LazyVim's base
    { "LazyVim/LazyVim", import = "lazyvim.plugins", opts = { colorscheme = "solarized-osaka" } },

    -- Import your custom stuff from lua/plugins/
    { import = "plugins" },
  },
  rocks = {
    enabled = false
  },
  defaults = {
    lazy = false,
    version = false,
  },
  install = { colorscheme = { "solarized-osaka" } },
  checker = { enabled = true },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})

-- 4. FINAL THEME SETTINGS (After plugins load)
vim.o.background = "dark"
