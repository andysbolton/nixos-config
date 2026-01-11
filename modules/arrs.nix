{ lib, config, ... }:
let
  modules = config.modules;

  services = [ "prowlarr" "radarr" "sonarr" ];

  mkArrConfig = name:
    lib.mkIf (modules.vpn.enable && modules.arrs.${name}.enable) {
      services.${name}.enable = true;
      systemd.services.${name} = {
        after = [ "netns@${modules.vpn.netns}.service" "wg-proton.service" ];
        bindsTo = [ "netns@${modules.vpn.netns}.service" "wg-proton.service" ];
        partOf = [ "netns@${modules.vpn.netns}.service" "wg-proton.service" ];
        serviceConfig.NetworkNamespacePath = "/run/netns/${modules.vpn.netns}";
      };
      users.users = lib.mkIf modules.arrs.${name}.addUserToMediaGroup {
        ${name}.extraGroups = [ "media" ];
      };
    };
in {
  options.modules.arrs = lib.genAttrs services (name:
    lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkEnableOption "the ${name} service.";
          addUserToMediaGroup = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Add ${name} user to media group.";
          };
        };
      };
      default = { };
    });

  config = lib.mkMerge (map mkArrConfig services);
}
