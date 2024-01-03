-- Set the virtual_column option to keep cursor column numbers the same
vim.o.virtual_column = "all"

return {
  { "alvan/vim-closetag" },
  { "windwp/nvim-autopairs" },
  { "nvim-lua/plenary.nvim" },
  { "tveskag/nvim-blame-line" },

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

  {
    'numToStr/Comment.nvim',
    config = function()
        require('Comment').setup()
    end
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
    enabled = true,
    event = "BufEnter",
    dependencies = {
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
    opts = {
      options = {
        diagnostics = "nvim_lsp",
        truncate_names = true, -- whether or not tab names should be truncated
        mode = "buffers", -- set to "tabs" to only show tabpages instead
        -- style_preset = bufferline.style_preset.minimal, -- or bufferline.style_preset.minimal,
        themable = true, -- allows highlight groups to be overriden i.e. sets highlights as default
        close_command = "bdelete! %d", -- can be a string | function, | false see "Mouse actions"
        right_mouse_command = "bdelete! %d", -- can be a string | function | false, see "Mouse actions"
        left_mouse_command = "buffer %d", -- can be a string | function, | false see "Mouse actions"
        middle_mouse_command = nil, -- can be a string | function, | false see "Mouse actions"
        indicator = {
          icon = "▎", -- this should be omitted if indicator style is not 'icon'
          style = "icon",
        },
        offsets = {
          {
            filetype = "NvimTree",
            text = "File Explorer",
            text_align = "left",
            separator = true,
          },
        },
        get_element_icon = function(element)
          -- element consists of {filetype: string, path: string, extension: string, directory: string}
          -- This can be used to change how bufferline fetches the icon
          -- for an element e.g. a buffer or a tab.
          -- e.g.
          local icon, hl = require(
            "nvim-web-devicons"
          ).get_icon_by_filetype(
            element.filetype,
            { default = false }
          )
          return icon, hl
          -- -- or
          -- local custom_map = {my_thing_ft: {icon = "my_thing_icon", hl}}
          -- return custom_map[element.filetype]
        end,
        show_buffer_icons = true, -- disable filetype icons for buffers
        show_buffer_close_icons = true,
        show_close_icon = true,
        show_tab_indicators = true,
        show_duplicate_prefix = true, -- whether to show duplicate buffer prefix
        persist_buffer_sort = true, -- whether or not custom sorted buffers should persist
        move_wraps_at_ends = false, -- whether or not the move command "wraps" at the first or last position
        -- can also be a table containing 2 custom separators
        -- [focused and unfocused]. eg: { '|', '|' }
        separator_style = "line",
        enforce_regular_tabs = true,
        always_show_bufferline = true,
        buffer_close_icon = "󰅖",
        modified_icon = "●",
        close_icon = "",
        left_trunc_marker = "",
        right_trunc_marker = "",
        color_icons = true, -- whether or not to add the filetype icon highlights
        hover = {
          enabled = true,
          delay = 200,
          reveal = { "close" },
        },
      },
    },
  },

  -- { "justinmk/vim-sneak" },

  -- statusline
  {
    "nvim-lualine/lualine.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    -- event = "VeryLazy",
    -- opts = function(_, opts)
    --   table.insert(opts.sections.lualine_x, "😄")
    -- end,
    config = function()
      -- local lualine = require("lualine")
      local lazy_status = require("lazy.status") -- to configure lazy pending updates count
      -- Bubbles config for lualine
      -- Author: lokesh-krishna
      -- MIT license, see LICENSE for more details.

      -- stylua: ignore
      local colors = {
        blue   = '#007dff',
        cyan   = '#79dac8',
        black  = '##1d1d1d',
        white  = '#c6c6c6',
        red    = '#ff5189',
        violet = '#d183e8',
        darkGrey = '#0a0a0a',
        green  = '#03e20a'
      }

      local bubbles_theme = {
        normal = {
          a = {
            fg = colors.black,
            bg = colors.blue,
          },
          b = {
            fg = colors.white,
            bg = colors.darkGrey,
          },
          c = {
            fg = colors.black,
            bg = colors.black,
          },
        },

        insert = {
          a = {
            fg = colors.black,
            bg = colors.green,
          },
        },
        visual = {
          a = {
            fg = colors.black,
            bg = colors.cyan,
          },
        },
        replace = {
          a = {
            fg = colors.black,
            bg = colors.red,
          },
        },

        inactive = {
          a = {
            fg = colors.white,
            bg = colors.black,
          },
          b = {
            fg = colors.white,
            bg = colors.black,
          },
          c = {
            fg = colors.black,
            bg = colors.black,
          },
        },
      }

      require("lualine").setup({
        options = {
          theme = bubbles_theme,
          component_separators = "|",
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
          lualine_b = { "filename", "branch" },
          lualine_c = { "fileformat" },
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
    end,
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

  -- add symbols-outline
  {
    "simrat39/symbols-outline.nvim",
    cmd = "SymbolsOutline",
    keys = {
      {
        "<leader>cs",
        "<cmd>SymbolsOutline<cr>",
        desc = "Symbols Outline",
      },
    },
    config = true,
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
