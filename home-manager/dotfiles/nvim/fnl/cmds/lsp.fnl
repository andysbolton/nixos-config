(local M {})

(local {: nvim_create_augroup : nvim_create_autocmd : nvim_win_get_cursor}
       vim.api)

(vim.fn.sign_define [{:name :light_bulb_sign
                      :text "💡"
                      :texthl :LspDiagnosticsDefaultInformation}])

(vim.diagnostic.config {:virtual_text false :virtual_lines true})

(fn buf-request-callback [line bufnr response]
  (vim.fn.sign_unplace :light_bulb_sign {:buffer bufnr})
  (when (and (not= nil response) (> (length response) 0))
    (vim.fn.sign_place 0 :light_bulb_sign :light_bulb_sign bufnr
                       {:lnum line :priority 10})))

(fn codeaction-autocmd-callback [client bufnr]
  (let [row (table.unpack (nvim_win_get_cursor 0))
        params (vim.lsp.util.make_range_params 0 client.offset_encoding)]
    (set params.context {:diagnostics (icollect [_ d (ipairs (vim.diagnostic.get bufnr
                                                                                 {:lnum (- row
                                                                                           1)}))]
                                        (?. d :user_data :lsp))
                         :triggerKind 1})
    (client:request :textDocument/codeAction params
                    (fn [_ response]
                      (buf-request-callback row bufnr response))
                    bufnr)
    nil))

(fn M.setup_codeactions [client bufnr]
  (let [code_action_group (nvim_create_augroup (.. :code_action_bufnr_ bufnr)
                                               {:clear true})]
    (nvim_create_autocmd [:CursorHold :CursorHoldI]
                         {:group code_action_group
                          :buffer bufnr
                          :callback (fn []
                                      (codeaction-autocmd-callback client bufnr))})))

M
