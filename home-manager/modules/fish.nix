{ config, pkgs, ... }:
{
  xdg = {
    configFile = {
      "fish/themes" = {
        source = "${pkgs.tokyonight-extras}/fish_themes";
        recursive = true;
      };
    };
  };

  programs.fish = {
    enable = true;

    generateCompletions = true;

    # Shell configuration
    shellInit = ''
      # Path additions
      fish_add_path ~/smartwyre/infra-orchestrator/scripts/util
      fish_add_path ~/.local/bin
      fish_add_path ~/bin

      # Key bindings
      bind \cS 'history-pager'

      # Initialize login shell
      if status is-login
        cd ~/
      end
    '';

    interactiveShellInit = ''
      batman --export-env | source
      fish_config theme choose tokyonight_night

      starship init fish | source
      enable_transience
    '';

    functions = {
      add = {
        argumentNames = [ "message" ];
        body = ''
          set branch (git branch --show-current)
          set match (string match --groups-only -r '(?i)(smart|cloud-\d+)' $branch)
          if [ -n "$match" ]
            set commit "$match: $message"
          else
            set commit "$message"
          end
          git add -A
          git commit -m "$commit"
          echo "Commited with message: $message"
        '';
      };

      addp = {
        argumentNames = [ "message" ];
        body = ''
          add $message
          if ! git push
            git push --set-upstream origin (git branch --show-current)
          end
        '';
      };

      bat = {
        body = ''
          if command -v batcat
            batcat $argv
          else
            eval (command -v bat) $argv
          end
        '';
      };

      starship_transient_prompt_func = {
        body = ''
          starship module character
        '';
      };

      p = {
        body = ''
          pwsh -Command $argv
        '';
      };

      ops = {
        body = ''
          eval $(op signin)
        '';
      };

      exercism = {
        body = ''
          if [ $argv[1] = "download" ]
            set dir (~/bin/exercism $argv) && echo $dir && cd $dir
          else
            ~/bin/exercism $argv
          end
        '';
      };

      cdn = {
        body = ''
          cd $argv[1] && nvim
        '';
      };

      fsource = {
        body = ''
          for line in (cat $argv | grep -v '^#')
            set item (string split -m 1 '=' $line)
            set -gx $item[1] $item[2]
            echo "Exported key $item[1]."
          end
        '';
      };

      nwhich = {
        body = ''
          readlink -f (which $argv[1])
        '';
      };

      psfind = {
        argumentNames = [ "app" ];
        body = ''
          set -l pids (pgrep -i $app)
          if test -z "$pids"
              return 1
          end

          ps -o pid,ppid,command -p $pids

          set -l exe_path (ps -ww -o ppid=,command= -p $pids | awk '$1 == 1 && /\.app\// { $1=""; print substr($0,2) }' | head -1)

          if test -n "$exe_path"
            set -l app_folder (echo "$exe_path" | sed -n 's|\(.*\)\.app/.*|\1.app|p')
            set -l source "$app_folder/Contents/Resources/en.lproj/InfoPlist.strings"

            set -l bundle_name (plutil -p "$source" 2>/dev/null | awk -F '=> ' '/CFBundleDisplayName/ {print $2}' | tr -d '"')

            if test -z "$bundle_name"
              set source "$app_folder/Contents/Info.plist"
              set bundle_name (plutil -extract CFBundleDisplayName xml1 "$source" -o - 2>/dev/null | xmllint --xpath "string(//string)" - 2>/dev/null)
            end

            if test -z "$bundle_name"
              set bundle_name (plutil -extract CFBundleName xml1 "$source" -o - 2>/dev/null | xmllint --xpath "string(//string)" - 2>/dev/null)
            end

            if test -z "$bundle_name"
              set bundle_name (basename "$app_folder" .app)
              set source "app folder name"
            end

            echo ""
            echo "parent info:"
            echo "  exe name:    $(basename $exe_path)"
            echo "  bundle name: $bundle_name (source: $source)"
            echo "  id:          $(osascript -e "id of app \"$bundle_name\"")"
          end
        '';
      };

      sub = {
        body = ''
          if count $argv >/dev/null
            # We're in selection mode.
            set ordinal $argv[1]

            if ! string match -qr '^\d+$' $ordinal
              echo "The subscription ordinal to select must be an integer, received '$argv[1]'."
              return
            end

            set index (math $argv[1] - 1)

            set sub $(
              az account list --all --query "[].{name:name,id:id}" |
                jq -r --arg INDEX $index \
                  'sort_by(.name) | to_entries | map(select(.key == ($INDEX | tonumber))) | .[].value.name'
            )
            if [ -n "$sub" ]
              az account set --subscription $sub >/dev/null
              echo "Switched to sub $sub."
            else
              echo "Subscription at ordinal '$ordinal' not found."
            end
          else
            # We're in list mode.
            set current_sub $(az account show --query name -o tsv)
            az account list --all --query "[].{name:name,id:id}" |
              jq -r --arg CURRENT_SUB $current_sub \
                'sort_by(.name)
                    | to_entries
                    | .[]
                    | .value.name = if .value.name == $CURRENT_SUB then "*** \(.value.name) ***" else .value.name end
                    | "\(.key + 1)~\(.value.name)~\(.value.id)"' |
              column -t -s'~' -c ' ',Name,Id
          end
        '';
      };

      restart-wm = {
        body = ''
          sudo launchctl kickstart -k system/org.nixos.yabai-sa
          sleep 2
          launchctl kickstart -k gui/(id -u)/org.nixos.yabai
          sleep 2
          launchctl kickstart -k gui/(id -u)/org.nix-community.home.skhd
          launchctl kickstart -k gui/(id -u)/org.nix-community.home.sketchybar
        '';
      };

      rebuild = {
        body = ''
          set -l untracked (git ls-files --others --exclude-standard)

          if test (count $untracked) -gt 0
            echo "Untracked files exist; add them before rebuild:"
            printf '%s\n' $untracked
            return 1
          end

          git status --short
          sudo darwin-rebuild switch --flake .#work-darwin
        '';
      };

      az_group_member_id = {
        body = ''
          set group_name $argv[1]
          set group_id (az ad group show --group "$group_name" --query id -o tsv)
          az rest --method GET \
            --url "https://graph.microsoft.com/beta/groups/$group_id/members" \
            --query "value[].{name:displayName, type:\"@odata.type\", importId:join('/', ['$group_id', id])}" \
            -o table
        '';
      };
    };

    shellAliases = {
      nvimconf = "nvim --cmd ':cd ~/.config/nvim'";
      nvc = "nvimconf";
      fishconf = "nvim ~/.config/fish/config.fish";
      fc = "fishconf";
      riverconf = "nvim ~/.config/river/init";
      rc = "riverconf";
      wayconf = "nvim --cmd ':cd ~/.config/waybar'";
      wyc = "wayconf";
      lrepl = "lein repl";
      ls = "lsd";
      syc = "systemctl";

      gp = "git pull";
      mm = "git checkout main && gp && git checkout - && git merge main";
    };

    shellAbbrs =
      let
        helpExpansion = key: {
          "${key}" = {
            position = "anywhere";
            expansion = "${key} | bat -p -lhelp";
          };
        };
      in
      helpExpansion "-h" // helpExpansion "--help" // { };
  };
}
