{ pkgs, modulesPath, ... }: {
  imports = [ "${modulesPath}/profiles/minimal.nix" ];

  disabledModules = [ "${modulesPath}/profiles/all-hardware.nix" ];

  programs.firefox = {
    enable = true;
    preferences = {
      "app.update.auto" = false;
      "browser.aboutwelcome.enabled" = false;
      "browser.fixup.fallback-to-https" = false;
      "browser.shell.checkDefaultBrowser" = false;
      "browser.startup.homepage_override.mstone" = "ignore";
      "datareporting.healthreport.uploadEnabled" = false;
      "datareporting.policy.dataSubmissionEnabled" = false;
      "extensions.pocket.enabled" = false;
      "signon.rememberSignons" = false;
    };
  };

  services.cage = {
    enable = true;
    user = "kvm";
    program = "${pkgs.firefox}/bin/firefox --kiosk http://jetkvm.tail4b1b78.ts.net";
  };
  users.users.kvm.isNormalUser = true;

  # The guest's DNS can't see MagicDNS (slirp forwards to the Mac's plain
  # resolver, which doesn't know *.ts.net), so pin the device's tailnet IP.
  # Routing needs no tailscale in the guest: slirp traffic exits as Mac
  # connections and the Mac routes 100.x via tailscaled.
  networking.hosts."100.106.162.4" = [ "jetkvm.tail4b1b78.ts.net" ];

  # dhcpcd intermittently fails to start in this minimal image (boots race:
  # sometimes full network, sometimes none). networkd is deterministic here.
  networking.useNetworkd = true;
  networking.useDHCP = true;
  services.qemuGuest.enable = true;

  # Debug shell in the host terminal: jetkvm-kiosk -serial mon:stdio
  # (full scrollback/copy-paste; Ctrl+A x quits qemu, Ctrl+A c toggles monitor)
  systemd.services."serial-getty@ttyAMA0" = {
    enable = true;
    wantedBy = [ "multi-user.target" ];
  };
  environment.systemPackages = [
  ];

  system.stateVersion = "25.05";
}
