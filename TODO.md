## Neovim

- [x] visual mode indicator
- [x] get back diagnostic icons in gutter
- [ ] actually investigate codecompanioncli
- [x] register fzf as vim.ui.select
- [ ] execute arbitrary lua (conjure?)
- [ ] investigate trouble.nvim
- [ ] client.supports_method is deprecated
- [ ] look at default code companion cli key maps
- [ ] move out the stuff at the top of plugins/lsp.lua
- [ ] move diagnostics out of plugins/lsp.lua
- [x] send diagnostics with code actions
  ```lua
    local nvim_diagnostics = vim.diagnostic.get(bufnr, {
      lnum = start_line,
      end_lnum = end_line,
    })
  ```
- [ ] move temp ui2 out of metrics.lua
- [ ] folds
- [ ] neorg
- [ ] prevent dupe diagnostic signs
- [ ] fix yank command. also yank stderr
- [ ] source code actions not doing anything
- [ ] codeactions: bring back diff
- [ ] code actions: wrench showing first line, ex: term.lua
- [ ] treesitter motions would be really helpful
- [ ] portable: vpn

## rofi

- [ ] search mozilla bookmarks
- [ ] cliphist
- [ ] query river windows

## mac

- [ ] icon is squashed in starship, change host in starship

## nix

- [ ] MOZ_ENABLE_WAYLAND=1 not seeming to work (no border on firefox)
- [ ] nix mcp server

## general

- [ ] check out lazygit
- [ ] fzf fish
- [ ] postmarketOS
