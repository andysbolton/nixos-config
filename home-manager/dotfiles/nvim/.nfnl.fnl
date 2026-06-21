{:source-dirs [:fnl]
 :out-dir :lua
 ;; Only compile under fnl/ so root-level files (e.g. flsproject.fnl, which
 ;; fennel-ls reads directly) aren't compiled to stray .lua artifacts.
 :source-file-patterns [:fnl/*.fnl :fnl/**/*.fnl]
 :verbose true}
