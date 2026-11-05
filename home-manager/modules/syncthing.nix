{ ... }:
{
  services.syncthing = {
    enable = true;
    settings.options = {
      globalAnnounceEnabled = false;
      relaysEnabled = false;
      urAccepted = -1;
    };
  };
}
