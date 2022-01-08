{ inputs, config, lib, system, ... }:
with builtins; with lib; {
  nixpkgs.config = {
    allowUnfree = true;

    packageOverrides =
      {
        local = inputs.self.packages.${system}; # import local packages
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

  nix = {
    binaryCaches = [
      "https://thefloweringash-armv7.cachix.org"
    ];
    binaryCachePublicKeys = [
      "thefloweringash-armv7.cachix.org-1:v+5yzBD2odFKeXbmC+OPWVqx4WVoIVO6UXgnSAWFtso="
    ];
  };

  # Let 'nixos-version --json' know about the Git revision
  # of this flake.
  system.configurationRevision = lib.mkIf (inputs.self ? rev) inputs.self.rev;

  system.stateVersion = "21.11";
}
