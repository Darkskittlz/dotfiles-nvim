local keymap = vim.keymap
local opts = { noremap = true, silent = true }
vim.g.maplocalleader = " "

keymap.set("n", "-", "<C-a>")
keymap.set("n", "+", "<C-x>")

-- A simple spinner helper
local spinner_frames = {
  "⠋",
  "⠙",
  "⠹",
  "⠸",
  "⠼",
  "⠴",
  "⠦",
  "⠧",
  "⠇",
  "⠏",
}

local function show_spinner()
  local i = 1
  local timer = vim.loop.new_timer()
  timer:start(
    0,
    100,
    vim.schedule_wrap(function()
      vim.notify(
        "Reloading Neovim config "
        .. spinner_frames[i],
        vim.log.levels.INFO,
        { timeout = 100 }
      )
      i = (i % #spinner_frames) + 1
    end)
  )
  return timer
end

keymap.set(
  "n",
  "<leader>rl",
  function()
    local spinner = show_spinner()
    -- Source init.lua / config
    vim.cmd("source $MYVIMRC")
    -- Optionally reload Lua modules
    for name, _ in pairs(package.loaded) do
      if name:match("^git_picker") then
        package.loaded[name] = nil
      end
    end
    require("utils.git_picker") -- reload your file
    spinner:stop()
    spinner:close()
    vim.o.background = original_bg -- restore original background
    vim.notify(
      "Config reloaded ✅",
      vim.log.levels.INFO
    )
  end,
  { desc = "Reload Neovim config with spinner" }
)

-- Mason --
vim.api.nvim_set_keymap(
  "n",
  "<leader>M",
  ':lua require("mason.ui").open()<CR>',
  { noremap = true, silent = true }
)

keymap.set("n", "<leader>gb", function()
  -- require('gitsigns').blame_line({ full = true })
  require("gitsigns").blame_line()
end, { desc = "Git blameline" })

keymap.set("n", "<leader>gh", function()
  require("utils.git_picker").open_git_ui()
end, { desc = "Git branch picker" })

keymap.set("n", "<leader>cc", function()
  vim.cmd("colorscheme catppuccin-latte")
end, {
  desc = "Switch to Catppuccin Latte colorscheme",
})

keymap.set("n", "<leader>cs", function()
  vim.cmd("colorscheme solarized-osaka")
end, {
  desc = "Switch to solarized-osaka colorscheme",
})

-- Neogit Keymap
-- keymap.set('n', '<leader>gg', function()
--   require('neogit').open({ kind = "floating" })
-- end, { desc = "Open Neogit (floating window)" })

-- copy --
keymap.set("v", "y", '"+y', opts)

-- delete line above --
keymap.set("n", "dw", "vb_d")

-- Select All
keymap.set("n", "<C-a>", "gg<S-v>G")

-- Jumplist
keymap.set("n", "<C-m>", "<C-i>", opts)

-- New tab
keymap.set("n", "te", "tabedit", opts)

-- Split Window
keymap.set("n", "ss", ":split<Return>", opts)
keymap.set("n", "sv", ":vsplit<Return>", opts)

-- Move window
keymap.set("n", "sh", "<C-w>h")
keymap.set("n", "sk", "<C-w>k")
keymap.set("n", "sj", "<C-w>j")
keymap.set("n", "sl", "<C-w>l")

-- Resize window
keymap.set("n", "<C-w><left>", "<C-w><")
keymap.set("n", "<C-w><right>", "<C-w>>")
keymap.set("n", "<C-w><up>", "<C-w>+")
keymap.set("n", "<C-w><down>", "<C-w>-")

-- Diagnostics
keymap.set("n", "<C-j>", function()
  vim.diagnostic.goto_next()
end, opts)

-- Press jk fast to exit insert mode
keymap.set("i", "jk", "<ESC>", opts)
keymap.set("i", "kj", "<ESC>", opts)

-- Visual Block --
-- Move text up and down
keymap.set("x", "J", ":m '>+1<CR>gv=gv")
keymap.set("x", "K", ":m '<-2<CR>gv=gv")
keymap.set("x", "<A-j>", ":m '>+1<CR>gv=gv")
keymap.set("x", "<A-k>", ":m '<-2<CR>gv=gv")

-- Surround selection with parentheses
keymap.set(
  "v",
  "<leader>(",
  'c(<C-R>")<Esc>',
  { noremap = true, silent = true }
)

-- Surround selection with single quotes
keymap.set(
  "v",
  "<leader>'",
  "c'<C-R>\"'<Esc>",
  { noremap = true, silent = true }
)

-- Surround selection with double quotes
keymap.set(
  "v",
  '<leader>"',
  'c"<C-R>""<Esc>',
  { noremap = true, silent = true }
)

keymap.set("n", "<leader>cn", function()
  if vim.wo.number then
    -- hide both absolute and relative numbers
    vim.wo.number = false
    vim.wo.relativenumber = false
  else
    -- show absolute numbers (you can enable relative if you want)
    vim.wo.number = true
    vim.wo.relativenumber = false
  end
end, { desc = "Toggle line numbers" })

-- ChatGPT Keymaps --
-- GpChatNew Mappings
keymap.set(
  "n",
  "<leader>gv",
  ":GpChatNew vsplit<CR>",
  { noremap = true, silent = true }
)
keymap.set(
  "n",
  "<leader>gs",
  ":GpChatNew split<CR>",
  { noremap = true, silent = true }
)
keymap.set(
  "n",
  "<leader>gt",
  ":GpChatNew tabnew<CR>",
  { noremap = true, silent = true }
)
keymap.set(
  "n",
  "<leader>gp",
  ":GpChatNew popup<CR>",
  { noremap = true, silent = true }
)

-- GpChatPaste Mappings
keymap.set(
  "v",
  "<leader>gvp",
  ':"<C-U>GpChatPaste<CR>',
  { noremap = true, silent = true }
)
keymap.set(
  "v",
  "<leader>gvs",
  ':"<C-U>GpChatPaste vsplit<CR>',
  { noremap = true, silent = true }
)
keymap.set(
  "v",
  "<leader>gsp",
  ':"<C-U>GpChatPaste split<CR>',
  { noremap = true, silent = true }
)
keymap.set(
  "v",
  "<leader>gtp",
  ':"<C-U>GpChatPaste tabnew<CR>',
  { noremap = true, silent = true }
)
keymap.set(
  "v",
  "<leader>gpp",
  ':"<C-U>GpChatPaste popup<CR>',
  { noremap = true, silent = true }
)

-- GpChatToggle Mappings
keymap.set(
  "n",
  "<leader>gtg",
  ":GpChatToggle<CR>",
  { noremap = true, silent = true }
)
keymap.set(
  "n",
  "<leader>gtv",
  ":GpChatToggle vsplit<CR>",
  { noremap = true, silent = true }
)
keymap.set(
  "n",
  "<leader>gth",
  ":GpChatToggle split<CR>",
  { noremap = true, silent = true }
)
keymap.set(
  "n",
  "<leader>gtt",
  ":GpChatToggle tabnew<CR>",
  { noremap = true, silent = true }
)
keymap.set(
  "n",
  "<leader>gttg",
  ":GpChatToggle popup<CR>",
  { noremap = true, silent = true }
)

-- GpChatFinder Mapping
keymap.set(
  "n",
  "<leader>gf",
  ":GpChatFinder<CR>",
  { noremap = true, silent = true }
)

-- GpChatRespond Mapping
keymap.set(
  "n",
  "<leader>gr",
  ":GpChatRespond<CR>",
  { noremap = true, silent = true }
)

-- GpChatDelete Mapping
keymap.set(
  "n",
  "<leader>gd",
  ":GpChatDelete<CR>",
  { noremap = true, silent = true }
)

-- Switch (cycle) between buffers with uppercase H/L
keymap.set(
  "n",
  "H",
  "<Cmd>BufferPrevious<CR>",
  { silent = true }
)

keymap.set(
  "n",
  "L",
  "<Cmd>BufferNext<CR>",
  { silent = true }
)

-- Reorder buffers with Alt+h / Alt+l
keymap.set(
  "n",
  "<A-h>",
  "<Cmd>BufferMovePrevious<CR>",
  { silent = true }
)

keymap.set(
  "n",
  "<A-l>",
  "<Cmd>BufferMoveNext<CR>",
  { silent = true }
)

keymap.set(
  "n",
  "<A-p>",
  "<Cmd>BufferPin<CR>",
  { silent = true }
)

-- Reorder buffers with Alt+h / Alt+l
keymap.set(
  "n",
  "<A-h>",
  "<Cmd>BufferMovePrevious<CR>",
  { silent = true }
)
keymap.set(
  "n",
  "<A-l>",
  "<Cmd>BufferMoveNext<CR>",
  { silent = true }
)
keymap.set(
  "n",
  "<A-p>",
  "<Cmd>BufferPin<CR>",
  { silent = true }
)
