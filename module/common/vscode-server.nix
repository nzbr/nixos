{ config, lib, inputs, pkgs, modulesPath, ... }:
(import "${inputs.vscode-server}/modules/vscode-server/module.nix"
  ({ name, description, serviceConfig }: {
    systemd.services."${name}-root" = {
      inherit description;
      wantedBy = [ "multi-user.target" ];
      serviceConfig = serviceConfig // {
        User = "root";
      };
    };
    systemd.services."${name}-${config.nzbr.user}" = {
      inherit description;
      wantedBy = [ "multi-user.target" ];
      serviceConfig = serviceConfig // {
        User = "${config.nzbr.user}";
      };
    };
  })
) { inherit lib pkgs; }
