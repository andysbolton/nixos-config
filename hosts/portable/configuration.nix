{
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ../../modules/theme.nix
    ../../modules/desktop.nix
    ../../modules/steam.nix
    ../../modules/vpn.nix
    ../../modules/wireless.nix
    inputs.sops-nix.nixosModules.sops
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "portable";

  users.users.andy.extraGroups = [
    "wheel"
    "wpa_supplicant"
  ];

  modules.wireless = {
    enable = true;
    secretsFile = config.sops.secrets."wireless.conf".path;
    networks = [
      # clay
      {
        ssid = "Fios-Xj7tG";
        pskRaw = "ext:psk_home";
      }
      # miller
      {
        ssid = "Verizon_S9K9SF";
        pskRaw = "ext:psk_sukh";
      }
      {
        ssid = "Verizon_S9K9SF 2GHz";
        pskRaw = "ext:psk_sukh";
      }
      {
        ssid = "Verizon_BL9V92";
        pskRaw = "ext:psk_sukh_ext";
      }
      # whisper
      {
        ssid = "Hammy 5 GHz";
        pskRaw = "ext:psk_parents";
      }
      # hobbs
      {
        ssid = "LDWP_5G";
        pskRaw = "ext:psk_dougie";
      }
      # gl
      {
        ssid = "GL-MT3000-4f3-5G";
        pskRaw = "ext:psk_gl";
      }
      {
        ssid = "Unitedwifi.com";
      }
    ];
  };

  environment.systemPackages = with pkgs; [
    moonlight-qt
    waypipe
    (writeShellScriptBin "stream-main" ''
      exec ${moonlight-qt}/bin/moonlight stream \
        --video-codec HEVC \
        --video-decoder hardware \
        --fps 60 \
        main "Desktop"
    '')
  ];

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [ intel-media-driver ];
  };

  sops = {
    defaultSopsFile = ../../secrets/portable.yaml;
    defaultSopsFormat = "yaml";
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    gnupg.sshKeyPaths = [ ];
    secrets."wireless.conf" = {
      owner = "wpa_supplicant";
      group = "wpa_supplicant";
      mode = "0440";
    };
    secrets."proton-vpn.conf" = { };
  };

  modules.vpn = {
    enable = true;
    dns = "10.2.0.1";
    ip = "10.2.0.2/32";
    ip6 = "2a07:b944::2:2/128";
    netns = "vpn";
    wgConfPath = config.sops.secrets."proton-vpn.conf".path;
  };

  services.keyd = {
    enable = true;
    keyboards = {
      laptop_keyboard = {
        ids = [ "0001:0001" ];
        settings = {
          main = {
            capslock = "leftcontrol";
            leftcontrol = "capslock";
            sysrq = "leftmeta";
          };
        };
      };
    };
  };

  networking.firewall.trustedInterfaces = [ "tailscale0" ];
  networking.firewall.allowedUDPPorts = [ config.services.tailscale.port ];

  system.stateVersion = "26.05";
}
