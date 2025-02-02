-- Set the virtual_column option to keep cursor column numbers the same
-- vim.o.virtual_column = "all"
vim.g.lazygit = {
  colors = {
    bg = "#000001", -- Set the background color to black
    -- Add other color settings as needed
  },
}

vim.opt.wrap = false

vim.api.nvim_set_option(
  "clipboard",
  "unnamedplus"
)

-- Highlight to the next parenthesis
vim.api.nvim_set_keymap('n', '<leader>hp', ':normal! v/<CR>(<CR>', { noremap = true, silent = true })

-- Highlight to the next curly brace
vim.api.nvim_set_keymap('n', '<leader>hc', ':normal! v/<CR>{<CR>', { noremap = true, silent = true })

vim.opt.termguicolors = true -- Enable 25-bit RGB color in the TUI,
local capabilities = vim.lsp.protocol.make_client_capabilities()



-- Bubbles config for lualine
-- Author: lokesh-krishna
-- MIT license, see LICENSE for more details.

-- stylua: ignore
local colors = {
  blue        = '#80a0ff',
  cyan        = '#79dac8',
  black       = '#080808',
  white       = '#c6c6c6',
  red         = '#ff5189',
  violet      = '#8C4F92',
  grey        = '#303030',
  green       = '#50C878',
  orange      = "#CC5500",
  purple      = "#9370DB",
  hackerGreen = "#005200",
}

local bubbles_theme = {
  normal = {
    a = { fg = colors.black, bg = colors.violet },
    b = { fg = colors.white, bg = colors.black },
    c = { fg = colors.white },
  },

  insert = {
    a = { fg = colors.black, bg = colors.blue },
  },
  visual = {
    a = { fg = colors.black, bg = colors.orange },
  },
  replace = {
    a = { fg = colors.black, bg = colors.red },
  },

  inactive = {
    a = { fg = colors.white, bg = colors.black },
    b = { fg = colors.white, bg = colors.black },
    c = { fg = colors.white },
  },
}

require("lualine").setup({
  options = {
    theme = bubbles_theme,
    component_separators = "",
    section_separators = {
      left = "",
      right = "",
    },
  },
  sections = {
    lualine_a = {
      {
        "mode",
        separator = { left = "" },
        right_padding = 2,
      },
    },
    lualine_b = { "branch" },
    lualine_c = {
      "%=", --[[ add your center compoentnts here in place of this comment ]]
    },
    lualine_x = {},
    lualine_y = { "filetype", "progress" },
    lualine_z = {
      {
        "location",
        separator = { right = "" },
        left_padding = 2,
      },
    },
  },
  inactive_sections = {
    lualine_a = { "filename" },
    lualine_b = {},
    lualine_c = {},
    lualine_x = {},
    lualine_y = {},
    lualine_z = { "location" },
  },
  tabline = {},
  extensions = {},
})
--
-- Eviline config for lualine
-- Author: shadmansaleh
-- Credit: glepnir
-- local lualine = require('lualine')
--
-- -- Color table for highlights
-- -- stylua: ignore
-- local colors = {
--   bg       = '#202328',
--   fg       = '#bbc2cf',
--   yellow   = '#ECBE7B',
--   cyan     = '#008080',
--   darkblue = '#081633',
--   green    = '#98be65',
--   orange   = '#FF8800',
--   violet   = '#a9a1e1',
--   magenta  = '#c678dd',
--   blue     = '#51afef',
--   red      = '#ec5f67',
-- }
--
-- local conditions = {
--   buffer_not_empty = function()
--     return vim.fn.empty(vim.fn.expand("%:t")) ~= 1
--   end,
--   hide_in_width = function()
--     return vim.fn.winwidth(0) > 80
--   end,
--   check_git_workspace = function()
--     local filepath = vim.fn.expand("%:p:h")
--     local gitdir =
--         vim.fn.finddir(".git", filepath .. ";")
--     return gitdir
--         and #gitdir > 0
--         and #gitdir < #filepath
--   end,
-- }
--
-- -- Config
-- local config = {
--   options = {
--     -- Disable sections and component separators
--     component_separators = "",
--     section_separators = "",
--     theme = {
--       -- We are going to use lualine_c an lualine_x as left and
--       -- right section. Both are highlighted by c theme .  So we
--       -- are just setting default looks o statusline
--       normal = {
--         c = { fg = colors.fg, bg = colors.bg },
--       },
--       inactive = {
--         c = { fg = colors.fg, bg = colors.bg },
--       },
--     },
--   },
--   sections = {
--     -- these are to remove the defaults
--     lualine_a = {},
--     lualine_b = {},
--     lualine_y = {},
--     lualine_z = {},
--     -- These will be filled later
--     lualine_c = {},
--     lualine_x = {},
--   },
--   inactive_sections = {
--     -- these are to remove the defaults
--     lualine_a = {},
--     lualine_b = {},
--     lualine_y = {},
--     lualine_z = {},
--     lualine_c = {},
--     lualine_x = {},
--   },
-- }
--
-- -- Inserts a component in lualine_c at left section
-- local function ins_left(component)
--   table.insert(
--     config.sections.lualine_c,
--     component
--   )
-- end
--
-- -- Inserts a component in lualine_x at right section
-- local function ins_right(component)
--   table.insert(
--     config.sections.lualine_x,
--     component
--   )
-- end
--
-- ins_left({
--   function()
--     return "▊"
--   end,
--   color = { fg = colors.blue },      -- Sets highlighting of component
--   padding = { left = 0, right = 1 }, -- We don't need space before this
-- })
--
-- ins_left({
--   -- mode component
--   function()
--     return ""
--   end,
--   color = function()
--     -- auto change color according to neovims mode
--     local mode_color = {
--       n = colors.red,
--       i = colors.green,
--       v = colors.blue,
--       [""] = colors.blue,
--       V = colors.blue,
--       c = colors.magenta,
--       no = colors.red,
--       s = colors.orange,
--       S = colors.orange,
--       [""] = colors.orange,
--       ic = colors.yellow,
--       R = colors.violet,
--       Rv = colors.violet,
--       cv = colors.red,
--       ce = colors.red,
--       r = colors.cyan,
--       rm = colors.cyan,
--       ["r?"] = colors.cyan,
--       ["!"] = colors.red,
--       t = colors.red,
--     }
--     return { fg = mode_color[vim.fn.mode()] }
--   end,
--   padding = { right = 1 },
-- })
--
-- ins_left({
--   -- filesize component
--   "filesize",
--   cond = conditions.buffer_not_empty,
-- })
--
-- ins_left({
--   "filename",
--   cond = conditions.buffer_not_empty,
--   color = { fg = colors.magenta, gui = "bold" },
-- })
--
-- ins_left({ "location" })
--
-- ins_left({
--   "progress",
--   color = { fg = colors.fg, gui = "bold" },
-- })
--
-- ins_left({
--   "diagnostics",
--   sources = { "nvim_diagnostic" },
--   symbols = {
--     error = " ",
--     warn = " ",
--     info = " ",
--   },
--   diagnostics_color = {
--     error = { fg = colors.red },
--     warn = { fg = colors.yellow },
--     info = { fg = colors.cyan },
--   },
-- })
--
-- -- Insert mid section. You can make any number of sections in neovim :)
-- -- for lualine it's any number greater then 2
-- ins_left({
--   function()
--     return "%="
--   end,
-- })
--
-- ins_left({
--   -- Lsp server name .
--   function()
--     local msg = "No Active Lsp"
--     local buf_ft = vim.api.nvim_get_option_value(
--       "filetype",
--       { buf = 0 }
--     )
--     local clients = vim.lsp.get_clients()
--     if next(clients) == nil then
--       return msg
--     end
--     for _, client in ipairs(clients) do
--       local filetypes = client.config.filetypes
--       if
--           filetypes
--           and vim.fn.index(filetypes, buf_ft)
--           ~= -1
--       then
--         return client.name
--       end
--     end
--     return msg
--   end,
--   icon = " LSP:",
--   color = { fg = "#ffffff", gui = "bold" },
-- })
--
-- -- Add components to right sections
-- ins_right({
--   "o:encoding",       -- option component same as &encoding in viml
--   fmt = string.upper, -- I'm not sure why it's upper case either ;)
--   cond = conditions.hide_in_width,
--   color = { fg = colors.green, gui = "bold" },
-- })
--
-- ins_right({
--   "fileformat",
--   fmt = string.upper,
--   icons_enabled = false, -- I think icons are cool but Eviline doesn't have them. sigh
--   color = { fg = colors.green, gui = "bold" },
-- })
--
-- ins_right({
--   "branch",
--   icon = "",
--   color = { fg = colors.violet, gui = "bold" },
-- })
--
--
-- ins_right({
--   function()
--     return "▊"
--   end,
--   color = { fg = colors.blue },
--   padding = { left = 1 },
-- })
--
-- -- Now don't forget to initialize lualine
-- lualine.setup(config)

-- Apply a white background
-- vim.cmd([[highlight Normal guibg=#00000]]) -- Set background color for normal text
vim.cmd([[highlight NormalNC guibg=#000000]]) -- Set background color for non-current windows


vim.api.nvim_set_hl(
  0,
  "RenderMarkdownH1Bg",
  { fg = "#ffffff", bg = "#003366" }
) -- Dark Blue
vim.api.nvim_set_hl(
  0,
  "RenderMarkdownH2Bg",
  { fg = "#ffffff", bg = "#008080" }
) -- Dark Green
vim.api.nvim_set_hl(
  0,
  "RenderMarkdownH3Bg",
  { fg = "#ffffff", bg = "#8B008B" }
) -- Dark Pink (Purple)
vim.api.nvim_set_hl(
  0,
  "RenderMarkdownH4Bg",
  { fg = "#ffffff", bg = "#8B0000" }
) -- Dark Gold
vim.api.nvim_set_hl(
  0,
  "RenderMarkdownH5Bg",
  { fg = "#ffffff", bg = "#8B0000" }
) -- Dark Red

-- Code block highlight
vim.api.nvim_set_hl(0, "RenderMarkdownCode", {
  fg = "#006500", -- Dark Green - Hacker green foreground color
  bg = "#1e1e1e", -- Dark background color for the code block
  bold = true,    -- Make text bold (optional)
})

vim.api.nvim_set_hl(
  0,
  "RenderMarkdownCodeInline",
  {
    fg = "#006500", -- Dark Green - Hacker green foreground color
    bg = "#151515", -- Grey background color
    italic = false, -- Optional: make inline code italic
    bold = true,
  }
)

vim.api.nvim_set_hl(0, "RenderMarkdownLink", {
  fg = "#1E90FF", -- Blue foreground color
})

local focusConfig = {}

focusConfig.setup = function()
  require("focus").setup({
    enable = true,          -- Enable module
    commands = true,        -- Create Focus commands
    autoresize = {
      enable = true,        -- Enable or disable auto-resizing of splits
      width = 1,            -- Force width for the focused window
      height = 1,           -- Force height for the focused window
      minwidth = 1,         -- Force minimum width for the unfocused window
      minheight = 1,        -- Force minimum height for the unfocused window
      height_quickfix = 11, -- Set the height of quickfix panel
    },
    split = {
      bufnew = false, -- Create blank buffer for new split windows
      tmux = false,   -- Create tmux splits instead of neovim splits
    },
    ui = {
      number = false,                    -- Display line numbers in the focused window only
      relativenumber = false,            -- Display relative line numbers in the focused window only
      hybridnumber = false,              -- Display hybrid line numbers in the focused window only
      absolutenumber_unfocussed = false, -- Preserve absolute numbers in the unfocused windows

      cursorline = true,                 -- Display a cursorline in the focused window only
      cursorcolumn = false,              -- Display cursorcolumn in the focused window only
      colorcolumn = {
        enable = false,                  -- Display colorcolumn in the focused window only
        list = "+2",                     -- Set the comma-separated list for the colorcolumn
      },
      signcolumn = true,                 -- Display signcolumn in the focused window only
      winhighlight = false,              -- Auto highlighting for focused/unfocused windows
    },
  })
end

local nvim_lsp = require("lspconfig")

nvim_lsp.jsonls.setup({
  on_attach = function(client, bufnr)
    if
        vim.bo[bufnr].filetype == "sh"
        or vim.fn.expand("%:t") == ".env"
    then
      client.resolved_capabilities.document_formatting =
          true
      client.resolved_capabilities.document_range_formatting =
          true
    end
  end,
})

return {
  { "alvan/vim-closetag" },
  { "windwp/nvim-autopairs" },
  { "nvim-lua/plenary.nvim" },
  { "tveskag/nvim-blame-line" },
  { "terrortylor/nvim-comment" },
  { "voldikss/vim-floaterm" },
  { "tpope/vim-surround" },
  { "NLKNguyen/papercolor-theme" },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    options = {},
    config = function()
      -- Load the UI configurations, which may include lualine
      local ui_config = require("plugins.ui")

      -- If ui_config contains a lualine config, use it
      if ui_config.lualine then
        require("lualine").setup(ui_config.lualine)
      end
    end,
  },
  {
    "iamcco/markdown-preview.nvim",
    cmd = {
      "MarkdownPreviewToggle",
      "MarkdownPreview",
      "MarkdownPreviewStop",
    },
    build = "cd app && yarn install",
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
    end,
    ft = { "markdown" },
  },
  {
    "hrsh8th/nvim-cmp",       -- Completion plugin
    dependencies = {
      "hrsh8th/cmp-nvim-lsp", -- LSP completion source
      "hrsh8th/cmp-buffer",   -- Buffer completion source
      "hrsh8th/cmp-path",     -- Path completion source
      "hrsh8th/cmp-cmdline",  -- Cmdline completion source
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      require("conform").setup({
        formatters_by_ft = {
          lua = {},
          python = {},
          rust = {},
          javascript = {},
          vue = {},
          html = {},
          css = {},
        },
      }),
    },
  },
  {
    "JoosepAlviste/nvim-ts-context-commentstring",
    config = function()
      require("nvim-treesitter.configs").setup({
        context_commentstring = {
          enable = true,
          enable_autocmd = false,
        },
      })
    end,
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 301
    end,
    opts = {
      c = {
        name = "ChatGPT",
        c = { "<cmd>ChatGPT<CR>", "ChatGPT" },
        e = {
          "<cmd>ChatGPTEditWithInstruction<CR>",
          "Edit with instruction",
          mode = { "n", "v" },
        },
        g = {
          "<cmd>ChatGPTRun grammar_correction<CR>",
          "Grammar Correction",
          mode = { "n", "v" },
        },
        t = {
          "<cmd>ChatGPTRun translate<CR>",
          "Translate",
          mode = { "n", "v" },
        },
        k = {
          "<cmd>ChatGPTRun keywords<CR>",
          "Keywords",
          mode = { "n", "v" },
        },
        d = {
          "<cmd>ChatGPTRun docstring<CR>",
          "Docstring",
          mode = { "n", "v" },
        },
        a = {
          "<cmd>ChatGPTRun add_tests<CR>",
          "Add Tests",
          mode = { "n", "v" },
        },
        o = {
          "<cmd>ChatGPTRun optimize_code<CR>",
          "Optimize Code",
          mode = { "n", "v" },
        },
        s = {
          "<cmd>ChatGPTRun summarize<CR>",
          "Summarize",
          mode = { "n", "v" },
        },
        f = {
          "<cmd>ChatGPTRun fix_bugs<CR>",
          "Fix Bugs",
          mode = { "n", "v" },
        },
        x = {
          "<cmd>ChatGPTRun explain_code<CR>",
          "Explain Code",
          mode = { "n", "v" },
        },
        r = {
          "<cmd>ChatGPTRun roxygen_edit<CR>",
          "Roxygen Edit",
          mode = { "n", "v" },
        },
        l = {
          "<cmd>ChatGPTRun code_readability_analysis<CR>",
          "Code Readability Analysis",
          mode = { "n", "v" },
        },
      },
    },
  },
  -- {
  --   "christoomey/vim-tmux-navigator",
  --   lazy = false,
  -- },
  {
    "JoosepAlviste/nvim-ts-context-commentstring",
  },
  { "rhysd/vim-fixjson", cmd = "FixJson" },
  {
    "nvim-focus/focus.nvim",
    config = focusConfig,
  },
  {
    "barrett-ruth/live-server.nvim",
    build = "pnpm add -g live-server",
    cmd = { "LiveServerStart", "LiveServerStop" },
    config = true,
  },
  -- {
  --   "jackMort/ChatGPT.nvim",
  --   event = "VeryLazy",
  --   config = function()
  --     require("chatgpt").setup({
  --       openai_api_key = os.getenv(
  --         "OPENAI_API_KEY"
  --       ),
  --     })
  --   end,
  --   dependencies = {
  --     "MunifTanjim/nui.nvim",
  --     "nvim-lua/plenary.nvim",
  --     "folke/trouble.nvim",
  --     "nvim-telescope/telescope.nvim",
  --   },
  -- },
  {
    "robitx/gp.nvim",
    config = function()
      require("gp").setup({
        openai_api_key = os.getenv(
          "OPEN_API_KEY"
        ),
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opt = true,
    event = "BufReadPre",
    config = function()
      -- Configure TypeScript LSP (`ts_ls`) for JavaScript and TypeScript files
      require("lspconfig").ts_ls.setup({
        capabilities = capabilities,
        on_attach = function(client, bufnr)
          -- Enable formatting for TypeScript and JavaScript
          client.server_capabilities.documentFormattingProvider = true
          client.server_capabilities.documentRangeFormattingProvider = true
        end,
        filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" }, -- Explicitly specify supported filetypes
        init_options = {
          plugins = {
            {
              name = "@vue/typescript-plugin",
              location = "/usr/local/lib/node_modules/@vue/typescript-plugin", -- Adjust location if necessary
              languages = { "javascript", "typescript", "vue" },
            },
          },
        },
      })

      -- Configure Vue LSP (`vuels`) for `.vue` files and ensure it's also handling formatting
      require("lspconfig").vuels.setup({
        on_attach = function(client, bufnr)
          -- Enable auto-formatting capability for vuels
          client.resolved_capabilities.document_formatting = true
          client.resolved_capabilities.document_range_formatting = true
        end,
      })

      -- Configure Lua LSP (`lua_ls`) for Lua files
      require("lspconfig").lua_ls.setup({
        capabilities = capabilities,
        on_attach = function(client, bufnr)
          -- Make sure that the server supports formatting
          if client.server_capabilities.documentFormattingProvider then
            client.server_capabilities.documentFormattingProvider = true
          end
          if client.server_capabilities.documentRangeFormattingProvider then
            client.server_capabilities.documentRangeFormattingProvider = true
          end
        end,
        filetypes = { "lua" },
      })

      -- Autoformat on save for various filetypes
      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = "*.jsx,*.tsx,*.js,*.ts,*.vue,*.lua", -- Adjust the pattern based on your needs
        callback = function()
          vim.lsp.buf.format({ async = true })
        end,
      })
    end
  },
  {
    "HampusHauffman/block.nvim",
    config = function()
      -- require("block").setup({})
    end,
  },
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      config = function(_, opts)
        local telescope = require("telescope")

        -- Ensure opts is a valid table before calling setup
        if type(opts) == "table" then
          telescope.setup(opts)

          -- Load the FZF extension
          pcall(telescope.load_extension, "fzf")
        else
          -- Log an error or fallback if opts is not a table
          print("Error: Telescope opts is nil or not a table!")
        end
      end,
      opts = {
        defaults = {
          layout_strategy = "horizontal",
          layout_config = {
            height = 1.95,
            prompt_position = "top",
            vertical = {
              mirror = true,
              preview_cutoff = 1,
              preview_height = 1.70,
            },
          },
        },
      },
      requires = {
        {
          "nvim-telescope/telescope-fzf-native.nvim",
          run = "make",
        },
        {
          "nvim-telescope/telescope-symbols.nvim",
          config = function()
            require("telescope").load_extension(
              "symbols"
            )
          end,
        },
        {
          "tiagovla/scope.nvim",
          opts = {},
          init = function()
            require("lazyvim.util").on_load(
              "telescope",
              function()
                require("telescope").load_extension(
                  "scope"
                )
              end
            )
          end,
          keys = {
            {
              "<leader>ba",
              "<Cmd>Telescope scope buffers theme=dropdown<CR>",
              desc = "Search buffers from all tabs",
            },
            {
              "<leader>bm",
              "<Cmd>ScopeMoveBuf<CR>",
              desc = "Move buffer to another tab",
            },
          },
        },
      },
    },

    --[[   Color Schemes ]]
    {
      "craftzdog/solarized-osaka.nvim",
      lazy = false,
      priority = 1001,
      opts = {},
      config = function()
        -- Theme Config
        local osakaConfig = {
          transparent = true,     -- Disable transparency to set a background color
          terminal_colors = true, -- Configure the colors used when opening a `:terminal` in Neovim
          styles = {
            -- Style to be applied to different syntax groups
            -- Value is any valid attr-list value for `:help nvim_set_hl`
            -- comments = { fg = "#21223a", bg = "#6d6d6d" },
            -- keywords = { fg = "#FFFFFF", bg = "#000001" },
            comments = { italic = true },
            functions = {},
            variables = {},
            -- Background styles. Can be "dark", "transparent" or "normal"
            sidebars = "transparent",       -- Keep sidebars dark if you want to preserve this
            floats = "transparent",         -- Floating windows can stay transparent if you like
          },
          sidebars = { "qf", "help" },      -- Set a darker background for sidebar-like windows

          hide_inactive_statusline = false, -- Enabling this option will hide inactive statuslines and replace them with a thin border instead
          dim_inactive = false,             -- Dims inactive windows
          lualine_bold = false,             -- When true, section headers in the lualine theme will be bold

          --   -- Borderless Telescope example
          on_highlights = function(hl, color)
            local prompt = "#2d3149"
            hl.TelescopeNormal = {
              bg = color.transparent,
              fg = color.fg_dark,
            }
            hl.TelescopeBorder = {
              bg = color.transparent,
              fg = color.transparent,
            }
            hl.TelescopePromptNormal = {
              bg = prompt,
            }
            hl.TelescopePromptBorder = {
              bg = prompt,
              fg = prompt,
            }
            hl.TelescopePromptTitle = {
              bg = prompt,
              fg = prompt,
            }
            hl.TelescopePreviewTitle = {
              bg = color.transparent,
              fg = color.transparent,
            }
            hl.TelescopeResultsTitle = {
              bg = color.transparent,
              fg = color.transparent,
            }
          end,
        }
        require("solarized-osaka").setup(osakaConfig)
      end,
    },
    -- {
    --   "habamax/vim-habanight",
    --   config = function()
    --     vim.cmd("colorscheme habanight")
    --     vim.cmd("hi Normal guibg=NONE ctermbg=NONE")
    --   end,
    -- },

    {
      "numToStr/Comment.nvim",
      dependencies = {
        "JoosepAlviste/nvim-ts-context-commentstring",
      },
      config = function()
        require("Comment").setup({
          pre_hook = require(
            "ts_context_commentstring.integrations.comment_nvim"
          ).create_pre_hook(),
        })
      end,
    },
    {
      "folke/noice.nvim",
      opts = function(_, opts)
        table.insert(opts.routes, {
          filter = {
            event = "notify",
            find = "No information available",
          },
          opts = { skip = true },
        })

        opts.presets.lsp_doc_border = true
      end,
    },

    {
      "rcarriga/nvim-notify",
      opts = {
        level = 4,
        render = "minimal",
        stages = "static",
        timeout = 2001,
      },
    },

    -- animations
    {
      "echasnovski/mini.animate",
      event = "VeryLazy",
      opts = function(_, opts)
        opts.scroll = {
          enable = false,
        }
      end,
    },

    -- bufferline
    {
      "akinsho/bufferline.nvim",
      -- tag = "*",
      -- event = "verylazy",
      requires = "nvim-tree/nvim-web-devicons",
      keys = {
        {
          "<tab>",
          "<cmd>bufferlinecyclenext<cr>",
          desc = "next tab",
        },
        {
          "<s-tab>",
          "<cmd>bufferlinecycleprev<cr>",
          desc = "prev tab",
        },
      },
      opts = {
        options = {
          show_buffer_close_icons = true,
          show_close_icon = true,
        },
      },
    },

    -- LOGO
    {
      "nvimdev/dashboard-nvim",
      lazy = false,
      opts = function(_, opts)
        local logo = [[
          ██████╗  █████╗ ██████╗ ██╗  ██╗    ███╗   ███╗███████╗ ██████╗ ██╗    ██╗
          ██╔══██╗██╔══██╗██╔══██╗██║ ██╔╝    ████╗ ████║██╔════╝██╔═══██╗██║    ██║
          ██║  ██║███████║██████╔╝█████╔╝     ██╔████╔██║█████╗  ██║   ██║██║ █╗ ██║
          ██║  ██║██╔══██║██╔══██╗██╔═██╗     ██║╚██╔╝██║██╔══╝  ██║   ██║██║███╗██║
          ██████╔╝██║  ██║██║  ██║██║  ██╗    ██║ ╚═╝ ██║███████╗╚██████╔╝╚███╔███╔╝
          ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝    ╚═╝     ╚═╝╚══════╝ ╚═════╝  ╚══╝╚══╝
      ]]

        opts.config = opts.config or {}
        opts.config.header = vim.split(logo, "\n")
      end,
    },

    -- Incline Floating File name and git info
    {
      "b0o/incline.nvim",
      opts = {
        window = {
          zindex = 41,
          margin = { horizontal = 1, vertical = 0 },
        },
        hide = { cursorline = true },
        -- ignore = { buftypes = function(bufnr, buftype) return false end },
        render = function(props)
          if
              not vim.api.nvim_buf_is_valid(props.buf)
          then
            return {}
          end

          if
              vim.bo[props.buf].buftype == "terminal"
          then
            return {
              {
                " "
                .. vim.bo[props.buf].channel
                .. " ",
                group = "DevIconTerminal",
              },
              {
                " "
                .. vim.api.nvim_win_get_number(
                  props.win
                ),
                group = "Special",
              },
            }
          end

          local filename = vim.fn.fnamemodify(
            vim.api.nvim_buf_get_name(props.buf),
            ":t"
          )
          local ft_icon, ft_color = require(
            "nvim-web-devicons"
          ).get_icon_color(filename)
          local modified = vim.api.nvim_get_option_value(
            "modified",
            { buf = props.buf }
          ) and "italic" or ""

          local function get_git_diff()
            local icons =
                require("lazyvim.config").icons.git
            icons["changed"] = icons.modified
            local signs =
                vim.b[props.buf].gitsigns_status_dict
            local labels = {}
            if signs == nil then
              return labels
            end
            for name, icon in pairs(icons) do
              if
                  tonumber(signs[name])
                  and signs[name] > 1
              then
                table.insert(labels, {
                  icon .. signs[name] .. " ",
                  group = "Diff" .. name,
                })
              end
            end
            if #labels > 1 then
              table.insert(labels, { "┊ " })
            end
            return labels
          end
          local function get_diagnostic_label()
            local icons =
                require("lazyvim.config").icons.diagnostics
            local label = {}

            for severity, icon in pairs(icons) do
              local n =
                  #vim.diagnostic.get(props.buf, {
                    severity = vim.diagnostic.severity[string.upper(
                      severity
                    )],
                  })
              if n > 1 then
                table.insert(label, {
                  icon .. n .. " ",
                  group = "DiagnosticSign"
                      .. severity,
                })
              end
            end
            if #label > 1 then
              table.insert(label, { "┊ " })
            end
            return label
          end

          local buffer = {
            { get_diagnostic_label() },
            { get_git_diff() },
            {
              ft_icon .. " ",
              guifg = ft_color,
              guibg = "none",
            },
            { filename .. " ", gui = modified },
            -- { " " .. vim.api.nvim_win_get_number(props.win), group = "Special" },
          }
          return buffer
        end,
      },
    },

    {
      "williamboman/mason.nvim",
      config = function()
        require("mason").setup()
      end,
      opts = {
        ensure_installed = {
          "stylua",
          "shellcheck",
          "shfmt",
          "flake9",
          "typescript-language-server",
          "html-lsp",
          "lua-language-server",
        },
      },
    },

    -- Use <tab> for completion and snippets (supertab)
    -- first: disable default <tab> and <s-tab> behavior in LuaSnip
    {
      "L3MON4D3/LuaSnip",
      keys = function()
        return {}
      end,
    },
    -- then: setup supertab in cmp
    {
      "hrsh8th/nvim-cmp",
      dependencies = {
        "hrsh8th/cmp-emoji",
      },
      ---@param opts cmp.ConfigSchema
      opts = function(_, opts)
        local has_words_before = function()
          unpack = unpack or table.unpack
          local line, col =
              unpack(vim.api.nvim_win_get_cursor(1))
          return col ~= 1
              and vim.api
              .nvim_buf_get_lines(1, line - 1, line, true)[1]
              :sub(col, col)
              :match("%s")
              == nil
        end

        local luasnip = require("luasnip")
        local cmp = require("cmp")
        cmp.setup({
          completion = {
            completeopt = "menu,menuone,noselect",
          },
          snippet = {
            expand = function(args)
              -- Use your snippet engine here (e.g., luasnip, vsnip)
              vim.fn["vsnip#anonymous"](args.body)
            end,
          },
          mapping = cmp.mapping.preset.insert({
            ["<C-p>"] = cmp.mapping.select_prev_item(),
            ["<C-n>"] = cmp.mapping.select_next_item(),
            ["<C-d>"] = cmp.mapping.scroll_docs(-3),
            ["<C-f>"] = cmp.mapping.scroll_docs(5),
            ["<C-Space>"] = cmp.mapping.complete(),
            ["<C-e>"] = cmp.mapping.close(),
            ["<CR>"] = cmp.mapping.confirm({
              select = true,
            }),
          }),
          sources = {
            { name = "nvim_lsp" }, -- Enable LSP completion
            { name = "buffer" },
            { name = "path" },
            { name = "cmdline" },
          },
        })

        -- Common capabilities for LSP
        local capabilities =
            vim.lsp.protocol.make_client_capabilities()

        -- Use the default capabilities from cmp_nvim_lsp
        local cmp_nvim_lsp = require("cmp_nvim_lsp")
        capabilities =
            cmp_nvim_lsp.default_capabilities(
              capabilities
            )

        -- Example LSP server setup with capabilities
        require("lspconfig").pyright.setup({
          capabilities = capabilities,
        })

        require("lspconfig").ts_ls.setup({
          capabilities = capabilities,
        })
      end,
    },
    {
      "MeanderingProgrammer/render-markdown.nvim",
      dependencies = {
        "nvim-treesitter/nvim-treesitter", -- Syntax highlighting support
        "echasnovski/mini.nvim",           -- If you're using mini.nvim suite (optional)
      },
      config = function()
        print(
          "Setting up render-markdown plugin..."
        )
        -- Call the setup function to initialize the plugin
        require("render-markdown").setup({
          heading = {
            -- Turn on / off heading icon & background rendering
            enabled = true,
            -- Turn on / off any sign column related rendering
            sign = true,
            -- Determines how icons fill the available space:
            --  right:   '#'s are concealed and icon is appended to right side
            --  inline:  '#'s are concealed and icon is inlined on left side
            --  overlay: icon is left padded with spaces and inserted on left hiding any additional '#'
            position = "overlay",
            -- Replaces '#+' of 'atx_h._marker'
            -- The number of '#' in the heading determines the 'level'
            -- The 'level' is used to index into the list using a cycle
            icons = {
              "󰲡 ",
              "󰲣 ",
              "󰲥 ",
              "󰲧 ",
              "󰲩 ",
              "󰲫 ",
            },
            -- Added to the sign column if enabled
            -- The 'level' is used to index into the list using a cycle
            signs = { "󰫎 " },
            -- Width of the heading background:
            --  block: width of the heading text
            --  full:  full width of the window
            -- Can also be a list of the above values in which case the 'level' is used
            -- to index into the list using a clamp
            width = "full",
            -- Amount of margin to add to the left of headings
            -- If a floating point value < 1 is provided it is treated as a percentage of the available window space
            -- Margin available space is computed after accounting for padding
            -- Can also be a list of numbers in which case the 'level' is used to index into the list using a clamp
            left_margin = 0,
            -- Amount of padding to add to the left of headings
            -- If a floating point value < 1 is provided it is treated as a percentage of the available window space
            -- Can also be a list of numbers in which case the 'level' is used to index into the list using a clamp
            left_pad = 0,
            -- Amount of padding to add to the right of headings when width is 'block'
            -- If a floating point value < 1 is provided it is treated as a percentage of the available window space
            -- Can also be a list of numbers in which case the 'level' is used to index into the list using a clamp
            right_pad = 0,
            -- Minimum width to use for headings when width is 'block'
            -- Can also be a list of integers in which case the 'level' is used to index into the list using a clamp
            min_width = 0,
            -- Determines if a border is added above and below headings
            -- Can also be a list of booleans in which case the 'level' is used to index into the list using a clamp
            border = false,
            -- Always use virtual lines for heading borders instead of attempting to use empty lines
            border_virtual = false,
            -- Highlight the start of the border using the foreground highlight
            border_prefix = false,
            -- Used above heading for border
            above = "▄",
            -- Used below heading for border
            below = "▀",
            -- The 'level' is used to index into the list using a clamp
            -- Highlight for the heading icon and extends through the entire line
            backgrounds = {
              "RenderMarkdownH1Bg",
              "RenderMarkdownH2Bg",
              "RenderMarkdownH3Bg",
              "RenderMarkdownH4Bg",
              "RenderMarkdownH5Bg",
              "RenderMarkdownH6Bg",
            },
            -- The 'level' is used to index into the list using a clamp
            -- Highlight for the heading and sign icons
            foregrounds = {
              "RenderMarkdownH1",
              "RenderMarkdownH2",
              "RenderMarkdownH3",
              "RenderMarkdownH4",
              "RenderMarkdownH5",
              "RenderMarkdownH6",
            },
          },
          code = {
            enabled = true,
            sign = true,
            style = "full",    -- You can use 'full' to show the language icon and name, or 'normal' for just basic rendering
            position = "left", -- Position of the language icon (left or right)
            language_pad = 0,
            language_name = true,
            disable_background = { "diff" },
            width = "full",
            left_margin = 0,
            left_pad = 0,
            right_pad = 0,
            min_width = 0,
            border = "thin", -- Border above and below code blocks
            above = "▄", -- Character for the top border
            below = "▀", -- Character for the bottom border
            highlight = "RenderMarkdownCode", -- Highlight for the entire code block
            highlight_inline = "RenderMarkdownCodeInline", -- Highlight for inline code
            highlight_language = "RenderMarkdownCodeLanguage", -- Optional: Highlight for language text (if you use language name)
          },
        })
      end,
    },
    {
      "nvim-neo-tree/neo-tree.nvim",
      branch = "v3.x",
      dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
        "MunifTanjim/nui.nvim",
        {
          "s1n7ax/nvim-window-picker",
          version = "3.*",
          config = function()
            require("window-picker").setup({
              filter_rules = {
                include_current_win = false,
                autoselect_one = true,
                -- filter using buffer options
                bo = {
                  -- if the file type is one of following, the window will be ignored
                  filetype = {
                    "neo-tree",
                    "neo-tree-popup",
                    "notify",
                  },
                  -- if the buffer type is one of following, the window will be ignored
                  buftype = {
                    "terminal",
                    "quickfix",
                  },
                },
              },
            })
          end,
        },
      },
      config = function()
        -- If you want icons for diagnostic errors, you'll need to define them somewhere:
        vim.fn.sign_define("DiagnosticSignError", {
          text = " ",
          texthl = "DiagnosticSignError",
        })
        vim.fn.sign_define("DiagnosticSignWarn", {
          text = " ",
          texthl = "DiagnosticSignWarn",
        })
        vim.fn.sign_define("DiagnosticSignInfo", {
          text = " ",
          texthl = "DiagnosticSignInfo",
        })
        vim.fn.sign_define("DiagnosticSignHint", {
          text = "󰌵",
          texthl = "DiagnosticSignHint",
        })

        require("neo-tree").setup({
          close_if_last_window = false, -- Close Neo-tree if it is the last window left in the tab
          popup_border_style = "rounded",
          enable_git_status = true,
          enable_diagnostics = true,
          enable_normal_mode_for_inputs = false, -- Enable normal mode for input dialogs.
          open_files_do_not_replace_types = {
            "terminal",
            "trouble",
            "qf",
          },                             -- when opening files, do not use windows containing these filetypes or buftypes
          sort_case_insensitive = false, -- used when sorting files and directories in the tree
          sort_function = nil,           -- use a custom function for sorting files and directories in the tree
          -- sort_function = function (a,b)
          --       if a.type == b.type then
          --           return a.path > b.path
          --       else
          --           return a.type > b.type
          --       end
          --   end , -- this sorts files and directories descendantly
          default_component_configs = {
            container = {
              enable_character_fade = true,
            },
            indent = {
              indent_size = 3,
              padding = 2, -- extra padding on left hand side
              -- indent guides
              with_markers = true,
              indent_marker = "│",
              last_indent_marker = "└",
              highlight = "NeoTreeIndentMarker",
              -- expander config, needed for nesting files
              with_expanders = nil, -- if nil and file nesting is enabled, will enable expanders
              expander_collapsed = "",
              expander_expanded = "",
              expander_highlight = "NeoTreeExpander",
            },
            icon = {
              folder_closed = "",
              folder_open = "",
              folder_empty = "󰜌",
              -- The next two settings are only a fallback, if you use nvim-web-devicons and configure default icons there
              -- then these will never be used.
              default = "*",
              highlight = "NeoTreeFileIcon",
            },
            modified = {
              symbol = "[+]",
              highlight = "NeoTreeModified",
            },
            name = {
              trailing_slash = false,
              use_git_status_colors = true,
              highlight = "NeoTreeFileName",
            },
            git_status = {
              symbols = {
                -- Change type
                added = "", -- or "✚", but this is redundant info if you use git_status_colors on the name
                modified = "", -- or "", but this is redundant info if you use git_status_colors on the name
                deleted = "✖", -- this can only be used in the git_status source
                renamed = "󰁕", -- this can only be used in the git_status source
                -- Status type
                untracked = "",
                ignored = "",
                unstaged = "󰄱",
                staged = "",
                conflict = "",
              },
            },
            -- If you don't want to use these columns, you can set `enabled = false` for each of them individually
            file_size = {
              enabled = true,
            },
            required_width = 65, -- min width of window required to show this column
            type = {
              enabled = true,
              required_width = 123, -- min width of window required to show this column
            },
            last_modified = {
              enabled = true,
              required_width = 89, -- min width of window required to show this column
            },
            created = {
              enabled = true,
              required_width = 111, -- min width of window required to show this column
            },
            symlink_target = {
              enabled = false,
            },
          },
          -- A list of functions, each representing a global custom command
          -- that will be available in all sources (if not overridden in `opts[source_name].commands`)
          -- see `:h neo-tree-custom-commands-global`
          commands = {},
          window = {
            position = "float",
            width = 31,
            mapping_options = {
              noremap = true,
              nowait = true,
            },
            mappings = {
              ["<space>"] = {
                "toggle_node",
                nowait = false, -- disable `nowait` if you have existing combos starting with this char that you want to use
              },
              ["<3-LeftMouse>"] = "open",
              ["<cr>"] = "open",
              ["<esc>"] = "cancel", -- close preview or floating neo-tree window
              ["P"] = {
                "toggle_preview",
                config = { use_float = true },
              },
              ["l"] = "focus_preview",
              ["S"] = "open_split",
              ["s"] = "open_vsplit",
              -- ["S"] = "split_with_window_picker",
              -- ["s"] = "vsplit_with_window_picker",
              ["t"] = "open_tabnew",
              -- ["<cr>"] = "open_drop",
              -- ["t"] = "open_tab_drop",
              ["w"] = "open_with_window_picker",
              --["P"] = "toggle_preview", -- enter preview mode, which shows the current node without focusing
              ["C"] = "close_node",
              -- ['C'] = 'close_all_subnodes',
              ["z"] = "close_all_nodes",
              --["Z"] = "expand_all_nodes",
              ["a"] = {
                "add",
                -- this command supports BASH style brace expansion ("x{a,b,c}" -> xa,xb,xc). see `:h neo-tree-file-actions` for details
                -- some commands may take optional config options, see `:h neo-tree-mappings` for details
                config = {
                  show_path = "none", -- "none", "relative", "absolute"
                },
              },
              ["A"] = "add_directory", -- also accepts the optional config.show_path option like "add". this also supports BASH style brace expansion.
              ["d"] = "delete",
              ["r"] = "rename",
              ["y"] = "copy_to_clipboard",
              ["x"] = "cut_to_clipboard",
              ["p"] = "paste_from_clipboard",
              ["c"] = "copy", -- takes text input for destination, also accepts the optional config.show_path option like "add":
              -- ["c"] = {
              --  "copy",
              --  config = {
              --    show_path = "none" -- "none", "relative", "absolute"
              --  }
              --}
              ["m"] = "move", -- takes text input for destination, also accepts the optional config.show_path option like "add".
              ["q"] = "close_window",
              ["R"] = "refresh",
              ["?"] = "show_help",
              ["<"] = "prev_source",
              [">"] = "next_source",
              ["i"] = "show_file_details",
              ["e"] = function()
                vim.api.nvim_exec(
                  "Neotree focus filesystem",
                  true
                )
              end,
              ["b"] = function()
                vim.api.nvim_exec(
                  "Neotree focus buffers",
                  true
                )
              end,
              ["g"] = function()
                vim.api.nvim_exec(
                  "Neotree focus git_status",
                  true
                )
              end,
            },
          },
          nesting_rules = {},
          filesystem = {
            filtered_items = {
              visible = true, -- when true, they will just be displayed differently than normal items
              hide_dotfiles = true,
              hide_gitignored = true,
              hide_hidden = true, -- only works on Windows for hidden files/directories
              hide_by_name = {
                --"node_modules"
              },
              hide_by_pattern = { -- uses glob style patterns
                --"*.meta",
                --"*/src/*/tsconfig.json",
              },
              always_show = { -- remains visible even if other settings would normally hide it
                -- ".gitignored",
              },
              never_show = { -- remains hidden even if visible is toggled to true, this overrides always_show
                --".DS_Store",
                --"thumbs.db"
              },
              never_show_by_pattern = { -- uses glob style patterns
                --".null-ls_*",
              },
            },
            follow_current_file = {
              enabled = true,                       -- This will find and focus the file in the active buffer every time
              --               -- the current file is changed while the tree is open.
              leave_dirs_open = false,              -- `false` closes auto expanded dirs, such as with `:Neotree reveal`
            },
            group_empty_dirs = false,               -- when true, empty folders will be grouped together
            hijack_netrw_behavior = "open_default", -- netrw disabled, opening a directory opens neo-tree
            -- in whatever position is specified in window.position
            -- "open_current",  -- netrw disabled, opening a directory opens within the
            -- window like netrw would, regardless of window.position
            -- "disabled",    -- netrw left alone, neo-tree does not handle opening dirs
            use_libuv_file_watcher = false, -- This will use the OS level file watchers to detect changes
            -- instead of relying on nvim autocmd events.
            window = {
              mappings = {
                ["<bs>"] = "navigate_up",
                ["."] = "set_root",
                ["H"] = "toggle_hidden",
                ["/"] = "fuzzy_finder",
                ["D"] = "fuzzy_finder_directory",
                ["#"] = "fuzzy_sorter", -- fuzzy sorting using the fzy algorithm
                -- ["D"] = "fuzzy_sorter_directory",
                ["f"] = "filter_on_submit",
                ["<c-x>"] = "clear_filter",
                ["[g"] = "prev_git_modified",
                ["]g"] = "next_git_modified",
                ["o"] = {
                  "show_help",
                  nowait = false,
                  config = {
                    title = "Order by",
                    prefix_key = "o",
                  },
                },
                ["oc"] = {
                  "order_by_created",
                  nowait = false,
                },
                ["od"] = {
                  "order_by_diagnostics",
                  nowait = false,
                },
                ["og"] = {
                  "order_by_git_status",
                  nowait = false,
                },
                ["om"] = {
                  "order_by_modified",
                  nowait = false,
                },
                ["on"] = {
                  "order_by_name",
                  nowait = false,
                },
                ["os"] = {
                  "order_by_size",
                  nowait = false,
                },
                ["ot"] = {
                  "order_by_type",
                  nowait = false,
                },
              },
              fuzzy_finder_mappings = { -- define keymaps for filter popup window in fuzzy_finder_mode
                ["<down>"] = "move_cursor_down",
                ["<C-n>"] = "move_cursor_down",
                ["<up>"] = "move_cursor_up",
                ["<C-p>"] = "move_cursor_up",
              },
            },

            commands = {}, -- Add a custom command or override a global one using the same function name
          },
          buffers = {
            follow_current_file = {
              enabled = true,          -- This will find and focus the file in the active buffer every time
              --              -- the current file is changed while the tree is open.
              leave_dirs_open = false, -- `false` closes auto expanded dirs, such as with `:Neotree reveal`
            },
            group_empty_dirs = true,   -- when true, empty folders will be grouped together
            show_unloaded = true,
            window = {
              mappings = {
                ["bd"] = "buffer_delete",
                ["<bs>"] = "navigate_up",
                ["."] = "set_root",
                ["o"] = {
                  "show_help",
                  nowait = false,
                  config = {
                    title = "Order by",
                    prefix_key = "o",
                  },
                },
                ["oc"] = {
                  "order_by_created",
                  nowait = false,
                },
                ["od"] = {
                  "order_by_diagnostics",
                  nowait = false,
                },
                ["om"] = {
                  "order_by_modified",
                  nowait = false,
                },
                ["on"] = {
                  "order_by_name",
                  nowait = false,
                },
                ["os"] = {
                  "order_by_size",
                  nowait = false,
                },
                ["ot"] = {
                  "order_by_type",
                  nowait = false,
                },
              },
            },
          },
          git_status = {
            window = {
              position = "float",
              mappings = {
                ["A"] = "git_add_all",
                ["gu"] = "git_unstage_file",
                ["ga"] = "git_add_file",
                ["gr"] = "git_revert_file",
                ["gc"] = "git_commit",
                ["gp"] = "git_push",
                ["gg"] = "git_commit_and_push",
                ["o"] = {
                  "show_help",
                  nowait = false,
                  config = {
                    title = "Order by",
                    prefix_key = "o",
                  },
                },
                ["oc"] = {
                  "order_by_created",
                  nowait = false,
                },
                ["od"] = {
                  "order_by_diagnostics",
                  nowait = false,
                },
                ["om"] = {
                  "order_by_modified",
                  nowait = false,
                },
                ["on"] = {
                  "order_by_name",
                  nowait = false,
                },
                ["os"] = {
                  "order_by_size",
                  nowait = false,
                },
                ["ot"] = {
                  "order_by_type",
                  nowait = false,
                },
              },
            },
          },
          event_handlers = {
            {
              event = "neo_tree_buffer_enter",
              handler = function()
                -- This effectively hides the cursor
                vim.cmd(
                  "highlight! Cursor blend=101"
                )
              end,
            },
            {
              event = "neo_tree_buffer_leave",
              handler = function()
                -- Make this whatever your current Cursor highlight group is.
                vim.cmd(
                  "highlight! Cursor guibg=#6f87af blend=0"
                )
              end,
            },
          },
        })

        vim.cmd(
          [[nnoremap \ :Neotree float toggle reveal<cr>]]
        )
      end,
    },
  },
}
