{ config, lib, pkgs, inputs, ... }:
with builtins; with lib; {

  nzbr = {
    system = "x86_64-linux";
    patterns = [ "common" "wsl" "development" ];
    # pattern.development.guiTools = true;

    remoteNixBuild.enable = true;

    program = {
      latex.enable = true;
    };

    service.syncthing.enable = true;
    service.libvirtd.enable = true;
  };

  services.syncthing.guiAddress = "127.0.0.1:8385";

  fileSystems."/tmp".options = mkForce [ "size=16G" ];

  nix.distributedBuilds = true;
  nix.extraOptions = ''
    builders-use-substitutes = true
  '';
  nix.settings.trusted-users = [
    "nzbr"
  ];

  # boot.binfmt.emulatedSystems = [ "aarch64-linux" "armv7l-linux" "armv6l-linux" ];
  wsl.interop.register = true;

  users.groups.kvm.members = [ "nzbr" ];

  environment.systemPackages = config.environment.windowsPackages;
  environment.windowsPackages = with pkgs; [
    eternal-terminal
    mosh
    qemu
  ];

  system.stateVersion = "22.05";
  nzbr.home.config.home.stateVersion = "22.05";
}
