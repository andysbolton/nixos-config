-- [nfnl] fnl/plugins/cmp.fnl
local function _1_()
  local cmp = require("cmp")
  local snip_loader = require("luasnip.loaders.from_vscode")
  local luasnip = require("luasnip")
  luasnip.config.setup({})
  snip_loader.lazy_load()
  local function _2_(_241)
    return luasnip.lsp_expand(_241.body)
  end
  local function _3_(fallback)
    local entry = cmp.get_selected_entry()
    if entry then
      if cmp.visible() then
        if luasnip.expandable() then
          return luasnip.expand()
        else
          return cmp.confirm({select = true})
        end
      else
        return nil
      end
    else
      return fallback()
    end
  end
  local function _7_(fallback)
    if luasnip.locally_jumpable(1) then
      return luasnip.jump(1)
    else
      return fallback()
    end
  end
  local function _9_(fallback)
    if luasnip.locally_jumpable(-1) then
      return luasnip.jump(-1)
    else
      return fallback()
    end
  end
  return cmp.setup({snippet = {expand = _2_}, window = {completion = cmp.config.window.bordered(), documentation = cmp.config.window.bordered()}, mapping = cmp.mapping.preset.insert({["<C-n>"] = cmp.mapping.select_next_item(), ["<C-p>"] = cmp.mapping.select_prev_item(), ["<C-e>"] = cmp.mapping.abort(), ["<CR>"] = cmp.mapping(_3_), ["<Tab>"] = cmp.mapping(_7_, {"i", "s"}), ["<S-Tab>"] = cmp.mapping(_9_, {"i", "s"})}), sources = cmp.config.sources({{name = "nvim_lsp"}, {name = "luasnip"}, {name = "path"}, {name = "cmdline"}, {name = "codecompanion"}}, {{name = "buffer"}})})
end
return {{"hrsh7th/nvim-cmp", config = _1_, dependencies = {"hrsh7th/cmp-nvim-lsp", "hrsh7th/cmp-buffer", "hrsh7th/cmp-path", "hrsh7th/cmp-cmdline", "hrsh7th/nvim-cmp", "saadparwaiz1/cmp_luasnip", {"L3MON4D3/LuaSnip", build = "make install_jsregexp", dependencies = {"rafamadriz/friendly-snippets"}, version = "v2.*"}}}}
