let
  branding = ./nixos-branding.png;
in
{ config, lib, pkgs, modulesPath, ... }:
{
  boot.plymouth = {
    enable = true;
    themePackages = [ ];
    theme = "spinner";
  };

  nixpkgs.overlays = [
    (self: super: {
      plymouth = super.unstable.plymouth.overrideAttrs (old: rec {
        preFixup = ''
                    cp ${branding} $out/share/plymouth/themes/spinner/watermark.png
                    # cat << EOF >> $out/share/plymouth/themes/spinner/spinner.plymouth
          # WatermarkHorizontalAlignment=.5
          # WatermarkVerticalAlignment=.5
          # EOF
        '';
      });
    })
  ];
}
