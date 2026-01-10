{ stdenv
, fetchFromGitHub
, cmake
, pkg-config
, gst_all_1
, qtbase
, boost
, wrapQtAppsHook
}:

stdenv.mkDerivation {
  name = "qtgstreamer";

  # src = fetchFromGitHub {
  #   owner = "GStreamer";
  #   repo = "qt-gstreamer";
  #   rev = "5dde8cec5c9f28b0cc63072886a03f029324c149";
  #   sha256 = "sha256-104b1tPA6yF/sjwUNxh3Y/pTfKOho/kBygauyd+rmfU=";
  # };
  src = builtins.fetchurl {
    url = "https://gstreamer.freedesktop.org/src/qt-gstreamer/qt-gstreamer-1.2.0.tar.xz";
    sha256 = "9f3b492b74cad9be918e4c4db96df48dab9c012f2ae5667f438b64a4d92e8fd4";
  };

  patches =
    let
      source = fetchFromGitHub {
        owner = "archlinux";
        repo = "svntogit-packages";
        rev = "da653f08641f941c49a2d475811fbcd12b330444";
        sha256 = "sha256-JEUhQ+7s8feLFPnsxzTq8WLccVrxq0R26uhPcyuKDm4=";
      };
    in
    [
      "${source}/trunk/gstreamer-1.6.patch"
      "${source}/trunk/gstreamer-1.16.patch"
      "${source}/trunk/qt-gstreamer-1.18.patch"
      "${source}/trunk/qt-gstreamer-gcc11.patch"

      # Fixes the red tint in openauto
      # Issue: https://bugzilla.gnome.org/show_bug.cgi?id=781816
      # Patch: https://bugzilla.gnome.org/attachment.cgi?id=350558
      ./red-artifact.patch
    ];

  nativeBuildInputs = [
    wrapQtAppsHook
    cmake
    pkg-config
  ];

  buildInputs = [
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    qtbase
    boost
  ];

  cmakeFlags = [
    "-DQT_VERSION=5"
    "-DCMAKE_BUILD_TYPE=Release"
    "-DUSE_GST_PLUGIN_DIR=OFF"
    "-DUSE_QT_PLUGIN_DIR=OFF"
    "-DQTGSTREAMER_EXAMPLES=OFF"
    "-DCMAKE_INSTALL_LIBDIR=lib"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
  ];

  postInstall = ''
    mkdir -p $(dirname $out/${qtbase.qtQmlPrefix})
    mv $out/lib/qt5/qml $out/${qtbase.qtQmlPrefix}
  '';
}
