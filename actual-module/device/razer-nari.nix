{ config, lib, inputs, pkgs, modulesPath, ... }:
with builtins; with lib; {
  options.nzbr.device.razerNari = with types; {
    enable = mkEnableOption "Razer Nari Pulseaudio Profile";
    pulseaudioPackage = mkOption {
      default = pkgs.pulseaudioFull;
      type = package;
      description = "The base Pulseaudio package that will be extended with the profile";
    };
  };

  config =
    let
      cfg = config.nzbr.device.razerNari;
    in
    mkIf cfg.enable {
      services.udev.extraRules = builtins.readFile "${inputs.razer-nari}/91-pulseaudio-razer-nari.rules";

      hardware.pulseaudio = {
        package = pkgs.pulseaudioRazerNari;
      };

      nixpkgs.overlays = [
        (self: super: {
          pulseaudioRazerNari = cfg.pulseaudioPackage.overrideAttrs (oldAttrs: rec {
            preFixup = oldAttrs.preFixup + ''
              mkdir -p $out/share/pulseaudio/alsa-mixer/{profile-sets,paths}
              cp ${inputs.razer-nari}/razer-nari-input.conf $out/share/pulseaudio/alsa-mixer/paths/
              cp ${inputs.razer-nari}/razer-nari-output-{game,chat}.conf $out/share/pulseaudio/alsa-mixer/paths/
              cp ${inputs.razer-nari}/razer-nari-usb-audio.conf $out/share/pulseaudio/alsa-mixer/profile-sets/
            '';
          });
        })
      ];
    };
}
