return {
  name = "fsharp",
  ft = { "fsharp" },
  ls = {
    name = "fsautocomplete",
    settings = {},
  },
  formatter = {
    name = "fantomas",
    actions = {
      function()
        return {
          exe = "fantomas",
          args = {},
          stdin = false,
        }
      end,
    },
  },
}
