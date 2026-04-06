(fn tx [& args]
  "Mixed sequential and associative tables at compile time."
  (let [to-merge (when (table? (. args (length args)))
                   (table.remove args))]
    (if to-merge
        (do
          (each [key value (pairs to-merge)]
            (tset args key value))
          args)
        args)))

{: tx}
