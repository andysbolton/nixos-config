{
  programs.firefox = {
    enable = true;

    profiles = {
      home = {
        id = 0;
        name = "home";
        isDefault = true;
        extensions = { force = true; };
        # I'm having trouble using nur.repos.rycee.firefox-addons and installing unfree extensions.
        # extensions = {
        #   force = true;
        #   packages = with inputs.firefox-addons.packages."x86_64-linux"; [
        #     grammarly
        #     onepassword-password-manager
        #     privacy-badger
        #     refined-github
        #     ublock-origin
        #     vimium
        #   ];
        # };
      };
    };

    policies = {
      AppAutoUpdate = false;
      Cookies = { Behavior = "reject-tracker-and-partition-foreign"; };
      DisablePocket = true;
      DisableSystemAddonUpdate = true;
      DisableTelemetry = true;
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptominig = true;
        Fingerpriting = true;
        EmailTracking = true;
      };
      FirefoxSuggest = {
        SponsoredSuggestions = false;
        ImproveSuggest = false;
      };
      Homepage = { StartPage = "none"; };
      ManualAppUpdateOnly = true;
      NetworkPrediction = false;
      PopupBlocking = { Default = true; };
      PostQuantumKeyAgreementEnabled = true;
      SkipTermsOfUse = true;
    };
  };
}
