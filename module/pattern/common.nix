{ config, lib, pkgs, modulesPath, ... }:
with builtins; with lib;
{
  options.nzbr.pattern.common.enable = mkEnableOption "Common default settings suited for any kind of system";

  config =
    let
      cfg = config.nzbr.pattern.common;
    in
    mkIf cfg.enable {

      nzbr = {
        agenix.enable = lib.mkDefault true;
        channels.enable = true;

        cli = {
          dotfiles.enable = true;
          direnv.enable = true;
          sudo.enable = true;
        };

        service = {
          ssh = {
            enable = true;
            authorizedSystems = [ "hurricane" "landslide" "meteor" "pulsar" ];
          };
        };

        home.config = {
          home.file.cache-marker = {
            target = ".cache/CACHEDIR.TAG";
            text = ''
              Signature: 8a477f597d28d172789f06886806bc55
            '';
          };
        };
      };

      environment.systemPackages = with pkgs; [
        bat
        btop
        diskus
        exa
        file
        git
        gnupg
        htop
        inetutils
        killall
        neofetch
        pv
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

        local."import"
        local.comma
      ];

      programs = {
        zsh.enable = true;
        mosh.enable = true;
        ssh = {
          setXAuthLocation = lib.mkForce true;
          startAgent = true;
        };
      };

      services.vscode-server.enable = mkDefault true;

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
        users.${config.nzbr.user} = {
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
    };
}
