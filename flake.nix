{
  description = "my very own special snowflake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11";
    nixpkgs-legacy.url = "github:NixOS/nixpkgs/nixos-21.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-bleeding-edge.url = "github:NixOS/nixpkgs/master";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      url = "github:nix-community/home-manager/release-21.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nzbr/NixOS-WSL";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    naersk = {
      # rust package builder
      url = "github:nix-community/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    kubenix = {
      url = "github:nzbr/kubenix";
      inputs.flake-compat.follows = "flake-compat";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    comma = {
      flake = false;
      url = "github:Shopify/comma";
    };
    dotfiles = {
      url = "github:nzbr/dotfiles";
      # TODO: submodules = true;
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
    # ceph-csi = {
    #   flake = false;
    #   url = "github:ceph/ceph-csi/release-v3.4";
    # };
  };

  outputs =
    inputs @ { self
    , flake-utils
    , nixpkgs
    , ...
    }:
    let
      baseLib = import ./lib/base.nix { lib = nixpkgs.lib; };
      lib = with nixpkgs.lib; foldl recursiveUpdate nixpkgs.lib ((map (x: import x { inherit lib; }) (baseLib.findModules ".nix" ./lib)) ++ [ inputs.kubenix.lib ]);
    in
    {
      inherit lib;

      nixosModules = map
        (file: import file)
        (lib.findModules ".nix" "${self}/module");
    } //
    (flake-utils.lib.eachDefaultSystem
      (system:
      let
        pkgs = nixpkgs.legacyPackages."${system}";
        naersk-lib = inputs.naersk.lib."${system}";
        scripts = (import ./scripts.nix) { inherit lib self; pkgs = (pkgs // self.packages.${system}); };
      in
      (with builtins; with nixpkgs; with lib; {

        devShell = pkgs.mkShell {
          buildInputs = with pkgs; with self.packages.${system}; [
            agenix
            morph
            nixpkgs-fmt
            rage
            inputs.kubenix.packages.${system}.helm-update
            inputs.kubenix.packages.${system}.yaml2nix
          ]
          ++
          mapAttrsToList
            (name: drv: pkgs.writeShellScriptBin name "set -ex\nexec ${pkgs.nixUnstable}/bin/nix run .#${name} \"$@\"")
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

            nixosConfigurations =
              let
                mkDefaultSystem = hostName: mkSystem hostName [ ];
                mkSystem = hostName: extraModules: (nixosSystem {
                  inherit system;
                  specialArgs = {
                    inherit lib inputs system;
                  };
                  modules =
                    [
                      ({ pkgs, config, ... }: {

                        imports = flatten [
                          inputs.agenix.nixosModules.age
                          inputs.kubenix.nixosModules
                        ];

                        nixpkgs.config = {
                          allowUnfree = true;

                          packageOverrides =
                            {
                              local = self.packages.${system}; # import local packages
                            } //
                            # import packages from inputs
                            lib.mapAttrs
                              (name: value: import value {
                                inherit system;
                                config = config.nixpkgs.config;
                              })
                              (with inputs; {
                                legacy = nixpkgs-legacy;
                                unstable = nixpkgs-unstable;
                                bleeding-edge = nixpkgs-bleeding-edge;
                              });
                        };

                        nix.envVars.TMPDIR = "/nix/build";
                        systemd.tmpfiles.rules = [
                          "d /nix/build 0777 root root"
                        ];

                        # Let 'nixos-version --json' know about the Git revision
                        # of this flake.
                        system.configurationRevision = lib.mkIf (self ? rev) self.rev;

                        system.stateVersion = "21.11";
                      })

                      ({ ... }: {
                        imports = self.nixosModules;

                        config = {
                          nzbr.flake = {
                            root = "${self}";
                            assets = "${self}/asset";
                            host = "${self}/host/${hostName}";
                          };
                        };
                      })

                      ({ ... }: {
                        imports = [
                          "${self}/host/${hostName}/default.nix"
                        ] ++ extraModules;
                      })
                    ];
                });
              in
              (listToAttrs (map
                (hostName:
                  lib.nameValuePair
                    hostName
                    (
                      (
                        mkDefaultSystem hostName
                      ) // (
                        mapAttrs'
                          (n: v: nameValuePair' (removeSuffix ".nix" n) (mkSystem hostName [ "${self}/host/${hostName}/${n}" ]))
                          (
                            filterAttrs
                              (n: v: (v == "regular") && (hasSuffix ".nix" n) && (n != "default.nix"))
                              (readDir "${self}/host/${hostName}")
                          )
                      ) // (
                        mapAttrs'
                          (n: v: nameValuePair' n (mkSystem hostName [ v ]))
                          inputs.nixos-generators.nixosModules
                      )
                    )
                )
                (mapAttrsToList (name: type: name) (readDir "${self}/host"))
              ));
          };

      }))
    );
}
