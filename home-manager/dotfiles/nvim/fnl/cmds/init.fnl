(local highlight-group
       (vim.api.nvim_create_augroup :highlight_on_yank {:clear true}))

(vim.api.nvim_create_autocmd :TextYankPost
                             {:callback (fn [] (vim.highlight.on_yank) nil)
                              :group highlight-group
                              :pattern "*"})
