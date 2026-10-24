{
  pkgs,
  osConfig,
  ...
}:
with osConfig.theme.css;
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
    @font-mono: "${osConfig.stylix.fonts.monospace.name}";
    @colors: {
      ${pkgs.lib.concatStringsSep "\n  " (
        pkgs.lib.mapAttrsToList (name: color: "${pkgs.lib.toLower name}: ${color};") osConfig.theme.css
      )}
    };
  '';

  # Load thresholds (%), styled as WARN / ATTENTION / ERROR in style.less.
  loadStates = {
    warning = 70;
    urgent = 85;
    critical = 95;
  };

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
              label="<span color='${OK}'>$icon</span> $esc_ssid"
            else
              label="$icon dns resolving…"
            fi
          fi
        fi

        ts=$(tailscale status --json 2>/dev/null)
        tsstate=$(printf '%s' "$ts" | jq -r '.BackendState // "down"' 2>/dev/null)
        exitnode=$(printf '%s' "$ts" | jq -r 'first(.Peer[]? | select(.ExitNode == true) | .HostName) // ""' 2>/dev/null)
        if [ "$tsstate" = "Running" ]; then
          tscolor="${TOGGLE_ON}"
          tstip="Running"
          [ -n "$exitnode" ] && tstip="Running (exit: $exitnode)"
        else
          tscolor="${TOGGLE_OFF}"
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
          "group/audio"
          "pulseaudio/slider"
        ];

        clock = {
          tooltip-format = "<tt><small>{calendar}</small></tt>";
          interval = 1;
          format = "${colorWrap TEXT_ALT "{0:%A, %B %d}"} | ${colorWrap TEXT "{0:%I:%M:%S %Z}"}";
        };

        "river/window" = {
          "max-length" = 60;
        };

        "systemd-failed-units" = {
          format-ok = "{system_state}/{user_state}";
        };

        "river/tags" = {
          "num-tags" = 10;
          "hide-vacant" = true;
        };

        "custom/lan-mouse" = {
          interval = 5;
          exec = pkgs.writeShellScript "lan-mouse-check" ''
            if ${systemctl} is-active --quiet "lan-mouse.service"; then
              echo "<span color='${TOGGLE_ON}'>󰍽</span>"
            else
              echo "<span color='${TOGGLE_OFF}'>󰍾</span>"
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
          # Battery states match at or below the value.
          states = {
            warning = 60;
            urgent = 20;
            critical = 10;
          };
          format = "${colorWrap OK "{icon}"} {capacity}%";
          # Low states drop the green so style.less colours the whole pill.
          format-warning = "{icon} {capacity}%";
          format-urgent = "{icon} {capacity}%";
          format-critical = "{icon} {capacity}%";
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

        "group/audio" = {
          orientation = "horizontal";
          modules = [
            "bluetooth"
            "pulseaudio"
          ];
        };

        bluetooth = {
          format = "󰂯";
          format-off = "${colorWrap TOGGLE_OFF "󰂲"}";
          format-disabled = "${colorWrap TOGGLE_OFF "󰂲"}";
          format-connected = "${colorWrap OK "󰂱"}";
          format-connected-battery = "${colorWrap OK "󰂱"} {device_battery_percentage}%";
          tooltip-format = "{controller_alias}: {status}";
          tooltip-format-connected = "{device_enumerate}";
          tooltip-format-enumerate-connected = "{device_alias}";
          tooltip-format-enumerate-connected-battery = "{device_alias} {device_battery_percentage}%";
          on-click = "${pkgs.blueman}/bin/blueman-manager";
        };

        pulseaudio = {
          "scroll-step" = 1;
          format = "${colorWrap OK "{icon}"} {volume}%{format_source}";
          "format-bluetooth" = "${colorWrap OK "{icon}"} {volume}%{format_source}";
          "format-bluetooth-muted" = " {icon}{format_source}";
          "format-muted" = " {format_source}";
          "format-source" = " ${colorWrap OK ""} {volume}%";
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

        modules-left = [ "group/stats" ];

        modules-right = [
          "custom/system"
          "custom/primary"
        ];

        "group/stats" = {
          orientation = "horizontal";
          modules = [
            "network#traffic"
            "disk"
            "memory"
            "cpu"
            "temperature"
            # "custom/gpu-utilization"
            # "custom/gpu-temperature"
          ];
        };

        "network#traffic" = {
          interval = 1;
          format = "${colorWrap LABEL "≈ net"} ↑{bandwidthUpBytes} ↓{bandwidthDownBytes}";
          format-disconnected = "${colorWrap LABEL "≈ net"} offline";
          tooltip-format = "{ifname}";
          # Rates change width every second; reserve room so the pill doesn't jitter.
          # min-length = 28;
        };

        disk = {
          states = loadStates;
          format = "${colorWrap DIVIDER "│"} ${colorWrap LABEL "◙ disk"} {percentage_used}%";
          tooltip-format = "{used} / {total}";
        };

        cpu = {
          states = loadStates;
          format = "${colorWrap DIVIDER "│"} ${colorWrap LABEL "▣ cpu"} {usage}%";
          tooltip = false;
          interval = 1;
        };

        memory = {
          states = loadStates;
          format = "${colorWrap DIVIDER "│"} ${colorWrap LABEL "≡ mem"} {percentage}%";
          tooltip-format = "{used:0.1f}G / {total:0.1f}G";
          interval = 1;
        };

        temperature = {
          "hwmon-path" = "/sys/devices/platform/nct6687.2592/hwmon/hwmon3/temp1_input";
          interval = 1;
          "critical-threshold" = 80;
          format = "${colorWrap DIVIDER "│"} ${colorWrap LABEL "☼ temp"} {temperatureC}°C";
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
          format = "${colorWrap RED "♥"}  {}";
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
          format = "█ ${colorWrap TEXT "{}"}";
          escape = true;
        };
      }
    ];
    # Read as text so it merges after Stylix's waybar CSS (import from derivation).
    style = pkgs.lib.mkAfter (
      builtins.readFile (
        pkgs.runCommand "waybar-style.css" { nativeBuildInputs = [ pkgs.lessc ]; } ''
          cp ${./style.less} style.less
          cp ${paletteLess} palette.less
          lessc style.less > $out
        ''
      )
    );
  };
}
