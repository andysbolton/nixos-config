{ fetchFromGitHub, stdenvNoCC, lib, }:

stdenvNoCC.mkDerivation rec {
  pname = "tokyonight-extras";
  version = "4.14.1";

  src = fetchFromGitHub {
    owner = "folke";
    repo = "tokyonight.nvim";
    rev = "v${version}";
    hash = "sha256-kQsV0x8/ycFp3+S6YKyiKFsAG5taOdQmx/dMuDqGyEQ=";
  };

  installPhase = ''
    mkdir -p $out
    cp -r extras/* $out
    cp LICENSE $out
  '';

  meta = with lib; {
    license = licenses.asl20;
    homepage = "https://github.com/folke/tokyonight.nvim";
    description = "A clean, dark Neovim theme written in Lua.";
    platforms = platforms.all;
  };
}
