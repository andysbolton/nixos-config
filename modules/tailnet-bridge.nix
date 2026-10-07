{
  lib,
  pkgs,
  config,
  ...
}:
let
  bridges = config.modules.tailnetBridge.bridges;

  mkBridgeUnit =
    name: bridgeCfg:
    lib.nameValuePair "${name}-bridge" {
      description = "Tailnet bridge for ${name} (port ${toString bridgeCfg.port})";
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
            TCP6-LISTEN:${toString bridgeCfg.port},fork,reuseaddr,ipv6only=0 \
            EXEC:"${pkgs.iproute2}/bin/ip netns exec ${bridgeCfg.netns} ${pkgs.socat}/bin/socat - TCP\:127.0.0.1\:${toString bridgeCfg.port}"
        '';
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
in
{
  options.modules.tailnetBridge.bridges = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          port = lib.mkOption {
            type = lib.types.port;
            description = "TCP port the bridged service listens on inside its network namespace, and the port exposed on tailscale0.";
          };
          netns = lib.mkOption {
            type = lib.types.str;
            description = "Name of the network namespace the bridged service runs in.";
          };
        };
      }
    );
    default = { };
    description = "Tailnet-reachable TCP bridges into netns-isolated services, keyed by the systemd service name of the bridged service.";
  };

  config = {
    systemd.services = lib.mapAttrs' mkBridgeUnit bridges;
    networking.firewall.interfaces.tailscale0.allowedTCPPorts = lib.mapAttrsToList (
      _: bridgeCfg: bridgeCfg.port
    ) bridges;
  };
}
