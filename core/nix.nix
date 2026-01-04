{ inputs, config, pkgs, lib, system, ... }:
with builtins; with lib;
{
  nixpkgs.config = {
    allowUnfree = true;
    nvidia.acceptLicense = true;

    packageOverrides = {
      local = inputs.self.packages.${system}; # import local packages
      nixd = inputs.nixd.packages.${system};
    } //
    # import packages from inputs
    lib.mapAttrs
      (name: value: import value {
        inherit system;
        config = config.nixpkgs.config;
      })
      (with inputs; {
        unstable = nixpkgs-unstable;
      });
  };

  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';

    settings = {
      substituters = [
        # "https://thefloweringash-armv7.cachix.org"
        "https://nzbr-nix-cache.s3.eu-central-1.wasabisys.com"
      ];
      trusted-public-keys = [
        # "thefloweringash-armv7.cachix.org-1:v+5yzBD2odFKeXbmC+OPWVqx4WVoIVO6UXgnSAWFtso="
        "nzbr-nix-cache.s3.eu-central-1.wasabisys.com:3BzCCe4Frvvwamd5wibtMAcEKwbVs4y2xKUR2vQ8gIo="
      ];
      auto-optimise-store = true;
    };

    registry.nixpkgs = {
      from = {
        id = "nixpkgs";
        type = "indirect";
      };
      exact = true;
      flake = inputs.nixpkgs;
    };

    gc = {
      automatic = mkDefault false;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  system.build.package = hostPkgs; # For building with nix build

  # Let 'nixos-version --json' know about the Git revision
  # of this flake.
  system.configurationRevision = lib.mkIf (inputs.self ? rev) inputs.self.rev;
}
