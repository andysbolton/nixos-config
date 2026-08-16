{:source-dirs [:fnl]
 :out-dir :lua
 ;; Compile init.fnl and fnl/** only, so other root-level files (e.g.
 ;; flsproject.fnl, which fennel-ls reads directly) aren't compiled to
 ;; stray .lua artifacts.
 :source-file-patterns [:init.fnl :fnl/*.fnl :fnl/**/*.fnl]
 :verbose true}
