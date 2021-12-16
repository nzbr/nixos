{ config, lib, pkgs, modulesPath, ... }:
with builtins; with lib;
{
  options.nzbr.pattern.vmware.enable = mkEnableOption "VMWare Guest";

  config =
    let
      cfg = config.nzbr.pattern.vmware;
    in
    mkIf cfg.enable {
      boot = {
        loader = {
          systemd-boot.enable = true;
          efi.canTouchEfiVariables = true;
        };


        initrd = {
          availableKernelModules = [ "ata_piix" "mptspi" "uhci_hcd" "ehci_pci" "sd_mod" "sr_mod" ];
          kernelModules = [];
        };

        kernelModules = [];
        extraModulePackages = [];
      };

      networking.interfaces.ens33.useDHCP = true;

      virtualisation.vmware.guest.enable = true;
    };
}
