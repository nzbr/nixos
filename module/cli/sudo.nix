{ config, lib, pkgs, ... }:
with builtins; with lib; {
  options.nzbr.cli.sudo = with types; {
    enable = mkEnableOption "Enables a customized sudo prompt";
  };

  config = mkIf config.nzbr.cli.sudo.enable {
    nixpkgs.overlays = [
      (self: super: {
        sudo = (super.sudo.override { withInsults = true; });
      })
    ];

    security.sudo.extraConfig = ''
      Defaults pwfeedback
      Defaults insults
      Defaults passprompt="[48;5;9m[38;5;15m 🔒 [38;5;9m[48;5;208m [38;5;15m[1m %p [22m[049m[38;5;208m[039m  "
      Defaults env_keep+=SSH_CONNECTION
    '';
  };
}
