; auto-load language configurations from configs/langs/
(let [files (vim.api.nvim_get_runtime_file :lua/configs/langs/*.lua true)]
  (icollect [_ filename (pairs files)]
    (let [module (.. :configs.langs.
                     (string.gsub filename "(.*[/\\])(.*)%.lua" "%2"))
          lang (require module)]
      (if (= (type lang) :table)
          lang))))
