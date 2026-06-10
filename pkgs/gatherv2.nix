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
    url = "https://downloads.gather.town/desktop-v2/GatherV2-${version}-universal.dmg";
    hash = "sha256-1tOHHx86oTcAGR2w4qa8zrinh5ymvo0c00EBE5GJvvY=";
    curlOpts = "-L";
  };

  nativeBuildInputs = [ undmg ];
  sourceRoot = ".";

  installPhase = ''
    mkdir -p $out/Applications
    mv GatherV2.app $out/Applications/
  '';

  meta = with lib; {
    description = "Gather Town V2 - Virtual video-calling space";
    homepage = "https://gather.town";
    license = licenses.unfree;
    platforms = [
      "aarch64-darwin"
      "x86_64-darwin"
    ];
  };
}
