# Most of this code is from the files at https://github.com/NixOS/nixpkgs/tree/master/nixos/modules/installer/sd-card

{ config, options, lib, pkgs, inputs, system, ... }:
with builtins; with lib; {
  options.nzbr.installer.sdcard = with types; {
    enable = mkEnableOption "SD Card Image";

    firmwarePartitionOffset = mkOption {
      type = int;
      default = 8;
      description = ''
        Gap in front of the /boot/firmware partition, in mebibytes (1024×1024
        bytes).
        Can be increased to make more space for boards requiring to dd u-boot
        SPL before actual partitions.

        Unless you are building your own images pre-configured with an
        installed U-Boot, you can instead opt to delete the existing `FIRMWARE`
        partition, which is used **only** for the Raspberry Pi family of
        hardware.
      '';
    };

    firmwarePartitionID = mkOption {
      type = str;
      default = "0x2178694e";
      description = ''
        Volume ID for the /boot/firmware partition on the SD card. This value
        must be a 32-bit hexadecimal number.
      '';
    };

    firmwarePartitionName = mkOption {
      type = str;
      default = "BOOT";
      description = ''
        Name of the filesystem which holds the boot firmware.
      '';
    };

    rootPartitionLabel = mkOption {
      type = str;
      default = "NIXOS";
      description = "Label of the root partition";
    };

    rootPartitionUUID = mkOption {
      type = str;
      default = "44444444-4444-4444-8888-888888888888";
      example = "14e19a7b-0ae0-484d-9d54-43bd6fdc20c7";
      description = ''
        UUID for the filesystem on the main NixOS partition on the SD card.
      '';
    };

    firmwareSize = mkOption {
      type = int;
      # As of 2019-08-18 the Raspberry pi firmware + u-boot takes ~18MiB
      default = 30;
      description = ''
        Size of the /boot/firmware partition, in megabytes.
      '';
    };

    populateFirmwareCommands = mkOption {
      example = literalExpression "'' cp \${pkgs.myBootLoader}/u-boot.bin firmware/ ''";
      description = ''
        Shell commands to populate the ./firmware directory.
        All files in that directory are copied to the
        /boot/firmware partition on the SD image.
      '';
    };

    populateRootCommands = mkOption {
      example = literalExpression "''\${config.boot.loader.generic-extlinux-compatible.populateCmd} -c \${config.system.build.toplevel} -d ./files/boot''";
      description = ''
        Shell commands to populate the ./files directory.
        All files in that directory are copied to the
        root (/) partition on the SD image. Use this to
        populate the ./files/boot (/boot) directory.
      '';
      default = "";
    };

    postBuildCommands = mkOption {
      example = literalExpression "'' dd if=\${pkgs.myBootLoader}/SPL of=$img bs=1024 seek=1 conv=notrunc ''";
      default = "";
      description = ''
        Shell commands to run after the image is built.
        Can be used for boards requiring to dd u-boot SPL before actual partitions.
      '';
    };

    compressImage = mkOption {
      type = bool;
      default = true;
      description = ''
        Whether the SD image should be compressed using
        <command>zstd</command>.
      '';
    };

    expandOnBoot = mkOption {
      type = bool;
      default = true;
      description = ''
        Whether to configure the sd image to expand it's partition on boot.
      '';
    };

    extraStorePaths = mkOption {
      type = listOf package;
      example = literalExpression "[ pkgs.stdenv ]";
      default = [ ];
      description = ''
        Derivations to be included in the Nix store in the generated SD image.
      '';
    };

  };

  config =
    let
      cfg = config.nzbr.installer.sdcard;
      imgName = with config.system.nixos; "nixos-${config.networking.hostName}-${release}-${codeName}-${pkgs.stdenv.hostPlatform.system}-${config.boot.kernelPackages.kernel.version}.img";
    in
    mkIf cfg.enable {
      # TODO: Optimize store?

      fileSystems = {
        "/boot/firmware" = {
          device = "/dev/disk/by-label/${cfg.firmwarePartitionName}";
          fsType = "vfat";
          options = [ "ro" ];
        };
        "/" = {
          device = "/dev/disk/by-label/${cfg.rootPartitionLabel}";
          fsType = "ext4";
        };
      };

      system.build.firmware =
        pkgs.callPackage
          (
            { stdenv }: stdenv.mkDerivation {
              name = "${config.networking.hostName}-firmware";

              buildCommand = ''
                set -eux
                mkdir -p $out
                cd $out
                ${cfg.populateFirmwareCommands}
              '';
            }
          )
          { };

      system.build.sdImage =
        let
          rootfsImage = pkgs.callPackage "${inputs.nixpkgs}/nixos/lib/make-ext4-fs.nix" ({
            storePaths = [ config.system.build.toplevel ] ++ cfg.extraStorePaths;
            compressImage = false;
            populateImageCommands = cfg.populateRootCommands;
            volumeLabel = cfg.rootPartitionLabel;
            uuid = cfg.rootPartitionUUID;
          });
        in
        pkgs.callPackage
          ({ stdenv
           , dosfstools
           , e2fsprogs
           , mtools
           , libfaketime
           , util-linux
           , zstd
           }: stdenv.mkDerivation {
            name = imgName;

            nativeBuildInputs = [ dosfstools e2fsprogs mtools libfaketime util-linux zstd ];

            inherit (cfg) compressImage;

            buildCommand = ''
              mkdir -p $out/nix-support $out/sd-image
              export img=$out/sd-image/${imgName}

              echo "${pkgs.stdenv.buildPlatform.system}" > $out/nix-support/system
              if test -n "$compressImage"; then
                echo "file sd-image $img.zst" >> $out/nix-support/hydra-build-products
              else
                echo "file sd-image $img" >> $out/nix-support/hydra-build-products
              fi

              # Gap in front of the first partition, in MiB
              gap=${toString cfg.firmwarePartitionOffset}

              # Create the image file sized to fit /boot/firmware and /, plus slack for the gap.
              rootSizeBlocks=$(du -B 512 --apparent-size ${rootfsImage} | awk '{ print $1 }')
              firmwareSizeBlocks=$((${toString cfg.firmwareSize} * 1024 * 1024 / 512))
              imageSize=$((rootSizeBlocks * 512 + firmwareSizeBlocks * 512 + gap * 1024 * 1024))
              truncate -s $imageSize $img

              # type=b is 'W95 FAT32', type=83 is 'Linux'.
              # The "bootable" partition is where u-boot will look file for the bootloader
              # information (dtbs, extlinux.conf file).
              sfdisk $img <<EOF
                  label: dos
                  label-id: ${cfg.firmwarePartitionID}

                  start=''${gap}M, size=$firmwareSizeBlocks, type=b
                  start=$((gap + ${toString cfg.firmwareSize}))M, type=83, bootable
              EOF

              # Copy the rootfs into the SD image
              eval $(partx $img -o START,SECTORS --nr 2 --pairs)
              dd conv=notrunc if=${rootfsImage} of=$img seek=$START count=$SECTORS

              # Create a FAT32 /boot/firmware partition of suitable size into firmware_part.img
              eval $(partx $img -o START,SECTORS --nr 1 --pairs)
              truncate -s $((SECTORS * 512)) firmware_part.img
              faketime "1970-01-01 00:00:00" mkfs.vfat -i ${cfg.firmwarePartitionID} -n ${cfg.firmwarePartitionName} firmware_part.img

              # Copy the populated /boot/firmware into the SD image
              (cd ${config.system.build.firmware}; mcopy -psvm -i $NIX_BUILD_TOP/firmware_part.img ./* ::)
              # Verify the FAT partition before copying it.
              fsck.vfat -vn firmware_part.img
              dd conv=notrunc if=firmware_part.img of=$img seek=$START count=$SECTORS

              ${cfg.postBuildCommands}

              if test -n "$compressImage"; then
                  zstd -T$NIX_BUILD_CORES --rm $img
              fi
            '';
          })
          { };

      boot.postBootCommands = lib.mkIf cfg.expandOnBoot ''
        # On the first boot do some maintenance tasks
        if [ -f /nix-path-registration ]; then
          set -euo pipefail
          set -x
          # Figure out device names for the boot device and root filesystem.
          rootPart=$(${pkgs.util-linux}/bin/findmnt -n -o SOURCE /)
          bootDevice=$(lsblk -npo PKNAME $rootPart)
          partNum=$(lsblk -npo MAJ:MIN $rootPart | ${pkgs.gawk}/bin/awk -F: '{print $2}')

          # Resize the root partition and the filesystem to fit the disk
          echo ",+," | sfdisk -N$partNum --no-reread $bootDevice
          ${pkgs.parted}/bin/partprobe
          ${pkgs.e2fsprogs}/bin/resize2fs $rootPart

          # Register the contents of the initial Nix store
          ${config.nix.package.out}/bin/nix-store --load-db < /nix-path-registration

          # nixos-rebuild also requires a "system" profile and an /etc/NIXOS tag.
          touch /etc/NIXOS
          ${config.nix.package.out}/bin/nix-env -p /nix/var/nix/profiles/system --set /run/current-system

          # Prevents this from running on later boots.
          rm -f /nix-path-registration
        fi
      '';
    };
}
