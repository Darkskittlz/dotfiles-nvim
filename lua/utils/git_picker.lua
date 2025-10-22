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

function M.git_branch_picker()
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
        width = 0.9,
        height = 0.9,
        preview_cutoff = 0.3,
        preview_height = 0.6,
        prompt_position = "top",
      },
    },
    sorting_strategy = "ascending",

    -- ✅ Add a previewer to show branch diffs
    previewer = previewers.new_termopen_previewer({
      get_command = function(entry)
        -- Shows diff between current branch and selected branch
        return { "git", "diff", entry.value }
      end,
    }),

    attach_mappings = function(prompt_bufnr, map)
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

      -- Close Telescope with q
      map("n", "q", actions.close)

      -- ✅ Scroll preview window with Ctrl-d / Ctrl-b
      map({ "i", "n" }, "<C-d>", actions.preview_scrolling_down)
      map({ "i", "n" }, "<C-b>", actions.preview_scrolling_up)

      -- ✅ Delete local branch with confirmation
      map({ "i", "n" }, "d", function()
        local selection = action_state.get_selected_entry()
        if not selection or not selection.value then return end

        local branch = selection.value
        vim.ui.input({ prompt = "Delete local branch '" .. branch .. "'? (y/N): " }, function(input)
          if input and input:lower() == "y" then
            local result = vim.fn.system("git branch -D " .. branch)
            vim.notify(result ~= "" and result or "Deleted branch: " .. branch, vim.log.levels.INFO)
            actions.close(prompt_bufnr)
          else
            vim.notify("Branch deletion canceled", vim.log.levels.INFO)
          end
        end)
      end)

      return true
    end,
  }):find()
end

return M
