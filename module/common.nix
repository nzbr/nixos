{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [
    ./common/cli/dotfiles.nix
    ./common/cli/lorri.nix
    ./common/cli/shell-init.nix
    ./common/cli/sudo.nix
    ./common/gpg.nix
    ./common/home-manager.nix
    ./common/nix-store.nix
    ./common/service/docker.nix
    ./common/service/ssh.nix
    ./common/vscode-server.nix
  ];

  # flakey flakey, rise and shine
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = "experimental-features = nix-command flakes";
  };

  environment.systemPackages = with pkgs; [
    file
    git
    gnupg
    htop
    inetutils
    killall
    rsync
    stow
    tmux
    vim
    wget

    cabextract
    p7zip
    unzip
    zip

    ntfs3g

    local.comma
  ];

  programs.zsh.enable = true;

  i18n = {
    defaultLocale = "de_DE.UTF-8";
    supportedLocales = lib.mkDefault [
      "de_DE.UTF-8/UTF-8"
      "en_US.UTF-8/UTF-8"
    ];
  };
  console.keyMap = "de-latin1";

  time.timeZone = "Europe/Berlin";

  networking.useDHCP = false; # Is deprecated and has to be set to false

  networking.firewall = {
    enable = true;
    allowPing = true;
    allowedTCPPorts = [ ];
    allowedUDPPorts = [ ];
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
    "kernel.sysrq" = 1;
    "vm.swappiness" = 1;
  };

  hardware.enableRedistributableFirmware = true;
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
}
