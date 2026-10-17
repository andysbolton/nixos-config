pkgs: src:
let
  inherit (pkgs)
    lib
    stdenv
    writeShellApplication
    writeTextFile
    ;
  name = baseNameOf src;
  plugin = pkgs.callPackage src { };
  platformScript = src + "/${name}.${stdenv.hostPlatform.parsed.kernel.name}.sh";
  script = writeShellApplication {
    inherit name;
    runtimeInputs = plugin.runtimeInputs or [ ];
    runtimeEnv = plugin.runtimeEnv or { };
    text =
      builtins.readFile (src + "/${name}.sh")
      + lib.optionalString (builtins.pathExists platformScript) (builtins.readFile platformScript);
  };
in
writeTextFile {
  name = "claude-plugin-${name}";
  destination = "/.claude-plugin/plugin.json";
  text = builtins.toJSON {
    inherit name;
    inherit (plugin) description;
    hooks = lib.mapAttrs (_: matcher: [
      (
        matcher
        // {
          hooks = [
            {
              type = "command";
              command = lib.getExe script;
            }
          ];
        }
      )
    ]) plugin.hooks;
  };
}
