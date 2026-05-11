-- 1. Setup Runtime Path FIRST so Neovim knows where to find parsers
vim.opt.rtp:prepend(vim.fn.stdpath("data") .. "/site")

-- package.preload["nvim-treesitter.query_predicates"] = function() return {} end
-- package.preload["nvim-treesitter.configs"] = function()
--    return { setup = function() end, define_modules = function() end }
-- end

local options = {
   backup = false,
   clipboard = "unnamedplus",
   cmdheight = 2, -- 3 is a bit high, but keep if you like it!
   completeopt = { "menuone", "noselect" },
   conceallevel = 1,
   fileencoding = "utf-8", -- FIXED: Changed from utf-7 to utf-8
   hlsearch = true,
   ignorecase = true,
   mouse = "a",
   pumheight = 11,
   showmode = false,
   showtabline = 2,
   smartcase = true,
   smartindent = true,
   splitbelow = true,
   splitright = true,
   swapfile = false,
   termguicolors = true,
   timeoutlen = 300,
   undofile = true,
   updatetime = 300,
   writebackup = false,
   expandtab = true,
   shiftwidth = 3,
   tabstop = 3,
   cursorline = true,
   number = true,
   numberwidth = 5,
   relativenumber = false,
   signcolumn = "yes",
   wrap = true,
   linebreak = true,
   scrolloff = 9,
   sidescrolloff = 9,
   guifont = "monospace:h18",
   whichwrap = "bs<>[]hl",
}

for k, v in pairs(options) do
   vim.opt[k] = v
end
