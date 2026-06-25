{ config, lib, ... }:
{
  options.modules.wireless = with lib; {
    enable = mkEnableOption "wireless networking";
    secretsFile = mkOption {
      type = types.str;
      description = "Secrets file with PSK passphrase.";
    };
    networks = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            ssid = mkOption {
              type = types.str;
              description = "SSID of the network.";
            };
            pskRaw = mkOption {
              type = types.str;
              description = "Name of the PSK in the form of ext:{var_name}.";
            };
          };
        }
      );
      default = [ ];
      description = "List of networks.";
    };
  };

  config = lib.mkIf config.modules.wireless.enable {
    networking.wireless = {
      enable = true;
      userControlled = true;
      extraConfig = "ctrl_interface=DIR=/run/wpa_supplicant GROUP=wpa_supplicant";
      fallbackToWPA2 = false;
      secretsFile = config.modules.wireless.secretsFile;
      networks = lib.genAttrs' config.modules.wireless.networks (
        nw:
        lib.nameValuePair nw.ssid {
          pskRaw = nw.pskRaw;
        }
      );
    };
  };
}
