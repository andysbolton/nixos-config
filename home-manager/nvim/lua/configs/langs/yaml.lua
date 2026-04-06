return {
  name = "yaml",
  ft = { "yaml", "yml" },
  ls = {
    name = "yamlls",
    settings = {
      yamlls = {
        settings = {
          yaml = {
            schemas = {
              ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = {
                "docker-compose*.yml",
                "docker-compose.*.yml",
              },
              ["https://raw.githubusercontent.com/microsoft/azure-pipelines-vscode/master/service-schema.json"] = {
                ".ci/*.yml",
                "azure-pipelines.yml",
              },
            },
          },
        },
      },
    },
  },
  formatter = {
    name = "prettierd",
    actions = {
      function() return require("formatter.filetypes.yaml").prettierd() end,
    },
  },
  treesitter = "yaml",
}
