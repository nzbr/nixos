{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [
    common/cli/dotfiles.nix
    common/cli/lorri.nix
    common/cli/sudo.nix
    common/gpg.nix
    common/home-manager.nix
    common/nix-store.nix
    common/nixpkgs.nix
    common/service/ssh.nix
    common/vscode-server.nix
  ];

  environment.systemPackages = with pkgs; [
    file
    git
    gnupg
    killall
    stow
    vim
    wget
  ];

  programs.zsh.enable = true;

  i18n = {
    defaultLocale = "de_DE.UTF-8";
    supportedLocales = [
      "de_DE.UTF-8/UTF-8"
      "en_US.UTF-8/UTF-8"
    ];
  };
  console.keyMap = "de-latin1";

  time.timeZone = "Europe/Berlin";

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [];
    allowedUDPPorts = [];
  };

  users = {
    defaultUserShell = pkgs.zsh;
    mutableUsers = false;
    users.root = {
      hashedPassword = lib.removeSuffix "\n" (builtins.readFile (builtins.toString ../secret/common/root.password));
    };
    users.nzbr = {
      isNormalUser = true;
      hashedPassword = lib.removeSuffix "\n" (builtins.readFile (builtins.toString ../secret/common/nzbr.password));
      extraGroups = [ "wheel" ];
    };
  };

  boot.kernel.sysctl = {
    "vm.swappiness" = 1;
  };

  hardware.enableRedistributableFirmware = true;
  powerManagement.cpuFreqGovernor = "ondemand";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  # Did you read the comment?
  system.stateVersion = "20.09";
}
