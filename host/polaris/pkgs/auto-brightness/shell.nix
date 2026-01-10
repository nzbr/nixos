{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  buildInputs = [
    pkgs.tinycc
    pkgs.vlang
    (pkgs.python3.withPackages (ps: with ps; [ plotly ]))
  ];
}
