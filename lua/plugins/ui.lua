-- Set the virtual_column option to keep cursor column numbers the same
vim.o.virtual_column = "all"
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
  { "voldikss/vim-floaterm" },
  { "tpope/vim-surround" },
  { "terrortylor/nvim-comment" },
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
      require("block").setup({})
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
}
