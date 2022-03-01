{ inputs, lib, hostName, extraModules, ... }:
with builtins; with lib; {
  imports = with inputs; flatten [
    (mapAttrsToList (n: v: v) self.nixosModules)
    (mapAttrsToList (n: v: v) nixos-wsl.nixosModules)
    ragenix.nixosModules.age
    nirgenx.nixosModules.nirgenx

    "${self}/host/${hostName}"
    extraModules
  ];
}
