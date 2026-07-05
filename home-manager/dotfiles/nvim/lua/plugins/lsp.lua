vim.api.nvim_create_user_command("LspRestart", function()
  for _, c in ipairs(vim.lsp.get_clients()) do
    c:stop(true)
  end
  vim.cmd.edit()
end, { desc = "Stop all LSP clients and reattach to the current buffer" })

-- Evaluate lua code -- move me to fennel!
local function eval(code)
  local chunk, err = load("return " .. code) -- try as an expression
  if not chunk then
    chunk, err = load(code)
  end -- fall back to a statement
  if not chunk then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end
  local ok, res = pcall(chunk)
  vim.notify(ok and vim.inspect(res) or tostring(res), ok and vim.log.levels.INFO or vim.log.levels.ERROR)
end

vim.keymap.set("n", "<leader>x", function() eval(vim.api.nvim_get_current_line()) end, { desc = "Eval line as Lua" })

vim.keymap.set("x", "<leader>x", function()
  local s, e = vim.fn.getpos("v")[2], vim.fn.getpos(".")[2]
  if s > e then
    s, e = e, s
  end
  eval(table.concat(vim.api.nvim_buf_get_lines(0, s - 1, e, false), "\n"))
end, { desc = "Eval selection as Lua" })

return {
  -- Disabled: refactor/other code actions are now indicated by cmds.lsp's cursor sign
  -- (wrench at eol + gutter bulb), quickfixes by its viewport sign. Restore to get the
  -- bulb back (and code-lens re-skinning, which it only does atop an action anyway).
  --[[
  {
    "kosayoda/nvim-lightbulb",
    config = function()
      require("nvim-lightbulb").setup {
        autocmd = { enabled = true },
        priority = 15,
        code_lenses = true,
        filter = function(_, result)
          -- quickfixes handled for current viewport by require("cmds.lsp").setup_codeactions
          if result.kind == "quickfix" then return false end
          -- lua parameter swap
          if vim.startswith(result.title, "Change to parameter") then return false end
          return true
        end,
      }
    end,
  },
  --]]
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      -- Useful status updates for LSP
      {
        "j-hui/fidget.nvim",
        tag = "legacy",
        config = true,
      },

      "onsails/lspkind.nvim",
    },
    config = function()
      local on_attach = function(client, bufnr)
        local nmap = function(keys, func, desc)
          if desc then desc = "LSP: " .. desc end

          vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
        end

        nmap("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")

        nmap("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
        nmap("gD", vim.lsp.buf.definition, "[G]oto [D]eclaration")
        nmap("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
        nmap("gI", vim.lsp.buf.implementation, "[G]oto [I]mplementation")

        nmap("<leader>D", vim.lsp.buf.type_definition, "Type [D]efinition")
        nmap("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
        nmap("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")

        nmap(
          "K",
          function()
            vim.lsp.buf.hover {
              max_height = math.floor(vim.o.lines * 0.5),
              max_width = math.floor(vim.o.columns * 0.4),
            }
          end,
          "Hover Documentation"
        )

        nmap("<leader>wra", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
        nmap("<leader>wrr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
        nmap("<leader>wrl", vim.lsp.buf.list_workspace_folders, "[W]orkspace [L]ist Folders")

        if client.supports_method "textDocument/codeAction" then
          nmap("<leader>ca", require("cmds.lsp").code_action, "[C]ode [A]ction")

          -- visual mode: use the selection (builtin default)
          vim.keymap.set("v", "<leader>ca", vim.lsp.buf.code_action, { buffer = bufnr, desc = "[C]ode [A]ction" })

          require("cmds.lsp").setup_codeactions(bufnr)
        end

        if client.supports_method "textDocument/signatureHelp" then
          nmap(
            "<C-s>",
            function()
              vim.lsp.buf.signature_help {
                max_height = math.floor(vim.o.lines * 0.5),
                max_width = math.floor(vim.o.columns * 0.4),
              }
            end,
            "Signature Help"
          )
        end
      end

      local signs = {
        [vim.diagnostic.severity.ERROR] = " ",
        [vim.diagnostic.severity.WARN] = " ",
        [vim.diagnostic.severity.INFO] = " ",
        [vim.diagnostic.severity.HINT] = " ",
      }

      vim.diagnostic.config {
        virtual_lines = {
          format = function(diagnostic) return signs[diagnostic.severity] .. diagnostic.message end,
        },
        signs = { text = signs },
        float = {
          border = "rounded",
          source = "if_many",
          -- Show severity icons as prefixes.
          prefix = function(diagnostic)
            local severity = vim.diagnostic.severity[diagnostic.severity]
            return signs[diagnostic.severity],
              "Diagnostic" .. severity:gsub("(%u)(%u+)", function(first, rest) return first .. string.lower(rest) end)
          end,
        },
      }

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      -- nvim-cmp supports additional completion capabilities, so broadcast that to servers
      capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

      -- Language servers are provided by nix (see programs.neovim.extraPackages),
      -- so we just configure and enable them here.
      local language_servers = require("configs.util").get_language_servers()

      for _, ls in pairs(language_servers) do
        local config = {
          settings = ls.settings,
        }

        if ls.on_init then config.on_init = ls.on_init end

        vim.lsp.config(ls.name, config)
        vim.lsp.enable(ls.name)
      end

      vim.lsp.config("*", {
        capabilities = capabilities,
        on_attach = on_attach,
      })

      require("lspkind").init {
        mode = "symbol_text",
        preset = "codicons",
        symbol_map = {
          Text = "󰉿",
          Method = "󰆧",
          Function = "󰊕",
          Constructor = "",
          Field = "󰜢",
          Variable = "󰀫",
          Class = "󰠱",
          Interface = "",
          Module = "",
          Property = "󰜢",
          Unit = "󰑭",
          Value = "󰎠",
          Enum = "",
          Keyword = "󰌋",
          Snippet = "",
          Color = "󰏘",
          File = "󰈙",
          Reference = "󰈇",
          Folder = "󰉋",
          EnumMember = "",
          Constant = "󰏿",
          Struct = "󰙅",
          Event = "",
          Operator = "󰆕",
          TypeParameter = "",
        },
      }
    end,
  },

  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {},
  },

  {
    "jmbuhr/otter.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {},
    config = function(_, opts)
      require("otter").setup(opts)

      local preambles = { bash = { "# shellcheck shell=bash", "# shellcheck disable=SC2215" } }

      -- vim.api.nvim_create_autocmd("FileType", {
      --   pattern = "nix",
      --   group = vim.api.nvim_create_augroup("otter_nix", { clear = true }),
      --   callback = function() require("otter").activate(nil, nil, true, nil, preambles) end,
      -- })
    end,
  },
}
