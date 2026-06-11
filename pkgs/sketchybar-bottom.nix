{
  lib,
  writeShellScriptBin,
  jq,
  ifstat-legacy,
  sketchybar,
  pkgs-unstable,
}:

writeShellScriptBin "sketchybar-bottom" ''
  export PATH=${
    lib.makeBinPath [
      jq
      ifstat-legacy
      pkgs-unstable.yabai
    ]
  }:${placeholder "out"}/bin:$PATH
  exec -a sketchybar-bottom ${sketchybar}/bin/sketchybar "$@"
''
