{ lib, pkgs, config, ... }:
{
  options.modules.monitoring = {
    enable = lib.mkEnableOption "local Prometheus + Grafana stack for hardware sensor history.";
  };

  config = lib.mkIf config.modules.monitoring.enable {
    services.prometheus.exporters.node = {
      enable = true;
      enabledCollectors = [ "hwmon" ];
      listenAddress = "127.0.0.1";
    };

    services.prometheus = {
      enable = true;
      listenAddress = "127.0.0.1";
      retentionTime = "90d";
      scrapeConfigs = [
        {
          job_name = "node";
          static_configs = [
            { targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ]; }
          ];
        }
      ];
    };

    systemd.services.grafana.preStart = lib.mkAfter ''
      secret_key="${config.services.grafana.dataDir}/secret_key"
      [ -f "$secret_key" ] || ${pkgs.openssl}/bin/openssl rand -hex 32 > "$secret_key"
      chmod 0600 "$secret_key"
    '';

    services.grafana = {
      enable = true;
      settings.server = {
        http_addr = "127.0.0.1";
        http_port = 3000;
      };
      settings.security.secret_key = "$__file{${config.services.grafana.dataDir}/secret_key}";
      provision = {
        enable = true;
        datasources.settings.datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            url = "http://127.0.0.1:${toString config.services.prometheus.port}";
            isDefault = true;
          }
        ];
      };
    };
  };
}
