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

local function get_branch_files(branch)
  local files = { staged = {}, unstaged = {} }
  local current_branch = vim.fn.systemlist("git rev-parse --abbrev-ref HEAD")[1] or ""
  if branch ~= current_branch then return files end

  local status = vim.fn.systemlist("git status --porcelain")
  for _, line in ipairs(status) do
    local x, y = line:sub(1, 1), line:sub(2, 2)
    local file = line:sub(4)
    if x ~= " " then table.insert(files.staged, file) end
    if y ~= " " then table.insert(files.unstaged, file) end
  end
  return files
end

local function reopen_git_picker()
  vim.defer_fn(function()
    -- replace with your actual git picker function
    require("utils.git_picker").git_branch_picker()
  end, 100)
end


local function create_diff_hunk_previewer()
  return previewers.new_buffer_previewer({
    title = "Diff Preview",

    get_buffer_by_name = function(_, entry)
      return "Diff: " .. (entry and entry.value or "HEAD")
    end,

    define_preview = function(self, entry, status)
      local buf = self.state.bufnr
      if not entry or not entry.value then
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "No diff available" })
        return
      end

      local diff_lines = vim.fn.systemlist("git diff -- " .. entry.value) or {}

      -- find hunk line numbers
      local hunks = {}
      for i, line in ipairs(diff_lines) do
        if line:match("^@@ .* @@") then
          table.insert(hunks, i)
        end
      end

      vim.api.nvim_buf_set_option(buf, "modifiable", true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, diff_lines)
      vim.api.nvim_buf_set_option(buf, "modifiable", false)
      vim.api.nvim_buf_set_option(buf, "filetype", "diff")

      -- hunk navigation
      local current_hunk = 1
      local winid = self.state.winid
      local function nav_hunk(next)
        if not winid or not vim.api.nvim_win_is_valid(winid) then return end
        if #hunks == 0 then return end

        if next and current_hunk < #hunks then
          current_hunk = current_hunk + 1
        elseif not next and current_hunk > 1 then
          current_hunk = current_hunk - 1
        end

        local row = hunks[current_hunk]
        if not row or row < 1 then return end   -- safety check
        local max_row = vim.api.nvim_buf_line_count(buf)
        if row > max_row then row = max_row end -- clamp to last line
        vim.api.nvim_win_set_cursor(winid, { row, 0 })
      end

      local opts = { noremap = true, silent = true }
      vim.api.nvim_buf_set_keymap(buf, "n", "<C-h>", "", vim.tbl_extend("force", opts, {
        callback = function() nav_hunk(false) end
      }))
      vim.api.nvim_buf_set_keymap(buf, "n", "<C-l>", "", vim.tbl_extend("force", opts, {
        callback = function() nav_hunk(true) end
      }))
    end
  })
end


local function open_branch_file_picker(branch)
  local files = get_branch_files(branch)
  local all_files = {}

  for _, f in ipairs(files.staged) do
    table.insert(all_files, { path = f, status = "staged" })
  end
  for _, f in ipairs(files.unstaged) do
    table.insert(all_files, { path = f, status = "unstaged" })
  end

  if vim.tbl_isempty(all_files) then
    vim.notify("No changed files on branch " .. branch, vim.log.levels.INFO)
    return
  end

  pickers.new({
    initial_mode = "normal",
    layout_strategy = "vertical",
    layout_config = {
      vertical = {
        width = 0.85,
        height = 0.85,
        preview_cutoff = 0.25,
        preview_height = 0.75,
        prompt_position = "top",
      },
    },
  }, {
    prompt_title = "Changed Files (" .. branch .. ")",
    finder = finders.new_table {
      results = all_files,
      entry_maker = function(entry)
        local icon = entry.status == "staged" and "✓" or "○"
        local color = entry.status == "staged" and "DiffAdd" or "DiffChange"
        return {
          value = entry.path,
          ordinal = entry.path,
          display = function()
            return string.format("%s  %s [%s]", icon, entry.path, entry.status)
          end,
          hl = { { 0, 1, color } },
        }
      end,
    },
    sorter = conf.generic_sorter({}),
    previewer = create_diff_hunk_previewer(),

    attach_mappings = function(prompt_bufnr, map)
      local picker = action_state.get_current_picker(prompt_bufnr)
      local previewer = picker.previewer


      local diff_lines = {}
      if previewer and previewer.state and vim.api.nvim_buf_is_valid(previewer.state.bufnr) then
        diff_lines = vim.api.nvim_buf_get_lines(previewer.state.bufnr, 0, -1, false) or {}
      end

      local hunks = {}
      for i, line in ipairs(diff_lines) do
        if line:match("^@@ .* @@") then
          table.insert(hunks, i)
        end
      end

      local current_hunk = 1
      -- now you can define hunk navigation keymaps
      local function nav_hunk(next)
        if next and current_hunk < #hunks then
          current_hunk = current_hunk + 1
        elseif not next and current_hunk > 1 then
          current_hunk = current_hunk - 1
        end
        vim.api.nvim_win_set_cursor(0, { hunks[current_hunk], 0 })
      end

      map({ "n", "i" }, "<C-h>", function() nav_hunk(false) end)
      map({ "n", "i" }, "<C-l>", function() nav_hunk(true) end)


      local function refresh_list()
        -- rebuild file list dynamically
        local new_files = get_branch_files(branch)
        local refreshed = {}

        for _, f in ipairs(new_files.staged) do
          table.insert(refreshed, { path = f, status = "staged" })
        end
        for _, f in ipairs(new_files.unstaged) do
          table.insert(refreshed, { path = f, status = "unstaged" })
        end

        picker:refresh(finders.new_table {
          results = refreshed,
          entry_maker = function(entry)
            local icon = entry.status == "staged" and "✓" or "○"
            local color = entry.status == "staged" and "DiffAdd" or "DiffChange"
            return {
              value = entry.path,
              ordinal = entry.path,
              display = function()
                return string.format("%s  %s [%s]", icon, entry.path, entry.status)
              end,
              hl = { { 0, 1, color } },
            }
          end,
        }, { reset_prompt = false })
      end

      -- 🟢 SPACE = toggle stage/unstage without reload
      map({ "n", "i" }, "<Space>", function()
        local selection = action_state.get_selected_entry()
        if not selection then return end
        local is_staged = vim.fn.system("git diff --cached --name-only " .. selection.value)
        if is_staged:match(selection.value) then
          vim.fn.system("git restore --staged " .. selection.value)
          vim.notify("Unstaged: " .. selection.value, vim.log.levels.INFO)
        else
          vim.fn.system("git add " .. selection.value)
          vim.notify("Staged: " .. selection.value, vim.log.levels.INFO)
        end
        refresh_list()
      end)



      -- 🔴 D = discard local changes
      map({ "n", "i" }, "D", function()
        local selection = action_state.get_selected_entry()
        if not selection then return end
        local confirm = vim.fn.confirm("Discard all changes to " .. selection.value .. "?", "&Yes\n&No", 2)
        if confirm == 1 then
          vim.fn.system("git restore " .. selection.value)
          vim.notify("Discarded changes in " .. selection.value, vim.log.levels.WARN)
          refresh_list()
        end
      end)


      -- Diff previewer commit logic
      map({ "i", "n" }, "c", function(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if not selection then
          vim.notify("No branch selected — using current branch", vim.log.levels.WARN)
        end

        -- ✅ Get real branch name
        local branch = selection and selection.value
        if not branch or branch == "" then
          branch = vim.fn.systemlist("git rev-parse --abbrev-ref HEAD")[1] or "HEAD"
        end
        branch = vim.trim(branch)

        -- Close the branch picker temporarily
        actions.close(prompt_bufnr)

        -- Window dimensions
        local width = math.floor(vim.o.columns * 0.6)
        local height_title_win = 1
        local height_desc_win = 3
        local height_diff = math.floor(vim.o.lines * 0.4)
        local spacing = 1
        local row = math.floor((vim.o.lines - (height_title_win + height_desc_win + height_diff + spacing * 2)) / 2)
        local col = math.floor((vim.o.columns - width) / 2)

        -- 🟩 Buffers
        local buf_title = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_option(buf_title, "buftype", "acwrite")
        vim.api.nvim_buf_set_option(buf_title, "bufhidden", "wipe")
        vim.api.nvim_buf_set_lines(buf_title, 0, -1, false, { "" })

        local buf_desc = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_option(buf_desc, "buftype", "acwrite")
        vim.api.nvim_buf_set_option(buf_desc, "bufhidden", "wipe")
        vim.api.nvim_buf_set_lines(buf_desc, 0, -1, false, { "", "", "" })

        local commit_label = "Commit Message"
        local padding = math.floor((width - #commit_label) / 2)
        local centered_label = string.rep(" ", padding) .. commit_label

        -- 🏷 Label buffer
        local buf_label = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_option(buf_label, "buftype", "nofile")
        vim.api.nvim_buf_set_option(buf_label, "bufhidden", "wipe")
        vim.api.nvim_buf_set_lines(buf_label, 0, -1, false, { centered_label })

        -- 🟦 Diff buffer
        local buf_diff = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_option(buf_diff, "buftype", "nofile")
        vim.api.nvim_buf_set_option(buf_diff, "bufhidden", "wipe")
        vim.api.nvim_buf_set_option(buf_diff, "filetype", "diff")

        -- Fill diff
        vim.api.nvim_buf_set_option(buf_diff, "modifiable", true)
        local diff_cmd = "git diff --cached " .. vim.fn.shellescape(branch)
        local diff_lines = vim.fn.systemlist(diff_cmd)
        if vim.v.shell_error ~= 0 or #diff_lines == 0 then
          diff_lines = { "[No staged changes or unable to read diff]" }
        end
        vim.api.nvim_buf_set_lines(buf_diff, 0, -1, false, diff_lines)
        vim.api.nvim_buf_set_option(buf_diff, "modifiable", false)

        -- 🪟 Windows
        local height_label = 1
        local win_label = vim.api.nvim_open_win(buf_label, false, {
          relative = "editor",
          width = width,
          height = height_label,
          row = row,
          col = col,
          style = "minimal",
          border = "none",
          zindex = 300,
        })

        local win_title = vim.api.nvim_open_win(buf_title, true, {
          relative = "editor",
          width = width,
          height = height_title_win,
          row = row + height_label,
          col = col,
          style = "minimal",
          border = "rounded",
          zindex = 300,
        })

        local win_desc = vim.api.nvim_open_win(buf_desc, true, {
          relative = "editor",
          width = width,
          height = height_desc_win,
          row = row + height_label + height_title_win + 2,
          col = col,
          style = "minimal",
          border = "rounded",
          zindex = 300,
        })

        local win_diff = vim.api.nvim_open_win(buf_diff, false, {
          relative = "editor",
          width = width,
          height = height_diff,
          row = row + height_label + height_title_win + height_desc_win + 4,
          col = col,
          style = "minimal",
          border = "rounded",
          zindex = 300,
        })

        -- 🧹 Close + reopen picker
        local function close_commit_popup()
          for _, w in ipairs({ win_label, win_title, win_desc, win_diff }) do
            if vim.api.nvim_win_is_valid(w) then
              vim.api.nvim_win_close(w, true)
            end
          end

          reopen_git_picker()
        end

        -- 💾 Commit logic
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

        -- 🗝️ Keymaps
        for _, buf in ipairs({ buf_title, buf_desc, buf_diff }) do
          vim.keymap.set("n", "q", close_commit_popup, { buffer = buf, noremap = true, silent = true })
          vim.keymap.set("n", "<Esc>", close_commit_popup, { buffer = buf, noremap = true, silent = true })
        end

        vim.keymap.set("n", "<CR>", commit_changes, { buffer = buf_title, noremap = true, silent = true })
        vim.keymap.set("n", "<CR>", commit_changes, { buffer = buf_desc, noremap = true, silent = true })

        -- 🔁 Tab navigation
        local windows = { win_title, win_desc, win_diff }
        local function cycle_window(forward)
          local current = vim.api.nvim_get_current_win()
          local idx
          for i, w in ipairs(windows) do
            if w == current then
              idx = i
              break
            end
          end
          if not idx then return end
          local next_idx = forward and (idx % #windows + 1) or (idx - 2) % #windows + 1
          vim.api.nvim_set_current_win(windows[next_idx])
        end

        for _, buf in ipairs({ buf_title, buf_desc, buf_diff }) do
          vim.keymap.set("n", "<Tab>", function() cycle_window(true) end,
            { buffer = buf, noremap = true, silent = true })
          vim.keymap.set("n", "<S-Tab>", function() cycle_window(false) end,
            { buffer = buf, noremap = true, silent = true })
        end

        -- ⬆️⬇️ Diff scroll
        vim.keymap.set("n", "<C-j>", function()
          vim.api.nvim_win_call(win_diff, function() vim.cmd("normal! <C-e>") end)
        end, { buffer = buf_diff, noremap = true, silent = true })

        vim.keymap.set("n", "<C-k>", function()
          vim.api.nvim_win_call(win_diff, function() vim.cmd("normal! <C-y>") end)
        end, { buffer = buf_diff, noremap = true, silent = true })

        -- Start editing
        vim.api.nvim_set_current_win(win_title)
        vim.cmd("startinsert")
      end)




      map({ "n", "i" }, "fd", function()
        actions.close(prompt_bufnr)
        reopen_git_picker()
      end)


      map({ "n", "i" }, "q", function()
        actions.close(prompt_bufnr)
        reopen_git_picker()
      end)

      return true
    end,
  }):find()
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
    if info.ahead > 0 then
      table.insert(parts, { " ↑" .. info.ahead, "DiffAdd" })
    end
    if info.behind > 0 then
      table.insert(parts, { " ↓" .. info.behind, "WarningMsg" })
    end

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
  if not mode then return previewers.new_termopen_previewer({}) end

  -- Use custom previewer if defined
  if mode.cmd_fn_preview then
    return mode.cmd_fn_preview(branch)
  end

  -- Default termopen previewer (runs simple git command)
  return previewers.new_termopen_previewer({
    title = function() return mode.name end,
    get_command = function(entry)
      local branch_name = (entry and entry.value) or branch or "HEAD"
      return mode.cmd_fn(branch_name)
    end,
  })
end


-- Main picker
function M.git_branch_picker_with_mode(selected_branch, mode_index)
  mode_index = mode_index or 1
  local branches = vim.fn.systemlist("git branch --list --format='%(refname:short)'")
  if vim.tbl_isempty(branches) then
    vim.notify("No branches found", vim.log.levels.INFO)
    return
  end

  branches = sort_branches(branches)

  pickers.new({}, {
    prompt_title = "Darkskittlz Modified Git Branch",
    finder = finders.new_table {
      results = branches,
      entry_maker = branch_entry_maker,
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
    previewer = create_git_previewer(selected_branch, mode_index),

    initial_mode = "normal",

    attach_mappings = function(prompt_bufnr, map)
      local current_mode = mode_index

      -- Checkout branch
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if selection and selection.value then
          vim.cmd("Git checkout " .. selection.value)
          vim.notify("Switched to branch: " .. selection.value, vim.log.levels.INFO)
        end
      end)

      -- Copy branch name
      map({ "i", "n" }, "y", function()
        local selection = action_state.get_selected_entry()
        if selection and selection.value then
          vim.fn.setreg("+", selection.value)
          vim.notify("Copied branch: " .. selection.value, vim.log.levels.INFO)
        end
      end)

      -- Commit changes in a floating window
      map({ "i", "n" }, "c", function(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if not selection then
          vim.notify("No branch selected — using current branch", vim.log.levels.WARN)
        end

        -- ✅ Get real branch name
        local branch = selection and selection.value
        if not branch or branch == "" then
          branch = vim.fn.systemlist("git rev-parse --abbrev-ref HEAD")[1] or "HEAD"
        end
        branch = vim.trim(branch)

        -- Close the branch picker temporarily
        actions.close(prompt_bufnr)

        -- Window dimensions
        local width = math.floor(vim.o.columns * 0.6)
        local height_title_win = 1
        local height_desc_win = 3
        local height_diff = math.floor(vim.o.lines * 0.4)
        local spacing = 1
        local row = math.floor((vim.o.lines - (height_title_win + height_desc_win + height_diff + spacing * 2)) / 2)
        local col = math.floor((vim.o.columns - width) / 2)

        -- 🟩 Buffers
        local buf_title = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_option(buf_title, "buftype", "acwrite")
        vim.api.nvim_buf_set_option(buf_title, "bufhidden", "wipe")
        vim.api.nvim_buf_set_lines(buf_title, 0, -1, false, { "" })

        local buf_desc = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_option(buf_desc, "buftype", "acwrite")
        vim.api.nvim_buf_set_option(buf_desc, "bufhidden", "wipe")
        vim.api.nvim_buf_set_lines(buf_desc, 0, -1, false, { "", "", "" })

        local commit_label = "Commit Message"
        local padding = math.floor((width - #commit_label) / 2)
        local centered_label = string.rep(" ", padding) .. commit_label

        -- 🏷 Label buffer
        local buf_label = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_option(buf_label, "buftype", "nofile")
        vim.api.nvim_buf_set_option(buf_label, "bufhidden", "wipe")
        vim.api.nvim_buf_set_lines(buf_label, 0, -1, false, { centered_label })

        -- 🟦 Diff buffer
        local buf_diff = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_option(buf_diff, "buftype", "nofile")
        vim.api.nvim_buf_set_option(buf_diff, "bufhidden", "wipe")
        vim.api.nvim_buf_set_option(buf_diff, "filetype", "diff")

        -- Fill diff
        vim.api.nvim_buf_set_option(buf_diff, "modifiable", true)
        local diff_cmd = "git diff --cached " .. vim.fn.shellescape(branch)
        local diff_lines = vim.fn.systemlist(diff_cmd)
        if vim.v.shell_error ~= 0 or #diff_lines == 0 then
          diff_lines = { "[No staged changes or unable to read diff]" }
        end
        vim.api.nvim_buf_set_lines(buf_diff, 0, -1, false, diff_lines)
        vim.api.nvim_buf_set_option(buf_diff, "modifiable", false)

        -- 🪟 Windows
        local height_label = 1
        local win_label = vim.api.nvim_open_win(buf_label, false, {
          relative = "editor",
          width = width,
          height = height_label,
          row = row,
          col = col,
          style = "minimal",
          border = "none",
          zindex = 300,
        })

        local win_title = vim.api.nvim_open_win(buf_title, true, {
          relative = "editor",
          width = width,
          height = height_title_win,
          row = row + height_label,
          col = col,
          style = "minimal",
          border = "rounded",
          zindex = 300,
        })

        local win_desc = vim.api.nvim_open_win(buf_desc, true, {
          relative = "editor",
          width = width,
          height = height_desc_win,
          row = row + height_label + height_title_win + 2,
          col = col,
          style = "minimal",
          border = "rounded",
          zindex = 300,
        })

        local win_diff = vim.api.nvim_open_win(buf_diff, false, {
          relative = "editor",
          width = width,
          height = height_diff,
          row = row + height_label + height_title_win + height_desc_win + 4,
          col = col,
          style = "minimal",
          border = "rounded",
          zindex = 300,
        })

        -- 🧹 Close + reopen picker
        local function close_commit_popup()
          for _, w in ipairs({ win_label, win_title, win_desc, win_diff }) do
            if vim.api.nvim_win_is_valid(w) then
              vim.api.nvim_win_close(w, true)
            end
          end

          reopen_git_picker()
        end

        -- 💾 Commit logic
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

        -- 🗝️ Keymaps
        for _, buf in ipairs({ buf_title, buf_desc, buf_diff }) do
          vim.keymap.set("n", "q", close_commit_popup, { buffer = buf, noremap = true, silent = true })
          vim.keymap.set("n", "<Esc>", close_commit_popup, { buffer = buf, noremap = true, silent = true })
        end

        vim.keymap.set("n", "<CR>", commit_changes, { buffer = buf_title, noremap = true, silent = true })
        vim.keymap.set("n", "<CR>", commit_changes, { buffer = buf_desc, noremap = true, silent = true })

        -- 🔁 Tab navigation
        local windows = { win_title, win_desc, win_diff }
        local function cycle_window(forward)
          local current = vim.api.nvim_get_current_win()
          local idx
          for i, w in ipairs(windows) do
            if w == current then
              idx = i
              break
            end
          end
          if not idx then return end
          local next_idx = forward and (idx % #windows + 1) or (idx - 2) % #windows + 1
          vim.api.nvim_set_current_win(windows[next_idx])
        end

        for _, buf in ipairs({ buf_title, buf_desc, buf_diff }) do
          vim.keymap.set("n", "<Tab>", function() cycle_window(true) end,
            { buffer = buf, noremap = true, silent = true })
          vim.keymap.set("n", "<S-Tab>", function() cycle_window(false) end,
            { buffer = buf, noremap = true, silent = true })
        end

        -- ⬆️⬇️ Diff scroll
        vim.keymap.set("n", "<C-j>", function()
          vim.api.nvim_win_call(win_diff, function() vim.cmd("normal! <C-e>") end)
        end, { buffer = buf_diff, noremap = true, silent = true })

        vim.keymap.set("n", "<C-k>", function()
          vim.api.nvim_win_call(win_diff, function() vim.cmd("normal! <C-y>") end)
        end, { buffer = buf_diff, noremap = true, silent = true })

        -- Start editing
        vim.api.nvim_set_current_win(win_title)
        vim.cmd("startinsert")
      end)


      -- Pull from remote
      map({ "i", "n" }, "p", function()
        local selection = action_state.get_selected_entry()
        if not selection or not selection.value then return end
        local branch = selection.value
        vim.fn.system("git pull origin " .. branch)
        vim.notify("Pulled latest changes for branch: " .. branch, vim.log.levels.INFO)
      end)

      -- Push branch with spinner
      map({ "i", "n" }, "P", function()
        local selection = action_state.get_selected_entry()
        if not selection or not selection.value then
          vim.notify("No branch selected", vim.log.levels.WARN)
          return
        end

        local branch = tostring(selection.value or "")
        if branch == "" then
          vim.notify("Invalid branch name", vim.log.levels.ERROR)
          return
        end

        -- Create a floating window to show spinner
        local buf = vim.api.nvim_create_buf(false, true)
        local width = 24
        local height = 1
        local row = math.floor((vim.o.lines - height) / 3)
        local col = math.floor((vim.o.columns - width) / 3)
        local win = vim.api.nvim_open_win(buf, true, {
          relative = "editor",
          width = width,
          height = height,
          row = row,
          col = col,
          style = "minimal",
          border = "rounded",
        })

        -- Spinner animation
        local spinner_frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠏" }
        local frame = 1
        local timer = vim.loop.new_timer()

        local function update_spinner()
          if vim.api.nvim_buf_is_valid(buf) then
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
              "   " .. spinner_frames[frame] .. " Pushing to " .. branch,
            })
            frame = (frame % #spinner_frames) + 1
          end
        end

        timer:start(0, 100, vim.schedule_wrap(update_spinner))

        -- Run push asynchronously
        vim.fn.jobstart({ "git", "push", "origin", branch }, {
          stdout_buffered = true,
          stderr_buffered = true,

          on_exit = vim.schedule_wrap(function(_, exit_code)
            timer:stop()
            if vim.api.nvim_win_is_valid(win) then
              vim.api.nvim_win_close(win, true)
            end
            if vim.api.nvim_buf_is_valid(buf) then
              vim.api.nvim_buf_delete(buf, { force = true })
            end

            if exit_code == 0 then
              vim.notify("Branch pushed: " .. branch, vim.log.levels.INFO)
              require("utils.git_picker").git_branch_picker()
            else
              vim.notify("Push failed for branch: " .. branch, vim.log.levels.ERROR)
            end
          end),
        })
      end)


      -- Close picker
      map("n", "q", function(prompt_bufnr)
        remove_picker_overlay()
        actions.close(prompt_bufnr)
      end)

      -- Delete branch
      map({ "i", "n" }, "d", function()
        local selection = action_state.get_selected_entry()
        if not selection or not selection.value then return end
        local branch = selection.value
        vim.ui.input({ prompt = "Delete local branch '" .. branch .. "'? (y/N): " }, function(input)
          if input and input:lower() == "y" then
            vim.fn.system("git branch -D " .. branch)
            vim.notify("Deleted branch: " .. branch, vim.log.levels.INFO)
            actions.close(prompt_bufnr)
          else
            vim.notify("Branch deletion canceled", vim.log.levels.INFO)
          end
        end)
      end)

      -- Inside attach_mappings
      map({ "n", "i" }, "<Space>", function()
        local selection = action_state.get_selected_entry()
        if not selection or not selection.value then return end

        local branch_name = selection.value
        local picker = action_state.get_current_picker(prompt_bufnr)

        -- Close current picker first
        actions.close(prompt_bufnr)

        -- Switch branch
        local result = vim.fn.system("git switch " .. branch_name)
        if vim.v.shell_error == 0 then
          vim.notify("Switched to branch: " .. branch_name, vim.log.levels.INFO)

          -- Reopen picker with refreshed file list
          vim.defer_fn(function()
            M.git_branch_picker_with_mode(branch_name, 1) -- 1 = Diff mode
          end, 50)                                        -- small delay to ensure git switch completed
        else
          vim.notify("Failed to switch branch:\n" .. result, vim.log.levels.ERROR)

          -- Reopen picker anyway so user isn't stuck
          vim.defer_fn(function()
            M.git_branch_picker_with_mode(branch_name, 1)
          end, 50)
        end
      end)

      -- Cycle preview modes
      local function cycle_preview(direction)
        local selection = action_state.get_selected_entry()
        if not selection or not selection.value then return end
        if direction == "next" then
          current_mode = (current_mode % #preview_modes) + 2
        else
          current_mode = (current_mode - 3) % #preview_modes + 1
        end
        actions.close(prompt_bufnr)
        vim.defer_fn(function()
          M.git_branch_picker_with_mode(selection.value, current_mode)
        end, 51)
      end
      map({ "i", "n" }, "+", function() cycle_preview("next") end)
      map({ "i", "n" }, "_", function() cycle_preview("prev") end)


      -- Scroll preview
      map({ "n", "i" }, "<C-d>", actions.preview_scrolling_down)
      map({ "n", "i" }, "<C-b>", actions.preview_scrolling_up)

      map({ "i", "n" }, "fd", function()
        local selection = action_state.get_selected_entry()
        if not selection or not selection.value then return end
        actions.close(prompt_bufnr)
        open_branch_file_picker(selection.value)
      end)

      return true
    end,
  }):find()
end

-- Default entry point
function M.git_branch_picker()
  M.git_branch_picker_with_mode(nil, 2)
end

return M
