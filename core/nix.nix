{ inputs, config, pkgs, lib, system, ... }:
with builtins; with lib;
let
  hostPkgs =
    if hasAttr "package" (readDir config.nzbr.flake.host)
    then
      (
        # This abomination allows to have packages from foreign architectures that are specific to a system (armv7l-linux on an aarch64-linux system)
        let
          dir = "${config.nzbr.flake.host}/package";
          pkgsBySystem = sys: (
            let
              nixpkgs =
                if sys == "armv7l-linux" # Needed to use the armv7 binary-cache
                then inputs.nixpkgs-unstable
                else inputs.nixpkgs;
            in
            import "${nixpkgs}" { system = sys; }
          );
        in
        mapAttrs'
          (name: type:
            let
              specialArgs = { inherit inputs config lib; };
              specialArgs' = { inherit inputs config lib; } // hostPkgs;
              drv = (import "${inputs.nixpkgs}" { inherit system; }).callPackage "${dir}/${name}" specialArgs;
            in
            nameValuePair'
              (drv.name)
              (
                if elem system (orElse drv.meta "platforms" [ system ])
                then (pkgsBySystem system).callPackage "${dir}/${name}" specialArgs'
                else (pkgsBySystem (head drv.meta.platforms)).callPackage "${dir}/${name}" specialArgs'
              )
          )
          (readDir dir)
      )
    else { };
in
{
  nixpkgs.config = {
    allowUnfree = true;

    packageOverrides =
      hostPkgs
      // {
        local = inputs.self.packages.${system}; # import local packages
        rnix-lsp = inputs.rnix-lsp.packages.${system};
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
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';

    binaryCaches = [
      # "https://thefloweringash-armv7.cachix.org"
    ];
    binaryCachePublicKeys = [
      # "thefloweringash-armv7.cachix.org-1:v+5yzBD2odFKeXbmC+OPWVqx4WVoIVO6UXgnSAWFtso="
    ];

    autoOptimiseStore = true;
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
