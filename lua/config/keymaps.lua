local keymap = vim.keymap
local opts = { noremap = true, silent = true }
vim.g.maplocalleader = " "

keymap.set("n", "-", "<C-a>")
keymap.set("n", "+", "<C-x>")

keymap.set("n", "<leader>tw",
  [[:s/\(\s\+\)className=\(['"]\)\(.\{-}\)\2/\=submatch(1) . "className=" . submatch(2) . "\r" . submatch(1) . "  " . substitute(submatch(3), ' ', '\r' . submatch(1) . "  ", 'g') . "\r" . submatch(1) . submatch(2)/g<CR>]],
  { desc = "Split Tailwind classes into block" })

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


-- Local Language Model
-- Toggle the floating chat window
keymap.set({ "n", "v" }, "<leader>aa", "<cmd>CodeCompanionChat Toggle<cr>", { noremap = true, silent = true })

-- Add selected text to the chat (useful for sending specific React components)
keymap.set("v", "ac", "<cmd>CodeCompanionChat Add<cr>", { noremap = true, silent = true })

-- Open the prompt selector (pre-defined actions like "Explain", "Fix", "Optimize")
keymap.set("n", "<leader>ap", "<cmd>CodeCompanionActions<cr>", { noremap = true, silent = true })

vim.api.nvim_create_autocmd("FileType", {
  pattern = "codecompanion",
  callback = function()
    -- 1. Native 'q' to stop the response (Built-in to CodeCompanion)
    -- No extra mapping needed if you want to keep the default 'stop' behavior

    -- 2. Use 'a' to close the floating window
    vim.keymap.set("n", "c", "<cmd>CodeCompanionChat Toggle<cr>", { noremap = true, silent = true, buffer = true })
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "codecompanion",
  callback = function()
    -- Force the Markdown render plugin to activate
    -- (Assuming you are using render-markdown.nvim based on your ToDo.md screenshot)
    local ok, render_markdown = pcall(require, "render-markdown")
    if ok then
      render_markdown.enable()
    end

    -- Ensure conceal is on so ## actually disappears
    vim.opt_local.conceallevel = 2
    vim.opt_local.concealcursor = "nc"

    -- Set syntax to markdown for treesitter support
    vim.treesitter.start(0, "markdown")
  end,
})


-- Time Tracker Keymaps
keymap.set("n", "<leader>tt", "<cmd>TimeTracker<cr>", { desc = "Open Time Tracker UI" })
keymap.set("n", "<leader>tr", function()
  local db_path = vim.fn.stdpath("data") .. "/time-tracker.db"
  local success = os.remove(db_path)
  if success then
    vim.notify("Time Tracker Reset: Restart Neovim to begin fresh session.", vim.log.levels.INFO)
  else
    vim.notify("Reset failed: Database file not found or currently in use.", vim.log.levels.WARN)
  end
end, { desc = "Reset Time Tracker Database" })



keymap.set("n", "<leader>rl", function()
  local spinner = show_spinner()

  -- Source init.lua
  vim.cmd("source $MYVIMRC")

  -- Reload all custom utils/config modules
  for name, _ in pairs(package.loaded) do
    if name:match("^utils") or name:match("^config") then
      package.loaded[name] = nil
    end
  end

  -- Re-require key files
  require("utils.git_picker")

  spinner:stop()
  spinner:close()

  vim.o.background = original_bg
  vim.notify("Config reloaded ✅", vim.log.levels.INFO)
end, { desc = "Reload Neovim config with spinner" })

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

-- Surround selection with []
keymap.set(
  "v",
  '<leader>[',
  'c[<C-R>"]<Esc>',
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
