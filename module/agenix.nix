{ config, lib, inputs, system, ... }:
with builtins; with lib;
let
  assets = config.nzbr.flake.assets;
  host = config.nzbr.flake.host;
  useAgenix = config.nzbr.agenix.enable;

  find = dir: map (name: removePrefix "${dir}/" name) (findModules "" dir);
  commonAssets = find "${assets}";
  hostAssets = find "${host}";
  allAssets = commonAssets ++ hostAssets;

  findAsset = name: (if elem name hostAssets then "${host}" else "${assets}") + "/${name}";
in
{
  options.nzbr = with types; {
    agenix.enable = mkEnableOption "Decrypt age-encrypted assets using the systems SSH host keys";

    assets = mkOption {
      type = attrsOf str;
    };
    foreignAssets = with types; mkOption {
      type = attrsOf (attrsOf str);
    };
  };

  config = {
    nzbr =
      {
        assets =
          if (assets == null || host == null) then { } else
          listToAttrs (
            map
              (file:
                let
                  file' = unsafeDiscardStringContext (removeSuffix ".age" file);
                in
                {
                  name = file';
                  value =
                    if (useAgenix && hasSuffix ".age" file)
                    then config.age.secrets.${file'}.path
                    else findAsset file;
                }
              )
              allAssets
          );

        foreignAssets =
          listToAttrs (
            map
              (host: nameValuePair' host inputs.self.packages.${system}.nixosConfigurations.${host}.config.nzbr.assets)
              (attrNames inputs.self.packages.${system}.nixosConfigurations)
          );
      };


    age = mkIf
      (
        useAgenix
        && assets != null
        && host != null
      )
      {
        identityPaths = [
          "/etc/ssh/ssh_host_ed25519_key"
          "/etc/ssh/ssh_host_rsa_key"
        ];
        secrets = listToAttrs (
          map
            (file:
              nameValuePair'
                (removeSuffix ".age" file)
                { file = findAsset file; }
            )
            (
              filter
                (name: hasSuffix ".age" name)
                allAssets
            )
        );
      };
  };
}
