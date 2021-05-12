{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [
    (import "${builtins.fetchTarball https://github.com/rycee/home-manager/archive/release-20.09.tar.gz}/nixos")
  ];


  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    users =
      let
        # homeCfg = (import ../../home/home.nix) {config = config; lib = lib; pkgs = pkgs; };
        homeCfg = {
          imports = [
            ../../home/home.nix
          ];
        };
      in {
        root = homeCfg;
        nzbr = homeCfg;
      };
  };
}
