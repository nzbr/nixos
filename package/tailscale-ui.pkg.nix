{ buildGoModule
, lib
, fetchFromGitHub
, go
, pkg-config
, glib
, cairo
, pango
, gtk3
, libappindicator-gtk3
, ...
}:

buildGoModule rec {
  pname = "tailscale-ui";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "muchobien";
    repo = "tailscale-ui";
    rev = "6e2fdafa22e7d81386a89a8c71c8797acf02c553";
    sha256 = "ch6x+lP/+H5bPy/0pD/weZq3UR9JBJmA6A7oPnZXHeE=";
  };

  vendorSha256 = "1E/txWecZdJVY9i/BaHsI0GGKdPydyBXVCeqVtdQei4=";

  proxyVendor = true;

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    glib
    cairo
    pango
    gtk3
    libappindicator-gtk3
  ];

  meta = with lib; {
    description = "Tailscale User Interface for Ubuntu";
    homepage = "https://github.com/muchobien/tailscale-ui";
    maintainers = with maintainers; [ nzbr ];
    platforms = platforms.linux;
  };
}
