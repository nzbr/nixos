{ config, lib, pkgs, ... }:
{
  programs.git.extraConfig = {
    init.defaultBranch = "main";
    pull.rebase = false;

    user.name = "nzbr";
    user.email = "mail" + "@" + "nzbr.de";
  };
}
