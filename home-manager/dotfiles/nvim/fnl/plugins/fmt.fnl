(import-macros {: tx} :macros)

;; Formatters are provided by nix (see programs.neovim.extraPackages).
(fn filetype-actions []
  (let [{: get_formatters} (require :configs.util)
        actions {}]
    (each [_ formatter (pairs (get_formatters))]
      (each [_ filetype (pairs (or formatter.filetypes {}))]
        (tset actions filetype formatter.actions)))
    actions))

[(tx :mhartington/formatter.nvim
     {:event :BufWritePre
      :config #(let [{: remove_trailing_whitespace} (require :formatter.filetypes.any)
                     {: register_formatters} (require :cmds.fmt)
                     formatter (require :formatter)
                     actions (filetype-actions)]
                 (set actions.* #(remove_trailing_whitespace))
                 (formatter.setup {:logging true
                                   :log_level vim.log.levels.WARN
                                   :filetype actions})
                 (register_formatters))})]
