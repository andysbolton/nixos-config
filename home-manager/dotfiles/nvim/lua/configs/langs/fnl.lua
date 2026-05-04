vim.filetype.add({
  extension = {
    fnlm = "fennel",
  },
})

return {
  name = "fennel",
  ft = { "fennel" },
  ls = {
    name = "fennel_ls",
    settings = {},
    on_init = function(client)
      -- fennel-ls crashes when it receives a documentSymbol request for a
      -- non-existent file (e.g. neo-tree buffers).
      local orig_request = client.rpc.request
      client.rpc.request = function(method, params, ...)
        if method == "textDocument/documentSymbol" then
          local uri = params and params.textDocument and params.textDocument.uri or ""
          local path = vim.uri_to_fname(uri)
          if not vim.uv.fs_stat(path) then return end
        end
        return orig_request(method, params, ...)
      end
    end,
    autoinstall = false,
  },
  formatter = {
    name = "fnlfmt",
    actions = {
      function()
        return {
          exe = "fnlfmt",
          args = { "--fix" },
          stdin = false,
        }
      end,
    },
    autoinstall = false,
  },
  treesitter = "fennel",
}
