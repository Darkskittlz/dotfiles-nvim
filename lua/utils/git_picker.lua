-- git_picker_no_telescope.lua
---@diagnostic disable: undefined-global
local M = {}

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
local function draw_fake_title(buf, title)
  vim.api.nvim_buf_set_option(
    buf,
    "modifiable",
    true
  )
  local w =
    vim.api.nvim_win_get_width(Ui.left_win)
  local pad = math.floor((w - #title) / 2)
  local line = "┌"
    .. string.rep("─", pad)
    .. title
    .. string.rep("─", pad)
    .. "┐"
  vim.api.nvim_buf_set_lines(
    buf,
    0,
    0,
    false,
    { line }
  )
  vim.api.nvim_buf_add_highlight(
    buf,
    -1,
    "GitPickerTitle",
    0,
    0,
    -1
  )
  vim.api.nvim_buf_set_option(
    buf,
    "modifiable",
    false
  )
end

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

  -- Reorder so current branch is first
  table.sort(cleaned, function(a, b)
    if a == current then
      return true
    end
    if b == current then
      return false
    end
    return a < b -- optional: alphabetical for others
  end)

  Ui.branches = cleaned

  -- Default selected branch is the first one (current branch)
  Ui.branch_selected = Ui.branch_selected
    or Ui.branches[1]
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

  local lines = {} -- lines to write
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
      -- print(
      --   "render_left: branch",
      --   i,
      --   b,
      --   "marker:",
      --   marker
      -- )
      table.insert(
        lines,
        string.format("%2s %s", marker, b)
      )
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
      -- print(
      --   string.format(
      --     "render_left: file[%d] = %s staged=%s",
      --     i,
      --     f.value,
      --     tostring(f.staged)
      --   )
      -- )
      local prefix = f.staged and "[S]" or "[U]"
      -- print("render_left: prefix =", prefix)
      local line = string.format(
        "%s %s %s",
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

  vim.api.nvim_buf_set_option(
    Ui.right_buf,
    "modifiable",
    true
  )

  local out = {}

  if Ui.mode == "branches" then
    local branch = Ui.branch_selected or "HEAD"
    out = run_git(
      "git log --oneline --decorate "
        .. vim.fn.shellescape(branch)
    )
    if #out == 0 then
      out = { "[No commits]" }
    end
    vim.api.nvim_buf_set_option(
      Ui.right_buf,
      "filetype",
      "gitcommit"
    )
  else
    local sel =
      Ui.changed_files[Ui.selected_index]
    out = sel and get_diff_for_target(sel.value)
      or { "[No file selected]" }
    vim.api.nvim_buf_set_option(
      Ui.right_buf,
      "filetype",
      "diff"
    )
  end

  vim.api.nvim_buf_set_lines(
    Ui.right_buf,
    0,
    -1,
    false,
    out
  )
  vim.api.nvim_buf_set_option(
    Ui.right_buf,
    "modifiable",
    false
  )
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

  -- Update the title of the left window dynamically
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
    return
  end

  local sel = Ui.changed_files[Ui.selected_index]
  if not sel then
    return
  end

  if
    vim.fn.confirm(
      "Discard changes to " .. sel.value .. "?",
      "Yes\nNo",
      2
    ) ~= 1
  then
    return
  end

  local root = git_root()
  local cmd =
    { "git", "restore", root .. "/" .. sel.value }
  vim.fn.system(cmd)
  refresh_ui()
end

local function make_transparent_highlights()
  local groups = {
    "Normal",
    "NormalNC",
    "NormalFloat",
    "FloatBorder",
  }

  for _, group in ipairs(groups) do
    local existing =
      vim.api.nvim_get_hl(0, { name = group })
    -- Preserve fg if it exists, just clear bg
    vim.api.nvim_set_hl(0, group, {
      fg = existing.fg,
      bg = "none",
      bold = existing.bold,
      italic = existing.italic,
      underline = existing.underline,
    })
  end
end

-- Checkout the selected branch
local function checkout_branch()
  if Ui.mode ~= "branches" then
    return
  end
  local branch = Ui.branches[Ui.selected_index]
  if not branch then
    return
  end

  -- print("Checking out branch:", branch)
  vim.fn.system(
    "git checkout " .. vim.fn.shellescape(branch)
  )
  Ui.branch_selected = branch
  refresh_ui()

  -- Reapply transparency
  vim.defer_fn(make_transparent_highlights, 50)
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
    vim.notify(
      "Failed to delete branch: " .. out,
      vim.log.levels.ERROR
    )
  else
    vim.notify(
      "Deleted branch: " .. branch,
      vim.log.levels.INFO
    )
  end

  -- reload branch list and refresh UI
  load_branches()
  refresh_ui()
  draw_fake_title(
    Ui.left_buf,
    (Ui.mode == "branches") and " Git Branches "
      or " Files Changed "
  )
end

-- Open UI
function M.open_git_ui()
  -- Create buffers
  Ui.right_buf =
    vim.api.nvim_create_buf(false, true)
  Ui.left_buf =
    vim.api.nvim_create_buf(false, true)

  -- Determine sizes
  local w = 90 -- width of each window
  local top_h = 5
  local bottom_h = 25
  local total_h = top_h + bottom_h + 1 -- +1 for spacing between windows

  -- Get Neovim UI dimensions
  local ui = vim.api.nvim_list_uis()[1]
  local editor_w = ui.width
  local editor_h = ui.height

  -- Compute centered position
  local row = math.floor((editor_h - total_h) / 2)
  local col = math.floor((editor_w - w) / 2)

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
  full_win =
    vim.api.nvim_open_win(blank_buf, false, {
      relative = "editor",
      width = ui.width,
      height = ui.height,
      row = 0,
      col = 0,
      style = "minimal",
      border = "none",
      zindex = 1, -- LOW zindex
      focusable = false, -- won't steal input
    })

  -- Git picker left window
  Ui.left_win =
    vim.api.nvim_open_win(Ui.left_buf, true, {
      relative = "editor",
      width = w,
      height = top_h,
      row = row,
      col = col,
      style = "minimal",
      border = "rounded",
      title = (Ui.mode == "branches")
          and " Git Branches "
        or " Files Changed ",
      title_pos = "center",
      zindex = 10, -- HIGHER than blank
    })

  -- Git picker right window
  Ui.right_win =
    vim.api.nvim_open_win(Ui.right_buf, false, {
      relative = "editor",
      width = w,
      height = bottom_h,
      row = row + top_h + 2,
      col = col,
      style = "minimal",
      border = "rounded",
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
  Ui.mode = "branches"
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
      full_win
      and vim.api.nvim_win_is_valid(full_win)
    then
      vim.api.nvim_win_close(full_win, true)
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
    vim.keymap.set("n", "j", function()
      local max_items = (
        Ui.mode == "branches" and #Ui.branches
        or #Ui.changed_files
      )
      Ui.selected_index =
        math.min(max_items, Ui.selected_index + 1)
      refresh_ui()
    end, {
      buffer = buf,
      noremap = true,
      silent = true,
    })
    vim.keymap.set("n", "k", function()
      Ui.selected_index =
        math.max(1, Ui.selected_index - 1)
      refresh_ui()
    end, {
      buffer = buf,
      noremap = true,
      silent = true,
    })
    vim.keymap.set("n", "j", function()
      local win = vim.api.nvim_get_current_win()
      if win == Ui.right_win then
        -- Scroll preview window down
        vim.cmd("normal! j")
        return
      end

      -- Scroll selection in left panel
      local max_items = (
        Ui.mode == "branches" and #Ui.branches
        or #Ui.changed_files
      )
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
      if win == Ui.right_win then
        -- Scroll preview window up
        vim.cmd("normal! k")
        return
      end

      -- Scroll selection in left panel
      Ui.selected_index =
        math.max(1, Ui.selected_index - 1)
      refresh_ui()
    end, {
      buffer = buf,
      noremap = true,
      silent = true,
    })

    -- Actions
    vim.keymap.set("n", "<Space>", function()
      local win = vim.api.nvim_get_current_win()
      if win ~= Ui.left_win then
        return -- Only operate in left panel
      end

      if Ui.mode == "files" then
        stage_unstage_selected()
      elseif Ui.mode == "branches" then
        checkout_branch()
      end
    end, {
      buffer = buf,
      noremap = true,
      silent = true,
    })

    vim.keymap.set("n", "D", function()
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
    -- Open file in editor
    vim.keymap.set("n", "o", function()
      if Ui.mode ~= "files" then
        return
      end
      local sel =
        Ui.changed_files[Ui.selected_index]
      if sel then
        vim.cmd(
          "edit "
            .. vim.fn.fnameescape(
              git_root() .. "/" .. sel.value
            )
        )
      end
    end, {
      buffer = buf,
      noremap = true,
      silent = true,
    })

    -- Render preview
    vim.keymap.set("n", "p", function()
      render_right()
      focus_right()
    end, {
      buffer = buf,
      noremap = true,
      silent = true,
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
  draw_header(Ui.left_buf)
end

return M
