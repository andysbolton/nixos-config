{ pkgs, config, ... }:
let systemctl = "${pkgs.systemd}/bin/systemctl --user";
in {
  programs.waybar = {
    enable = true;
    settings = [{
      layer = "top";
      modules-left = [ "river/tags" "river/window" "custom/lan-mouse" ];
      modules-center = [ "clock" ];
      modules-right = [
        "systemd-failed-units"
        "pulseaudio"
        "pulseaudio/slider"
        "disk"
        "memory"
        "cpu"
        "temperature"
        "custom/gpu-utilization"
        "custom/gpu-temperature"
      ];

      clock = {
        interval = 1;
        format = "{:%A, %B %d | %I:%M:%S %Z}";
        tooltip-format = "<tt><small>{calendar}</small></tt>";
      };

      "river/window" = { "max-length" = 70; };

      "river/tags" = {
        "num-tags" = 10;
        "hide-vacant" = true;
      };

      disk = { format = " {used} / {total}"; };

      cpu = {
        format = " {usage} %";
        tooltip = false;
        interval = 1;
      };

      memory = {
        format = " {used:0.1f}G / {total:0.1f}G";
        interval = 1;
      };

      temperature = {
        "hwmon-path" =
          "/sys/devices/platform/nct6687.2592/hwmon/hwmon3/temp1_input";
        interval = 1;
        "critical-threshold" = 80;
        format = " {icon} {temperatureC}°C";
        "format-icons" = [ "" "" "" "" ];
      };

      "custom/gpu-utilization" = {
        exec =
          "/run/current-system/sw/bin/nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader";
        format = "⚙ {}";
        interval = 1;
      };

      "custom/gpu-temperature" = {
        exec =
          "/run/current-system/sw/bin/nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader";
        format = "⚙{icon} {}°C";
        interval = 1;
        "critical-threshold" = 80;
        "format-icons" = [ "" "" "" "" ];
      };

      "custom/lan-mouse" = {
        interval = 5;
        exec = pkgs.writeShellScript "lan-mouse-check" ''
          if ${systemctl} is-active --quiet "lan-mouse.service"; then
            echo " 󰍽 "
          else
            echo " 󰍾 "
          fi
        '';
        format = "{}";
        tooltip-format = "LAN Mouse";
        on-click = pkgs.writeShellScript "lan-mouse-toggle" ''
          if ${systemctl} is-active --quiet "lan-mouse.service"; then
            ${systemctl} stop "lan-mouse.service"
          else
            ${systemctl} start "lan-mouse.service"
          fi
        '';
      };

      pulseaudio = {
        "scroll-step" = 1;
        format = "{icon} {volume}%{format_source}";
        "format-bluetooth" = "{icon} {volume}%{format_source}";
        "format-bluetooth-muted" = " {icon}{format_source}";
        "format-muted" = " {format_source}";
        "format-source" = "  {volume}%";
        "format-source-muted" = " ";
        "format-icons" = {
          headphone = "";
          phone = "";
          portable = "";
          car = "";
          default = [ "" "" "" ];
        };
        "on-click" = "${pkgs.pavucontrol}/bin/pavucontrol";
      };

      "pulseaudio/slider" = {
        min = 0;
        max = 100;
        orientation = "horizontal";
      };
    }];
    style = ./style.css;
    systemd = {
      enable = true;
      target = "river-session.target";
    };
  };
}
