(local M {})

(fn get-file-name [path]
  (let [matches (icollect [seg (string.gmatch path "([^/\\]+)")]
                  seg)]
    (. matches (length matches))))

(fn buf-write-post-callback [ev]
  (vim.cmd :FormatWrite)
  (vim.notify (.. "Formatted " (get-file-name ev.file) " buf (" ev.buf ")."))
  nil)

; TODO: Replace function name with kebab case once consumer is refactored.
(fn M.register_formatters []
  (let [group (vim.api.nvim_create_augroup :formatting-group {:clear true})]
    (vim.api.nvim_create_autocmd :BufWritePost
                                 {: group :callback buf-write-post-callback})))

M
