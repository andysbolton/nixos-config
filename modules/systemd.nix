{ pkgs, ... }:
{
  systemd = {
    user.services.lan-mouse = {
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      description = "lan-mouse (mouse and keyboard sharing)";
      serviceConfig = {
        ExecStart = ''${pkgs.lan-mouse}/bin/lan-mouse --daemon'';
        Restart = "on-failure";
      };
    };
  };
}
