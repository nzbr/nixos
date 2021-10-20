{ config, lib, pkgs, ... }:
with builtins; with lib; {

  options.nzbr.cli.git = with types; {
    enable = mkEnableOption "Enables customized git settings";
    userInfo = mkEnableOption "Set more specific values like name and email";
  };

  config = mkIf config.nzbr.cli.git.enable (
    {
      nzbr.home.config = {
        programs.git = {
          enable = true;
          lfs.enable = true;
          delta.enable = true;
          extraConfig = {
            core.autocrlf = "input";
            init.defaultBranch = "main";
            pull.rebase = false;
          };
        } // (
          if config.nzbr.cli.git.userInfo
          then {
            userName = "nzbr";
            userEmail = "mail" + "@" + "nzbr.de";
            signing = {
              key = "BF3A3EE631442C5FC9FB39A76C78B50B97A42F8A";
              signByDefault = true;
            };
          }
          else { }
        );
      };
    }
  );

}
