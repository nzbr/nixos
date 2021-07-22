{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    git-crypt
    nixpkgs-fmt

    # keep this line if you use bash
    bashInteractive
  ];
}
