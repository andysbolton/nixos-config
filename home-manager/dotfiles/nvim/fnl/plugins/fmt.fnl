(import-macros {: tx} :macros)

;; Formatters are provided by nix (see programs.neovim.extraPackages).
(local formatters (let [{: get_formatters} (require :configs.util)]
                    (get_formatters)))

(local filetype-actions (let [filetype-actions {}]
                          (each [_ formatter (pairs formatters)]
                            (each [_ filetype (pairs (or formatter.filetypes {}))]
                              (tset filetype-actions filetype formatter.actions)))
                          filetype-actions))

[(tx :mhartington/formatter.nvim
     {:config #(let [{: remove_trailing_whitespace} (require :formatter.filetypes.any)
                     {: register_formatters} (require :cmds.fmt)
                     formatter (require :formatter)]
                 (set filetype-actions.* #(remove_trailing_whitespace))
                 (formatter.setup {:logging true
                                   :log_level vim.log.levels.WARN
                                   :filetype filetype-actions})
                 (register_formatters))})]
