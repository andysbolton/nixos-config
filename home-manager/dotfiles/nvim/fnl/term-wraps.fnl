;; Joins soft-wrapped terminal rows on yank, using the command output that
;; fish delimits with OSC 133 C/D marks to tell soft wraps from real newlines.
(local M {})

(local max-outputs 50)
(local max-bytes 200000)
(local states {})

(fn clean [s]
  (pick-values 1 (-> s
                     (: :gsub "\027%][^\a\027]*\a" "")
                     (: :gsub "\027%][^\a\027]*\027\\" "")
                     (: :gsub "\027[P_%^X][^\027]*\027\\" "")
                     (: :gsub "\027%[[0-?]*[ -/]*[@-~]" "")
                     (: :gsub "\027[%(%)]%w" "")
                     (: :gsub "\027." "")
                     (: :gsub "\r\n" "\n")
                     ;; \r returns to column 0; keep only what was written last
                     (: :gsub "[^\n]*\r" ""))))

(fn feed [st chunk]
  (set st.raw (.. st.raw chunk))
  (var more true)
  (while more
    (if st.in-output
        (let [d (st.raw:find "\027]133;D" 1 true)]
          (if d
              (do
                (table.insert st.outputs (clean (st.raw:sub 1 (- d 1))))
                (when (> (length st.outputs) max-outputs)
                  (table.remove st.outputs 1))
                (set st.raw (st.raw:sub (+ d 1)))
                (set st.in-output false))
              (do
                (when (> (length st.raw) max-bytes)
                  (set st.raw (st.raw:sub (- max-bytes))))
                (set more false))))
        (let [c (st.raw:find "\027]133;C" 1 true)
              (_ e) (when c (st.raw:find "\a" c true))]
          (if e
              (do
                (set st.raw (st.raw:sub (+ e 1)))
                (set st.in-output true))
              (do
                (set st.raw (if c (st.raw:sub c) (st.raw:sub -16)))
                (set more false)))))))

(fn M.on_stdout [term _job data]
  (let [st (or (. states term.bufnr) {:raw "" :outputs [] :in-output false})]
    (tset states term.bufnr st)
    (feed st (table.concat data "\n"))))

(fn newest-first [st]
  (let [outs (if st.in-output [(clean st.raw)] [])]
    (for [i (length st.outputs) 1 -1]
      (table.insert outs (. st.outputs i)))
    outs))

(fn wrapped? [outs row nxt]
  (and (not= nxt "") (accumulate [res nil _ out (ipairs outs)
                                  :until (not= res nil)]
                       (if (out:find (.. row nxt) 1 true) true
                           (out:find (.. row "\n") 1 true) false
                           nil))))

(fn join-wraps []
  (let [ev vim.v.event
        st (. states (vim.api.nvim_get_current_buf))]
    (when (and st (= vim.bo.buftype :terminal) (= ev.operator :y)
               (not= (ev.regtype:sub 1 1) "\022"))
      (let [info (. (vim.fn.getwininfo (vim.api.nvim_get_current_win)) 1)
            cols (- info.width info.textoff)
            outs (newest-first st)
            start (vim.fn.line "'[")
            out [(. ev.regcontents 1)]]
        (for [i 2 (length ev.regcontents)]
          (let [row (vim.fn.getline (+ start i -2))
                nxt (vim.fn.getline (+ start i -1))]
            ;; a wide char that doesn't fit wraps one column early
            (if (and (>= (vim.fn.strdisplaywidth row) (- cols 1))
                     (wrapped? outs row nxt))
                (tset out (length out)
                      (.. (. out (length out)) (. ev.regcontents i)))
                (table.insert out (. ev.regcontents i)))))
        (vim.fn.setreg ev.regname out ev.regtype)
        (when (and (= ev.regname "") (vim.o.clipboard:find :unnamedplus))
          (vim.fn.setreg "+" out ev.regtype)))))
  nil)

(vim.api.nvim_create_autocmd :TextYankPost
                             {:callback join-wraps
                              :group (vim.api.nvim_create_augroup :term_wraps
                                                                  {:clear true})})

(vim.api.nvim_create_autocmd :BufWipeout
                             {:callback #(tset states $1.buf nil)
                              :group :term_wraps})

M
