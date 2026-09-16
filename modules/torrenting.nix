{
  config,
  pkgs,
  lib,
  ...
}:
let
  netns = "vpn";
  qbittorrentWebuiPort = 4292;
  downloadPath = "/mnt/media/Seeding";
in
{
  users = {
    groups = {
      media = { };
      unpackerr = { };
    };
    users = {
      andy = {
        extraGroups = [ "media" ];
      };
      plex = {
        extraGroups = [ "media" ];
      };
      qbittorrent = {
        extraGroups = [ "media" ];
      };
      unpackerr = {
        extraGroups = [ "media" ];
        group = "unpackerr";
        isSystemUser = true;
      };
    };
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ qbittorrentWebuiPort ];

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
          Password_PBKDF2 = "@ByteArray(vLgY97a9ORuU9WjrDlDf0g==:Vu9xMEOIxpDYZ5f/yGb9Q1O0DmGDBmAOFlbMVzynHkiiWqE+uC2IbBOyo8x66JH0CglfLNrrg9+vDedTMmVV6w==)";
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
    wants = [
      "netns@${netns}.service"
      "wg-proton.service"
      "proton-port-forwarding.service"
    ];
    serviceConfig =
      let
        injectForwardedPort =
          pkgs.writers.writeBash "inject-forwarded-port"
            {
              makeWrapperArgs = [
                "--prefix"
                "PATH"
                ":"
                "${lib.makeBinPath [ pkgs.busybox ]}"
              ];
            }
            ''
              port=$(cat /run/proton-forwarded-port)
              echo "Editing /var/lib/qBittorrent/qBittorrent/config/qBittorrent.conf with forwarded port."
              sed -E -i \
                -e "s/Session\\\Port=[0-9]*/Session\\\Port=$port/" \
                -e "s/PortRangeMax=[0-9]*/PortRangeMax=$port/" \
                -e "s/PortRangeMin=[0-9]*/PortRangeMin=$port/" \
                /var/lib/qBittorrent/qBittorrent/config/qBittorrent.conf
            '';
      in
      {
        User = "qbittorrent";
        Group = lib.mkForce "media";
        NetworkNamespacePath = "/var/run/netns/${netns}";
        UMask = "0002";
        BindReadOnlyPaths = [ "/etc/netns/${netns}/resolv.conf:/etc/resolv.conf:norbind" ];
        ExecStartPre = lib.mkIf config.modules.vpn.enable (
          lib.mkAfter [
            "${injectForwardedPort}"
          ]
        );
      };
  };

  services.plex.enable = true;
  systemd.services.plex = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };

  systemd.services.unpackerr = {
    description = "unpackerr service";
    bindsTo = [ "wg-proton.service" ];
    after = [
      "network-online.target"
      "wg-proton.service"
    ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    environment =
      let
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
          UN_RADARR_0_API_KEY = "filepath:${config.sops.secrets."radarr_api_key".path}";
          UN_RADARR_0_PATHS_0 = downloadPath;
          UN_RADARR_0_PROTOCOLS = "torrent";
        };
      in
      globalVars // radarrVars;

    serviceConfig = {
      Type = "simple";
      User = "unpackerr";
      Group = "media";
      TimeoutStopSec = "5min";
      NetworkNamespacePath = "/var/run/netns/${netns}";
      ExecStart = "${pkgs.unpackerr}/bin/unpackerr";
    };
  };

  systemd.services.qbittorrent-bridge = {
    description = "Tailnet bridge for qBittorrent (port ${toString qbittorrentWebuiPort})";
    wantedBy = [ "multi-user.target" ];
    after = [
      "wg-proton.service"
      "qbittorrent.service"
    ];
    wants = [
      "wg-proton.service"
      "qbittorrent.service"
    ];
    serviceConfig = {
      ExecStart = pkgs.writeShellScript "qbittorrent-bridge" ''
        exec ${pkgs.socat}/bin/socat \
          TCP6-LISTEN:${toString qbittorrentWebuiPort},fork,reuseaddr,ipv6only=0 \
          EXEC:"${pkgs.iproute2}/bin/ip netns exec ${netns} ${pkgs.socat}/bin/socat - TCP\:127.0.0.1\:${toString qbittorrentWebuiPort}"
      '';
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  systemd.services."proton-port-forwarding" = lib.mkIf config.modules.vpn.enable {
    description = "Acquire incoming port from protonvpn natpmp and update qBittorrent.";
    after = [ "wg-proton.service" ];
    bindsTo = [ "wg-proton.service" ];
    partOf = [ "qbittorrent.service" ];
    serviceConfig = {
      NetworkNamespacePath = "/var/run/netns/${config.modules.vpn.netns}";
      User = "root";
      ExecStartPre = pkgs.writers.writeBash "aquire-and-set-port" ''
        port=$(
          (${pkgs.libnatpmp}/bin/natpmpc -a 1 0 udp 60 -g ${config.modules.vpn.dns} && ${pkgs.libnatpmp}/bin/natpmpc -a 1 0 tcp 60 -g ${config.modules.vpn.dns}) |
            ${pkgs.busybox}/bin/grep -E "^Mapped public port ([0-9]+).*" |
            ${pkgs.busybox}/bin/sed -E "s/^[^0-9]*([0-9]+).+/\1/" |
            ${pkgs.busybox}/bin/uniq
        )
        ${pkgs.busybox}/bin/echo "Acquired port $port, writing to /run/proton-forwarded-port."
        echo $port > /run/proton-forwarded-port
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
}
