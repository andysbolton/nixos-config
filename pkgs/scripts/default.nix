{
  lib,
  stdenv,
  writeShellApplication,
  bat,
  claude-code,
  coreutils,
  fd,
  fzf,
  gawk,
  jira-cli-go,
  jq,
  perl,
  sqlite,
  wl-clipboard,
  yabai,
}:

let
  binDir = ./.;

  mkScript =
    name: runtimeInputs:
    writeShellApplication {
      inherit name runtimeInputs;
      bashOptions = [ ];
      text = builtins.readFile (binDir + "/${name}.sh");
    };

  # Consumed by the launchers, never invoked directly.
  catalogs = {
    apps = mkScript "apps" [
      coreutils
      fd
    ];
    azure-resource-types = mkScript "azure-resource-types" [
      coreutils
      jq
    ];
    bookmarks = mkScript "bookmarks" [
      coreutils
      gawk
      perl
      sqlite
    ];
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
    (lib.attrValues catalogs)
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
