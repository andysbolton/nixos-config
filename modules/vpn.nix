{ lib, pkgs, config, ... }: {
  options.modules.vpn = {
    enable = lib.mkEnableOption "the ProtonVPN WireGuard setup.";

    dns = lib.mkOption {
      type = lib.types.str;
      description = "DNS server IP address to use within the VPN.";
    };

    ip = lib.mkOption {
      type = lib.types.str;
      description = "IP address to assign to the WireGuard interface.";
    };

    netns = lib.mkOption {
      type = lib.types.str;
      description = "Name of the network namespace to use with the VPN.";
    };

    wgConfPath = lib.mkOption {
      type = lib.types.path;
      description = "Path to the WireGuard configuration file.";
    };
  };

  config = lib.mkIf config.modules.vpn.enable {
    # Create the network namespace service
    systemd.services."netns@" = {
      description = "%I network namespace";
      before = [ "network.target" ];
      # Adding partOf ensures that if wg-proton stops,
      # this unit is considered for stopping as well
      partOf = [ "wg-proton.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.iproute2}/bin/ip netns add %I";
        ExecStop = "${pkgs.iproute2}/bin/ip netns del %I";
      };
    };

    systemd.services.wg-proton = {
      description = "wg network interface (proton)";
      requires = [ "network-online.target" ];
      bindsTo = [ "netns@${config.modules.vpn.netns}.service" ];
      after = [ "netns@${config.modules.vpn.netns}.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = with pkgs;
          writers.writeBash "wg-up" ''
            set -e

            ${iproute2}/bin/ip link add wg0 type wireguard
            ${iproute2}/bin/ip link set wg0 netns ${config.modules.vpn.netns}
            # ${iproute2}/bin/ip --netns ${config.modules.vpn.netns} link set dev wg0 mtu 1280
            ${iproute2}/bin/ip --netns ${config.modules.vpn.netns} address add ${config.modules.vpn.ip} dev wg0
            ${iproute2}/bin/ip netns exec ${config.modules.vpn.netns} \
              ${wireguard-tools}/bin/wg setconf wg0 ${config.modules.vpn.wgConfPath}
            # Bring up loopback, as this will allow accessing the localhost application UI
            # (assuming the localhost application and the browser are both in the same netns)
            ${iproute2}/bin/ip --netns ${config.modules.vpn.netns} link set lo up
            ${iproute2}/bin/ip --netns ${config.modules.vpn.netns} link set wg0 up
            ${iproute2}/bin/ip --netns ${config.modules.vpn.netns} route add default dev wg0
          '';
        ExecStop = with pkgs;
          writers.writeBash "wg-down" ''
            ${iproute2}/bin/ip --netns ${config.modules.vpn.netns} route del default dev wg0
            ${iproute2}/bin/ip --netns ${config.modules.vpn.netns} link del wg0
            ${iproute2}/bin/ip link del wg0
          '';
      };
    };

    systemd.services."proton-port-forwarding" = {
      enable = true;
      description =
        "Acquire incoming port from protonvpn natpmp and update qBittorrent.";
      after = [ "wg-proton.service" ];
      bindsTo = [ "wg-proton.service" ];
      partOf = [ "qbittorrent.service" ];
      serviceConfig = {
        NetworkNamespacePath = "/run/netns/${config.modules.vpn.netns}";
        User = "root";
        ExecStartPre = pkgs.writers.writeBash "aquire-and-set-port" ''
          port=$(
            (${pkgs.libnatpmp}/bin/natpmpc -a 1 0 udp 60 -g ${config.modules.vpn.dns} && ${pkgs.libnatpmp}/bin/natpmpc -a 1 0 tcp 60 -g ${config.modules.vpn.dns}) |
              ${pkgs.busybox}/bin/grep -E "^Mapped public port ([0-9]+).*" |
              ${pkgs.busybox}/bin/sed -E "s/^[^0-9]*([0-9]+).+/\1/" |
              ${pkgs.busybox}/bin/uniq
          )
          ${pkgs.busybox}/bin/echo "Acquired port $port."
          ${pkgs.busybox}/bin/echo "Editing /var/lib/qBittorrent/qBittorrent/config/qBittorrent.conf with forwarded port."
          ${pkgs.busybox}/bin/sed -E -i \
            -e "s/Session\\\Port=[0-9]*/Session\\\Port=$port/" \
            -e "s/PortRangeMax=[0-9]*/PortRangeMax=$port/" \
            -e "s/PortRangeMin=[0-9]*/PortRangeMin=$port/" \
            /var/lib/qBittorrent/qBittorrent/config/qBittorrent.conf
        '';
        ExecStart = pkgs.writers.writeBash "keep-port-open" ''
          ${pkgs.busybox}/bin/echo "Starting port loop."
          while true; do
            (${pkgs.libnatpmp}/bin/natpmpc -a 1 0 udp 60 -g ${config.modules.vpn.dns} && ${pkgs.libnatpmp}/bin/natpmpc -a 1 0 tcp 60 -g ${config.modules.vpn.dns}) > /dev/null
            ${pkgs.busybox}/bin/sleep 45
          done
        '';
        Type = "simple";
        Restart = "on-failure";
      };
    };
  };
}
