(local M {})

(fn M.empty [table]
  (or (= nil table) (= nil (next table))))

(local debug-log (.. (vim.fn.stdpath :data) :/debug.txt))
(fn M.log [...]
  (let [n (select "#" ...)
        parts {}]
    (for [i 1 n]
      (tset parts i (vim.inspect (select i ...))))
    (with-open [f (io.open debug-log :a)]
      (f:write (.. (os.date "%H:%M:%S ") (table.concat parts " ") "\n")))))

(vim.api.nvim_create_user_command :ViewDebugLog
                                  (fn [] (vim.cmd (.. "vsp " debug-log)))
                                  {:desc "View debug log."})

M
