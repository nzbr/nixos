{ config, lib, pkgs, modulesPath, root, ... }:
{
  imports = [
    ./common/agenix.nix
    ./common/initrd-secrets.nix
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
    bat
    exa
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
  console.keyMap = "us";

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
      passwordFile = config.nzbr.assets."root.password";
    };
    users.nzbr = {
      isNormalUser = true;
      passwordFile = config.nzbr.assets."nzbr.password";
      extraGroups = [ "wheel" "plugdev" ];
    };
  };

  boot.kernel.sysctl = {
    "kernel.sysrq" = 1;
    "vm.swappiness" = 1;
  };

  hardware.enableRedistributableFirmware = true;
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";

  # TODO: Move this somewhere else
  age.secrets."ssh/id_ed25519".owner = "nzbr";
}
