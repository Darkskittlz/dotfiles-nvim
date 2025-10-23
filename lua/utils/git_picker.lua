---@diagnostic disable: undefined-global
local M = {}

-- Highlight groups
vim.api.nvim_set_hl(0, "GitBranchCurrent", { fg = "#549afc", bold = true })
vim.api.nvim_set_hl(0, "GitBranchStaged", { fg = "#9ece6a" })
vim.api.nvim_set_hl(0, "GitBranchUnstaged", { fg = "#e0af68" })
vim.api.nvim_set_hl(0, "GitBranchFilesChanged", { fg = "#f7768e" })
vim.api.nvim_set_hl(0, "GitBranchAhead", { fg = "#7aa2f7" })
vim.api.nvim_set_hl(0, "GitBranchBehind", { fg = "#bb9af7" })
vim.api.nvim_set_hl(0, "GitDiffAdd", { fg = "#9ece6a" })
vim.api.nvim_set_hl(0, "GitDiffDelete", { fg = "#f7768e" })

local preview_modes = {
  { name = "Diff",   cmd = function(branch) return "git diff " .. branch end },
  { name = "Log",    cmd = function(branch) return "git log --oneline " .. branch end },
  { name = "Reflog", cmd = function(branch) return "git reflog --oneline " .. branch end },
}

local function current_branch()
  return vim.fn.systemlist("git rev-parse --abbrev-ref HEAD")[1] or ""
end

local function get_branch_info(branch)
  local info = { staged = 0, unstaged = 0, files_changed = 0, ahead = 0, behind = 0 }
  local cur = current_branch()
  if branch == cur then
    for _, l in ipairs(vim.fn.systemlist("git status --porcelain")) do
      local x, y = l:sub(1, 1), l:sub(2, 2)
      if x ~= " " then info.staged = info.staged + 1 end
      if y ~= " " then info.unstaged = info.unstaged + 1 end
    end
    info.files_changed = #vim.fn.systemlist("git diff --name-only " .. branch)
  end
  local ok = pcall(vim.fn.systemlist, "git rev-parse --abbrev-ref " .. branch .. "@{upstream}")
  if ok then
    local counts = vim.fn.systemlist("git rev-list --left-right --count " .. branch .. "...@{upstream}")[1]
    if counts then
      local a, b = counts:match("(%d+)%s+(%d+)")
      info.ahead = tonumber(a) or 0
      info.behind = tonumber(b) or 0
    end
  end
  return info
end

local function format_branch_line(branch)
  local info = get_branch_info(branch)
  local cur = current_branch()
  local parts = {}
  table.insert(parts, { (branch == cur and "* " or "  ") .. branch, branch == cur and "GitBranchCurrent" or "Normal" })
  if info.staged > 0 then table.insert(parts, { " ●" .. info.staged, "GitBranchStaged" }) end
  if info.unstaged > 0 then table.insert(parts, { " ✚" .. info.unstaged, "GitBranchUnstaged" }) end
  if info.files_changed > 0 then
    table.insert(parts,
      { " (" .. info.files_changed .. " file" .. (info.files_changed > 1 and "s" or "") .. " changed)",
        "GitBranchFilesChanged" })
  end
  if info.ahead > 0 then table.insert(parts, { " ↑" .. info.ahead, "GitBranchAhead" }) end
  if info.behind > 0 then table.insert(parts, { " ↓" .. info.behind, "GitBranchBehind" }) end
  local line = ""
  for _, p in ipairs(parts) do line = line .. p[1] end
  return line, parts
end

local function open_window(lines, opts)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  local win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    width = opts.width,
    height = opts.height,
    row = opts.row,
    col = opts.col,
    style = "minimal",
    border =
    "rounded"
  })
  return buf, win
end

local function get_preview_content(branch, mode_index)
  local mode = preview_modes[mode_index]
  if not mode then return {} end
  return vim.fn.systemlist(mode.cmd(branch))
end

local function create_commit_window(branch, reopen)
  local width = math.floor(vim.o.columns * 0.6)
  local row = math.floor(vim.o.lines * 0.3)
  local col = math.floor((vim.o.columns - width) / 2)
  local spacing = 1
  local buf_title, win_title = open_window({ "" }, { width = width, height = 1, row = row, col = col })
  local buf_body, win_body = open_window({ "" }, { width = width, height = 6, row = row + 2 + spacing, col = col })
  local function close_commit()
    for _, w in ipairs({ win_title, win_body }) do if vim.api.nvim_win_is_valid(w) then vim.api.nvim_win_close(w, true) end end
    if reopen then reopen() end
    vim.notify("Commit cancelled", vim.log.levels.INFO)
  end
  local function commit_changes()
    local title = vim.api.nvim_buf_get_lines(buf_title, 0, -1, false)[1] or ""
    local body = table.concat(vim.api.nvim_buf_get_lines(buf_body, 0, -1, false), "\n")
    vim.fn.system("git add -A")
    local cmd = 'git commit -m ' .. vim.fn.shellescape(title)
    if body:match("%S") then cmd = cmd .. ' -m ' .. vim.fn.shellescape(body) end
    vim.fn.system(cmd)
    vim.notify("Committed changes on branch: " .. branch, vim.log.levels.INFO)
    close_commit()
  end
  for _, b in ipairs({ buf_title, buf_body }) do
    vim.api.nvim_buf_set_keymap(b, "n", "q", "", { noremap = true, silent = true, callback = close_commit })
    vim.api.nvim_buf_set_keymap(b, "n", "<Esc>", "", { noremap = true, silent = true, callback = close_commit })
    vim.api.nvim_buf_set_keymap(b, "n", "<leader>w", "", { noremap = true, silent = true, callback = commit_changes })
  end
  vim.api.nvim_buf_set_keymap(buf_title, "n", "<Tab>", "",
    { noremap = true, silent = true, callback = function() vim.api.nvim_set_current_win(win_body) end })
  vim.api.nvim_buf_set_keymap(buf_body, "n", "<Tab>", "",
    { noremap = true, silent = true, callback = function() vim.api.nvim_set_current_win(win_title) end })
  vim.api.nvim_buf_set_keymap(buf_title, "n", "<S-Tab>", "",
    { noremap = true, silent = true, callback = function() vim.api.nvim_set_current_win(win_body) end })
  vim.api.nvim_buf_set_keymap(buf_body, "n", "<S-Tab>", "",
    { noremap = true, silent = true, callback = function() vim.api.nvim_set_current_win(win_title) end })
end

function M.git_branch_ui(mode_index)
  mode_index = mode_index or 1
  local cur = current_branch()
  local branches = vim.fn.systemlist("git branch --list --format='%(refname:short)'")
  table.sort(branches,
    function(a, b) if a == cur then return true elseif b == cur then return false else return a < b end end)
  local width = math.floor(vim.o.columns * 0.6)
  local spacing = 1
  local h_files = math.floor(vim.o.lines * 0.12)
  local h_preview = math.floor(vim.o.lines * 0.2)
  local h_branches = math.floor(vim.o.lines * 0.25)
  local h_msg = 3
  local total_height = h_files + h_preview + h_branches + h_msg + spacing * 3
  local start_row = math.floor((vim.o.lines - total_height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  local row_files = start_row
  local row_preview = row_files + h_files + spacing
  local row_branches = row_preview + h_preview + spacing
  local row_msg = row_branches + h_branches + spacing

  local files = vim.fn.systemlist("git diff --name-only " .. cur)
  local buf_files, win_files = open_window(files, { width = width, height = h_files, row = row_files, col = col })

  local preview_lines = get_preview_content(cur, mode_index)
  local buf_preview, win_preview = open_window(preview_lines,
    {
      width = width,
      height = h_preview,
      row = row_preview,
      col =
          col
    })

  local branch_lines = {}
  for _, b in ipairs(branches) do
    local line = format_branch_line(b)
    table.insert(branch_lines, line)
  end


  local buf_branches, win_branches = open_window(branch_lines,
    {
      width = width,
      height = h_branches,
      row = row_branches,
      col =
          col
    })

  local buf_msg, win_msg = open_window(
    { "<Space>:checkout  y:copy  p:pull  P:push  c:commit  +/_:cycle  j/k:navigate  q:close" }, {
      width = width, height = h_msg, row = row_msg, col = col
    })

  vim.api.nvim_set_current_win(win_branches)

  local function close_all()
    for _, w in ipairs({ win_files, win_preview, win_branches, win_msg }) do
      if vim.api.nvim_win_is_valid(w) then vim.api.nvim_win_close(w, true) end
    end
  end

  -- Branch window keymaps
  local function get_current_branch_line()
    local line = vim.api.nvim_get_current_line()
    return line:gsub("^%*?%s*", ""):match("^[^%s]+")
  end

  vim.api.nvim_buf_set_keymap(buf_branches, "n", "q", "", { noremap = true, silent = true, callback = close_all })
  vim.api.nvim_buf_set_keymap(buf_branches, "n", "j", "",
    { noremap = true, silent = true, callback = function() vim.cmd("normal! j") end })
  vim.api.nvim_buf_set_keymap(buf_branches, "n", "k", "",
    { noremap = true, silent = true, callback = function() vim.cmd("normal! k") end })

  vim.api.nvim_buf_set_keymap(buf_branches, "n", "<Space>", "", {
    noremap = true,
    silent = true,
    callback = function()
      local branch = get_current_branch_line()
      if branch then
        vim.cmd("Git checkout " .. branch)
        close_all()
        M.git_branch_ui(mode_index)
      end
    end
  })
  vim.api.nvim_buf_set_keymap(buf_branches, "n", "y", "", {
    noremap = true,
    silent = true,
    callback = function()
      local branch = get_current_branch_line()
      if branch then
        vim.fn.setreg("+", branch)
        vim.notify("Copied branch: " .. branch, vim.log.levels.INFO)
      end
    end
  })
  vim.api.nvim_buf_set_keymap(buf_branches, "n", "p", "", {
    noremap = true,
    silent = true,
    callback = function()
      local branch = get_current_branch_line()
      if branch then
        vim.fn.system("git pull origin " .. branch)
        vim.notify("Pulled " .. branch, vim.log.levels.INFO)
      end
    end
  })
  vim.api.nvim_buf_set_keymap(buf_branches, "n", "c", "", {
    noremap = true,
    silent = true,
    callback = function()
      local branch = get_current_branch_line()
      if branch then create_commit_window(branch, function() M.git_branch_ui(mode_index) end) end
    end
  })
  -- TODO: Implement P push spinner if needed
  vim.api.nvim_buf_set_keymap(buf_branches, "n", "+", "", {
    noremap = true,
    silent = true,
    callback = function()
      local new_mode = (mode_index % #preview_modes) + 1
      close_all()
      M.git_branch_ui(new_mode)
    end
  })
  vim.api.nvim_buf_set_keymap(buf_branches, "n", "_", "", {
    noremap = true,
    silent = true,
    callback = function()
      local new_mode = (mode_index - 2) % #preview_modes + 1
      close_all()
      M.git_branch_ui(new_mode)
    end
  })
end

function M.git_branch_picker() M.git_branch_ui() end

return M
