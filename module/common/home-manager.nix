{ config, lib, inputs, pkgs, modulesPath, ... }:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];


  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    users =
      let
        homeCfg = {
          imports = [
            (import ../../home/home.nix { sys = config; })
          ];
        };
      in
      {
        root = homeCfg;
        nzbr = homeCfg;
      };
  };
}
