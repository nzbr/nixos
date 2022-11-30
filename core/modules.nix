{ inputs, lib, hostName, extraModules, ... }:
with builtins; with lib; {
  imports = with inputs; flatten [
    (mapAttrsToList (n: v: v) self.nixosModules)
    (mapAttrsToList (n: v: v) nixos-wsl.nixosModules)
    agenix.nixosModules.age
    nirgenx.nixosModules.nirgenx
    vscode-server.nixosModules.default
    xyno-experiments.nixosModule

    "${self}/host/${hostName}"
    extraModules
  ];
}
