-- Claim-on-save for workspace farms; the module loads lazily on first save
-- of a farm-path buffer.
vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("workspaces_claim", { clear = true }),
  pattern = "*/.workspaces/*",
  callback = function(ev) require("workspaces").claim_on_save(ev.buf) end,
})
