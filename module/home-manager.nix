{ config, options, lib, inputs, pkgs, ... }:
with builtins; with lib; {

  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  options.nzbr.home = with types; {
    users = mkOption {
      description = "Names of the users that the config should be applied to";
      type = listOf str;
      default = [ "root" config.nzbr.user ];
    };

    config = mkOption {
      description = "Home Manager config for the specified users";
      type = attrsOf anything;
      default = { };
    };
  };

  config = {
    home-manager = {
      useUserPackages = false;
      useGlobalPkgs = true;
      users =
        if config.nzbr.home.config == { }
        then [ ]
        else
          listToAttrs (
            map
              (user: nameValuePair' user { config = config.nzbr.home.config; })
              config.nzbr.home.users
          );
    };

    environment.extraInit = ''
      if [ -f /etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh ]; then
          source /etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh
      fi
    '';
  };

}
