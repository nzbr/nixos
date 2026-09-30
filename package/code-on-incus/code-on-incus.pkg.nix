{
  lib,
  buildGoModule,
  pkg-config,
  systemd,
  incus,
  iptables,
  makeWrapper,
  nftables,
  inputs,
  ...
}:

buildGoModule rec {
  name = "code-on-incus";

  src = inputs.code-on-incus;
  patches = [ ./skip-nic-security-on-wsl.patch ];

  vendorHash = "sha256-XSTbxBrLzHBNLhzCz7aDqZ5ioaQlZgIWexjtpbX9xk0=";
  subPackages = [ "cmd/coi" ];

  nativeBuildInputs = [ pkg-config makeWrapper ];
  buildInputs = [ systemd ];

  preBuild = ''
    mkdir -p internal/config/embedded internal/image/embedded
    cp profiles/default/config.toml internal/config/embedded/default_config.toml
    cp testdata/dummy/dummy internal/image/embedded/dummy
  '';

  postInstall = ''
    wrapProgram "$out/bin/coi" --prefix PATH : ${lib.makeBinPath [ incus iptables nftables ]}
  '';
}
