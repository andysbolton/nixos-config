(import-macros {: tx} :macros)

[(tx :gpanders/fennel-repl.nvim {:ft :fennel})
 (tx :gpanders/nvim-parinfer {:ft [:fennel]})
 (tx :vlime/vlime {:ft :lisp})
 (tx :Olical/conjure {:ft [:fennel :lua]
                      :config #(set vim.g.conjure#extract#tree_sitter#enabled
                                    true)})
 (tx :andysbolton/nvim-paredit
     {:branch :feature/support-fennel-if-pair
      :ft [:fennel]
      :config (fn []
                (let [paredit (require :nvim-paredit)]
                  (paredit.setup {:keys {:<localleader>o false
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
                                         :<localleader>rf [paredit.api.raise_form
                                                           "[R]aise [f]orm"]
                                         :<localleader>re [paredit.api.raise_element
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
