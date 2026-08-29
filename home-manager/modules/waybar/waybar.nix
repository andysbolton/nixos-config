{
  pkgs,
  osConfig,
  ...
}:
with osConfig.palette.hex;
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

  # The @colors map style.less imports, so the stylesheet tracks the scheme
  # instead of carrying its own copy of the hex values.
  paletteLess = pkgs.writeText "palette.less" ''
    @colors: {
      ${pkgs.lib.concatStringsSep "\n  " (
        pkgs.lib.mapAttrsToList (name: hex: "${pkgs.lib.toLower name}: ${hex};") osConfig.palette.hex
      )}
    };
  '';

  netTools = pkgs.lib.makeBinPath [
    pkgs.iw
    pkgs.iproute2
    pkgs.systemd
    pkgs.tailscale
    pkgs.jq
    pkgs.coreutils
    pkgs.gawk
    pkgs.gnused
  ];

  # Wifi + real DNS reachability + tailscale, as one pill. class colours the
  # label from style.less:
  # ok = connected and an uncached lookup resolved; nodns = link up but DNS dead
  # (the post-AP-switch recovery window); down = no association.
  networkStatus =
    pkgs.writeShellScript "network-status"
      # bash
      ''
        export PATH=${netTools}

        iface=$(iw dev | awk '$1=="Interface"{print $2; exit}')

        class="down"
        label="󰤭 offline"

        if [ -n "$iface" ]; then
          link=$(iw dev "$iface" link 2>/dev/null)
          ssid=$(printf '%s\n' "$link" | sed -n 's/^[[:space:]]*SSID: //p')
          dbm=$(printf '%s\n' "$link" | sed -n 's/^[[:space:]]*signal: \(-\{0,1\}[0-9]\{1,\}\).*/\1/p')
          ip4=$(ip -4 -o addr show "$iface" 2>/dev/null | awk '{print $4; exit}')

          if [ -n "$ssid" ]; then
            pct=0
            if [ -n "$dbm" ]; then
              pct=$(( 2 * (dbm + 100) ))
              [ "$pct" -gt 100 ] && pct=100
              [ "$pct" -lt 0 ] && pct=0
            fi
            if   [ "$pct" -ge 80 ]; then icon="󰤨"
            elif [ "$pct" -ge 60 ]; then icon="󰤥"
            elif [ "$pct" -ge 40 ]; then icon="󰤢"
            elif [ "$pct" -ge 20 ]; then icon="󰤟"
            else icon="󰤯"
            fi

            if [ -z "$ip4" ]; then
              class="nodns"; health="no IP"
            elif timeout 2 resolvectl query -4 --cache=no example.com >/dev/null 2>&1; then
              class="ok"; health="online"
            else
              class="nodns"; health="DNS unreachable"
            fi

            esc_ssid=$(printf '%s' "$ssid" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g')
            if [ "$class" = "ok" ]; then
              label="$icon $esc_ssid"
            else
              label="$icon dns resolving…"
            fi
          fi
        fi

        ts=$(tailscale status --json 2>/dev/null)
        tsstate=$(printf '%s' "$ts" | jq -r '.BackendState // "down"' 2>/dev/null)
        exitnode=$(printf '%s' "$ts" | jq -r 'first(.Peer[]? | select(.ExitNode == true) | .HostName) // ""' 2>/dev/null)
        if [ "$tsstate" = "Running" ]; then
          tscolor="${GREEN}"
          tstip="Running"
          [ -n "$exitnode" ] && tstip="Running (exit: $exitnode)"
        else
          tscolor="${SUBTEXT}"
          tstip="''${tsstate:-down}"
        fi
        tsseg="<span color='$tscolor'>󰦝</span>"

        text="$label  $tsseg"

        sig=""
        [ -n "$dbm" ] && sig=" ($dbm dBm, $pct%)"
        dns=$(resolvectl dns "$iface" 2>/dev/null | sed 's/.*: //' | tr -d '\n')
        tooltip=$(printf 'Interface: %s\nSSID: %s%s\nIPv4: %s\nDNS: %s\nHealth: %s\nTailscale: %s' \
          "''${iface:-none}" "''${esc_ssid:-—}" "$sig" "''${ip4:-—}" "''${dns:-—}" "''${health:-disconnected}" "$tstip")

        jq -nc --arg text "$text" --arg tooltip "$tooltip" --arg class "$class" \
          '{text: $text, tooltip: $tooltip, class: $class}'
      '';
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
          "river/mode"
          "systemd-failed-units"
        ];

        modules-center = [ "clock" ];

        modules-right = [
          "custom/network"
          "battery"
          "pulseaudio"
          "pulseaudio/slider"
        ];

        clock = {
          tooltip-format = "<tt><small>{calendar}</small></tt>";
          interval = 1;
          format = "${colorWrap OVERLAY "{0:%A, %B %d}"} | ${colorWrap TEXT "{0:%I:%M:%S %Z}"}";
        };

        "river/window" = {
          "max-length" = 60;
        };

        "river/tags" = {
          "num-tags" = 10;
          "hide-vacant" = true;
        };

        "custom/lan-mouse" = {
          interval = 5;
          exec = pkgs.writeShellScript "lan-mouse-check" ''
            if ${systemctl} is-active --quiet "lan-mouse.service"; then
              echo "󰍽"
            else
              echo "󰍾"
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

        "custom/network" = {
          interval = 10;
          return-type = "json";
          exec = networkStatus;
          format = "{}";
          tooltip = true;
        };

        "river/mode" = {
          format = "{}";
        };

        battery = {
          format = "{icon} {capacity}%";
          format-icons = {
            default = [
              "󰂎"
              "󰁺"
              "󰁻"
              "󰁼"
              "󰁽"
              "󰁾"
              "󰁿"
              "󰂀"
              "󰂁"
              "󰂂"
              "󰁹"
            ];
            charging = [
              "󰢟"
              "󰢜"
              "󰂆"
              "󰂇"
              "󰂈"
              "󰢝"
              "󰂉"
              "󰢞"
              "󰂊"
              "󰂋"
              "󰂅"
            ];
          };
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
          "onclick" = "${pkgs.pavucontrol}/bin/pavucontrol";
          "on-right-click" = "${pkgs.pavucontrol}/bin/pavucontrol";
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
      cp ${./style.less} style.less
      cp ${paletteLess} palette.less
      lessc style.less > $out
    '';
  };
}
