{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
let
  routerIp = "10.0.10.1";
  subnet = "10.0.10.0/24";
in
{
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
    inputs.self.modules.nixos.base
    inputs.self.modules.nixos.fleet
    inputs.self.modules.nixos.headless
    inputs.self.modules.nixos.pxe
  ];

  environment.systemPackages = with pkgs; [
    arp-scan
    dig
    nmap
    tcpdump
  ];

  networking = {
    hostName = "router";
    nat = {
      enable = true;
      externalInterface = "eno1";
      internalInterfaces = [ "enp1s0" ];
    };
    nftables.enable = true;
    useDHCP = false;
    useNetworkd = true;
    firewall.interfaces.enp1s0 = {
      allowedTCPPorts = [
        22 # SSH
        53 # DNS
        5000 # harmonia
      ];
      allowedUDPPorts = [
        53 # DNS
        67 # DHCP
      ];
    };
  };

  systemd.network = {
    enable = true;
    networks.wan = {
      name = "eno1";
      DHCP = "yes";
      dhcpV4Config.RequestAddress = "192.168.1.155";
    };
    networks.management = {
      name = "enp1s0";
      address = [ "${routerIp}/24" ];
      linkConfig.RequiredForOnline = "no";
      dns = [ routerIp ];
      domains = [
        "home.arpa"
        "~10.in-addr.arpa"
      ];
    };
  };

  services.meshcentral.enable = true;

  services.kea.dhcp4 = {
    enable = true;
    settings = {
      interfaces-config = {
        interfaces = [ "enp1s0" ];
      };
      match-client-id = false;
      subnet4 = [
        {
          id = 1;
          subnet = subnet;
          pools = [
            { pool = "10.0.10.150 - 10.0.10.240"; }
          ];
          reservations = lib.mapAttrsToList (_: d: {
            hw-address = d.mac;
            ip-address = d.ip;
          }) config.fleet.devices;
          option-data = [
            {
              name = "routers";
              data = routerIp;
            }
            {
              name = "domain-name-servers";
              data = routerIp;
            }
            {
              name = "domain-search";
              data = "home.arpa";
            }
          ];
        }
      ];
      valid-lifetime = 3600;
    };
  };

  services.unbound = {
    enable = true;
    checkconf = true;
    settings = {
      server = {
        interface = [
          routerIp
          "127.0.0.1"
        ];
        access-control = [
          "${subnet} allow"
          "127.0.0.0/8 allow"
        ];
        local-zone = ''"home.arpa." static'';
        local-data = lib.mapAttrsToList (
          _: d: ''"${d.name}.home.arpa. 3600 IN A ${d.ip}"''
        ) config.fleet.devices;
        local-data-ptr = lib.mapAttrsToList (
          _: d: ''"${d.ip} 3600 ${d.name}.home.arpa."''
        ) config.fleet.devices;
      };
      forward-zone = [
        {
          name = ".";
          forward-addr = [
            "1.1.1.1@853#cloudflare-dns.com"
            "1.0.0.1@853#cloudflare-dns.com"
          ];
          forward-tls-upstream = "yes";
        }
      ];
    };
  };

  pxe = {
    firewallInterfaces = [ "enp1s0" ];
    wipe = true;
  };

  services.pixiecore = {
    dhcpNoBind = true;
    listen = config.fleet.router.ip;
  };

  services.harmonia.cache.enable = true;

  system.extraDependencies =
    config.fleet.nodes
    |> builtins.attrNames
    |> lib.concatMap (
      name:
      let
        nodeBuild = inputs.self.nixosConfigurations.${name}.config.system.build;
      in
      [
        nodeBuild.toplevel
        nodeBuild.diskoScript
      ]
    );

  system.stateVersion = "26.05";
}
