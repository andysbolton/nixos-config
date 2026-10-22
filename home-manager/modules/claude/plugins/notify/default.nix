{
  lib,
  stdenv,
  jq,
  libnotify,
  libcanberra-gtk3,
  sound-theme-freedesktop,
}:
{
  description = "Desktop notification when a turn finishes or Claude needs input";
  hooks = {
    Stop = { };
    Notification = { };
  };
  runtimeInputs = [
    jq
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    libnotify
    libcanberra-gtk3
  ];
  runtimeEnv = lib.optionalAttrs stdenv.hostPlatform.isLinux {
    NOTIFY_SOUND = "${sound-theme-freedesktop}/share/sounds/freedesktop/stereo/complete.oga";
  };
}
