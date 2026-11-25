{
  flake.modules.nixos.login-shell = { pkgs, ... }: {
    programs.fish.enable = true;
    users.defaultUserShell = pkgs.fish;
  };
}
