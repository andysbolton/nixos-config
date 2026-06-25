(local M {})

(local {: group-by : head : empty? : debounce : tail} (require :utils))
(local {: nvim_buf_clear_namespace
        : nvim_buf_get_lines
        : nvim_buf_is_valid
        : nvim_buf_set_extmark
        : nvim_create_augroup
        : nvim_create_autocmd
        : nvim_create_namespace
        : nvim_win_get_buf
        : nvim_win_get_cursor
        : nvim_echo
        : nvim_get_current_win
        : nvim_set_option_value} vim.api)

(local ns (nvim_create_namespace :code_action_sign))

(fn first-viewport-line [] (vim.fn.line :w0))
(fn last-viewport-line [] (vim.fn.line :w$))
(fn current-line [] (head (nvim_win_get_cursor 0)))

(fn line-length-0-indexed [bufnr line]
  (-> (nvim_buf_get_lines bufnr (- line 1) line false)
      head
      length
      (- 1)
      (math.max 0)))

(fn code-action-clients [bufnr]
  (vim.lsp.get_clients {: bufnr :method :textDocument/codeAction}))

(fn make-given-range-params [context bufnr start-pos end-pos offset]
  ;; make_given_range_params is mark-line (1-indexed rows, 0-indexed columns)
  (doto (vim.lsp.util.make_given_range_params start-pos end-pos bufnr offset)
    (tset :context context)))

(fn make-range-params [context offset-encoding]
  (doto (vim.lsp.util.make_range_params 0 offset-encoding)
    (tset :context context)))

(fn range-builder [context bufnr start-pos end-pos]
  (if (or (= bufnr start-pos end-pos nil) (= (tail end-pos) 0))
      (fn [offset] (make-range-params context offset))
      (fn [offset]
        (make-given-range-params context bufnr start-pos end-pos offset))))

(fn request-code-actions [client bufnr params cb]
  (client:request :textDocument/codeAction params
                  (fn [err result context]
                    (when err
                      (nvim_echo [[(.. "LSP client request failed: "
                                       (. err :message))
                                   :ErrorMsg]]
                                 true {:err true}))
                    (cb (or result []) context)) bufnr))

;; Fan a request out to every code-action client; `on-actions` runs per client response,
;; `on-done` runs once after all have replied.
(fn request-all [{: clients : bufnr : make-params : on-actions : on-done}]
  (var pending (length clients))
  (each [_ client (ipairs clients)]
    (let [params (make-params (. client :offset_encoding))]
      (request-code-actions client bufnr params
                            (fn [actions context]
                              (on-actions actions context)
                              (set pending (- pending 1))
                              (when (= pending 0) (when on-done (on-done))))))))

(fn apply-action [action {: client_id : bufnr}]
  (let [client (vim.lsp.get_client_by_id client_id)
        do-apply (fn [act]
                   (when act.edit
                     (vim.lsp.util.apply_workspace_edit act.edit
                                                        client.offset_encoding))
                   (when act.command
                     (let [command (if (= (type act.command) :table)
                                       act.command
                                       act)]
                       (client:exec_cmd command {: bufnr}))))]
    (if (and (not action.edit) (client:supports_method :codeAction/resolve))
        (client:request :codeAction/resolve action
                        (fn [err resolved]
                          (do-apply (if (or err (not resolved)) action resolved)))
                        bufnr)
        (do-apply action))))

(fn select-and-apply [items]
  (vim.ui.select items {:prompt "Code action:"
                        :format_item (fn [item]
                                       (let [a item.action]
                                         (.. (or a.title "")
                                             (if a.kind (.. "  [" a.kind "]")
                                                 ""))))}
                 (fn [choice]
                   (when choice
                     (apply-action choice.action choice.context)))))

;; Parse a collection of code actions and return the lines they apply to.
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

;; Viewport quickfix sign: a bulb on every visible line that has a quickfix, unioned across
;; all clients.
(fn codeaction-viewport-callback [bufnr]
  (let [clients (code-action-clients bufnr)]
    (when (> (length clients) 0)
      (let [first-line (first-viewport-line)
            ll (last-viewport-line)
            ll-cols (line-length-0-indexed bufnr ll)
            buf-uri (vim.uri_from_bufnr bufnr)
            context {:diagnostics (vim.lsp.diagnostic.from (vim.tbl_filter (fn [d]
                                                                             (<= (- first-line
                                                                                    1)
                                                                                 d.lnum
                                                                                 (- ll
                                                                                    1)))
                                                                           (vim.diagnostic.get bufnr)))
                     :only [:quickfix]
                     :triggerKind 1}
            seen {}]
        ;; viewport request
        (request-all {: clients
                      : bufnr
                      :make-params (range-builder context bufnr [first-line 0]
                                                  [ll ll-cols])
                      :on-actions (fn [actions]
                                    (each [_ line (ipairs (action-lines actions
                                                                        buf-uri))]
                                      (tset seen line true)))
                      :on-done (fn []
                                 (when (nvim_buf_is_valid bufnr)
                                   (nvim_buf_clear_namespace bufnr ns 0 -1)
                                   (each [line _ (pairs seen)]
                                     (nvim_buf_set_extmark bufnr ns line 0
                                                           {:sign_text ""
                                                            :sign_hl_group :DiagnosticSignWarn
                                                            :priority 35}))))}))))
  nil)

;; The order here determines the order of the winbar markers.
(local kind-styles [{:prefix :quickfix :icon "" :hl :Warn}
                    {:prefix :source :icon "" :hl :Hint}
                    {:prefix :refactor :icon "" :hl :Info}
                    {:prefix :gopls :icon "" :hl :Hint}])

(local default-kind-style
       {:icon "" :hl :Warning :rank (+ 1 (length kind-styles))})

(fn kind-style [kind]
  (or (accumulate [found nil i {: prefix : icon : hl} (ipairs kind-styles)
                   :until found]
        (when (vim.startswith (or kind "") prefix)
          {: icon : hl :rank i})) default-kind-style))

(fn set-winbar-count [bufnr actions-by-kind]
  (let [win (nvim_get_current_win)]
    (if (and (not (empty? actions-by-kind)) (= (nvim_win_get_buf win) bufnr))
        (let [entries (icollect [kind actions (pairs actions-by-kind)]
                        {:count (length actions) :style (kind-style kind)})]
          (table.sort entries #(< (. $1 :style :rank) (. $2 :style :rank)))
          (nvim_set_option_value :winbar
                                 (accumulate [s "" _ entry (ipairs entries)]
                                   (let [{: count :style {: icon : hl}} entry]
                                     (.. s "%#DiagnosticSign" hl "#" icon " "
                                         count "%* ")))
                                 {: win}))
        (nvim_set_option_value :winbar "" {: win}))))

(fn codeaction-line-callback [bufnr]
  (when (= (nvim_win_get_buf 0) bufnr)
    (let [clients (code-action-clients bufnr)]
      (if (= (length clients) 0)
          (set-winbar-count bufnr [])
          (let [row (current-line)
                row-cols (line-length-0-indexed bufnr row)
                context {:triggerKind 1
                         :diagnostics (M.line_diagnostics bufnr row)}
                actions []]
            ;; line request
            (request-all {: clients
                          : bufnr
                          :make-params (range-builder context bufnr [row 0]
                                                      [row row-cols])
                          :on-actions (fn [as]
                                        (each [_ a (ipairs as)]
                                          (table.insert actions a)))
                          :on-done #(when (nvim_buf_is_valid bufnr)
                                      (set-winbar-count bufnr
                                                        (group-by (fn [action]
                                                                    (case (string.match (or action.kind
                                                                                            "")
                                                                                        "^([^.]*)")
                                                                      (key) key))
                                                                  actions)))})))))
  nil)

(fn M.line_diagnostics [bufnr row]
  (vim.lsp.diagnostic.from (vim.diagnostic.get bufnr {:lnum (- row 1)})))

(fn M.code_action []
  (let [bufnr 0
        row (current-line)
        clients (code-action-clients bufnr)
        context {:triggerKind 1 :diagnostics (M.line_diagnostics bufnr row)}
        items []
        row-cols (line-length-0-indexed bufnr row)]
    (request-all {: clients
                  : bufnr
                  :make-params (range-builder context bufnr [row 0]
                                              [row row-cols])
                  :on-actions (fn [actions context]
                                (each [_ action (ipairs actions)]
                                  (table.insert items {: action : context})))
                  :on-done (fn []
                             (if (= (length items) 0)
                                 (vim.notify "No code actions available"
                                             vim.log.levels.INFO)
                                 (select-and-apply items)))})))

;; Buffer-scoped (client-agnostic: the callbacks union all code-action clients themselves), so
;; register once per buffer no matter how many clients attach.
(fn M.setup_codeactions [bufnr]
  (when (not (. (. vim.b bufnr) :code_action_setup))
    (tset (. vim.b bufnr) :code_action_setup true)
    (let [group (nvim_create_augroup (.. :code_action_bufnr_ bufnr)
                                     {:clear true})]
      (nvim_create_autocmd [:DiagnosticChanged :WinScrolled]
                           {: group
                            :buffer bufnr
                            :callback (debounce 100
                                                #(codeaction-viewport-callback bufnr))})
      (nvim_create_autocmd [:CursorHold
                            :BufEnter
                            :InsertLeave
                            :DiagnosticChanged]
                           {: group
                            :buffer bufnr
                            :callback #(codeaction-line-callback bufnr)})
      (nvim_create_autocmd [:BufLeave]
                           {: group
                            :buffer bufnr
                            :callback (fn []
                                        (set-winbar-count bufnr [])
                                        nil)}))))

M
