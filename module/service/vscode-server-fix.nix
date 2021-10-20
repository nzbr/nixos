{ config, lib, inputs, pkgs, modulesPath, ... }:
with builtins; with lib; {
  options.nzbr.service.vscode-server-fix = {
    enable = mkEnableOption "automatically fix vscode remote server";
  };

  config = mkIf config.nzbr.service.vscode-server-fix.enable
    (
      (
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
      ).config
    );
}
