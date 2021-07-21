{
  description = "my very own special snowflake";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    home-manager.url = "github:nix-community/home-manager/release-21.05";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixos-wsl.url = "github:Trundle/NixOS-WSL";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.05";

    ragon = {
      url = "github:ragon000/nixos-config";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    comma = {
      flake = false;
      url = "github:Shopify/comma";
    };
    razer-nari = {
      flake = false;
      url = "github:imustafin/razer-nari-pulseaudio-profile";
    };
    vscode-server = {
      flake = false;
      url = "github:msteen/nixos-vscode-server";
    };
  };

  outputs = inputs @ {
    self,
    flake-utils,
    nixpkgs,
    ...
  # }: flake-utils.lib.eachDefaultSystem (system: with builtins; with nixpkgs; with lib; rec {
  }:
  let
    system = "x86_64-linux";
  in
  (with builtins; with nixpkgs; with lib; rec {
    nixosConfigurations = (listToAttrs (map
      (path:
        {
          name = removeSuffix ".nix" path;
          value = nixosSystem {
            inherit system;
            specialArgs = { inherit lib inputs system; };
            modules = [
              ({pkgs, ...}: {
                # Let 'nixos-version --json' know about the Git revision
                # of this flake.
                system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;

                system.stateVersion = "21.05";
              })
              (import (./machine + "/${path}"))
            ];
          };
        }
      )
      (mapAttrsToList (name: type: name) (readDir ./machine))
    ));
  });
}
