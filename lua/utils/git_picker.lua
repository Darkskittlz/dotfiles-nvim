-- git_picker_no_telescope.lua
---@diagnostic disable: undefined-global
local M = {}

-- TODO: add l keymap to show pretty git graph

-- Highlights
vim.api.nvim_set_hl(
  0,
  "GitBranchCurrent",
  { fg = "#549afc", bold = true }
)
vim.api.nvim_set_hl(
  0,
  "GitStaged",
  { fg = "#a6e22e", bold = true }
)
vim.api.nvim_set_hl(
  0,
  "GitUnstaged",
  { fg = "#e6db74", bold = true }
)
vim.api.nvim_set_hl(
  0,
  "GitPickerTitle",
  { fg = "#268bd3", bold = true }
)
vim.api.nvim_set_hl(0, "DiffAdd", { fg = "#00aa00", bg = "", bold = false })    -- green
vim.api.nvim_set_hl(0, "DiffDelete", { fg = "#f92672", bg = "", bold = false }) -- red/pink
vim.api.nvim_set_hl(0, "DiffChange", { fg = "#fd971f", bg = "", bold = false }) -- orange/yellow
vim.api.nvim_set_hl(0, "GitHash", { fg = "#00dfff", bold = true, italic = false })
vim.api.nvim_set_hl(0, "GitDate", { fg = "#ffd700", bold = false, italic = true })
vim.api.nvim_set_hl(0, "GitMsg", { fg = "#ffffff", bold = false, italic = false })
vim.api.nvim_set_hl(0, "GitCommitMerge", { fg = "#c678dd", bold = true }) -- purple




vim.cmd([[
highlight GitStaged guifg=green
highlight GitStagedFile guifg=green
highlight GitUnstaged guifg=yellow
highlight GitUnstagedFile guifg=yellow
highlight GitBranchCurrent guifg=cyan gui=bold
]])

local Ui = {
  left_buf = nil,
  left_win = nil,
  right_buf = nil,
  right_win = nil,
  mode = "branches",
  branches = {},
  stashes = {},
  changed_files = {},
  selected_index = 1,
  branch_selected = nil,
}

local function git_root()
  local root = vim.fn.systemlist(
    "git rev-parse --show-toplevel"
  )[1]
  return root ~= "" and root or "."
end

local function run_git(cmd)
  if type(cmd) == "table" then
    return vim.fn.systemlist(cmd)
  end
  return vim.fn.systemlist(cmd)
end

---------------------------------------------------------------------------
-- 🔄 Load list of Git branches
---------------------------------------------------------------------------
local function load_branches()
  local branches = run_git(
    "git branch --list --format='%(refname:short)'"
  ) or {}

  -- Filter out empty/whitespace-only lines
  local cleaned = {}
  for _, b in ipairs(branches) do
    if b and b:match("%S") then
      table.insert(cleaned, b)
    end
  end

  -- Get the current branch
  local current = run_git(
    "git rev-parse --abbrev-ref HEAD"
  )[1] or ""

  -- Store branch statuses separately
  local branch_statuses = {}
  local status = run_git("git status --porcelain")
  for _, branch in ipairs(cleaned) do
    if branch == current then
      local staged = false
      local unstaged = false
      for _, line in ipairs(status) do
        local x = line:sub(1, 1) -- staged
        local y = line:sub(2, 2) -- unstaged

        if x ~= " " then
          staged = true
        end
        if y ~= " " then
          unstaged = true
        end
      end

      if unstaged then
        branch_statuses[branch] = "💣" -- unstaged changes exist
      elseif staged then
        branch_statuses[branch] = "✅" -- staged changes ready to commit
      else
        branch_statuses[branch] = "" -- clean
      end
    else
      branch_statuses[branch] = "" -- other branches just blank
    end
  end

  -- Reorder so current branch is first
  table.sort(cleaned, function(a, b)
    if a == current then
      return true
    end
    if b == current then
      return false
    end
    return a < b
  end)

  -- Save pure branch names
  Ui.branches = cleaned
  Ui.branch_statuses = branch_statuses

  -- Default selected branch
  Ui.branch_selected = Ui.branch_selected
      or Ui.branches[1]
end

---------------------------------------------------------------------------
-- 🕵️ Load list of Git stashes
---------------------------------------------------------------------------
local function load_stashes()
  local raw = run_git(
    "git stash list --pretty='%gd: %s'"
  ) or {}
  UiStash.stashes = vim.tbl_filter(function(s)
    return s and #s > 0
  end, raw)
  UiStash.selected_index = 1
end

---------------------------------------------------------------------------
-- 🧩 Load list of changed files (staged + unstaged)
--  branch: optional branch or commit ref (defaults to HEAD)
---------------------------------------------------------------------------
local function get_changed_files(branch)
  branch = branch or "HEAD" -- fallback if not provided

  -------------------------------------------------------------------------
  -- Run Git commands:
  --   - `git diff --cached --name-status` → staged changes
  --   - `git diff --name-status`          → unstaged changes
  -------------------------------------------------------------------------
  local staged_lines = run_git(
    "git diff --cached --name-status " .. branch
  ) or {}
  local unstaged_lines = run_git(
    "git diff --name-status " .. branch
  ) or {}

  -------------------------------------------------------------------------
  -- Prepare data structures:
  --   index   → map of path → { value, status, staged }
  --   results → list of all files (for ordered display)
  -------------------------------------------------------------------------
  local index, results = {}, {}

  -------------------------------------------------------------------------
  -- Helper: add(status, path, staged_flag)
  -------------------------------------------------------------------------
  local function add(status, path, staged_flag)
    if not index[path] then
      index[path] = {
        value = path,
        status = status or "M",
        staged = staged_flag or false,
      }
      table.insert(results, index[path])
    else
      -- Update staged flag and status if necessary
      if staged_flag then
        index[path].staged = true
        index[path].status = status
            or index[path].status
      else
        index[path].staged = index[path].staged
            or false
        index[path].status = status
            or index[path].status
      end
    end
    -- print(
    --   "get_changed_files: file=",
    --   path,
    --   "status=",
    --   status,
    --   "staged=",
    --   index[path].staged
    -- )
  end

  -------------------------------------------------------------------------
  -- Parse staged lines
  -------------------------------------------------------------------------
  for _, line in ipairs(staged_lines) do
    if line and line:match("%S") then
      -- line format: "M  path/to/file" or "A  path/to/file"
      local s, p = line:match("^(%S+)%s+(.*)$")
      if not s then
        -- fallback if --name-status didn't provide status
        s, p = "M", line
      end
      if p then
        add(s, p, true)
      end
    end
  end

  -------------------------------------------------------------------------
  -- Parse unstaged lines
  -------------------------------------------------------------------------
  for _, line in ipairs(unstaged_lines) do
    if line and line:match("%S") then
      local s, p = line:match("^(%S+)%s+(.*)$")
      if not s then
        s, p = "M", line
      end
      if p then
        add(s, p, false)
      end
    end
  end

  -------------------------------------------------------------------------
  -- Store final list
  -------------------------------------------------------------------------
  Ui.changed_files = results
end

-- Diff preview
local function get_diff_for_target(target)
  if not target or target == "" then
    return { "[No target]" }
  end
  local root = git_root()
  local cmd = string.format(
    "git -C %s diff -- %s; echo '\n--- STAGED CHANGES ---\n'; git -C %s diff --cached -- %s",
    vim.fn.fnameescape(root),
    vim.fn.shellescape(target),
    vim.fn.fnameescape(root),
    vim.fn.shellescape(target)
  )
  local out =
      vim.fn.systemlist({ "bash", "-c", cmd })
  if vim.v.shell_error ~= 0 or #out == 0 then
    return { "[No changes]" }
  end
  return out
end

---------------------------------------------------------------------------
-- Render the left panel (branches or changed files)
---------------------------------------------------------------------------
local function render_left()
  if not Ui.left_buf then
    -- print("render_left: no left buffer")
    return
  end

  -- print("render_left: starting, mode =", Ui.mode)
  vim.api.nvim_buf_set_option(
    Ui.left_buf,
    "modifiable",
    true
  )

  local lines = {}      -- lines to write
  local highlights = {} -- highlight info

  if Ui.mode == "branches" then
    -- print("render_left: loading branches")
    load_branches()
    local current = run_git(
      "git rev-parse --abbrev-ref HEAD"
    )[1] or ""
    -- print(
    --   "render_left: current branch =",
    --   current
    -- )
    for i, b in ipairs(Ui.branches) do
      local marker = (b == current) and "*" or " "
      local status = Ui.branch_statuses[b] or "" -- fetch ⚠ if there are uncommitted changes
      local line = string.format(
        "%2s %s %s",
        marker,
        b,
        status
      )
      table.insert(lines, line)

      if b == current then
        table.insert(
          highlights,
          { line = i, hl = "GitBranchCurrent" }
        )
      end
    end
  else
    -- print(
    --   "render_left: rendering changed files, selected branch =",
    --   Ui.branch_selected
    -- )
    -- print("render_left: get_changed_files call")
    get_changed_files(Ui.branch_selected)
    -- print(
    --   "render_left: Ui.changed_files count =",
    --   #Ui.changed_files
    -- )
    for i, f in ipairs(Ui.changed_files) do
      local prefix = f.staged and "✅" or "💣"
      -- print("render_left: prefix =", prefix)
      local line = string.format(
        " %s %s %s",
        prefix,
        f.status or "",
        f.value
      )
      table.insert(lines, line)

      -- Highlight prefix color
      table.insert(highlights, {
        line = i,
        hl = f.staged and "GitStaged"
            or "GitUnstaged",
        col = 0,
        length = #line, -- only highlight [U]/[S]
      })

      -- Highlight filename differently
      table.insert(highlights, {
        line = i,
        hl = f.staged and "GitStagedFile"
            or "GitUnstagedFile",
        col = 4,
        length = #f.value,
      })
    end
  end

  -- print(
  --   "render_left: writing lines to buffer, line count =",
  --   #lines
  -- )
  vim.api.nvim_buf_set_lines(
    Ui.left_buf,
    0,
    -1,
    false,
    lines
  )

  -- Apply highlights
  vim.api.nvim_buf_clear_namespace(
    Ui.left_buf,
    -1,
    0,
    -1
  )
  for _, h in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(
      Ui.left_buf,
      -1,
      h.hl,
      h.line - 1,
      h.col or 0,
      h.length or -1
    )
  end

  vim.api.nvim_buf_set_option(
    Ui.left_buf,
    "modifiable",
    false
  )
  -- print("render_left: done")
end

---------------------------------------------------------------------------
-- Render the right panel (commit log or diff preview)
---------------------------------------------------------------------------
local function render_right()
  if not Ui.right_buf then
    return
  end

  vim.api.nvim_buf_set_option(Ui.right_buf, "modifiable", true)
  local out = {}

  if Ui.mode == "branches" then
    local branch = Ui.branch_selected or "HEAD"
    out = run_git([[git log --pretty=format:"%h %ad %s" --date=short ]] .. vim.fn.shellescape(branch))
    if #out == 0 then out = { "[No commits]" } end

    vim.api.nvim_buf_set_lines(Ui.right_buf, 0, -1, false, out)
    vim.api.nvim_buf_set_option(Ui.right_buf, "filetype", "")
    vim.api.nvim_buf_clear_namespace(Ui.right_buf, -1, 0, -1)

    -- Override highlights
    for i, line in ipairs(out) do
      local hash, date, msg = line:match("^(%S+)%s+(%S+)%s+(.*)$")
      if hash then
        vim.api.nvim_buf_add_highlight(Ui.right_buf, -1, "GitHash", i - 1, 0, #hash)
        vim.api.nvim_buf_add_highlight(Ui.right_buf, -1, "GitDate", i - 1, #hash + 1, #hash + 1 + #date)
        vim.api.nvim_buf_add_highlight(Ui.right_buf, -1, "GitMsg", i - 1, #hash + 1 + #date + 2, -1)
      end
    end
  elseif Ui.mode == "files" then
    -- Files / diff view
    local sel = Ui.changed_files[Ui.selected_index]
    out = sel and get_diff_for_target(sel.value) or { "[No file selected]" }
    vim.api.nvim_buf_set_option(Ui.right_buf, "filetype", "diff")

    -- Apply highlights for diff view
    for i, line in ipairs(out) do
      if line:match("^%+.*") then
        vim.api.nvim_buf_add_highlight(Ui.right_buf, -1, "DiffAddLine", i - 1, 0, -1)
      elseif line:match("^%-.*") then
        vim.api.nvim_buf_add_highlight(Ui.right_buf, -1, "DiffDeleteLine", i - 1, 0, -1)
      elseif line:match("^diff ") then
        vim.api.nvim_buf_add_highlight(Ui.right_buf, -1, "DiffFile", i - 1, 0, -1)
      elseif line:match("^@@") then
        vim.api.nvim_buf_add_highlight(Ui.right_buf, -1, "DiffHeader", i - 1, 0, -1)
      end
    end
  end

  vim.api.nvim_buf_set_lines(Ui.right_buf, 0, -1, false, out)
  vim.api.nvim_buf_set_option(Ui.right_buf, "modifiable", false)
end


local function refresh_ui()
  if Ui.mode == "branches" then
    Ui.branch_selected =
        Ui.branches[Ui.selected_index]
  end

  render_left()
  render_right()

  local total = (Ui.mode == "branches")
      and #Ui.branches
      or #Ui.changed_files
  Ui.selected_index = math.max(
    1,
    math.min(
      Ui.selected_index,
      math.max(1, total)
    )
  )

  if
      Ui.left_win
      and vim.api.nvim_win_is_valid(Ui.left_win)
  then
    vim.api.nvim_win_set_cursor(
      Ui.left_win,
      { Ui.selected_index, 0 }
    )
  end
end

-- Focus helpers
local function focus_left()
  if
      Ui.left_win
      and vim.api.nvim_win_is_valid(Ui.left_win)
  then
    vim.api.nvim_set_current_win(Ui.left_win)
  end
end

local function focus_right()
  if
      Ui.right_win
      and vim.api.nvim_win_is_valid(Ui.right_win)
  then
    vim.api.nvim_set_current_win(Ui.right_win)
  end
end

-- When initializing your UI
local function init_ui()
  -- Load branches and changed files
  load_branches()
  get_changed_files(Ui.branch_selected)

  -- Determine initial mode based on whether there are changes
  if #Ui.changed_files > 0 then
    Ui.mode = "files"
  else
    Ui.mode = "branches"
  end

  Ui.selected_index = 1

  -- Create buffers / windows here if needed
  refresh_ui()
  focus_left()
end

-- Toggle between branches and files mode
local function toggle_mode()
  if not Ui then
    return
  end

  Ui.mode = (Ui.mode == "branches") and "files"
      or "branches"
  Ui.selected_index = 1
  refresh_ui()
  focus_left()

  if Ui.mode == "files" then
    -- Update staged files preview
    staged_files =
        run_git("git diff --cached --name-only")
  end

  -- Update the left window title
  if
      Ui.left_win
      and vim.api.nvim_win_is_valid(Ui.left_win)
  then
    vim.api.nvim_win_set_config(Ui.left_win, {
      title = (Ui.mode == "branches")
          and " Git Branches "
          or " Files Changed ",
    })
  end

  -- Update the right window title
  if
      Ui.right_win
      and vim.api.nvim_win_is_valid(Ui.right_win)
  then
    vim.api.nvim_win_set_config(Ui.right_win, {
      title = (Ui.mode == "branches") and " Log "
          or " Diff ",
    })
  end
end

-- Stage or unstage the selected file
local function stage_unstage_selected()
  if Ui.mode ~= "files" then
    -- print(
    --   "stage_unstage_selected: not in files mode, exiting"
    -- )
    return
  end

  local sel = Ui.changed_files[Ui.selected_index]
  if not sel then
    -- print(
    --   "stage_unstage_selected: no file selected at index",
    --   Ui.selected_index
    -- )
    return
  end

  -- print(
  --   "stage_unstage_selected: selected file =",
  --   sel.value,
  --   "staged =",
  --   sel.staged
  -- )

  local root = git_root()
  local staged_files =
      run_git("git diff --cached --name-only")
  -- print(
  --   "stage_unstage_selected: currently staged files:",
  --   table.concat(staged_files, ", ")
  -- )

  local cmd
  if
      vim.tbl_contains(staged_files, sel.value)
  then
    -- print(
    --   "stage_unstage_selected: file is staged, will unstage"
    -- )
    cmd = {
      "git",
      "restore",
      "--staged",
      root .. "/" .. sel.value,
    }
  else
    -- print(
    --   "stage_unstage_selected: file is not staged, will stage"
    -- )
    cmd =
    { "git", "add", root .. "/" .. sel.value }
  end

  -- Run the git command
  local result = vim.fn.system(cmd)
  -- print(
  --   "stage_unstage_selected: git command executed, output:\n",
  --   result
  -- )

  -- Refresh changed files
  -- print(
  --   "stage_unstage_selected: refreshing changed files"
  -- )
  get_changed_files(Ui.branch_selected)
  -- print(
  --   "stage_unstage_selected: Ui.changed_files after refresh:"
  -- )
  for i, f in ipairs(Ui.changed_files) do
    -- print(
    --   string.format(
    --     "  [%d] %s staged=%s status=%s",
    --     i,
    --     f.value,
    --     tostring(f.staged),
    --     f.status or ""
    --   )
    -- )
  end

  -- Redraw panels
  -- print(
  --   "stage_unstage_selected: rendering left panel"
  -- )
  render_left()
  -- print(
  --   "stage_unstage_selected: rendering right panel"
  -- )
  render_right()

  -- Highlight selected line briefly
  vim.api.nvim_buf_add_highlight(
    Ui.left_buf,
    -1,
    "Visual",
    Ui.selected_index - 1,
    0,
    -1
  )
  vim.defer_fn(function()
    -- print(
    --   "stage_unstage_selected: deferred render_left"
    -- )
    render_left()
  end, 100)

  vim.api.nvim_win_set_cursor(
    Ui.left_win,
    { Ui.selected_index, 0 }
  )
  -- print("stage_unstage_selected: finished")
end

-- Discard changes for the selected file
local function discard_changes_selected()
  if Ui.mode ~= "files" then
    print(
      "Exiting: Ui.mode is not 'files', current mode:",
      Ui.mode
    )
    return
  end

  local sel = Ui.changed_files[Ui.selected_index]
  if not sel then
    print(
      "Exiting: No selected file at index",
      Ui.selected_index
    )
    return
  end

  print("Selected file to discard:", sel.value)

  local confirm_result = vim.fn.confirm(
    "Discard changes to " .. sel.value .. "?",
    "Yes\nNo",
    2
  )
  print("Confirm result:", confirm_result)

  if confirm_result ~= 1 then
    print("Discard canceled by user")
    return
  end

  local root = git_root()
  print("Git root detected:", root)

  local cmd =
  { "git", "restore", root .. "/" .. sel.value }
  print(
    "Running command:",
    table.concat(cmd, " ")
  )

  local result = vim.fn.system(cmd)
  local err = vim.v.shell_error
  print("Command output:", result)
  print("Shell error code:", err)

  if err ~= 0 then
    print("Error discarding changes!")
  else
    print("Successfully discarded changes")
  end

  refresh_ui()
  print("UI refreshed")
end

local function show_centered_message(msg, icon)
  -- print(
  --   "[DEBUG] show_centered_message called with msg:",
  --   msg or "nil",
  --   "icon:",
  --   icon or "nil"
  -- )

  icon = icon or "🈯" -- default icon
  local buf = vim.api.nvim_create_buf(false, true)
  if not buf or buf == 0 then
    -- print("[DEBUG] Failed to create buffer")
    return
  end
  -- print("[DEBUG] Created buffer:", buf)

  local lines = vim.split(msg or "", "\n")
  if #lines > 0 then
    lines[1] = icon .. " " .. lines[1]
  else
    lines = { icon }
  end
  -- print(
  --   "[DEBUG] Lines prepared:",
  --   table.concat(lines, " | ")
  -- )

  -- Set lines
  vim.api.nvim_buf_set_lines(
    buf,
    0,
    -1,
    false,
    lines
  )
  -- print("[DEBUG] Lines set in buffer")

  -- Create highlight
  vim.api.nvim_set_hl(
    0,
    "CenteredMessage",
    { fg = "#FFFFFF", bold = true }
  )
  -- print(
  --   "[DEBUG] Highlight defined: CenteredMessage"
  -- )

  for i = 0, #lines - 1 do
    vim.api.nvim_buf_add_highlight(
      buf,
      -1,
      "CenteredMessage",
      i,
      0,
      -1
    )
  end
  -- print("[DEBUG] Highlights applied")

  -- Get UI info
  local ui_list = vim.api.nvim_list_uis()
  if not ui_list or #ui_list == 0 then
    -- print(
    --   "[DEBUG] No UI available — skipping window creation"
    -- )
    return
  end
  local ui = ui_list[1]
  -- print(
  --   "[DEBUG] UI info — width:",
  --   ui.width,
  --   "height:",
  --   ui.height
  -- )

  local width =
      math.max(60, math.min(80, #lines[1] + 4))
  local height = #lines
  -- print(
  --   "[DEBUG] Calculated window size:",
  --   width,
  --   "x",
  --   height
  -- )

  local win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    width = width,
    height = height,
    row = 2,
    col = math.floor((ui.width - width) / 2),
    style = "minimal",
    border = "rounded",
    zindex = 50,
  })

  if not win or win == 0 then
    -- print("[DEBUG] Failed to open window")
    return
  end
  -- print(
  --   "[DEBUG] Window opened successfully:",
  --   win
  -- )

  vim.api.nvim_buf_set_option(
    buf,
    "modifiable",
    false
  )
  -- print("[DEBUG] Buffer made unmodifiable")

  vim.defer_fn(function()
    -- print("[DEBUG] Auto-close timer triggered")
    if vim.api.nvim_win_is_valid(win) then
      -- print("[DEBUG] Closing window:", win)
      vim.api.nvim_win_close(win, true)
    else
      -- print(
      --   "[DEBUG] Window already invalid — not closing"
      -- )
    end
  end, 2000)
end

local function show_centered_error(msg)
  local buf = vim.api.nvim_create_buf(false, true)
  local lines = vim.split(msg, "\n")
  vim.api.nvim_buf_set_lines(
    buf,
    0,
    -1,
    false,
    vim.split(msg, "\n")
  )

  vim.api.nvim_set_hl(
    0,
    "CenteredError",
    { fg = "#FF5555", bold = true }
  )

  -- Apply highlight to all lines
  for i = 0, #lines - 1 do
    vim.api.nvim_buf_add_highlight(
      buf,
      -1,
      "CenteredError",
      i,
      0,
      -1
    )
  end

  local width = 60
  local height = #lines
  local ui = vim.api.nvim_list_uis()[1]

  local win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    width = width,
    height = height,
    row = 2,
    col = math.floor((ui.width - width) / 2),
    style = "minimal",
    border = "rounded",
    zindex = 50,
  })

  vim.api.nvim_buf_set_option(
    buf,
    "modifiable",
    false
  )
  -- Auto close after 3 seconds
  vim.defer_fn(function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, 2000)
end

-- Checkout the selected branch
local function checkout_branch()
  print("DEBUG: Starting checkout_branch()")

  if Ui.mode ~= "branches" then
    print("DEBUG: Not in branches mode, exiting")
    return
  end

  local branch = Ui.branches[Ui.selected_index]
  if not branch then
    -- print("DEBUG: No branch selected, exiting")
    return
  end
  -- print("DEBUG: Selected branch =", branch)

  -- Check for uncommitted changes
  local status =
      vim.fn.systemlist("git status --porcelain")
  -- print("DEBUG: git status lines =", #status)
  if #status > 0 then
    show_centered_error(
      "🚨 You have uncommitted changes!\nCommit, stash, or discard them before switching branches."
    )
    return
  end

  -- Switch branch using 'git switch'
  -- print("DEBUG: Running git switch command")
  local cmd = "git switch "
      .. vim.fn.shellescape(branch)
  local result = vim.fn.system(cmd)
  -- print(
  --   "DEBUG: git switch result =",
  --   result:gsub("\n", "\\n")
  -- )
  -- print(
  --   "DEBUG: vim.v.shell_error =",
  --   vim.v.shell_error
  -- )

  if vim.v.shell_error ~= 0 then
    show_centered_message(
      "Failed to switch branch:\n" .. result,
      vim.log.levels.ERROR
    )
    return
  end

  -- Update internal state
  Ui.branch_selected = branch
  print(
  -- "DEBUG: branch_selected updated to",
    Ui.branch_selected
  )
  show_centered_message(
    "Switched to branch: " .. branch,
    vim.log.levels.INFO
  )

  -- === Refresh branch window (flicker-free) ===
  if
      Ui.full_win
      and vim.api.nvim_win_is_valid(Ui.full_win)
  then
    local buf =
        vim.api.nvim_win_get_buf(Ui.full_win)
    vim.api.nvim_buf_set_option(
      buf,
      "modifiable",
      true
    )

    local lines = {}
    for i, b in ipairs(Ui.branches) do
      local prefix = (b == branch) and "* "
          or "  "
      table.insert(lines, prefix .. b)
    end

    vim.api.nvim_buf_set_lines(
      buf,
      0,
      -1,
      false,
      lines
    )
    vim.api.nvim_buf_set_option(
      buf,
      "modifiable",
      false
    )

    -- Move cursor to the selected branch
    vim.api.nvim_win_set_cursor(
      Ui.full_win,
      { Ui.selected_index, 0 }
    )
  end

  -- print("DEBUG: checkout_branch() finished")
end

-- Delete the selected branch
local function delete_branch()
  -- only relevant in branches mode
  if Ui.mode ~= "branches" then
    return
  end

  -- get currently selected branch
  local branch = Ui.branches[Ui.selected_index]
  if not branch then
    return
  end

  -- confirm deletion
  local ok_confirm = vim.fn.confirm(
    "Delete branch " .. branch .. "?",
    "Yes\nNo",
    2
  )
  if ok_confirm ~= 1 then
    return
  end

  -- run git delete branch
  local out = vim.fn.system(
    "git branch -D " .. vim.fn.shellescape(branch)
  )
  if vim.v.shell_error ~= 0 then
    show_centered_message(
      "Failed to delete branch: " .. out,
      vim.log.levels.ERROR
    )
  else
    show_centered_message(
      "Deleted branch: " .. branch,
      vim.log.levels.INFO
    )
  end

  -- reload branch list and refresh UI
  load_branches()
  refresh_ui()
end

-- Open UI
function M.open_git_ui()
  -- Create buffers
  Ui.right_buf =
      vim.api.nvim_create_buf(false, true)
  Ui.left_buf =
      vim.api.nvim_create_buf(false, true)

  -- Get Neovim UI dimensions
  local ui = vim.api.nvim_list_uis()[1]
  local editor_w = ui.width
  local editor_h = ui.height

  -- Define bottom and top window heights
  local bottom_h = 5                    -- height of bottom window
  local top_h = editor_h - bottom_h - 8 -- height of top window, leave 2 lines for separation

  -- Compute centered horizontal position
  local w = math.floor(editor_w * 0.9)       -- 60% of editor width
  local col = math.floor((editor_w - w) / 2) -- center horizontally

  -- Create a blank buffer that covers the whole editor
  local blank_buf =
      vim.api.nvim_create_buf(false, true) -- nofile, ephemeral
  vim.api.nvim_buf_set_option(
    blank_buf,
    "buftype",
    "nofile"
  )
  vim.api.nvim_buf_set_option(
    blank_buf,
    "bufhidden",
    "wipe"
  )

  vim.api.nvim_buf_set_lines(
    blank_buf,
    0,
    -1,
    false,
    {}
  ) -- empty content

  -- Fullscreen blank background (non-focusable)
  Ui.full_win =
      vim.api.nvim_open_win(blank_buf, false, {
        relative = "editor",
        width = ui.width,
        height = ui.height,
        row = 0,
        col = 0,
        style = "minimal",
        border = "none",
        zindex = 1,        -- LOW zindex
        focusable = false, -- won't steal input
      })

  -- Git Difference Preview
  Ui.right_win =
      vim.api.nvim_open_win(Ui.right_buf, false, {
        relative = "editor",
        width = w,
        height = top_h - 4, -- now the smaller panel is on top
        row = 4,
        col = col,
        style = "minimal",
        border = "rounded",
        title = (Ui.mode == "branches")
            and " Diff "
            or " Log ",
        title_pos = "center",
        zindex = 10,
      })

  -- Bottom: branches/files
  Ui.left_win =
      vim.api.nvim_open_win(Ui.left_buf, true, {
        relative = "editor",
        width = w,
        height = bottom_h + 2,         -- now the bigger panel is on bottom
        row = editor_h - bottom_h - 6, -- move it below the top window
        col = col,
        style = "minimal",
        border = "rounded",
        title = (Ui.mode == "branches")
            and " Git Branches "
            or " Files Changed ",
        title_pos = "center",
        zindex = 10,
      })

  vim.api.nvim_buf_set_option(
    blank_buf,
    "modifiable",
    false
  )
  vim.api.nvim_buf_set_option(
    blank_buf,
    "buflisted",
    false
  )

  -- Common buffer setup
  for _, buf in ipairs({
    Ui.left_buf,
    Ui.right_buf,
  }) do
    vim.api.nvim_buf_set_option(
      buf,
      "buftype",
      "nofile"
    )
    vim.api.nvim_buf_set_option(
      buf,
      "bufhidden",
      "wipe"
    )
    vim.api.nvim_buf_set_option(
      buf,
      "modifiable",
      true
    )
  end

  -- Initialize UI state
  Ui.mode = "files"
  Ui.selected_index = 1
  load_branches()
  get_changed_files()

  -- Function to close UI
  local function close_ui()
    -- Close left picker window
    if
        Ui.left_win
        and vim.api.nvim_win_is_valid(Ui.left_win)
    then
      vim.api.nvim_win_close(Ui.left_win, true)
    end

    -- Close right picker window
    if
        Ui.right_win
        and vim.api.nvim_win_is_valid(Ui.right_win)
    then
      vim.api.nvim_win_close(Ui.right_win, true)
    end

    -- Close full-screen blank window
    if
        Ui.full_win
        and vim.api.nvim_win_is_valid(Ui.full_win)
    then
      vim.api.nvim_win_close(Ui.full_win, true)
      Ui.full_win = nil -- clear it after closing
    end

    -- Delete the buffers if they still exist
    for _, buf in ipairs({
      Ui.left_buf,
      Ui.right_buf,
      blank_buf,
    }) do
      if
          buf and vim.api.nvim_buf_is_valid(buf)
      then
        vim.api.nvim_buf_delete(
          buf,
          { force = true }
        )
      end
    end

    -- Clear UI state
    Ui.left_win, Ui.right_win, Ui.left_buf, Ui.right_buf =
        nil, nil, nil, nil

    -- Restore focus to the previously active window
    vim.schedule(function()
      pcall(function()
        vim.cmd("wincmd p")
      end)
    end)
  end

  -- Keymaps
  local function set_keymaps(buf)
    -- Navigation & mode toggle
    vim.keymap.set("n", "H", toggle_mode, {
      buffer = buf,
      noremap = true,
      silent = true,
    })
    vim.keymap.set("n", "L", toggle_mode, {
      buffer = buf,
      noremap = true,
      silent = true,
    })
    vim.keymap.set("n", "h", focus_left, {
      buffer = buf,
      noremap = true,
      silent = true,
    })
    vim.keymap.set("n", "l", focus_right, {
      buffer = buf,
      noremap = true,
      silent = true,
    })

    vim.keymap.set("n", "s", function()
      -- Load stashes
      UiStash = UiStash
          or { stashes = {}, selected_index = 1 }
      load_stashes()

      if #UiStash.stashes == 0 then
        vim.notify(
          "No stashes available",
          vim.log.levels.INFO
        )
        return
      end

      local width =
          math.floor(vim.o.columns * 0.9)
      local height_title = 1
      local height_desc = 4
      local height_diff =
          math.floor(vim.o.lines * 0.72)
      local spacing = 1
      local col =
          math.floor((vim.o.columns - width) / 2)

      -- =========================
      -- Background overlay
      -- =========================
      local buf_overlay =
          vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(
        buf_overlay,
        0,
        -1,
        false,
        { string.rep(" ", width) }
      )
      local win_overlay = vim.api.nvim_open_win(
        buf_overlay,
        false,
        {
          relative = "editor",
          width = vim.o.columns,
          height = vim.o.lines,
          row = 0,
          col = 0,
          style = "minimal",
          border = "none",
          zindex = 200,
        }
      )

      -- =========================
      -- Buffers
      -- =========================
      local buf_diff =
          vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_option(
        buf_diff,
        "buftype",
        "nofile"
      )
      vim.api.nvim_buf_set_option(
        buf_diff,
        "bufhidden",
        "wipe"
      )
      vim.api.nvim_buf_set_option(
        buf_diff,
        "filetype",
        "diff"
      )
      vim.api.nvim_buf_set_option(
        buf_diff,
        "modifiable",
        false
      )

      local buf_title =
          vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_option(
        buf_title,
        "buftype",
        "acwrite"
      )
      vim.api.nvim_buf_set_option(
        buf_title,
        "bufhidden",
        "wipe"
      )
      vim.api.nvim_buf_set_lines(
        buf_title,
        0,
        -1,
        false,
        { "" }
      )

      local buf_list =
          vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_option(
        buf_list,
        "buftype",
        "nofile"
      )
      vim.api.nvim_buf_set_option(
        buf_list,
        "bufhidden",
        "wipe"
      )
      vim.api.nvim_buf_set_lines(
        buf_list,
        0,
        -1,
        false,
        UiStash.stashes
      )

      -- =========================
      -- Windows
      -- =========================
      local win_diff =
          vim.api.nvim_open_win(buf_diff, false, {
            relative = "editor",
            width = width,
            height = height_diff - 3,
            row = 4,
            col = col,
            style = "minimal",
            border = "rounded",
            zindex = 300,
            focusable = true,
            title = " Stash Diff ",
            title_pos = "center",
          })

      local win_title =
          vim.api.nvim_open_win(buf_title, true, {
            relative = "editor",
            width = width,
            height = height_title,
            row = 2 + height_diff + spacing,
            col = col,
            style = "minimal",
            border = "rounded",
            zindex = 300,
            title = " Stash Message ",
            title_pos = "center",
          })

      local win_list =
          vim.api.nvim_open_win(buf_list, true, {
            relative = "editor",
            width = width,
            height = math.max(
              5,
              math.min(
                #UiStash.stashes,
                height_desc
              )
            ), -- <-- ensure at least 3 rows
            row = height_diff + height_title + 5,
            col = col,
            style = "minimal",
            border = "rounded",
            zindex = 300,
            title = " Stash List ",
            title_pos = "center",
            focusable = true,
          })

      -- =========================
      -- Close helper
      -- =========================
      local function close_stash_popup()
        for _, w in ipairs({
          win_title,
          win_list,
          win_diff,
          win_overlay,
        }) do
          if vim.api.nvim_win_is_valid(w) then
            vim.api.nvim_win_close(w, true)
          end
        end
        Ui.mode = "files"
        Ui.selected_index = 1
        refresh_ui()
        focus_left()
      end

      -- ================================================
      -- Update diff buffer based on the focused window
      -- ================================================
      local function update_diff(focused_win)
        focused_win = focused_win
            or vim.api.nvim_get_current_win()
        local diff_lines = {}

        if focused_win == win_title then
          -- Show staged changes in title window
          local staged =
              vim.fn.systemlist("git diff --cached")
          if #staged > 0 then
            diff_lines = staged
          else
            diff_lines = { "No staged changes" }
          end
        else
          -- Show stash diff for selected stash
          local entry =
              UiStash.stashes[UiStash.selected_index]
          if entry then
            local ref = entry:match("stash@{%d+}")
            diff_lines =
                run_git("git stash show -p " .. ref)
          end
        end

        vim.api.nvim_buf_set_option(
          buf_diff,
          "modifiable",
          true
        )
        vim.api.nvim_buf_set_lines(
          buf_diff,
          0,
          -1,
          false,
          diff_lines
        )
        vim.api.nvim_buf_set_option(
          buf_diff,
          "modifiable",
          false
        )

        -- Highlight stash list
        local lines = {}
        for i, s in ipairs(UiStash.stashes) do
          lines[i] = (
            i == UiStash.selected_index and "> "
            or "  "
          ) .. s
        end
        vim.api.nvim_buf_set_lines(
          buf_list,
          0,
          -1,
          false,
          lines
        )
        vim.api.nvim_win_set_cursor(
          win_list,
          { UiStash.selected_index, 0 }
        )

        vim.api.nvim_win_call(win_diff, function()
          vim.cmd("redraw")
        end)
      end

      -- Map H/L to switch focus and refresh diff accordingly
      vim.keymap.set("n", "H", function()
        local cur = vim.api.nvim_get_current_win()
        if cur == win_diff then
          vim.api.nvim_set_current_win(win_title)
          update_diff(win_title) -- show staged changes
        end
      end, {
        buffer = b,
        noremap = true,
        silent = true,
      })

      vim.keymap.set("n", "L", function()
        local cur = vim.api.nvim_get_current_win()
        if cur == win_title then
          vim.api.nvim_set_current_win(win_diff)
          update_diff(win_diff) -- show selected stash diff
        end
      end, {
        buffer = b,
        noremap = true,
        silent = true,
      })

      -- =========================
      -- Prefill title and CR mapping
      -- =========================
      local staged = vim.fn.systemlist(
        "git diff --cached --name-only"
      )
      local prefill = ""
      if #staged > 0 then
        prefill = "Staging: "
            .. table.concat(staged, ", ")
      end
      vim.api.nvim_buf_set_lines(
        buf_title,
        0,
        -1,
        false,
        { prefill }
      )

      -- Enter insert mode immediately
      vim.api.nvim_set_current_win(win_title)

      -- ==================
      -- Keymaps
      -- ==================
      for _, b in ipairs({
        buf_title,
        buf_list,
        buf_diff,
      }) do
        vim.keymap.set(
          "n",
          "q",
          close_stash_popup,
          {
            buffer = b,
            noremap = true,
            silent = true,
          }
        )
        vim.keymap.set(
          "n",
          "<Esc>",
          close_stash_popup,
          {
            buffer = b,
            noremap = true,
            silent = true,
          }
        )

        vim.keymap.set("n", "<CR>", function()
          local msg = table.concat(
            vim.api.nvim_buf_get_lines(
              buf_title,
              0,
              -1,
              false
            ),
            " "
          )
          if msg == "" then
            msg = "WIP"
          end

          vim.fn.system(
            "git stash push -m "
            .. vim.fn.shellescape(msg)
          )
          load_stashes()
          update_diff()

          -------------------------------------------------------------------
          -- Floating success popup
          -------------------------------------------------------------------
          local buf_success =
              vim.api.nvim_create_buf(false, true)
          local msg_success = "Stash created: "
              .. msg

          vim.api.nvim_buf_set_lines(
            buf_success,
            0,
            -1,
            false,
            { msg_success }
          )
          vim.api.nvim_buf_add_highlight(
            buf_success,
            -1,
            "String",
            0,
            0,
            -1
          )

          local ui = vim.api.nvim_list_uis()[1]
          local width = #msg_success
          local col =
              math.floor((ui.width - width) / 2)

          local win_success =
              vim.api.nvim_open_win(
                buf_success,
                false,
                {
                  relative = "editor",
                  width = width,
                  height = 1,
                  row = 1,
                  col = col,
                  style = "minimal",
                  border = "rounded",
                  zindex = 450,
                }
              )

          vim.defer_fn(function()
            if
                vim.api.nvim_win_is_valid(
                  win_success
                )
            then
              vim.api.nvim_win_close(
                win_success,
                true
              )
            end
          end, 1500)

          -------------------------------------------------------------------
          -- Reset input buffer
          -------------------------------------------------------------------
          vim.api.nvim_buf_set_lines(
            buf_title,
            0,
            -1,
            false,
            { "" }
          )
          vim.api.nvim_set_current_win(win_list) -- focus stash list
        end, {
          buffer = buf_title,
          noremap = true,
          silent = true,
        })

        vim.keymap.set("n", "g", function()
          local entry =
              UiStash.stashes[UiStash.selected_index]
          if not entry then
            vim.notify(
              "No stash selected",
              vim.log.levels.WARN
            )
            return
          end

          local ref = entry:match("stash@{%d+}")
          if not ref then
            return
          end

          -- File name used in confirmation message
          local staged_files = vim.fn.systemlist(
            "git diff --name-only " .. ref
          )
          local last_file = staged_files[#staged_files]
              or "unknown"
          local file_name =
              vim.fn.fnamemodify(last_file, ":t")

          -------------------------------------------------------------------
          -- Floating confirmation window
          -------------------------------------------------------------------
          local buf_conf =
              vim.api.nvim_create_buf(false, true)
          local prompt = "Pop stash: "
              .. file_name
              .. " ? (y/n/c)"
          vim.api.nvim_buf_set_lines(
            buf_conf,
            0,
            -1,
            false,
            { prompt }
          )

          local ui = vim.api.nvim_list_uis()[1]
          local width = #prompt
          local col =
              math.floor((ui.width - width) / 2)
          local win_conf = vim.api.nvim_open_win(
            buf_conf,
            true,
            {
              relative = "editor",
              width = width,
              height = 1,
              row = 1,
              col = col,
              style = "minimal",
              border = "rounded",
              zindex = 300,
            }
          )

          -------------------------------------------------------------------
          -- Confirmation input
          -------------------------------------------------------------------
          vim.keymap.set("n", "y", function()
            if
                vim.api.nvim_win_is_valid(win_conf)
            then
              vim.api.nvim_win_close(
                win_conf,
                true
              )
            end

            local result = vim.fn.system(
              "git stash pop " .. ref
            )

            if vim.v.shell_error == 0 then
              -------------------------------------------------------------------
              -- Floating success message
              -------------------------------------------------------------------
              local msg = "Popped stash: "
                  .. file_name
              local buf_success =
                  vim.api.nvim_create_buf(
                    false,
                    true
                  )
              vim.api.nvim_buf_set_lines(
                buf_success,
                0,
                -1,
                false,
                { msg }
              )
              vim.api.nvim_buf_add_highlight(
                buf_success,
                -1,
                "String",
                0,
                0,
                -1
              )

              local w = #msg
              local c =
                  math.floor((ui.width - w) / 2)

              local win_success =
                  vim.api.nvim_open_win(
                    buf_success,
                    false,
                    {
                      relative = "editor",
                      width = w,
                      height = 1,
                      row = 1,
                      col = c,
                      style = "minimal",
                      border = "rounded",
                      zindex = 450,
                    }
                  )

              vim.defer_fn(function()
                if
                    vim.api.nvim_win_is_valid(
                      win_success
                    )
                then
                  vim.api.nvim_win_close(
                    win_success,
                    true
                  )
                end
              end, 1500)
            else
              vim.notify(
                "Failed to pop stash: " .. result,
                vim.log.levels.ERROR
              )
            end

            load_stashes()
            update_diff()
          end, { buffer = buf_conf })

          vim.keymap.set("n", "n", function()
            if
                vim.api.nvim_win_is_valid(win_conf)
            then
              vim.api.nvim_win_close(
                win_conf,
                true
              )
            end
          end, { buffer = buf_conf })

          vim.keymap.set("n", "c", function()
            if
                vim.api.nvim_win_is_valid(win_conf)
            then
              vim.api.nvim_win_close(
                win_conf,
                true
              )
            end
          end, { buffer = buf_conf })
        end, { buffer = buf_list })

        vim.keymap.set("n", "d", function()
          local stash =
              UiStash.stashes[UiStash.selected_index]
          if not stash then
            vim.notify(
              "No stash selected",
              vim.log.levels.WARN
            )
            return
          end

          local ref = stash:match("stash@{%d+}")
          local staged_files = vim.fn.systemlist(
            "git diff --name-only " .. ref
          )
          local last = staged_files[#staged_files]
              or "unknown"
          local file_name =
              vim.fn.fnamemodify(last, ":t")

          -------------------------------------------------------------------
          -- Floating confirmation window
          -------------------------------------------------------------------
          local buf_conf =
              vim.api.nvim_create_buf(false, true)
          local prompt = "Drop stash: "
              .. file_name
              .. " ? (y/n)"
          vim.api.nvim_buf_set_lines(
            buf_conf,
            0,
            -1,
            false,
            { prompt }
          )

          local ui = vim.api.nvim_list_uis()[1]
          local width = #prompt
          local col =
              math.floor((ui.width - width) / 2)

          local win_conf = vim.api.nvim_open_win(
            buf_conf,
            true,
            {
              relative = "editor",
              width = width,
              height = 1,
              row = 1,
              col = col,
              style = "minimal",
              border = "rounded",
              zindex = 300,
            }
          )

          -------------------------------------------------------------------
          -- Confirm: y (DROP)
          -------------------------------------------------------------------
          vim.keymap.set("n", "y", function()
            if
                vim.api.nvim_win_is_valid(win_conf)
            then
              vim.api.nvim_win_close(
                win_conf,
                true
              )
            end

            ---------------------------------------------------------------
            -- Drop stash
            ---------------------------------------------------------------
            vim.fn.system(
              "git stash drop " .. ref
            )

            load_stashes()
            update_diff()
            refresh_ui()

            ---------------------------------------------------------------
            -- Success popup (red text)
            ---------------------------------------------------------------
            vim.api.nvim_set_hl(
              0,
              "DropMessage",
              { fg = "#ff4444", bold = true }
            )

            local msg = "Dropped stash: "
                .. file_name
            local buf_success =
                vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_lines(
              buf_success,
              0,
              -1,
              false,
              { msg }
            )
            vim.api.nvim_buf_add_highlight(
              buf_success,
              -1,
              "DropMessage",
              0,
              0,
              -1
            )

            local w = #msg
            local c =
                math.floor((ui.width - w) / 2)

            local win_success =
                vim.api.nvim_open_win(
                  buf_success,
                  false,
                  {
                    relative = "editor",
                    width = w,
                    height = 1,
                    row = 1,
                    col = c,
                    style = "minimal",
                    border = "rounded",
                    zindex = 450,
                  }
                )

            vim.defer_fn(function()
              if
                  vim.api.nvim_win_is_valid(
                    win_success
                  )
              then
                vim.api.nvim_win_close(
                  win_success,
                  true
                )
              end
            end, 1500)
          end, { buffer = buf_conf }) -- <--- FIXED

          -------------------------------------------------------------------
          -- Cancel: n
          -------------------------------------------------------------------
          vim.keymap.set("n", "n", function()
            if
                vim.api.nvim_win_is_valid(win_conf)
            then
              vim.api.nvim_win_close(
                win_conf,
                true
              )
            end
          end, { buffer = buf_conf }) -- <--- FIXED
        end, { buffer = buf_list })

        vim.keymap.set("n", "H", function()
          if
              vim.api.nvim_get_current_win()
              == win_diff
          then
            vim.api.nvim_set_current_win(
              win_title
            )
          end
        end, {
          buffer = b,
          noremap = true,
          silent = true,
        })

        vim.keymap.set("n", "L", function()
          if
              vim.api.nvim_get_current_win()
              == win_title
          then
            vim.api.nvim_set_current_win(win_diff)
          end
        end, {
          buffer = b,
          noremap = true,
          silent = true,
        })

        vim.keymap.set("n", "<Tab>", function()
          vim.api.nvim_set_current_win(win_list)
          vim.cmd("stopinsert") -- exit insert mode so j/k works
        end, { buffer = b })
        vim.keymap.set("n", "<S-Tab>", function()
          vim.api.nvim_set_current_win(win_title)
          vim.cmd("startinsert") -- exit insert mode so j/k works
        end, { buffer = b })

        vim.keymap.set("n", "j", function()
          UiStash.selected_index = math.min(
            #UiStash.stashes,
            UiStash.selected_index + 1
          )
          update_diff()
        end, {
          buffer = buf_list,
          noremap = true,
          silent = true,
        })

        vim.keymap.set("n", "k", function()
          UiStash.selected_index = math.max(
            1,
            UiStash.selected_index - 1
          )
          update_diff()
        end, {
          buffer = buf_list,
          noremap = true,
          silent = true,
        })
      end

      -- Start in insert mode on title
      vim.api.nvim_set_current_win(win_title)

      -- Initialize diff & highlight
      update_diff()
    end, {
      buffer = buf,
      noremap = true,
      silent = true,
    })

    local function has_worktree_changes()
      -- returns >0 when there are changes
      return vim.fn.system(
        "git status --porcelain"
      ) ~= ""
    end

    local function make_show_error(
        row,
        height,
        ui
    )
      return function(msg)
        local buf_err =
            vim.api.nvim_create_buf(false, true)
        vim.api.nvim_set_hl(0, "ResetError", {
          fg = "#ff4444",
          bg = "NONE",
          bold = true,
        })
        vim.api.nvim_buf_set_lines(
          buf_err,
          0,
          -1,
          false,
          { msg }
        )
        vim.api.nvim_buf_add_highlight(
          buf_err,
          -1,
          "ResetError",
          0,
          0,
          -1
        )

        local w = #msg + 4
        local error_row = row + height
        local error_col =
            math.floor((ui.width - w) / 2)

        local win_err =
            vim.api.nvim_open_win(buf_err, false, {
              relative = "editor",
              width = w,
              height = 1,
              row = error_row - 10,
              col = error_col,
              style = "minimal",
              border = "rounded",
              zindex = 600,
            })

        vim.defer_fn(function()
          if
              vim.api.nvim_win_is_valid(win_err)
          then
            vim.api.nvim_win_close(win_err, true)
          end
        end, 1800)
      end
    end

    -- G keymap for reset/rebase options on commits
    vim.keymap.set("n", "g", function()
      if Ui.mode ~= "branches" then
        return
      end

      local win = vim.api.nvim_get_current_win()
      if win ~= Ui.right_win then
        return
      end

      local cursor =
          vim.api.nvim_win_get_cursor(Ui.right_win)
      local line = vim.api.nvim_buf_get_lines(
        Ui.right_buf,
        cursor[1] - 1,
        cursor[1],
        false
      )[1] or ""

      local hash = line:match("^(%S+)")
      if not hash then
        return
      end

      ---------------------------------------------------------------------------
      -- COLOR HIGHLIGHTS
      ---------------------------------------------------------------------------
      vim.api.nvim_set_hl(
        0,
        "ResetBlue",
        { fg = "#4da3ff", bold = true }
      )
      vim.api.nvim_set_hl(
        0,
        "ResetGreen",
        { fg = "#32cd32", bold = true }
      )
      vim.api.nvim_set_hl(
        0,
        "ResetRed",
        { fg = "#ff4444", bold = true }
      )
      vim.api.nvim_set_hl(
        0,
        "ResetWhite",
        { fg = "#bbbbbb", bold = true }
      )

      ---------------------------------------------------------------------------
      -- OPTIONS
      ---------------------------------------------------------------------------
      local options = {
        {
          key = "m",
          label = "Mixed reset",
          hl = "ResetBlue",
          desc = "Reset HEAD to this commit, keeping changes unstaged.",
          cmd = "git reset --mixed " .. hash,
        },
        {
          key = "s",
          label = "Soft reset",
          hl = "ResetGreen",
          desc = "Reset HEAD to this commit, keeping all changes staged.",
          cmd = "git reset --soft " .. hash,
        },
        {
          key = "h",
          label = "Hard reset",
          hl = "ResetRed",
          desc = "Fully reset working tree & index to this commit.",
          cmd = "git reset --hard " .. hash,
        },
        {
          key = "c",
          label = "Cancel",
          hl = "ResetWhite",
          desc = "Exit without doing anything.",
          cmd = nil,
        },
      }

      local selected = 1

      ---------------------------------------------------------------------------
      -- POPUP WINDOWS
      ---------------------------------------------------------------------------
      local ui = vim.api.nvim_list_uis()[1]
      local width = 52
      local height = #options + 3

      local row =
          math.floor((ui.height - height) / 2)
      local col =
          math.floor((ui.width - width) / 2)

      local buf =
          vim.api.nvim_create_buf(false, true)
      local win =
          vim.api.nvim_open_win(buf, true, {
            relative = "editor",
            width = width,
            height = height,
            row = row,
            col = col,
            style = "minimal",
            border = "rounded",
            title = " Reset to " .. hash .. " ",
            title_pos = "center",
            zindex = 500,
          })

      local buf_desc =
          vim.api.nvim_create_buf(false, true)
      local win_desc =
          vim.api.nvim_open_win(buf_desc, false, {
            relative = "editor",
            width = width,
            height = 3,
            row = row + height + 2,
            col = col,
            style = "minimal",
            border = "rounded",
            title = " Info ",
            title_pos = "center",
            zindex = 500,
          })

      ---------------------------------------------------------------------------
      -- RENDER
      ---------------------------------------------------------------------------
      local function render()
        local lines = { "" }
        for i, opt in ipairs(options) do
          local prefix = (i == selected)
              and " "
              or "  "
          lines[#lines + 1] = prefix .. opt.label
        end

        vim.api.nvim_buf_set_lines(
          buf,
          0,
          -1,
          false,
          lines
        )
        vim.api.nvim_buf_clear_namespace(
          buf,
          -1,
          0,
          -1
        )
        vim.api.nvim_buf_add_highlight(
          buf,
          -1,
          options[selected].hl,
          selected,
          0,
          -1
        )

        vim.api.nvim_buf_set_lines(
          buf_desc,
          0,
          -1,
          false,
          { options[selected].desc }
        )
        vim.api.nvim_buf_clear_namespace(
          buf_desc,
          -1,
          0,
          -1
        )
        vim.api.nvim_buf_add_highlight(
          buf_desc,
          -1,
          options[selected].hl,
          0,
          0,
          -1
        )
      end

      render()

      ---------------------------------------------------------------------------
      -- CLOSE POPUP
      ---------------------------------------------------------------------------
      local function close_all()
        if
            vim.api.nvim_win_is_valid(win_desc)
        then
          vim.api.nvim_win_close(win_desc, true)
        end
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end

        Ui.mode = "branches"
        refresh_ui()
      end

      ---------------------------------------------------------------------------
      -- MOVEMENT
      ---------------------------------------------------------------------------
      vim.keymap.set("n", "j", function()
        selected =
            math.min(#options, selected + 1)
        render()
      end, { buffer = buf })

      vim.keymap.set("n", "k", function()
        selected = math.max(1, selected - 1)
        render()
      end, { buffer = buf })

      ---------------------------------------------------------------------------
      -- APPLY RESET
      ---------------------------------------------------------------------------
      local function apply_selected_reset()
        local opt = options[selected]

        if opt.cmd == nil then
          close_all()
          return
        end

        local show_error =
            make_show_error(row, height, ui)

        if has_worktree_changes() then
          show_error(
            "Cannot reset: work tree has uncommitted changes"
          )
          return
        end

        vim.fn.system(opt.cmd)

        local buf_ok =
            vim.api.nvim_create_buf(false, true)
        local msg = opt.label .. " → " .. hash
        vim.api.nvim_buf_set_lines(
          buf_ok,
          0,
          -1,
          false,
          { msg }
        )
        vim.api.nvim_buf_add_highlight(
          buf_ok,
          -1,
          opt.hl,
          0,
          0,
          -1
        )

        local w = #msg + 4
        local c = math.floor((ui.width - w) / 2)
        local win_ok =
            vim.api.nvim_open_win(buf_ok, false, {
              relative = "editor",
              width = w,
              height = 1,
              row = row - 2,
              col = c,
              style = "minimal",
              border = "rounded",
              zindex = 600,
            })

        vim.defer_fn(function()
          if
              vim.api.nvim_win_is_valid(win_ok)
          then
            vim.api.nvim_win_close(win_ok, true)
          end
        end, 1500)

        close_all()
      end

      ---------------------------------------------------------------------------
      -- ENTER KEY
      ---------------------------------------------------------------------------
      vim.keymap.set("n", "<CR>", function()
        apply_selected_reset()
      end, { buffer = buf })

      ---------------------------------------------------------------------------
      -- APPLY RESET ON M/S/H/C
      ---------------------------------------------------------------------------
      for i, opt in ipairs(options) do
        vim.keymap.set("n", opt.key, function()
          if opt.cmd == nil then
            close_all()
            return
          end

          local show_error =
              make_show_error(row, height, ui)

          if has_worktree_changes() then
            show_error(
              "Cannot reset: work tree has uncommitted changes"
            )
            return
          end

          vim.fn.system(opt.cmd)

          -- success popup
          local buf_ok =
              vim.api.nvim_create_buf(false, true)
          local msg = opt.label .. " → " .. hash
          vim.api.nvim_buf_set_lines(
            buf_ok,
            0,
            -1,
            false,
            { msg }
          )
          vim.api.nvim_buf_add_highlight(
            buf_ok,
            -1,
            opt.hl,
            0,
            0,
            -1
          )

          local w = #msg + 4
          local c = math.floor((ui.width - w) / 2)
          local win_ok =
              vim.api.nvim_open_win(buf_ok, false, {
                relative = "editor",
                width = w,
                height = 1,
                row = row - 2,
                col = c,
                style = "minimal",
                border = "rounded",
                zindex = 600,
              })

          vim.defer_fn(function()
            if
                vim.api.nvim_win_is_valid(win_ok)
            then
              vim.api.nvim_win_close(win_ok, true)
            end
          end, 1500)

          close_all()
        end, { buffer = buf })
      end

      ---------------------------------------------------------------------------
      -- EXIT
      ---------------------------------------------------------------------------
      vim.keymap.set("n", "q", function()
        close_all()
      end, { buffer = buf })

      vim.keymap.set("n", "<Esc>", function()
        close_all()
      end, { buffer = buf })
    end, { noremap = true, silent = true })

    vim.keymap.set("n", "j", function()
      local win = vim.api.nvim_get_current_win()

      -- If cursor is in the right window, scroll preview instead of moving selection
      if win == Ui.right_win then
        vim.cmd("normal! j")
        return
      end

      -- Compute max items for current mode (branches, files, stashes)
      local max_items = (
            Ui.mode == "branches" and #Ui.branches
          )
          or (Ui.mode == "files" and #Ui.changed_files)
          or (Ui.mode == "stashes" and #Ui.stashes)
          or 0

      Ui.selected_index =
          math.min(max_items, Ui.selected_index + 1)

      refresh_ui()
    end, {
      buffer = buf,
      noremap = true,
      silent = true,
    })

    vim.keymap.set("n", "k", function()
      local win = vim.api.nvim_get_current_win()

      -- If cursor is in the right window, scroll preview instead of moving selection
      if win == Ui.right_win then
        vim.cmd("normal! k")
        return
      end

      -- Move selection up
      Ui.selected_index =
          math.max(1, Ui.selected_index - 1)

      refresh_ui()
    end, {
      buffer = buf,
      noremap = true,
      silent = true,
    })

    -- Keymap for <Space>
    vim.keymap.set("n", "<Space>", function()
      local win = vim.api.nvim_get_current_win()
      if win ~= Ui.left_win then
        return -- Only operate in left panel
      end

      if Ui.mode == "files" then
        stage_unstage_selected()
        render_left() -- refresh UI so staging is visible
      elseif Ui.mode == "branches" then
        checkout_branch()
      end
    end, {
      buffer = buf,
      noremap = true,
      silent = true,
    })

    -- Commit Keymap
    vim.keymap.set("n", "c", function()
      if
          Ui.mode ~= "branch"
          and Ui.mode ~= "files"
      then
        return
      end

      local branch =
          Ui.branches[Ui.selected_index]
      if not branch or branch == "" then
        branch = Ui.branch_selected or "HEAD"
      end

      local width =
          math.floor(vim.o.columns * 0.9)
      local height_title = 1
      local height_desc = 4
      local height_diff =
          math.floor(vim.o.lines * 0.72) -- taller diff
      local spacing = 1
      local col =
          math.floor((vim.o.columns - width) / 2)

      -- =========================
      -- Background overlay
      -- =========================
      local buf_overlay =
          vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(
        buf_overlay,
        0,
        -1,
        false,
        { string.rep(" ", width) }
      )
      local win_overlay = vim.api.nvim_open_win(
        buf_overlay,
        false,
        {
          relative = "editor",
          width = vim.o.columns,
          height = vim.o.lines,
          row = 0,
          col = 0,
          style = "minimal",
          border = "none",
          zindex = 200,
        }
      )

      -- =========================
      -- Buffers
      -- =========================
      local buf_diff =
          vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_option(
        buf_diff,
        "buftype",
        "nofile"
      )
      vim.api.nvim_buf_set_option(
        buf_diff,
        "bufhidden",
        "wipe"
      )
      vim.api.nvim_buf_set_option(
        buf_diff,
        "filetype",
        "diff"
      )

      local diff_cmd = "git diff --cached "
          .. vim.fn.shellescape(branch)
      local diff_lines =
          vim.fn.systemlist(diff_cmd)
      if
          vim.v.shell_error ~= 0
          or #diff_lines == 0
      then
        diff_lines = { "[No staged changes]" }
      end
      vim.api.nvim_buf_set_lines(
        buf_diff,
        0,
        -1,
        false,
        diff_lines
      )
      vim.api.nvim_buf_set_option(
        buf_diff,
        "modifiable",
        false
      )

      local buf_title =
          vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_option(
        buf_title,
        "buftype",
        "acwrite"
      )
      vim.api.nvim_buf_set_option(
        buf_title,
        "bufhidden",
        "wipe"
      )
      vim.api.nvim_buf_set_lines(
        buf_title,
        0,
        -1,
        false,
        { "" }
      )

      local buf_desc =
          vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_option(
        buf_desc,
        "buftype",
        "acwrite"
      )
      vim.api.nvim_buf_set_option(
        buf_desc,
        "bufhidden",
        "wipe"
      )
      vim.api.nvim_buf_set_lines(
        buf_desc,
        0,
        -1,
        false,
        { "", "", "" }
      )

      -- =========================
      -- Windows (diff top, commit bottom)
      -- =========================
      local win_diff =
          vim.api.nvim_open_win(buf_diff, false, {
            relative = "editor",
            width = width,
            height = height_diff - 3,
            row = 4,
            col = col,
            style = "minimal",
            border = "rounded",
            zindex = 300,
            focusable = true,
            title = " Commit ",
            title_pos = "center",
          })

      local win_title =
          vim.api.nvim_open_win(buf_title, true, {
            relative = "editor",
            width = width,
            height = height_title,
            row = 2 + height_diff + spacing,
            col = col,
            style = "minimal",
            border = "rounded",
            zindex = 300,
            title = " Title ",
            title_pos = "center",
          })

      local win_desc =
          vim.api.nvim_open_win(buf_desc, true, {
            relative = "editor",
            width = width,
            height = height_desc - 1,
            row = height_diff + height_title + 5,
            col = col,
            style = "minimal",
            border = "rounded",
            zindex = 300,
            title = " Description ",
            title_pos = "center",
          })

      -- =========================
      -- Close popup helper
      -- =========================
      local function close_commit_popup()
        for _, w in ipairs({
          win_title,
          win_desc,
          win_diff,
          win_overlay,
        }) do
          if vim.api.nvim_win_is_valid(w) then
            vim.api.nvim_win_close(w, true)
          end
        end
        if
            Ui.full_win
            and vim.api.nvim_win_is_valid(
              Ui.full_win
            )
        then
          vim.api.nvim_set_current_win(
            Ui.left_win
          )
          focus_left()
        end
      end

      -- =========================
      -- Commit logic
      -- =========================
      local function commit_changes()
        local title = vim.api.nvim_buf_get_lines(
          buf_title,
          0,
          -1,
          false
        )[1] or ""
        local body = table.concat(
          vim.api.nvim_buf_get_lines(
            buf_desc,
            0,
            -1,
            false
          ),
          "\n"
        )

        vim.fn.system("git add -A")
        local cmd = "git commit -m "
            .. vim.fn.shellescape(title)
        if body:match("%S") then
          cmd = cmd
              .. " -m "
              .. vim.fn.shellescape(body)
        end
        vim.fn.system(cmd)
        show_centered_message(
          "Committed changes on branch: "
          .. branch,
          "🌸"
        )
        close_commit_popup()
      end

      -- =========================
      -- Keymaps
      -- =========================
      for _, b in ipairs({
        buf_title,
        buf_desc,
        buf_diff,
      }) do
        vim.keymap.set(
          "n",
          "q",
          close_commit_popup,
          {
            buffer = b,
            noremap = true,
            silent = true,
          }
        )
        vim.keymap.set(
          "n",
          "<Esc>",
          close_commit_popup,
          {
            buffer = b,
            noremap = true,
            silent = true,
          }
        )

        vim.keymap.set("n", "<Tab>", function()
          vim.api.nvim_set_current_win(win_desc)
        end, { buffer = b })
        vim.keymap.set("n", "<S-Tab>", function()
          vim.api.nvim_set_current_win(win_title)
        end, { buffer = b })

        vim.keymap.set("n", "<C-d>", function()
          vim.api.nvim_win_call(
            win_diff,
            function()
              vim.cmd("normal! <C-d>")
            end
          )
        end, {
          buffer = buf_diff,
          noremap = true,
          silent = false,
        })

        vim.keymap.set("n", "<C-b>", function()
          vim.api.nvim_win_call(
            win_diff,
            function()
              vim.cmd("normal! <C-b>")
            end
          )
        end, {
          buffer = buf_diff,
          noremap = true,
          silent = false,
        })
      end

      vim.keymap.set(
        "n",
        "<CR>",
        commit_changes,
        {
          buffer = buf_title,
          noremap = true,
          silent = true,
        }
      )
      vim.keymap.set(
        "n",
        "<CR>",
        commit_changes,
        {
          buffer = buf_desc,
          noremap = true,
          silent = true,
        }
      )

      -- Start typing in title
      vim.api.nvim_set_current_win(win_title)
      vim.cmd("startinsert")
    end)

    -- Delete branch
    vim.keymap.set("n", "d", function()
      local win = vim.api.nvim_get_current_win()
      if win ~= Ui.left_win then
        return
      end

      if Ui.mode == "files" then
        discard_changes_selected()
      else
        delete_branch()
      end
    end, {
      buffer = buf,
      noremap = true,
      silent = true,
    })

    -- Pull latest changes
    vim.keymap.set("n", "p", function()
      if Ui.mode ~= "branches" then
        return
      end
      local branch =
          Ui.branches[Ui.selected_index]
      if not branch or branch == "" then
        show_centered_message(
          "No branch selected",
          vim.log.levels.WARN
        )
        return
      end

      local cmd = "git pull origin " .. branch
      vim.fn.system(cmd)
      show_centered_message(
        "Pulled latest changes for branch: "
        .. branch,
        vim.log.levels.INFO
      )
      refresh_ui()
    end, {
      buffer = buf,
      noremap = true,
      silent = true,
    })

    -- Push branch
    vim.keymap.set("n", "P", function()
      local current_branch = branch or Ui.branch_selected or "HEAD"
      local remote = "origin"
      print("DEBUG: Starting push for branch:", current_branch)

      local spinner_chars = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
      local spinner_idx = 1

      -- Spinner window
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false,
        { "Pushing to " .. current_branch .. " " .. spinner_chars[spinner_idx] })
      local ui = vim.api.nvim_list_uis()[1]
      local win = vim.api.nvim_open_win(buf, false, {
        relative = "editor",
        width = 50,
        height = 1,
        row = 2,
        col = math.floor((ui.width - 50) / 2),
        style = "minimal",
        border = "rounded",
        zindex = 50,
      })

      local spinner_timer = vim.loop.new_timer()
      spinner_timer:start(100, 100, vim.schedule_wrap(function()
        if not vim.api.nvim_win_is_valid(win) then
          spinner_timer:stop()
          spinner_timer:close()
          return
        end
        spinner_idx = spinner_idx % #spinner_chars + 1
        vim.api.nvim_buf_set_lines(buf, 0, -1, false,
          { "✨ Pushing To " .. current_branch .. " " .. spinner_chars[spinner_idx] })
      end))

      local function do_push(force)
        local args = { "git", "push", "-u", remote, current_branch }
        if force then table.insert(args, 3, "--force") end
        print("DEBUG: running git args", vim.inspect(args))

        vim.fn.jobstart(args, {
          stdout_buffered = true,
          stderr_buffered = true,
          on_exit = function(_, exit_code, _)
            spinner_timer:stop()
            spinner_timer:close()
            vim.schedule(function()
              if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
              if exit_code == 0 then
                print("DEBUG: push succeeded")
                show_centered_message("✅ Successfully pushed branch: " .. current_branch)
              else
                print("DEBUG: push failed for other reason")
                show_centered_message(" Failed to push branch: " .. current_branch)
              end
            end)
          end,
        })
      end

      -- Run a dry-run push first to detect divergence
      local dry_output = vim.fn.system("git push --dry-run -u " .. remote .. " " .. current_branch .. " 2>&1")
      print("DEBUG: dry-run output:\n" .. dry_output)
      if dry_output:match("rejected") or dry_output:match("non-fast-forward") then
        local answer = vim.fn.input("Branch has diverged. Force push? (y/N): ")
        if answer:lower() == "y" then
          do_push(true)
        else
          print("DEBUG: user declined force push")
          show_centered_message("Push aborted.")
        end
      else
        do_push(false)
      end

      refresh_ui()
    end)


    -- n keymap to create new branches off of selected branch
    vim.keymap.set("n", "n", function()
      if not Ui.branch_selected then return end
      if vim.api.nvim_get_current_win() ~= branch_ui_win then
        return -- ignore outside branch window
      end
      local current_branch = Ui.branch_selected
      if not current_branch or current_branch == "" then
        vim.notify("No branch selected!", vim.log.levels.ERROR)
        return
      end

      local function show_centered_error(msg)
        local buf = vim.api.nvim_create_buf(false, true)
        local lines = vim.split(msg, "\n")
        vim.api.nvim_buf_set_lines(
          buf,
          0,
          -1,
          false,
          vim.split(msg, "\n")
        )

        vim.api.nvim_set_hl(
          0,
          "CenteredError",
          { fg = "#FF5555", bold = true }
        )

        -- Apply highlight to all lines
        for i = 0, #lines - 1 do
          vim.api.nvim_buf_add_highlight(
            buf,
            -1,
            "CenteredError",
            i,
            0,
            -1
          )
        end

        local width = 60
        local height = #lines
        local ui = vim.api.nvim_list_uis()[1]

        local win = vim.api.nvim_open_win(buf, false, {
          relative = "editor",
          width = width,
          height = height,
          row = 2,
          col = math.floor((ui.width - width) / 2),
          style = "minimal",
          border = "rounded",
          zindex = 50,
        })

        vim.api.nvim_buf_set_option(
          buf,
          "modifiable",
          false
        )
        -- Auto close after 3 seconds
        vim.defer_fn(function()
          if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
          end
        end, 2000)
      end

      -- Check for uncommitted changes using systemlist
      local status = vim.fn.systemlist("git status --porcelain")
      if #status > 0 then
        show_centered_error(
          "🚨 You have uncommitted changes!\nCommit, stash, or discard them before switching branches."
        )
        return
      end

      -- Window size
      local width, height = 50, 1
      local ui = vim.api.nvim_list_uis()[1]
      local buf = vim.api.nvim_create_buf(false, true)

      -- Open floating window with a title
      local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = 3,
        col = math.floor((ui.width - width) / 2),
        style = "minimal",
        border = "rounded",
        title = " Create New Branch: " .. current_branch .. " ",
        title_pos = "center",
        zindex = 50,
      })

      -- Start insert mode at second line
      vim.api.nvim_win_set_cursor(win, { 1, 0 })
      vim.cmd("startinsert")

      -- Keymap for Enter to create branch
      -- Normal mode mapping inside the buffer
      -- after creating `buf` and `win`
      -- set normal mode mapping for Enter
      vim.keymap.set("n", "<CR>", function()
        local new_branch = vim.api.nvim_get_current_line()
        vim.api.nvim_win_close(win, true)

        if new_branch == "" then
          print("Aborted: no branch name entered")
          return
        end

        -- Spinner
        local spinner_chars = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
        local spinner_idx = 1
        local spin_buf = vim.api.nvim_create_buf(false, true)
        local spin_win = vim.api.nvim_open_win(spin_buf, false, {
          relative = "editor",
          width = 50,
          height = 1,
          row = 2,
          col = math.floor((vim.api.nvim_list_uis()[1].width - 50) / 2),
          style = "minimal",
          border = "rounded",
          zindex = 50,
        })

        local spinner_timer = vim.loop.new_timer()
        spinner_timer:start(100, 100, vim.schedule_wrap(function()
          if not vim.api.nvim_win_is_valid(spin_win) then
            spinner_timer:stop()
            spinner_timer:close()
            return
          end
          spinner_idx = spinner_idx % #spinner_chars + 1
          vim.api.nvim_buf_set_lines(spin_buf, 0, -1, false,
            { "✨ Creating new branch " .. new_branch .. " " .. spinner_chars[spinner_idx] })
        end))

        vim.fn.jobstart({ "git", "checkout", "-b", new_branch, current_branch }, {
          on_exit = function(_, exit_code)
            spinner_timer:stop()
            spinner_timer:close()
            vim.schedule(function()
              if vim.api.nvim_win_is_valid(spin_win) then
                vim.api.nvim_win_close(spin_win, true)
              end
              if exit_code == 0 then
                print("✅ Created new branch '" .. new_branch .. "' from '" .. current_branch .. "'")
              else
                print(" Failed to create branch '" .. new_branch .. "'")
              end
            end)
          end,
        })
      end, { buffer = buf, noremap = true, silent = true })

      -- Keymap to quit the floating window with 'q' in normal mode
      vim.api.nvim_buf_set_keymap(buf, "n", "q",
        [[<Cmd>lua vim.api.nvim_win_close(0, true)<CR>]],
        { noremap = true, silent = true }
      )
    end, {
      noremap = true,
      silent = true,
      desc = "Create new branch from selected",
    })


    -- Close UI
    vim.keymap.set("n", "q", close_ui, {
      buffer = buf,
      noremap = true,
      silent = true,
    })
  end

  -- Apply keymaps to both buffers
  set_keymaps(Ui.left_buf)
  set_keymaps(Ui.right_buf)
  refresh_ui()
  init_ui()
end

return M
