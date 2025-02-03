return {
  "telescope.nvim",
  dependencies = {
    "nvim-telescope/telescope-file-browser.nvim",
    "nvim-telescope/telescope-fzf-native.nvim",
  },
  keys = {
    {
      ";f",
      function()
        local builtin =
            require("telescope.builtin")
        builtin.find_files({
          no_ignore = false,
          hidden = true,
          -- layout_config = { height = 0.3 }, -- Results window: 30% height
        })
      end,
    },
    {
      ";r",
      function()
        local builtin = require("telescope.builtin")
        builtin.oldfiles({
          -- You can add layout or other options here if needed
        })
      end,
    },
    {
      ";g",
      function()
        local builtin = require("telescope.builtin")
        builtin.live_grep({
          -- You can add layout or other options here if needed
        })
      end,
    },
    {
      "\\\\",
      function()
        local builtin =
            require("telescope.builtin")
        builtin.buffers({
          -- layout_config = { height = 0.3 }, -- Results window: 30% height
        })
      end,
    },
    {
      ";t",
      function()
        local builtin =
            require("telescope.builtin")
        builtin.help_tags({
          -- layout_config = { height = 0.3 }, -- Results window: 30% height
        })
      end,
    },
    {
      ";;",
      function()
        local builtin =
            require("telescope.builtin")
        builtin.resume({
          -- layout_config = { height = 0.3 }, -- Results window: 30% height
        })
      end,
    },
    {
      ";e",
      function()
        local builtin =
            require("telescope.builtin")
        builtin.diagnostics({
          wrap_results = false,
          layout_strategy = "horizontal",
          layout_config = {
            prompt_position = "top",
            height = 0.99,
            preview_width = 0.6,
            preview_cutoff = 0.4,
          },
          sorting_strategy = "ascending",
          winblend = 0,
          mappings = {
            n = {},
          },
          path_display = function(opts, path)
            local tail = vim.fn.fnamemodify(path, ":t")   -- Get the filename
            local parent = vim.fn.fnamemodify(path, ":h:t") -- Get the parent directory
            return parent .. "/" .. tail                  -- Show "parent/filename"
          end,
          entry_display = function(entry)
            -- This will remove the line and character positions from the result display
            return entry.value -- Only return the formatted path without additional data
          end,
        })
      end,
    },
    {
      ";s",
      function()
        local builtin =
            require("telescope.builtin")
        builtin.treesitter({
          -- layout_config = { height = 0.3 }, -- Results window: 30% height
        })
      end,
    },
    {
      "sf",
      function()
        local telescope = require("telescope")
        local function telescope_buffer_dir()
          return vim.fn.expand("%:p:h")
        end

        telescope.extensions.file_browser.file_browser({
          path = "%:p:h",
          cwd = telescope_buffer_dir(),
          respect_gitignore = false,
          hidden = true,
          grouped = true,
          previewer = false,
          initial_mode = "normal",
          layout_config = { height = 40 },
        })
      end,
    },
  },

  config = function(_, opts)
    opts = opts or {} -- Ensure opts is not nil
    local telescope = require("telescope")
    local actions = require("telescope")
    local fb_actions =
        require("telescope").extensions.file_browser.actions

    opts.defaults = vim.tbl_deep_extend(
      "force",
      opts.defaults or {},
      {
        wrap_results = false,
        layout_strategy = "horizontal",
        layout_config = {
          prompt_position = "top",
          height = 0.99,
          preview_width = 0.6,
          preview_cutoff = 0.4,
        },
        sorting_strategy = "ascending",
        winblend = 0,
        mappings = {
          n = {},
        },
        path_display = function(opts, path)
          local tail = vim.fn.fnamemodify(path, ":t")     -- Get the filename
          local parent = vim.fn.fnamemodify(path, ":h:t") -- Get the parent directory
          return parent .. "/" .. tail                    -- Show "parent/filename"
        end,
        entry_display = function(entry)
          -- This will remove the line and character positions from the result display
          return entry.value -- Only return the formatted path without additional data
        end,
      }
    )
    opts.pickers = {
      diagnostics = {
        theme = "ivy",
        initial_mode = "normal",
        layout_config = {
          height = 0.2,
          preview_cutoff = 999,
        },
      },
    }
    opts.extensions = {
      file_browser = {
        theme = "dropdown",
        hijack_netrw = true,
        mappings = {
          ["n"] = {
            ["N"] = fb_actions.create,
            ["h"] = fb_actions.goto_parent_dir,
            ["/"] = function()
              vim.cmd("startinsert")
            end,
            ["<C-u>"] = function(prompt_bufnr)
              for i = 1, 10 do
                actions.move_selection_previous(
                  prompt_bufnr
                )
              end
            end,
            ["<C-d>"] = function(prompt_bufnr)
              for i = 1, 10 do
                actions.move_selection_next(
                  prompt_bufnr
                )
              end
            end,
            ["<PageUp>"] = actions.preview_scrolling_up,
            ["<PageDown>"] = actions.preview_scrolling_down,
          },
        },
      },
    }

    -- Set up highlights to remove the dark blue background and padding
    opts.on_highlights = function(hl, c)
      -- Ensure floating windows are transparent
      hl.NormalFloat = { bg = "NONE" }
      hl.FloatBorder =
      { bg = c.blue, fg = c.blue } -- Adjust this fg color if needed

      -- Telescope prompt and border customization
      local prompt = "#2d3149" -- Change this if you want a different color for the prompt
      hl.TelescopeNormal =
      { bg = c.transparent, fg = c.fg_dark }
      hl.TelescopeBorder =
      { bg = c.transparent, fg = c.transparent }
      hl.TelescopePromptNormal =
      { bg = c.transparent, fg = c.fg_dark }
      hl.TelescopePromptBorder =
      { bg = c.transparent, fg = c.transparent }
      hl.TelescopePromptTitle =
      { bg = c.transparent, fg = c.fg_dark }
      hl.TelescopePreviewTitle =
      { bg = c.transparent, fg = c.transparent }
      hl.TelescopeResultsTitle =
      { bg = c.transparent, fg = c.transparent }

      -- Optional: Adjust padding for Telescope prompt (if it's still visible)
      hl.TelescopePrompt = { padding = 0 }
    end

    telescope.setup(opts)
    require("telescope").load_extension("fzf")
    require("telescope").load_extension(
      "file_browser"
    )
  end,
}
