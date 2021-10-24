{ config, lib, inputs, pkgs, modulesPath, ... }:
let
  root = config.nzbr.flake.root;
in
with builtins; with lib; {
  networking.hostName = "live";

  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-base.nix"
    "${modulesPath}/installer/cd-dvd/channel.nix"
  ];

  nzbr = {
    patterns = [ "common" ]; # desktop contents are provided within this file

    user = "nixos";
    agenix.enable = false;

    desktop = {
      gnome.enable = true;
      pulseaudio.enable = true;
    };

    home.config = {
      dconf.settings = {
        "org/gnome/desktop/background" = {
          picture-uri = mkForce (builtins.fetchurl {
            # Use a free image from unsplash
            # 482eb40256a904860fbad4c983f65f37ad7439b4d41202eead244e62e271c2a7 https://unsplash.com/photos/IWenq-4JHqo/download\?force\=true
            url = "https://unsplash.com/photos/2HqpqSqy0zg/download\?force\=true";
            sha256 = "29e19663b210b1e952a2dd8bef3c1226edcc10ec3b635b1e3f1751ba96349b81";
          });
        };

        "org/gnome/shell" = {
          favorite-apps = mkForce [
            "vivaldi-stable.desktop"
            "org.gnome.Nautilus.desktop"
            "org.gnome.Terminal.desktop"
            "org.gnome.DiskUtility.desktop"
            "gparted.desktop"
          ];
        };
      };
    };

    # desktop.nix entries
    device.razerNari.enable = true;
  };

  environment.systemPackages = with pkgs; [

    # partitioning and recovery tools
    ddrescue
    fsarchiver
    gparted
    partimage
    squashfsTools
    testdisk
    testdisk-qt

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
    squashfsCompression = "zstd";
  };

  users.users.${config.nzbr.user} = {
    uid = 1000;
    extraGroups = [ "networkmanager" ];
    passwordFile = mkForce null;
  };
  users.users.root.passwordFile = mkForce null;
  services.getty.autologinUser = lib.mkForce config.nzbr.user;

  services = {
    xserver = {
      enable = true;
      libinput.enable = true;

      ### GNOME ###

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
}
