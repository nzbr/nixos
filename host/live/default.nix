{ config, lib, inputs, pkgs, modulesPath, root, ... }:
{
  networking.hostName = "live";
  nzbr.user = "live";

  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-base.nix"
    "${modulesPath}/installer/cd-dvd/channel.nix"

    "${root}/module/common.nix"
    # desktop.nix contents are provided within this file
    "${root}/module/desktop/gnome.nix"
    "${root}/module/desktop/theme"
    "${root}/module/desktop/pulseaudio.nix"
    "${root}/module/desktop/device/razer-nari.nix"
  ];


  environment.systemPackages = with pkgs; [

    # partitioning and recovery tools
    ddrescue
    fsarchiver
    gparted
    partimage
    squashfsTools
    testdisk
    testdisk-qt

    # Needed for the dotfiles
    antibody

    # Desktop packages
    unstable.vivaldi
    unstable.vivaldi-ffmpeg-codecs
    vlc
    xsel
    lm_sensors
    gnome.gnome-tweak-tool
  ];

  ### GRAPHICAL BASE ###

  # Whitelist wheel users to do anything
  # This is useful for things like pkexec
  #
  # WARNING: this is dangerous for systems
  # outside the installation-cd and shouldn't
  # be used anywhere else.
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';

  # KDE complains if power management is disabled (to be precise, if
  # there is no power management backend such as upower).
  powerManagement.enable = true;


  ### CUSTOM ###

  fonts.fonts = with pkgs; [
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    roboto
    roboto-slab
    roboto-mono
  ];

  isoImage = {
    edition = "nzbr";
    isoName = with config.system.nixos; with config.isoImage; lib.mkForce "${isoBaseName}-${edition}-${release}-${codeName}-${pkgs.stdenv.hostPlatform.system}.iso";
  };

  users.users.${config.nzbr.user} = {
    uid = 1000;
    extraGroups = [ "networkmanager" ];
  };
  services.getty.autologinUser = lib.mkForce config.nzbr.user;

  services = {
    xserver = {
      enable = true;
      libinput.enable = true;

      ### GNOME ###

      desktopManager.gnome.favoriteAppsOverride = lib.mkForce ''
        [org.gnome.shell]
        favorite-apps=[ 'vivaldi-stable.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Terminal.desktop', 'org.gnome.DiskUtility.desktop', 'gparted.desktop' ]
      '';

      displayManager = {
        gdm = {
          wayland = false;
          # autoSuspend makes the machine automatically suspend after inactivity.
          # It's possible someone could/try to ssh'd into the machine and obviously
          # have issues because it's inactive.
          # See:
          # * https://github.com/NixOS/nixpkgs/pull/63790
          # * https://gitlab.gnome.org/GNOME/gnome-control-center/issues/22
          autoSuspend = false;
        };
      };
    };

    flatpak.enable = true;
    thermald.enable = true;
    power-profiles-daemon.enable = false;
    tlp.enable = true;
  };

  xdg.portal.enable = true;

  networking = {
    wireless = {
      enable = lib.mkForce false; # Overwrite iso base
      iwd.enable = true;
    };
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
      packages = with pkgs; [
        networkmanager-openvpn
        networkmanager-openconnect
      ];
    };
  };

  system.activationScripts.copy-dotfiles = {
    deps = [ "etc" ];
    text =
      let
        script = pkgs.writeScript "dotfiles.sh" ''
          echo "Setting up dotfiles for $(whoami)..."
          rsync -ar "${inputs.dotfiles}/." "$HOME/.dotfiles"
          mkdir -p $HOME/{.cache,.config,.local/{bin,share,lib}}
          touch $HOME/{.cache,.config,.local/{bin,share,lib}}/.stowkeep
          export DOT_NOINSTALL=1 && source $HOME/.dotfiles/control.sh && autolink_all
          rm -f $HOME/{.cache,.config,.local/{bin,share,lib}}/.stowkeep
          # sha256sum $HOME/.zsh_plugins.txt $HOME/.zshrc > $HOME/.zsh.sha
          mkdir -p "$HOME/.cache/antibody"
          ln -s "${pkgs.antibody}/bin/antibody" "$HOME/.cache/antibody/antibody"
        '';
      in
      ''
        # Add all installed packages to path
        for i in ${toString config.environment.systemPackages}; do
            PATH=$PATH:$i/bin:$i/sbin
        done
        sudo -u ${config.nzbr.user} bash "${script}"
        HOME=/root bash "${script}"
      '';
  };

  environment.etc."nixos/config".source = ./..;
}
