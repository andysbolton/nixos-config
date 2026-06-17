{ pkgs, config, ... }:
let
  systemctl = "${pkgs.systemd}/bin/systemctl --user";

  # Print the most recent entry of the cliphist db given as $1, decoded.
  # Image entries are stored as binary, so show "(image)" rather than
  # dumping raw bytes into the bar.
  clipLatest = pkgs.writeShellScript "clip-latest" ''
    db="$1"
    line=$(cliphist -db-path "$db" list | sort -nr | head -1)
    case "$line" in
      "") printf '%s' "(empty)" ;;
      *"binary data"*) printf '%s' "(image)" ;;
      *) printf '%s' "$line" | cliphist -db-path "$db" decode ;;
    esac
  '';

  colorWrap = color: item: ''<span color="${color}">${item}</span>'';
in
{
  programs.waybar = {
    enable = true;
    systemd = {
      enable = true;
      targets = [ "graphical-session.target" ];
    };
    settings = [
      {
        name = "top-bar";
        layer = "top";
        spacing = 0;

        modules-left = [
          "river/tags"
          "river/window"
          "custom/lan-mouse"
          "systemd-failed-units"
        ];

        modules-center = [ "clock" ];

        modules-right = [
          "pulseaudio"
          "pulseaudio/slider"
        ];

        clock = {
          tooltip-format = "<tt><small>{calendar}</small></tt>";
          interval = 1;
          format = "${colorWrap config.palette.hex.OVERLAY "{0:%A, %B %d}"} | ${colorWrap config.palette.hex.TEXT "{0:%I:%M:%S %Z}"}";
        };

        "river/window" = {
          "max-length" = 70;
        };

        "river/tags" = {
          "num-tags" = 10;
          "hide-vacant" = true;
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
            default = [
              ""
              ""
              ""
            ];
          };
          "on-click" = "${pkgs.pavucontrol}/bin/pavucontrol";
        };

        "pulseaudio/slider" = {
          min = 0;
          max = 100;
          orientation = "horizontal";
        };
      }
      {
        name = "bottom-bar";
        layer = "top";
        position = "bottom";
        spacing = 0;

        modules-left = [
          "disk"
          "memory"
          "cpu"
          "temperature"
          # "custom/gpu-utilization"
          # "custom/gpu-temperature"
        ];

        modules-right = [
          "custom/system"
          "custom/primary"
        ];

        disk = {
          format = " {used} / {total}";
        };

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
          "hwmon-path" = "/sys/devices/platform/nct6687.2592/hwmon/hwmon3/temp1_input";
          interval = 1;
          "critical-threshold" = 80;
          format = " {icon} {temperatureC}°C";
          "format-icons" = [
            ""
            ""
            ""
            ""
          ];
        };

        # "custom/gpu-utilization" = {
        #   exec = "/run/current-system/sw/bin/nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader";
        #   format = "⚙ {}";
        #   interval = 1;
        # };
        #
        # "custom/gpu-temperature" = {
        #   exec = "/run/current-system/sw/bin/nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader";
        #   format = "⚙{icon} {text}°C";
        #   interval = 1;
        #   "critical-threshold" = 80;
        #   "format-icons" = [
        #     ""
        #     ""
        #     ""
        #     ""
        #   ];
        # };

        "custom/system-label" = {
          format = "System: ";
        };

        "custom/system" = {
          interval = 1;
          exec = pkgs.writeShellScript "clipboard-system-check" ''
            ${clipLatest} "$HOME/.cache/cliphist/system-db"
          '';
          max-length = 30;
          min-length = 30;
          format = "System: {}";
          align = 0;
          escape = true;
        };

        "custom/primary" = {
          interval = 1;
          exec = pkgs.writeShellScript "clipboard-primary-check" ''
            ${clipLatest} "$HOME/.cache/cliphist/primary-db"
          '';
          max-length = 30;
          min-length = 30;
          align = 0;
          format = "Primary: {}";
          escape = true;
        };
      }
    ];
    style = pkgs.runCommand "waybar-style.css" { nativeBuildInputs = [ pkgs.lessc ]; } ''
      lessc ${./style.less} > $out
    '';
  };
}
