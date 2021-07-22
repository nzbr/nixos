{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    git-crypt

    # keep this line if you use bash
    bashInteractive
  ];
}
