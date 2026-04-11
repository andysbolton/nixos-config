(import-macros {: tx} :utils.macros)

[(tx :hrsh7th/nvim-cmp
     {:dependencies [:hrsh7th/cmp-nvim-lsp
                     :hrsh7th/cmp-buffer
                     :hrsh7th/cmp-path
                     :hrsh7th/cmp-cmdline
                     :hrsh7th/nvim-cmp
                     :saadparwaiz1/cmp_luasnip
                     (tx :L3MON4D3/LuaSnip
                         {:version :v2.*
                          :build "make install_jsregexp"
                          :dependencies [:rafamadriz/friendly-snippets]})]
      :config (fn []
                (let [cmp (require :cmp)
                      snip-loader (require :luasnip.loaders.from_vscode)
                      luasnip (require :luasnip)]
                  (luasnip.config.setup {})
                  (snip-loader.lazy_load)
                  (cmp.setup {:snippet {:expand #(luasnip.lsp_expand $1.body)}
                              :window {:completion (cmp.config.window.bordered)
                                       :documentation (cmp.config.window.bordered)}
                              :mapping (cmp.mapping.preset.insert {:<C-n> (cmp.mapping.select_next_item)
                                                                   :<C-p> (cmp.mapping.select_prev_item)
                                                                   :<C-e> (cmp.mapping.abort)
                                                                   :<CR> (cmp.mapping (fn [fallback]
                                                                                        (let [entry (cmp.get_selected_entry)]
                                                                                          (if entry
                                                                                              (if (cmp.visible)
                                                                                                  (if (luasnip.expandable)
                                                                                                      (luasnip.expand)
                                                                                                      (cmp.confirm {:select true})))
                                                                                              (fallback)))))
                                                                   :<Tab> (cmp.mapping (fn [fallback]
                                                                                         (if (luasnip.locally_jumpable 1)
                                                                                             (luasnip.jump 1)
                                                                                             (fallback)))
                                                                                       [:i
                                                                                        :s])
                                                                   :<S-Tab> (cmp.mapping (fn [fallback]
                                                                                           (if (luasnip.locally_jumpable -1)
                                                                                               (luasnip.jump -1)
                                                                                               (fallback)))
                                                                                         [:i
                                                                                          :s])})
                              :sources (cmp.config.sources [{:name :nvim_lsp}
                                                            {:name :luasnip}
                                                            {:name :path}
                                                            {:name :cmdline}
                                                            {:name :codecompanion}]
                                                           [{:name :buffer}])})))})]
