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
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ragon = {
      url = "github:ragon000/nixos-config";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    comma = {
      flake = false;
      url = "github:Shopify/comma";
    };
    dotfiles = {
      url = "github:nzbr/dotfiles";
      flake = false;
    };
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
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
    let
      pkgs = nixpkgs.legacyPackages."${system}";
      naersk-lib = inputs.naersk.lib."${system}";
      baseLib = import ./lib/base.nix { inherit pkgs; lib = nixpkgs.lib; };
      lib = nixpkgs.lib.extend (self': super':
        with nixpkgs.lib; foldl recursiveUpdate { } (map (x: import x { inherit pkgs; lib = self'; }) (baseLib.findModules ".nix" ./lib))
      );
      scripts = (import ./scripts.nix) { inherit lib self; pkgs = (pkgs // self.packages.${system}); };
    in
    (with builtins; with nixpkgs; with lib; rec {

      inherit lib;

      devShell = pkgs.mkShell {
        buildInputs = with pkgs; with self.packages.${system}; [
          agenix
          rage

          git-crypt

          nixpkgs-fmt
        ]
        ++
        mapAttrsToList
          (name: drv: pkgs.writeShellScriptBin name "${pkgs.nixUnstable}/bin/nix run .#${name} \"$@\"")
          scripts;
      };

      apps = mapAttrs'
        (name: value:
          nameValuePair'
            name
            (flake-utils.lib.mkApp
              {
                inherit name;
                drv = pkgs.writeShellScriptBin name value;
              }
            )
        )
        scripts;

      packages =
        loadPackages pkgs ".pkg.nix" ./package # import all packages from pkg directory
        // inputs.agenix.packages.${system} # import all packages from agenix flake
        // {

          comma = pkgs.callPackage (import inputs.comma) { };

          wsld = naersk-lib.buildPackage {
            pname = "wsld";
            root = inputs.wsld;
            cargoBuildOptions = (default: default ++ [ "-p" "wsld" ]);
          };

          nixosConfigurations = (listToAttrs (map
            (hostName:
              lib.nameValuePair
                hostName
                (nixosSystem {
                  inherit system;
                  specialArgs = {
                    inherit lib inputs system;
                    root = "${self}";
                    assets = "${self}/assets";
                    host = "${self}/host/${hostName}";
                  };
                  modules = [
                    inputs.agenix.nixosModules.age

                    ({ pkgs, config, ... }: {

                      nixpkgs.config = {
                        allowUnfree = true;

                        packageOverrides =
                          {
                            local = self.packages."${system}"; # import local packages
                          } //
                          # import packages from inputs
                          lib.mapAttrs
                            (name: value: import value {
                              inherit system;
                              config = config.nixpkgs.config;
                            })
                            (with inputs; {
                              unstable = nixpkgs-unstable;
                              bleeding-edge = nixpkgs-bleeding-edge;
                              legacy = nixpkgs-legacy;
                              ragon = ragon;
                            });
                      };

                      # Let 'nixos-version --json' know about the Git revision
                      # of this flake.
                      system.configurationRevision = lib.mkIf (self ? rev) self.rev;

                      system.stateVersion = "21.05";
                    })

                    (import (./host + "/${hostName}"))
                  ];
                })
            )
            (mapAttrsToList (name: type: name) (readDir ./host))
          ));
        };

    }));
}
