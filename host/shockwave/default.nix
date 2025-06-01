{ config, lib, pkgs, inputs, system, ... }:

let
  winsounds = pkgs.stdenv.mkDerivation {
    name = "windows-sounds";

    src = builtins.fetchurl {
      url = "https://winsounds.com/downloads/WindowsMe.zip";
      sha256 = "1rny6nwjprd36r5hhdi0i2bwlafmjdlyx62n4l5fm4mlqy0vc7rn";
    };

    buildCommand = ''
      mkdir -p $out
      ${pkgs.unzip}/bin/unzip -d $out $src
    '';
  };

  playSound = name: pkgs.writeShellScript "play-${name}.sh" ''
    ${config.services.pulseaudio.package}/bin/paplay --volume 32768 "${winsounds}/${if lib.hasInfix "." name then name else "${name}.WAV"}"
  '';
in

with builtins; with lib; {

  nzbr = {
    system = "aarch64-linux";
    patterns = [ "common" ];

    deployment.targetHost = "shockwave.dragon-augmented.ts.net";

    agenix.enable = mkForce false;
    nopasswd.enable = true;

    service = {
      tailscale.enable = true;
    };
  };

  # Try to gc 16GiB if there are less than 16GiB left on /nix/store
  nix.settings = {
    min-free = 17179869184;
    max-free = 34359738368;
  };

  nixpkgs.config.platform = lib.systems.platforms.raspberrypi3;

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;

    kernelPackages = pkgs.linuxKernel.rpiPackages.linux_rpi3; # RPi Kernel is needed for the hifiberry module
    kernelParams = [ "console=tty1" ];

    initrd.includeDefaultModules = false; # NixOS tries to load ahci per default, which the RPi kernel does not have
    initrd.availableKernelModules = [
      "usb_storage"
      "usbhid"
      "hid_roccat"
      "hid_roccat_common"
      "hid_roccat_isku"
    ];

    kernelModules = [
      "snd_soc_bmc2708"
      "snd_soc_bcm2708_i2s"
      "bcm2708_dmaengine"
      "snd_soc_pcm512x"
      "snd_soc_hifiberry_dacplus"
    ];

    blacklistedKernelModules = [
      "snd_bcm2835"
    ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/33f37880-1fc2-403b-b9af-5945e1113f13";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/5053-F3DD";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };
  };

  swapDevices = [{
    device = "/swapfile";
  }];

  # sound.enable = true;

  hardware = {
    # deviceTree = {
    #   enable = true;
    #   overlays = [
    #     "${pkgs.linuxKernel.rpiPackages.linux_rpi3.kernel}/dtbs/overlays/hifiberry-dacplus.dtbo"
    #   ];
    # };
    bluetooth = {
      enable = true;
      settings = {
        General = {
          DiscoverableTimeout = 0;
        };
        Policy = {
          AutoEnable = true;
        };
      };
    };
  };

  services.pulseaudio = {
    enable = true;
    systemWide = true;
    package = pkgs.pulseaudio.override {
      x11Support = false;
      jackaudioSupport = false;
      bluetoothSupport = true;
      advancedBluetoothCodecs = true;
    };
    zeroconf.publish.enable = true;
    tcp = {
      enable = true;
      anonymousClients.allowAll = true;
    };
  };

  networking.firewall.allowedTCPPorts = [
    4713 # PulseAudio
  ];

  environment.systemPackages = with pkgs; [
    pavucontrol
  ];

  users.groups.pulse-access.members = [ "root" config.nzbr.user ];

  # services.xserver = {
  #   enable = true;
  #   displayManager.lightdm.enable = true;
  #   displayManager.lightdm.greeters.slick.enable = true;
  #   desktopManager.lxqt.enable = true;
  # };

  # TODO: Generate a PIN and display it in Home Assistant or something like that
  systemd.services.bluetooth-agent =
    let
      pinFile = pkgs.writeText "pins.txt" ''
        00:00:00:00:00:00 *
        *                 *
      '';
    in
    {
      after = [ "bluetooth.service" ];
      wantedBy = [ "multi-user.target" ];
      preStart = ''
        ${pkgs.bluez}/bin/hciconfig hci0 up
        ${pkgs.bluez}/bin/hciconfig hci0 piscan
        ${pkgs.bluez}/bin/hciconfig hci0 sspmode 1
        ${pkgs.bluez}/bin/bluetoothctl discoverable on
      '';
      serviceConfig = {
        ExecStart = "${pkgs.bluez-tools}/bin/bt-agent --capability=DisplayOnly --pin ${pinFile}";
        Restart = "always";
        RestartSec = 5;
      };
    };

  systemd.services.bootsound = {
    after = [ "pulseaudio.service" ];
    requires = [ "pulseaudio.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = playSound "The Microsoft Sound.wav";
      ExecStop = playSound "LOGOFF";
    };
  };

  services.udev.extraRules =
    let
      attach = playSound "TADA";
      detach = playSound "CHORD";
    in
    ''
      SUBSYSTEM=="bluetooth", ACTION=="add", RUN+="${attach}"
      SUBSYSTEM=="bluetooth", ACTION=="remove", RUN+="${detach}"
    '';

  system.stateVersion = "23.11";
  nzbr.home.config.home.stateVersion = "23.11";
}
