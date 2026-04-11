(local M {})

(local config_utils (require :configs.util))
(local utils (require :utils))
(local formatters-by-ft {})

(each [_ lang (pairs (config_utils.get_configs))]
  (when (and lang.formatter (not (= lang.autoinstall false)))
    (if (or (utils.empty lang.ft) (= #lang.ft 0))
        (vim.notify (.. "No filetypes specified for " lang.name ".")
                    vim.log.levels.WARN)
        (each [_ ft (pairs lang.ft)]
          (tset formatters-by-ft ft lang.formatter)))))

(fn get-file-name [path]
  (let [matches (icollect [seg (string.gmatch path "([^/\\]+)")]
                  seg)]
    (. matches (length matches))))

(fn buf-write-post-callback [ev]
  (let [formatter (. formatters-by-ft vim.bo.filetype)]
    (when formatter
      (if formatter.use_lsp
          (vim.lsp.buf.format)
          (vim.cmd :FormatWrite))
      (vim.notify (.. "Formatted " (get-file-name ev.file) " with "
                      (or formatter.name "[couldn't find formatter name]")
                      (or (and formatter.use_lsp " (LSP)") "") " (buf " ev.buf
                      ")."))
      nil)))

; TODO: Replace function name with kebab case once consumer is refactored.
(fn M.register_formatters []
  (let [group (vim.api.nvim_create_augroup :formatting-group {:clear true})]
    (vim.api.nvim_create_autocmd :BufWritePost
                                 {: group :callback buf-write-post-callback})))

M
