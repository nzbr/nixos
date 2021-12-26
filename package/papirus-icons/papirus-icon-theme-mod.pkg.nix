{ stdenv, ... }:
stdenv.mkDerivation rec {
  pname = "papirus-icon-theme-mod";
  version = "20210601";

  src = builtins.fetchGit {
    url = "https://github.com/PapirusDevelopmentTeam/papirus-icon-theme.git";
    rev = "89fd451b2e36805b268e16430f0414af9d25b291";
  };

  buildPhase = ''
    patch Papirus/index.theme "${./index.theme.patch}"
    patch Papirus-Light/index.theme "${./index.theme.patch}"
    patch Papirus-Dark/index.theme "${./index-dark.theme.patch}"

    rm -vrf ePapirus
    rm -vrf */*/apps */*/devices
  '';

  preInstall = ''
    mkdir -p "$out"
  '';

  installPhase = ''
    make DESTDIR=$out install
    mv -v $out/usr/share $out/share
    rmdir -v $out/usr
  '';
}
