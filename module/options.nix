{ lib, config, ... }:
with builtins; with lib; {
  options.nzbr = with types; {
    system = strOption;
    user = mkStrOpt "nzbr";
    hostName = mkStrOpt "${config.networking.hostName}.dragon-augmented.ts.net";
    nodeIp = mkOption {
      type = str;
      description = "internal IP that is accessible from other hosts (mainly for k3s) - tailscale IP in my case";
      example = "100.x.y.z";
    };
    nodeIp6 = mkOption {
      type = str;
      description = "internal IPv6 that is accessible from other hosts (mainly for k3s) - tailscale IP in my case";
      example = "fd7a:115c:a1e0:.../96";
    };

    flake = {
      root = strOptOrNull;
      assets = strOptOrNull;
      host = strOptOrNull;
    };

    deployment = {
      targetUser = mkStrOpt "root";
      targetHost = mkStrOpt config.nzbr.hostName;
      substituteOnDestination = mkBoolOpt true;
    };
  };
}
