(local M {})

(fn M.empty? [table]
  (or (= nil table) (= nil (next table))))

(local debug-log (.. (vim.fn.stdpath :data) :/debug.txt))
(fn M.log [...]
  (let [n (select "#" ...)
        parts {}]
    (for [i 1 n]
      (let [a (select i ...)]
        (tset parts i (if (= (type a) :table) (vim.inspect a) (tostring a)))))
    (with-open [f (io.open debug-log :a)]
      (f:write (.. (os.date "%H:%M:%S ") (table.concat parts " ") "\n")))))

(fn M.any? [pred list]
  (accumulate [found? false _ x (ipairs list) :until found?]
    (pred x)))

(fn M.tail [list]
  (. list (length list)))

(fn M.head [list] (. list 1))

(fn M.group-by [key-fn coll]
  (accumulate [acc {} _ item (ipairs coll)]
    (let [k (key-fn item)]
      (when (= nil (. acc k))
        (tset acc k []))
      (table.insert (. acc k) item)
      acc)))

(fn M.debounce [ms f]
  (let [timer (vim.uv.new_timer)]
    (fn []
      (timer:stop)
      (timer:start ms 0 (vim.schedule_wrap f))
      nil)))

(vim.api.nvim_create_user_command :DebugLogView
                                  #(vim.cmd (.. "vsp " debug-log))
                                  {:desc "View debug log."})

(vim.api.nvim_create_user_command :DebugLogClear
                                  #(vim.cmd (.. "!rm -f " debug-log))
                                  {:desc "View debug log."})

M
