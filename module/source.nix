{ config, lib, ... }:
with builtins; with lib; {
  options.nzbr.source = with types; {
    enable = mkEnableOption "Flake Source";
  };

  config = mkIf config.nzbr.source.enable {
    environment.etc."nixos".source = config.nzbr.flake.root;
  };
}
