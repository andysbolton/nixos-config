{ config, lib, ... }:
let
  devices = {
    main = "SAPZNVQ-2JKUUER-WIQUBNX-ZHPSUSK-PBNOQMF-6VHULMD-KIQVTSA-M266VA3";
    portable = "JVST5FR-VECGD66-S4PZX2L-QAA6XEK-XHFEWJB-VZFYQB5-Q66ZZKF-LFLW7AK";
    work = "MLOHC3I-W2DNPJA-VFPV5OC-J2FTFTG-O5OLXK6-J2AFDFO-OZDULFX-42FFVQK";
  };
in
{
  services.syncthing = {
    enable = true;
    settings = {
      options = {
        globalAnnounceEnabled = false;
        relaysEnabled = false;
        urAccepted = -1;
      };
      # Hostnames resolve via Tailscale MagicDNS.
      devices = lib.mapAttrs (name: id: {
        inherit id;
        addresses = [
          "tcp://${name}:22000"
          "dynamic"
        ];
      }) devices;
      folders.org = {
        path = "${config.home.homeDirectory}/org";
        devices = lib.attrNames devices;
      };
    };
  };
}
