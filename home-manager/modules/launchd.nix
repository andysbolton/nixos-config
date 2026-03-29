#
# { lib, config, ... }:
# let
#   modules = config.modules;
#
# in {
#   options.modules.enabled = lib.mkOption {
#             type = lib.types.bool;
#             default = true;
#             description = "Enable launchd services.";
#           };
#
#
#   config = {
#
# launchd.user.agents.lazyssh = {
#           serviceConfig = {
#             ProgramArguments = mkCmd pkgs.system cfg.configFile;
#             RunAtLoad = true;
#             KeepAlive = true;
#           };
#         };
#   }
# }
