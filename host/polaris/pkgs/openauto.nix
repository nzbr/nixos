{ stdenv
, writeText
, fetchFromGitHub
, cmake
, aasdk
, boost177
, h264bitstream
, libusb1
, openssl
, protobuf_21
, pulseaudio
, qtbase
, qtmultimedia
, qtconnectivity
, qtgstreamer
, pkg-config
, rtaudio
, gst_all_1
, wrapQtAppsHook
, wrapGAppsHook3
, ...
}:

stdenv.mkDerivation {
  name = "openauto";

  src = fetchFromGitHub {
    owner = "openDsh";
    repo = "openauto";
    rev = "e7caeb4d49186af867c1d4693c9f3bf9e9ef99e0";
    sha256 = "sha256-3jCyJ+xXQfr4b62VoyBpzxlnurf4XpzV8uE8opvKfvE=";
  };

  nativeBuildInputs = [
    wrapGAppsHook3
    wrapQtAppsHook
    cmake
    protobuf_21
    pkg-config
  ];

  buildInputs = [
    aasdk
    boost177
    h264bitstream
    libusb1
    openssl
    protobuf_21
    pulseaudio
    rtaudio
    qtbase
    qtmultimedia
    qtconnectivity
    qtgstreamer
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
    gst_all_1.gst-vaapi
  ];

  # Qt5GStreamer_DIR = "${qtmultimedia.dev}";

  cmakeFlags = [
    "-DRPI3_BUILD=TRUE"
    "-DCMAKE_BUILD_TYPE=Release"
    "-DGST_BUILD=true"
    # "-DCMAKE_INSTALL_RPATH=$out/lib"
    "-DCMAKE_SKIP_RPATH=TRUE"
    # "-DCMAKE_SKIP_BUILD_RPATH=TRUE"
    # "-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=FALSE"
  ];

  # wrapGappsHook is used to automatically collect the GStreamer plugins. It should not actually wrap the application,
  # because then it would be wrapped twice.
  dontWrapGApps = true;
  preFixup = ''
    qtWrapperArgs+=("''${gappsWrapperArgs[@]}")
  '';
}
