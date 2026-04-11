(local M {})

(fn M.empty [table]
  (or (= nil table) (= nil (next table))))

M
