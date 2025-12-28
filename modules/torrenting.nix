{ config, pkgs, lib, ... }:
let
  netns = "vpn";
  ip = "10.2.0.2/32";
  dns = "10.2.0.1";
  wgConfPath = config.sops.secrets."proton-vpn.conf".path;
  qbittorrentWebuiPort = 4292;
  downloadPath = "/mnt/media/Seeding";
in {
  users.groups.media = { };
  users.groups.unpackerr = { };
  users.users.andy.extraGroups = [ "media" ];
  users.users.plex.extraGroups = [ "media" ];
  users.users.radarr.extraGroups = [ "media" ];
  users.users.qbittorrent.extraGroups = [ "media" ];
  users.users.unpackerr = {
    isSystemUser = true;
    group = "unpackerr";
    extraGroups = [ "media" ];
  };

  services.qbittorrent = {
    enable = true;
    webuiPort = qbittorrentWebuiPort;
    serverConfig = {
      LegalNotice.Accepted = true;

      BitTorrent.Session = {
        QueueingSystemEnabled = false;
        DefaultSavePath = downloadPath;
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
      User = "qbittorrent";
      Group = lib.mkForce "media";
      NetworkNamespacePath = "/run/netns/${netns}";
      UMask = "0002";
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
          ${iproute2}/bin/ip --netns ${netns} link set dev wg0 mtu 1280
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

  systemd.services.unpackerr = {
    description = "unpackerr service";
    bindsTo = [ "wg-proton.service" ];
    after = [ "network-online.target" "wg-proton.service" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    # unitConfig = {
    #   ConditionDirectoryNotEmpty = requiredPaths;
    # };
    environment = let
      # Global settings
      globalVars = {
        UN_DEBUG = "false";
        UN_LOG_FILE = ""; # Log to stdout for container
        UN_LOG_FILES = "0"; # Disable log rotation (container stdout)
        UN_LOG_FILE_MB = "0";
        UN_START_DELAY = "1m";
        UN_RETRY_DELAY = "5m";
        UN_MAX_RETRIES = "3";
        UN_WEBSERVER_METRICS = "true";
        UN_WEBSERVER_LISTEN_ADDR = "0.0.0.0:1819";
        TZ = "America/Mountain";
      };

      # Sonarr configuration (0-indexed for Unpackerr)
      # sonarrVars = {
      #   UN_SONARR_0_URL = cfg.sonarr.url;
      #   UN_SONARR_0_PATHS_0 = cfg.sonarr.path;
      #   UN_SONARR_0_PROTOCOLS = cfg.sonarr.protocols;
      #   UN_SONARR_0_TIMEOUT = cfg.sonarr.timeout;
      #   UN_SONARR_0_DELETE_ORIG = lib.boolToString cfg.sonarr.deleteOrig;
      #   UN_SONARR_0_DELETE_DELAY = cfg.sonarr.deleteDelay;
      #   UN_SONARR_0_SYNCTHING = "false";
      # };

      # Radarr configuration
      radarrVars = {
        UN_RADARR_0_URL = "http://localhost:7878/";
        UN_RADARR_0_API_KEY =
          "filepath:${config.sops.secrets."radarr_api_key".path}";
        UN_RADARR_0_PATHS_0 = downloadPath;
        UN_RADARR_0_PROTOCOLS = "torrent";
      };
    in globalVars // radarrVars;

    serviceConfig = {
      Type = "simple";
      User = "unpackerr";
      Group = "media";
      TimeoutStopSec = "5min";
      NetworkNamespacePath = "/var/run/netns/${netns}";
      ExecStart = "${pkgs.unpackerr}/bin/unpackerr";
    };
  };

  environment.etc."netns/${netns}/resolv.conf".text = "nameserver ${dns}";
}
