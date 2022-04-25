{ config, lib, inputs, pkgs, modulesPath, ... }:
let
  root = config.nzbr.flake.root;
in
with builtins; with lib; {
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-base.nix"
    "${modulesPath}/installer/cd-dvd/channel.nix"
  ];

  nzbr = {
    system = "x86_64-linux";
    patterns = [ "common" ]; # desktop contents are provided within this file

    user = "nixos";
    agenix.enable = false;
    nopasswd.enable = true;

    desktop = {
      gnome.enable = true;
      pulseaudio.enable = true;
    };

    home.config = {
      dconf.settings = {
        "org/gnome/desktop/background" = {
          picture-uri = mkForce (builtins.fetchurl {
            name = "background";

            # Use a free image from unsplash

            # url = "https://unsplash.com/photos/2HqpqSqy0zg/download\?force\=true";
            url = "https://images.unsplash.com/photo-1516715094483-75da7dee9758?ixlib=rb-1.2.1&q=80&fm=png&cs=tinysrgb";
            sha256 = "1w8b7gjhl20icpw4q6i31c54g3wicy0gxgpbjyz5aqph1qvzhwax";

            # Alternative: 482eb40256a904860fbad4c983f65f37ad7439b4d41202eead244e62e271c2a7 https://unsplash.com/photos/IWenq-4JHqo/download\?force\=true
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

  # KDE complains if power management is disabled (to be precise, if
  # there is no power management backend such as upower).
  powerManagement.enable = true;

  fonts.fonts = with pkgs; [
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    roboto
    roboto-slab
    roboto-mono
  ];

  isoImage = {
    edition = "nzbr";
    isoName = with config.system.nixos; with config.isoImage; lib.mkForce "${isoBaseName}-${edition}-${release}-${codeName}-${pkgs.stdenv.hostPlatform.system}-${config.boot.kernelPackages.kernel.version}.iso";
    squashfsCompression = "zstd";
  };

  users.users.${config.nzbr.user} = {
    uid = 1000;
    extraGroups = [ "networkmanager" ];
  };

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
