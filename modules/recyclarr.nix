{
  lib,
  config,
  ...
}:
let
  netns = config.modules.vpn.netns;

  profile = "1080p";

  # MB per minute of runtime; 80 ≈ 9.4GB for a 2h movie.
  sizeLimits = name: {
    inherit name;
    min = 5;
    max = 80;
    preferred = 79;
  };

  hdQualities = res: [
    "Bluray-${res}"
    "WEBDL-${res}"
    "WEBRip-${res}"
    "HDTV-${res}"
  ];

  mkInstance =
    {
      type,
      port,
      apiKey,
      sdQualities,
      rejected,
      preferred,
      lowQuality,
    }:
    {
      base_url = "http://localhost:${toString port}";
      api_key._secret = apiKey;
      delete_old_custom_formats = true;

      quality_definition = {
        inherit type;
        qualities = map sizeLimits (hdQualities "1080p" ++ hdQualities "720p");
      };

      quality_profiles = [
        {
          name = profile;
          min_format_score = -1000;
          reset_unmatched_scores.enabled = true;
          upgrade = {
            allowed = true;
            until_quality = "HD 1080p";
            until_score = 0;
          };
          qualities = [
            {
              name = "HD 1080p";
              qualities = hdQualities "1080p";
            }
            {
              name = "HD 720p";
              qualities = hdQualities "720p";
            }
          ]
          ++ map (name: { inherit name; }) sdQualities;
        }
      ];

      custom_formats = [
        {
          trash_ids = rejected ++ preferred;
          assign_scores_to = [ { name = profile; } ];
        }
        {
          trash_ids = lowQuality;
          assign_scores_to = [
            {
              name = profile;
              score = -500;
            }
          ];
        }
      ];
    };
in
{
  options.modules.recyclarr.enable = lib.mkEnableOption "recyclarr quality profile sync";

  config = lib.mkIf (config.modules.vpn.enable && config.modules.recyclarr.enable) {
    services.recyclarr = {
      enable = true;
      configuration = {
        radarr.hd-bluray-web = mkInstance {
          type = "movie";
          port = 7878;
          apiKey = config.sops.secrets."radarr_api_key".path;
          sdQualities = [
            "Bluray-576p"
            "Bluray-480p"
            "WEBDL-480p"
            "WEBRip-480p"
            "DVD"
          ];
          rejected = [
            "ed38b889b31be83fda192888e2286d83" # BR-DISK
            "b8cd450cbfa689c0259a01d9e29ba3d6" # 3D
            "0a3f082873eb454bde444150b70253cc" # Extras
            "bfd8eb01832d646a0a89c4deb46f8564" # Upscaled
            "c465ccc73923871b3eb1802042331306" # Line/Mic Dubbed
            "712d74cd88bceb883ee32f773656b1f5" # Sing-Along Versions
            "d6e9318c875905d6cfb5bee961afcea9" # Language: Not Original
          ];
          preferred = [
            "ed27ebfef2f323e964fb1f61391bcb35" # HD Bluray Tier 01
            "c20c8647f2746a1f4c4262b0fbbeeeae" # HD Bluray Tier 02
            "5608c71bcebba0a5e666223bae8c9227" # HD Bluray Tier 03
            "c20f169ef63c5f40c2def54abaf4438e" # WEB Tier 01
            "403816d65392c79236dcb6dd591aeda4" # WEB Tier 02
            "af94e0fe497124d1f9ce732069ec8c3b" # WEB Tier 03
            "e7718d7a3ce595f289bfee26adc178f5" # Repack/Proper
            "ae43b294509409a6a13919dedd4764c4" # Repack2
            "5caaaa1c08c1742aa4342d8c4cc463f2" # Repack3
          ];
          lowQuality = [
            "90a6f9a284dff5103f6346090e6280c8" # LQ
            "e204b80c87be9497a8a6eaff48f72905" # LQ (Release Title)
          ];
        };

        sonarr.web-1080p = mkInstance {
          type = "series";
          port = 8989;
          apiKey = config.sops.secrets."sonarr_api_key".path;
          sdQualities = [
            "Bluray-576p"
            "Bluray-480p"
            "WEBDL-480p"
            "WEBRip-480p"
            "DVD"
            "SDTV"
          ];
          rejected = [
            "85c61753df5da1fb2aab6f2a47426b09" # BR-DISK
            "fbcb31d8dabd2a319072b84fc0b7249c" # Extras
            "23297a736ca77c0fc8e70f8edd7ee56c" # Upscaled
            "ae575f95ab639ba5d15f663bf019e3e8" # Language: Not Original
          ];
          preferred = [
            "d6819cba26b1a6508138d25fb5e32293" # HD Bluray Tier 01
            "c2216b7b8aa545dc1ce8388c618f8d57" # HD Bluray Tier 02
            "e6258996055b9fbab7e9cb2f75819294" # WEB Tier 01
            "58790d4e2fdcd9733aa7ae68ba2bb503" # WEB Tier 02
            "d84935abd3f8556dcd51d4f27e22d0a6" # WEB Tier 03
            "ec8fa7296b64e8cd390a1600981f3923" # Repack/Proper
          ];
          lowQuality = [
            "9c11cd3f07101cdba90a2d81cf0e56b4" # LQ
            "e2315f990da2e2cbfc9fa5b7a6fcfe48" # LQ (Release Title)
          ];
        };
      };
    };

    systemd.services.recyclarr = {
      after = [
        "netns@${netns}.service"
        "wg-proton.service"
        "radarr.service"
        "sonarr.service"
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
