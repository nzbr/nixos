{ config, lib, pkgs, modulesPath, ... }:
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
    androidComposition.androidsdk

    desktop-file-utils
    flutter
    global
    go
    python3
    unstable.dotnet-sdk_5
    unstable.tabnine
  ];

  nixpkgs.config.android_sdk.accept_license = true;

  system.activationScripts.flutter-sdk.text = ''
    echo "setting up /run/flutter..."
    ln -snf ${pkgs.flutter.unwrapped} /run/flutter
  '';
}
