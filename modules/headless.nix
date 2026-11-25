{
  flake.modules.nixos.headless = {
    # Disable so interactive login isn't necessary.
    security.sudo.wheelNeedsPassword = false;

    systemd.targets = {
      sleep.enable = false;
      suspend.enable = false;
      hibernate.enable = false;
      hybrid-sleep.enable = false;
    };
  };
}
