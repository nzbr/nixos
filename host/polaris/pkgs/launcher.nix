{ stdenvNoCC
, writeText
, openDsh
, ...
}:
let
  desktopFile = writeText "openauto.desktop" ''
    [Desktop Entry]
    Type=Application
    Name=Android Auto
    Categories=Audio;AudioVideo;Player;
    Icon=android-auto
    Exec=${openDsh}/bin/dash
  '';
in
stdenvNoCC.mkDerivation {
  name = "openauto-launcher";

  buildCommand = ''
    install -Dm644 ${desktopFile} $out/share/applications/openauto.desktop
    install -Dm644 ${openDsh.src}/assets/icons/android_auto_color.svg $out/share/icons/hicolor/scalable/apps/android-auto.svg
  '';
}
