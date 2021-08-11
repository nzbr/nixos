{ sys }:
{ config, lib, pkgs, ... }:
{
  imports = [
    ./module/git.nix
    ./module/gnome.nix
    ./module/theme.nix
    ./module/zsh.nix
    ./module/ssh.nix
  ];

  config = {
    home.file.cache-marker = {
      target = ".cache/CACHEDIR.TAG";
      text = ''
        Signature: 8a477f597d28d172789f06886806bc55
      '';
    };
  };

  options = with lib; {
    networking.hostName = mkOption {
      default = sys.networking.hostName;
      type = types.str;
    };
  };
}
