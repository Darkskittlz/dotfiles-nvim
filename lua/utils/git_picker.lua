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

-- Define preview modes
local preview_modes = {
  { name = "Log",    cmd_fn = function(branch) return { "git", "log", "--oneline", branch } end },
  { name = "Reflog", cmd_fn = function(branch) return { "git", "reflog", "--oneline", branch } end },
  { name = "Diff",   cmd_fn = function(branch) return { "git", "diff", branch } end },
}

-- Create previewer with simple title
local function create_git_previewer(branch, mode_index)
  return previewers.new_termopen_previewer({
    title = function()
      local mode = preview_modes[mode_index]
      local display_branch = branch or "current"
      return string.format("%s", mode.name)
    end,
    get_command = function(entry)
      local branch_name = (entry and entry.value) or branch or "HEAD"
      local mode = preview_modes[mode_index]
      if not branch_name or not mode then return { "echo", "" } end
      return mode.cmd_fn(branch_name)
    end,
  })
end

function M.git_branch_picker_with_mode(selected_branch, mode_index)
  mode_index = mode_index or 1
  local branches = vim.fn.systemlist("git branch --list --format='%(refname:short)'")
  if vim.tbl_isempty(branches) then
    vim.notify("No branches found", vim.log.levels.INFO)
    return
  end

  pickers.new({}, {
    prompt_title = "Git Branches",
    finder = finders.new_table { results = branches },
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

      -- Fetch new branches with confirmation
      map({ "i", "n" }, "r", function()
        vim.ui.input({ prompt = "Fetch new branches from origin? (y/N): " }, function(input)
          if input and input:lower() == "y" then
            vim.notify("Fetching new branches...", vim.log.levels.INFO)
            vim.fn.system("git fetch origin")
            vim.notify("Fetch complete", vim.log.levels.INFO)
            actions.close(prompt_bufnr)
            vim.defer_fn(function()
              M.git_branch_picker_with_mode(nil, current_mode)
            end, 50)
          else
            vim.notify("Fetch canceled", vim.log.levels.INFO)
          end
        end)
      end)

      return true
    end,
  }):find()
end

-- Default entry point
function M.git_branch_picker()
  M.git_branch_picker_with_mode(nil, 1)
end

return M
