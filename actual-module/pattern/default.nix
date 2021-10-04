{ config, lib, pkgs, modulesPath, ... }:
with builtins; with lib; {
  options.nzbr.patterns = with types; mkOption {
    type = listOf str;
    default = [ ];
    description = "List of names of prototypes (premade configuration snippets) to activate";
  };

  config.nzbr.pattern = listToAttrs (
    map
      (name: nameValuePair' name { enable = true; })
      (config.nzbr.patterns)
  );
}
