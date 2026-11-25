{
  inputs,
  ...
}:
let
  netbootConfig = inputs.self.nixosConfigurations.netboot.config;
  netbootBuild = netbootConfig.system.build;
in
{
  flake.modules.nixos.pxe = { config, lib, ... }: {
    options.pxe.firewallInterfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Interfaces for which to open firewall ports.";
    };

    options.pxe.wipe = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to wipe the disks and install the OS.";
    };

    config = {
      services.pixiecore = {
        enable = true;
        openFirewall = false;
        kernel = "${netbootBuild.kernel}/bzImage";
        cmdLine = "init=${netbootBuild.toplevel}/init ${toString netbootConfig.boot.kernelParams}${
          if config.pxe.wipe then " fleet.wipe" else ""
        }";
        initrd = "${netbootBuild.netbootRamdisk}/initrd";
      };

      networking.firewall.interfaces = lib.genAttrs config.pxe.firewallInterfaces (i: {
        allowedTCPPorts = [
          config.services.pixiecore.port
        ];
        allowedUDPPorts = [
          67
          69
          4011
        ];
      });
    };
  };
}
