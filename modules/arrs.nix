{
  lib,
  config,
  ...
}:
let
  modules = config.modules;

  arrs = {
    bazarr = {
      port = 6767;
    };
    prowlarr = {
      port = 9696;
    };
    radarr = {
      port = 7878;
    };
    sonarr = {
      port = 8989;
    };
  };

  mkArrConfig =
    name: arrCfg:
    lib.mkIf (modules.vpn.enable && modules.arrs.${name}.enable) {
      services.${name}.enable = true;
      systemd.services.${name} = {
        after = [
          "netns@${modules.vpn.netns}.service"
          "wg-proton.service"
        ];
        bindsTo = [
          "netns@${modules.vpn.netns}.service"
          "wg-proton.service"
        ];
        partOf = [
          "netns@${modules.vpn.netns}.service"
          "wg-proton.service"
        ];
        serviceConfig = {
          NetworkNamespacePath = "/run/netns/${modules.vpn.netns}";
          Group = lib.mkForce "media";
          UMask = lib.mkForce "0002";
        };
      };

      users.users = lib.mkIf modules.arrs.${name}.addUserToMediaGroup {
        ${name}.extraGroups = [ "media" ];
      };

      modules.tailnetBridge.bridges.${name} = {
        port = arrCfg.port;
        netns = modules.vpn.netns;
      };
    };
in
{
  options.modules.arrs = lib.genAttrs (lib.attrNames arrs) (
    name:
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
    }
  );

  config = lib.mkMerge (lib.mapAttrsToList mkArrConfig arrs);
}
