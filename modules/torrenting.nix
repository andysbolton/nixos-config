{ config, pkgs, lib, ... }:
let
  netns = "vpn";
  dns = "10.2.0.1";
  qbittorrentWebuiPort = 4292;
  downloadPath = "/mnt/media/Seeding";
in {
  users.groups.media = { };
  users.groups.unpackerr = { };
  users.users.andy.extraGroups = [ "media" ];
  users.users.plex.extraGroups = [ "media" ];
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
