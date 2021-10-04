# https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=xstow

{ stdenv, lib, ncurses }:

stdenv.mkDerivation rec {
  pname = "xstow";
  version = "1.0.2";

  meta = with lib; {
    description = "XStow is a replacement of GNU Stow written in C++. It supports all features of Stow with some extensions.";
    homepage = "http://xstow.sourceforge.net";
    license = licenses.gpl2Only;
    maintainers = with maintainers; [ nzbr ];
    platforms = platforms.unix;
  };

  src = fetchTarball {
    url = "http://downloads.sourceforge.net/sourceforge/${pname}/${pname}-${version}.tar.bz2";
    sha256 = "0v1mymvflp4nfqm2xd35fkw8v8a6bf3nn64g4qjlg9jhbvsh7x2f";
  };

  configureFlags = [ "--with-curses=${ncurses}" ];

  makeFlags = [ ];
}
