{ config, lib, pkgs, ... }:
{

  nixpkgs.overlays = [
    (final: prev: {
      autoBrightness = prev.callPackage ../pkgs/auto-brightness/default.nix { };
    })
  ];

  # From https://wiki.archlinux.org/title/Backlight
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chgrp video $sys$devpath/brightness", RUN+="${pkgs.coreutils}/bin/chmod g+w $sys$devpath/brightness"
  '';

  users.groups.video.members = [ config.nzbr.user ];

  environment.etc."auto-brightness.json".text = lib.generators.toJSON { } {
    app = {
      interval = 33;
      average_samples = 100;
    };
    hw = {
      illuminance_sensor = "/sys/bus/iio/devices/iio\:device0/in_illuminance0_input";
      backlight_device = "/sys/class/backlight/rpi_backlight";
    };
    brightness = {
      min_brightness = 10;
      max_illuminance = 750;
    };
    theme = {
      required_exceeding_samples = 500;
      dark_threshold = 1000;
      dark = {
        color_scheme = "BreezeDark";
        accent_color = "#00E600";
      };
      light_threshold = 2000;
      light = {
        color_scheme = "BreezeLight";
        accent_color = "#8000FF";
      };
    };
  };

  nzbr.home.config.systemd.user.services.auto-brightness = {
    Unit = {
      Description = "Auto Brightness Service";
      After = [ "plasma-workspace.target" ];
      Wants = [ "plasma-workspace.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.autoBrightness}/bin/auto-brightness";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  system.build.autoBrightness = pkgs.autoBrightness;

}
