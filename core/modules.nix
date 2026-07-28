{ inputs, lib, hostName, extraModules, ... }:
with builtins; with lib; {
  imports = with inputs; flatten [
    (mapAttrsToList (n: v: v) self.nixosModules)
    (mapAttrsToList (n: v: v) nixos-wsl.nixosModules)
    agenix.nixosModules.age
    nirgenx.nixosModules.nirgenx
    disko.nixosModules.disko

    "${self}/host/${hostName}"
    extraModules
  ];
}
