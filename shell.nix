{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    rage
    git-crypt

    # keep this line if you use bash
    bashInteractive
  ];
}
