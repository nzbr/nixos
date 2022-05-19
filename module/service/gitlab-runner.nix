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
    in
    mkIf cfg.enable {
      systemd.services.gitlab-runner.restartIfChanged = true;

      services.gitlab-runner = {
        enable = true;
        concurrent = 3;
        services =
          {
            nixos = {
              registrationConfigFile = config.nzbr.assets."git.nzbr.de-runner-registration.env";
              tagList = [ "nix" ];
              runUntagged = false;
              executor = "docker";
              dockerImage = "alpine";
              dockerVolumes = [
                "/nix/store:/nix/store:ro"
                "/nix/var/nix/db:/nix/var/nix/db:ro"
                "/nix/var/nix/daemon-socket:/nix/var/nix/daemon-socket:ro"
              ];
              preBuildScript = pkgs.writeScript "nix-setup" ''
                mkdir -p -m 0755 /nix/var/log/nix/drvs
                mkdir -p -m 0755 /nix/var/nix/gcroots
                mkdir -p -m 0755 /nix/var/nix/profiles
                mkdir -p -m 0755 /nix/var/nix/temproots
                mkdir -p -m 0755 /nix/var/nix/userpool
                mkdir -p -m 1777 /nix/var/nix/gcroots/per-user
                mkdir -p -m 1777 /nix/var/nix/profiles/per-user
                mkdir -p -m 0755 /nix/var/nix/profiles/per-user/root

                . ${pkgs.nix}/etc/profile.d/nix.sh

                ${pkgs.nix}/bin/nix-env -i ${concatStringsSep " " (with pkgs; [ nix cacert ])}

                ${pkgs.nix}/bin/nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs
                ${pkgs.nix}/bin/nix-channel --update nixpkgs

                ln -s $HOME/.nix-defexpr /.nix-defexpr
              '';
              environmentVariables = {
                ENV = "/etc/profile";
                USER = "root";
                NIX_REMOTE = "daemon";
                PATH = "/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:/bin:/sbin:/usr/bin:/usr/sbin";
                NIX_SSL_CERT_FILE = "/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt";
                NIX_PATH = "/.nix-defexpr/channels";
              };
            };
            docker = {
              registrationConfigFile = config.nzbr.assets."git.nzbr.de-runner-registration.env";
              tagList = [ "docker" "linux" ] ++ cfg.extraTags;
              runUntagged = true;
              executor = "docker";
              dockerImage = "archlinux";
            };

            gitlab-com = {
              registrationConfigFile = config.nzbr.assets."gitlab.com-runner-registration.env";
              tagList = [ "docker" "linux" "nzbr" ];
              runUntagged = true;
              executor = "docker";
              dockerImage = "archlinux";
            };
          };
      };
    };

}
