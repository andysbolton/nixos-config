(local M {})

(local utils (require :utils))

; tables for caching
(local language-servers {})
(local formatters {})
(local linters {})
(local treesitters {})

; TODO: Replace function name with kebab case once consumer is refactored.
(fn M.get_configs [] (require :configs))

(fn M.get_language_servers []
  (when (utils.empty language-servers)
    (each [_ lang (pairs (M.get_configs))]
      (when lang.ls
        (tset language-servers lang.ls.name lang.ls))))
  language-servers)

(fn M.get_formatters []
  (when (utils.empty formatters)
    (each [_ lang (pairs (M.get_configs))]
      (when lang.formatter
        (let [formatter lang.formatter]
          (set formatter.filetypes lang.ft)
          (table.insert formatters formatter)))))
  formatters)

(fn M.get_linters []
  (when (utils.empty linters)
    (each [_ lang (pairs (M.get_configs))]
      (when lang.linter
        (let [linter lang.linter]
          (set linter.filetypes lang.ft)
          (table.insert linters linter)))))
  linters)

(fn M.get_treesitters []
  (when (utils.empty treesitters)
    (each [_ lang (pairs (M.get_configs))]
      (when lang.treesitter
        (table.insert treesitters lang.treesitter))))
  treesitters)

M
