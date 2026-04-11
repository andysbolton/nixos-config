local hover = vim.lsp.buf.hover
---@diagnostic disable-next-line: duplicate-set-field
vim.lsp.buf.hover = function()
  return hover {
    max_height = math.floor(vim.o.lines * 0.5),
    max_width = math.floor(vim.o.columns * 0.4),
  }
end

local signature_help = vim.lsp.buf.signature_help
---@diagnostic disable-next-line: duplicate-set-field
vim.lsp.buf.signature_help = function()
  return signature_help {
    max_height = math.floor(vim.o.lines * 0.5),
    max_width = math.floor(vim.o.columns * 0.4),
  }
end

return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      {
        "williamboman/mason-lspconfig.nvim",
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

            nmap("K", vim.lsp.buf.hover, "Hover Documentation")

            nmap("<leader>wra", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
            nmap("<leader>wrr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
            nmap("<leader>wrl", vim.lsp.buf.list_workspace_folders, "[W]orkspace [L]ist Folders")

            if client.supports_method "textDocument/codeAction" then
              vim.keymap.set({ "n", "v" }, "<leader>ca", function()
                if vim.fn.has "win32" == 1 then
                  vim.lsp.buf.code_action()
                else
                  -- This has a dependency on mkfifo at the moment,
                  -- so it can't be used on Windows.
                  require("fzf-lua").lsp_code_actions {
                    winopts = {
                      relative = "cursor",
                      width = 0.6,
                      height = 0.6,
                      row = 1,
                    },
                  }
                end
              end, { buffer = bufnr, desc = "[C]ode [A]ction" })

              require("cmds.lsp").setup_codeactions(bufnr)
            end

            if client.supports_method "textDocument/signatureHelp" then
              nmap("<C-s>", vim.lsp.buf.signature_help, "Signature Help")
            end
          end

          local signs = {
            ERROR = " ",
            WARN = " ",
            HINT = " ",
            INFO = " ",
          }

          for type, icon in pairs(signs) do
            local hl = "DiagnosticSign" .. type:sub(1, 1) .. type:sub(2):lower()
            vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
          end

          vim.diagnostic.config {
            virtual_text = {
              prefix = "",
              format = function(diagnostic)
                return signs[vim.diagnostic.severity[diagnostic.severity]:upper()] .. diagnostic.message
              end,
            },
            -- Is this doing anything?
            virtual_lines = {
              prefix = "",
              format = function(diagnostic)
                return signs[vim.diagnostic.severity[diagnostic.severity]:upper()] .. diagnostic.message
              end,
            },
            float = {
              border = "rounded",
              source = "if_many",
              -- Show severity icons as prefixes.
              prefix = function(diag)
                local level = vim.diagnostic.severity[diag.severity]:upper()
                local prefix = string.format(" %s ", signs[level])
                return prefix, "Diagnostic" .. level:gsub("^%l", string.upper)
              end,
            },
          }

          local capabilities = vim.lsp.protocol.make_client_capabilities()
          -- nvim-cmp supports additional completion capabilities, so broadcast that to servers
          capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

          local mason_lspconfig = require "mason-lspconfig"
          local language_servers = require("configs.util").get_language_servers()

          local language_servers_to_install = {}

          for _, ls in pairs(language_servers) do
            vim.lsp.enable(ls.name)
            vim.lsp.config(ls.name, {
              settings = ls.settings,
            })
            if ls.auto_install ~= false then table.insert(language_servers_to_install, ls.name) end
          end

          -- table.insert(language_servers_to_install, "efm")
          mason_lspconfig.setup {
            ensure_installed = language_servers_to_install,
          }
          vim.lsp.config("*", {
            capabilities = capabilities,
            on_attach = on_attach,
          })

          if vim.fn.has "win32" == 1 then
            local ahk2_config = {
              autostart = true,
              cmd = {
                "node",
                vim.fn.expand "$HOME/vscode-autohotkey2-lsp/server/dist/server.js",
                "--stdio",
              },
              filetypes = { "ahk", "autohotkey", "ah2" },
              init_options = {
                locale = "en-us",
                InterpreterPath = vim.fn.expand "$HOME/scoop/shims/autohotkey.exe",
              },
              single_file_support = true,
              flags = { debounce_text_changes = 500 },
              capabilities = capabilities,
              on_attach = on_attach,
            }
            local configs = require "lspconfig.configs"
            configs["ahk2"] = { default_config = ahk2_config }
            require("lspconfig").ahk2.setup {}
          end

          require("lspkind").init {
            mode = "symbol_text",
            preset = "codicons",
            symbol_map = {
              Text = "󰉿",
              Method = "󰆧",
              Function = "󰊕",
              Constructor = "",
              Field = "󰜢",
              Variable = "󰀫",
              Class = "󰠱",
              Interface = "",
              Module = "",
              Property = "󰜢",
              Unit = "󰑭",
              Value = "󰎠",
              Enum = "",
              Keyword = "󰌋",
              Snippet = "",
              Color = "󰏘",
              File = "󰈙",
              Reference = "󰈇",
              Folder = "󰉋",
              EnumMember = "",
              Constant = "󰏿",
              Struct = "󰙅",
              Event = "",
              Operator = "󰆕",
              TypeParameter = "",
            },
          }
        end,
      },

      -- Useful status updates for LSP
      {
        "j-hui/fidget.nvim",
        tag = "legacy",
        config = true,
      },

      {
        "folke/neodev.nvim",
        config = true,
      },

      "onsails/lspkind.nvim",
    },
  },
}
