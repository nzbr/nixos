# https://github.com/NixOS/nixpkgs/issues/92769#issuecomment-673744092

{ stdenv, fetchFromGitHub, nodejs, nodePackages, glib }:

stdenv.mkDerivation rec {
  pname = "gnome-shell-extension-pop-shell";
  version = "2020-08-13";

  src = fetchFromGitHub {
    owner = "pop-os";
    repo = "shell";
    rev = "55c40ce66a5a51e83c083063a704372e18ca49e5";
    sha256 = "1pv01jc85g1a3dbamcnvm9iwr03llxycnywx5p7ng04xyq5l6923";
  };

  uuid = "pop-shell@system76.com";

  nativeBuildInputs = [ glib nodePackages.typescript];

  makeFlags = [ "INSTALLBASE=$(out)/share/gnome-shell/extensions" ];

  postInstall = ''
    mkdir -p $out/share/gsettings-schemas/pop-shell-${version}/glib-2.0

    schemadir=${glib.makeSchemaPath "$out" "${pname}-${version}"}
    mkdir -p $schemadir
    cp -r $out/share/gnome-shell/extensions/$uuid/schemas/* $schemadir

  '';

  meta = with stdenv.lib; {
    description = "i3wm-like keyboard-driven layer for GNOME Shell";
    homepage = "https://github.com/pop-os/shell";
    license = licenses.gpl3;
    maintainers = with maintainers; [ mog ];
    platforms = platforms.linux;
  };
}
