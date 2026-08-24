{ pkgs, modulesPath, ... }:
let
  serialTty = if pkgs.stdenv.hostPlatform.isAarch64 then "ttyAMA0" else "ttyS0";
in
{
  imports = [
    "${modulesPath}/profiles/minimal.nix"
    "${modulesPath}/profiles/qemu-guest.nix"
  ];

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

  # macOS MagicDNS is a scoped resolver file (/etc/resolver/ts.net) that slirp's
  # DNS proxy never reads, so aim *.ts.net at tailscaled's quad100 listener.
  # Routing needs no tailscale in the guest: slirp traffic exits as Mac
  # connections and the Mac routes 100.x via tailscaled.
  networking.nameservers = [ "100.100.100.100" ];
  services.resolved.settings.Resolve.Domains = [ "~ts.net" ];

  # dhcpcd intermittently fails to start in this minimal image (boots race:
  # sometimes full network, sometimes none). networkd is deterministic here.
  networking.useNetworkd = true;
  networking.useDHCP = true;
  services.qemuGuest.enable = true;

  # Debug shell in the host terminal: jetkvm-kiosk -serial mon:stdio
  # (full scrollback/copy-paste; Ctrl+A x quits qemu, Ctrl+A c toggles monitor)
  systemd.services."serial-getty@${serialTty}" = {
    enable = true;
    wantedBy = [ "multi-user.target" ];
  };

  system.stateVersion = "25.05";
}
