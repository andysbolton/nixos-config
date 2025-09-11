{ config, pkgs, ... }:
let
  netns = "vpn";
  ip = "10.2.0.2/32";
  dns = "10.2.0.1";
  wgConfPath = config.sops.secrets."proton-vpn.conf".path;
  qbittorrentWebuiPort = 4292;
in {
  services.qbittorrent = {
    enable = true;
    webuiPort = qbittorrentWebuiPort;
    serverConfig = {
      LegalNotice.Accepted = true;
      Preferences = {
        WebUI = {
          Username = "admin";
          Password_PBKDF2 =
            "@ByteArray(vLgY97a9ORuU9WjrDlDf0g==:Vu9xMEOIxpDYZ5f/yGb9Q1O0DmGDBmAOFlbMVzynHkiiWqE+uC2IbBOyo8x66JH0CglfLNrrg9+vDedTMmVV6w==)";
        };

        General.Locale = "en";

        Connection = {
          PortRangeMin = 46130;
          PortRangeMax = 46130;
          UPnP = false;
          RandomPort = false;
          Interface = "wg0";
        };
      };
    };
  };

  systemd.services.qbittorrent = {
    after = [ "netns@${netns}.service" "wg-proton.service" ];
    bindsTo = [ "netns@${netns}.service" "wg-proton.service" ];
    serviceConfig = {
      NetworkNamespacePath = "/run/netns/${netns}";
      BindReadOnlyPaths =
        [ "/etc/netns/${netns}/resolv.conf:/etc/resolv.conf:norbind" ];
    };
  };

  services.radarr = { enable = true; };
  systemd.services.radarr = {
    after = [ "netns@${netns}.service" "wg-proton.service" ];
    bindsTo = [ "netns@${netns}.service" "wg-proton.service" ];
    serviceConfig = { NetworkNamespacePath = "/run/netns/${netns}"; };
  };

  # Create the network namespace service
  systemd.services."netns@" = {
    description = "%I network namespace";
    before = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.iproute2}/bin/ip netns add %I";
      ExecStop = "${pkgs.iproute2}/bin/ip netns del %I";
    };
  };

  systemd.services.wg-proton = {
    description = "wg network interface (proton)";
    bindsTo = [ "netns@${netns}.service" ];
    requires = [ "network-online.target" ];
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
          # Bring up loopback, as this will allow accessing the qbittorrent web UI on localhost
          # (assuming qbittorent and the browser are both in the same netns)
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

  environment.etc."netns/${netns}/resolv.conf".text = "nameserver ${dns}";

  programs.firejail = {
    enable = true;
    wrappedBinaries = {
      firefox = {
        executable = "${pkgs.firefox}/bin/firefox";
        extraArgs = [
          "--netns=${netns}"
          # https://github.com/netblue30/firejail/issues/6843
          # Running with no profile to remove grapical corruption without disabling hardware acceleration.
          # Let's revisit this later.
          "--profile=noprofile"
        ];
      };
    };
  };
}
