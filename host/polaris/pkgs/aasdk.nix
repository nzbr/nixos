{ stdenv
, fetchFromGitHub
, cmake
, protobuf_21
, libusb1
, openssl
, boost177
, openDsh
, ...
}:

stdenv.mkDerivation {
  name = "aasdk";

  src = fetchFromGitHub {
    owner = "openDsh";
    repo = "aasdk";
    rev = "1bc0fe69d5f5f505c978a0c6e32c860e820fa8f6";
    sha256 = "sha256-Gqd+IHn3G3yU1/SSrp8B+isn1mhsGj2w41oMmSgkpQY=";
  };

  patches = [
    "${openDsh.src}/patches/aasdk_openssl-fips-fix.patch"
  ];

  nativeBuildInputs = [
    cmake
    protobuf_21
  ];

  buildInputs = [
    protobuf_21
    libusb1
    openssl
    boost177
  ];

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
  ];
}
