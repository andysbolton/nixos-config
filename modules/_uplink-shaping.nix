{
  lib,
  pkgs,
  config,
  utils,
  ...
}:
let
  cfg = config.modules.uplinkShaping;
  device = "sys-subsystem-net-devices-${utils.escapeSystemdPath cfg.interface}.device";
in
{
  options.modules.uplinkShaping = {
    enable = lib.mkEnableOption "CAKE egress shaping on the uplink interface.";

    interface = lib.mkOption {
      type = lib.types.str;
      description = "Interface to shape.";
    };

    bandwidth = lib.mkOption {
      type = lib.types.str;
      example = "34mbit";
      description = "Shaper rate; set slightly below the measured upload so the queue forms here, not in the modem.";
    };
  };

  config = lib.mkIf cfg.enable {
    # fwmark 1-3 selects the diffserv4 tin: 1 = Bulk, 2 = Best Effort, 3 = Video.
    systemd.services.uplink-shaping = {
      description = "CAKE egress shaping on ${cfg.interface}";
      bindsTo = [ device ];
      after = [ device ];
      wantedBy = [
        device
        "multi-user.target"
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.iproute2}/bin/tc qdisc replace dev ${cfg.interface} root cake bandwidth ${cfg.bandwidth} docsis diffserv4 fwmark 0x3";
        ExecStop = "${pkgs.iproute2}/bin/tc qdisc del dev ${cfg.interface} root";
      };
    };
  };
}
