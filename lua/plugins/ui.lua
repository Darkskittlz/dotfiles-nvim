-- Set the virtual_column option to keep cursor column numbers the same
-- vim.o.virtual_column = "all"
vim.g.lazygit = {
  colors = {
    bg = "#000000", -- Set the background color to black
    -- Add other color settings as needed
  },
}

vim.opt.wrap = false

vim.api.nvim_set_option(
  "clipboard",
  "unnamedplus"
)

-- Theme Config
local osakaConfig = {
  transparent = true, -- Enable this to disable setting the background color
  terminal_colors = true, -- Configure the colors used when opening a `:terminal` in Neovim
  styles = {
    -- Style to be applied to different syntax groups
    -- Value is any valid attr-list value for `:help nvim_set_hl`
    -- comments = { fg = "#a8a8a8", bg = "#000000" },
    -- keywords = { fg = "#FFFFFF", bg = "#000000" },
    functions = {},
    variables = {},
    -- Background styles. Can be "dark", "transparent" or "normal"
    sidebars = "dark", -- style for sidebars
    floats = "transparent", -- style for floating windows
  },
  sidebars = { "qf", "help" }, -- Set a darker background on sidebar-like windows

  hide_inactive_statusline = false, -- Enabling this option, will hide inactive statuslines and replace them with a thin border instead
  dim_inactive = false, -- Dims inactive windows
  lualine_bold = false, -- When true, section headers in the lualine theme will be bold
}

require("solarized-osaka").setup(osakaConfig)

local focusConfig = {}

focusConfig.setup = function()
  require("focus").setup({
    enable = true, -- Enable module
    commands = true, -- Create Focus commands
    autoresize = {
      enable = true, -- Enable or disable auto-resizing of splits
      width = 0, -- Force width for the focused window
      height = 0, -- Force height for the focused window
      minwidth = 0, -- Force minimum width for the unfocused window
      minheight = 0, -- Force minimum height for the unfocused window
      height_quickfix = 10, -- Set the height of quickfix panel
    },
    split = {
      bufnew = false, -- Create blank buffer for new split windows
      tmux = false, -- Create tmux splits instead of neovim splits
    },
    ui = {
      number = false, -- Display line numbers in the focused window only
      relativenumber = false, -- Display relative line numbers in the focused window only
      hybridnumber = false, -- Display hybrid line numbers in the focused window only
      absolutenumber_unfocussed = false, -- Preserve absolute numbers in the unfocused windows

      cursorline = true, -- Display a cursorline in the focused window only
      cursorcolumn = false, -- Display cursorcolumn in the focused window only
      colorcolumn = {
        enable = false, -- Display colorcolumn in the focused window only
        list = "+1", -- Set the comma-separated list for the colorcolumn
      },
      signcolumn = true, -- Display signcolumn in the focused window only
      winhighlight = false, -- Auto highlighting for focused/unfocused windows
    },
  })
end

local nvim_lsp = require("lspconfig")

nvim_lsp.jsonls.setup({
  on_attach = function(client)
    -- Enable formatting on save
    if
      client.resolved_capabilities.document_formatting
    then
      vim.cmd(
        "autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync()"
      )
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
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
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
  {
    "jackMort/ChatGPT.nvim",
    event = "VeryLazy",
    config = function()
      require("chatgpt").setup({
        openai_api_key = os.getenv(
          "OPENAI_API_KEY"
        ),
      })
    end,
    dependencies = {
      "MunifTanjim/nui.nvim",
      "nvim-lua/plenary.nvim",
      "folke/trouble.nvim",
      "nvim-telescope/telescope.nvim",
    },
  },
  {
    "neovim/nvim-lspconfig",
    opt = true,
    event = "BufReadPre",
  },
  {
    "HampusHauffman/block.nvim",
    config = function()
      -- require("block").setup({})
    end,
  },
  {
    "nvim-telescope/telescope.nvim",
    opts = {
      defaults = {
        layout_strategy = "vertical",
        layout_config = {
          height = 0.95, -- Adjust the height of the results pane to be smaller
          prompt_position = "top",
          vertical = {
            mirror = true,
            preview_cutoff = 0,
            preview_height = 0.70, -- Adjust the width of the preview pane to be bigger
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
  {
    "iamcco/markdown-preview.nvim",
    cmd = {
      "MarkdownPreviewToggle",
      "MarkdownPreview",
      "MarkdownPreviewStop",
    },
    ft = { "markdown" },
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
  },

  --[[   Color Schemes ]]
  {
    "craftzdog/solarized-osaka.nvim",
    lazy = false,
    priority = 1000,
    opts = {},
    config = function()
      vim.cmd("colorscheme solarized-osaka")
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
    config = function()
      require("Comment").setup()
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
      level = 3,
      render = "minimal",
      stages = "static",
      timeout = 2000,
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
    event = "VimEnter",
    opts = function(_, opts)
      local logo = [[
          ██████╗  █████╗ ██████╗ ██╗  ██╗    ███╗   ███╗███████╗ ██████╗ ██╗    ██╗
          ██╔══██╗██╔══██╗██╔══██╗██║ ██╔╝    ████╗ ████║██╔════╝██╔═══██╗██║    ██║
          ██║  ██║███████║██████╔╝█████╔╝     ██╔████╔██║█████╗  ██║   ██║██║ █╗ ██║
          ██║  ██║██╔══██║██╔══██╗██╔═██╗     ██║╚██╔╝██║██╔══╝  ██║   ██║██║███╗██║
          ██████╔╝██║  ██║██║  ██║██║  ██╗    ██║ ╚═╝ ██║███████╗╚██████╔╝╚███╔███╔╝
          ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝    ╚═╝     ╚═╝╚══════╝ ╚═════╝  ╚══╝╚══╝
      ]]

      logo = string.rep("\n", 8) .. logo .. "\n\n"
      opts.config.header = vim.split(logo, "\n")
    end,
  },

  -- Incline Floating File name and git info
  {
    "b0o/incline.nvim",
    opts = {
      window = {
        zindex = 40,
        margin = { horizontal = 0, vertical = 0 },
      },
      hide = { cursorline = true },
      -- ignore = { buftypes = function(bufnr, buftype) return false end },
      render = function(props)
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
          { buf = 0 }
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
              and signs[name] > 0
            then
              table.insert(labels, {
                icon .. signs[name] .. " ",
                group = "Diff" .. name,
              })
            end
          end
          if #labels > 0 then
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
            if n > 0 then
              table.insert(label, {
                icon .. n .. " ",
                group = "DiagnosticSign"
                  .. severity,
              })
            end
          end
          if #label > 0 then
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

  -- add any tools you want to have installed below
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "stylua",
        "shellcheck",
        "shfmt",
        "flake8",
        "typescript-language-server",
        "lua-language-server",
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
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-emoji",
    },
    ---@param opts cmp.ConfigSchema
    opts = function(_, opts)
      local has_words_before = function()
        unpack = unpack or table.unpack
        local line, col =
          unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0
          and vim.api
              .nvim_buf_get_lines(0, line - 1, line, true)[1]
              :sub(col, col)
              :match("%s")
            == nil
      end

      local luasnip = require("luasnip")
      local cmp = require("cmp")

      opts.mapping =
        vim.tbl_extend("force", opts.mapping, {
          ["<Tab>"] = cmp.mapping(
            function(fallback)
              if cmp.visible() then
                cmp.select_next_item()
              -- You could replace the expand_or_jumpable() calls with expand_or_locally_jumpable()
              -- this way you will only jump inside the snippet region
              elseif
                luasnip.expand_or_jumpable()
              then
                luasnip.expand_or_jump()
              elseif has_words_before() then
                cmp.complete()
              else
                fallback()
              end
            end,
            { "i", "s" }
          ),
          ["<S-Tab>"] = cmp.mapping(
            function(fallback)
              if cmp.visible() then
                cmp.select_prev_item()
              elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
              else
                fallback()
              end
            end,
            { "i", "s" }
          ),
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
        version = "2.*",
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
        }, -- when opening files, do not use windows containing these filetypes or buftypes
        sort_case_insensitive = false, -- used when sorting files and directories in the tree
        sort_function = nil, -- use a custom function for sorting files and directories in the tree
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
            indent_size = 2,
            padding = 1, -- extra padding on left hand side
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
            required_width = 64, -- min width of window required to show this column
          },
          type = {
            enabled = true,
            required_width = 122, -- min width of window required to show this column
          },
          last_modified = {
            enabled = true,
            required_width = 88, -- min width of window required to show this column
          },
          created = {
            enabled = true,
            required_width = 110, -- min width of window required to show this column
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
          width = 30,
          mapping_options = {
            noremap = true,
            nowait = true,
          },
          mappings = {
            ["<space>"] = {
              "toggle_node",
              nowait = false, -- disable `nowait` if you have existing combos starting with this char that you want to use
            },
            ["<2-LeftMouse>"] = "open",
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
            enabled = true, -- This will find and focus the file in the active buffer every time
            --               -- the current file is changed while the tree is open.
            leave_dirs_open = false, -- `false` closes auto expanded dirs, such as with `:Neotree reveal`
          },
          group_empty_dirs = false, -- when true, empty folders will be grouped together
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
            enabled = true, -- This will find and focus the file in the active buffer every time
            --              -- the current file is changed while the tree is open.
            leave_dirs_open = false, -- `false` closes auto expanded dirs, such as with `:Neotree reveal`
          },
          group_empty_dirs = true, -- when true, empty folders will be grouped together
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
                "highlight! Cursor blend=100"
              )
            end,
          },
          {
            event = "neo_tree_buffer_leave",
            handler = function()
              -- Make this whatever your current Cursor highlight group is.
              vim.cmd(
                "highlight! Cursor guibg=#5f87af blend=0"
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
}
