# Adapted from https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=urbackup2-server

{ stdenv
, fetchurl
, cryptopp
, curl
, fuse
, pkg-config
, sqlite
, zlib
, writeShellScriptBin
, coreutils
, ...
}:

stdenv.mkDerivation
rec {
  pname = "urbackup2-server";
  version = "2.5.30";

  src = fetchurl {
    url = "https://www.urbackup.org/downloads/Server/${version}/urbackup-server-${version}.tar.gz";
    sha512 = "E6IbVwj/9VIbYQ/aS8kzsJ1d13gKibjM4gJCO5ASc2Avu/KcqT6En2uyqG5gS7hsC0VPBmdtOZwjYNsFJvdClw==";
  };

  buildInputs = [ cryptopp curl fuse sqlite zlib ];
  nativeBuildInputs = [ pkg-config passthru.chmodWrapper ];

  # Unfortunately urbackup doesn't use PATH for its helper binaries, so the /run/wrappers/bin hack is needed
  configurePhase = ''
    ./configure \
      --prefix=/ \
      --bindir=/run/wrappers/bin \
      --datarootdir=/usr/share \
      --sbindir=/sbin \
      --sysconfdir=/etc \
      --localstatedir=/var \
      --enable-packaging \
      --with-mountvhd \
      --with-zlib \
      --with-libcurl \
      --enable-embedded-cryptopp
  '';

  buildPhase = ''
    make -j $NIX_BUILD_CORES
  '';

  installPhase = ''
    mkdir -p $out
    make DESTDIR=$out install

    # Correct paths that have to be set to diffrerent values in configure
    mv $out/run/wrappers/bin $out/bin
    mv $out/usr/share $out/share
    rm -rf $out/run $out/usr

    # Correct some file mode bits, thanks cfstras
    chmod a+x "$out/share/urbackup/www/"{css,fonts,js,images,}
  '';

  passthru = {
    # Prevent make from running chmod +s
    chmodWrapper = writeShellScriptBin "chmod" ''
      if [[ "$1" == "+s" ]]; then
        shift
        echo "Skipping chmod +s $@" >&2
        exit 0
      fi
      exec ${coreutils}/bin/chmod "$@"
    '';
  };
}
