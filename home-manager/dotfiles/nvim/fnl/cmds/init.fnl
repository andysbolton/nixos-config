; highlight on yank
(local highlight-group
       (vim.api.nvim_create_augroup :highlight_on_yank {:clear true}))

(vim.api.nvim_create_autocmd :TextYankPost
                             {:callback (fn [] (vim.highlight.on_yank) nil)
                              :group highlight-group
                              :pattern "*"})

(vim.api.nvim_create_user_command :LspInfo "checkhealth vim.lsp"
                                  {:desc "View LSP info"})

(fn view-lsp-logs []
  (vim.cmd (.. :tabedit (vim.lsp.log.get_filename)))
  (let [bufnr (vim.api.nvim_get_current_buf)
        tabnr (vim.api.nvim_get_current_tabpage)]
    (vim.api.nvim_set_option_value :readonly true {:buf bufnr})
    (vim.keymap.set :n :q (.. "<cmd>bdelete! " bufnr " | tabclose" tabnr tabnr
                              :cr<cr>)
                    {:buffer bufnr
                     :silent true
                     :desc "Close LSP log tab buffer."})))

(vim.api.nvim_create_user_command :LspLog view-lsp-logs
                                  {:desc "View LSP logfile."})

(vim.api.nvim_create_user_command :LspLogClear
                                  #(vim.cmd (.. "!rm "
                                                (vim.lsp.log.get_filename)))
                                  {:desc "Clear LSP logfile."})

; window title gets a ✳ prefix while any terminal buffer runs Claude Code
(fn claude-term? [buf]
  (and (= (. vim.bo buf :buftype) :terminal)
       (>= (vim.fn.match (or (. vim.b buf :term_title) "")
                         "^[✳◐◑◒◓] ") 0)))

(fn update-title []
  (set vim.o.titlestring
       (.. (if (: (vim.iter (vim.api.nvim_list_bufs)) :any claude-term?)
               "✳ "
               "") "nvim " (vim.fn.fnamemodify (vim.fn.getcwd) ":~"))))

(set vim.o.title true)
(vim.api.nvim_create_autocmd [:VimEnter
                              :DirChanged
                              :FocusLost
                              :TermOpen
                              :TermClose]
                             {:callback update-title
                              :group (vim.api.nvim_create_augroup :claude_title
                                                                  {:clear true})})

;; Maybe I'll come back to this. If you do K hover documentation and there's a vim help
;; ref in |bars|, it opens the help page in the floating hover with ctrl-]. You can't go
;; back with ctlr-o in the jumplist though which is annoying, it just closes the floating
;; window.

; (fn help-tag-under-cursor []
;   (let [line (vim.api.nvim_get_current_line)
;         col (+ 1 (. (vim.api.nvim_win_get_cursor 0) 2))]
;     (accumulate [found nil s tag e (line:gmatch "()|([^|%s]+)|()") :until found]
;       (when (and (<= s col) (< col e)) tag))))
;
; (vim.api.nvim_create_autocmd :FileType
;                              {:pattern :markdown
;                               :group (vim.api.nvim_create_augroup :float_help_tags
;                                                                   {:clear true})
;                               :callback (fn [{: buf}]
;                                           (when (= (. vim.bo buf :buftype)
;                                                    :nofile)
;                                             (vim.keymap.set :n "<C-]>"
;                                                             (fn []
;                                                               (case (help-tag-under-cursor)
;                                                                 tag (do
;                                                                       (vim.api.nvim_win_close 0
;                                                                                               true)
;                                                                       (vim.cmd.help tag))))
;                                                             {:buffer buf
;                                                              :desc "Open help for |tag| under cursor"}))
;                                           nil)})
