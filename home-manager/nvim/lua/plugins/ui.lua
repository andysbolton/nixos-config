return {
  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      vim.keymap.set("n", "<leader><tab>", ":BufferLineCycleNext<cr>", { desc = "Cycle to next tab", silent = true })
      vim.keymap.set(
        "n",
        "<leader><s-tab>",
        ":BufferLineCyclePrev<cr>",
        { desc = "Cycle to previous tab", silent = true }
      )
      vim.keymap.set(
        "n",
        "<leader>bd",
        ":bp<bar>sp<bar>bn<bar>bd!<CR>",
        { desc = "Delete current buffer", silent = true }
      )
      vim.keymap.set(
        "n",
        "<leader>bdr",
        ":BufferLineCloseRight<cr>",
        { desc = "Delete buffers to the right", silent = true }
      )
      vim.keymap.set(
        "n",
        "<leader>bdl",
        ":BufferLineCloseLeft<cr>",
        { desc = "Delete buffers to the left", silent = true }
      )
      vim.keymap.set("n", "<leader>bdo", ":BufferLineCloseOthers<cr>", { desc = "Delete other buffers", silent = true })

      for i = 1, 15 do
        vim.keymap.set(
          "n",
          "<leader>bs" .. i,
          ":BufferLineGoToBuffer " .. i .. "<cr>",
          { desc = "[B]uffer: [s]et " .. i }
        )
        vim.keymap.set("n", "<leader>bd" .. i, function()
          for _, buf in pairs(require("bufferline.buffers").get_components(require "bufferline.state")) do
            if buf.ordinal == i then vim.cmd("bd! " .. buf.id) end
          end
        end, { desc = "[B]uffer: [d]elete " .. i })
      end

      require("bufferline").setup {
        options = {
          separator_style = "slant",
          buffer_close_icon = "✕",
          indicator = {
            icon = "",
          },
          offsets = {
            {
              filetype = "neo-tree",
            },
          },
          ---@diagnostic disable-next-line: undefined-field
          numbers = function(opts) return string.format("%s.%s", opts.ordinal, opts.lower(opts.id)) end,
        },
      }
    end,
  },

  {
    "utilyre/barbecue.nvim",
    name = "barbecue",
    version = "*",
    dependencies = {
      "SmiteshP/nvim-navic",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      theme = "tokyonight-storm",
    },
  },

  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function() vim.cmd [[colorscheme tokyonight-storm]] end,
  },

  {
    "nvim-lualine/lualine.nvim",
    config = function()
      require("lualine").setup {
        options = {
          icons_enabled = true,
          theme = "tokyonight-storm",
          disabled_filetypes = { "neo-tree" },
        },
        extensions = { "lazy" },
        sections = {
          lualine_c = {
            {
              "filename",
              cond = function() return vim.bo.buftype ~= "terminal" end,
            },
          },
        },
      }
    end,
  },

  {
    -- Add indentation guides even on blank lines
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {
      indent = { char = "┊" },
    },
  },

  {
    "goolord/alpha-nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function() require("alpha").setup(require("alpha.themes.startify").config) end,
  },

  {
    "rcarriga/nvim-notify",
    config = function()
      require("notify").setup {
        stages = "fade_in_slide_out",
        timeout = 3000,
        icons = {
          ERROR = "",
          WARN = "",
          INFO = "",
          DEBUG = "",
          TRACE = "✎",
        },
        render = "wrapped-default",
      }
      vim.notify = require "notify"
    end,
  },

  {
    "mrjones2014/smart-splits.nvim",
    keys = {
      {
        "<A-h>",
        function() require("smart-splits").resize_left() end,
        mode = { "n", "t" },
      },
      {
        "<A-l>",
        function() require("smart-splits").resize_right() end,
        mode = { "n", "t" },
      },
      {
        "<A-k>",
        function() require("smart-splits").resize_up() end,
        mode = { "n", "t" },
      },
      {
        "<A-j>",
        function() require("smart-splits").resize_down() end,
        mode = { "n", "t" },
      },
      {
        "<leader>swh",
        function() require("smart-splits").swap_buf_left() end,
        mode = { "n", "t" },
        desc = "[S][w]ap buffer left",
      },
      {
        "<leader>swj",
        function() require("smart-splits").swap_buf_down() end,
        mode = { "n", "t" },
        desc = "[S][w]ap buffer down",
      },
      {
        "<leader>swk",
        function() require("smart-splits").swap_buf_up() end,
        mode = { "n", "t" },
        desc = "[S][w]ap buffer up",
      },
      {
        "<leader>swl",
        function() require("smart-splits").swap_buf_right() end,
        mode = { "n", "t" },
        desc = "[S][w]ap buffer right",
      },
      {
        "<C-h>",
        function() require("smart-splits").move_cursor_left() end,
        mode = { "n", "t" },
      },
      {
        "<C-j>",
        function() require("smart-splits").move_cursor_down() end,
        mode = { "n", "t" },
      },
      {
        "<C-k>",
        function() require("smart-splits").move_cursor_up() end,
        mode = { "n", "t" },
      },
      {
        "<C-l>",
        function() require("smart-splits").move_cursor_right() end,
        mode = { "n", "t" },
      },
    },
  },
}
