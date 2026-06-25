(import-macros {: tx} :macros)

[:gpanders/fennel-repl.nvim
 :gpanders/nvim-parinfer
 :vlime/vlime
 (tx :Olical/conjure {:config #(set vim.g.conjure#extract#tree_sitter#enabled
                                    true)})
 (tx :julienvincent/nvim-paredit
     {:config (fn []
                (let [paredit (require :nvim-paredit)
                      ts-context (require :nvim-paredit.treesitter.context)
                      ts-forms (require :nvim-paredit.treesitter.forms)
                      ts-utils (require :nvim-paredit.treesitter.utils)
                      ;; the fennel grammar groups special-form clauses into *_pair nodes
                      ;; (if_pair, case_pair, binding_pair); see through them so raise targets
                      ;; the element and the real enclosing form, not the pair.
                      pair? (fn [node] (and node (string.match (node:type) "_pair$")))
                      pair-aware-root (fn [node context]
                                        (var result (ts-forms.get_node_root node context))
                                        (var guard 0)
                                        (while (and (pair? result) (< guard 16))
                                          (let [nxt (ts-utils.find_root_element_relative_to result
                                                                                            node)]
                                            (if (or (not nxt) (nxt:equal result))
                                                (set guard 99)
                                                (do (set result nxt) (set guard (+ guard 1))))))
                                        result)
                      enclosing-form (fn [node]
                                       (var p (node:parent))
                                       (while (pair? p) (set p (p:parent)))
                                       p)
                      raise (fn [pick]
                              (fn []
                                (let [context (ts-context.create_context)]
                                  (when context
                                    (let [current (pair-aware-root (pick context) context)]
                                      (when current
                                        (let [parent (enclosing-form current)]
                                          (when (and parent
                                                     (not (ts-utils.is_document_root parent)))
                                            (let [text (vim.treesitter.get_node_text current 0)
                                                  (sr sc er ec) (parent:range)]
                                              (vim.api.nvim_buf_set_text 0 sr sc er ec
                                                                         (vim.fn.split text "\n"))
                                              (vim.api.nvim_win_set_cursor 0
                                                                           [(+ sr 1) sc]))))))))))
                      raise-form (raise (fn [c] (ts-forms.find_nearest_form c.node c)))
                      raise-element (raise (fn [c] c.node))]
                  (paredit.setup {:indent {:enabled true}
                                  :keys {:<localleader>o false
                                         :<localleader>O false
                                         ">)" false
                                         ">(" false
                                         "<)" false
                                         "<(" false
                                         :>s [paredit.api.slurp_forwards
                                              "Slurp forwards"]
                                         :<s [paredit.api.slurp_backwards
                                              "Slurp backwards"]
                                         :>b [paredit.api.barf_forwards
                                              "Barf forwards"]
                                         :<b [paredit.api.barf_backwards
                                              "Barf backwards"]
                                         :<localleader>rf [raise-form "[R]aise [f]orm"]
                                         :<localleader>re [raise-element
                                                           "[R]aise [e]lement"]
                                         :<localleader>wh [#(paredit.cursor.place_cursor (paredit.wrap.wrap_element_under_cursor "("
                                                                                                                                 ")"
                                                                                                                                 {:placement :inner_start
                                                                                                                                  :mode :insert}))
                                                           "[W]rap element [h]ead"]
                                         :<localleader>wt [#(paredit.cursor.place_cursor (paredit.wrap.wrap_element_under_cursor "("
                                                                                                                                 ")"
                                                                                                                                 {:placement :inner_end
                                                                                                                                  :mode :insert}))
                                                           "[W]rap element insert [t]ail"]
                                         :<localleader>weh [#(paredit.cursor.place_cursor (paredit.wrap.wrap_enclosing_form_under_cursor "("
                                                                                                                                         ")"
                                                                                                                                         {:placement :innert_start
                                                                                                                                          :mode :insert}))
                                                            "[W]rap [e]nclosing form insert [h]ead"]
                                         :<localleader>wet [#(paredit.cursor.place_cursor (paredit.wrap.wrap_enclosing_form_under_cursor "("
                                                                                                                                         ")"
                                                                                                                                         {:placement :inner_end
                                                                                                                                          :mode :insert}))
                                                            "[W]rap [e]nclosing form insert [t]ail"]}})))})]
