{ lib, ... }:
with builtins; with lib; {
  options.nzbr = with types; {
    user = mkStrOpt "nzbr";

    flake =
      let
        strOptOrNull = mkOption { type = nullOr str; default = null; };
      in
      {
        root = strOptOrNull;
        assets = strOptOrNull;
        host = strOptOrNull;
      };
  };
}
