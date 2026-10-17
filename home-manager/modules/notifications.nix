{ ... }:
{
  services.dunst = {
    enable = true;
    settings = {
      global = {
        monitor = 0;
        follow = "mouse";

        width = 400;
        height = "(0, 300)";
        origin = "bottom-center";

        gap_size = 30;
        sort = "yes";

        line_height = 0;

        markup = "full";
        format = "<b>%s</b>\\n%a\\n\\n%b";
        alignment = "left";
        show_age_threshold = 60;

        show_indicators = "yes";

        enable_recursive_icon_lookup = true;
        icon_position = "left";
        min_icon_size = 32;
        max_icon_size = 128;
      };

      urgency_low = {
        timeout = 5;
      };

      urgency_normal = {
        timeout = 10;
      };

      urgency_critical = {
        timeout = 0;
      };
    };
  };
}
