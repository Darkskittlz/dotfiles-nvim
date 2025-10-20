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
    layout_strategy = "vertical", -- vertical layout (optional)
    layout_config = {
      height = 0.5,               -- half the height of the screen
      width = 0.5,                -- optional, adjust width
      prompt_position = "top"
    },
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        vim.cmd("Git checkout " .. selection[1])
      end)

      map("i", "y", function()
        local selection = action_state.get_selected_entry()
        vim.fn.setreg("+", selection[1])
        vim.notify("Copied branch: " .. selection[1], vim.log.levels.INFO)
      end)
      map("n", "y", function()
        local selection = action_state.get_selected_entry()
        vim.fn.setreg("+", selection[1])
        vim.notify("Copied branch: " .. selection[1], vim.log.levels.INFO)
      end)

      return true
    end,
  }):find()
end

return M
