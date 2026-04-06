-- [nfnl] fnl/configs/init.fnl
local files = vim.api.nvim_get_runtime_file("lua/configs/langs/*.lua", true)
local tbl_26_ = {}
local i_27_ = 0
for _, filename in pairs(files) do
  local val_28_
  do
    local module = ("configs.langs." .. string.gsub(filename, "(.*[/\\])(.*)%.lua", "%2"))
    local lang = require(module)
    if (type(lang) == "table") then
      val_28_ = lang
    else
      val_28_ = nil
    end
  end
  if (nil ~= val_28_) then
    i_27_ = (i_27_ + 1)
    tbl_26_[i_27_] = val_28_
  else
  end
end
return tbl_26_
