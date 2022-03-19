{ config, lib, pkgs, ... }:
with builtins; with lib;
{
  options.nzbr.pattern.vmware.enable = mkEnableOption "VMWare Guest";

  config =
    let
      cfg = config.nzbr.pattern.vmware;
    in
    mkIf cfg.enable {

      nzbr.boot.grub.enable = true;

      boot = {
        loader = {
          efi.canTouchEfiVariables = false;
          grub.efiInstallAsRemovable = true;
        };


        initrd = {
          availableKernelModules = [ "ata_piix" "mptspi" "uhci_hcd" "ehci_pci" "sd_mod" "sr_mod" ];
          kernelModules = [ ];
        };

        kernelModules = [ ];
        extraModulePackages = [ ];
      };

      networking.usePredictableInterfaceNames = true;
      networking.interfaces.ens33.useDHCP = true;

      systemd.network.enable = false;

      virtualisation.vmware.guest.enable = true;
    };
}
