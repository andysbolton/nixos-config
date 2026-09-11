return {
  name = "csharp",
  ft = { "cs" },
  ls = {
    name = "omnisharp",
    settings = {
      omnisharp = {
        RoslynExtensionsOptions = {
          AnalyzeOpenDocumentsOnly = true,
        },
      },
    },
    handlers = {
      ["textDocument/publishDiagnostics"] = function(err, result, ctx)
        if result and result.uri then
          local fname = vim.uri_to_fname(result.uri)
          if vim.fn.bufexists(fname) == 0 then
            local real = vim.uv.fs_realpath(fname)
            local open = false
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
              local name = vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_name(buf)
              if name and name ~= "" and real and vim.uv.fs_realpath(name) == real then
                open = true
                break
              end
            end
            if not open then return end
          end
        end
        return vim.lsp.handlers["textDocument/publishDiagnostics"](err, result, ctx)
      end,
    },
  },
  treesitter = "c_sharp",
  formatter = {
    name = "csharpier",
    action = function()
      local util = require "formatter.util"
      return {
        exe = "dotnet",
        args = { "csharpier", util.escape_path(util.get_current_buffer_file_name()) },
        stdin = true,
      }
    end,
  },
}
