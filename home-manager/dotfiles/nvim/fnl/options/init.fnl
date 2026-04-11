(set vim.o.hlsearch true)

(set vim.wo.number true)
(set vim.wo.relativenumber true)

;; Enable mouse mode
(set vim.o.mouse :a)

;; Sync clipboard between OS and Neovim.
(set vim.o.clipboard :unnamedplus)

;; Enable break indent
(set vim.o.breakindent true)

;; Save undo history
(set vim.o.undofile true)

;; Case insensitive searching UNLESS /C or capital in search
(set vim.o.ignorecase true)
(set vim.o.smartcase true)

;; Keep signcolumn on by defaul
(set vim.wo.signcolumn :yes)

;; Decrease update time
(set vim.o.updatetime 250)
(set vim.o.timeout true)
(set vim.o.timeoutlen 300)

;; Set completeopt to have a better completion experience
(set vim.o.completeopt "menuone,noselect")

(set vim.o.termguicolors true)

;; Split to below and right by default
(set vim.o.splitbelow true)
(set vim.o.splitright true)

(set vim.o.tabstop 4)
(set vim.o.shiftwidth 4)
(set vim.o.softtabstop 4)
(set vim.o.expandtab true)

(set vim.o.autoread true)
; I should move this out of this file.
(vim.api.nvim_create_autocmd [:BufEnter :CursorHold :CursorHoldI :FocusGained]
                             {:command "if mode() != 'c' | checktime | endif"
                              :pattern ["*"]})

(set vim.opt.list true)
(vim.opt.listchars:append {:extends "›"
                           :precedes "‹"
                           :eol "⏎"
                           :trail "·"
                           :nbsp "⎵"
                           :space " "})

(set vim.o.mousemoveevent true)

(set vim.fileformats "unix")
