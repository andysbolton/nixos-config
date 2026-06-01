{ config, lib, ... }:
{
  options.modules.wireless = {
    enable = lib.mkEnableOption "wireless networking";
    ssid = lib.mkOption {
      type = lib.types.str;
    };
    secretsFile = lib.mkOption {
      type = lib.types.path;
    };
  };

  config = lib.mkIf config.modules.wireless.enable {
    networking.wireless = {
      enable = true;
      userControlled = true;
      secretsFile = config.modules.wireless.secretsFile;
      extraConfig = "ctrl_interface=DIR=/run/wpa_supplicant GROUP=wpa_supplicant";
      networks.${config.modules.wireless.ssid} = {
        pskRaw = "ext:psk";
        extraConfig = "disabled=0";
      };
    };
  };
}
