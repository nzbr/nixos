{ config, lib, pkgs, modulesPath, ... }:
with builtins; with lib;
{
  options.nzbr.pattern.development.enable = mkEnableOption "Development Tools";

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

        desktop-file-utils
        gcc
        global
        go
        kubectl
        kubernetes-helm
        python3
        unstable.flutter
        unstable.dotnet-sdk_5
        unstable.tabnine
      ] ++ (
        if config.nzbr.pattern.desktop.enable then
          [
            jetbrains.idea-ultimate

            unstable.lens
            unstable.gitkraken
            unstable.insomnia
            vscode

            unstable.timeular

            scrcpy
          ]
        else [ ]
      );

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
              flutter = flutter.unwrapped;
              node12 = nodejs-12_x;
              node14 = nodejs-14_x;
              inherit yarn;
            }
        )
      );

      programs.adb.enable = true;
      users.groups.adbusers.members = [ config.nzbr.user ];

      services.udev.packages = [
        pkgs.android-udev-rules
      ];
    }
  );
}