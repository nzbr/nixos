{ config, lib, pkgs, modulesPath, ... }:
with builtins; with lib;
{
  options.nzbr.pattern.development = {
    enable = mkEnableOption "Development Tools";
    guiTools = mkEnableOption "GUI Tools";
  };

  config = mkIf config.nzbr.pattern.development.enable (
    let
      androidComposition = pkgs.unstable.androidenv.composeAndroidPackages {
        toolsVersion = "26.1.1";
        platformToolsVersion = "31.0.2";
        buildToolsVersions = [ "30.0.3" ];
        includeEmulator = false;
        emulatorVersion = "30.0.10";
        platformVersions = [ "30" ];
        includeSources = false;
        includeSystemImages = false;
        systemImageTypes = [ "google_apis_playstore" ];
        abiVersions = [ "armeabi-v7a" "arm64-v8a" ];
        cmakeVersions = [ "3.10.2" ];
        includeNDK = true;
        ndkVersions = [ "22.0.7026061" ];
        useGoogleAPIs = true;
        useGoogleTVAddOns = true;
        includeExtras = [
          "extras;google;gcm"
        ];
      };
    in
    {
      environment.systemPackages = with pkgs; [
        # androidComposition.androidsdk

        clang
        cmake
        desktop-file-utils
        docker-compose
        dotnet-sdk
        entr
        gcc
        gh
        git-crypt
        global
        gnumake
        go
        google-cloud-sdk
        gtk3
        kubectl
        kubernetes-helm
        ninja
        pkg-config
        powershell
        (python3.withPackages (pypi: with pypi; [
          autopep8
          black
          ipykernel
        ]))
        unstable.flutter

        # Language servers
        rnix-lsp.rnix-lsp
        unstable.nil

      ] ++ (
        if config.nzbr.pattern.development.guiTools then
          [
            jetbrains.idea-ultimate
            gitkraken
            remmina
          ] ++ (if config.nzbr.pattern.wsl.enable then [ ] else [
            vscode
            timeular
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

      nzbr.nix-ld.enable = true;

      nzbr.cli.git = {
        enable = true;
        userInfo = true;
      };

      nixpkgs.config.android_sdk.accept_license = true;

      system.activationScripts.sdks.text = with pkgs; concatStringsSep "\n" (
        [ "mkdir -p /run/sdk" ]
        ++ (
          mapAttrsToList
            (name: pkg: "ln -vsnf ${pkg} /run/sdk/${name}")
            {
              flutter = unstable.flutter.unwrapped;
              node14 = nodejs-14_x;
              inherit jdk11;
              inherit yarn;
            }
        )
      );

      programs.adb.enable = true;
      users.groups.adbusers.members = [ config.nzbr.user ];

      services.udev.packages = [
        pkgs.android-udev-rules
      ];

      virtualisation.docker.enable = mkDefault true;

      programs.ssh.forwardX11 = true;
    }
  );
}
