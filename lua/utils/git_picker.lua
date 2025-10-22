---@diagnostic disable: undefined-global

local M = {}

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

-- Preview modes
local preview_modes = {
  { name = "Log",    cmd_fn = function(branch) return { "git", "log", "--oneline", branch } end },
  { name = "Reflog", cmd_fn = function(branch) return { "git", "reflog", "--oneline", branch } end },
  { name = "Diff",   cmd_fn = function(branch) return { "git", "diff", branch } end },
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
  return previewers.new_termopen_previewer({
    title = function()
      local mode = preview_modes[mode_index]
      return mode and mode.name or ""
    end,
    get_command = function(entry)
      local branch_name = (entry and entry.value) or branch or "HEAD"
      local mode = preview_modes[mode_index]
      if not branch_name or not mode then return { "echo", "" } end
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
    prompt_title = "Git Branches",
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
      map({ "i", "n" }, "c", function()
        local selection = action_state.get_selected_entry()
        if not selection or not selection.value then return end
        local branch = selection.value

        -- Create a scratch buffer
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_option(buf, "buftype", "acwrite")
        vim.api.nvim_buf_set_option(buf, "filetype", "gitcommit")
        vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

        -- Initial lines: title and body separated by a blank line
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
          "# Title: first line is the commit summary",
          "",
          "# Body: remaining lines are the commit message",
          "",
        })

        -- Floating window dimensions
        local width = math.floor(vim.o.columns * 0.6)
        local height = math.floor(vim.o.lines * 0.4)
        local row = math.floor((vim.o.lines - height) / 2)
        local col = math.floor((vim.o.columns - width) / 2)

        local win = vim.api.nvim_open_win(buf, true, {
          relative = "editor",
          width = width,
          height = height,
          row = row,
          col = col,
          style = "minimal",
          border = "rounded",
        })

        -- Map <Esc> to close without committing
        vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", "<cmd>bd!<CR>", { noremap = true, silent = true })

        -- Map <leader>w to save and commit
        vim.api.nvim_buf_set_keymap(buf, "n", "<leader>w", "", {
          noremap = true,
          silent = true,
          callback = function()
            local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
            local title = lines[1] or ""
            local body = table.concat(lines, "\n", 2)

            -- Stage all changes and commit
            vim.fn.system("git add -A")
            local cmd = 'git commit -m ' .. vim.fn.shellescape(title)
            if body ~= "" then
              cmd = cmd .. ' -m ' .. vim.fn.shellescape(body)
            end
            vim.fn.system(cmd)
            vim.notify("Committed changes on branch: " .. branch, vim.log.levels.INFO)
            vim.api.nvim_win_close(win, true)
            vim.api.nvim_buf_delete(buf, { force = true })
          end
        })
      end)


      -- Pull from remote
      map({ "i", "n" }, "p", function()
        local selection = action_state.get_selected_entry()
        if not selection or not selection.value then return end
        local branch = selection.value
        vim.fn.system("git pull origin " .. branch)
        vim.notify("Pulled latest changes for branch: " .. branch, vim.log.levels.INFO)
      end)

      -- Push to remote
      map({ "i", "n" }, "P", function()
        local selection = action_state.get_selected_entry()
        if not selection or not selection.value then return end
        local branch = selection.value
        vim.fn.system("git push origin " .. branch)
        vim.notify("Pushed branch: " .. branch .. " to remote", vim.log.levels.INFO)
      end)

      -- Close picker
      map("n", "q", actions.close)

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

      -- Cycle preview modes
      local function cycle_preview(direction)
        local selection = action_state.get_selected_entry()
        if not selection or not selection.value then return end
        if direction == "next" then
          current_mode = (current_mode % #preview_modes) + 1
        else
          current_mode = (current_mode - 2) % #preview_modes + 1
        end
        actions.close(prompt_bufnr)
        vim.defer_fn(function()
          M.git_branch_picker_with_mode(selection.value, current_mode)
        end, 50)
      end
      map({ "i", "n" }, "+", function() cycle_preview("next") end)
      map({ "i", "n" }, "_", function() cycle_preview("prev") end)

      -- Scroll preview
      map({ "i", "n" }, "<C-d>", actions.preview_scrolling_down)
      map({ "i", "n" }, "<C-b>", actions.preview_scrolling_up)

      return true
    end,
  }):find()
end

-- Default entry point
function M.git_branch_picker()
  M.git_branch_picker_with_mode(nil, 1)
end

return M
