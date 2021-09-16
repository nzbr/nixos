{ config, lib, pkgs, ... }:
{
  programs.git = {
    enable = true;
    userName = "nzbr";
    userEmail = "mail" + "@" + "nzbr.de";
    signing = {
      key = "BF3A3EE631442C5FC9FB39A76C78B50B97A42F8A";
      signByDefault = true;
    };
    lfs.enable = true;
    delta.enable = true;
    extraConfig = {
      core.autocrlf = "input";
      init.defaultBranch = "main";
      pull.rebase = false;
    };
  };
}
