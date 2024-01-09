{ config, lib, pkgs, ... }:
with builtins; with lib;
let
  root = config.nzbr.flake.root;
in
{

  options.nzbr.cli.git = with types; {
    enable = mkEnableOption "Enables customized git settings";
    userInfo = mkEnableOption "Set more specific values like name and email";
  };

  config = mkIf config.nzbr.cli.git.enable (
    {
      nzbr.home.config = {
        programs.git = recursiveUpdate
          {
            enable = true;
            lfs.enable = true;
            delta.enable = true;
            extraConfig = {
              core.autocrlf = "input";
              init.defaultBranch = "main";
              pull.rebase = false;
            };
          }
          (
            if config.nzbr.cli.git.userInfo
            then {
              userName = "nzbr";
              userEmail = "mail" + "@" + "nzbr.de";
              extraConfig =
                let
                  hasSSH = root != null
                    && (hasAttr "ssh" (readDir "${root}/host/${config.networking.hostName}"))
                    && (hasAttr "id_ed25519.age" (readDir "${root}/host/${config.networking.hostName}/ssh"))
                    && (hasAttr "id_ed25519.pub" (readDir "${root}/host/${config.networking.hostName}/ssh"));
                in
                {
                  gpg.format = mkIf hasSSH "ssh";
                  gpg.ssh.allowedSignersFile = mkIf hasSSH (toString (pkgs.writeText "allowed_signers" ''
                    ${config.nzbr.home.config.programs.git.userEmail} ${readFile "${root}/host/${config.networking.hostName}/ssh/id_ed25519.pub"}"
                  ''));
                  user.signingKey = "~/.ssh/id_ed25519.pub";
                  commit.gpgSign = hasSSH;
                };
            }
            else { }
          );
      };
    }
  );

}
