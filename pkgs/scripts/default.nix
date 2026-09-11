{
  lib,
  stdenv,
  writeShellApplication,
  azureCli ? null,
  bat,
  claude-code,
  coreutils,
  fd,
  firefox,
  fzf,
  gawk,
  jira-cli-go,
  jq,
  python3,
  sqlite,
  wl-clipboard,
  yabai,
}:

let
  binDir = ./.;

  python3WithGio = python3.withPackages (ps: [ ps.pygobject3 ]);

  mkScript =
    name: runtimeInputs:
    writeShellApplication {
      inherit name runtimeInputs;
      bashOptions = [ ];
      text = builtins.readFile (binDir + "/${name}.sh");
    };

  # Consumed by the launchers, never invoked directly.
  catalogs = {
    azure-resource-types = mkScript "azure-resource-types" (
      [
        coreutils
        jq
      ]
      ++ lib.optional (azureCli != null) azureCli
    );
    bookmarks = mkScript "bookmarks" [
      coreutils
      sqlite
    ];
    mac-apps = mkScript "mac-apps" [
      coreutils
      fd
    ];
    nixos-apps = mkScript "nixos-apps" [ python3WithGio ];
  };

  yabai-spaces = mkScript "yabai-spaces" [
    fzf
    gawk
    jq
    yabai
  ];
in
catalogs
// {
  inherit yabai-spaces;

  ask-claude = mkScript "ask-claude" [
    bat
    claude-code
    coreutils
  ];

  mac-launcher = mkScript "mac-launcher" (
    (lib.attrValues (builtins.removeAttrs catalogs [ "nixos-apps" ]))
    ++ [
      coreutils
      fzf
      jira-cli-go
      jq
      yabai-spaces
    ]
  );

  nixos-launcher = mkScript "nixos-launcher" [
    coreutils
    catalogs.bookmarks
    catalogs.nixos-apps
    firefox
    fzf
  ];

  search-nix-pkgs = mkScript "search-nix-pkgs" (
    [
      coreutils
      fzf
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [ wl-clipboard ]
  );
}
