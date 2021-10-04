{ config, lib, pkgs, modulesPath, ... }:
with builtins; with lib;
{
  options.nzbr.pattern.laptop.enable = mkEnableOption "Default settings for laptops";

  config =
    let
      cfg = config.nzbr.pattern.laptop;
    in
    mkIf cfg.enable {
      nzbr.pattern.desktop.enable = lib.mkDefault true;

      services.thermald.enable = true;
      services.power-profiles-daemon.enable = false;
      services.tlp = {
        enable = true;
        settings = {
          "CPU_SCALING_GOVERNOR_ON_AC" = "ondemand"; # one of ondemand, conservative, performance, powersave, userland
          "CPU_SCALING_GOVERNOR_ON_BAT" = "powersave";
          "CPU_ENERGY_PERF_POLICY_ON_AC" = "balance_performance"; # one of performance, balance_performance, default, balance_power, power
          "CPU_ENERGY_PERF_POLICY_ON_BAT" = "power";
          "CPU_BOOST_ON_AC" = 1; # Turbo-Boost
          "CPU_BOOST_ON_BAT" = 0;
        };
      };

      services.logind = {
        lidSwitch = "hibernate";
        lidSwitchDocked = "ignore";
        lidSwitchExternalPower = "hybrid-sleep";
      };
    };
}
