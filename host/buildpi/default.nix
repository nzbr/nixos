{ config, lib, pkgs, inputs, system, ... }:
with builtins; with lib; {

  nzbr = {
    system = "aarch64-linux";
    patterns = [ "common" ];

    agenix.enable = mkForce false;
    nopasswd.enable = true;

    # installer.sdcard.enable = true;
    # boot.raspberrypi = {
    #   enable = true;
    #   initrd = true;
    #   config = {
    #     pi4 = {
    #       # over_voltage = 8;
    #       # arm_freq_min = 100;
    #       # arm_freq = 2350;
    #       over_voltage = 6;
    #       arm_freq = 2000;
    #     };
    #     all = {
    #       dtoverlay = [
    #         "gpio-fan,gpiopin=14,temp=60000"
    #       ];
    #     };
    #   };
    # };

    service = {
      tailscale.enable = true;
      buildServer = {
        # enable = true;
        maxJobs = 4;
        systems = [ "aarch64-linux" ];
      };
    };
  };

  # Does not make a lot of sense without agenix
  systemd.services.tailscale-up.enable = false;
  systemd.services.tailscaled.after = [ "dhcpcd.service" ];

  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-uuid/2178-694E";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };
    "/" = {
      device = "/dev/disk/by-uuid/44444444-4444-4444-8888-888888888888";
      fsType = "ext4";
    };
  };

  boot.loader.systemd-boot.enable = true;

  swapDevices = [
    {
      device = "/swapfile";
      size = 32768;
    }
  ];

  # Try to gc 16GiB if there are less than 16GiB left on /nix/store
  nix.settings = {
    min-free = 17179869184;
    max-free = 34359738368;
    # cores = 3; # Use only 3 cores for building to not interfere with OctoPrint
    system-features = [ "nixos-test" "benchmark" "kvm" "gccarch-armv8-a" ]; # disable big-parallel
  };

  # services = {
  #   octoprint = {
  #     enable = true;
  #     plugins = super:
  #       with super;
  #       let
  #         psucontrol_homeassistant = buildPlugin rec {
  #           pname = "psucontrol_homeassistant";
  #           version = "1.0.5";

  #           src = pkgs.fetchFromGitHub {
  #             owner = "edekeijzer";
  #             repo = "OctoPrint-PSUControl-HomeAssistant";
  #             rev = version;
  #             sha256 = "sha256-gphn2PSBjNC2Cji7vbAT3Tx+HrXktFrD81iCqNMcPeE=";
  #           };

  #           propagatedBuildInputs = [
  #             python-periphery
  #           ];
  #         };
  #       in
  #       [
  #         psucontrol
  #         psucontrol_homeassistant
  #         themeify
  #       ];
  #   };
  # };
  # users.groups.video.members = [ "octoprint" ]; # RPis are cursed and OctoPrint needs to be in the video group to use vcgencmd TODO: The udev rules for this are missing

  boot.initrd.kernelModules = [
    "vc4"
    "bcm2835_dma"
    "i2c_bcm2835"
    "xhci_pci"
    "usbhid"
    "usb_storage"
  ];
  # boot = {
  #   # kernelPackages = pkgs.linuxKernel.rpiPackages.linux_rpi4; # Cross compile the kernel so it doesn't take forever
  #   kernelModules = [
  #     "hid_roccat"
  #     "hid_roccat_common"
  #     "hid_roccat_isku"
  #   ];
  #   # kernelPatches = [
  #   #   {
  #   #     name = "usb-storage";
  #   #     patch = null;
  #   #     extraConfig = ''
  #   #       USB_XHCI_PCI y
  #   #       USB_XHCI_PCI_RENESAS y
  #   #       UIO y
  #   #       UIO_PDRV_GENIRQ y
  #   #       EXT4_USE_FOR_EXT2 y
  #   #       FUSE_FS y
  #   #       PSTORE y
  #   #       NLS_CODEPAGE_437 y
  #   #     '';
  #   #   }
  #   #   {
  #   #     name = "fix";
  #   #     patch = null;
  #   #     extraConfig = ''
  #   #       # Needed to compile for some reason
  #   #       COMPILE_TEST n
  #   #       DEBUG_INFO_BTF n
  #   #       CRYPTO_AEGIS128 n
  #   #     '';
  #   #   }
  #   #   {
  #   #     name = "debloat";
  #   #     patch = null;
  #   #     extraConfig = ''
  #   #       IKHEADERS n
  #   #       BLK_DEV_INITRD n
  #   #       HOTPLUG_CPU n
  #   #       XEN n
  #   #       IP_DCCP n
  #   #       TIPC n
  #   #       ATM n
  #   #       L2TP n
  #   #       DECNET n
  #   #       LLC2 n
  #   #       ATALK n
  #   #       X25 n
  #   #       LAPB n
  #   #       PHONET n
  #   #       6LOWPAN n
  #   #       IEEE802154 n
  #   #       BATMAN_ADV n
  #   #       QRTR n
  #   #       HAMRADIO n
  #   #       CAN n
  #   #       BT n
  #   #       CFG80211 n
  #   #       WIMAX n
  #   #       NET_9P n
  #   #       CAIF n
  #   #       NFC n
  #   #       PCCARD n
  #   #       RAPIDIO n
  #   #       GNSS n
  #   #       BLK_DEV_NVME n
  #   #       NVME_FC n
  #   #       NVME_TCP n
  #   #       NVME_TARGET n
  #   #       AD525X_DPOT n
  #   #       ISL_29003 n
  #   #       ISL_29020 n
  #   #       SENSORS_TSL2550 n
  #   #       SENSORS_BH1770 n
  #   #       SENSORS_APDS990X n
  #   #       HMC6352 n
  #   #       DS1682 n
  #   #       LATTICE_ECP3_CONFIG n
  #   #       PCI_ENDPOINT_TEST n
  #   #       XILINX_SDFEC n
  #   #       HISI_HIKEY_USB n
  #   #       C2PORT n
  #   #       SENSORS_LIS3_SPI n
  #   #       SENSORS_LIS3_I2C n
  #   #       GENWQE n
  #   #       ECHO n
  #   #       MISC_ALCOR_PCI n
  #   #       HABANA_AI n
  #   #       MD n
  #   #       FUSION n
  #   #       WATCHDOG n
  #   #       BCMA n
  #   #       MEDIA_SUPPORT n
  #   #       DRM_RADEON n
  #   #       DRM_AMDGPU n
  #   #       DRM_NOUVEAU n
  #   #       DRM_VKMS n
  #   #       DRM_ARCGPU n
  #   #       DRM_HISI_HIBMC n
  #   #       DRM_HISI_KIRIN n
  #   #       DRM_MXSFB n
  #   #       DRM_GM12U320 n
  #   #       TINYDRM_HX8357D n
  #   #       TINYDRM_ILI9225 n
  #   #       TINYDRM_ILI9341 n
  #   #       TINYDRM_ILI9486 n
  #   #       TINYDRM_MI0283QT n
  #   #       TINYDRM_REPAPER n
  #   #       TINYDRM_ST7586 n
  #   #       TINYDRM_ST7735R n
  #   #       DRM_PL111 n
  #   #       DRM_LIMA n
  #   #       DRM_PANFROST n
  #   #       DRM_TIDSS n
  #   #       DRM_GUD n
  #   #       DRM_LEGACY n
  #   #       SOUND n
  #   #       MEMSTICK n
  #   #       ACCESSIBILITY n
  #   #       INFINIBAND n
  #   #       GREYBUS n
  #   #       COMEDI n
  #   #       FB_SM750 n
  #   #       FIREWIRE_SERIAL n
  #   #       GS_FPGABOOT n
  #   #       KS7010 n
  #   #       FIELDBUS_DEV n
  #   #       QLGE n
  #   #       SPMI_HISI3670 n
  #   #       MFD_HI6421_SPMI n
  #   #       CHROME_PLATFORMS n
  #   #       SOUNDWIRE n
  #   #       IIO n
  #   #       NTB n
  #   #       IPACK_BUS n
  #   #       MCB n
  #   #       USB4 n
  #   #       ANDROID n
  #   #       FPGA n
  #   #       FSI n
  #   #       SIOX n
  #   #       SLIMBUS n
  #   #       COUNTER n
  #   #       MOST n
  #   #     '';
  #   #   }
  #   # ];
  # };

  system.stateVersion = "23.05";
  nzbr.home.config.home.stateVersion = "23.05";

}
