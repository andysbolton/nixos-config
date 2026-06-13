{
  inputs,
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  # Per-host TLS cert fingerprints for lan-mouse cross-authentication.
  # Get each host's fingerprint with:
  #   openssl x509 -in $XDG_CONFIG_HOME/lan-mouse/lan-mouse.pem -fingerprint -sha256 -noout \
  #     | sed 's/.*=//' | tr 'A-Z' 'a-z'
  fingerprints = {
    work = "87:94:13:86:65:a8:14:bb:25:a9:e7:25:90:ee:e9:71:d6:a2:56:bc:e1:3a:1b:49:1e:dd:ae:03:ac:7a:4d:32";
    main = "1e:98:e7:f3:05:ab:f5:a9:87:47:af:32:c3:41:f8:df:fc:71:b9:f9:87:d9:32:b1:fe:ae:21:a1:62:3c:3e:b1";
    portable = "6e:a8:6d:1b:c4:a9:47:7c:7c:8a:ed:66:4c:ee:f4:6d:95:67:6a:18:f8:67:27:24:dc:6d:37:ef:b4:cd:eb:50";
  };

  me = osConfig.networking.hostName;
  others = lib.filterAttrs (n: _: n != me) fingerprints;

  karabiner = "/opt/homebrew/bin/karabiner_cli";

  darwinEnterHook = ''
    pbpaste | ssh portable "env (systemctl --user show-environment | grep ^WAYLAND_DISPLAY=) wl-copy >/dev/null 2>&1"

    "${karabiner}" --select-profile empty || exit 0

    trap '"${karabiner}" --select-profile work' EXIT

    tail -n0 -F /tmp/lan-mouse.err.log | grep -m1 -E "releasing capture"
  '';

  linuxEnterHook = ''
    ${pkgs.wl-clipboard}/bin/wl-paste | ssh work "pbcopy"

    input=$(${pkgs.river-classic}/bin/riverctl list-inputs | grep -i "pointer.*mx_anywhere")

    ${pkgs.river-classic}/bin/riverctl input "$input" natural-scroll enabled

    trap '${pkgs.river-classic}/bin/riverctl input "$input" natural-scroll disabled' EXIT

    journalctl --user -u lan-mouse.service -n0 -f -o cat | grep -m1 -E "releasing capture"
  '';

  # darwinToLinuxCopy = ''
  #   pbpaste | ssh
  # '';

  topology = {
    main = [
      {
        position = "left";
        hostname = "work.tail4b1b78.ts.net";
        activate_on_startup = true;
        ips = [ "100.93.122.89" ];
      }
    ];
    work = [
      {
        position = "left";
        hostname = "portable.tail4b1b78.ts.net";
        activate_on_startup = true;
        ips = [ "100.127.37.90" ];
        enter_hook = darwinEnterHook;
      }
      # {
      #   position = "right";
      #   hostname = "main.tail4b1b78.ts.net";
      #   activate_on_startup = true;
      #   ips = [ "100.69.169.2" ];
      #   enter_hook = darwinEnterHook;
      # }
    ];
    portable = [
      {
        position = "right";
        hostname = "work.tail4b1b78.ts.net";
        activate_on_startup = true;
        ips = [ "100.93.122.89" ];
        enter_hook = linuxEnterHook;
      }
    ];
  };
in
{
  imports = [ inputs.lan-mouse.homeManagerModules.default ];
  programs.lan-mouse = {
    enable = true;
    settings = {
      release_bind = [
        "KeyA"
        "KeyS"
        "KeyD"
        "KeyF"
      ];
      port = 4242;
      frontend = "cli";
      authorized_fingerprints = lib.mapAttrs' (n: v: lib.nameValuePair v n) others;
      clients = topology.${me} or [ ];
    };
  };

  launchd.agents.lan-mouse.config = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    StandardOutPath = "/tmp/lan-mouse.log";
    StandardErrorPath = "/tmp/lan-mouse.err.log";
  };
}
