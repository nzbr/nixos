{ options, config, lib, pkgs, modulesPath, ... }:
with builtins; with lib;
{
  options.nzbr.pattern.development = {
    enable = mkEnableOption "Development Tools";
    guiTools = mkEnableOption "GUI Tools";
  };

  config = mkIf config.nzbr.pattern.development.enable (
    {
      environment.systemPackages = with pkgs; [
        # androidComposition.androidsdk

        gh
        gnumake
        nix-output-monitor
        powershell
        # (python3.withPackages (pypi: with pypi; [
        #   autopep8
        #   black
        #   ipykernel
        # ]))
        conda
        mamba

        # Language servers
        unstable.nil
        nixd.nixd

      ] ++ (
        if config.nzbr.pattern.development.guiTools then
          [
            jetbrains.idea-ultimate
            jetbrains.rider
            gitkraken
          ] ++ (if config.nzbr.pattern.wsl.enable then [ ] else [
            vscode
            scrcpy
            lens
            insomnia
          ])
        else [ ]
      );

      environment.variables =
        let
          devPkgs = with pkgs; [
            glib
            gtk3
          ];
        in
        {
          PKG_CONFIG_PATH = concatStringsSep ":" (
            map
              (pkg: "${pkg.dev}/lib/pkgconfig")
              devPkgs
          );
          CMAKE_PREFIX_PATH = "${pkgs.cmake}:${pkgs.pkg-config}:" + concatStringsSep ":" (
            map
              (pkg: "${pkg.dev}")
              devPkgs
          );
          CHROME_EXECUTABLE = "${pkgs.chromium}/bin/chromium";
        };

      programs.nix-ld.enable = true;

      nzbr.cli.git = {
        enable = true;
        userInfo = true;
      };

      programs.adb.enable = true;
      users.groups.adbusers.members = [ config.nzbr.user ];

      virtualisation.docker.enable = mkDefault true;
    }
  );
}
