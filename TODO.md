## Neovim

- [ ] visual mode indicator
- [ ] get back diagnostic icons in gutter
- [ ] actually investigate codecompanioncli
- [ ] register fzf as vim.ui.select
- [ ] execute arbitrary lua (conjure?)
- [ ] investigate trouble.nvim
- [ ] client.supports_method is deprecated
- [ ] look at default code companion cli key maps
- [ ] move out the stuff at the top of plugins/lsp.lua
- [ ] send diagnostics with code actions
  ```lua
    local nvim_diagnostics = vim.diagnostic.get(bufnr, {
      lnum = start_line,
      end_lnum = end_line,
    })
  ```
- [ ] move temp ui2 out of metrics.lua

## rofi

- [ ] search mozilla bookmarks
- [ ] query river windows
- [ ] cliphist

## mac

- [ ] icon is squashed in starship, change host in starship

## nix

- [ ] MOZ_ENABLE_WAYLAND=1 not seeming to work (no border on firefox)
- [ ] nix mcp server

## general

- [ ] check out lazygit
