return {
  "nvim-orgmode/orgmode",
  event = "VeryLazy",
  config = function()
    require("orgmode").setup {
      org_agenda_files = { "~/org/*.org", "~/org/notes/**/*.org" },
      org_default_notes_file = "~/org/refile.org",
      org_archive_location = "~/org/archive/%s_archive::",
      org_capture_templates = {
        a = {
          description = "Leg day",
          target = "~/org/training.org",
          template = "* %<%Y-%m-%d %a>  :A:\nBSS %?\nRDL \nGB \nRL \nWS \nCR ",
        },
        c = {
          description = "Upper day",
          target = "~/org/training.org",
          template = "* %<%Y-%m-%d %a>  :C:\nDH %?\nPU \nCU \nEPU \nPPU \nDIP \nHOL \nSP ",
        },
        b = {
          description = "HIIT",
          target = "~/org/training.org",
          template = "* %<%Y-%m-%d %a>  :B:\n%?",
        },
      },
    }

    vim.lsp.enable "org"
  end,
}
