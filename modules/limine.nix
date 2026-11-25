{
  flake.modules.nixos.limine.boot.loader = {
    limine = {
      enable = true;
      maxGenerations = 10;
    };
    efi.canTouchEfiVariables = true;
  };
}
