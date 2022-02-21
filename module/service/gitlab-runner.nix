{ config, lib, pkgs, modulesPath, ... }:
with builtins; with lib; {
  options.nzbr.service.gitlab-runner = with types; {
    enable = mkEnableOption "GitLab Runner";
  };

  config =
    let
      cfg = config.nzbr.service.gitlab-runner;
    in
    mkIf cfg.enable {
      services.gitlab-runner = {
        enable = true;
        concurrent = 3;
        services =
          let
            registrationConfigFile = config.nzbr.assets."gitlab-runner-registration.env";
          in
          {
            nixos = {
              inherit registrationConfigFile;
              tagList = [ "nix" ];
              runUntagged = false;
              executor = "docker";
              dockerImage = "nixos/nix";
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
                mkdir -p -m 0700 "$HOME/.nix-defexpr"

                . ${pkgs.nix}/etc/profile.d/nix.sh

                ${pkgs.nix}/bin/nix-env -i ${concatStringsSep " " (with pkgs; [ nix cacert ])}

                ${pkgs.nix}/bin/nix-channel --add https://nixos.org/channels/nixpkgs-unstable
                ${pkgs.nix}/bin/nix-channel --update nixpkgs
              '';
              environmentVariables = {
                ENV = "/etc/profile";
                USER = "root";
                NIX_REMOTE = "daemon";
                PATH = "/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:/bin:/sbin:/usr/bin:/usr/sbin";
                NIX_SSL_CERT_FILE = "/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt";
              };
            };
            docker = {
              inherit registrationConfigFile;
              tagList = [ "docker" "linux" ];
              runUntagged = true;
              executor = "docker";
              dockerImage = "archlinux";
            };
          };
      };
    };

}
