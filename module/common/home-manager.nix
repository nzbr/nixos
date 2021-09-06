{ config, lib, inputs, pkgs, modulesPath, root, ... }:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];


  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    extraSpecialArgs = { sys = config; inherit root; };
    users =
      let
        homeCfg = {
          imports = [
            (import ../../home/home.nix)
          ];
        };
      in
      {
        root = homeCfg;
        ${config.nzbr.user} = homeCfg;
      };
  };
}
