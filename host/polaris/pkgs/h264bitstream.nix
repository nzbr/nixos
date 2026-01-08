{
  stdenv
, fetchFromGitHub
, cmake
, ...
}:

stdenv.mkDerivation {
  name = "h264bitstream";

  src = fetchFromGitHub {
    owner = "aizvorski";
    repo = "h264bitstream";
    rev = "70124d3051ba45e6b326264f0b25e6f48a7479e7";
    sha256 = "sha256-2LmprlZvtvPf0qlVT6WdoB4zyaLEjACE1Y46HAPzil0=";
  };

  nativeBuildInputs = [
    cmake
  ];

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
    "-DCMAKE_INSTALL_LIBDIR=lib"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
  ];
}
