(set vim.o.hlsearch true)

(set vim.wo.number true)
(set vim.wo.relativenumber true)

;; Enable mouse mode
(set vim.o.mouse :a)

;; Sync clipboard between OS and Neovim.
(set vim.o.clipboard :unnamedplus)

;; Over SSH there's no local clipboard daemon, so route +/* through OSC 52
;; (the terminal intercepts it) instead of the normal system-clipboard provider.
(when (or (os.getenv :SSH_TTY) (os.getenv :SSH_CONNECTION))
  (let [osc52 (require :vim.ui.clipboard.osc52)]
    (set vim.g.clipboard
         {:name "OSC 52"
          :copy {:+ (osc52.copy "+") :* (osc52.copy "*")}
          :paste {:+ (osc52.paste "+") :* (osc52.paste "*")}})))

;; Open file:// URIs in this nvim instead of xdg-open.
(let [system-open vim.ui.open]
  (set vim.ui.open (fn [path opt]
                     (let [(uri line) (path:match "^(file://[^#]*)#?L?(%d*)$")]
                       (if uri
                           (do
                             (when (not= (. (vim.api.nvim_win_get_config 0)
                                            :relative)
                                         "")
                               (vim.api.nvim_win_close 0 false))
                             (vim.cmd.edit (vim.fn.fnameescape (vim.uri_to_fname uri)))
                             (when (not= line "")
                               (vim.api.nvim_win_set_cursor 0
                                                            [(tonumber line) 0]))
                             nil)
                           (system-open path opt))))))

;; Enable break indent
(set vim.o.breakindent true)

;; Save undo history
(set vim.o.undofile true)

;; Case insensitive searching UNLESS /C or capital in search
(set vim.o.ignorecase true)
(set vim.o.smartcase true)

(set vim.wo.signcolumn "auto:2")

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
                             {:pattern ["*"]
                              :callback (fn []
                                          (when (and (not= (vim.fn.mode) :c)
                                                     (not= vim.bo.buftype
                                                           :nofile))
                                            (vim.cmd :checktime)))
                              :desc "Reload buffer on focus/hold unless in command-line window"})

(set vim.opt.list true)
(vim.opt.listchars:append {:extends "›"
                           :precedes "‹"
                           :eol "⏎"
                           :trail "·"
                           :nbsp "⎵"
                           :space " "})

(set vim.o.scrolloff 1)
(set vim.o.sidescrolloff 2)
(vim.opt.display:append :truncate)

(set vim.o.mousemoveevent true)

(set vim.fileformats :unix)

(set vim.o.showmode false)
