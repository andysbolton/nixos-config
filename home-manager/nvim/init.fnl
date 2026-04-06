(set table.unpack (or table.unpack unpack))

(set vim.g.python3_host_prog (.. (vim.fn.expand "~") ".asdf/shims/python"))

(set vim.g.mapleader " ")
(set vim.g.maplocalleader " ")
(set vim.g.copilot_no_tab_map true)
(set vim.o.winborder :rounded)

; bootstrap lazy
(local lazypath (.. (vim.fn.stdpath :data) :/lazy/lazy.nvim))

(when (not (vim.loop.fs_stat lazypath))
  (vim.fn.system [:git
                  :clone
                  "--filter=blob:none"
                  "https://github.com/folke/lazy.nvim.git"
                  :--branch=stable
                  lazypath]))

(vim.opt.rtp:prepend lazypath)
(let [lazy (require :lazy)]
  (lazy.setup [{:import :plugins}] [{:change_detection {:notify false}}]))

(require :mappings)
(require :options)
(require :cmds)

; -- vim: ts=2 sts=2 sw=2 et
