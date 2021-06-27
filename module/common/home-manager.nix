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
        homeCfg = {
          imports = [
            (import ../../home/home.nix {sys=config;})
          ];
        };
      in {
        root = homeCfg;
        nzbr = homeCfg;
      };
  };
}
