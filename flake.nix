{
  description = "my very own special snowflake";

  inputs = {
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixos-wsl.url = "github:nzbr/NixOS-WSL/WSLg";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.05";
    nixpkgs-legacy.url = "github:NixOS/nixpkgs/nixos-20.09";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-bleeding-edge.url = "github:NixOS/nixpkgs/master";

    flake-utils.url = "github:numtide/flake-utils";
    home-manager.url = "github:nix-community/home-manager/release-21.05";
    naersk.url = "github:nix-community/naersk"; # rust package builder

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
    wsld = {
      flake = false;
      url = "github:nbdd0121/wsld";
    };
  };

  outputs =
    inputs @ { self
    , flake-utils
    , nixpkgs
    , ...
    }: flake-utils.lib.eachDefaultSystem (system:
    # }:
    let
      # system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages."${system}";
      lib = nixpkgs.lib.extend (self: super: import ./lib { inherit pkgs; lib = self; });
      naersk-lib = inputs.naersk.lib."${system}";
    in
    (with builtins; with nixpkgs; with lib; rec {

      packages =
        lib.loadPackages pkgs ".pkg.nix" ./pkg # import all packages from pkg directory
        // {

          wsld = naersk-lib.buildPackage {
            pname = "wsld";
            root = inputs.wsld;
            cargoBuildOptions = (default: default ++ [ "-p" "wsld" ]);
          };

          nixosConfigurations = (listToAttrs (map
            (path:
              {
                name = removeSuffix ".nix" path;
                value = nixosSystem {
                  inherit system;
                  specialArgs = { inherit lib inputs system; local-pkgs = self.packages."${system}"; };
                  modules = [
                    ({ pkgs, ... }: {
                      # Let 'nixos-version --json' know about the Git revision
                      # of this flake.
                      system.configurationRevision = lib.mkIf (self ? rev) self.rev;

                      system.stateVersion = "21.05";
                    })
                    (import (./machine + "/${path}"))
                  ];
                };
              }
            )
            (mapAttrsToList (name: type: name) (readDir ./machine))
          ));
        };

    }));
}
