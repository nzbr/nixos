{ config, lib, pkgs, ... }:
with lib; {

  options.nzbr.nix-ld.enable = mkEnableOption "support for running foreign dynamic binaries";

  config = mkIf config.nzbr.nix-ld.enable {
    programs.nix-ld.enable = true;
    environment.variables = {
      NIX_LD_LIBRARY_PATH = lib.makeLibraryPath [
        pkgs.stdenv.cc.cc
      ];
      NIX_LD = "${pkgs.glibc}/lib/ld-linux-x86-64.so.2";
    };
  };
}
