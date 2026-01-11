{ lib, config, ... }: {
  config = {
    users.users.radarr.extraGroups = [ "media" ];
    services.radarr.enable = true;
    systemd.services.radarr = {
      after =
        [ "netns@${config.modules.vpn.netns}.service" "wg-proton.service" ];
      bindsTo =
        [ "netns@${config.modules.vpn.netns}.service" "wg-proton.service" ];
      partOf =
        [ "netns@${config.modules.vpn.netns}.service" "wg-proton.service" ];
      serviceConfig.NetworkNamespacePath =
        "/run/netns/${config.modules.vpn.netns}";
    };
  };
}
