{ config, lib, pkgs, modulesPath, ... }:
with builtins; with lib; {
  options.nzbr.service.gitlab-runner = with types; {
    enable = mkEnableOption "GitLab Runner";
    extraTags = mkOption {
      type = listOf str;
      default = [ ];
    };
  };

  config =
    let
      cfg = config.nzbr.service.gitlab-runner;
      nix-setup = pkgs.writeScript "nix-setup" ''
        mkdir -p -m 0755 /nix/var/log/nix/drvs
        mkdir -p -m 0755 /nix/var/nix/gcroots
        mkdir -p -m 0755 /nix/var/nix/profiles
        mkdir -p -m 0755 /nix/var/nix/temproots
        mkdir -p -m 0755 /nix/var/nix/userpool
        mkdir -p -m 1777 /nix/var/nix/gcroots/per-user
        mkdir -p -m 1777 /nix/var/nix/profiles/per-user
        mkdir -p -m 0755 /nix/var/nix/profiles/per-user/root
        mkdir -p -m 0700 "$HOME/.nix-defexpr"
        . ${pkgs.nix}/etc/profile.d/nix.sh
        ${pkgs.nix}/bin/nix-channel --add https://nixos.org/channels/nixos-unstable nixpkgs
        ${pkgs.nix}/bin/nix-channel --update nixpkgs
        ${pkgs.nix}/bin/nix-env -i ${concatStringsSep " " (with pkgs; [ nix cacert git openssh ])}
      '';
      nix-env = {
        ENV = "/etc/profile";
        USER = "root";
        NIX_REMOTE = "daemon";
        NIX_SSL_CERT_FILE = "/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt";
        NIX_PATH = "/root/.nix-defexpr/channels";
        PATH = "/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:/bin:/sbin:/usr/bin:/usr/sbin";
      };
      nix-volumes = [
        "/nix/store:/nix/store:ro"
        "/nix/var/nix/db:/nix/var/nix/db:ro"
        "/nix/var/nix/daemon-socket:/nix/var/nix/daemon-socket:ro"
      ];
    in
    mkIf cfg.enable {
      systemd.services.gitlab-runner.restartIfChanged = true;

      virtualisation.docker.enable = true;

      services.gitlab-runner = {
        enable = true;
        settings.concurrent = 3;
        services =
          {
            nix = {
              registrationConfigFile = config.nzbr.assets."git.nzbr.de-runner-registration-docker.env";
              registrationFlags = [
                "--name ${config.networking.hostName}-nix"
              ];
              tagList = [ "nix" ];
              runUntagged = false;
              executor = "docker";
              dockerImage = "archlinux";
              dockerPrivileged = true;
              dockerVolumes = nix-volumes;
              preBuildScript = nix-setup;
              environmentVariables = nix-env;
            };

            docker = {
              registrationConfigFile = config.nzbr.assets."git.nzbr.de-runner-registration-nix.env";
              registrationFlags = [
                "--name ${config.networking.hostName}"
              ];
              tagList = [ "docker" "linux" ] ++ cfg.extraTags;
              runUntagged = true;
              executor = "docker";
              dockerImage = "archlinux";
              dockerPrivileged = true;
            };

            # gitlab-com = {
            #   registrationConfigFile = config.nzbr.assets."gitlab.com-runner-registration.env";
            #   registrationFlags = [
            #     "--name ${config.networking.hostName}"
            #   ];
            #   tagList = [ "docker" "linux" ];
            #   runUntagged = true;
            #   executor = "docker";
            #   dockerImage = "archlinux";
            #   dockerPrivileged = true;
            # };

            # devsaur = {
            #   registrationConfigFile = config.nzbr.assets."devsaur-runner-registration.env";
            #   registrationFlags = [
            #     "--name nzbr-${config.networking.hostName}"
            #   ];
            #   tagList = [ "docker" "linux" "nzbr" ];
            #   runUntagged = true;
            #   executor = "docker";
            #   dockerImage = "archlinux";
            #   dockerDisableCache = true;
            # };
          };
      };
    };

}
