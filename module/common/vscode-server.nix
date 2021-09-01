{ config, lib, inputs, pkgs, modulesPath, ... }:
(import "${inputs.vscode-server}/modules/vscode-server/module.nix"
  ({name, description, serviceConfig}: {
    systemd.services."${name}-root" = {
      inherit description;
      wantedBy = [ "multi-user.target" ];
      serviceConfig = serviceConfig // {
        User = "root";
      };
    };
    systemd.services."${name}-nzbr" = {
      inherit description;
      wantedBy = [ "multi-user.target" ];
      serviceConfig = serviceConfig // {
        User = "nzbr";
      };
    };
  })
){ inherit lib pkgs; }
