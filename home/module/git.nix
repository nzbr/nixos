{ config, lib, pkgs, ... }:
{
  programs.git.extraConfig = {
    init.defaultBranch = "main";
    user.name = "nzbr";
    user.email = "mail" + "@" + "nzbr.de";
  };
}
