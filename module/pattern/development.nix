{ options, config, lib, pkgs, modulesPath, ... }:
with builtins; with lib;
{
  options.nzbr.pattern.development = {
    enable = mkEnableOption "Development Tools";
    guiTools = mkEnableOption "GUI Tools";
  };

  config = mkIf config.nzbr.pattern.development.enable (
    {
      environment.systemPackages = with pkgs; [
        # androidComposition.androidsdk
        android-tools

        gh
        gnumake
        nix-output-monitor
        nh
        powershell
        # (python3.withPackages (pypi: with pypi; [
        #   autopep8
        #   black
        #   ipykernel
        # ]))
        conda
        mamba
        jq

        # Language servers
        unstable.nil
        nixd

        master.claude-code
        master.codex
        local.code-on-incus
      ] ++ (
        if config.nzbr.pattern.development.guiTools then
          [
            unstable.gitbutler
          ] ++ (if config.nzbr.pattern.wsl.enable then [ ] else [
            vscode
            scrcpy
            lens
            insomnia
          ])
        else [ ]
      );

      environment.variables =
        let
          devPkgs = with pkgs; [
            glib
            gtk3
          ];
        in
        {
          PKG_CONFIG_PATH = concatStringsSep ":" (
            map
              (pkg: "${pkg.dev}/lib/pkgconfig")
              devPkgs
          );
          CMAKE_PREFIX_PATH = "${pkgs.cmake}:${pkgs.pkg-config}:" + concatStringsSep ":" (
            map
              (pkg: "${pkg.dev}")
              devPkgs
          );
          CHROME_EXECUTABLE = "${pkgs.chromium}/bin/chromium";
        };

      programs.nix-ld.enable = true;

      nzbr.cli.git = {
        enable = true;
        userInfo = true;
      };

      nzbr.cli.agent-login-bridge.enable = true;

      virtualisation.docker.enable = mkDefault true;

      virtualisation.incus.enable = mkDefault true;
      boot.supportedFilesystems.btrfs = mkDefault true;
      networking.nftables = {
        enable = true;
        flushRuleset = false;
      };
      networking.firewall.interfaces.incusbr0 = {
        allowedTCPPorts = [ 53 67 ];
        allowedUDPPorts = [ 53 67 ];
      };
      networking.firewall.trustedInterfaces = [ "incusbr0" ];

      users.groups = {
        adbusers.members = [ config.nzbr.user ];
        incus-admin.members = [ config.nzbr.user ];
      };
    }
  );
}
