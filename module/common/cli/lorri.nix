{ config, lib, pkgs, modulesPath, ... }:
{
  services.lorri.enable = true;

  environment = {
    systemPackages = with pkgs; [
      direnv
    ];

    etc."shell-hooks/99-direnv.sh" = {
      mode = "0755";
      text = ''
        eval "$(direnv hook $(ps -p $$ -ocmd=))"
      '';
    };
  };
}
