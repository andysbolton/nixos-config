{
  fetchurl,
  stdenvNoCC,
  lib,
  undmg,
}:

stdenvNoCC.mkDerivation rec {
  pname = "gatherv2";
  version = "0.47.5";

  src = fetchurl {
    url = "https://api.v2.gather.town/api/v2/releases/latest/macos/v2";
    hash = "sha256-1tOHHx86oTcAGR2w4qa8zrinh5ymvo0c00EBE5GJvvY=";
    name = "GatherV2-${version}.dmg";
  };

  nativeBuildInputs = [ undmg ];
  sourceRoot = ".";

  installPhase = ''
    mkdir -p $out/Applications
    cp -r GatherV2.app $out/Applications/
  '';

  meta = with lib; {
    description = "Gather Town V2 - Virtual video-calling space";
    homepage = "https://gather.town";
    license = licenses.unfree;
    platforms = [ "aarch64-darwin" "x86_64-darwin" ];
  };
}
