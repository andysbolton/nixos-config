{
  inputs,
  lib,
  osConfig,
  ...
}:
let
  # Per-host TLS cert fingerprints for lan-mouse cross-authentication.
  # Get each host's fingerprint with:
  #   openssl x509 -in ~/.config/lan-mouse/lan-mouse.pem -fingerprint -sha256 -noout \
  #     | sed 's/.*=//' | tr 'A-Z' 'a-z'
  fingerprints = {
    # main     = "aa:bb:...";
    # portable = "cc:dd:...";
    # work     = "ee:ff:...";
  };

  me = osConfig.networking.hostName;
  others = lib.filterAttrs (n: _: n != me) fingerprints;

  # Per-host topology — who's adjacent to whom, from each host's perspective.
  topology = {
    main = [
      {
        position = "left";
        hostname = "work";
        activate_on_startup = true;
        ips = [ ];
      }
    ];
    work = [
      {
        position = "right";
        hostname = "main";
        activate_on_startup = true;
        ips = [ ];
      }
    ];
    portable = [ ];
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
}
