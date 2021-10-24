{ lib, ... }:
with builtins; with lib; {
  options.nzbr = with types; {
    user = mkStrOpt "nzbr";

    flake = {
      root = strOptOrNull;
      assets = strOptOrNull;
      host = strOptOrNull;
    };

    deployment = {
      targetUser = mkStrOpt "root";
      targetHost = strOption;
      substituteOnDestination = mkBoolOpt true;
    };
  };
}
