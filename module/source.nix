{ config, lib, inputs, ... }:
with builtins; with lib; {
  options.nzbr.source = with types; {
    enable = mkEnableOption "Flake Source";
  };

  config = mkIf config.nzbr.source.enable {
    environment.etc."nixos".source = config.nzbr.flake.root;

    system.activationScripts.inputs.text = ''
      echo linking inputs
      mkdir -p /run/inputs
      ${concatStringsSep " && " (mapAttrsToList (name: val: "ln -sf ${val} /run/inputs/${name}") inputs)}
    '';
  };
}
