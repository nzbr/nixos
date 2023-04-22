{ lib, ... }:
with builtins; with lib; {
  parseKernelConfig = config:
    let
      blocklist = [
        # Host-Dependent options
        "CONFIG_CC_VERSION_TEXT"
        "CONFIG_CC_IS_GCC"
        "CONFIG_GCC_VERSION"
        "CONFIG_LD_VERSION"
        "CONFIG_CLANG_VERSION"
        "CONFIG_LLD_VERSION"
        "CONFIG_CC_CAN_LINK"
        "CONFIG_CC_CAN_LINK_STATIC"
        "CONFIG_CC_HAS_ASM_GOTO"
        "CONFIG_CC_HAS_ASM_INLINE"
        "CONFIG_BUILDTIME_TABLE_SORT"

        # String options
        "CONFIG_LOCALVERSION"
        "CONFIG_LOCALVERSION_AUTO"
        "CONFIG_BUILD_SALT"
        "CONFIG_DEFAULT_INIT"
        "CONFIG_INITRAMFS_SOURCE"
        "CONFIG_CMDLINE"
        "CONFIG_EXTRA_FIRMWARE"
        "CONFIG_SYSTEM_TRUSTED_KEYS"
        "CONFIG_MAGIC_SYSRQ_SERIAL_SEQUENCE"

        # Broken options
        "CONFIG_B53_SRAB_DRIVER"
        "CONFIG_VITESSE_PHY"
        "CONFIG_USB_EHCI_HCD_OMAP"
        "CONFIG_CRYPTO_MICHAEL_MIC"
      ];

      configLines = splitString "\n" config;
    in
    mapAttrs'
      (n: v: nameValuePair (removePrefix "CONFIG_" n) (if v == "\"\"" then "" else v))
      (
        listToAttrs
          (
            filter
              (x: x != null && (hasPrefix "CONFIG_" x.name) && !(elem x.name blocklist))
              (
                map
                  (line:
                    if (hasSuffix " is not set" line)
                    then nameValuePair (removePrefix "# " (removeSuffix " is not set" line)) "n"
                    else
                      let
                        rx = match "(.*)=(.*)" line;
                      in
                      if rx != null
                      then
                        nameValuePair (elemAt rx 0) (elemAt rx 1)
                      else
                        null
                  )
                  configLines
              )
          )
      );

  mkKernelPatch = name: config:
    let
      extraConfig =
        concatStringsSep "\n" (
          mapAttrsToList
            (n: v: "${n} ${v}")
            config
        );
    in
    {
      inherit name extraConfig;
      patch = null;
    };

  kernelPatches = {
    logo = mkKernelPatch "logo" {
      LOGO = "y";
      LOGO_LINUX_MONO = "y";
      LOGO_LINUX_VGA16 = "y";
      LOGO_LINUX_CLUT224 = "y";
    };
    tuntap = mkKernelPatch "tun/tap" {
      TUN = "y";
      TAP = "y";
    };
  };

}
