{ inputs, ... }:
{
  flake.modules.nixos.base = {
    imports = [
      inputs.self.modules.nixos.limine
      inputs.self.modules.nixos.login-shell
      inputs.self.modules.nixos.me
      inputs.self.modules.nixos.nixpkgs
      inputs.self.modules.nixos.remote-access
    ];
  };
}
