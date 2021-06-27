{ sys }:
{ config, lib, pkgs, ... }:
{
  imports = [
    ./module/git.nix
    ./module/theme.nix
    ./module/zsh.nix
    ./module/ssh.nix
  ];

  options = with lib; {
    networking.hostName = mkOption {
      default = sys.networking.hostName;
      type = types.str;
    };
  };
}
