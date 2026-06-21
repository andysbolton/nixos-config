(local M {})

(local {: nvim_buf_clear_namespace
        : nvim_buf_get_lines
        : nvim_buf_is_valid
        : nvim_buf_set_extmark
        : nvim_create_augroup
        : nvim_create_autocmd
        : nvim_create_namespace} vim.api)

(local ns (nvim_create_namespace :code_action_sign))

(fn M.line_diagnostics [bufnr row]
  (vim.lsp.diagnostic.from (vim.diagnostic.get bufnr {:lnum (- row 1)})))

(fn action-lines [actions buf-uri]
  (let [seen {}
        lines []
        add (fn [range]
              (let [line (?. range :start :line)]
                (when (and line (not (. seen line)))
                  (table.insert lines line)
                  (tset seen line true))))]
    (each [_ a (ipairs actions)]
      (when (= (?. a :kind) :quickfix)
        (let [diagnostics (or (?. a :diagnostics) [])]
          (if (> (length diagnostics) 0)
              (each [_ d (ipairs diagnostics)]
                (add (. d :range)))
              (let [edit (?. a :edit)]
                (when edit
                  (each [_ te (ipairs (or (?. edit :changes buf-uri) []))]
                    (add (. te :range)))
                  (each [_ dc (ipairs (or (?. edit :documentChanges) []))]
                    (when (= (?. dc :textDocument :uri) buf-uri)
                      (each [_ te (ipairs (or (?. dc :edits) []))]
                        (add (. te :range)))))))))))
    lines))

(fn buf-request-callback [bufnr response]
  (when (nvim_buf_is_valid bufnr)
    (nvim_buf_clear_namespace bufnr ns 0 -1)
    (let [buf-uri (vim.uri_from_bufnr bufnr)
          lines (action-lines (or response []) buf-uri)]
      (each [_ line (pairs lines)]
        (nvim_buf_set_extmark bufnr ns line 0
                              {:sign_text ""
                               :sign_hl_group :DiagnosticSignError
                               :priority 15})))))

(fn codeaction-autocmd-callback [client bufnr]
  (let [first-line (vim.fn.line :w0)
        last-line (vim.fn.line :w$)
        last-line-length (length (or (. (nvim_buf_get_lines bufnr
                                                            (- last-line 1)
                                                            last-line false)
                                        1)
                                     ""))
        params (vim.lsp.util.make_given_range_params [first-line 0]
                                                     [last-line
                                                      last-line-length]
                                                     bufnr
                                                     client.offset_encoding)]
    (set params.context {:diagnostics (vim.lsp.diagnostic.from (vim.tbl_filter (fn [d]
                                                                                 (<= (- first-line
                                                                                        1)
                                                                                     d.lnum
                                                                                     (- last-line
                                                                                        1)))
                                                                               (vim.diagnostic.get bufnr)))
                         :only [:quickfix]
                         :triggerKind 1})
    (client:request :textDocument/codeAction params
                    (fn [_ response]
                      (buf-request-callback bufnr response))
                    bufnr)
    nil))

(fn M.setup_codeactions [client bufnr]
  (let [group (nvim_create_augroup (.. :code_action_bufnr_ bufnr) {:clear true})]
    (nvim_create_autocmd [:DiagnosticChanged :WinScrolled]
                         {: group
                          :buffer bufnr
                          :callback #(codeaction-autocmd-callback client bufnr)})))

M
