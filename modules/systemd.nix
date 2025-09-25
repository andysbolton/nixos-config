{ pkgs, ... }: {
  # TODO: check out https://github.com/ornicar/dotfiles/blob/c23b91b32fe8d7ec381780136e9ffaefb8adcba4/nix/home/modules/lan-mouse.nix for copy paste and some other options.
  systemd = {
    user.services.lan-mouse = {
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      description = "lan-mouse (mouse and keyboard sharing)";
      serviceConfig = {
        ExecStart = "${pkgs.lan-mouse}/bin/lan-mouse --daemon";
        Restart = "on-failure";
      };
    };
  };
}
