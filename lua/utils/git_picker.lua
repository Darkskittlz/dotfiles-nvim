-- git_picker_no_telescope.lua
-- Replace the Telescope-based picker with a bespoke two-pane Git UI.
-- Left pane: branches/logs (actions: checkout, pull, push, delete, etc.)
-- Right pane: file-diff preview & staging actions (stage/unstage/discard)
-- Switch focus/mode with h / l

---@diagnostic disable: undefined-global
local M = {}

-- Highlights (keep user-provided ones, but define fallbacks)
vim.api.nvim_set_hl(0, "GitBranchCurrent", { fg = "#549afc", bold = true })
vim.api.nvim_set_hl(0, "GitStaged", { fg = "#a6e22e", bg = "NONE", bold = true })
vim.api.nvim_set_hl(0, "GitUnstaged", { fg = "#e6db74", bg = "NONE", bold = true })

-- state
local Ui = {
  overlay_buf = nil,
  overlay_win = nil,
  left_buf = nil,
  left_win = nil,
  right_buf = nil,
  right_win = nil,
  mode = "branches", -- or "files"
  branches = {},
  changed_files = {},
  selected_index = 1,
  branch_selected = nil,
}

local function git_root()
  local root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
  return root and root ~= "" and root or nil
end

local function run_git(cmd)
  -- cmd: table or string
  if type(cmd) == "table" then
    return vim.fn.systemlist(cmd)
  else
    return vim.fn.systemlist(cmd)
  end
end

-- data loaders
local function load_branches()
  local branches = run_git("git branch --list --format='%(refname:short)'") or {}
  Ui.branches = branches
  Ui.branch_selected = Ui.branch_selected or branches[1]
end

local function get_changed_files(branch)
  branch = branch or "HEAD"
  local staged = run_git("git diff --cached --name-status " .. branch) or {}
  local unstaged = run_git("git diff --name-status " .. branch) or {}

  local index = {}
  local results = {}

  local function add(status, path, staged_flag)
    if not index[path] then
      index[path] = { value = path, status = status, staged = staged_flag }
      table.insert(results, index[path])
    else
      -- if unstaged also present, prefer showing unstaged state
      if not staged_flag then
        index[path].staged = false
        index[path].status = status or index[path].status
      else
        index[path].staged = index[path].staged or true
      end
    end
  end

  -- staged first (so they persist)
  for _, line in ipairs(staged) do
    local s, p = line:match("^(%S+)%s+(.*)$")
    if p then add(s, p, true) end
  end
  for _, line in ipairs(unstaged) do
    local s, p = line:match("^(%S+)%s+(.*)$")
    if p then add(s, p, false) end
  end

  Ui.changed_files = results
end

local function get_diff_for_target(target)
  -- target may be branch or file
  if not target or target == "" then return { "[No target]" } end
  local git_root_dir = git_root() or "."
  -- produce combined diff: unstaged then staged
  local cmd = string.format("git -C %s diff -- %s; echo '\n--- STAGED CHANGES ---\n'; git -C %s diff --cached -- %s",
    vim.fn.fnameescape(git_root_dir), vim.fn.shellescape(target), vim.fn.fnameescape(git_root_dir),
    vim.fn.shellescape(target))
  local out = vim.fn.systemlist({ "bash", "-c", cmd })
  if vim.v.shell_error ~= 0 or #out == 0 then return { "[No changes to display]" } end
  return out
end

-- renderers
local function open_or_reuse_buf(name)
  local bufnr = vim.fn.bufnr(name)
  if bufnr == -1 then
    bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(bufnr, name)
  end
  return bufnr
end

local function render_left()
  if not Ui.left_buf then return end
  vim.api.nvim_buf_set_option(Ui.left_buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(Ui.left_buf, 0, -1, false, {})

  if Ui.mode == "branches" then
    load_branches()
    local current = vim.fn.systemlist("git rev-parse --abbrev-ref HEAD")[1] or ""
    for i, b in ipairs(Ui.branches) do
      local marker = (b == current) and "*" or " "
      local line = string.format("%2s %s", marker, b)
      vim.api.nvim_buf_set_lines(Ui.left_buf, -1, -1, false, { line })
      -- add highlight for current
      if b == current then
        vim.api.nvim_buf_add_highlight(Ui.left_buf, -1, "GitBranchCurrent", i - 1, 0, -1)
      end
    end
  else
    -- files mode: show changed files (use selected branch for context)
    get_changed_files(Ui.branch_selected)
    for i, f in ipairs(Ui.changed_files) do
      local prefix = f.staged and "[S]" or "[U]"
      local line = string.format("%s %s %s", prefix, f.status or "", f.value)
      vim.api.nvim_buf_set_lines(Ui.left_buf, -1, -1, false, { line })
      local hl = f.staged and "GitStaged" or "GitUnstaged"
      vim.api.nvim_buf_add_highlight(Ui.left_buf, -1, hl, i - 1, 0, #prefix)
    end
  end

  vim.api.nvim_buf_set_option(Ui.left_buf, "modifiable", false)
end

local function render_right()
  if not Ui.right_buf then return end
  vim.api.nvim_buf_set_option(Ui.right_buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(Ui.right_buf, 0, -1, false, {})

  if Ui.mode == "branches" then
    -- show git log for branch_selected
    local branch = Ui.branch_selected or "HEAD"
    local out = run_git("git log --oneline --decorate " .. vim.fn.shellescape(branch))
    if #out == 0 then out = { "[No commits]" } end
    vim.api.nvim_buf_set_lines(Ui.right_buf, 0, -1, false, out)
    vim.api.nvim_buf_set_option(Ui.right_buf, "filetype", "gitcommit")
  else
    -- files mode: preview diff for selected changed file
    local sel = Ui.changed_files[Ui.selected_index]
    if not sel then
      vim.api.nvim_buf_set_lines(Ui.right_buf, 0, -1, false, { "[No file selected]" })
    else
      local out = get_diff_for_target(sel.value)
      vim.api.nvim_buf_set_lines(Ui.right_buf, 0, -1, false, out)
      vim.api.nvim_buf_set_option(Ui.right_buf, "filetype", "diff")
    end
  end

  vim.api.nvim_buf_set_option(Ui.right_buf, "modifiable", false)
end

local function refresh_ui()
  render_left()
  render_right()
  -- ensure selection visible
  if Ui.left_win and vim.api.nvim_win_is_valid(Ui.left_win) then
    vim.api.nvim_set_current_win(Ui.left_win)
    local lcount = vim.api.nvim_buf_line_count(Ui.left_buf)
    local line = math.min(math.max(Ui.selected_index, 1), lcount)
    pcall(vim.api.nvim_win_set_cursor, Ui.left_win, { line, 0 })
  end
end

-- actions
local function focus_left()
  if Ui.left_win and vim.api.nvim_win_is_valid(Ui.left_win) then
    vim.api.nvim_set_current_win(Ui.left_win)
  end
end
local function focus_right()
  if Ui.right_win and vim.api.nvim_win_is_valid(Ui.right_win) then
    vim.api.nvim_set_current_win(Ui.right_win)
  end
end

local function toggle_mode()
  Ui.mode = (Ui.mode == "branches") and "files" or "branches"
  Ui.selected_index = 1
  refresh_ui()
end

local function stage_unstage_selected()
  if Ui.mode ~= "files" then return end
  local sel = Ui.changed_files[Ui.selected_index]
  if not sel then return end
  local git_root_dir = git_root() or "."
  local full = git_root_dir .. "/" .. sel.value
  local staged_files = run_git("git diff --cached --name-only")
  local is_staged = vim.tbl_contains(staged_files, sel.value)
  local cmd
  if is_staged then
    cmd = { "git", "restore", "--staged", full }
  else
    cmd = { "git", "add", full }
  end
  local out = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    vim.notify("Git failed: " .. out, vim.log.levels.ERROR)
  end
  -- reload changed files and render
  get_changed_files(Ui.branch_selected)
  refresh_ui()
end

local function discard_changes_selected()
  if Ui.mode ~= "files" then return end
  local sel = Ui.changed_files[Ui.selected_index]
  if not sel then return end
  local ok = vim.fn.confirm("Discard changes to " .. sel.value .. "?", "Yes\nNo", 2)
  if ok ~= 1 then return end
  local git_root_dir = git_root() or "."
  local full = git_root_dir .. "/" .. sel.value
  local cmd = { "git", "restore", full }
  local out = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    vim.notify("Git failed: " .. out, vim.log.levels.ERROR)
  end
  get_changed_files(Ui.branch_selected)
  refresh_ui()
end

local function checkout_branch()
  if Ui.mode ~= "branches" then return end
  local cursor = vim.api.nvim_win_get_cursor(Ui.left_win)
  local line = cursor[1]
  local branch = Ui.branches[line]
  if not branch then return end
  local out = vim.fn.system("git checkout " .. vim.fn.shellescape(branch))
  if vim.v.shell_error ~= 0 then
    vim.notify("Checkout failed: " .. out, vim.log.levels.ERROR)
  else
    vim.notify("Checked out: " .. branch, vim.log.levels.INFO)
  end
  load_branches()
  Ui.branch_selected = branch
  refresh_ui()
end

local function delete_branch()
  if Ui.mode ~= "branches" then return end
  local cursor = vim.api.nvim_win_get_cursor(Ui.left_win)
  local branch = Ui.branches[cursor[1]]
  if not branch then return end
  local ok = vim.fn.confirm("Delete branch " .. branch .. "?", "Yes\nNo", 2)
  if ok ~= 1 then return end
  local out = vim.fn.system("git branch -D " .. vim.fn.shellescape(branch))
  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to delete: " .. out, vim.log.levels.ERROR)
  else
    vim.notify("Deleted branch: " .. branch, vim.log.levels.INFO)
  end
  load_branches()
  refresh_ui()
end

local function refresh_data()
  load_branches()
  get_changed_files(Ui.branch_selected)
  refresh_ui()
end

-- UI open/close
function M.open_git_ui()

  -- left and right buffers
  Ui.left_buf = open_or_reuse_buf("__GitPickerLeft__")
  Ui.right_buf = open_or_reuse_buf("__GitPickerRight__")

  local w = math.floor(vim.o.columns * 0.9)
  local h = math.floor(vim.o.lines * 0.9)
  local row = math.floor((vim.o.lines - h) / 2)
  local col = math.floor((vim.o.columns - w) / 2)

  local left_w = math.floor(w * 0.36)
  local right_w = w - left_w - 2

  Ui.left_win = vim.api.nvim_open_win(Ui.left_buf, true, {
    relative = "editor",
    width = left_w,
    height = h,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    zindex = 1001,
  })

  Ui.right_win = vim.api.nvim_open_win(Ui.right_buf, false, {
    relative = "editor",
    width = right_w,
    height = h,
    row = row,
    col = col + left_w + 2,
    style = "minimal",
    border = "rounded",
    zindex = 1001,
  })

  vim.api.nvim_buf_set_option(Ui.left_buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(Ui.right_buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(Ui.left_buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(Ui.right_buf, "bufhidden", "wipe")

  -- initial data
  load_branches()
  get_changed_files(Ui.branch_selected)
  Ui.mode = "branches"
  Ui.selected_index = 1

  -- render
  refresh_ui()

  -- keymaps
  local opts = { noremap = true, silent = true }

  -- close
  vim.keymap.set("n", "q", function()
    if Ui.left_win and vim.api.nvim_win_is_valid(Ui.left_win) then pcall(vim.api.nvim_win_close, Ui.left_win, true) end
    if Ui.right_win and vim.api.nvim_win_is_valid(Ui.right_win) then pcall(vim.api.nvim_win_close, Ui.right_win, true) end
    if Ui.overlay_win and vim.api.nvim_win_is_valid(Ui.overlay_win) then pcall(vim.api.nvim_win_close, Ui.overlay_win,
        true) end
  end, opts)

  -- switch focus/mode
  vim.keymap.set("n", "h", function() -- go to left (branches/files list)
    Ui.mode = (Ui.mode == "branches") and "files" or "branches"
    Ui.selected_index = 1
    refresh_ui()
    focus_left()
  end, opts)
  vim.keymap.set("n", "l", function() focus_right() end, opts)

  -- navigation in left buffer
  vim.keymap.set("n", "j", function()
    Ui.selected_index = math.min(#(Ui.mode == "branches" and Ui.branches or Ui.changed_files), Ui.selected_index + 1)
    refresh_ui()
  end, opts)
  vim.keymap.set("n", "k", function()
    Ui.selected_index = math.max(1, Ui.selected_index - 1)
    refresh_ui()
  end, opts)

  -- actions
  vim.keymap.set("n", "<Space>", function()
    if Ui.mode == "files" then stage_unstage_selected() end
  end, opts)

  vim.keymap.set("n", "D", function()
    if Ui.mode == "files" then discard_changes_selected() end
    if Ui.mode == "branches" then delete_branch() end
  end, opts)

  vim.keymap.set("n", "c", function()
    if Ui.mode == "branches" then checkout_branch() end
  end, opts)

  vim.keymap.set("n", "r", function() refresh_data() end, opts)

  -- view raw diff for current selection in right pane
  vim.keymap.set("n", "p", function()
    -- refresh right pane explicitly
    render_right()
    focus_right()
  end, opts)

  -- open file in editor from files mode
  vim.keymap.set("n", "o", function()
    if Ui.mode ~= "files" then return end
    local sel = Ui.changed_files[Ui.selected_index]
    if not sel then return end
    local root = git_root() or "."
    local full = root .. "/" .. sel.value
    vim.cmd("edit " .. vim.fn.fnameescape(full))
  end, opts)

  focus_left()
end

return M

