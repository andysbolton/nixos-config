(local M {})

(local lsp_util vim.lsp.util)
(local {: buf_request_all
        : nvim_buf_clear_namespace
        : nvim_buf_set_extmark
        : nvim_create_augroup
        : nvim_create_autocmd
        : nvim_create_namespace
        : nvim_win_get_cursor} vim.api)

(vim.fn.sign_define :light_bulb_sign
                    {:text "💡" :texthl :LspDiagnosticsDefaultInformation})

(vim.diagnostic.config {:virtual_text false :virtual_lines true})

(fn buf-request-callback [line ns_id bufnr res]
  (vim.fn.sign_unplace :light_bulb_sign)
  (nvim_buf_clear_namespace bufnr ns_id 0 -1)
  (let [(_ value) (next res)
        result (. value :result)
        len (if (not= nil result) (length result) 0)]
    (when (> len 0)
      (let [line_num (- line 1)
            col_num 0
            text (string.format " %d code actions" len)
            opts {:virt_text [[text :DiagnosticInfo]]
                  :virt_text_pos :eol_right_align
                  :priority 0}]
        (nvim_buf_set_extmark bufnr ns_id line_num col_num opts)
        (vim.fn.sign_place 0 :light_bulb_sign :light_bulb_sign bufnr
                           {:lnum line :priority 10})))))

(fn codeaction-autocmd-callback [ns_id bufnr]
  (let [line (table.unpack (nvim_win_get_cursor 0))]
    (var params (lsp_util.make_range_params 0 :utf-8))
    (set params.context
         {:diagnostics (vim.diagnostic.get bufnr {:namespace ns_id :lnum line})
          :triggerKind vim.lsp.protocol.CodeActionTriggerKind.Invoked})
    (buf_request_all bufnr :textDocument/codeAction params
                     (fn [res]
                       (buf-request-callback line ns_id bufnr res)))
    nil))

(fn M.setup_codeactions [bufnr]
  (let [ns_id (nvim_create_namespace (.. :code_action_virtual_text_ bufnr))
        code_action_group (nvim_create_augroup (.. :code_action_bufnr_ bufnr)
                                               {:clear true})]
    (nvim_create_autocmd [:CursorHold :CursorHoldI :BufLeave]
                         {:group code_action_group
                          :buffer bufnr
                          :callback (fn [] codeaction-autocmd-callback ns_id
                                      bufnr)})))

M
