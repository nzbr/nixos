{ config, lib, pkgs, ... }:
let
  inherit (lib)
    mkForce
    ;
in
{
  nzbr.boot.raspberrypi.initrd = true;

  boot = {

    plymouth = {
      enable = true;
      theme = "dragon";
      themePackages = [
        # By default we would install all themes
        (pkgs.adi1090x-plymouth-themes.override {
          selected_themes = [ config.boot.plymouth.theme ];
        })
      ];
    };

    consoleLogLevel = 3;
    initrd = {
      verbose = false;
      systemd = {
        enable = true; # Should alleviate some of the delay using an initrd introduces
        tpm2.enable = false;
      };
    };
    kernelParams = [
      "quiet"
      "boot.shell_on_fail"
      "udev.log_priority=3"
      "rd.systemd.show_status=auto"
    ];
  };

  # Do not delay boot until plymouth has quit
  systemd.services.plymouth-quit-wait.wantedBy = mkForce [ ];

  # Only kill plymouth after the graphical session has started
  # systemd.services.plymouth-quit.after = [ "display-manager.service" ];
  # systemd.services.plymouth-quit.enable = false;

  # Prevent getty prompt from flashing before display-manager launches
  systemd.services."autovt@tty1".enable = false;

  systemd.user.services.plymouth-quit = {
    description = "Quit Plymouth";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${config.security.sudo.package} ${pkgs.plymouth}/bin/plymouth quit";
    };
    after = [ "plasma-workspace.target" ];
    wantedBy = [ "default.target" ];
  };

  security.sudo.extraRules = [
    {
      users = [ config.nzbr.user ];
      commands = [
        { command = "${pkgs.plymouth}/bin/plymouth"; options = [ "NOPASSWD" ]; }
      ];
    }
  ];
}
