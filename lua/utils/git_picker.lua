---@diagnostic disable: undefined-global

local M = {}

local overlay_win = nil
local overlay_buf = nil


local function create_picker_overlay()
  overlay_buf = vim.api.nvim_create_buf(false, true)
  overlay_win = vim.api.nvim_open_win(overlay_buf, false, {
    relative = "editor",
    width = vim.o.columns,
    height = vim.o.lines,
    row = 0,
    col = 0,
    style = "minimal",
    focusable = false,
    zindex = 50, -- below Telescope picker
    border = "none",
  })
  local ns = vim.api.nvim_create_namespace("GitPickerOverlay")
  vim.api.nvim_set_hl(0, "GitPickerOverlay", { bg = "#000000", blend = 80 })
  vim.api.nvim_win_set_hl_ns(overlay_win, ns)
  vim.api.nvim_buf_set_option(overlay_buf, "modifiable", false)
end

local function remove_picker_overlay()
  if overlay_win and vim.api.nvim_win_is_valid(overlay_win) then
    vim.api.nvim_win_close(overlay_win, true)
  end
  overlay_win = nil
  overlay_buf = nil
end

local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
  vim.notify("Telescope is not installed", vim.log.levels.ERROR)
  return M
end

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")
local entry_display = require("telescope.pickers.entry_display")


-- Highlight for current branch
vim.api.nvim_set_hl(0, "GitBranchCurrent", { fg = "#549afc", bold = true })

-- Displayer for columns
local displayer = entry_display.create {
  separator = "",
  items = {
    { width = 30 },       -- branch name column
    { remaining = true }, -- info column
  },
}

local function reopen_git_picker()
  vim.defer_fn(function()
    -- replace with your actual git picker function
    require("utils.git_picker").git_branch_picker()
  end, 100)
end

local function create_file_diff_previewer()
  return previewers.new_termopen_previewer({
    title = function() return "Diff" end,
    get_command = function(entry)
      local branch_name = (entry and entry.value) or "HEAD"
      -- Show diff for the branch (or file if selected)
      return { "git", "diff", branch_name }
    end,
  })
end

-- Preview modes
local preview_modes = {
  {
    name = "Diff",
    cmd_fn = function(branch) return { "git", "diff", branch } end,
    cmd_fn_preview = function(branch) return create_file_diff_previewer() end,
  },
  {
    name = "Log",
    cmd_fn = function(branch) return { "git", "log", "--oneline", branch } end,
  },
  {
    name = "Reflog",
    cmd_fn = function(branch) return { "git", "reflog", "--oneline", branch } end,
  },
}

local function get_branch_info(branch)
  local info = { staged = 0, unstaged = 0, ahead = 0, behind = 0, files_changed = 0 }
  local current_branch = vim.fn.systemlist("git rev-parse --abbrev-ref HEAD")[1] or ""

  if not branch or branch == "" then return info end

  -- Only current branch can have local changes
  if branch == current_branch then
    local changes = vim.fn.systemlist("git status --porcelain") or {}
    for _, line in ipairs(changes) do
      local x, y = line:sub(1, 1), line:sub(2, 2)
      if x ~= " " then info.staged = info.staged + 1 end
      if y ~= " " then info.unstaged = info.unstaged + 1 end
    end

    local files = vim.fn.systemlist("git diff --name-only HEAD") or {}
    info.files_changed = #files
  end

  -- Always check ahead/behind for any branch
  local ok, upstream = pcall(vim.fn.systemlist, "git rev-parse --abbrev-ref " .. branch .. "@{upstream}")
  if ok and upstream[1] and upstream[1] ~= "" then
    local counts = vim.fn.systemlist(
      "git rev-list --left-right --count " .. branch .. "...@{upstream}"
    )[1]
    if counts then
      local ahead, behind = counts:match("(%d+)%s+(%d+)")
      info.ahead = tonumber(ahead) or 0
      info.behind = tonumber(behind) or 0
    end
  end

  return info
end

-- Get changed files in the branch
local function get_changed_files(branch)
  branch = branch or "HEAD"

  -- `git diff --name-status <branch>` lists changed files
  local files = vim.fn.systemlist("git diff --name-status " .. branch)
  local results = {}

  for _, line in ipairs(files) do
    -- line is like "M\tpath/to/file.lua" or "A\tnewfile.txt"
    local status, path = line:match("^(%S+)%s+(.*)$")
    if path then
      table.insert(results, { value = path, status = status })
    end
  end

  return results
end

local function branch_entry_maker(branch)
  local current_branch = vim.fn.systemlist("git rev-parse --abbrev-ref HEAD")[1] or ""

  local display_fn = function(entry)
    local info = get_branch_info(entry.value) -- recalc for this branch
    local parts = {}
    local is_current = entry.value == current_branch

    -- Branch name with * for current, always blue
    table.insert(parts, {
      (is_current and "* " or "") .. entry.value,
      is_current and "GitBranchCurrent" or "Normal",
    })

    -- Staged/unstaged changes (only current branch)
    if info.staged > 0 then
      table.insert(parts, { " ● " .. info.staged, "DiffAdd" })
    end
    if info.unstaged > 0 then
      table.insert(parts, { " ✚ " .. info.unstaged, "DiffChange" })
    end

    -- Files changed (only current branch)
    if is_current and info.files_changed > 0 then
      table.insert(parts, { string.format(" (%d file%s changed)", info.files_changed,
        info.files_changed > 1 and "s" or ""), "WarningMsg" })
    end

    -- Commits ahead/behind
    -- if info.ahead > 0 then
    --   table.insert(parts, { " ↑" .. info.ahead, "DiffAdd" })
    -- end
    -- if info.behind > 0 then
    --   table.insert(parts, { " ↓" .. info.behind, "WarningMsg" })
    -- end

    return displayer(parts)
  end

  return {
    value = branch,
    ordinal = branch,
    display = display_fn,
  }
end

-- Sort branches with current branch first
local function sort_branches(branches)
  local current_branch = vim.fn.systemlist("git rev-parse --abbrev-ref HEAD")[1] or ""
  table.sort(branches, function(a, b)
    if a == current_branch then return true end
    if b == current_branch then return false end
    return a < b
  end)
  return branches
end

-- Previewer
local function create_git_previewer(branch, mode_index)
  local mode = preview_modes[mode_index]
  if not mode then
    vim.notify("Invalid preview mode", vim.log.levels.WARN)
    return previewers.new_termopen_previewer({})
  end

  return previewers.new_termopen_previewer({
    title = function() return mode.name end,
    get_command = function(entry)
      local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1] or "."
      local branch_name = (entry and entry.value) or branch or "HEAD"

      vim.print({ mode_index = mode_index, branch_name = branch_name, git_root = git_root })

      if mode_index == 1 then
        -- File diff
        local file_path = branch_name
        local cmd = { "git", "-C", git_root, "diff", "--color=always", file_path }
        vim.print({ git_diff_cmd = cmd })
        return cmd
      elseif mode_index == 2 then
        -- Git log
        local cmd = { "git", "-C", git_root, "log", "--oneline", branch_name }
        vim.print({ git_log_cmd = cmd })
        return cmd
      elseif mode_index == 3 then
        -- Git reflog
        local cmd = { "git", "-C", git_root, "reflog", branch_name }
        vim.print({ git_reflog_cmd = cmd })
        return cmd
      else
        -- fallback
        return { "echo", "[No preview]" }
      end
    end,
  })
end

-- Main function: displays Git branches or files changed depending on mode
function M.git_branch_picker_with_mode(selected_branch, mode_index)
  mode_index = mode_index or 1 -- default mode is 1 (diff mode)

  -- print("=== git_branch_picker_with_mode called ===")
  -- print("Mode index:", mode_index)
  -- print("Selected branch:", selected_branch)

  -- Mode 1 = show changed files, Mode 2+ = show branches
  local entries = {}
  local entry_maker = nil
  local picker_title = ""

  if mode_index == 1 then
    -- Get changed files for the selected branch
    local function get_changed_files(branch)
      branch = branch or "HEAD"
      local files = vim.fn.systemlist("git diff --name-status " .. branch)
      vim.print({ git_diff_output = files })

      local results = {}
      for _, line in ipairs(files) do
        local status, path = line:match("^(%S+)%s+(.*)$")
        if path then
          table.insert(results, { value = path, status = status })
        end
      end

      vim.print({ parsed_files = results })
      return results
    end

    -- Entry maker for files
    entry_maker = function(entry)
      -- entry = { value = filepath, status = git_status }
      return {
        value = entry.value,
        display = string.format("%s %s", entry.status or " ", entry.value),
        ordinal = entry.value,
      }
    end
    entries = get_changed_files(selected_branch)
    picker_title = "Changed Files: " .. (selected_branch or "HEAD")
  else
    -- Get branches normally
    local branches = vim.fn.systemlist("git branch --list --format='%(refname:short)'")
    vim.print({ branches = branches })
    if vim.tbl_isempty(branches) then
      vim.notify("No branches found", vim.log.levels.INFO)
      return
    end
    branches = sort_branches(branches)
    entries = branches
    entry_maker = branch_entry_maker
    picker_title = "Branches"
  end

  vim.print({ picker_title = picker_title })

  -- Build the Telescope picker
  pickers.new({}, {
    prompt_title = picker_title,
    finder = finders.new_table {
      results = entries,
      entry_maker = entry_maker,
    },
    sorter = conf.generic_sorter({}),
    layout_strategy = "vertical",
    layout_config = {
      vertical = {
        width = 0.8,
        height = 0.8,
        preview_cutoff = 0.3,
        preview_height = 0.6,
        prompt_position = "top",
      },
    },
    sorting_strategy = "ascending",

    -- Use diff previewer for files, default for branches
    previewer = create_git_previewer(selected_branch, mode_index),
    initial_mode = "normal",

    attach_mappings = function(prompt_bufnr, map)
      local current_mode = mode_index

      local function get_selection()
        local sel = action_state.get_selected_entry()
        return sel and sel.value or nil
      end

      local function get_current_branch()
        return vim.fn.systemlist("git rev-parse --abbrev-ref HEAD")[1] or "HEAD"
      end

      -- =========================
      -- Default action (Enter)
      -- =========================
      actions.select_default:replace(function()
        local entry = get_selection()
        vim.print({ selected_entry = entry, current_mode = current_mode })
        actions.close(prompt_bufnr)

        if not entry then return end

        if current_mode == 1 then
          local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
          if git_root and git_root ~= "" then
            local full_path = git_root .. "/" .. entry
            vim.cmd("edit " .. vim.fn.fnameescape(full_path))
          else
            vim.notify("Cannot determine git root", vim.log.levels.ERROR)
          end
        else
          vim.cmd("Git checkout " .. entry)
          vim.notify("Switched to branch: " .. entry, vim.log.levels.INFO)
        end
      end)
      print("Picker title:", picker_title)


      -- =========================
      -- Copy branch name (branch mode only)
      -- =========================
      map({ "i", "n" }, "y", function()
        if current_mode == 1 then return end
        local entry = get_selection()
        if entry then
          vim.fn.setreg("+", entry)
          vim.notify("Copied branch: " .. entry, vim.log.levels.INFO)
        end
      end)

      -- =========================
      -- Commit changes popup
      -- =========================
      map({ "i", "n" }, "c", function(prompt_bufnr)
        local branch = get_selection()
        if current_mode == 1 or not branch or branch == "" then
          branch = get_current_branch()
        end

        actions.close(prompt_bufnr)

        -- === Floating windows setup ===
        local width = math.floor(vim.o.columns * 0.6)
        local height_title = 1
        local height_desc = 3
        local height_diff = math.floor(vim.o.lines * 0.4)
        local spacing = 1
        local row = math.floor((vim.o.lines - (height_title + height_desc + height_diff + spacing * 2)) / 2)
        local col = math.floor((vim.o.columns - width) / 2)

        -- Buffers
        local buf_title = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_option(buf_title, "buftype", "acwrite")
        vim.api.nvim_buf_set_option(buf_title, "bufhidden", "wipe")
        vim.api.nvim_buf_set_lines(buf_title, 0, -1, false, { "" })

        local buf_desc = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_option(buf_desc, "buftype", "acwrite")
        vim.api.nvim_buf_set_option(buf_desc, "bufhidden", "wipe")
        vim.api.nvim_buf_set_lines(buf_desc, 0, -1, false, { "", "", "" })

        local buf_label = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_option(buf_label, "buftype", "nofile")
        vim.api.nvim_buf_set_option(buf_label, "bufhidden", "wipe")
        local commit_label = "Commit Message"
        local padding = math.floor((width - #commit_label) / 2)
        vim.api.nvim_buf_set_lines(buf_label, 0, -1, false, { string.rep(" ", padding) .. commit_label })

        local buf_diff = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_option(buf_diff, "buftype", "nofile")
        vim.api.nvim_buf_set_option(buf_diff, "bufhidden", "wipe")
        vim.api.nvim_buf_set_option(buf_diff, "filetype", "diff")

        -- Fill diff
        vim.api.nvim_buf_set_option(buf_diff, "modifiable", true)
        local diff_cmd = "git diff --cached " .. vim.fn.shellescape(branch)
        local diff_lines = vim.fn.systemlist(diff_cmd)
        if vim.v.shell_error ~= 0 or #diff_lines == 0 then
          diff_lines = { "[No staged changes]" }
        end
        vim.api.nvim_buf_set_lines(buf_diff, 0, -1, false, diff_lines)
        vim.api.nvim_buf_set_option(buf_diff, "modifiable", false)

        -- Windows
        local win_label = vim.api.nvim_open_win(buf_label, false, {
          relative = "editor",
          width = width,
          height = height_title,
          row = row,
          col = col,
          style = "minimal",
          border = "none",
          zindex = 300
        })
        local win_title = vim.api.nvim_open_win(buf_title, true, {
          relative = "editor",
          width = width,
          height = height_title,
          row = row + height_title,
          col = col,
          style = "minimal",
          border = "rounded",
          zindex = 300
        })
        local win_desc = vim.api.nvim_open_win(buf_desc, true, {
          relative = "editor",
          width = width,
          height = height_desc,
          row = row + height_title * 2 + 2,
          col = col,
          style = "minimal",
          border = "rounded",
          zindex = 300
        })
        local win_diff = vim.api.nvim_open_win(buf_diff, false, {
          relative = "editor",
          width = width,
          height = height_diff,
          row = row + height_title * 2 + height_desc + 4,
          col = col,
          style = "minimal",
          border = "rounded",
          zindex = 300
        })

        -- Close popup helper
        local function close_commit_popup()
          for _, w in ipairs({ win_label, win_title, win_desc, win_diff }) do
            if vim.api.nvim_win_is_valid(w) then
              vim.api.nvim_win_close(w, true)
            end
          end
          reopen_git_picker()
        end

        -- Commit logic
        local function commit_changes()
          local title = vim.api.nvim_buf_get_lines(buf_title, 0, -1, false)[1] or ""
          local body = table.concat(vim.api.nvim_buf_get_lines(buf_desc, 0, -1, false), "\n")
          vim.fn.system("git add -A")
          local cmd = 'git commit -m ' .. vim.fn.shellescape(title)
          if body:match("%S") then
            cmd = cmd .. ' -m ' .. vim.fn.shellescape(body)
          end
          vim.fn.system(cmd)
          vim.notify("Committed changes on branch: " .. branch, vim.log.levels.INFO)
          close_commit_popup()
        end

        -- Keymaps inside popup
        for _, buf in ipairs({ buf_title, buf_desc, buf_diff }) do
          vim.keymap.set("n", "q", close_commit_popup, { buffer = buf, noremap = true, silent = true })
          vim.keymap.set("n", "<Esc>", close_commit_popup, { buffer = buf, noremap = true, silent = true })
          vim.keymap.set("n", "<Tab>", function() vim.api.nvim_set_current_win(win_desc) end, { buffer = buf })
          vim.keymap.set("n", "<S-Tab>", function() vim.api.nvim_set_current_win(win_title) end, { buffer = buf })
        end
        vim.keymap.set("n", "<CR>", commit_changes, { buffer = buf_title, noremap = true, silent = true })
        vim.keymap.set("n", "<CR>", commit_changes, { buffer = buf_desc, noremap = true, silent = true })

        -- Scroll diff
        vim.keymap.set("n", "<C-j>", function()
          vim.api.nvim_win_call(win_diff, function() vim.cmd("normal! <C-e>") end)
        end, { buffer = buf_diff })
        vim.keymap.set("n", "<C-k>", function()
          vim.api.nvim_win_call(win_diff, function() vim.cmd("normal! <C-y>") end)
        end, { buffer = buf_diff })

        vim.api.nvim_set_current_win(win_title)
        vim.cmd("startinsert")
      end)

      -- =========================
      -- Branch-only actions
      -- =========================
      if current_mode > 1 then
        -- Pull
        map({ "i", "n" }, "p", function()
          local branch = get_selection()
          if branch then
            vim.fn.system("git pull origin " .. branch)
            vim.notify("Pulled latest changes for branch: " .. branch, vim.log.levels.INFO)
          end
        end)

        -- Push
        map({ "i", "n" }, "P", function()
          local branch = get_selection()
          if not branch or branch == "" then
            vim.notify("No branch selected", vim.log.levels.WARN)
            return
          end

          -- Push spinner logic here (your existing code)
          -- ...
        end)

        -- Delete branch
        map({ "i", "n" }, "d", function()
          local branch = get_selection()
          if not branch then return end
          vim.ui.input({ prompt = "Delete branch '" .. branch .. "'? (y/N): " }, function(input)
            if input and input:lower() == "y" then
              vim.fn.system("git branch -D " .. branch)
              vim.notify("Deleted branch: " .. branch, vim.log.levels.INFO)
              actions.close(prompt_bufnr)
            else
              vim.notify("Branch deletion canceled", vim.log.levels.INFO)
            end
          end)
        end)

        -- Space: switch branch
        map({ "i", "n" }, "<Space>", function()
          local branch = get_selection()
          if not branch then return end
          actions.close(prompt_bufnr)
          local result = vim.fn.system("git switch " .. branch)
          if vim.v.shell_error == 0 then
            vim.notify("Switched to branch: " .. branch, vim.log.levels.INFO)
            vim.defer_fn(function()
              M.git_branch_picker_with_mode(branch, 2) -- branch mode
            end, 50)
          else
            vim.notify("Failed to switch branch:\n" .. result, vim.log.levels.ERROR)
          end
        end)
      end

      -- =========================
      -- Cycle preview modes (both modes)
      -- =========================
      local function cycle_preview(direction)
        local entry = get_selection()
        if not entry then return end
        if direction == "next" then
          current_mode = (current_mode % #preview_modes) + 1
        else
          current_mode = (current_mode - 2) % #preview_modes + 1
        end
        actions.close(prompt_bufnr)
        vim.defer_fn(function()
          if current_mode == 1 then
            -- diff mode
            M.git_branch_picker_with_mode(nil, current_mode)
          else
            M.git_branch_picker_with_mode(entry, current_mode)
          end
        end, 50)
      end
      map({ "i", "n" }, "+", function() cycle_preview("next") end)
      map({ "i", "n" }, "_", function() cycle_preview("prev") end)

      -- Scroll preview
      map({ "n", "i" }, "<C-d>", actions.preview_scrolling_down)
      map({ "n", "i" }, "<C-b>", actions.preview_scrolling_up)

      -- Quit picker
      map("n", "q", function()
        remove_picker_overlay()
        actions.close(prompt_bufnr)
      end)

      return true
    end
  }):find()
end

-- Default entry point
function M.git_branch_picker()
  M.git_branch_picker_with_mode(nil, 2)
end

return M
