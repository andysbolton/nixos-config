{ config, pkgs, ... }:
let
  netns = "vpn";
  ip = "10.2.0.2/32";
  dns = "10.2.0.1";
  wgConfPath = config.sops.secrets."proton-vpn.conf".path;
  qbittorrentWebuiPort = 4292;
in {
  users.groups.media = {};
  users.users.plex.extraGroups = [ "media" ];
  users.users.radarr.extraGroups = [ "media" ];
  users.users.qbittorrent.extraGroups = [ "media" ];

  services.qbittorrent = {
    enable = true;
    webuiPort = qbittorrentWebuiPort;
    serverConfig = {
      LegalNotice.Accepted = true;

      BitTorrent.Session = {
        QueueingSystemEnabled = false;
        DefaultSavePath = "/mnt/media/Seeding";
      };

      Network.PortForwarding.Enabled = false;

      Preferences = {
        WebUI = {
          Username = "admin";
          Password_PBKDF2 =
            "@ByteArray(vLgY97a9ORuU9WjrDlDf0g==:Vu9xMEOIxpDYZ5f/yGb9Q1O0DmGDBmAOFlbMVzynHkiiWqE+uC2IbBOyo8x66JH0CglfLNrrg9+vDedTMmVV6w==)";
        };

        General.Locale = "en";

        Connection = {
          UPnP = false;
          RandomPort = false;
          Interface = "wg0";
          PortRangeMin = "";
          PortRangeMax = "";
        };
      };
    };
  };

  systemd.services.qbittorrent = {
    after = [
      "netns@${netns}.service"
      "wg-proton.service"
      "proton-port-forwarding.service"
    ];
    bindsTo = [
      "netns@${netns}.service"
      "wg-proton.service"
      "proton-port-forwarding.service"
    ];
    partOf = [ 
      "netns@${netns}.service"
      "wg-proton.service"
      "proton-port-forwarding.service"
    ];
    serviceConfig = {
      NetworkNamespacePath = "/run/netns/${netns}";
      BindReadOnlyPaths =
        [ "/etc/netns/${netns}/resolv.conf:/etc/resolv.conf:norbind" ];
    };
  };

  services.plex.enable = true;

  services.radarr.enable = true;
  systemd.services.radarr = {
    after = [ "netns@${netns}.service" "wg-proton.service" ];
    bindsTo = [ "netns@${netns}.service" "wg-proton.service" ];
    partOf = [ "netns@${netns}.service" "wg-proton.service" ];
    serviceConfig.NetworkNamespacePath = "/run/netns/${netns}";
  };

  services.prowlarr.enable = true;
  systemd.services.prowlarr = {
    after = [ "netns@${netns}.service" "wg-proton.service" ];
    bindsTo = [ "netns@${netns}.service" "wg-proton.service" ];
    partOf = [ "netns@${netns}.service" "wg-proton.service" ];
    serviceConfig.NetworkNamespacePath = "/run/netns/${netns}";
  };

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
    bindsTo = [ "netns@${netns}.service" ];
    after = [ "netns@${netns}.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = with pkgs;
        writers.writeBash "wg-up" ''
          set -e

          ${iproute2}/bin/ip link add wg0 type wireguard
          ${iproute2}/bin/ip link set wg0 netns ${netns}
          ${iproute2}/bin/ip --netns ${netns} address add ${ip} dev wg0
          ${iproute2}/bin/ip netns exec ${netns} \
            ${wireguard-tools}/bin/wg setconf wg0 ${wgConfPath}
          # Bring up loopback, as this will allow accessing the localhost application UI
          # (assuming the localhost application and the browser are both in the same netns)
          ${iproute2}/bin/ip --netns ${netns} link set lo up
          ${iproute2}/bin/ip --netns ${netns} link set wg0 up
          ${iproute2}/bin/ip --netns ${netns} route add default dev wg0
        '';
      ExecStop = with pkgs;
        writers.writeBash "wg-down" ''
          ${iproute2}/bin/ip --netns ${netns} route del default dev wg0
          ${iproute2}/bin/ip --netns ${netns} link del wg0
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
      NetworkNamespacePath = "/run/netns/${netns}";
      User = "root";
      ExecStartPre = pkgs.writers.writeBash "aquire-and-set-port" ''
        port=$(
          (${pkgs.libnatpmp}/bin/natpmpc -a 1 0 udp 60 -g ${dns} && ${pkgs.libnatpmp}/bin/natpmpc -a 1 0 tcp 60 -g ${dns}) |
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
          (${pkgs.libnatpmp}/bin/natpmpc -a 1 0 udp 60 -g ${dns} && ${pkgs.libnatpmp}/bin/natpmpc -a 1 0 tcp 60 -g ${dns}) > /dev/null
          ${pkgs.busybox}/bin/sleep 45
        done
      '';
      Type = "simple";
      Restart = "on-failure";
    };
  };

  environment.etc."netns/${netns}/resolv.conf".text = "nameserver ${dns}";
}
