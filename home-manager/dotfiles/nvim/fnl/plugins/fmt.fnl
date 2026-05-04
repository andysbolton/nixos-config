(import-macros {: tx} :macros)

(local formatters (let [{: get_formatters} (require :configs.util)]
                    (get_formatters)))

(local (formatter-names filetype-actions)
       (let [formatter-names {}
             filetype-actions {}]
         (each [_ formatter (pairs formatters)]
           (when (and formatter.name
                      (not= formatter.autoinstall false))
             (table.insert formatter-names formatter.name))
           (each [_ filetype (pairs (or formatter.filetypes {}))]
             (tset filetype-actions filetype formatter.actions)))
         (values formatter-names filetype-actions)))

[(tx :mhartington/formatter.nvim
     {:dependencies [:williamboman/mason.nvim
                     :WhoIsSethDaniel/mason-tool-installer.nvim]
      :config #(let [mason-tool-installer (require :mason-tool-installer)
                     {: remove_trailing_whitespace} (require :formatter.filetypes.any)
                     {: register_formatters} (require :cmds.fmt)
                     formatter (require :formatter)]
                 (mason-tool-installer.setup {:ensure_installed [(table.unpack formatter-names)]})
                 (set filetype-actions.* #(remove_trailing_whitespace))
                 (formatter.setup {:logging true
                                   :log_level vim.log.levels.WARN
                                   :filetype filetype-actions})
                 (register_formatters))})]
