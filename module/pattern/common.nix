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
        source.enable = true;

        cli = {
          dotfiles.enable = true;
          lorri.enable = true;
          sudo.enable = true;
        };

        service = {
          ssh = {
            enable = true;
            authorizedSystems = [ "hurricane" "landslide" "meteor" ];
          };
          vscode-server-fix.enable = true;
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

      nix = {
        # Enable flake support
        package = pkgs.nixFlakes;
        extraOptions = "experimental-features = nix-command flakes";

        autoOptimiseStore = true;
        gc = {
          automatic = true;
          dates = "daily";
          options = "--delete-older-than 30d";
        };
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

        local.comma # TODO: Replace comma by something that just invokes nix-run

        # Move to a docker module
        docker-compose
      ];

      programs = {
        zsh.enable = true;
        mosh.enable = true;
        ssh = {
          setXAuthLocation = lib.mkForce true;
          startAgent = true;
        };
      };

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

      virtualisation = {
        docker.enable = true;
        oci-containers.backend = "docker";
      };
      users.groups.docker.members = [ config.nzbr.user ];
    };
}