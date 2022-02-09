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
      inputs.flake-compat.follows = "flake-compat";
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

    dotfiles = {
      url = "github:nzbr/dotfiles";
      # TODO: submodules = true; (once that is supported)
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
    with builtins; with lib; {
      inherit lib;

      nixosModules =
        let
          modulesPath = "${self}/module";
        in
        listToAttrs (
          map
            (file:
              nameValuePair'
                (removePrefix "${modulesPath}/" file)
                (import file)
            )
            (lib.findModules ".nix" modulesPath)
        );

      nixosConfigurations =
        let
          allConfigs = system:
            let
              mkDefaultSystem = hostName: mkSystem hostName [ ];
              mkSystem = hostName: extraModules: (nixosSystem {
                inherit system;
                specialArgs = {
                  inherit lib inputs system hostName extraModules;
                };
                modules =
                  [
                    {
                      imports = mapAttrsToList
                        (name: type: "${self}/core/${name}")
                        (readDir "${self}/core");

                      nzbr.flake = {
                        root = "${inputs.self}";
                        assets = "${inputs.self}/asset";
                        host = "${inputs.self}/host/${hostName}";
                      };
                    }
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
                    ) # // (
                    #   mapAttrs'
                    #     (n: v: nameValuePair' n (mkSystem hostName [ v ]))
                    #     inputs.nixos-generators.nixosModules
                    # )
                  )
              )
              (mapAttrsToList (name: type: name) (readDir "${self}/host"))
            ));
        in
        mapAttrs
          (n: v:
            (allConfigs v.config.nzbr.system).${n}
              // (
              mapAttrs
                (n': v': allSystems.${v'.config.nzbr.system}.${n}.${n'})
                (filterAttrs (n': v': v' ? config.nzbr) v)
            )
          )
          (allConfigs "x86_64-linux");
    } //
    (flake-utils.lib.eachSystem
      lib.systems.supported.nzbr
      (system:
      let
        pkgs = (import "${inputs.nixpkgs}" { inherit system; });
        naersk = pkgs.callPackage "${inputs.naersk}" { };
        scripts = (
          # legacy scripts.nix
          mapAttrs (name: script: pkgs.writeShellScriptBin name script) ((import ./scripts.nix) { inherit lib self; pkgs = (pkgs // self.packages.${system}); })
        ) // (
          # collect from script directory
          listToAttrs (
            map
            (file: rec {
              name = unsafeDiscardStringContext (replaceStrings [ "/" ] [ "-" ] (removePrefix "${self}/script/" file)); # this is safe, actually
              value = pkgs.substituteAll {
                inherit name;
                src = file;
                dir = "bin";
                isExecutable = true;

                # packages that are available to the scripts
                inherit (pkgs)
                  bash
                  gnused
                  jq
                  nixFlakes
                  python3
                  rage
                  wireguard
                  ;
                nixpkgs = toString inputs.nixpkgs;
              };
            })
            (findModules "" "${self}/script")
          )
        );
      in
      (with builtins; with nixpkgs; with lib; rec {

        devShell = pkgs.mkShell {
          buildInputs =
            let
              ifAvailable = collection: package: (orElse collection system { ${package} = [ ]; }).${package};
            in
            with pkgs; (flatten [
              (ifAvailable inputs.agenix.packages "agenix")
              morph
              nixpkgs-fmt
              rage
              (ifAvailable inputs.kubenix.packages "helm-update")
              (ifAvailable inputs.kubenix.packages "yaml2nix")
            ])
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
                  drv = value;
                }
              )
          )
          scripts // packages;

        packages =
          filterAttrs
            (name: pkg: (elem system (orElse pkg.meta "platforms" [ system ])))
            (
              loadPackages pkgs { inherit inputs naersk; } ".pkg.nix" ./package # import all packages from pkg directory
            );

      }))
    );
}
