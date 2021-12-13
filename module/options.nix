{ lib, ... }:
with builtins; with lib; {
  options.nzbr = with types; {
    user = mkStrOpt "nzbr";
    nodeIp = mkOption {
      type = str;
      description = "internal IP that is accessible from other hosts (mainly for k3s) - tailscale IP in my case";
      example = "100.x.y.z";
    };

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
