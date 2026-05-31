{ config, pkgs-unstable, ... }:
{
  hardware = {
    nvidia = {
      modesetting.enable = true;
      # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
      # Enable this if you have graphical corruption issues or application crashes after waking
      # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
      # of just the bare essentials.
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      open = true;
      nvidiaSettings = true;
      package = (pkgs-unstable.linuxPackagesFor config.boot.kernelPackages.kernel).nvidiaPackages.latest;
    };

    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    # Enable OpenGL
    graphics = {
      enable = true;
    };
  };
}
