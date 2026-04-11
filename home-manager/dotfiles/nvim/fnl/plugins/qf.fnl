(import-macros {: tx} :utils.macros)

[(tx :stevearc/quicker.nvim
     {:config (fn []
                (let [{: collapse : expand : toggle :setup qfsetup} (require :quicker)]
                  (vim.keymap.set :n :<leader>q #(toggle)
                                  {:desc "Toggle quickfix"})
                  (vim.keymap.set :n :<leader>l #(toggle {:loclist true})
                                  {:desc "Toggle loclist"})
                  (qfsetup {:keys [(tx ">"
                                       #(expand {:before 2
                                                 :after 2
                                                 :add_to_existing true})
                                       {:desc "Expand quickfix context"})
                                   (tx "<" #(collapse)
                                       {:desc "Collapse quickfix context"})]})))})
 (tx :kevinhwang91/nvim-bqf
     {:ft :qf
      :config #(let [{: setup} (require :bqf)]
                 (setup {:auto_enable true} :auto_resize_height true :preview
                        {:win_height 12
                         :win_vheight 12
                         :delay_syntax 80
                         :show_title false
                         :border ["┏"
                                  "━"
                                  "┓"
                                  "┃"
                                  "┛"
                                  "━"
                                  "┗"
                                  "┃"]} :filter
                        {:fzf {:extra_opts [:--bind
                                            "ctrl-o:toggle-all"
                                            :--delimiter
                                            "│"]}}))})]
