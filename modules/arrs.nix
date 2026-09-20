{
  lib,
  config,
  pkgs,
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

      systemd.services."${name}-bridge" = {
        description = "Tailnet bridge for ${name} (port ${toString arrCfg.port})";
        wantedBy = [ "multi-user.target" ];
        after = [
          "wg-proton.service"
          "${name}.service"
        ];
        wants = [
          "wg-proton.service"
          "${name}.service"
        ];
        serviceConfig = {
          ExecStart = pkgs.writeShellScript "${name}-bridge" ''
            exec ${pkgs.socat}/bin/socat \
              TCP6-LISTEN:${toString arrCfg.port},fork,reuseaddr,ipv6only=0 \
              EXEC:"${pkgs.iproute2}/bin/ip netns exec ${modules.vpn.netns} ${pkgs.socat}/bin/socat - TCP\:127.0.0.1\:${toString arrCfg.port}"
          '';
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };

      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ arrCfg.port ];
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
