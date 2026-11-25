{
  flake.modules.nixos.remote-access = {
    services = {
      eternal-terminal = {
        enable = true;
      };
      openssh = {
        enable = true;
        settings.PasswordAuthentication = false;
      };
      tailscale = {
        enable = true;
        openFirewall = true;
      };
    };

    networking.firewall.trustedInterfaces = [ "tailscale0" ];

    systemd.services.tailscaled = {
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
    };
  };
}
