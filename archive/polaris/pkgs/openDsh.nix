{ stdenv
, fetchFromGitHub
, cmake
, pkg-config
, aasdk
, openauto
, boost177
, qtbase
, qtmultimedia
, qtconnectivity
, qtserialbus
, qtwebsockets
, qtgstreamer
, bluez-qt
, rtaudio
, gst_all_1
, protobuf_21
, taglib_1
, libusb1
, wrapGAppsHook3
, wrapQtAppsHook
, ...
}:

stdenv.mkDerivation {
  name = "openDsh";

  src = fetchFromGitHub {
    owner = "openDsh";
    repo = "dash";
    rev = "2d56f99cff5990e420297ca02e7cf45fe2aebb81";
    sha256 = "sha256-aRB8ku3+xkPeMtyJ5Cf1q5nWK0dfFqsMIObv72LD/g8=";
  };

  patches = [
    ./0001-patchy-patch.patch
  ];

  nativeBuildInputs = [
    cmake
    pkg-config
    wrapGAppsHook3
    wrapQtAppsHook
  ];

  buildInputs = [
    aasdk
    openauto
    boost177
    qtbase
    qtmultimedia
    qtconnectivity
    qtserialbus
    qtwebsockets
    qtgstreamer
    bluez-qt
    protobuf_21
    rtaudio
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
    gst_all_1.gst-vaapi
    taglib_1
    libusb1
  ];

  cmakeFlags = [
    "-DGST_BUILD=True"
  ];

  # same trick as in openauto
  dontWrapGApps = true;
  preFixup = ''
    qtWrapperArgs+=("''${gappsWrapperArgs[@]}")
  '';
}
