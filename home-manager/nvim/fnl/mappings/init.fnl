(local {:set km-set} vim.keymap)

(km-set [:n :v] :<Space> :<Nop> {:silent true})

; Remap for dealing with word wrap)
(km-set :n :k "v:count == 0 ? 'gk' : 'k'" {:expr true :silent true})
(km-set :n :j "v:count == 0 ? 'gj' : 'j'" {:expr true :silent true})

; Move lines up/down
(km-set :n :<A-Down> ":m .+1<CR>==" {:desc "Move line down" :silent true})

(km-set :n :<A-Up> ":m .-2<CR>==" {:desc "Move line up" :silent true})
(km-set :i :<A-Down> "<Esc>:m .+1<CR>==gi"
        {:desc "Move line down" :silent true})

(km-set :i :<A-Up> "<Esc>:m .-2<CR>==gi" {:desc "Move line up" :silent true})

(km-set :v :<A-Down> ":m '>+1<CR>gv=gv" {:desc "Move line down" :silent true})

(km-set :v :<A-Up> ":m '<-2<CR>gv=gv" {:desc "Move line up" :silent true})

; Insert newlines without entering insert mode
(km-set :n :<leader>o :o<Esc>k {:silent true})
(km-set :n :<leader>O :O<Esc>j {:silent true})

; Delete to black hole register
(km-set [:n :v] :<leader>dd "\"_dd<Esc>" {:silent true})
(km-set [:v] :<leader>d "\"_d<Esc>" {:silent true})
(km-set [:n] :<leader>x "\"_x<Esc>" {:silent true})
(km-set :n :<leader>xa ":wa | qa<cr>"
        {:desc "Write and close all buffers while terminal open" :silent true})

(km-set :n :<leader>w ":w<cr>" {:desc "[W]rite" :silent true})
(km-set :n :<leader>wa ":wa<cr>" {:desc "[W]rite [A]ll" :silent true})
(km-set :n :<C-a> ":normal gg0vG$<cr>" {:desc "Select all text"})

; Diagnostic keymaps
(km-set :n "[d" #(vim.diagnostic.jump {:count 1 :float true})
        {:desc "Go to previous diagnostic message"})

(km-set :n "]d" #(vim.diagnostic.jump {:count -1 :float true})
        {:desc "Go to next diagnostic message"})

(km-set :n :<leader>d vim.diagnostic.open_float
        {:desc "Open floating diagnostic message"})

; Copy current buffer name
(km-set :n :<leader>c ":let @+=expand('%')<cr>"
        {:desc "[C]opy current buffer name" :silent true})

(km-set :i :<C-L> "<Plug>(copilot-accept-word)")

; Fugitive
(km-set :n :<leader>gs ":Git<CR>")
(km-set :n :<leader>gd ":Gdiffsplit<CR>")
(km-set :n :<leader>gc ":Git commit<CR>")
(km-set :n :<leader>gb ":Git blame<CR>")
(km-set :n :<leader>gm ":Git mergetool<CR>")

; Improve diff experience (move me)
(vim.opt.diffopt:append "algorithm:patience")
(vim.opt.diffopt:append :indent-heuristic)
