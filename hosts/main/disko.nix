{ lib, ... }:
{
  # A build-vm guest has no such partition, and systemd initrd waits for it.
  virtualisation.vmVariant.boot.resumeDevice = lib.mkVMOverride "";

  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            swap = {
              size = "16G";
              content = {
                type = "swap";
                discardPolicy = "both";
                resumeDevice = true; # resume from hiberation from this device
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
      media1 = {
        type = "disk";
        device = "/dev/sda1";
        content = {
          type = "gpt";
          partitions = {
            media = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "xfs";
                mountpoint = "/mnt/media";
                mountOptions = [
                  "defaults"
                  "pquota"
                ];
              };
            };
          };
        };
      };
    };
  };
}
