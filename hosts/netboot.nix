{
  config,
  inputs,
  lib,
  modulesPath,
  pkgs,
  ...
}:
let
  fleetWhoami = (
    pkgs.writeShellApplication {
      name = "fleet-whoami";
      runtimeInputs = [ pkgs.jq ];
      text =
        # bash
        ''
          while IFS= read -r mac
          do
            match=$(jq -c -r --arg mac "$mac" '.[$mac] // empty' </etc/fleet/nodes.json)
            if [ -n "$match" ]; then
              echo "$match"
              exit 0
            fi
          done < <(cat /sys/class/net/*/address | sed '/^$/d')
          exit 1
        '';
    }
  );
  fleetWhoamiExe = lib.getExe fleetWhoami;
in
{
  imports = [
    "${modulesPath}/installer/netboot/netboot-minimal.nix"
    inputs.self.modules.nixos.me
    inputs.self.modules.nixos.fleet
  ];

  users.users.root.openssh.authorizedKeys.keyFiles = [ ../keys/andy-ed25519.pub ];

  environment.etc."fleet/nodes.json".text =
    config.fleet.nodes
    |> lib.mapAttrs' (
      name: node: {
        name = node.mac;
        value =
          let
            nodeBuild = inputs.self.nixosConfigurations.${name}.config.system.build;
          in
          {
            inherit name;
            toplevel = "${builtins.unsafeDiscardStringContext nodeBuild.toplevel}";
            diskoScript = "${builtins.unsafeDiscardStringContext nodeBuild.diskoScript}";
          };
      }
    )
    |> builtins.toJSON;

  environment.systemPackages = [
    fleetWhoami
  ];

  systemd.services.installer = {
    wantedBy = [
      "multi-user.target"
    ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    path = [
      config.nix.package
      config.system.build.nixos-install
      pkgs.jq
    ];
    script = ''
      node=$(${fleetWhoamiExe})

      toplevel=$(echo "$node" | jq -r ".toplevel")
      diskoScript=$(echo "$node" | jq -r ".diskoScript")

      nix-store --realize "$diskoScript"
      "$diskoScript"

      nixos-install --system "$toplevel" --no-root-password

      reboot
    '';
    serviceConfig = {
      ExecCondition = fleetWhoamiExe;
      Type = "oneshot";
      StandardOutput = "journal+console";
    };
    unitConfig.ConditionKernelCommandLine = "fleet.wipe";
  };

  nix.settings = {
    substituters = [ "http://router:5000" ];
    require-sigs = false;
  };

  netboot.squashfsCompression = "zstd -Xcompression-level 3";

  system.stateVersion = "26.05";
}
