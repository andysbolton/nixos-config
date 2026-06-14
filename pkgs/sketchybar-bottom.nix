{
  ifstat-legacy,
  jq,
  lib,
  pkgs-unstable,
  pngpaste,
  sketchybar,
  writeShellScriptBin,
}:

writeShellScriptBin "sketchybar-bottom" ''
  export PATH=${
    lib.makeBinPath [
      jq
      ifstat-legacy
      pkgs-unstable.yabai
      pngpaste
    ]
  }:${placeholder "out"}/bin:$PATH
  export LC_CTYPE=UTF-8
  exec -a sketchybar-bottom ${sketchybar}/bin/sketchybar "$@"
''
