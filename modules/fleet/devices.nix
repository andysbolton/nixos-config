{ config, lib, ... }:
let
  deviceModule =
    { name, ... }:
    {
      options = {
        name = lib.mkOption {
          type = lib.types.str;
          default = name;
        };
        mac = lib.mkOption { type = lib.types.str; };
        ip = lib.mkOption { type = lib.types.str; };
        type = lib.mkOption { type = lib.types.str; };
      };
    };

  deviceType = lib.types.submodule deviceModule;

  deviceOfType =
    type:
    lib.types.submodule [
      deviceModule
      { type = type; }
    ];

  options = {
    router = lib.mkOption {
      type = deviceOfType "router";
      readOnly = true;
    };
    switch = lib.mkOption {
      type = deviceOfType "switch";
      readOnly = true;
    };
    nodes = lib.mkOption {
      type = lib.types.attrsOf (deviceOfType "node");
      readOnly = true;
    };
    devices = lib.mkOption {
      type = lib.types.attrsOf deviceType;
      readOnly = true;
      description = "All devices in my homelab.";
    };
  };
in
{
  options.fleet = options;

  config = {
    fleet = {
      router = {
        mac = "00:a0:c9:a1:1e:5c";
        ip = "10.0.10.1";
      };
      switch = {
        mac = "e0:d3:62:56:01:40";
        ip = "10.0.10.100";
      };
      nodes = {
        node1 = {
          mac = "e8:6a:64:ef:2c:8b";
          ip = "10.0.10.101";
        };
        node2 = {
          mac = "e8:6a:64:ff:ee:f8";
          ip = "10.0.10.102";
        };
        node3 = {
          mac = "98:fa:9b:00:29:c6";
          ip = "10.0.10.103";
        };
      };
      devices = {
        router = config.fleet.router;
        switch = config.fleet.switch;
      }
      // config.fleet.nodes;
    };

    flake.modules.nixos.fleet = {
      options.fleet = options // {
        device = lib.mkOption {
          type = deviceType;
          readOnly = true;
          description = "The current device.";
        };
      };

      config.fleet = config.fleet;
    };
  };
}
