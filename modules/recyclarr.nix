{
  lib,
  config,
  ...
}:
let
  netns = config.modules.vpn.netns;

  sizeCap = name: {
    inherit name;
    max = 80;
    preferred = 79;
  };
in
{
  options.modules.recyclarr.enable = lib.mkEnableOption "recyclarr TRaSH guide sync";

  config = lib.mkIf (config.modules.vpn.enable && config.modules.recyclarr.enable) {
    services.recyclarr = {
      enable = true;
      configuration = {
        radarr.hd-bluray-web = {
          base_url = "http://localhost:7878";
          api_key._secret = config.sops.secrets."radarr_api_key".path;
          delete_old_custom_formats = true;

          # MB per minute of runtime; 80 ≈ 9.4GB for a 2h movie.
          quality_definition = {
            type = "movie";
            qualities = map sizeCap [
              "Bluray-1080p"
              "WEBDL-1080p"
              "WEBRip-1080p"
            ];
          };

          quality_profiles = [
            {
              trash_id = "d1d67249d3890e49bc12e275d989a7e9"; # HD Bluray + WEB
              reset_unmatched_scores.enabled = true;
              upgrade.allowed = false;
            }
          ];

          custom_format_groups.add = [
            { trash_id = "f8bf8eab4617f12dfdbd16303d8da245"; } # [Optional] Golden Rule HD
            { trash_id = "a3ac6af01d78e4f21fcb75f601ac96df"; } # [Unwanted] Unwanted Formats
          ];
        };
      };
    };

    systemd.services.recyclarr = {
      after = [
        "netns@${netns}.service"
        "wg-proton.service"
        "radarr.service"
      ];
      requires = [
        "netns@${netns}.service"
        "wg-proton.service"
      ];
      serviceConfig = {
        NetworkNamespacePath = "/run/netns/${netns}";
        BindReadOnlyPaths = [ "/etc/netns/${netns}/resolv.conf:/etc/resolv.conf:norbind" ];
      };
    };
  };
}
