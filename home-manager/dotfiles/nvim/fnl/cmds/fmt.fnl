(local M {})

(local config_utils (require :configs.util))
(local utils (require :utils))
(local formatters-by-ft {})

(each [_ lang (pairs (config_utils.get_configs))]
  (when lang.formatter
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
      (vim.cmd :FormatWrite) ; always run formatter even even if it's using LSP format so we get default formatters like whitespace removal
      (vim.notify (.. "Formatted " (get-file-name ev.file) " buf (" ev.buf ")."))
      nil)))

; TODO: Replace function name with kebab case once consumer is refactored.
(fn M.register_formatters []
  (let [group (vim.api.nvim_create_augroup :formatting-group {:clear true})]
    (vim.api.nvim_create_autocmd :BufWritePost
                                 {: group :callback buf-write-post-callback})))

M
