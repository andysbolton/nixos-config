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
       (>= (vim.fn.match (or (. vim.b buf :term_title) "") "^[✳◐◑◒◓] ") 0)))

(fn update-title []
  (set vim.o.titlestring
       (.. (if (: (vim.iter (vim.api.nvim_list_bufs)) :any claude-term?) "✳ " "")
           "nvim " (vim.fn.fnamemodify (vim.fn.getcwd) ":~"))))

(set vim.o.title true)
(vim.api.nvim_create_autocmd [:VimEnter :DirChanged :FocusLost :TermOpen :TermClose]
                             {:callback update-title
                              :group (vim.api.nvim_create_augroup :claude_title
                                                                  {:clear true})})
