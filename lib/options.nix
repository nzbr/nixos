{ lib, ... }:
with builtins; with lib; with types; {
  boolOption = mkOption { type = bool; };
  mkBoolOpt = default:
    mkOption {
      inherit default;
      type = bool;
    };

  strOption = mkOption { type = str; };
  strOptOrNull = mkOption { type = nullOr str; default = null; };
  mkStrOpt = default:
    mkOption {
      type = str;
      inherit default;
    };

  intOption = mkOption { type = int; };
  mkIntOpt = default:
    mkOption {
      type = int;
      inherit default;
    };
}
